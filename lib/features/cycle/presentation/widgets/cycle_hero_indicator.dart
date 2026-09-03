// lib/features/cycle/presentation/widgets/cycle_hero_indicator.dart
import 'package:flutter/material.dart';
import 'package:herflow/core/constants/app_colors.dart';
import '../../domain/entities/cycle_day_info.dart';

/// Widget Vòng tròn Hero thể hiện ngày chu kỳ và pha sinh học
class CycleHeroIndicator extends StatelessWidget {
  final CycleDayInfo dayInfo;
  final int daysLeft;
  final int daysLate;

  const CycleHeroIndicator({
    super.key,
    required this.dayInfo,
    required this.daysLeft,
    this.daysLate = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final phase = dayInfo.phase;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: phase.color.withAlpha(isDark ? 80 : 50),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: phase.color.withAlpha(isDark ? 35 : 20),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      child: Column(
        children: [
          // Vòng tròn sinh học trung tâm
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 164,
                height: 164,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: phase.backgroundColor.withAlpha(isDark ? 60 : 180),
                ),
              ),
              Container(
                width: 144,
                height: 144,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: phase.color.withAlpha(180),
                    width: 3.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(phase.icon, color: phase.color, size: 26),
                    const SizedBox(height: 2),
                    Text(
                      'Ngày ${dayInfo.cycleDay}',
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: phase.color,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      phase.shortTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: phase.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Tagline sinh học
          Text(
            phase.tagline,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
            ),
          ),

          const SizedBox(height: 14),

          // Badge thông tin: Số ngày đến kỳ tiếp theo & Khả năng thụ thai
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              if (daysLate > 0)
                _buildBadge(
                  context,
                  icon: Icons.schedule_rounded,
                  label: 'Trễ kinh $daysLate ngày',
                  color: Colors.orange,
                )
              else
                _buildBadge(
                  context,
                  icon: Icons.hourglass_top_rounded,
                  label: daysLeft > 0 ? '$daysLeft ngày nữa tới kỳ mới' : 'Đang trong kỳ',
                  color: AppColors.primary,
                ),
              _buildBadge(
                context,
                icon: Icons.child_care_rounded,
                label: 'Thụ thai: ${dayInfo.conceptionProbability.split(' ').first}',
                color: AppColors.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 40 : 25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
