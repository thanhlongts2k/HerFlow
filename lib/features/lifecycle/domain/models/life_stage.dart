// lib/features/lifecycle/domain/models/life_stage.dart

/// Giai đoạn sống hiện tại của người dùng trong nền tảng Moona.
/// Điều khiển toàn bộ layout, tính năng và điều hướng của ứng dụng.
///
/// KIẾN TRÚC: [Q1] Code tiếng Anh — UI tiếng Việt.
/// Không bao giờ hardcode string tên mode trong UI; luôn dùng `displayName`.
enum LifeStage {
  /// 🌸 Nàng — Theo dõi chu kỳ cá nhân, độc lập, không bắt buộc ghép đôi.
  solo,

  /// 💑 Chung đôi — Đồng bộ realtime vợ-chồng, Care Signals, góc nhìn Chồng.
  couple,

  /// 🥚 Đón bé — Cửa sổ thụ thai, nhiệt độ BBT, nhắc nhở sinh hoạt tối ưu.
  conception,

  /// 🤰 Thai kỳ — Đếm tuần thai, kích thước thai nhi, lịch khám, nhật ký ốm nghén.
  pregnancy,

  /// 🍼 Nuôi con — Hồ sơ đa bé, log bú/ngủ/bỉm, biểu đồ tăng trưởng WHO.
  motherhood,
}

extension LifeStageExt on LifeStage {
  // ── Hiển thị UI (tiếng Việt) ────────────────────────────────────────────

  /// Tên hiển thị tiếng Việt trên giao diện người dùng.
  String get displayName {
    switch (this) {
      case LifeStage.solo:        return 'Nàng';
      case LifeStage.couple:      return 'Chung Đôi';
      case LifeStage.conception:  return 'Đón Bé';
      case LifeStage.pregnancy:   return 'Thai Kỳ';
      case LifeStage.motherhood:  return 'Nuôi Con';
    }
  }

  /// Mô tả ngắn hiển thị trong màn hình chọn chế độ.
  String get description {
    switch (this) {
      case LifeStage.solo:
        return 'Theo dõi chu kỳ cá nhân, bảo mật riêng tư, không cần ghép đôi.';
      case LifeStage.couple:
        return 'Đồng bộ realtime với người thương. Tín hiệu yêu thương & góc nhìn Chồng.';
      case LifeStage.conception:
        return 'Cửa sổ thụ thai chuyên sâu, theo dõi nhiệt độ BBT và lịch quan hệ tối ưu.';
      case LifeStage.pregnancy:
        return 'Hành trình thai kỳ theo tuần. Kích thước bé, lịch khám và nhật ký ốm nghén.';
      case LifeStage.motherhood:
        return 'Hồ sơ nhiều bé. Nhật ký bú/ngủ/bỉm, biểu đồ tăng trưởng chuẩn WHO.';
    }
  }

  /// Emoji đại diện cho chế độ (dùng trong UI, notification, log).
  String get icon {
    switch (this) {
      case LifeStage.solo:        return '🌸';
      case LifeStage.couple:      return '💑';
      case LifeStage.conception:  return '🥚';
      case LifeStage.pregnancy:   return '🤰';
      case LifeStage.motherhood:  return '🍼';
    }
  }

  // ── Feature flags (kiểm soát module nào được kích hoạt) ─────────────────

  /// Có cần kết nối Couple module (coupleId, Care Signals, HusbandView) không?
  bool get requiresCoupleModule => this == LifeStage.couple;

  /// Có cần module Conception (BBT, Fertile Window) không?
  bool get requiresConceptionModule => this == LifeStage.conception;

  /// Có cần module Pregnancy (tuần thai, lịch khám) không?
  bool get requiresPregnancyModule => this == LifeStage.pregnancy;

  /// Có cần module Motherhood (hồ sơ bé, nhật ký sơ sinh) không?
  bool get requiresMotherhoodModule => this == LifeStage.motherhood;

  // ── Chu kỳ kinh nguyệt ──────────────────────────────────────────────────

  /// Có theo dõi chu kỳ kinh nguyệt không?
  /// Thai kỳ và nuôi con không hiển thị dự báo chu kỳ hoạt động.
  bool get tracksMenstrualCycle {
    switch (this) {
      case LifeStage.solo:
      case LifeStage.couple:
      case LifeStage.conception:
        return true;
      case LifeStage.pregnancy:
      case LifeStage.motherhood:
        return false;
    }
  }

  /// Chu kỳ có bị tạm ẩn (không cảnh báo trễ kinh) không?
  /// Dùng cho DP-05 Cycle Logic Isolation và LAM Algorithm.
  bool get cyclePredictionPaused {
    switch (this) {
      case LifeStage.pregnancy:
      case LifeStage.motherhood:
        return true;
      default:
        return false;
    }
  }

  /// Là chế độ cá nhân (không liên quan đến partner module)?
  bool get isPersonalMode {
    switch (this) {
      case LifeStage.solo:
      case LifeStage.conception:
      case LifeStage.pregnancy:
      case LifeStage.motherhood:
        return true;
      case LifeStage.couple:
        return false;
    }
  }

  // ── Thứ tự logic (dùng để sort/display trong onboarding) ────────────────

  /// Thứ tự hiển thị trong màn hình chọn chế độ (0 = đầu tiên).
  int get displayOrder {
    switch (this) {
      case LifeStage.solo:        return 0;
      case LifeStage.couple:      return 1;
      case LifeStage.conception:  return 2;
      case LifeStage.pregnancy:   return 3;
      case LifeStage.motherhood:  return 4;
    }
  }

  // ── Serialization ────────────────────────────────────────────────────────

  /// Chuyển từ string sang enum, an toàn với giá trị không hợp lệ.
  /// Default fallback: [LifeStage.solo]
  static LifeStage fromString(String? value) {
    if (value == null || value.isEmpty) return LifeStage.solo;
    return LifeStage.values.firstWhere(
      (s) => s.name == value,
      orElse: () => LifeStage.solo,
    );
  }

  /// Chuyển từ enum về string để lưu Hive/Firestore.
  String toStorageString() => name;
}
