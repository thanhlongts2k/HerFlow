// lib/features/motherhood/presentation/widgets/husband_motherhood_companion_card.dart
//
// Thẻ Tóm tắt Nuôi Con dành cho Bố Bỉm (Husband Motherhood Companion Card).
// Hiển thị trên màn hình Góc Nhìn Bố Bỉm (HusbandViewScreen):
// - Trạng thái của bé: Tên, ngày tuổi, cữ bú/ngủ/tã gần nhất.
// - Cảnh báo tuần bão tố Wonder Weeks.
// - Lời khuyên tâm lý đỡ đần người thương cữ đêm.

import 'package:flutter/material.dart';
import 'package:herflow/core/constants/app_colors.dart';
import 'package:herflow/features/motherhood/domain/models/child_profile_model.dart';
import 'package:herflow/features/motherhood/domain/models/motherhood_status_model.dart';

class HusbandMotherhoodCompanionCard extends StatelessWidget {
  final MotherhoodStatusModel? status;
  final ChildProfileModel? localChild;
  final bool isDark;
  final String partnerName;

  const HusbandMotherhoodCompanionCard({
    super.key,
    required this.status,
    this.localChild,
    required this.isDark,
    required this.partnerName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final babyName = status?.activeChildName ?? localChild?.name ?? 'Bé yêu';
    final ageDisplay =
        status?.activeChildAgeDisplay ?? localChild?.getAgeDisplay() ?? 'Đang cập nhật';
    final isStorm = status?.isStormPeriod ?? false;
    final leapTitle = status?.currentLeapTitle;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppColors.secondaryDark.withAlpha(90),
                  AppColors.surfaceDark,
                ]
              : [
                  AppColors.secondaryContainer.withAlpha(220),
                  Colors.white,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : AppColors.secondary).withAlpha(20),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: (isDark ? Colors.white : AppColors.secondary).withAlpha(30),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. HEADER: TÊN BÉ VÀ ĐỒNG HÀNH ──
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withAlpha(30),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.secondary,
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: const Text('👶', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            babyName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Bố Bỉm',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ageDisplay,
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

          // ── 2. BA CHỈ SỐ HOẠT ĐỘNG GẦN NHẤT ──
          Row(
            children: [
              // Cữ bú gần nhất
              Expanded(
                child: _buildMetricBox(
                  icon: '🍼',
                  label: 'Bú gần nhất',
                  value: status?.lastFeedingSummary ?? 'Chưa ghi',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),

              // Tã gần nhất
              Expanded(
                child: _buildMetricBox(
                  icon: '🧷',
                  label: 'Tã gần nhất',
                  value: status?.lastDiaperSummary ?? 'Chưa ghi',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),

              // Giấc ngủ
              Expanded(
                child: _buildMetricBox(
                  icon: '😴',
                  label: 'Giấc ngủ',
                  value: status?.lastSleepDurationMinutes != null
                      ? '${status!.lastSleepDurationMinutes}p'
                      : 'Chưa ghi',
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── 3. WONDER WEEKS ALERT CHO BỐ ──
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isStorm
                  ? Colors.deepOrange.withAlpha(isDark ? 30 : 15)
                  : Colors.amber.withAlpha(isDark ? 30 : 15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isStorm
                    ? Colors.deepOrange.withAlpha(80)
                    : Colors.amber.withAlpha(80),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isStorm ? '⚡' : '☀️', style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isStorm
                            ? 'Tuần bão tố ${leapTitle != null ? "($leapTitle)" : ""}'
                            : 'Tuần bình yên của con',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isStorm ? Colors.deepOrange : Colors.amber.shade800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isStorm
                            ? 'Bé đang vào đợt khủng hoảng phát triển, có thể quấy khóc và khó ngủ hơn. Bố hãy kiên nhẫn bế dỗ để $partnerName có thêm giấc ngủ nhé!'
                            : 'Bé đang ở tuần thích nghi tốt. Bố hãy tranh thủ chơi đùa và tương tác mắt cùng con!',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white70 : Colors.black87,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── 4. LỜI KHUYÊN TÂM LÝ CHO BỐ BỈM ──
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withAlpha(8) : Colors.white.withAlpha(160),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black.withAlpha(10),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Gợi ý cho Bố: Hãy xung phong bế vỗ ợ hơi hoặc thay tã sau cữ bú đêm. '
                    'Một cử chỉ san sẻ nhỏ của Bố sẽ giúp $partnerName phục hồi thể lực và cảm thấy luôn được yêu thương.',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.white60 : Colors.black87,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBox({
    required String icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(10) : Colors.white.withAlpha(180),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withAlpha(10),
        ),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white60 : Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
