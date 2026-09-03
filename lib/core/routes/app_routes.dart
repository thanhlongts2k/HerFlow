// lib/core/routes/app_routes.dart
import 'package:flutter/material.dart';
import 'package:herflow/features/home/presentation/screens/main_nav_screen.dart';
import 'package:herflow/features/onboarding/presentation/screens/onboarding_screen.dart';

/// Định nghĩa các tuyến đường điều hướng trong Moona
class AppRoutes {
  AppRoutes._();

  static const String home = '/home';
  static const String onboarding = '/onboarding';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case onboarding:
        return MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
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
