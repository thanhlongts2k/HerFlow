// lib/core/constants/app_constants.dart

/// Các hằng số cấu hình hệ thống và Box Hive lưu trữ của HerFlow
class AppConstants {
  AppConstants._();

  // App Metadata
  static const String appName = 'HerFlow';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Chu Kỳ • Cảm Xúc • Dinh Dưỡng Phụ Nữ';

  // Hive Box Names
  static const String cycleBoxName = 'herflow_cycle_box';
  static const String moodBoxName = 'herflow_mood_box';
  static const String nutritionBoxName = 'herflow_nutrition_box';
  static const String settingsBoxName = 'herflow_settings_box';

  // Sinh lý chu kỳ mặc định
  static const int defaultCycleLength = 28; // Chu kỳ trung bình 28 ngày
  static const int defaultPeriodDuration = 5; // Thời gian hành kinh trung bình 5 ngày
  static const int minCycleLength = 21;
  static const int maxCycleLength = 45;

  // Key SharedPreferences / Hive Settings
  static const String keyLastPeriodStart = 'last_period_start';
  static const String keyCycleLength = 'cycle_length';
  static const String keyPeriodDuration = 'period_duration';
  static const String keyThemeMode = 'theme_mode';
  static const String keyIsHusbandMode = 'is_husband_mode';
}
