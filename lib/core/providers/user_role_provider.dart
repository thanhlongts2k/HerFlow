// lib/core/providers/user_role_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:herflow/core/constants/app_constants.dart';
import 'package:herflow/core/constants/user_role.dart';

/// Quản lý trạng thái Vai trò người dùng (Vợ / Chồng) với đồng bộ Hive
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

  /// Cập nhật vai trò mới và lưu vào Hive
  Future<void> setRole(UserRole role) async {
    state = role;
    await _settingsBox.put(keyAppUserRole, role.name);
    // Đồng bộ sang partner_user_role của PartnerSyncRepository
    await _settingsBox.put('partner_user_role', role.name);
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
