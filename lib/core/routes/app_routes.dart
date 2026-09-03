// lib/core/routes/app_routes.dart
import 'package:flutter/material.dart';
import '../../features/home/presentation/screens/main_nav_screen.dart';

/// Định nghĩa các tuyến đường điều hướng trong HerFlow
class AppRoutes {
  AppRoutes._();

  static const String home = '/';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
      default:
        return MaterialPageRoute(
          builder: (_) => const MainNavScreen(),
          settings: settings,
        );
    }
  }
}
