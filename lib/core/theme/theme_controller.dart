// lib/core/theme/theme_controller.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:herflow/core/constants/app_constants.dart';

/// Provider quản lý trạng thái Theme toàn cầu theo thời gian thực (Realtime Theme State)
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(_loadInitialThemeMode());

  /// Đọc theme đã lưu từ Hive settingsBox lúc khởi động
  static ThemeMode _loadInitialThemeMode() {
    try {
      if (!Hive.isBoxOpen(AppConstants.settingsBoxName)) {
        return ThemeMode.system;
      }
      final box = Hive.box(AppConstants.settingsBoxName);
      final saved = box.get(AppConstants.keyThemeMode, defaultValue: 'system') as String;
      switch (saved) {
        case 'light':
          return ThemeMode.light;
        case 'dark':
          return ThemeMode.dark;
        default:
          return ThemeMode.system;
      }
    } catch (_) {
      return ThemeMode.system;
    }
  }

  /// Cập nhật theme: Vừa ghi vào Hive vừa cập nhật state của Riverpod để toàn bộ app đổi màu tức thì
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;

    try {
      final box = Hive.box(AppConstants.settingsBoxName);
      String modeStr;
      switch (mode) {
        case ThemeMode.light:
          modeStr = 'light';
          break;
        case ThemeMode.dark:
          modeStr = 'dark';
          break;
        default:
          modeStr = 'system';
      }
      await box.put(AppConstants.keyThemeMode, modeStr);
    } catch (e) {
      debugPrint('Error saving themeMode: $e');
    }
  }
}
