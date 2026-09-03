// lib/features/cycle/presentation/widgets/cycle_day_detail_card.dart
import 'package:flutter/material.dart';
import 'package:herflow/core/constants/app_colors.dart';
import 'package:herflow/core/utils/date_utils.dart';
import '../../domain/entities/cycle_day_info.dart';

/// Thẻ thông tin sinh học chi tiết cho ngày đang được chọn trên lịch
class CycleDayDetailCard extends StatelessWidget {
  final CycleDayInfo dayInfo;
  final VoidCallback onTogglePeriod;

  const CycleDayDetailCard({
    super.key,
    required this.dayInfo,
    required this.onTogglePeriod,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final phase = dayInfo.phase;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: phase.color.withAlpha(isDark ? 80 : 50),
        ),
      ),
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tiêu đề: Ngày chọn & Pha sinh học
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppDateUtils.formatHeaderDate(dayInfo.date),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Ngày thứ ${dayInfo.cycleDay} của chu kỳ',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: phase.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: phase.backgroundColor.withAlpha(isDark ? 70 : 180),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: phase.color.withAlpha(80)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(phase.icon, size: 14, color: phase.color),
                      const SizedBox(width: 4),
                      Text(
                        phase.shortTitle,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: phase.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 12),

            // 1. Thụ thai & Hormone
            _buildInsightRow(
              context,
              icon: Icons.bubble_chart_rounded,
              iconColor: AppColors.secondary,
              label: 'Khả năng thụ thai:',
              value: dayInfo.conceptionProbability,
            ),
            const SizedBox(height: 10),
            _buildInsightRow(
              context,
              icon: Icons.science_rounded,
              iconColor: phase.color,
              label: 'Biến chuyển hormone:',
              value: dayInfo.hormoneStatus,
            ),
            const SizedBox(height: 10),

            // 2. Gợi ý vận động
            _buildInsightRow(
              context,
              icon: Icons.fitness_center_rounded,
              iconColor: AppColors.phaseOvulation,
              label: 'Vận động tối ưu:',
              value: dayInfo.workoutTip,
            ),

            const SizedBox(height: 16),

            // 3. Nút 1-chạm Toggle ngày hành kinh
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onTogglePeriod,
                icon: Icon(
                  dayInfo.isPeriodDay ? Icons.remove_circle_outline : Icons.water_drop_rounded,
                  size: 18,
                ),
                label: Text(
                  dayInfo.isPeriodDay
                      ? 'Hủy đánh dấu ngày hành kinh này'
                      : 'Đánh dấu là ngày hành kinh',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: dayInfo.isPeriodDay
                      ? (isDark ? Colors.red.withAlpha(50) : const Color(0xFFFEE2E2))
                      : AppColors.primary,
                  foregroundColor: dayInfo.isPeriodDay ? Colors.red : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              text: '$label ',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.textTheme.bodyMedium?.color,
              ),
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
