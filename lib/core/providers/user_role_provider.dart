// lib/core/providers/user_role_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:herflow/core/constants/app_constants.dart';
import 'package:herflow/core/constants/user_role.dart';

/// Quản lý trạng thái Vai trò người dùng (Vợ / Chồng) với đồng bộ 2 chiều Hive + Cloud Firestore
class UserRoleNotifier extends StateNotifier<UserRole> {
  final Box _settingsBox;

  static const String keyAppUserRole = 'app_user_role';

  UserRoleNotifier(this._settingsBox) : super(_loadInitialRole(_settingsBox));

  static UserRole _loadInitialRole(Box box) {
    final saved = box.get(keyAppUserRole);
    if (saved == UserRole.husband.name || saved == 'husband') {
      return UserRole.husband;
    }
    if (saved == UserRole.wife.name || saved == 'wife') {
      return UserRole.wife;
    }
    // Fallback: Kiểm tra partner_user_role
    final partnerRole = box.get('partner_user_role');
    if (partnerRole == 'husband') {
      return UserRole.husband;
    }
    // Mặc định ban đầu là Vợ
    return UserRole.wife;
  }

  /// Cập nhật vai trò mới, lưu vào Hive cục bộ và đẩy lên Cloud Firestore document users/{uid}
  Future<void> setRole(UserRole role, {String? uid}) async {
    state = role;
    await _settingsBox.put(keyAppUserRole, role.name);
    await _settingsBox.put('partner_user_role', role.name);
    await _settingsBox.put(AppConstants.keyHasSelectedRole, true);

    // Đồng bộ tức thì lên Firestore nếu có định danh tài khoản người dùng
    final effectiveUid = (uid != null && uid.isNotEmpty)
        ? uid
        : FirebaseAuth.instance.currentUser?.uid;

    if (effectiveUid != null && effectiveUid.isNotEmpty) {
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
  Future<void> resetRole() async {
    state = UserRole.wife;
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
