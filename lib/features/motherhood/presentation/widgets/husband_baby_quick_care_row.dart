// lib/features/motherhood/presentation/widgets/husband_baby_quick_care_row.dart
//
// Thanh tác vụ nhanh của Bố Bỉm (Husband Baby Quick Care Row):
// Bố ghi nhanh 1-chạm: "Đã cho bú bình", "Đã thay tã sạch", "Đã ru bé ngủ"
// Tự động gán loggedByRole: 'husband' và đồng bộ trực tiếp sang máy Mẹ qua Firestore.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:herflow/core/constants/app_colors.dart';
import 'package:herflow/core/utils/haptic_feedback_utils.dart';
import 'package:herflow/features/motherhood/domain/models/baby_activity_log_model.dart';
import 'package:herflow/features/motherhood/presentation/controllers/baby_log_controller.dart';
import 'package:herflow/features/motherhood/presentation/controllers/child_profile_controller.dart';

class HusbandBabyQuickCareRow extends ConsumerWidget {
  final bool isDark;
  final String partnerName;

  const HusbandBabyQuickCareRow({
    super.key,
    required this.isDark,
    required this.partnerName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeChild = ref.watch(activeChildProvider);
    final childId = activeChild?.childId ?? 'default_child';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('👨‍🍼', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              'Bố Đỡ Đần Cùng $partnerName (Ghi Nhanh 1-Chạm)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // 1. Đã cho bú bình
            Expanded(
              child: _buildDadActionButton(
                context,
                ref,
                icon: '🍼',
                title: 'Cho bú bình',
                subtitle: '90ml sữa',
                color: AppColors.primary,
                onTap: () async {
                  AppHaptics.medium();
                  await ref.read(babyLogControllerProvider.notifier).quickLogFeeding(
                        childId: childId,
                        type: FeedingType.bottleBreastMilk,
                        amountMl: 90,
                        notes: 'Bố cho bú bình đỡ mẹ',
                        userRole: 'husband',
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('🍼 Bố vừa cho bé bú bình 90ml! Đã đồng bộ sang máy $partnerName 💕'),
                        backgroundColor: AppColors.primary,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 8),

            // 2. Đã thay tã sạch
            Expanded(
              child: _buildDadActionButton(
                context,
                ref,
                icon: '🧷',
                title: 'Đã thay tã',
                subtitle: 'Tã sạch thơm',
                color: AppColors.accentPeach,
                onTap: () async {
                  AppHaptics.medium();
                  await ref.read(babyLogControllerProvider.notifier).quickLogDiaper(
                        childId: childId,
                        type: DiaperType.clean,
                        notes: 'Bố thay tã sạch cho bé',
                        userRole: 'husband',
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('🧷 Bố vừa thay tã sạch cho con! Đã đồng bộ sang máy $partnerName 💕'),
                        backgroundColor: AppColors.accentPeach,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 8),

            // 3. Đã ru bé ngủ
            Expanded(
              child: _buildDadActionButton(
                context,
                ref,
                icon: '😴',
                title: 'Đã ru ngủ',
                subtitle: 'Bé đã say giấc',
                color: AppColors.secondary,
                onTap: () async {
                  AppHaptics.medium();
                  final now = DateTime.now();
                  await ref.read(babyLogControllerProvider.notifier).quickLogSleep(
                        childId: childId,
                        startTime: now.subtract(const Duration(minutes: 30)),
                        endTime: now,
                        durationMinutes: 30,
                        notes: 'Bố ru bé ngủ sâu',
                        userRole: 'husband',
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('😴 Bố vừa ru bé ngủ ngon! Đã đồng bộ sang máy $partnerName 💕'),
                        backgroundColor: AppColors.secondary,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDadActionButton(
    BuildContext context,
    WidgetRef ref, {
    required String icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: isDark ? color.withAlpha(25) : color.withAlpha(20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(60), width: 1.2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
