import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:herflow/core/constants/app_constants.dart';
import 'package:herflow/core/constants/user_role.dart';
import 'package:herflow/core/providers/user_role_provider.dart';
import 'package:herflow/core/utils/user_scope.dart';
import 'package:herflow/features/lifecycle/domain/models/life_stage.dart';
import 'package:herflow/features/auth/presentation/controllers/auth_controller.dart';
import 'package:herflow/features/partner_sync/presentation/controllers/partner_sync_controller.dart';

// ════════════════════════════════════════════════════════════════════════════
// STATE
// ════════════════════════════════════════════════════════════════════════════

/// Trạng thái đầy đủ của giai đoạn sống hiện tại.
class LifeStageState {
  final LifeStage currentStage;
  final bool isPaused;
  final String? pauseReason;
  final bool isLoading;

  const LifeStageState({
    this.currentStage = LifeStage.solo,
    this.isPaused = false,
    this.pauseReason,
    this.isLoading = false,
  });

  /// Trạng thái bình thường (không loading, không tạm dừng).
  const LifeStageState.normal({LifeStage stage = LifeStage.solo})
      : currentStage = stage,
        isPaused = false,
        pauseReason = null,
        isLoading = false;

  LifeStageState copyWith({
    LifeStage? currentStage,
    bool? isPaused,
    String? pauseReason,
    bool? isLoading,
    bool clearPauseReason = false,
  }) {
    return LifeStageState(
      currentStage: currentStage ?? this.currentStage,
      isPaused: isPaused ?? this.isPaused,
      pauseReason: clearPauseReason ? null : (pauseReason ?? this.pauseReason),
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LifeStageState &&
          other.currentStage == currentStage &&
          other.isPaused == isPaused &&
          other.pauseReason == pauseReason &&
          other.isLoading == isLoading;

  @override
  int get hashCode => Object.hash(currentStage, isPaused, pauseReason, isLoading);

  @override
  String toString() =>
      'LifeStageState(stage=$currentStage, isPaused=$isPaused, '
      'reason=$pauseReason, isLoading=$isLoading)';
}

// ════════════════════════════════════════════════════════════════════════════
// CONTROLLER
// ════════════════════════════════════════════════════════════════════════════

/// Notifier quản lý toàn bộ vòng đời [LifeStage] của người dùng.
///
/// ## Nguyên tắc hoạt động
/// 1. Đọc Hive local khi khởi động → state tức thì (không blocking UI).
/// 2. [switchStage]: Lưu Hive ngay → sync Firestore fire-and-forget.
/// 3. [setPauseMode]: Dùng cho tính năng Pause/Loss Mode (DP Safeguard).
/// 4. [loadForUser]: Được gọi bởi AuthController sau khi login/restore.
///
/// ## Backward compat
/// User v0.6.6 chưa có `life_stage` trong Hive → HiveMigrationValidator
/// đã chạy trước và ghi mặc định → controller đọc được giá trị hợp lệ.
class LifeStageController extends StateNotifier<LifeStageState> {
  final Box _settingsBox;
  final FirebaseFirestore? _firestore;
  final Ref? _ref;
  StreamSubscription<DocumentSnapshot>? _coupleSubscription;
  String? _listenerUid;

  LifeStageController({Box? settingsBox, FirebaseFirestore? firestore, Ref? ref, String? defaultUid})
      : _settingsBox = settingsBox ?? Hive.box(AppConstants.settingsBoxName),
        _firestore = firestore,
        _ref = ref,
        _listenerUid = defaultUid,
        super(const LifeStageState()) {
    // Khởi tạo state ngay từ Hive local (không cần async)
    _loadFromLocal(defaultUid);
  }

  FirebaseFirestore? get _safeFirestore {
    if (_firestore != null) return _firestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Scoped key cho Hive (theo UID để tránh rò rỉ dữ liệu giữa tài khoản).
  String _k(String base, [String? uid]) => UserScope.key(base, uid);

  /// Lấy coupleId nếu người dùng đã ghép đôi
  String? getSavedCoupleId([String? explicitUid]) {
    final uid = explicitUid ?? UserScope.currentUid();
    final scoped = _settingsBox.get(_k('partner_couple_id', uid)) as String?;
    if (scoped != null && scoped.isNotEmpty) return scoped;
    final fallback = _settingsBox.get('partner_couple_id') as String?;
    if (fallback != null && fallback.isNotEmpty) return fallback;
    if (_ref != null) {
      try {
        final fromProvider = _ref.read(savedCoupleIdProvider);
        if (fromProvider != null && fromProvider.isNotEmpty) return fromProvider;
      } catch (_) {}
    }
    return null;
  }

  /// Đọc LifeStage từ Hive một cách null-safe (DP-01).
  LifeStage _readStageFromHive([String? uid]) {
    final raw = _settingsBox.get(_k(AppConstants.keyLifeStage, uid));
    final value = raw is String ? raw : null;
    return LifeStageExt.fromString(value); // Fallback: solo
  }

  /// Đọc isPaused từ Hive một cách null-safe (DP-01).
  bool _readIsPausedFromHive([String? uid]) {
    final raw = _settingsBox.get(_k(AppConstants.keyIsPausedMode, uid));
    return raw is bool ? raw : false; // null → false, không crash
  }

  /// Đọc pauseReason từ Hive null-safe.
  String? _readPauseReasonFromHive([String? uid]) {
    final raw = _settingsBox.get(_k(AppConstants.keyPauseReason, uid));
    return raw is String ? raw : null;
  }

  /// Nạp state từ Hive local mà không blocking (đồng bộ vì Hive đọc đồng bộ).
  void _loadFromLocal([String? uid]) {
    final stage    = _readStageFromHive(uid);
    final isPaused = _readIsPausedFromHive(uid);
    final reason   = isPaused ? _readPauseReasonFromHive(uid) : null;

    state = LifeStageState(
      currentStage: stage,
      isPaused: isPaused,
      pauseReason: reason,
      isLoading: false,
    );
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Nạp LifeStage cho người dùng cụ thể sau khi login/restore.
  ///
  /// Được gọi bởi [AuthController._restoreUserDataFromCloud].
  /// [cloudLifeStage]: Giá trị lấy từ Firestore `users/{uid}/lifeStage`.
  /// [hasCoupleId]: True khi user có coupleId hợp lệ trong Firestore.
  ///
  /// Logic backward compat (DP-01):
  ///   - Cloud có lifeStage → dùng ngay.
  ///   - Cloud không có lifeStage + (hasCoupleId hoặc local partner_couple_id) → infer = couple.
  ///   - Cloud không có gì → solo hoặc localStage.
  Future<void> loadForUser({
    required String uid,
    String? cloudLifeStage,
    bool hasCoupleId = false,
  }) async {
    state = state.copyWith(isLoading: true);

    final savedCoupleId = _settingsBox.get(_k('partner_couple_id', uid)) as String?
        ?? _settingsBox.get('partner_couple_id') as String?;
    final isActuallyCoupled = hasCoupleId || (savedCoupleId != null && savedCoupleId.isNotEmpty);

    LifeStage resolvedStage;

    if (cloudLifeStage != null && cloudLifeStage.isNotEmpty) {
      // User mới v0.7+ đã có lifeStage trên Firestore
      resolvedStage = LifeStageExt.fromString(cloudLifeStage);
    } else {
      // Backward compat: user v0.6.6/v0.6.7 chưa có lifeStage
      // Tài khoản đã có coupleId thì stage luôn khởi tạo là LifeStage.couple
      if (isActuallyCoupled) {
        resolvedStage = LifeStage.couple;
      } else {
        final localStage = _readStageFromHive(uid);
        if (localStage != LifeStage.solo) {
          resolvedStage = localStage;
        } else {
          resolvedStage = LifeStage.solo;
        }
      }
    }

    final isPaused = _readIsPausedFromHive(uid);
    final reason   = isPaused ? _readPauseReasonFromHive(uid) : null;

    // Lưu vào Hive (đảm bảo nhất quán)
    await _settingsBox.put(_k(AppConstants.keyLifeStage, uid), resolvedStage.toStorageString());

    _listenerUid = uid;

    state = LifeStageState(
      currentStage: resolvedStage,
      isPaused: isPaused,
      pauseReason: reason,
      isLoading: false,
    );

    debugPrint('[LifeStageController] loadForUser uid=$uid → $resolvedStage');

    // Khởi tạo stream listener cho Chồng nếu có coupleId
    if (_ref != null && isActuallyCoupled) {
      try {
        final role = _ref.read(userRoleProvider);
        final cid = savedCoupleId ?? getSavedCoupleId(uid);
        if (role == UserRole.husband && cid != null && cid.isNotEmpty) {
          startListeningToCouple(cid, uid);
        }
      } catch (_) {}
    }
  }

  /// Chuyển đổi sang [LifeStage] mới.
  ///
  /// Thứ tự thực hiện (quan trọng — đừng đổi):
  ///   1. Cập nhật state ngay (UI phản hồi tức thì).
  ///   2. Lưu xuống Hive local (bền vững offline).
  ///   3. Cập nhật UserModel hiện tại qua AuthController (nếu có Ref).
  ///   4. Sync lên Firestore (fire-and-forget, không blocking).
  ///
  /// Không xóa bất kỳ dữ liệu nào khi chuyển stage.
  Future<void> switchStage(LifeStage nextStage, {String? uid}) async {
    final effectiveUid = uid ?? UserScope.currentUid();

    // Không làm gì nếu đã ở stage này rồi
    if (state.currentStage == nextStage && !state.isLoading) return;

    // 1. Cập nhật RAM ngay
    state = state.copyWith(currentStage: nextStage, isLoading: false);

    // 2. Lưu Hive local
    await _settingsBox.put(
      _k(AppConstants.keyLifeStage, effectiveUid),
      nextStage.toStorageString(),
    );

    // 3. Cập nhật UserModel hiện tại nếu có Ref
    if (_ref != null) {
      try {
        _ref.read(authControllerProvider.notifier).updateLifeStage(
          stage: nextStage,
        );
      } catch (e) {
        // Safe fallback in test or early init
      }
    }

    // 4. Sync Firestore users/{uid}
    if (effectiveUid.isNotEmpty) {
      try {
        await _safeFirestore?.collection('users').doc(effectiveUid).set(
          {
            'lifeStage': nextStage.toStorageString(),
            'currentStage': nextStage.toStorageString(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      } catch (e) {
        debugPrint('[LifeStageController] Firestore user sync skipped/error: $e');
      }
    }

    // 5. Cập nhật currentStage lên document couple trên Firestore (couples/{coupleId})
    final coupleId = getSavedCoupleId(effectiveUid);
    if (coupleId != null && coupleId.isNotEmpty) {
      try {
        await _safeFirestore?.collection('couples').doc(coupleId).set(
          {
            'currentStage': nextStage.toStorageString(),
            'lifeStage': nextStage.toStorageString(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        debugPrint(
          '[LifeStageController] Đã đồng bộ Firestore couples/$coupleId: ${nextStage.toStorageString()}',
        );
      } catch (e) {
        debugPrint('[LifeStageController] Firestore couple sync error: $e');
      }
    }

    debugPrint(
      '[LifeStageController] switchStage: '
      '${state.currentStage} → $nextStage (uid=${effectiveUid.isEmpty ? "anon" : effectiveUid})',
    );
  }

  /// Bật/tắt chế độ Tạm Dừng & Chữa Lành (Pause/Loss Mode — DP Safeguard).
  ///
  /// Khi [isPaused] = true:
  ///   - Toàn bộ widget thai kỳ/em bé bị ẩn.
  ///   - Notification tuần thai bị hủy (do DP-02 trong LifecycleNotificationManager).
  ///   - UI chuyển sang HealingModeView.
  ///
  /// [reason]: 'loss' | 'medical' | 'personal'
  Future<void> setPauseMode({
    required bool isPaused,
    String? reason,
    String? uid,
  }) async {
    final effectiveUid = uid ?? UserScope.currentUid();

    // 1. Cập nhật RAM ngay
    state = state.copyWith(
      isPaused: isPaused,
      pauseReason: isPaused ? reason : null,
      clearPauseReason: !isPaused,
    );

    // 2. Lưu Hive local
    await _settingsBox.put(
      _k(AppConstants.keyIsPausedMode, effectiveUid),
      isPaused,
    );
    if (isPaused && reason != null) {
      await _settingsBox.put(_k(AppConstants.keyPauseReason, effectiveUid), reason);
    } else {
      await _settingsBox.delete(_k(AppConstants.keyPauseReason, effectiveUid));
    }

    // 3. Cập nhật UserModel hiện tại nếu có Ref
    if (_ref != null) {
      try {
        _ref.read(authControllerProvider.notifier).updateLifeStage(
          stage: state.currentStage,
          isPaused: isPaused,
          pauseReason: isPaused ? reason : null,
          clearPauseReason: !isPaused,
        );
      } catch (e) {
        // Safe fallback
      }
    }

    // 4. Sync Firestore fire-and-forget
    if (effectiveUid.isNotEmpty) {
      try {
        _safeFirestore?.collection('users').doc(effectiveUid).set(
          {
            'isPaused': isPaused,
            'pauseReason': isPaused ? reason : null,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        ).catchError((e) {
          debugPrint('[LifeStageController] Firestore pause sync error (ignored): $e');
        });
      } catch (e) {
        debugPrint('[LifeStageController] Firestore sync skipped: $e');
      }
    }

    debugPrint(
      '[LifeStageController] setPauseMode: isPaused=$isPaused, reason=$reason',
    );
  }

  /// Lắng nghe thay đổi giai đoạn từ Document couples/{coupleId} theo thời gian thực (phía Chồng)
  void startListeningToCouple(String coupleId, [String? listenerUid]) {
    _coupleSubscription?.cancel();
    if (coupleId.isEmpty) return;

    if (listenerUid != null && listenerUid.isNotEmpty) {
      _listenerUid = listenerUid;
    } else if (_listenerUid == null || _listenerUid!.isEmpty) {
      final current = UserScope.currentUid();
      if (current.isNotEmpty) {
        _listenerUid = current;
      }
    }

    try {
      _coupleSubscription = _safeFirestore
          ?.collection('couples')
          .doc(coupleId)
          .snapshots()
          .listen((snapshot) async {
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data() as Map<String, dynamic>;
          final rawStage = data['currentStage'] as String? ?? data['lifeStage'] as String?;
          if (rawStage != null && rawStage.isNotEmpty) {
            final syncedStage = LifeStageExt.fromString(rawStage);
            if (syncedStage != state.currentStage) {
              debugPrint(
                '[LifeStageController] Đồng bộ LifeStage từ Vợ: ${state.currentStage} → $syncedStage (raw=$rawStage)',
              );
              final uid = (_listenerUid != null && _listenerUid!.isNotEmpty)
                  ? _listenerUid!
                  : UserScope.currentUid();
              await _settingsBox.put(_k(AppConstants.keyLifeStage, uid), syncedStage.toStorageString());
              await _settingsBox.put(AppConstants.keyLifeStage, syncedStage.toStorageString());

              // Cập nhật State RAM ngay để kích hoạt reactive rebuild toàn bộ UI
              state = state.copyWith(currentStage: syncedStage, isLoading: false);

              // Cập nhật UserModel hiện tại nếu có Ref
              if (_ref != null) {
                try {
                  _ref.read(authControllerProvider.notifier).updateLifeStage(stage: syncedStage);
                } catch (_) {}
              }
            }
          }
        }
      }, onError: (e) {
        debugPrint('[LifeStageController] Lỗi stream couple: $e');
      });
    } catch (e) {
      debugPrint('[LifeStageController] startListeningToCouple skipped: $e');
    }
  }

  /// Hủy lắng nghe stream couple (DP-04)
  void cancelCoupleSubscription() {
    _coupleSubscription?.cancel();
    _coupleSubscription = null;
    debugPrint('[LifeStageController] Đã hủy couple subscription');
  }

  @override
  void dispose() {
    cancelCoupleSubscription();
    super.dispose();
  }

  /// Reset về trạng thái mặc định khi logout.
  /// Chỉ reset RAM — không xóa Hive (dữ liệu thuộc về tài khoản, không phải thiết bị).
  void reset() {
    cancelCoupleSubscription();
    _listenerUid = null;
    state = const LifeStageState.normal();
  }
}

// ════════════════════════════════════════════════════════════════════════════
// PROVIDERS
// ════════════════════════════════════════════════════════════════════════════

/// Provider chính quản lý LifeStage state.
final lifeStageControllerProvider =
    StateNotifierProvider<LifeStageController, LifeStageState>(
  (ref) {
    final controller = LifeStageController(ref: ref);

    // Lắng nghe coupleId và userRole để Chồng tự động lắng nghe couples/{coupleId}
    ref.listen<String?>(savedCoupleIdProvider, (_, coupleId) {
      final role = ref.read(userRoleProvider);
      final effectiveCoupleId = coupleId ?? controller.getSavedCoupleId();
      if (role == UserRole.husband && effectiveCoupleId != null && effectiveCoupleId.isNotEmpty) {
        controller.startListeningToCouple(effectiveCoupleId);
      } else if (effectiveCoupleId == null || effectiveCoupleId.isEmpty) {
        controller.cancelCoupleSubscription();
      }
    });

    ref.listen<UserRole>(userRoleProvider, (_, role) {
      final coupleId = ref.read(savedCoupleIdProvider) ?? controller.getSavedCoupleId();
      if (role == UserRole.husband && coupleId != null && coupleId.isNotEmpty) {
        controller.startListeningToCouple(coupleId);
      } else if (role != UserRole.husband) {
        controller.cancelCoupleSubscription();
      }
    });

    // Khởi tạo ngay nếu đã có coupleId và là Chồng
    final initialCoupleId = ref.read(savedCoupleIdProvider) ?? controller.getSavedCoupleId();
    final initialRole = ref.read(userRoleProvider);
    if (initialRole == UserRole.husband && initialCoupleId != null && initialCoupleId.isNotEmpty) {
      controller.startListeningToCouple(initialCoupleId);
    }

    ref.onDispose(() => controller.dispose());
    return controller;
  },
);

/// Alias theo tài liệu kiến trúc kỹ thuật (Riverpod)
final lifeStageProvider = lifeStageControllerProvider;

// ── Selector providers tiện ích ───────────────────────────────────────────

/// Trả về [LifeStage] hiện tại.
final currentLifeStageProvider = Provider<LifeStage>((ref) {
  return ref.watch(lifeStageControllerProvider).currentStage;
});

/// `true` khi đang ở chế độ Chung Đôi.
final isCoupleModeProvider = Provider<bool>((ref) {
  return ref.watch(currentLifeStageProvider) == LifeStage.couple;
});

/// `true` khi chế độ sống hiện tại hỗ trợ tính năng cặp đôi / người đồng hành (tất cả các mode trừ Solo).
/// Tách bạch giữa LifeStage (giai đoạn sinh học) và trạng thái đồng hành.
final supportsCompanionProvider = Provider<bool>((ref) {
  return ref.watch(currentLifeStageProvider).supportsPartner;
});

/// `true` khi đang ở chế độ Nàng (Solo).
final isSoloModeProvider = Provider<bool>((ref) {
  return ref.watch(currentLifeStageProvider) == LifeStage.solo;
});

/// `true` khi đang ở chế độ Chuẩn Bị Bầu (Conception).
final isConceptionModeProvider = Provider<bool>((ref) {
  return ref.watch(currentLifeStageProvider) == LifeStage.conception;
});

/// `true` khi đang ở chế độ Thai Kỳ.
final isPregnancyModeProvider = Provider<bool>((ref) {
  return ref.watch(currentLifeStageProvider) == LifeStage.pregnancy;
});

/// `true` khi đang ở chế độ Nuôi Con.
final isMotherhoodModeProvider = Provider<bool>((ref) {
  return ref.watch(currentLifeStageProvider) == LifeStage.motherhood;
});

/// `true` khi Pause/Loss Mode đang kích hoạt.
final isPausedModeProvider = Provider<bool>((ref) {
  return ref.watch(lifeStageControllerProvider).isPaused;
});

/// `true` khi chu kỳ kinh nguyệt đang bị tạm ẩn (thai kỳ hoặc nuôi con).
/// Dùng cho DP-05 Cycle Logic Isolation và LAM algorithm.
final isCyclePredictionPausedProvider = Provider<bool>((ref) {
  return ref.watch(currentLifeStageProvider).cyclePredictionPaused;
});

/// `true` khi đang ở giai đoạn có bé (thai kỳ hoặc nuôi con).
final isBabyPhaseProvider = Provider<bool>((ref) {
  final stage = ref.watch(currentLifeStageProvider);
  return stage == LifeStage.pregnancy || stage == LifeStage.motherhood;
});
