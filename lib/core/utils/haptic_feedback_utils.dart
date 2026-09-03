// lib/core/utils/haptic_feedback_utils.dart
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:herflow/core/constants/app_constants.dart';

/// Tiện ích phản hồi xúc giác (Haptic Feedback) toàn app
/// Kiểm tra trạng thái bật/tắt từ settingsBox trước khi kích hoạt
abstract final class AppHaptics {
  static bool _isEnabled() {
    final box = Hive.box(AppConstants.settingsBoxName);
    return box.get('haptic_enabled', defaultValue: true) as bool;
  }

  /// Rung nhẹ (Light) — dùng cho tap thông thường
  static void light() {
    if (_isEnabled()) HapticFeedback.lightImpact();
  }

  /// Rung trung bình (Medium) — dùng cho xác nhận hành động
  static void medium() {
    if (_isEnabled()) HapticFeedback.mediumImpact();
  }

  /// Rung mạnh (Heavy) — dùng cho cảnh báo hoặc hành động quan trọng
  static void heavy() {
    if (_isEnabled()) HapticFeedback.heavyImpact();
  }

  /// Rung selection — dùng khi thay đổi lựa chọn
  static void selection() {
    if (_isEnabled()) HapticFeedback.selectionClick();
  }
}
