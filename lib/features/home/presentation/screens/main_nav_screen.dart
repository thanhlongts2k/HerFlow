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
import 'package:herflow/features/lifecycle/domain/models/life_stage.dart';
import 'package:herflow/features/lifecycle/presentation/controllers/life_stage_controller.dart';
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
  // ── Danh sách màn hình cho role Vợ / Cá nhân ────────────────────────────
  static final List<Widget> _wifeScreens = [
    const CycleScreen(),
    const MoodScreen(),
    const NutritionScreen(),
    const SettingsScreen(),
  ];

  // ── Danh sách màn hình cho role Chồng (Couple Mode) ─────────────────────
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
    final currentStage = ref.watch(currentLifeStageProvider);
    final isCoupleMode = ref.watch(isCoupleModeProvider);

    // DP-03: Khi LifeStage thay đổi, tự động reset currentIndex về 0 (Trang chủ)
    ref.listen<LifeStage>(currentLifeStageProvider, (previous, next) {
      if (previous != next) {
        ref.read(currentBottomNavIndexProvider.notifier).state = 0;
      }
    });

    // Chỉ hiển thị giao diện Chồng khi ĐANG Ở CHẾ ĐỘ COUPLE và có vai trò Chồng
    if (isCoupleMode && userRole == UserRole.husband) {
      return _buildHusbandLayout(context, ref);
    }

    // Các chế độ còn lại (Solo, Conception, Pregnancy, Motherhood, hoặc Vợ trong Couple)
    return _buildWifeLayout(context, ref, currentStage, isCoupleMode);
  }

  // ── Layout dành cho Chồng (có BottomNav 4 tab) ──────────────────────────
  Widget _buildHusbandLayout(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(currentBottomNavIndexProvider);
    // DP-03: Bọc chỉ số an toàn tránh lỗi RangeError
    final safeIndex = currentIndex.clamp(0, _husbandScreens.length - 1);

    return Scaffold(
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: IndexedStack(
              index: safeIndex,
              children: _husbandScreens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeIndex,
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

  // ── Layout dành cho Vợ / Cá nhân ────────────────────────────────────────
  Widget _buildWifeLayout(
    BuildContext context,
    WidgetRef ref,
    LifeStage currentStage,
    bool isCoupleMode,
  ) {
    final currentIndex = ref.watch(currentBottomNavIndexProvider);
    // DP-03: Bọc chỉ số an toàn tránh lỗi RangeError
    final safeIndex = currentIndex.clamp(0, _wifeScreens.length - 1);

    return Scaffold(
      body: Column(
        children: [
          const OfflineBanner(),
          // Banner thông báo cho các mode Phase 2/3 đang hoàn thiện
          if (!isCoupleMode && currentStage != LifeStage.solo)
            _buildPhaseNoticeBanner(context, currentStage),
          Expanded(
            child: IndexedStack(
              index: safeIndex,
              children: _wifeScreens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeIndex,
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

  /// Banner thông báo nhẹ nhàng cho các chế độ chuyên sâu đang trong tiến trình hoàn thiện
  Widget _buildPhaseNoticeBanner(BuildContext context, LifeStage stage) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 2),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(isDark ? 35 : 18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withAlpha(isDark ? 80 : 45),
        ),
      ),
      child: Row(
        children: [
          Text(stage.icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Chế độ ${stage.displayName} (Đang hoàn thiện module)',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  _phaseBannerMessage(stage),
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _phaseBannerMessage(LifeStage stage) {
    switch (stage) {
      case LifeStage.conception:
        return 'Module cửa sổ thụ thai chuyên sâu & canh rụng trứng (Phase 2) đang hoàn thiện.';
      case LifeStage.pregnancy:
        return 'Module theo dõi 40 tuần thai & nhật ký phát triển của bé (Phase 2) đang hoàn thiện.';
      case LifeStage.motherhood:
        return 'Module cữ bú, giấc ngủ & chu kỳ sau sinh LAM (Phase 3) đang hoàn thiện.';
      default:
        return 'Module tính năng chuyên sâu đang được chuẩn bị.';
    }
  }
}
