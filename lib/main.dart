// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/constants/app_constants.dart';
import 'core/notifications/notification_service.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/biometric_lock_screen.dart';

import 'core/theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khóa hướng màn hình dọc (Portrait mode)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Khởi tạo định dạng ngày tháng tiếng Việt
  await initializeDateFormatting('vi', null);

  // Khởi tạo cơ sở dữ liệu cục bộ Hive (Offline-first)
  await Hive.initFlutter();

  // Mở các Box lưu trữ dữ liệu an toàn trên máy
  await Future.wait([
    Hive.openBox(AppConstants.cycleBoxName),
    Hive.openBox(AppConstants.moodBoxName),
    Hive.openBox(AppConstants.settingsBoxName),
  ]);

  // Khởi tạo Firebase phòng thủ ngoại lệ
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  // Khởi tạo NotificationService và kênh thông báo PMS
  try {
    await NotificationService.instance.initialize();
  } catch (e) {
    debugPrint('NotificationService init notice: $e');
  }

  // Kiểm tra trạng thái hoàn thành Onboarding
  final settingsBox = Hive.box(AppConstants.settingsBoxName);
  final isOnboardingCompleted =
      settingsBox.get(AppConstants.keyIsOnboardingCompleted, defaultValue: false) as bool;

  runApp(
    ProviderScope(
      child: MoonaApp(isOnboardingCompleted: isOnboardingCompleted),
    ),
  );
}

class MoonaApp extends ConsumerWidget {
  final bool isOnboardingCompleted;

  const MoonaApp({super.key, required this.isOnboardingCompleted});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      initialRoute: isOnboardingCompleted ? AppRoutes.home : AppRoutes.onboarding,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      builder: (context, child) {
        return BiometricLockScreen(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

