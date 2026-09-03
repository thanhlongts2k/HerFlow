// lib/features/nutrition/presentation/screens/nutrition_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:herflow/core/constants/app_colors.dart';
import 'package:herflow/core/utils/date_utils.dart';
import 'package:herflow/features/cycle/presentation/controllers/cycle_controller.dart';
import 'package:herflow/features/nutrition/presentation/controllers/nutrition_controller.dart';

/// Màn hình Đề Xuất Dinh Dưỡng Đồng Bộ Chu Kỳ (Cycle-Synced Nutrition)
class NutritionScreen extends ConsumerWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendation = ref.watch(activeNutritionRecommendationProvider);
    final selectedDate = ref.watch(selectedCalendarDateProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final phase = recommendation.phase;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dinh Dưỡng Đồng Bộ',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: AppColors.phaseFollicular,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Gợi ý ăn uống theo ${phase.vietnameseName} (${AppDateUtils.dayMonthFormat.format(selectedDate)})',
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. BANNER PHA SINH HỌC HIỆN TẠI
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: phase.backgroundColor.withAlpha(isDark ? 60 : 180),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: phase.color.withAlpha(isDark ? 80 : 50),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: phase.color.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(phase.icon, color: phase.color, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recommendation.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: phase.color,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          recommendation.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 2. THỰC PHẨM VÀNG NÊN NẠP
            _buildNutritionSection(
              context,
              title: 'Thực phẩm vàng nên ăn',
              icon: Icons.check_circle_outline_rounded,
              iconColor: AppColors.success,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: recommendation.superfoods.map((food) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2D24) : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.success.withAlpha(50)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.eco_rounded, size: 14, color: AppColors.success),
                        const SizedBox(width: 6),
                        Text(
                          food,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF166534),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // 3. THỰC PHẨM NÊN HẠN CHẾ
            _buildNutritionSection(
              context,
              title: 'Món ăn & Đồ uống nên hạn chế',
              icon: Icons.highlight_off_rounded,
              iconColor: AppColors.error,
              child: Column(
                children: recommendation.foodsToAvoid.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.remove_circle_outline, size: 15, color: AppColors.error),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // 4. TRÀ THẢO MỘC & THỨC UỐNG XOA DỊU
            _buildNutritionSection(
              context,
              title: 'Thức uống gợi ý',
              icon: Icons.emoji_food_beverage_rounded,
              iconColor: AppColors.accentPeach,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.accentPeach.withAlpha(isDark ? 30 : 25),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.coffee_rounded, color: AppColors.accentPeach, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        recommendation.teaSuggestion,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF9A3412),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 5. VI CHẤT THEN CHỐT & BỮA ĂN MẪU
            _buildNutritionSection(
              context,
              title: 'Bữa ăn mẫu gợi ý cho hôm nay',
              icon: Icons.restaurant_rounded,
              iconColor: AppColors.secondary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recommendation.sampleMeal,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text(
                        'Vi chất bổ trợ: ',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                      Expanded(
                        child: Text(
                          recommendation.keyNutrients.join(' • '),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: phase.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
