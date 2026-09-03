// lib/core/providers/user_role_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:herflow/core/constants/app_constants.dart';
import 'package:herflow/core/constants/user_role.dart';
import 'package:herflow/core/utils/user_scope.dart';

/// Quản lý trạng thái Vai trò người dùng (Vợ / Chồng) với đồng bộ 2 chiều Hive + Cloud Firestore
/// Đã được gắn phạm vi UserScope để chống nhận nhầm vai trò giữa các tài khoản khác nhau trên cùng máy.
class UserRoleNotifier extends StateNotifier<UserRole> {
  final Box _settingsBox;

  static const String keyAppUserRole = 'app_user_role';

  UserRoleNotifier(this._settingsBox) : super(_loadInitialRole(_settingsBox));

  static UserRole _loadInitialRole(Box box) {
    final uid = UserScope.currentUid();
    final scoped = box.get(UserScope.key(keyAppUserRole, uid));
    if (scoped == UserRole.husband.name || scoped == 'husband') {
      return UserRole.husband;
    }
    if (scoped == UserRole.wife.name || scoped == 'wife') {
      return UserRole.wife;
    }

    final saved = box.get(keyAppUserRole);
    if (saved == UserRole.husband.name || saved == 'husband') {
      return UserRole.husband;
    }
    if (saved == UserRole.wife.name || saved == 'wife') {
      return UserRole.wife;
    }

    // Mặc định ban đầu là Vợ
    return UserRole.wife;
  }

  /// Cập nhật vai trò mới, lưu vào Hive cục bộ (user-scoped) và đẩy lên Cloud Firestore document users/{uid}
  Future<void> setRole(UserRole role, {String? uid}) async {
    state = role;
    final effectiveUid = (uid != null && uid.isNotEmpty)
        ? uid
        : UserScope.currentUid();

    await _settingsBox.put(UserScope.key(keyAppUserRole, effectiveUid), role.name);
    await _settingsBox.put(UserScope.key(AppConstants.keyHasSelectedRole, effectiveUid), true);
    await _settingsBox.put(keyAppUserRole, role.name);
    await _settingsBox.put(AppConstants.keyHasSelectedRole, true);

    // Đồng bộ tức thì lên Firestore nếu có định danh tài khoản người dùng
    if (effectiveUid.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(effectiveUid).set({
          'role': role.name,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)).timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('UserRoleNotifier: Sync role to Firestore notice: $e');
      }
    }
  }

  /// Đặt lại vai trò về mặc định và dọn sạch cache cục bộ (khi Đăng xuất)
  Future<void> resetRole([String? explicitUid]) async {
    state = UserRole.wife;
    final uid = explicitUid ?? UserScope.currentUid();
    await _settingsBox.delete(UserScope.key(keyAppUserRole, uid));
    await _settingsBox.delete(UserScope.key(AppConstants.keyHasSelectedRole, uid));
    await _settingsBox.delete(UserScope.key(AppConstants.keyIsOnboardingCompleted, uid));

    // Dọn dẹp cả legacy non-prefixed
    await _settingsBox.delete(keyAppUserRole);
    await _settingsBox.delete('partner_user_role');
    await _settingsBox.delete(AppConstants.keyHasSelectedRole);
    await _settingsBox.delete(AppConstants.keyIsOnboardingCompleted);
  }

  /// Chuyển đổi nhanh qua lại giữa Vợ và Chồng (phục vụ test và chuyển đổi linh hoạt)
  Future<void> toggleRole() async {
    final nextRole = state == UserRole.wife ? UserRole.husband : UserRole.wife;
    await setRole(nextRole);
  }
}

/// Provider vai trò người dùng hiện tại
final userRoleProvider = StateNotifierProvider<UserRoleNotifier, UserRole>((ref) {
  final box = Hive.box(AppConstants.settingsBoxName);
  return UserRoleNotifier(box);
});
