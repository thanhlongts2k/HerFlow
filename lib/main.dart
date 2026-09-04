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
import 'core/storage/hive_migration_validator.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/biometric_lock_screen.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  // Mở các Box lưu trữ cần thiết
  await Hive.openBox(AppConstants.cycleBoxName);
  await Hive.openBox(AppConstants.moodBoxName);
  await Hive.openBox(AppConstants.settingsBoxName);
  await Hive.openBox(AppConstants.userBoxName);
  await Hive.openBox(AppConstants.motherhoodBoxName);

  // DP-01: Chạy Hive Migration trước khi bất kỳ provider nào đọc dữ liệu.
  // Bọc try-catch phòng thủ: migration lỗi thì app vẫn chạy fallback an toàn.
  try {
    final settingsBox = Hive.box(AppConstants.settingsBoxName);
    final userBox     = Hive.box(AppConstants.userBoxName);
    // Lấy UID nếu user đã từng đăng nhập (có thể rỗng = lần đầu cài app)
    final existingUid = userBox.get(AppConstants.keyUserUid) as String? ?? '';
    await HiveMigrationValidator.runMigrations(
      settingsBox: settingsBox,
      uid: existingUid,
    );
  } catch (e) {
    // Migration lỗi KHÔNG crash app — chỉ log để debug
    debugPrint('[main] HiveMigration error (safe fallback): $e');
  }

  // Khởi tạo Firebase
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

  // Kiểm tra trạng thái xác thực và phân vai trò
  final userBox = Hive.box(AppConstants.userBoxName);
  final settingsBox = Hive.box(AppConstants.settingsBoxName);

  final isLoggedIn = userBox.get(AppConstants.keyUserIsLoggedIn, defaultValue: false) as bool;
  bool hasSelectedRole = settingsBox.get(AppConstants.keyHasSelectedRole, defaultValue: false) as bool;
  bool isOnboardingCompleted =
      settingsBox.get(AppConstants.keyIsOnboardingCompleted, defaultValue: false) as bool;

  // Khôi phục vai trò từ Cloud Firestore trong nền (non-blocking để không gây trễ / màn hình đen lúc khởi động)
  final uid = userBox.get(AppConstants.keyUserUid) as String? ?? FirebaseAuth.instance.currentUser?.uid;
  if ((isLoggedIn || FirebaseAuth.instance.currentUser != null) && uid != null && uid.isNotEmpty) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get()
        .timeout(const Duration(seconds: 4))
        .then((doc) async {
      if (doc.exists && doc.data() != null) {
        final cloudRole = doc.data()?['role'] as String?;
        if (cloudRole != null && (cloudRole == 'wife' || cloudRole == 'husband')) {
          await settingsBox.put('app_user_role', cloudRole);
          await settingsBox.put('partner_user_role', cloudRole);
          await settingsBox.put(AppConstants.keyHasSelectedRole, true);
          await settingsBox.put(AppConstants.keyIsOnboardingCompleted, true);
        }
      }
    }).catchError((e) {
      debugPrint('Cloud role background sync notice: $e');
    });
  }

  String initialRoute;
  if (!isLoggedIn) {
    initialRoute = AppRoutes.login;
  } else if (!hasSelectedRole) {
    initialRoute = AppRoutes.roleSelection;
  } else if (!isOnboardingCompleted) {
    initialRoute = AppRoutes.onboarding;
  } else {
    initialRoute = AppRoutes.home;
  }

  runApp(
    ProviderScope(
      child: MoonaApp(initialRoute: initialRoute),
    ),
  );
}

class MoonaApp extends ConsumerWidget {
  final String initialRoute;

  const MoonaApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      initialRoute: initialRoute,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      builder: (context, child) {
        return BiometricLockScreen(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

