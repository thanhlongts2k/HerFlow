// lib/features/motherhood/presentation/widgets/baby_summary_hero_card.dart
//
// Thẻ Hero tổng quan trạng thái hôm nay của bé sơ sinh:
// Tóm tắt cữ bú, giấc ngủ, tã bỉm, tuần khủng hoảng Wonder Weeks và chuẩn tăng trưởng WHO.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:herflow/core/constants/app_colors.dart';
import 'package:herflow/core/utils/haptic_feedback_utils.dart';
import 'package:herflow/features/motherhood/domain/models/child_profile_model.dart';
import 'package:herflow/features/motherhood/domain/models/who_growth_standards.dart';
import 'package:herflow/features/motherhood/domain/models/wonder_weeks_model.dart';
import 'package:herflow/features/motherhood/presentation/controllers/baby_log_controller.dart';
import 'package:herflow/features/motherhood/presentation/controllers/child_profile_controller.dart';

class BabySummaryHeroCard extends ConsumerWidget {
  final ChildProfileModel child;
  final VoidCallback? onSwitchChild;

  const BabySummaryHeroCard({
    super.key,
    required this.child,
    this.onSwitchChild,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final logState = ref.watch(babyLogControllerProvider);
    final childList = ref.watch(childProfileControllerProvider).children;

    final ageWeeks = child.getAgeInWeeks();
    final correctedWeeks = child.getCorrectedAgeInWeeks();
    final leap = WonderWeeksData.getLeapForWeek(correctedWeeks);
    final isStorm = WonderWeeksData.isStormPeriod(correctedWeeks);

    // Chuẩn Z-Score nếu có cân nặng
    String? whoGrowthLabel;
    if (child.birthWeightKg != null && child.birthWeightKg! > 0) {
      final z = WhoGrowthStandards.evaluateWeightZScore(
        weightKg: child.birthWeightKg!,
        ageMonths: child.getAgeInMonths(),
        gender: child.gender,
      );
      whoGrowthLabel = WhoGrowthStandards.getGrowthStatusLabel(z);
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppColors.primaryDark.withAlpha(90),
                  AppColors.surfaceDark,
                ]
              : [
                  AppColors.primaryContainer.withAlpha(220),
                  Colors.white,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : AppColors.primary).withAlpha(18),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: (isDark ? Colors.white : AppColors.primary).withAlpha(25),
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. HÀNG ĐẦU: TÊN BÉ, TUỔI VÀ NÚT ĐỔI BÉ ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar tròn
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: (child.gender == 'girl'
                          ? AppColors.primary
                          : AppColors.secondary)
                      .withAlpha(30),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: child.gender == 'girl'
                        ? AppColors.primary
                        : AppColors.secondary,
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  child.gender == 'girl' ? '👧' : '👶',
                  style: const TextStyle(fontSize: 26),
                ),
              ),
              const SizedBox(width: 14),

              // Tên và ngày tuổi
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            child.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (childList.length > 1) ...[
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () {
                              AppHaptics.selection();
                              onSwitchChild?.call();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(25),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Đổi bé',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  Icon(Icons.keyboard_arrow_down_rounded,
                                      size: 14, color: AppColors.primary),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${child.getAgeDisplay()} • Tuần $ageWeeks'
                      '${child.estimatedDueDate != null ? ' (hiệu chỉnh $correctedWeeks tuần)' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── 2. WONDER WEEKS & WHO BADGES ──
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (leap != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isStorm
                        ? Colors.orange.withAlpha(25)
                        : Colors.amber.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isStorm
                          ? Colors.orange.withAlpha(120)
                          : Colors.amber.withAlpha(120),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(isStorm ? '⚡' : '☀️',
                          style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 5),
                      Text(
                        'Leap ${leap.leapIndex}: ${isStorm ? 'Tuần bão tố' : 'Tuần êm đềm'}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isStorm ? Colors.deepOrange : Colors.amber.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              if (whoGrowthLabel != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.accentMint.withAlpha(35),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.phaseOvulation.withAlpha(120),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('⚖️', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 5),
                      Text(
                        whoGrowthLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.phaseOvulation,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // ── 3. HÀNG 3 THẺ TÓM TẮT TRONG NGÀY (BÚ, NGỦ, TÃ BỈM) ──
          Row(
            children: [
              // Cữ bú
              Expanded(
                child: _buildMetricTile(
                  icon: '🍼',
                  label: 'Cữ bú',
                  value: '${logState.todayFeedingCount} cữ',
                  subtext: logState.lastFeeding != null
                      ? DateFormat('HH:mm').format(logState.lastFeeding!.timestamp)
                      : 'Chưa có',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),

              // Giấc ngủ
              Expanded(
                child: _buildMetricTile(
                  icon: '😴',
                  label: 'Giấc ngủ',
                  value: '${(logState.todaySleepDurationMinutes / 60).toStringAsFixed(1)}h',
                  subtext: logState.lastSleep != null ? 'Đã thức dậy' : 'Chưa ghi',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),

              // Tã bỉm
              Expanded(
                child: _buildMetricTile(
                  icon: '🧷',
                  label: 'Tã bỉm',
                  value: '${logState.todayDiaperCount} lần',
                  subtext: logState.lastDiaper != null
                      ? DateFormat('HH:mm').format(logState.lastDiaper!.timestamp)
                      : 'Chưa có',
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String icon,
    required String label,
    required String value,
    required String subtext,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(10) : Colors.white.withAlpha(190),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withAlpha(12),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white60 : Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: TextStyle(
              fontSize: 9,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
