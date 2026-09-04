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
import 'package:herflow/features/lifecycle/presentation/screens/pregnancy_home_screen.dart';
import 'package:herflow/features/motherhood/presentation/screens/motherhood_home_screen.dart';
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
  // ── Danh sách màn hình cho role Chồng / Bạn đời (Chung Đôi, Chuẩn Bị Bầu, Thai Kỳ, Nuôi Con) ─
  static final List<Widget> _husbandScreens = [
    const HusbandViewScreen(isWifePreview: false), // Tab 0: Trang chủ Chồng / Bố Bầu / Bố Bỉm
    const MoodScreen(),                             // Tab 1: Cảm xúc & Tâm trạng nàng
    const NutritionScreen(),                        // Tab 2: Dinh dưỡng & Cẩm nang chăm sóc
    const SettingsScreen(),                         // Tab 3: Cài đặt & Đăng xuất
  ];

  bool _isPhaseBannerDismissed = false;

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
    final isHusband = userRole == UserRole.husband;

    // DP-03: Khi LifeStage thay đổi, tự động reset currentIndex về 0 (Trang chủ) và hiện lại banner
    ref.listen<LifeStage>(currentLifeStageProvider, (previous, next) {
      if (previous != next) {
        ref.read(currentBottomNavIndexProvider.notifier).state = 0;
        if (mounted) {
          setState(() {
            _isPhaseBannerDismissed = false;
          });
        }
      }
    });

    // 1. Chế độ Nàng (Solo): Độc lập hoàn toàn, không có kết nối hay giao diện Chồng
    if (currentStage == LifeStage.solo) {
      return _buildWifeLayout(context, ref, currentStage);
    }

    // 2. Các giai đoạn có người đồng hành (Chung Đôi, Chuẩn Bị Bầu, Thai Kỳ, Nuôi Con) + Role Chồng:
    // Hiển thị giao diện Chồng với góc nhìn tương ứng (Chồng, Bố Bầu, Bố Bỉm, Bạn Đời)
    if (isHusband) {
      return _buildHusbandLayout(context, ref, currentStage);
    }

    // 3. Các giai đoạn có người đồng hành (Chung Đôi, Chuẩn Bị Bầu, Thai Kỳ, Nuôi Con) + Role Vợ:
    // Hiển thị giao diện Vợ, giữ nguyên kết nối đồng hành realtime nếu đã ghép đôi
    return _buildWifeLayout(context, ref, currentStage);
  }

  // ── Layout dành cho Chồng (có BottomNav 4 tab biến hóa theo LifeStage) ───
  Widget _buildHusbandLayout(
    BuildContext context,
    WidgetRef ref,
    LifeStage currentStage,
  ) {
    final currentIndex = ref.watch(currentBottomNavIndexProvider);
    // DP-03: Bọc chỉ số an toàn tránh lỗi RangeError
    final safeIndex = currentIndex.clamp(0, _husbandScreens.length - 1);

    return Scaffold(
      body: Column(
        children: [
          const OfflineBanner(),
          // Banner thông báo góc nhìn Chồng/Bố Bầu/Bố Bỉm ở các mode Phase 2/3 (an toàn SafeArea)
          if (currentStage != LifeStage.couple && currentStage != LifeStage.solo && !_isPhaseBannerDismissed)
            _buildHusbandPhaseNoticeBanner(context, currentStage),
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
        destinations: [
          NavigationDestination(
            icon: Icon(_getHusbandHomeIcon(currentStage, isSelected: false)),
            selectedIcon: Icon(_getHusbandHomeIcon(currentStage, isSelected: true), color: AppColors.secondary),
            label: _getHusbandHomeLabel(currentStage),
          ),
          const NavigationDestination(
            icon: Icon(Icons.favorite_border_rounded),
            selectedIcon: Icon(Icons.favorite_rounded, color: AppColors.primary),
            label: 'Cảm xúc',
          ),
          const NavigationDestination(
            icon: Icon(Icons.restaurant_outlined),
            selectedIcon: Icon(Icons.restaurant_rounded, color: AppColors.phaseFollicular),
            label: 'Dinh dưỡng',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded, color: AppColors.primary),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }

  // ── Layout dành cho Vợ / Phụ nữ ──────────────────────────────────────────
  Widget _buildWifeLayout(
    BuildContext context,
    WidgetRef ref,
    LifeStage currentStage,
  ) {
    final currentIndex = ref.watch(currentBottomNavIndexProvider);

    // Dynamic screens theo LifeStage: Chế độ Nuôi Con / Thai Kỳ chuyển Tab 0 sang Dashboard tương ứng
    final wifeScreens = [
      currentStage == LifeStage.motherhood
          ? const MotherhoodHomeScreen()
          : currentStage == LifeStage.pregnancy
              ? const PregnancyHomeScreen()
              : const CycleScreen(),
      const MoodScreen(),
      const NutritionScreen(),
      const SettingsScreen(),
    ];

    // DP-03: Bọc chỉ số an toàn tránh lỗi RangeError
    final safeIndex = currentIndex.clamp(0, wifeScreens.length - 1);

    return Scaffold(
      body: Column(
        children: [
          const OfflineBanner(),
          // Banner thông báo cho các mode Phase 2/3 đang hoàn thiện (an toàn SafeArea)
          // Chế độ Thai Kỳ và Nuôi Con đã có Dashboard hoàn thiện, tự động ẩn banner lộ trình này
          if (currentStage != LifeStage.couple &&
              currentStage != LifeStage.solo &&
              currentStage != LifeStage.pregnancy &&
              currentStage != LifeStage.motherhood &&
              !_isPhaseBannerDismissed)
            _buildPhaseNoticeBanner(context, currentStage),
          Expanded(
            child: IndexedStack(
              index: safeIndex,
              children: wifeScreens,
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
        destinations: [
          NavigationDestination(
            icon: Icon(currentStage == LifeStage.motherhood
                ? Icons.child_friendly_outlined
                : currentStage == LifeStage.pregnancy
                    ? Icons.pregnant_woman_outlined
                    : Icons.calendar_month_outlined),
            selectedIcon: Icon(
              currentStage == LifeStage.motherhood
                  ? Icons.child_friendly_rounded
                  : currentStage == LifeStage.pregnancy
                      ? Icons.pregnant_woman_rounded
                      : Icons.calendar_month_rounded,
              color: AppColors.primary,
            ),
            label: currentStage == LifeStage.motherhood
                ? 'Nuôi Con'
                : currentStage == LifeStage.pregnancy
                    ? 'Thai Kỳ'
                    : 'Chu kỳ',
          ),
          const NavigationDestination(
            icon: Icon(Icons.mood_outlined),
            selectedIcon: Icon(Icons.mood_rounded, color: AppColors.secondary),
            label: 'Cảm xúc',
          ),
          const NavigationDestination(
            icon: Icon(Icons.restaurant_outlined),
            selectedIcon: Icon(Icons.restaurant_rounded, color: AppColors.phaseFollicular),
            label: 'Dinh dưỡng',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded, color: AppColors.primary),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }

  // ── Helper cho Tab Chồng / Người đồng hành ──────────────────────────────
  String _getHusbandHomeLabel(LifeStage stage) {
    switch (stage) {
      case LifeStage.pregnancy:
        return 'Bố Bầu';
      case LifeStage.motherhood:
        return 'Bố Bỉm';
      case LifeStage.conception:
        return 'Đồng hành';
      case LifeStage.couple:
      case LifeStage.solo:
        return 'Trang chủ';
    }
  }

  IconData _getHusbandHomeIcon(LifeStage stage, {required bool isSelected}) {
    switch (stage) {
      case LifeStage.pregnancy:
        return isSelected ? Icons.child_care_rounded : Icons.child_care_outlined;
      case LifeStage.motherhood:
        return isSelected ? Icons.family_restroom_rounded : Icons.family_restroom_outlined;
      case LifeStage.conception:
        return isSelected ? Icons.spa_rounded : Icons.spa_outlined;
      case LifeStage.couple:
      case LifeStage.solo:
        return isSelected ? Icons.shield_rounded : Icons.shield_outlined;
    }
  }

  /// Banner thông báo góc nhìn Chồng/Bố Bầu/Bố Bỉm cho các chế độ Phase 2/3
  Widget _buildHusbandPhaseNoticeBanner(BuildContext context, LifeStage stage) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = _getStageBannerTheme(stage, isDark);

    return SafeArea(
      bottom: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: theme.bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.borderColor),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: theme.borderColor.withAlpha(40),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(stage.icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _husbandPhaseBannerTitle(stage),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: theme.titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _husbandPhaseBannerMessage(stage),
                    style: TextStyle(
                      fontSize: 10.5,
                      color: theme.bodyColor,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () {
                AppHaptics.light();
                setState(() {
                  _isPhaseBannerDismissed = true;
                });
              },
              icon: Icon(
                Icons.close_rounded,
                size: 18,
                color: theme.closeIconColor,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
              tooltip: 'Ẩn thông báo',
            ),
          ],
        ),
      ),
    );
  }

  String _husbandPhaseBannerTitle(LifeStage stage) {
    switch (stage) {
      case LifeStage.pregnancy:
        return 'Chế độ Thai Kỳ — Góc nhìn Bố Bầu';
      case LifeStage.motherhood:
        return 'Chế độ Nuôi Con — Góc nhìn Bố Bỉm';
      case LifeStage.conception:
        return 'Chế độ Chuẩn Bị Bầu — Góc nhìn Bạn Đời';
      default:
        return 'Góc nhìn đồng hành';
    }
  }

  String _husbandPhaseBannerMessage(LifeStage stage) {
    switch (stage) {
      case LifeStage.pregnancy:
        return 'Đồng hành cùng vợ theo dõi 40 tuần thai của con, lịch khám và cẩm nang chăm vợ bầu.';
      case LifeStage.motherhood:
        return 'Cùng vợ theo dõi cữ bú, giấc ngủ của con và chia sẻ trách nhiệm chăm sóc bé yêu.';
      case LifeStage.conception:
        return 'Cùng vợ theo dõi cửa sổ thụ thai, ngày rụng trứng và bồi bổ sức khỏe đón con yêu.';
      default:
        return 'Góc nhìn đồng hành cùng người thương.';
    }
  }

  /// Banner thông báo nhẹ nhàng dạng Floating Notice Card cho các chế độ chuyên sâu
  Widget _buildPhaseNoticeBanner(BuildContext context, LifeStage stage) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = _getStageBannerTheme(stage, isDark);

    return SafeArea(
      bottom: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: theme.bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.borderColor),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: theme.borderColor.withAlpha(40),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(stage.icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Chế độ ${stage.displayName} (Đang hoàn thiện module)',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: theme.titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _phaseBannerMessage(stage),
                    style: TextStyle(
                      fontSize: 10.5,
                      color: theme.bodyColor,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () {
                AppHaptics.light();
                setState(() {
                  _isPhaseBannerDismissed = true;
                });
              },
              icon: Icon(
                Icons.close_rounded,
                size: 18,
                color: theme.closeIconColor,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
              tooltip: 'Ẩn thông báo',
            ),
          ],
        ),
      ),
    );
  }

  /// Bảng màu pastel nhẹ nhàng đồng bộ theo từng Mode
  _BannerThemeConfig _getStageBannerTheme(LifeStage stage, bool isDark) {
    switch (stage) {
      case LifeStage.conception:
        // Chuẩn Bị Bầu: Cam / Vàng nhạt pastel
        return _BannerThemeConfig(
          bgColor: isDark
              ? const Color(0xFFFFA726).withAlpha(35)
              : const Color(0xFFFFF8E1),
          borderColor: isDark
              ? const Color(0xFFFFA726).withAlpha(80)
              : const Color(0xFFFFE082),
          titleColor: isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100),
          bodyColor: isDark ? Colors.white70 : const Color(0xFF5D4037),
          closeIconColor: isDark ? Colors.white60 : const Color(0xFF8D6E63),
        );
      case LifeStage.pregnancy:
        // Thai Kỳ: Tím nhạt pastel
        return _BannerThemeConfig(
          bgColor: isDark
              ? const Color(0xFFAB47BC).withAlpha(35)
              : const Color(0xFFF3E5F5),
          borderColor: isDark
              ? const Color(0xFFAB47BC).withAlpha(80)
              : const Color(0xFFCE93D8),
          titleColor: isDark ? const Color(0xFFCE93D8) : const Color(0xFF6A1B9A),
          bodyColor: isDark ? Colors.white70 : const Color(0xFF4A148C),
          closeIconColor: isDark ? Colors.white60 : const Color(0xFF7B1FA2),
        );
      case LifeStage.motherhood:
        // Nuôi Con: Xanh / Hồng pastel nhẹ nhàng
        return _BannerThemeConfig(
          bgColor: isDark
              ? const Color(0xFF26A69A).withAlpha(35)
              : const Color(0xFFE0F2F1),
          borderColor: isDark
              ? const Color(0xFF26A69A).withAlpha(80)
              : const Color(0xFF80CBC4),
          titleColor: isDark ? const Color(0xFF80CBC4) : const Color(0xFF00695C),
          bodyColor: isDark ? Colors.white70 : const Color(0xFF004D40),
          closeIconColor: isDark ? Colors.white60 : const Color(0xFF00796B),
        );
      default:
        return _BannerThemeConfig(
          bgColor: AppColors.primary.withAlpha(isDark ? 35 : 18),
          borderColor: AppColors.primary.withAlpha(isDark ? 80 : 45),
          titleColor: AppColors.primary,
          bodyColor: isDark ? Colors.white70 : Colors.black87,
          closeIconColor: isDark ? Colors.white60 : Colors.black54,
        );
    }
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

class _BannerThemeConfig {
  final Color bgColor;
  final Color borderColor;
  final Color titleColor;
  final Color bodyColor;
  final Color closeIconColor;

  const _BannerThemeConfig({
    required this.bgColor,
    required this.borderColor,
    required this.titleColor,
    required this.bodyColor,
    required this.closeIconColor,
  });
}
