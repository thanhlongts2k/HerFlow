// lib/features/motherhood/presentation/controllers/child_profile_controller.dart
//
// Controller quản lý danh sách hồ sơ bé sơ sinh và trẻ nhỏ (ChildProfileModel).
// Hỗ trợ Clean Architecture, quản lý đa bé (multiple children), cô lập dữ liệu UserScope,
// và đồng bộ trạng thái tóm tắt sang máy Bạn đời qua Firestore.

import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:herflow/core/constants/app_constants.dart';
import 'package:herflow/core/utils/user_scope.dart';
import 'package:herflow/features/motherhood/domain/models/child_profile_model.dart';
import 'package:herflow/features/motherhood/domain/models/motherhood_status_model.dart';

// ════════════════════════════════════════════════════════════════════════════
// STATE
// ════════════════════════════════════════════════════════════════════════════

class ChildProfileState {
  final List<ChildProfileModel> children;
  final String? activeChildId;
  final bool isLoading;
  final String? errorMessage;

  const ChildProfileState({
    this.children = const [],
    this.activeChildId,
    this.isLoading = false,
    this.errorMessage,
  });

  /// Lấy hồ sơ bé đang được chọn theo dõi
  ChildProfileModel? get activeChild {
    if (children.isEmpty) return null;
    if (activeChildId != null) {
      for (final c in children) {
        if (c.childId == activeChildId) return c;
      }
    }
    return children.first;
  }

  ChildProfileState copyWith({
    List<ChildProfileModel>? children,
    String? activeChildId,
    bool? isLoading,
    String? errorMessage,
    bool clearActiveChildId = false,
  }) {
    return ChildProfileState(
      children: children ?? this.children,
      activeChildId: clearActiveChildId
          ? null
          : (activeChildId ?? this.activeChildId),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// CONTROLLER
// ════════════════════════════════════════════════════════════════════════════

class ChildProfileController extends StateNotifier<ChildProfileState> {
  final Box? _box;
  final FirebaseFirestore? _firestore;

  ChildProfileController({
    Box? motherhoodBox,
    FirebaseFirestore? firestore,
    String? defaultUid,
  })  : _box = motherhoodBox ?? _resolveBox(),
        _firestore = firestore ?? _resolveFirestore(),
        super(const ChildProfileState(isLoading: true)) {
    loadChildren(defaultUid);
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

  void loadChildren([String? uid]) {
    final effectiveUid = uid ?? UserScope.currentUid();
    if (_box == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    try {
      final rawJson = _box.get(_k(AppConstants.keyChildrenList, effectiveUid));
      List<ChildProfileModel> list = [];
      if (rawJson is String && rawJson.isNotEmpty) {
        final decoded = jsonDecode(rawJson) as List<dynamic>;
        list = decoded
            .map((item) => ChildProfileModel.fromJson(
                Map<String, dynamic>.from(item as Map)))
            .toList();
      }

      final activeId = _box.get(_k(AppConstants.keyActiveChildId, effectiveUid))
          as String?;

      state = state.copyWith(
        children: list,
        activeChildId: activeId ?? (list.isNotEmpty ? list.first.childId : null),
        isLoading: false,
      );
    } catch (e) {
      debugPrint('[ChildProfileController] Load error: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể tải danh sách bé: $e',
      );
    }
  }

  // ── Thêm bé mới ────────────────────────────────────────────────────────────

  Future<void> addChild(ChildProfileModel child, {String? uid}) async {
    final effectiveUid = uid ?? UserScope.currentUid();
    final updatedList = List<ChildProfileModel>.from(state.children)
      ..removeWhere((c) => c.childId == child.childId)
      ..add(child);

    final activeId = state.activeChildId ?? child.childId;

    state = state.copyWith(
      children: updatedList,
      activeChildId: activeId,
    );

    await _saveToLocal(effectiveUid, updatedList, activeId);
    _syncSummaryToPartner(effectiveUid);
  }

  // ── Cập nhật hồ sơ bé ─────────────────────────────────────────────────────

  Future<void> updateChild(ChildProfileModel child, {String? uid}) async {
    final effectiveUid = uid ?? UserScope.currentUid();
    final updatedList = state.children.map((c) {
      return c.childId == child.childId ? child : c;
    }).toList();

    state = state.copyWith(children: updatedList);

    await _saveToLocal(effectiveUid, updatedList, state.activeChildId);
    if (state.activeChildId == child.childId) {
      _syncSummaryToPartner(effectiveUid);
    }
  }

  // ── Xóa hồ sơ bé ──────────────────────────────────────────────────────────

  Future<void> deleteChild(String childId, {String? uid}) async {
    final effectiveUid = uid ?? UserScope.currentUid();
    final updatedList =
        state.children.where((c) => c.childId != childId).toList();

    String? newActiveId = state.activeChildId;
    if (newActiveId == childId) {
      newActiveId = updatedList.isNotEmpty ? updatedList.first.childId : null;
    }

    state = state.copyWith(
      children: updatedList,
      activeChildId: newActiveId,
      clearActiveChildId: newActiveId == null,
    );

    await _saveToLocal(effectiveUid, updatedList, newActiveId);
    _syncSummaryToPartner(effectiveUid);
  }

  // ── Chọn bé đang hoạt động ────────────────────────────────────────────────

  Future<void> setActiveChild(String childId, {String? uid}) async {
    final effectiveUid = uid ?? UserScope.currentUid();
    if (state.activeChildId == childId) return;

    state = state.copyWith(activeChildId: childId);
    if (_box != null) {
      await _box.put(_k(AppConstants.keyActiveChildId, effectiveUid), childId);
    }
    _syncSummaryToPartner(effectiveUid);
  }

  // ── Tạm dừng tracking (Chế độ chữa lành) ───────────────────────────────────

  Future<void> togglePauseTracking(String childId, {String? uid}) async {
    final child = state.children.firstWhere((c) => c.childId == childId);
    final updated = child.copyWith(isPaused: !child.isPaused);
    await updateChild(updated, uid: uid);
  }

  // ── Lưu trữ cục bộ ────────────────────────────────────────────────────────

  Future<void> _saveToLocal(
    String effectiveUid,
    List<ChildProfileModel> children,
    String? activeChildId,
  ) async {
    if (_box == null) return;
    try {
      final jsonString =
          jsonEncode(children.map((c) => c.toJson()).toList());
      await _box.put(_k(AppConstants.keyChildrenList, effectiveUid), jsonString);
      if (activeChildId != null) {
        await _box.put(
          _k(AppConstants.keyActiveChildId, effectiveUid),
          activeChildId,
        );
      } else {
        await _box.delete(_k(AppConstants.keyActiveChildId, effectiveUid));
      }
    } catch (e) {
      debugPrint('[ChildProfileController] Save error: $e');
    }
  }

  // ── Đồng bộ Firestore sang máy Bạn đời ────────────────────────────────────

  void _syncSummaryToPartner(String effectiveUid) {
    if (_firestore == null) return;
    final coupleId = _getCoupleId(effectiveUid);
    if (coupleId == null || coupleId.isEmpty) return;

    final active = state.activeChild;
    final status = MotherhoodStatusModel(
      coupleId: coupleId,
      activeChildId: active?.childId,
      activeChildName: active?.name,
      activeChildAgeDisplay: active?.getAgeDisplay(),
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
      debugPrint('[ChildProfileController] Partner sync note: $e');
    });
  }
}

// ════════════════════════════════════════════════════════════════════════════
// PROVIDERS
// ════════════════════════════════════════════════════════════════════════════

final childProfileControllerProvider =
    StateNotifierProvider<ChildProfileController, ChildProfileState>((ref) {
  return ChildProfileController();
});

final activeChildProvider = Provider<ChildProfileModel?>((ref) {
  return ref.watch(childProfileControllerProvider).activeChild;
});
