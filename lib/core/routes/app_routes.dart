// lib/core/routes/app_routes.dart
import 'package:flutter/material.dart';
import 'package:herflow/features/auth/presentation/screens/login_screen.dart';
import 'package:herflow/features/backup/presentation/screens/backup_restore_screen.dart';
import 'package:herflow/features/home/presentation/screens/main_nav_screen.dart';
import 'package:herflow/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:herflow/features/onboarding/presentation/screens/role_selection_screen.dart';
import 'package:herflow/features/settings/presentation/screens/settings_screen.dart';

/// Định nghĩa các tuyến đường điều hướng trong Moona
class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String roleSelection = '/role_selection';
  static const String home = '/home';
  static const String onboarding = '/onboarding';
  static const String settings = '/settings';
  static const String backupRestore = '/backup_restore';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
      case roleSelection:
        return MaterialPageRoute(
          builder: (_) => const RoleSelectionScreen(),
          settings: settings,
        );
      case onboarding:
        return MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
          settings: settings,
        );
      case AppRoutes.settings:
        return MaterialPageRoute(
          builder: (_) => const SettingsScreen(),
          settings: settings,
        );
      case backupRestore:
        return MaterialPageRoute(
          builder: (_) => const BackupRestoreScreen(),
          settings: settings,
        );
      case home:
      default:
        return MaterialPageRoute(
          builder: (_) => const MainNavScreen(),
          settings: settings,
        );
    }
  }
}
