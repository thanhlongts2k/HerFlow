// lib/features/lifecycle/presentation/widgets/maternal_health_summary_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:herflow/core/constants/app_colors.dart';
import 'package:herflow/core/utils/haptic_feedback_utils.dart';
import 'package:herflow/features/lifecycle/domain/services/maternal_calculator_service.dart';
import 'package:herflow/features/lifecycle/presentation/controllers/pregnancy_controller.dart';
import 'package:herflow/features/lifecycle/presentation/widgets/maternal_profile_sheet.dart';

/// Thẻ Hồ Sơ Thể Trạng & Dải Tăng Cân Chuẩn IOM trên PregnancyHomeScreen
///
/// Hỗ trợ cơ chế Thu thập dữ liệu theo tiến trình (Progressive Profiling):
/// - Khi chưa điền đủ: hiển thị thanh % tiến trình hoàn thiện và nút CTA.
/// - Khi đã điền đủ: hiển thị BMI tiền thai kỳ, dải cân nặng khuyến nghị cho tuần thai hiện tại và lời khuyên y khoa cá nhân hóa.
class MaternalHealthSummaryCard extends ConsumerWidget {
  final int currentWeek;
  final bool isDark;

  const MaternalHealthSummaryCard({
    super.key,
    required this.currentWeek,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(maternalProfileProvider);
    final eval = ref.watch(maternalEvaluationProvider);

    final isBiometricsComplete = profile?.isBiometricsComplete ?? false;
    final completionPct = profile?.completionPercentage ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF221C35).withAlpha(180) : Colors.white.withAlpha(220),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(22) : AppColors.primary.withAlpha(25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withAlpha(60) : Colors.black.withAlpha(12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: isBiometricsComplete && eval != null
          ? _buildCompletedContent(context, theme, profile!, eval)
          : _buildIncompleteContent(context, theme, completionPct),
    );
  }

  /// Trạng thái 1: Chưa hoàn thiện hồ sơ thể trạng (< 100% biometrics)
  Widget _buildIncompleteContent(
    BuildContext context,
    ThemeData theme,
    int completionPct,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(isDark ? 40 : 25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.assignment_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Hồ Sơ Thể Trạng Của Mẹ',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(isDark ? 45 : 20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Đã xong $completionPct%',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Thanh tiến trình
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: completionPct / 100.0,
            minHeight: 6,
            backgroundColor: isDark ? Colors.white12 : Colors.black.withAlpha(15),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        const SizedBox(height: 12),

        Text(
          'Cập nhật chiều cao, cân nặng và năm sinh để HerFlow tính toán chuẩn IOM và dải tăng cân an toàn cho bạn.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark ? Colors.white70 : Colors.black87,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),

        // Nút mở modal hoàn thiện
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              AppHaptics.selection();
              MaternalProfileSheet.show(context);
            },
            icon: const Icon(Icons.edit_note_rounded, size: 18),
            label: const Text('Hoàn thiện hồ sơ thể trạng'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary.withAlpha(120)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  /// Trạng thái 2: Đã hoàn thiện dữ liệu sinh học -> Thể hiện dải IOM & lời khuyên
  Widget _buildCompletedContent(
    BuildContext context,
    ThemeData theme,
    dynamic profile,
    MaternalEvaluationResult eval,
  ) {
    final bmiCategory = eval.bmiCategory ?? IomBmiCategory.normal;
    final ageTier = eval.ageTier ?? MaternalAgeTier.standard;
    final gainRange = eval.weeklyGainRange;
    final gainStatus = eval.gainStatus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(isDark ? 40 : 25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Thể Trạng & Cân Nặng Thai Kỳ',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              tooltip: 'Chỉnh sửa hồ sơ',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                AppHaptics.selection();
                MaternalProfileSheet.show(context);
              },
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Badges: BMI ban đầu & Tuổi mẹ
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: bmiCategory.color.withAlpha(isDark ? 35 : 20),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: bmiCategory.color.withAlpha(70)),
              ),
              child: Text(
                'BMI trước bầu: ${eval.bmi ?? "--"} (${bmiCategory.label})',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: bmiCategory.color,
                ),
              ),
            ),
            if (eval.age != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: ageTier.color.withAlpha(isDark ? 35 : 20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: ageTier.color.withAlpha(70)),
                ),
                child: Text(
                  'Mẹ ${eval.age} tuổi • ${ageTier.label}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: ageTier.color,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),

        // Dải tăng cân khuyến nghị cho tuần hiện tại (chuẩn IOM)
        if (gainRange != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black.withAlpha(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dải tăng cân chuẩn IOM tuần $currentWeek:',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        gainRange.formattedRange,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (eval.actualGainKg != null) ...[
                  Container(
                    height: 36,
                    width: 1,
                    color: isDark ? Colors.white24 : Colors.black12,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Thực tế:',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      Text(
                        '${eval.actualGainKg! >= 0 ? "+" : ""}${eval.actualGainKg} kg',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: gainStatus?.color ?? AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        // Huy hiệu trạng thái tăng cân (nếu đã có ghi nhận)
        if (gainStatus != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: gainStatus.color.withAlpha(isDark ? 30 : 18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(gainStatus.icon, size: 15, color: gainStatus.color),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    gainStatus.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: gainStatus.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Banner lời khuyên y khoa cá nhân hóa
        if (eval.clinicalTip.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withAlpha(isDark ? 35 : 20),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withAlpha(40)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    eval.clinicalTip,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white.withAlpha(220) : const Color(0xFF2D3748),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
