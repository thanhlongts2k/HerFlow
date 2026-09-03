// lib/core/utils/user_scope.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:herflow/core/constants/app_constants.dart';

/// Tiện ích cô lập phạm vi lưu trữ cục bộ theo UID tài khoản (User-Scoped Storage)
/// Đảm bảo dữ liệu cá nhân của các tài khoản trên cùng thiết bị hoàn toàn tách biệt.
class UserScope {
  UserScope._();

  static String? _activeUid;

  /// Thiết lập chủ động UID hiện tại khi đăng nhập để triệt tiêu Race Condition
  static void setActiveUid(String? uid) {
    _activeUid = (uid != null && uid.trim().isNotEmpty) ? uid.trim() : null;
  }

  /// Xóa sạch active UID khi đăng xuất
  static void clear() {
    _activeUid = null;
  }

  /// Lấy UID người dùng hiện tại đang đăng nhập
  static String currentUid() {
    if (_activeUid != null && _activeUid!.isNotEmpty) {
      return _activeUid!;
    }

    try {
      final authUid = FirebaseAuth.instance.currentUser?.uid;
      if (authUid != null && authUid.isNotEmpty) return authUid;

      if (Hive.isBoxOpen(AppConstants.userBoxName)) {
        final box = Hive.box(AppConstants.userBoxName);
        final uid = box.get(AppConstants.keyUserUid) as String?;
        if (uid != null && uid.isNotEmpty) return uid;
      }
    } catch (_) {}
    return '';
  }

  /// Tạo khóa lưu trữ gắn tiền tố UID để chống rò rỉ dữ liệu chéo giữa các tài khoản.
  /// Ví dụ: `UID123_nickname_call_partner`, `UID123_partner_couple_id`.
  static String key(String baseKey, [String? explicitUid]) {
    final uid = (explicitUid != null && explicitUid.isNotEmpty)
        ? explicitUid
        : currentUid();
    return uid.isNotEmpty ? '${uid}_$baseKey' : baseKey;
  }
}
