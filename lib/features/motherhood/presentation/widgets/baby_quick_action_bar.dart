// lib/features/motherhood/presentation/widgets/baby_quick_action_bar.dart
//
// Thanh 4 nút tác vụ nhanh 1-chạm (Quick Action Bar):
// 1. 🍼 Bú sữa (Mở FeedingTimerSheet)
// 2. 😴 Giấc ngủ (Ghi nhanh thời lượng ngủ)
// 3. 🧷 Thay tã (Modal 1-chạm: Ướt, Bẩn, Cả hai)
// 4. ⚖️ Đo bé (Cập nhật Cân nặng / Chiều cao chuẩn WHO)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:herflow/core/constants/app_colors.dart';
import 'package:herflow/core/utils/haptic_feedback_utils.dart';
import 'package:herflow/features/motherhood/domain/models/baby_activity_log_model.dart';
import 'package:herflow/features/motherhood/domain/models/child_profile_model.dart';
import 'package:herflow/features/motherhood/domain/models/who_growth_standards.dart';
import 'package:herflow/features/motherhood/presentation/controllers/baby_log_controller.dart';
import 'package:herflow/features/motherhood/presentation/controllers/child_profile_controller.dart';
import 'package:herflow/features/motherhood/presentation/widgets/feeding_timer_sheet.dart';

class BabyQuickActionBar extends ConsumerWidget {
  final ChildProfileModel child;

  const BabyQuickActionBar({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        // 1. Bú sữa
        Expanded(
          child: _buildActionButton(
            context,
            icon: '🍼',
            label: 'Bú sữa',
            color: AppColors.primary,
            isDark: isDark,
            onTap: () {
              FeedingTimerSheet.show(
                context,
                childId: child.childId,
                childName: child.name,
              );
            },
          ),
        ),
        const SizedBox(width: 10),

        // 2. Giấc ngủ
        Expanded(
          child: _buildActionButton(
            context,
            icon: '😴',
            label: 'Giấc ngủ',
            color: AppColors.secondary,
            isDark: isDark,
            onTap: () => _showSleepQuickSheet(context, ref),
          ),
        ),
        const SizedBox(width: 10),

        // 3. Thay tã
        Expanded(
          child: _buildActionButton(
            context,
            icon: '🧷',
            label: 'Thay tã',
            color: AppColors.accentPeach,
            isDark: isDark,
            onTap: () => _showDiaperQuickSheet(context, ref),
          ),
        ),
        const SizedBox(width: 10),

        // 4. Đo bé (WHO)
        Expanded(
          child: _buildActionButton(
            context,
            icon: '⚖️',
            label: 'Đo bé',
            color: AppColors.phaseOvulation,
            isDark: isDark,
            onTap: () => _showGrowthMeasurementDialog(context, ref),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        AppHaptics.selection();
        onTap();
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? color.withAlpha(25) : color.withAlpha(20),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color.withAlpha(60),
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Modal Ghi nhanh Giấc Ngủ ──────────────────────────────────────────────

  void _showSleepQuickSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Ghi Nhanh Giấc Ngủ Bé 😴',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Chọn thời lượng giấc ngủ gần nhất của bé:',
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildSleepOptionChip(ctx, ref, '30 phút', 30),
                    _buildSleepOptionChip(ctx, ref, '45 phút', 45),
                    _buildSleepOptionChip(ctx, ref, '1 tiếng', 60),
                    _buildSleepOptionChip(ctx, ref, '1.5 tiếng', 90),
                    _buildSleepOptionChip(ctx, ref, '2 tiếng', 120),
                    _buildSleepOptionChip(ctx, ref, '3 tiếng', 180),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSleepOptionChip(
    BuildContext ctx,
    WidgetRef ref,
    String label,
    int minutes,
  ) {
    return ActionChip(
      avatar: const Text('🌙', style: TextStyle(fontSize: 14)),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      onPressed: () async {
        AppHaptics.medium();
        final now = DateTime.now();
        final start = now.subtract(Duration(minutes: minutes));

        await ref.read(babyLogControllerProvider.notifier).quickLogSleep(
              childId: child.childId,
              startTime: start,
              endTime: now,
              durationMinutes: minutes,
            );

        if (ctx.mounted) {
          Navigator.pop(ctx);
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text('😴 Đã ghi nhận giấc ngủ ($label)'),
              backgroundColor: AppColors.secondary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }

  // ── Modal Ghi nhanh Thay Tã ───────────────────────────────────────────────

  void _showDiaperQuickSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Ghi Nhanh Thay Tã 🧷',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Chọn tình trạng tã của bé khi thay:',
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildDiaperOptionButton(
                        ctx,
                        ref,
                        icon: '💧',
                        label: 'Tã ướt',
                        type: DiaperType.wet,
                        color: Colors.lightBlue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildDiaperOptionButton(
                        ctx,
                        ref,
                        icon: '💩',
                        label: 'Tã bẩn',
                        type: DiaperType.dirty,
                        color: Colors.brown,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildDiaperOptionButton(
                        ctx,
                        ref,
                        icon: '🧷',
                        label: 'Cả hai',
                        type: DiaperType.both,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDiaperOptionButton(
    BuildContext ctx,
    WidgetRef ref, {
    required String icon,
    required String label,
    required DiaperType type,
    required Color color,
  }) {
    return InkWell(
      onTap: () async {
        AppHaptics.medium();
        await ref.read(babyLogControllerProvider.notifier).quickLogDiaper(
              childId: child.childId,
              type: type,
            );
        if (ctx.mounted) {
          Navigator.pop(ctx);
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text('🧷 Đã ghi nhận thay $label cho bé'),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(80), width: 1),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // ── Dialog Cập Nhật Cân Nặng / Chiều Cao (WHO) ────────────────────────────

  void _showGrowthMeasurementDialog(BuildContext context, WidgetRef ref) {
    final weightCtrl = TextEditingController(
      text: child.birthWeightKg != null ? child.birthWeightKg.toString() : '',
    );
    final heightCtrl = TextEditingController(
      text: child.birthHeightCm != null ? child.birthHeightCm.toString() : '',
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Text('⚖️', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                'Chỉ Số Bé: ${child.name}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: weightCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Cân nặng hiện tại (kg)',
                  hintText: 'Ví dụ: 6.2',
                  suffixText: 'kg',
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: heightCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Chiều dài / chiều cao (cm)',
                  hintText: 'Ví dụ: 61.5',
                  suffixText: 'cm',
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                AppHaptics.medium();
                final w = double.tryParse(weightCtrl.text.trim());
                final h = double.tryParse(heightCtrl.text.trim());

                final updated = child.copyWith(
                  birthWeightKg: w ?? child.birthWeightKg,
                  birthHeightCm: h ?? child.birthHeightCm,
                  updatedAt: DateTime.now(),
                );

                await ref
                    .read(childProfileControllerProvider.notifier)
                    .updateChild(updated);

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  if (w != null) {
                    final z = WhoGrowthStandards.evaluateWeightZScore(
                      weightKg: w,
                      ageMonths: child.getAgeInMonths(),
                      gender: child.gender,
                    );
                    final status = WhoGrowthStandards.getGrowthStatusLabel(z);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('⚖️ Đã lưu cân nặng $w kg: $status'),
                        backgroundColor: AppColors.phaseOvulation,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Lưu Chỉ Số'),
            ),
          ],
        );
      },
    );
  }
}
