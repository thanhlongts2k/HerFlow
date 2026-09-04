// lib/features/lifecycle/presentation/screens/pregnancy_home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:herflow/core/constants/app_colors.dart';
import 'package:herflow/core/utils/haptic_feedback_utils.dart';
import 'package:herflow/core/widgets/moona_confirm_dialog.dart';
import 'package:herflow/features/lifecycle/domain/models/fetal_week_data.dart';
import 'package:herflow/features/lifecycle/domain/services/pregnancy_calculator_service.dart';
import 'package:herflow/features/lifecycle/presentation/controllers/life_stage_controller.dart';
import 'package:herflow/features/lifecycle/presentation/controllers/pregnancy_controller.dart';
import 'package:herflow/features/lifecycle/presentation/widgets/kick_counter_sheet.dart';
import 'package:herflow/features/lifecycle/presentation/widgets/maternal_health_summary_card.dart';
import 'package:herflow/features/lifecycle/presentation/widgets/prenatal_appointments_card.dart';
import 'package:herflow/features/lifecycle/presentation/widgets/pregnancy_setup_sheet.dart';

/// Màn hình chính Theo Dõi Thai Kỳ (Pregnancy Mode Dashboard).
///
/// Thay thế màn hình Chu kỳ khi người dùng ở giai đoạn LifeStage.pregnancy.
/// Bao gồm:
/// - Gestational Hero Card: Tuổi thai, tam cá nguyệt, đếm ngược ngày sinh D-Day, progress bar.
/// - Week Carousel / Selector: Cho phép khám phá từ tuần 1 đến tuần 40.
/// - Fetal Comparison Card: Emoji hoa quả so sánh, chiều dài/cân nặng, cột mốc của con, mẹo cho mẹ.
/// - Healing Mode View: Chế độ chữa lành khi isPaused == true (DP Safeguard).
/// - Empty State: Hướng dẫn thiết lập ngày dự sinh khi chưa có cấu hình.
class PregnancyHomeScreen extends ConsumerStatefulWidget {
  const PregnancyHomeScreen({super.key});

  @override
  ConsumerState<PregnancyHomeScreen> createState() => _PregnancyHomeScreenState();
}

class _PregnancyHomeScreenState extends ConsumerState<PregnancyHomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _weekSelectorController = ScrollController();

  /// Tuần đang được người dùng chọn xem trước trên Carousel (1..40).
  /// Nếu là null, mặc định hiển thị tuần hiện tại theo tính toán thai kỳ.
  int? _selectedWeekOverride;

  @override
  void dispose() {
    _scrollController.dispose();
    _weekSelectorController.dispose();
    super.dispose();
  }

  /// Cuộn week selector đến vị trí tuần được chọn
  void _scrollToSelectedWeek(int week) {
    if (!_weekSelectorController.hasClients) return;
    // Mỗi item tuần rộng ~64px + 8px margin = ~72px
    final targetOffset = ((week - 1) * 72.0) - 100.0;
    _weekSelectorController.animateTo(
      targetOffset.clamp(0.0, _weekSelectorController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  /// Bật/Tắt chế độ Tạm Dừng & Chữa Lành (Pause/Loss Mode)
  Future<void> _handleTogglePauseMode(bool currentIsPaused) async {
    AppHaptics.selection();
    if (!currentIsPaused) {
      final confirmed = await MoonaConfirmDialog.show(
        context,
        title: 'Tạm Dừng Chế Độ Thai Kỳ?',
        message:
            'Chế độ này sẽ ẩn toàn bộ thông tin em bé, đếm ngược ngày sinh và các thông báo tuần thai. '
            'HerFlow sẽ chuyển sang giao diện Chữa Lành & Nghỉ Ngơi để đồng hành chăm sóc sức khỏe cho bạn.',
        icon: Icons.spa_outlined,
        confirmText: 'Bật chế độ Chữa Lành',
        cancelText: 'Hủy',
        isDestructive: false,
      );
      if (confirmed == true && mounted) {
        await ref.read(lifeStageControllerProvider.notifier).setPauseMode(
              isPaused: true,
              reason: 'personal',
            );
      }
    } else {
      final confirmed = await MoonaConfirmDialog.show(
        context,
        title: 'Tiếp Tục Theo Dõi Thai Kỳ?',
        message: 'Bạn có muốn quay lại theo dõi hành trình lớn lên của bé yêu không?',
        icon: Icons.favorite_rounded,
        confirmText: 'Tiếp tục theo dõi',
        cancelText: 'Đóng',
      );
      if (confirmed == true && mounted) {
        await ref.read(lifeStageControllerProvider.notifier).setPauseMode(isPaused: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final pregnancyConfig = ref.watch(pregnancyConfigProvider);
    final ageResult = ref.watch(currentGestationalAgeProvider);
    final lifeStageState = ref.watch(lifeStageControllerProvider);
    final isPaused = lifeStageState.isPaused;

    // Nếu chưa có cấu hình thai kỳ hoặc đã tắt tracking -> Hiển thị Empty State
    if (pregnancyConfig == null || !pregnancyConfig.isTrackingActive) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: _buildEmptyState(context, isDark),
        ),
      );
    }

    // Nếu đang ở chế độ Chữa Lành (Pause Mode) -> Hiển thị Healing View
    if (isPaused) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context, isDark, isPaused: true),
                const SizedBox(height: 20),
                _buildHealingView(context, isDark),
              ],
            ),
          ),
        ),
      );
    }

    // Tuần thai thực tế của bé (1..40)
    final actualWeekOrdinal = (ageResult?.currentWeekOrdinal ?? 1).clamp(1, 40);
    // Tuần đang hiển thị trên UI (có thể do user chọn xem trước)
    final displayWeek = (_selectedWeekOverride ?? actualWeekOrdinal).clamp(1, 40);
    final isViewingDifferentWeek = _selectedWeekOverride != null && _selectedWeekOverride != actualWeekOrdinal;
    final fetalData = FetalWeekData.getWeekData(displayWeek);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header Bar
              _buildHeader(context, isDark, isPaused: false),
              const SizedBox(height: 18),

              // 2. Thẻ Hero "Hành Trình Thai Kỳ"
              if (ageResult != null) ...[
                _buildHeroCard(context, isDark, ageResult, pregnancyConfig.estimatedDueDate),
                const SizedBox(height: 20),
              ],

              // 2.2. Thẻ Hồ Sơ Thể Trạng Mẹ Bầu & Chuẩn Tăng Cân IOM
              MaternalHealthSummaryCard(
                currentWeek: actualWeekOrdinal,
                isDark: isDark,
              ),
              const SizedBox(height: 20),

              // 3. Bộ chuyển tuần thai (Week Carousel / Selector)
              _buildWeekSelectorSection(
                context,
                isDark,
                currentWeek: actualWeekOrdinal,
                selectedWeek: displayWeek,
                isViewingDifferentWeek: isViewingDifferentWeek,
              ),
              const SizedBox(height: 16),

              // 4. Thẻ "Bé Yêu Tuần Này" (Fetal Comparison Card)
              _buildFetalComparisonCard(
                context,
                isDark,
                fetalData: fetalData,
                displayWeek: displayWeek,
                isActualWeek: displayWeek == actualWeekOrdinal,
              ),
              const SizedBox(height: 20),

              // 5. Thẻ Lời nhắn nhủ cho mẹ (Mom Tips & Cột mốc vàng)
              _buildMomTipsCard(context, isDark, fetalData),
              const SizedBox(height: 20),

              // 6. Nút Bộ Đếm Cử Động Thai (hiển thị nổi bật từ tuần 28 trở đi)
              _buildKickCounterBanner(
                context,
                isDark,
                currentWeek: actualWeekOrdinal,
              ),
              const SizedBox(height: 20),

              // 7. Lịch Khám Thai Mốc Vàng
              PrenatalAppointmentsCard(
                currentWeek: actualWeekOrdinal,
                isDark: isDark,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Kick Counter Banner ─────────────────────────────────────────────────────
  /// Banner / nút mở bộ đếm cử động thai.
  /// Từ tuần 28 trở đi sẽ được highlight màu primary với gợi ý nổi bật.
  Widget _buildKickCounterBanner(
    BuildContext context,
    bool isDark, {
    required int currentWeek,
  }) {
    final isHighlighted = currentWeek >= 28;

    return GestureDetector(
      onTap: () {
        AppHaptics.medium();
        KickCounterSheet.show(context);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isHighlighted
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withAlpha(isDark ? 55 : 35),
                    AppColors.primaryLight.withAlpha(isDark ? 40 : 25),
                  ],
                )
              : null,
          color: isHighlighted
              ? null
              : (isDark ? AppColors.cardDark : AppColors.cardLight),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isHighlighted
                ? AppColors.primary.withAlpha(isDark ? 100 : 70)
                : (isDark
                    ? Colors.white.withAlpha(18)
                    : Colors.black.withAlpha(10)),
            width: isHighlighted ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isHighlighted
                  ? AppColors.primary.withAlpha(isDark ? 40 : 25)
                  : Colors.black.withAlpha(isDark ? 25 : 10),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: isHighlighted
                    ? const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                      )
                    : null,
                color: isHighlighted
                    ? null
                    : (isDark ? Colors.white10 : Colors.black.withAlpha(15)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.touch_app_rounded,
                color: isHighlighted
                    ? Colors.white
                    : (isDark ? Colors.white54 : Colors.black45),
                size: 26,
              ),
            ),
            const SizedBox(width: 14),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Đếm Cử Động Thai',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isHighlighted
                              ? AppColors.primary
                              : (isDark ? Colors.white.withAlpha(222) : Colors.black.withAlpha(222)),
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (isHighlighted) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Tuần 28+',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isHighlighted
                        ? 'Bắt đầu đếm ngay! Mục tiêu 10 cử động trong 2 giờ 🩷'
                        : 'Chuẩn Cardiff "Count to 10" — Kích hoạt từ tuần 28',
                    style: TextStyle(
                      fontSize: 12,
                      color: isHighlighted
                          ? (isDark ? Colors.white.withAlpha(178) : AppColors.primaryDark)
                          : (isDark ? Colors.white.withAlpha(115) : Colors.black.withAlpha(115)),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            // Chevron
            Icon(
              Icons.chevron_right_rounded,
              color: isHighlighted
                  ? AppColors.primary
                  : (isDark ? Colors.white30 : Colors.black26),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // ── Header Bar ─────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, bool isDark, {required bool isPaused}) {

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isPaused
                ? AppColors.secondary.withAlpha(isDark ? 50 : 30)
                : AppColors.primary.withAlpha(isDark ? 50 : 25),
            border: Border.all(
              color: isPaused
                  ? AppColors.secondary.withAlpha(isDark ? 100 : 70)
                  : AppColors.primary.withAlpha(isDark ? 100 : 60),
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            isPaused ? '🕊️' : '🌱',
            style: const TextStyle(fontSize: 22),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isPaused ? 'Chế Độ Chữa Lành' : 'Hành Trình Đón Bé',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isPaused
                    ? 'Nghỉ ngơi và hồi phục thể chất'
                    : 'Bé yêu đang lớn lên từng ngày ✨',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        // Nút chỉnh ngày dự sinh
        IconButton(
          onPressed: () {
            AppHaptics.selection();
            PregnancySetupSheet.show(context);
          },
          tooltip: 'Chỉnh ngày dự sinh',
          icon: Icon(
            Icons.edit_calendar_rounded,
            color: isDark ? Colors.white70 : Colors.black54,
            size: 22,
          ),
        ),
        // Nút Tạm Dừng & Chữa Lành (Pause/Loss Mode)
        IconButton(
          onPressed: () => _handleTogglePauseMode(isPaused),
          tooltip: isPaused ? 'Tiếp tục theo dõi' : 'Tạm dừng & Chữa lành',
          icon: Icon(
            isPaused ? Icons.favorite_rounded : Icons.spa_outlined,
            color: isPaused ? AppColors.secondary : (isDark ? Colors.white70 : Colors.black54),
            size: 22,
          ),
        ),
      ],
    );
  }

  // ── Thẻ Hero "Hành Trình Thai Kỳ" ──────────────────────────────────────────
  Widget _buildHeroCard(
    BuildContext context,
    bool isDark,
    GestationalAgeResult ageResult,
    DateTime? dueDate,
  ) {
    // Màu gradient theo Tam cá nguyệt
    final List<Color> gradientColors;
    final Color accentColor;
    final String trimesterTitle;

    switch (ageResult.trimester) {
      case Trimester.first:
        trimesterTitle = 'Tam cá nguyệt 1 • 3 tháng đầu';
        accentColor = const Color(0xFFE91E63);
        gradientColors = isDark
            ? [const Color(0xFF2C1E2E), const Color(0xFF1E1728)]
            : [const Color(0xFFFDF0F6), const Color(0xFFF6EAF8)];
        break;
      case Trimester.second:
        trimesterTitle = 'Tam cá nguyệt 2 • 3 tháng giữa';
        accentColor = const Color(0xFFF57C00);
        gradientColors = isDark
            ? [const Color(0xFF33261A), const Color(0xFF201B18)]
            : [const Color(0xFFFFF8E7), const Color(0xFFFFF0DD)];
        break;
      case Trimester.third:
        trimesterTitle = 'Tam cá nguyệt 3 • 3 tháng cuối';
        accentColor = const Color(0xFF00897B);
        gradientColors = isDark
            ? [const Color(0xFF192B28), const Color(0xFF141F24)]
            : [const Color(0xFFEBF7F5), const Color(0xFFE5F1F8)];
        break;
    }

    final dueDateFormatted = dueDate != null ? DateFormat('dd/MM/yyyy').format(dueDate) : null;
    final percent = (ageResult.progressPercentage * 100).clamp(0, 100);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accentColor.withAlpha(isDark ? 80 : 50),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withAlpha(isDark ? 30 : 20),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge Tam cá nguyệt
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(isDark ? 50 : 25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: accentColor.withAlpha(isDark ? 90 : 60),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 13, color: accentColor),
                    const SizedBox(width: 6),
                    Text(
                      trimesterTitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (dueDateFormatted != null)
                Text(
                  'Dự sinh: $dueDateFormatted',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Số tuần tuổi thai lớn
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'Tuần ${ageResult.currentWeek}',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '+ ${ageResult.currentDayOfWeek} ngày',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Bé đang ở tuần thứ ${ageResult.currentWeekOrdinal} của thai kỳ',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 18),

          // D-Day Countdown Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: (isDark ? Colors.black : Colors.white).withAlpha(isDark ? 90 : 180),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withAlpha(15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(isDark ? 40 : 25),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text('🗓️', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ageResult.daysUntilDue > 0
                            ? 'D-Day: Còn ${ageResult.daysUntilDue} ngày nữa đón con'
                            : (ageResult.daysUntilDue == 0
                                ? 'D-Day: Hôm nay là ngày dự sinh của bé! 🎉'
                                : 'Đã qua ngày dự sinh ${-ageResult.daysUntilDue} ngày'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        'Đã hoàn thành ${percent.toStringAsFixed(1)}% chặng đường',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Progress Bar tiến trình 40 tuần
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: ageResult.progressPercentage.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: isDark ? Colors.white12 : Colors.black12,
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tuần 1',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Tuần 40 (Đón bé)',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Bộ chọn tuần thai (Week Carousel / Selector) ───────────────────────────
  Widget _buildWeekSelectorSection(
    BuildContext context,
    bool isDark, {
    required int currentWeek,
    required int selectedWeek,
    required bool isViewingDifferentWeek,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Hành Trình 40 Tuần',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: -0.2,
              ),
            ),
            if (isViewingDifferentWeek)
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  AppHaptics.light();
                  setState(() {
                    _selectedWeekOverride = null;
                  });
                  _scrollToSelectedWeek(currentWeek);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(isDark ? 40 : 25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withAlpha(isDark ? 90 : 60),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.restart_alt_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Về tuần hiện tại (T.$currentWeek)',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),

        // Carousel cuộn ngang 40 tuần
        SizedBox(
          height: 78,
          child: ListView.separated(
            controller: _weekSelectorController,
            scrollDirection: Axis.horizontal,
            itemCount: 40,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final weekNumber = index + 1;
              final isSelected = weekNumber == selectedWeek;
              final isActual = weekNumber == currentWeek;
              final weekFetal = FetalWeekData.getWeekData(weekNumber);

              return GestureDetector(
                onTap: () {
                  AppHaptics.selection();
                  setState(() {
                    _selectedWeekOverride = weekNumber;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 64,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? const Color(0xFF241D30) : Colors.white),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (isActual
                              ? AppColors.primary.withAlpha(isDark ? 140 : 100)
                              : (isDark ? Colors.white12 : Colors.black12)),
                      width: isActual ? 1.8 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(70),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        weekFetal.fruitEmoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'T.$weekNumber',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : (isActual
                                  ? AppColors.primary
                                  : (isDark ? Colors.white70 : Colors.black87)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Thẻ "Bé Yêu Tuần Này" (Fetal Comparison Card) ──────────────────────────
  Widget _buildFetalComparisonCard(
    BuildContext context,
    bool isDark, {
    required FetalWeekData fetalData,
    required int displayWeek,
    required bool isActualWeek,
  }) {
    final trimesterNum = fetalData.week <= 13 ? 1 : (fetalData.week <= 27 ? 2 : 3);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E182A) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withAlpha(15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 60 : 18),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Badge trạng thái tuần
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isActualWeek
                      ? AppColors.primary.withAlpha(isDark ? 40 : 25)
                      : (isDark ? Colors.white12 : Colors.black.withAlpha(15)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isActualWeek ? 'Tuần hiện tại của bé' : 'Đang xem tuần thứ $displayWeek',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isActualWeek
                        ? AppColors.primary
                        : (isDark ? Colors.white70 : Colors.black54),
                  ),
                ),
              ),
              Text(
                'Tam cá nguyệt $trimesterNum',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Emoji hoa quả phóng to
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withAlpha(isDark ? 30 : 15),
              border: Border.all(
                color: AppColors.primary.withAlpha(isDark ? 70 : 40),
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              fetalData.fruitEmoji,
              style: const TextStyle(fontSize: 48),
            ),
          ),
          const SizedBox(height: 12),

          // Tên quả so sánh
          Text(
            'Bé to bằng ${fetalData.fruitName}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black87,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),

          // 2 Chip thông số kích thước: Chiều dài & Cân nặng
          Row(
            children: [
              Expanded(
                child: _buildMetricChip(
                  context,
                  isDark,
                  icon: '📏',
                  title: 'Chiều dài',
                  value: fetalData.formattedLength,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricChip(
                  context,
                  isDark,
                  icon: '⚖️',
                  title: 'Cân nặng',
                  value: fetalData.formattedWeight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Cột mốc kỳ diệu tuần này (Baby Highlights)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF261F35) : const Color(0xFFF9F7FC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('✨', style: TextStyle(fontSize: 15)),
                    const SizedBox(width: 6),
                    Text(
                      'Cột mốc kỳ diệu tuần này:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  fetalData.babyHighlights,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
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

  Widget _buildMetricChip(
    BuildContext context,
    bool isDark, {
    required String icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF261F35) : const Color(0xFFF7F5FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withAlpha(12),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ── Thẻ Lời nhắn nhủ cho mẹ (Mom Tips) ──────────────────────────────────────
  Widget _buildMomTipsCard(BuildContext context, bool isDark, FetalWeekData fetalData) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E182A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withAlpha(15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withAlpha(isDark ? 40 : 25),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text('💡', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 10),
              Text(
                'Lời khuyên cho mẹ tuần này',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🌱 ', style: TextStyle(fontSize: 13)),
              Expanded(
                child: Text(
                  fetalData.momTip,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Chế độ Chữa Lành & Nghỉ Ngơi (Healing Mode View) ─────────────────────────
  Widget _buildHealingView(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E182A) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.secondary.withAlpha(isDark ? 80 : 50),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withAlpha(isDark ? 25 : 15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.secondary.withAlpha(isDark ? 40 : 25),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text('🕊️', style: TextStyle(fontSize: 36)),
          ),
          const SizedBox(height: 18),
          Text(
            'Không Gian Yên Bình & Chữa Lành',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'HerFlow luôn ở bên bạn. Hãy dành thời gian nghỉ ngơi, lắng nghe cơ thể và vỗ về tâm hồn. '
            'Mọi thông tin thai kỳ và thông báo đã được tạm dừng để bạn có không gian tĩnh lặng nhất.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 22),

          // Lời khuyên hồi phục
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withAlpha(10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gợi ý chăm sóc cho bạn:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('• Uống đủ nước ấm, bổ sung các món hầm dinh dưỡng, thanh đạm.'),
                const SizedBox(height: 4),
                const Text('• Ngủ đủ giấc, giữ ấm cơ thể và hạn chế vận động mạnh.'),
                const SizedBox(height: 4),
                const Text('• Chia sẻ cảm xúc với người thân hoặc chuyên gia tâm lý khi cần.'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Nút tiếp tục theo dõi
          OutlinedButton.icon(
            onPressed: () => _handleTogglePauseMode(true),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.secondary,
              side: const BorderSide(color: AppColors.secondary),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.favorite_rounded, size: 18),
            label: const Text(
              'Tiếp Tục Theo Dõi Thai Kỳ',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty State khi chưa thiết lập thai kỳ ──────────────────────────────────
  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E182A) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.primary.withAlpha(isDark ? 80 : 50),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(isDark ? 30 : 20),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withAlpha(isDark ? 40 : 25),
                ),
                alignment: Alignment.center,
                child: const Text('🌱', style: TextStyle(fontSize: 40)),
              ),
              const SizedBox(height: 20),
              Text(
                'Chào Mừng Đến Với\nHành Trình Thai Kỳ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Thiết lập ngày dự sinh hoặc ngày đầu kỳ kinh cuối để theo dõi 40 tuần phát triển kỳ diệu của con, '
                'kèm so sánh kích thước hoa quả và lời khuyên dinh dưỡng hữu ích.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 26),
              FilledButton.icon(
                onPressed: () {
                  AppHaptics.medium();
                  PregnancySetupSheet.show(context);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.favorite_rounded, size: 18),
                label: const Text(
                  'Bắt Đầu Theo Dõi Thai Kỳ',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
