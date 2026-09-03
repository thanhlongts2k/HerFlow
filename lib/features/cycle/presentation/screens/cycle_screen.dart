// lib/features/cycle/presentation/screens/cycle_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:herflow/core/constants/app_colors.dart';
import 'package:herflow/core/utils/date_utils.dart';
import '../controllers/cycle_controller.dart';
import '../widgets/cycle_calendar_view.dart';
import '../widgets/cycle_day_detail_card.dart';
import '../widgets/cycle_hero_indicator.dart';
import '../widgets/cycle_phase_legend.dart';
import '../widgets/cycle_settings_sheet.dart';
import '../widgets/log_period_modal.dart';
import 'package:herflow/features/care_signals/presentation/widgets/care_signal_sheet.dart';

/// Màn hình chính Theo Dõi Chu Kỳ Sinh Học 4 Pha (Cycle Screen)
class CycleScreen extends ConsumerWidget {
  const CycleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cycleAsync = ref.watch(cycleControllerProvider);
    final selectedDate = ref.watch(selectedCalendarDateProvider);
    final dayInfo = ref.watch(selectedCycleDayInfoProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Moona',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              AppDateUtils.formatHeaderDate(DateTime.now()),
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_rounded, color: AppColors.primary),
            tooltip: 'Gửi tín hiệu yêu thương đến chồng',
            onPressed: () => CareSignalSheet.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Tùy chỉnh chu kỳ',
            onPressed: () {
              final cycle = cycleAsync.valueOrNull;
              if (cycle != null) {
                CycleSettingsSheet.show(
                  context,
                  cycle.cycleLength,
                  cycle.periodDuration,
                );
              }
            },
          ),
        ],
      ),
      body: cycleAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(
          child: Text('Lỗi tải dữ liệu: $err'),
        ),
        data: (cycleInfo) {
          final daysLeft = cycleInfo.daysUntilNextPeriod(selectedDate);
          final currentDayInfo = dayInfo ?? cycleInfo.getDayInfo(selectedDate);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. HERO INDICATOR: VÒNG TRÒN TIẾN TRÌNH SINH HỌC
                CycleHeroIndicator(
                  dayInfo: currentDayInfo,
                  daysLeft: daysLeft,
                ),

                const SizedBox(height: 20),

                // 2. LỊCH TƯƠNG TÁC TABLE_CALENDAR 4 PHA
                CycleCalendarView(
                  cycleInfo: cycleInfo,
                  selectedDate: selectedDate,
                  onDateSelected: (newDate) {
                    ref.read(selectedCalendarDateProvider.notifier).state = newDate;
                  },
                ),

                const SizedBox(height: 14),

                // 3. CHÚ THÍCH MÀU SẮC 4 PHA
                const CyclePhaseLegend(),

                const SizedBox(height: 18),

                // 4. THẺ THÔNG TIN CHI TIẾT CHO NGÀY ĐANG CHỌN (INSIGHTS & TOGGLE)
                CycleDayDetailCard(
                  dayInfo: currentDayInfo,
                  onTogglePeriod: () {
                    ref.read(cycleControllerProvider.notifier).togglePeriodDay(selectedDate);
                  },
                ),

                const SizedBox(height: 16),

                // 5. NÚT GHI NHẬN KỲ KINH MỚI CHI TIẾT
                OutlinedButton.icon(
                  onPressed: () => LogPeriodModal.show(context, selectedDate),
                  icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                  label: const Text('Ghi nhận kỳ kinh chi tiết cho ngày này'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}
