// lib/features/motherhood/presentation/controllers/lam_status_controller.dart
//
// Controller đánh giá hiệu lực Phương Pháp Vô Kinh Cho Con Bú (Lactational Amenorrhea Method - LAM)
// theo chuẩn Y khoa của Tổ chức Y Tế Thế Giới (WHO).
//
// 3 Điều kiện Y khoa chuẩn của LAM:
//   1. Bé dưới 6 tháng tuổi (< 183 ngày).
//   2. Mẹ cho bú hoàn toàn bằng sữa mẹ (không dặm sữa ngoài, không ăn dặm).
//   3. Mẹ chưa có kinh nguyệt trở lại sau sinh (> 56 ngày / 8 tuần sau sinh).
//
// Khi LAM đang hiệu lực: Tự động ức chế cảnh báo trễ kinh để mẹ không hoang mang.
// Khi 1 trong 3 điều kiện bị phá vỡ: Bật cảnh báo mẹ cần dùng biện pháp ngừa thai chủ động.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:herflow/core/constants/app_constants.dart';
import 'package:herflow/core/utils/user_scope.dart';
import 'package:herflow/features/motherhood/domain/models/child_profile_model.dart';

// ════════════════════════════════════════════════════════════════════════════
// STATE
// ════════════════════════════════════════════════════════════════════════════

class LamState {
  final bool isEligible;                  // Thỏa mãn cả 3 điều kiện LAM
  final bool isUnder6Months;              // Điều kiện 1: Bé < 6 tháng
  final bool isExclusiveBreastfeeding;    // Điều kiện 2: Bú mẹ hoàn toàn
  final bool hasMensesReturned;           // Điều kiện 3: Kinh nguyệt đã trở lại chưa
  final DateTime? mensesReturnDate;
  final String statusMessage;
  final bool shouldSuppressLatePeriodAlert;

  const LamState({
    this.isEligible = false,
    this.isUnder6Months = true,
    this.isExclusiveBreastfeeding = true,
    this.hasMensesReturned = false,
    this.mensesReturnDate,
    this.statusMessage = 'Đang đánh giá điều kiện LAM...',
    this.shouldSuppressLatePeriodAlert = false,
  });

  LamState copyWith({
    bool? isEligible,
    bool? isUnder6Months,
    bool? isExclusiveBreastfeeding,
    bool? hasMensesReturned,
    DateTime? mensesReturnDate,
    String? statusMessage,
    bool? shouldSuppressLatePeriodAlert,
    bool clearMensesDate = false,
  }) {
    return LamState(
      isEligible: isEligible ?? this.isEligible,
      isUnder6Months: isUnder6Months ?? this.isUnder6Months,
      isExclusiveBreastfeeding:
          isExclusiveBreastfeeding ?? this.isExclusiveBreastfeeding,
      hasMensesReturned: hasMensesReturned ?? this.hasMensesReturned,
      mensesReturnDate: clearMensesDate
          ? null
          : (mensesReturnDate ?? this.mensesReturnDate),
      statusMessage: statusMessage ?? this.statusMessage,
      shouldSuppressLatePeriodAlert:
          shouldSuppressLatePeriodAlert ?? this.shouldSuppressLatePeriodAlert,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEligible': isEligible,
      'isUnder6Months': isUnder6Months,
      'isExclusiveBreastfeeding': isExclusiveBreastfeeding,
      'hasMensesReturned': hasMensesReturned,
      'mensesReturnDate': mensesReturnDate?.toIso8601String(),
      'statusMessage': statusMessage,
      'shouldSuppressLatePeriodAlert': shouldSuppressLatePeriodAlert,
    };
  }

  factory LamState.fromJson(Map<String, dynamic> json) {
    return LamState(
      isEligible: json['isEligible'] as bool? ?? false,
      isUnder6Months: json['isUnder6Months'] as bool? ?? true,
      isExclusiveBreastfeeding: json['isExclusiveBreastfeeding'] as bool? ?? true,
      hasMensesReturned: json['hasMensesReturned'] as bool? ?? false,
      mensesReturnDate: json['mensesReturnDate'] != null
          ? DateTime.tryParse(json['mensesReturnDate'] as String)
          : null,
      statusMessage: json['statusMessage'] as String? ?? '',
      shouldSuppressLatePeriodAlert:
          json['shouldSuppressLatePeriodAlert'] as bool? ?? false,
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// CONTROLLER
// ════════════════════════════════════════════════════════════════════════════

class LamStatusController extends StateNotifier<LamState> {
  final Box? _box;

  LamStatusController({
    Box? motherhoodBox,
    String? defaultUid,
  })  : _box = motherhoodBox ?? _resolveBox(),
        super(const LamState()) {
    _loadFromLocal(defaultUid);
  }

  static Box? _resolveBox() {
    try {
      if (Hive.isBoxOpen(AppConstants.motherhoodBoxName)) {
        return Hive.box(AppConstants.motherhoodBoxName);
      }
    } catch (_) {}
    return null;
  }

  String _k(String base, [String? uid]) => UserScope.key(base, uid);

  // ── Load dữ liệu từ Local ─────────────────────────────────────────────────

  void _loadFromLocal([String? uid]) {
    final effectiveUid = uid ?? UserScope.currentUid();
    if (_box == null) return;

    try {
      final raw = _box.get(_k(AppConstants.keyLamStatus, effectiveUid));
      if (raw is String && raw.isNotEmpty) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        state = LamState.fromJson(map);
      }
    } catch (e) {
      debugPrint('[LamStatusController] Load error: $e');
    }
  }

  // ── Đánh giá lại LAM dựa trên hồ sơ bé ────────────────────────────────────

  void evaluateWithChild(ChildProfileModel? child, {DateTime? now}) {
    if (child == null) {
      state = state.copyWith(
        isEligible: false,
        statusMessage: 'Chưa có thông tin bé để đánh giá điều kiện LAM.',
        shouldSuppressLatePeriodAlert: false,
      );
      return;
    }

    final targetDate = now ?? DateTime.now();
    final ageDays = child.getAgeInDays(targetDate);
    final isUnder6M = ageDays <= 182; // 6 tháng ≈ 182.5 ngày
    final isExclusive = child.isBreastfeedingExclusively;
    final mensesReturned = state.hasMensesReturned;

    final eligible = isUnder6M && isExclusive && !mensesReturned;

    String msg;
    if (eligible) {
      msg = 'Phương pháp LAM đang có hiệu lực (~98% ngừa thai tự nhiên).';
    } else if (!isUnder6M) {
      msg = 'Bé đã qua 6 tháng tuổi. Hiệu quả LAM giảm sút, hãy dùng biện pháp ngừa thai bổ sung.';
    } else if (!isExclusive) {
      msg = 'Bé không còn bú mẹ hoàn toàn. Cơ chế vô kinh có thể bị gián đoạn.';
    } else {
      msg = 'Kinh nguyệt đã trở lại. Chu kỳ sinh sản đã phục hồi, mẹ cần tránh thai chủ động.';
    }

    if (state.isEligible == eligible &&
        state.isUnder6Months == isUnder6M &&
        state.isExclusiveBreastfeeding == isExclusive &&
        state.statusMessage == msg &&
        state.shouldSuppressLatePeriodAlert == eligible) {
      return;
    }

    state = state.copyWith(
      isEligible: eligible,
      isUnder6Months: isUnder6M,
      isExclusiveBreastfeeding: isExclusive,
      statusMessage: msg,
      shouldSuppressLatePeriodAlert: eligible,
    );

    _saveToLocal();
  }

  // ── Cập nhật trạng thái Kinh nguyệt ────────────────────────────────────────

  Future<void> setMensesReturned(bool returned, {DateTime? date, String? uid}) async {
    final effectiveUid = uid ?? UserScope.currentUid();
    state = state.copyWith(
      hasMensesReturned: returned,
      mensesReturnDate: returned ? (date ?? DateTime.now()) : null,
      clearMensesDate: !returned,
    );

    // Tái đánh giá hiệu lực
    final eligible = state.isUnder6Months &&
        state.isExclusiveBreastfeeding &&
        !returned;

    final msg = eligible
        ? 'Phương pháp LAM đang có hiệu lực (~98% ngừa thai tự nhiên).'
        : 'Kinh nguyệt đã trở lại. Chu kỳ sinh sản đã phục hồi, mẹ cần tránh thai chủ động.';

    state = state.copyWith(
      isEligible: eligible,
      statusMessage: msg,
      shouldSuppressLatePeriodAlert: eligible,
    );

    await _saveToLocal(effectiveUid);
  }

  // ── Cập nhật trạng thái Bú mẹ hoàn toàn ────────────────────────────────────

  Future<void> setExclusiveBreastfeeding(bool exclusive, {String? uid}) async {
    final effectiveUid = uid ?? UserScope.currentUid();
    state = state.copyWith(isExclusiveBreastfeeding: exclusive);

    final eligible = state.isUnder6Months &&
        exclusive &&
        !state.hasMensesReturned;

    final msg = eligible
        ? 'Phương pháp LAM đang có hiệu lực (~98% ngừa thai tự nhiên).'
        : 'Bé không còn bú mẹ hoàn toàn. Cơ chế vô kinh có thể bị gián đoạn.';

    state = state.copyWith(
      isEligible: eligible,
      statusMessage: msg,
      shouldSuppressLatePeriodAlert: eligible,
    );

    await _saveToLocal(effectiveUid);
  }

  // ── Lưu trữ Local ─────────────────────────────────────────────────────────

  Future<void> _saveToLocal([String? uid]) async {
    final effectiveUid = uid ?? UserScope.currentUid();
    if (_box == null) return;
    try {
      final jsonString = jsonEncode(state.toJson());
      await _box.put(_k(AppConstants.keyLamStatus, effectiveUid), jsonString);
    } catch (e) {
      debugPrint('[LamStatusController] Save error: $e');
    }
  }
}

// ════════════════════════════════════════════════════════════════════════════
// PROVIDERS
// ════════════════════════════════════════════════════════════════════════════

final lamStatusControllerProvider =
    StateNotifierProvider<LamStatusController, LamState>((ref) {
  return LamStatusController();
});
