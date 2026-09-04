// lib/features/motherhood/presentation/controllers/baby_log_controller.dart
//
// Controller quản lý nhật ký hoạt động sơ sinh (cữ bú, giấc ngủ, tã bỉm, v.v.).
// Hỗ trợ Clean Architecture, ghi chép nhanh 1 chạm (Quick Log),
// lưu trữ UserScope cục bộ và đồng bộ tức thời sang máy Bạn đời.

import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:herflow/core/constants/app_constants.dart';
import 'package:herflow/core/utils/user_scope.dart';
import 'package:herflow/features/motherhood/domain/models/baby_activity_log_model.dart';
import 'package:herflow/features/motherhood/domain/models/motherhood_status_model.dart';
import 'package:herflow/features/partner_sync/presentation/controllers/partner_sync_controller.dart';

// ════════════════════════════════════════════════════════════════════════════
// STATE
// ════════════════════════════════════════════════════════════════════════════

class BabyLogState {
  final List<BabyActivityLogModel> logs;
  final DateTime selectedDate;
  final bool isLoading;
  final String? errorMessage;

  const BabyLogState({
    this.logs = const [],
    required this.selectedDate,
    this.isLoading = false,
    this.errorMessage,
  });

  /// Danh sách nhật ký của ngày [selectedDate]
  List<BabyActivityLogModel> get todayLogs {
    return logs.where((l) {
      return l.timestamp.year == selectedDate.year &&
          l.timestamp.month == selectedDate.month &&
          l.timestamp.day == selectedDate.day;
    }).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Cữ bú gần nhất
  BabyActivityLogModel? get lastFeeding {
    final feedings = logs.where((l) => l.type == ActivityType.feeding).toList();
    if (feedings.isEmpty) return null;
    feedings.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return feedings.first;
  }

  /// Lần thay tã gần nhất
  BabyActivityLogModel? get lastDiaper {
    final diapers = logs.where((l) => l.type == ActivityType.diaper).toList();
    if (diapers.isEmpty) return null;
    diapers.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return diapers.first;
  }

  /// Giấc ngủ gần nhất
  BabyActivityLogModel? get lastSleep {
    final sleeps = logs.where((l) => l.type == ActivityType.sleep).toList();
    if (sleeps.isEmpty) return null;
    sleeps.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sleeps.first;
  }

  /// Số cữ bú trong ngày được chọn
  int get todayFeedingCount {
    return todayLogs.where((l) => l.type == ActivityType.feeding).length;
  }

  /// Số lần thay tã trong ngày được chọn
  int get todayDiaperCount {
    return todayLogs.where((l) => l.type == ActivityType.diaper).length;
  }

  /// Tổng thời lượng ngủ trong ngày (phút)
  int get todaySleepDurationMinutes {
    return todayLogs
        .where((l) => l.type == ActivityType.sleep)
        .fold(0, (total, item) => total + item.calculatedDurationMinutes);
  }

  BabyLogState copyWith({
    List<BabyActivityLogModel>? logs,
    DateTime? selectedDate,
    bool? isLoading,
    String? errorMessage,
  }) {
    return BabyLogState(
      logs: logs ?? this.logs,
      selectedDate: selectedDate ?? this.selectedDate,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// CONTROLLER
// ════════════════════════════════════════════════════════════════════════════

class BabyLogController extends StateNotifier<BabyLogState> {
  final Box? _box;
  final FirebaseFirestore? _firestore;

  BabyLogController({
    Box? motherhoodBox,
    FirebaseFirestore? firestore,
    String? defaultUid,
  })  : _box = motherhoodBox ?? _resolveBox(),
        _firestore = firestore ?? _resolveFirestore(),
        super(BabyLogState(
          selectedDate: DateTime.now(),
          isLoading: true,
        )) {
    loadLogs(uid: defaultUid);
  }

  static Box? _resolveBox() {
    try {
      if (Hive.isBoxOpen(AppConstants.motherhoodBoxName)) {
        return Hive.box(AppConstants.motherhoodBoxName);
      }
    } catch (_) {}
    return null;
  }

  static FirebaseFirestore? _resolveFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  String _k(String base, [String? uid]) => UserScope.key(base, uid);

  String? _getCoupleId(String uid) {
    try {
      if (Hive.isBoxOpen(AppConstants.settingsBoxName)) {
        final box = Hive.box(AppConstants.settingsBoxName);
        return box.get(UserScope.key('partner_couple_id', uid)) as String? ??
            box.get('partner_couple_id') as String?;
      }
    } catch (_) {}
    return null;
  }

  // ── Load dữ liệu ──────────────────────────────────────────────────────────

  void loadLogs({String? childId, String? uid}) {
    final effectiveUid = uid ?? UserScope.currentUid();
    if (_box == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    try {
      final rawJson = _box.get(_k(AppConstants.keyBabyLogs, effectiveUid));
      List<BabyActivityLogModel> list = [];
      if (rawJson is String && rawJson.isNotEmpty) {
        final decoded = jsonDecode(rawJson) as List<dynamic>;
        list = decoded
            .map((item) => BabyActivityLogModel.fromJson(
                Map<String, dynamic>.from(item as Map)))
            .toList();
      }

      // Lọc theo childId nếu được truyền vào
      if (childId != null && childId.isNotEmpty) {
        list = list.where((l) => l.childId == childId).toList();
      }

      state = state.copyWith(
        logs: list,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('[BabyLogController] Load error: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể tải nhật ký bé: $e',
      );
    }
  }

  // ── Thêm nhật ký mới ──────────────────────────────────────────────────────

  Future<void> addLog(BabyActivityLogModel log, {String? uid}) async {
    final effectiveUid = uid ?? UserScope.currentUid();
    final updatedList = List<BabyActivityLogModel>.from(state.logs)
      ..removeWhere((l) => l.id == log.id)
      ..add(log);

    state = state.copyWith(logs: updatedList);

    await _saveToLocal(effectiveUid, updatedList);
    _syncSummaryToPartner(effectiveUid);
  }

  // ── Xóa nhật ký ───────────────────────────────────────────────────────────

  Future<void> deleteLog(String logId, {String? uid}) async {
    final effectiveUid = uid ?? UserScope.currentUid();
    final updatedList = state.logs.where((l) => l.id != logId).toList();

    state = state.copyWith(logs: updatedList);

    await _saveToLocal(effectiveUid, updatedList);
    _syncSummaryToPartner(effectiveUid);
  }

  // ── Tiện ích Ghi chép Nhanh (Quick Log) ───────────────────────────────────

  Future<void> quickLogFeeding({
    required String childId,
    required FeedingType type,
    double? amountMl,
    int? durationMinutes,
    String? notes,
    String? uid,
    String userRole = 'wife',
  }) async {
    final effectiveUid = uid ?? UserScope.currentUid();
    final now = DateTime.now();
    final log = BabyActivityLogModel(
      id: 'feed_${now.millisecondsSinceEpoch}',
      childId: childId,
      loggedByUid: effectiveUid,
      loggedByRole: userRole,
      type: ActivityType.feeding,
      timestamp: now,
      feedingType: type,
      amountMl: amountMl,
      durationMinutes: durationMinutes,
      notes: notes,
    );
    await addLog(log, uid: effectiveUid);
  }

  Future<void> quickLogDiaper({
    required String childId,
    required DiaperType type,
    String? notes,
    String? uid,
    String userRole = 'wife',
  }) async {
    final effectiveUid = uid ?? UserScope.currentUid();
    final now = DateTime.now();
    final log = BabyActivityLogModel(
      id: 'diaper_${now.millisecondsSinceEpoch}',
      childId: childId,
      loggedByUid: effectiveUid,
      loggedByRole: userRole,
      type: ActivityType.diaper,
      timestamp: now,
      diaperType: type,
      notes: notes,
    );
    await addLog(log, uid: effectiveUid);
  }

  Future<void> quickLogSleep({
    required String childId,
    required DateTime startTime,
    DateTime? endTime,
    int? durationMinutes,
    String? notes,
    String? uid,
    String userRole = 'wife',
  }) async {
    final effectiveUid = uid ?? UserScope.currentUid();
    final now = DateTime.now();
    final log = BabyActivityLogModel(
      id: 'sleep_${now.millisecondsSinceEpoch}',
      childId: childId,
      loggedByUid: effectiveUid,
      loggedByRole: userRole,
      type: ActivityType.sleep,
      timestamp: startTime,
      endTime: endTime,
      durationMinutes: durationMinutes,
      notes: notes,
    );
    await addLog(log, uid: effectiveUid);
  }

  // ── Đổi ngày hiển thị ─────────────────────────────────────────────────────

  void selectDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  // ── Lưu trữ cục bộ ────────────────────────────────────────────────────────

  Future<void> _saveToLocal(
    String effectiveUid,
    List<BabyActivityLogModel> logs,
  ) async {
    if (_box == null) return;
    try {
      final jsonString =
          jsonEncode(logs.map((l) => l.toJson()).toList());
      await _box.put(_k(AppConstants.keyBabyLogs, effectiveUid), jsonString);
    } catch (e) {
      debugPrint('[BabyLogController] Save error: $e');
    }
  }

  // ── Đồng bộ Firestore sang máy Bạn đời ────────────────────────────────────

  void _syncSummaryToPartner(String effectiveUid) {
    if (_firestore == null) return;
    final coupleId = _getCoupleId(effectiveUid);
    if (coupleId == null || coupleId.isEmpty) return;

    final lastFeed = state.lastFeeding;
    final lastDiap = state.lastDiaper;
    final lastSlp = state.lastSleep;

    String? feedSummary;
    if (lastFeed != null) {
      if (lastFeed.feedingType != null) {
        switch (lastFeed.feedingType!) {
          case FeedingType.breastLeft:
            feedSummary = 'Bú mẹ ngực trái (${lastFeed.calculatedDurationMinutes}p)';
            break;
          case FeedingType.breastRight:
            feedSummary = 'Bú mẹ ngực phải (${lastFeed.calculatedDurationMinutes}p)';
            break;
          case FeedingType.bottleBreastMilk:
            feedSummary = 'Bú bình sữa mẹ (${lastFeed.amountMl ?? 0}ml)';
            break;
          case FeedingType.bottleFormula:
            feedSummary = 'Bú sữa công thức (${lastFeed.amountMl ?? 0}ml)';
            break;
          case FeedingType.solid:
            feedSummary = 'Ăn dặm';
            break;
        }
      }
    }

    String? diaperSummary;
    if (lastDiap != null && lastDiap.diaperType != null) {
      switch (lastDiap.diaperType!) {
        case DiaperType.wet:
          diaperSummary = 'Tã ướt';
          break;
        case DiaperType.dirty:
          diaperSummary = 'Tã bẩn';
          break;
        case DiaperType.both:
          diaperSummary = 'Cả ướt & bẩn';
          break;
        case DiaperType.clean:
          diaperSummary = 'Tã sạch';
          break;
      }
    }

    final status = MotherhoodStatusModel(
      coupleId: coupleId,
      lastFeedingTime: lastFeed?.timestamp,
      lastFeedingSummary: feedSummary,
      lastDiaperTime: lastDiap?.timestamp,
      lastDiaperSummary: diaperSummary,
      lastSleepTime: lastSlp?.timestamp,
      lastSleepDurationMinutes: lastSlp?.calculatedDurationMinutes,
      updatedAt: DateTime.now(),
      updatedByUid: effectiveUid,
      updatedByRole: 'wife',
    );

    _firestore
        .collection('couples')
        .doc(coupleId)
        .collection('motherhoodStatus')
        .doc('today')
        .set(status.toMap(), SetOptions(merge: true))
        .catchError((e) {
      debugPrint('[BabyLogController] Partner sync note: $e');
    });
  }
}

// ════════════════════════════════════════════════════════════════════════════
// PROVIDERS
// ════════════════════════════════════════════════════════════════════════════

final babyLogControllerProvider =
    StateNotifierProvider<BabyLogController, BabyLogState>((ref) {
  return BabyLogController();
});

/// StreamProvider lắng nghe trạng thái Nuôi Con từ Firestore theo thời gian thực:
/// couples/{coupleId}/motherhoodStatus/today
final motherhoodStatusStreamProvider =
    StreamProvider.autoDispose<MotherhoodStatusModel?>((ref) {
  final coupleId = ref.watch(savedCoupleIdProvider);
  if (coupleId == null || coupleId.isEmpty) {
    return Stream.value(null);
  }

  try {
    return FirebaseFirestore.instance
        .collection('couples')
        .doc(coupleId)
        .collection('motherhoodStatus')
        .doc('today')
        .snapshots()
        .map((doc) {
          if (!doc.exists || doc.data() == null) return null;
          return MotherhoodStatusModel.fromMap(doc.data()!);
        })
        .handleError((e) {
          debugPrint('[motherhoodStatusStreamProvider] note: $e');
          return null;
        });
  } catch (_) {
    return Stream.value(null);
  }
});
