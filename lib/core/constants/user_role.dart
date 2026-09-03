// lib/core/constants/user_role.dart

/// Vai trò người dùng trong ứng dụng Moona
enum UserRole {
  /// Vợ — Theo dõi chu kỳ cá nhân, tâm trạng, dinh dưỡng, gửi tín hiệu yêu thương
  wife,

  /// Chồng — Đồng hành cùng vợ, nhận realtime status, tuyệt chiêu quan tâm, phản hồi 1 chạm
  husband,
}

extension UserRoleExt on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.wife:
        return 'Vợ (Theo dõi chu kỳ)';
      case UserRole.husband:
        return 'Chồng (Đồng hành cùng nàng)';
    }
  }

  String get shortName {
    switch (this) {
      case UserRole.wife:
        return 'Vợ';
      case UserRole.husband:
        return 'Chồng';
    }
  }

  String get emoji {
    switch (this) {
      case UserRole.wife:
        return '🌸';
      case UserRole.husband:
        return '🛡️';
    }
  }

  bool get isWife => this == UserRole.wife;
  bool get isHusband => this == UserRole.husband;
}
