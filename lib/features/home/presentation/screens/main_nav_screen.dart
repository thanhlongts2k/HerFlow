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

/// Quản lý Tab Navigation chính của ứng dụng Moona (Dành cho Vợ)
final currentBottomNavIndexProvider = StateProvider<int>((ref) => 0);

class MainNavScreen extends ConsumerWidget {
  const MainNavScreen({super.key});

  static final List<Widget> _wifeScreens = [
    const CycleScreen(),
    const MoodScreen(),
    const NutritionScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRole = ref.watch(userRoleProvider);

    return Stack(
      children: [
        // 1. CẤU TRÚC GIAO DIỆN CHÍNH DỰA THEO VAI TRÒ
        if (userRole == UserRole.husband)
          const Column(
            children: [
              OfflineBanner(),
              Expanded(child: HusbandViewScreen(isWifePreview: false)),
            ],
          )
        else
          _buildWifeLayout(context, ref),

        // 2. NÚT CHUYỂN ROLE NHANH DEBUG (CHỈ HIỆN KHI DEBUG / TEST)
        if (kDebugMode)
          _buildDebugRoleSwitcher(context, ref, userRole),
      ],
    );
  }

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

  Widget _buildDebugRoleSwitcher(
    BuildContext context,
    WidgetRef ref,
    UserRole userRole,
  ) {
    final isWife = userRole == UserRole.wife;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      right: 16,
      // Nằm phía trên BottomBar của Vợ hoặc góc dưới của Chồng
      bottom: isWife ? 92 : 24,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(24),
        color: isWife ? AppColors.primary : AppColors.secondary,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () async {
            AppHaptics.medium();
            await ref.read(userRoleProvider.notifier).toggleRole();
            if (context.mounted) {
              final newRole = ref.read(userRoleProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Đã đổi vai trò: ${newRole.emoji} ${newRole.displayName}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  backgroundColor: newRole.isHusband ? AppColors.secondary : AppColors.primary,
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withAlpha(isDark ? 100 : 180),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  userRole.emoji,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 6),
                Text(
                  'Mode: ${userRole.shortName}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.swap_horiz_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
