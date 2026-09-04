// lib/features/home/presentation/screens/main_nav_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:herflow/core/constants/app_colors.dart';
import 'package:herflow/core/constants/user_role.dart';
import 'package:herflow/core/providers/user_role_provider.dart';
import 'package:herflow/core/utils/haptic_feedback_utils.dart';
import 'package:herflow/core/widgets/offline_banner.dart';
import 'package:herflow/features/cycle/presentation/screens/cycle_screen.dart';
import 'package:herflow/features/husband_view/presentation/screens/husband_view_screen.dart';
import 'package:herflow/features/mood/presentation/screens/mood_screen.dart';
import 'package:herflow/features/nutrition/presentation/screens/nutrition_screen.dart';
import 'package:herflow/features/settings/presentation/screens/settings_screen.dart';

import 'package:herflow/core/services/app_update_service.dart';
import 'package:herflow/core/widgets/app_update_dialog.dart';

/// Provider quản lý index tab hiện tại (dùng chung cho cả Vợ và Chồng)
final currentBottomNavIndexProvider = StateProvider<int>((ref) => 0);

class MainNavScreen extends ConsumerStatefulWidget {
  const MainNavScreen({super.key});

  @override
  ConsumerState<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends ConsumerState<MainNavScreen> {
  // ── Danh sách màn hình cho role Vợ ──────────────────────────────────────
  static final List<Widget> _wifeScreens = [
    const CycleScreen(),
    const MoodScreen(),
    const NutritionScreen(),
    const SettingsScreen(),
  ];

  // ── Danh sách màn hình cho role Chồng ───────────────────────────────────
  static final List<Widget> _husbandScreens = [
    const HusbandViewScreen(isWifePreview: false), // Tab 0: Trang chủ Chồng
    const MoodScreen(),                             // Tab 1: Cảm xúc & Tâm trạng nàng
    const NutritionScreen(),                        // Tab 2: Dinh dưỡng & Cẩm nang chăm sóc
    const SettingsScreen(),                         // Tab 3: Cài đặt & Đăng xuất
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final update = await AppUpdateService.checkForUpdate(forceCheck: kDebugMode);
      if (mounted && update != null) {
        AppUpdateDialog.show(context, update);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userRole = ref.watch(userRoleProvider);

    if (userRole == UserRole.husband) {
      return _buildHusbandLayout(context, ref);
    }

    return _buildWifeLayout(context, ref);
  }

  // ── Layout dành cho Chồng (có BottomNav 4 tab) ──────────────────────────
  Widget _buildHusbandLayout(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(currentBottomNavIndexProvider);

    return Scaffold(
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: IndexedStack(
              index: currentIndex,
              children: _husbandScreens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          AppHaptics.selection();
          ref.read(currentBottomNavIndexProvider.notifier).state = index;
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.shield_outlined),
            selectedIcon: Icon(Icons.shield_rounded, color: AppColors.secondary),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border_rounded),
            selectedIcon: Icon(Icons.favorite_rounded, color: AppColors.primary),
            label: 'Cảm xúc',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_outlined),
            selectedIcon: Icon(Icons.restaurant_rounded, color: AppColors.phaseFollicular),
            label: 'Dinh dưỡng',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded, color: AppColors.primary),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }

  // ── Layout dành cho Vợ (có BottomNav 4 tab chu kỳ) ──────────────────────
  Widget _buildWifeLayout(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(currentBottomNavIndexProvider);

    return Scaffold(
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: IndexedStack(
              index: currentIndex,
              children: _wifeScreens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          AppHaptics.selection();
          ref.read(currentBottomNavIndexProvider.notifier).state = index;
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded, color: AppColors.primary),
            label: 'Chu kỳ',
          ),
          NavigationDestination(
            icon: Icon(Icons.mood_outlined),
            selectedIcon: Icon(Icons.mood_rounded, color: AppColors.secondary),
            label: 'Cảm xúc',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_outlined),
            selectedIcon: Icon(Icons.restaurant_rounded, color: AppColors.phaseFollicular),
            label: 'Dinh dưỡng',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded, color: AppColors.primary),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }
}
