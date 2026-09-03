// lib/features/auth/presentation/controllers/auth_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:herflow/core/constants/user_role.dart';
import 'package:herflow/core/providers/user_role_provider.dart';
import 'package:herflow/core/utils/user_scope.dart';
import 'package:herflow/features/care_signals/presentation/controllers/care_signal_controller.dart';
import 'package:herflow/features/cycle/presentation/controllers/cycle_controller.dart';
import 'package:herflow/features/home/presentation/screens/main_nav_screen.dart';
import 'package:herflow/features/partner_sync/presentation/controllers/partner_sync_controller.dart';
import 'package:herflow/features/settings/domain/models/nickname_config.dart';
import 'package:herflow/features/settings/presentation/controllers/nickname_controller.dart';
import '../../data/auth_repository.dart';
import '../../domain/models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthController extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthRepository _repository;
  final Ref _ref;

  AuthController(this._repository, this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    final user = _repository.getCurrentUser();
    state = AsyncValue.data(user);
    if (user != null) {
      UserScope.setActiveUid(user.uid);
      if (user.role != null) {
        final role = user.role == 'husband' ? UserRole.husband : UserRole.wife;
        _ref.read(userRoleProvider.notifier).setRole(role, uid: user.uid);
      }
      _restoreUserDataFromCloud(user.uid);
    } else {
      UserScope.clear();
    }
  }

  /// Lớp 3: Nạp toàn bộ dữ liệu chuẩn từ Cloud Firestore vào local cache và RAM State khi đăng nhập
  Future<void> _restoreUserDataFromCloud(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 4));

      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          // 1. Phục hồi vai trò
          final cloudRole = data['role'] as String?;
          if (cloudRole != null && (cloudRole == 'husband' || cloudRole == 'wife')) {
            final role = cloudRole == 'husband' ? UserRole.husband : UserRole.wife;
            await _ref.read(userRoleProvider.notifier).setRole(role, uid: uid);
            final current = state.valueOrNull;
            if (current != null && current.role != cloudRole) {
              state = AsyncValue.data(current.copyWith(role: cloudRole));
            }
          }

          // 2. Phục hồi ghép đôi coupleId
          final cloudCoupleId = data['coupleId'] as String?;
          if (cloudCoupleId != null && cloudCoupleId.isNotEmpty) {
            await _ref.read(partnerSyncRepositoryProvider).saveCoupleId(cloudCoupleId, uid);
            _ref.read(savedCoupleIdProvider.notifier).state = cloudCoupleId;
          } else {
            _ref.read(savedCoupleIdProvider.notifier).state = null;
          }

          // 3. Phục hồi danh xưng
          if (data['nicknames'] != null) {
            final map = Map<String, dynamic>.from(data['nicknames'] as Map);
            final config = NicknameConfig.fromMap(map);
            await _ref.read(nicknameConfigProvider.notifier).applyConfig(config, uid);
          } else {
            await _ref.read(nicknameConfigProvider.notifier).loadForUser(uid);
          }
        }
      } else {
        // Tài khoản hoàn toàn mới trên Firestore -> bảo đảm trạng thái mặc định tinh khôi
        _ref.read(savedCoupleIdProvider.notifier).state = null;
        await _ref.read(nicknameConfigProvider.notifier).loadForUser(uid);
      }

      // Làm tươi Cycle state cho user mới
      _ref.invalidate(cycleControllerProvider);
    } catch (e) {
      debugPrint('Restore user data from Cloud notice: $e');
      _ref.read(savedCoupleIdProvider.notifier).state =
          _ref.read(partnerSyncRepositoryProvider).getSavedCoupleId(uid);
      await _ref.read(nicknameConfigProvider.notifier).loadForUser(uid);
      _ref.invalidate(cycleControllerProvider);
    }
  }

  Future<UserModel?> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.signInWithGoogle();
      if (user != null) {
        // 1. Cập nhật ngay lập tức active UID vào UserScope TRƯỚC KHI các provider khác đọc
        UserScope.setActiveUid(user.uid);

        // 2. Invalidate triệt để các controller để đảm bảo xóa trắng bộ nhớ RAM của tài khoản trước
        _invalidateAllUserScopedProviders();

        if (user.role != null) {
          final role = user.role == 'husband' ? UserRole.husband : UserRole.wife;
          await _ref.read(userRoleProvider.notifier).setRole(role, uid: user.uid);
        }
        await _restoreUserDataFromCloud(user.uid);
      }
      state = AsyncValue.data(user);
      return user;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<UserModel> signInAsDemo({
    String displayName = 'Người Dùng Moona',
    String email = 'user@moona.app',
    String? photoUrl,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.signInAsDemo(
        displayName: displayName,
        email: email,
        photoUrl: photoUrl,
      );

      // 1. Cập nhật ngay active UID vào UserScope
      UserScope.setActiveUid(user.uid);

      // 2. Invalidate triệt để các controller
      _invalidateAllUserScopedProviders();

      if (user.role != null) {
        final role = user.role == 'husband' ? UserRole.husband : UserRole.wife;
        await _ref.read(userRoleProvider.notifier).setRole(role, uid: user.uid);
      }
      await _restoreUserDataFromCloud(user.uid);
      state = AsyncValue.data(user);
      return user;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Lớp 2: Complete Logout Purge - Xóa sạch RAM, dọn dẹp Hive và Invalidate TOÀN BỘ Providers
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      // 1. Xóa active UID khỏi UserScope
      UserScope.clear();

      // 2. Xóa sạch session trong Hive
      await _repository.signOut();

      // 3. Reset vai trò và ghép đôi
      await _ref.read(userRoleProvider.notifier).resetRole();

      // 4. Invalidate triệt để mọi Provider trong RAM để không lưu vết object cũ
      _invalidateAllUserScopedProviders();

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Làm tươi toàn bộ State Tree gắn liền với người dùng
  void _invalidateAllUserScopedProviders() {
    _ref.invalidate(userRoleProvider);
    _ref.invalidate(savedCoupleIdProvider);
    _ref.invalidate(savedUserRoleProvider);
    _ref.invalidate(isPairedProvider);
    _ref.invalidate(nicknameConfigProvider);
    _ref.invalidate(cycleControllerProvider);
    _ref.invalidate(selectedCycleDayInfoProvider);
    _ref.invalidate(partnerSyncControllerProvider);
    _ref.invalidate(partnerLiveStatusStreamProvider);
    _ref.invalidate(latestCareSignalStreamProvider);
    _ref.invalidate(currentBottomNavIndexProvider);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<UserModel?>>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthController(repo, ref);
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authControllerProvider).valueOrNull;
});

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});
