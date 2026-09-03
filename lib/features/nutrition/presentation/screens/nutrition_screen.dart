// lib/features/nutrition/presentation/screens/nutrition_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:herflow/core/constants/app_colors.dart';
import 'package:herflow/core/constants/cycle_phase.dart';
import 'package:herflow/core/constants/user_role.dart';
import 'package:herflow/core/providers/user_role_provider.dart';
import 'package:herflow/core/utils/date_utils.dart';
import 'package:herflow/features/cycle/presentation/controllers/cycle_controller.dart';
import 'package:herflow/features/nutrition/presentation/controllers/nutrition_controller.dart';
import 'package:herflow/features/settings/presentation/controllers/nickname_controller.dart';

/// Màn hình Đề Xuất Dinh Dưỡng Đồng Bộ Chu Kỳ (Vợ: Tự chăm sóc; Chồng: Chàng chuẩn bị cho Nàng)
class NutritionScreen extends ConsumerWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendation = ref.watch(activeNutritionRecommendationProvider);
    final selectedDate = ref.watch(selectedCalendarDateProvider);
    final userRole = ref.watch(userRoleProvider);
    final isHusband = userRole == UserRole.husband;
    final nicknameConfig = ref.watch(nicknameConfigProvider);
    final partnerName = nicknameConfig.callPartnerAs.isNotEmpty
        ? nicknameConfig.callPartnerAs
        : (isHusband ? 'Bé iu' : 'Anh');

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final phase = recommendation.phase;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isHusband ? 'Dinh Dưỡng Chăm Sóc Nàng' : 'Dinh Dưỡng Đồng Bộ',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: AppColors.phaseFollicular,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              isHusband
                  ? 'Gợi ý món ăn chàng nên chuẩn bị cho $partnerName (${AppDateUtils.dayMonthFormat.format(selectedDate)})'
                  : 'Gợi ý ăn uống theo ${phase.vietnameseName} (${AppDateUtils.dayMonthFormat.format(selectedDate)})',
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
            // 1. BANNER PHA SINH HỌC HIỆN TẠI (ĐIỀU CHỈNH GÓC NHÌN CHĂM SÓC CHO CHỒNG)
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
                          isHusband ? '$partnerName đang ở ${phase.vietnameseName}' : recommendation.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: phase.color,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isHusband
                              ? _getHusbandAdviceForPhase(phase, partnerName)
                              : recommendation.description,
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

            // 2. THỰC PHẨM NÊN NẠP / CHÀNG NÊN MUA NẤU
            _buildNutritionSection(
              context,
              title: isHusband ? 'Thực phẩm chàng nên mua & nấu cho nàng' : 'Thực phẩm vàng nên ăn',
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
              title: isHusband ? 'Món ăn & Đồ uống nên nhắc nàng tránh xa' : 'Món ăn & Đồ uống nên hạn chế',
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
              title: isHusband ? 'Thức uống chàng nên pha bưng tận tay nàng' : 'Thức uống gợi ý',
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
                        isHusband
                            ? 'Pha ngay cho $partnerName một tách: ${recommendation.teaSuggestion}'
                            : recommendation.teaSuggestion,
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
              title: isHusband ? 'Bữa ăn chàng có thể chuẩn bị hôm nay' : 'Bữa ăn mẫu gợi ý cho hôm nay',
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
                      Text(
                        isHusband ? 'Vi chất nàng cần: ' : 'Vi chất bổ trợ: ',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
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

  static String _getHusbandAdviceForPhase(CyclePhase phase, String partnerName) {
    switch (phase) {
      case CyclePhase.menstrual:
        return 'Cơ thể $partnerName đang mệt mỏi và mất máu. Chàng hãy chủ động chuẩn bị các món ấm, canh hầm bổ máu, tránh để nàng uống nước đá hay đồ lạnh.';
      case CyclePhase.follicular:
        return '$partnerName đang hồi phục và dồi dào sinh lực. Rất thích hợp để chàng đưa nàng đi ăn các món tươi ngon, bổ sung salad và hoa quả giàu vitamin.';
      case CyclePhase.ovulation:
        return 'Năng lượng của $partnerName đạt đỉnh điểm, nàng rạng rỡ và nhiều cảm xúc. Chàng có thể chuẩn bị các bữa tối lãng mạn, bổ sung thực phẩm giàu kẽm và protein.';
      case CyclePhase.luteal:
        return 'Giai đoạn tiền kinh nguyệt (PMS), $partnerName dễ thèm ngọt, đầy hơi và cáu gắt nhẹ. Chàng hãy kiên nhẫn, chuẩn bị ngũ cốc, món thanh đạm và trà ấm.';
    }
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
