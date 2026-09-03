// lib/features/auth/presentation/controllers/auth_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:herflow/core/constants/user_role.dart';
import 'package:herflow/core/providers/user_role_provider.dart';
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
      if (user.role != null) {
        final role = user.role == 'husband' ? UserRole.husband : UserRole.wife;
        _ref.read(userRoleProvider.notifier).setRole(role, uid: user.uid);
      }
      _checkCloudRoleAsync(user.uid);
    }
  }

  Future<void> _checkCloudRoleAsync(String uid) async {
    try {
      final cloudRole = await _repository.getUserRoleFromFirestore(uid);
      if (cloudRole != null && (cloudRole == 'husband' || cloudRole == 'wife')) {
        final role = cloudRole == 'husband' ? UserRole.husband : UserRole.wife;
        await _ref.read(userRoleProvider.notifier).setRole(role, uid: uid);
        final current = state.valueOrNull;
        if (current != null && current.role != cloudRole) {
          state = AsyncValue.data(current.copyWith(role: cloudRole));
        }
      }
    } catch (e) {
      // Ignore background sync errors
    }
  }

  Future<UserModel?> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.signInWithGoogle();
      if (user != null && user.role != null) {
        final role = user.role == 'husband' ? UserRole.husband : UserRole.wife;
        await _ref.read(userRoleProvider.notifier).setRole(role, uid: user.uid);
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
      if (user.role != null) {
        final role = user.role == 'husband' ? UserRole.husband : UserRole.wife;
        await _ref.read(userRoleProvider.notifier).setRole(role, uid: user.uid);
      }
      state = AsyncValue.data(user);
      return user;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _repository.signOut();
      await _ref.read(userRoleProvider.notifier).resetRole();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
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
