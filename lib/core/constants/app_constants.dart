// lib/core/constants/app_constants.dart

/// Các hằng số cấu hình hệ thống và Box Hive lưu trữ của Moona
class AppConstants {
  AppConstants._();

  // App Metadata
  static const String appName = 'Moona';
  static const String appVersion = '0.3.0';
  static const String appTagline = 'Chu Kỳ • Cảm Xúc • Dinh Dưỡng Phụ Nữ';

  // Hive Box Names
  static const String cycleBoxName = 'herflow_cycle_box';
  static const String moodBoxName = 'herflow_mood_box';
  static const String nutritionBoxName = 'herflow_nutrition_box';
  static const String settingsBoxName = 'herflow_settings_box';
  static const String userBoxName = 'herflow_user_box';

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
  static const String keyIsOnboardingCompleted = 'is_onboarding_completed';
  static const String keyIsBiometricEnabled = 'is_biometric_enabled';
  static const String keyOnboardingGoal = 'onboarding_goal';
  static const String keyHasSelectedRole = 'has_selected_role';

  // Key User Profile
  static const String keyUserUid = 'user_uid';
  static const String keyUserDisplayName = 'user_display_name';
  static const String keyUserEmail = 'user_email';
  static const String keyUserPhotoUrl = 'user_photo_url';
  static const String keyUserIsLoggedIn = 'user_is_logged_in';
}
