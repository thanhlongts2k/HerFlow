// lib/features/home/presentation/screens/main_nav_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:herflow/core/constants/app_colors.dart';
import 'package:herflow/core/utils/haptic_feedback_utils.dart';
import 'package:herflow/core/widgets/offline_banner.dart';
import 'package:herflow/features/cycle/presentation/screens/cycle_screen.dart';
import 'package:herflow/features/husband_view/presentation/screens/husband_view_screen.dart';
import 'package:herflow/features/mood/presentation/screens/mood_screen.dart';
import 'package:herflow/features/nutrition/presentation/screens/nutrition_screen.dart';

/// Quản lý Tab Navigation chính của ứng dụng Moona
final currentBottomNavIndexProvider = StateProvider<int>((ref) => 0);

class MainNavScreen extends ConsumerWidget {
  const MainNavScreen({super.key});

  static final List<Widget> _screens = [
    const CycleScreen(),
    const MoodScreen(),
    const NutritionScreen(),
    const HusbandViewScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(currentBottomNavIndexProvider);

    return Scaffold(
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: IndexedStack(
              index: currentIndex,
              children: _screens,
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
            icon: Icon(Icons.favorite_outline_rounded),
            selectedIcon: Icon(Icons.favorite_rounded, color: AppColors.primary),
            label: 'Góc nhìn anh',
          ),
        ],
      ),
    );
  }
}
