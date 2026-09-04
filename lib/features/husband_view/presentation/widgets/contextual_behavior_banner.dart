import 'package:flutter/material.dart';
import 'package:herflow/core/constants/app_colors.dart';
import 'package:herflow/core/constants/cycle_phase.dart';

/// Thẻ "Chế Độ Ứng Xử" Theo Chu Kỳ Sinh Học Của Vợ (Contextual Behavior Mode Banner)
/// Tự động nhận diện giai đoạn chu kỳ của nàng để cung cấp chỉ dẫn tâm lý tức thời cho Chồng.
class ContextualBehaviorBanner extends StatelessWidget {
  final CyclePhase phase;
  final String partnerName;
  final bool isDark;

  const ContextualBehaviorBanner({
    super.key,
    required this.phase,
    required this.partnerName,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final modeInfo = _getModeInfo(phase, partnerName);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            modeInfo.accentColor.withAlpha(isDark ? 55 : 30),
            modeInfo.accentColor.withAlpha(isDark ? 25 : 12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: modeInfo.accentColor.withAlpha(isDark ? 110 : 80),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: modeInfo.accentColor.withAlpha(isDark ? 30 : 15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge Chế Độ Ứng Xử
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: modeInfo.accentColor.withAlpha(isDark ? 50 : 35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: modeInfo.accentColor.withAlpha(isDark ? 120 : 90),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(modeInfo.badgeIcon, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    modeInfo.badgeLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : modeInfo.accentColor,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Lời nhắc hành động tâm lý thông minh
          Text(
            modeInfo.guidanceText,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.42,
              color: isDark ? Colors.white.withAlpha(235) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  _BehaviorModeInfo _getModeInfo(CyclePhase phase, String partner) {
    switch (phase) {
      case CyclePhase.luteal:
        return const _BehaviorModeInfo(
          badgeIcon: '⚠️',
          badgeLabel: 'Chế độ Cưng chiều & Nhường nhịn (Hoàng thể / Sát kỳ)',
          guidanceText:
              'Nội tiết tố đang sụt giảm khiến nàng dễ kiệt sức và nhạy cảm. Ưu tiên lắng nghe, nhường nhịn và ôm ấp thay vì phân bua đúng sai.',
          accentColor: Color(0xFF9C27B0), // Purple Hoàng thể
        );
      case CyclePhase.menstrual:
        return const _BehaviorModeInfo(
          badgeIcon: '🍵',
          badgeLabel: 'Chế độ Chăm sóc & Tiếp sức (Kỳ dâu)',
          guidanceText:
              'Nàng đang chịu cơn đau vật lý và cạn pin năng lượng. Chuẩn bị nước ấm, túi chườm và chủ động gánh vác việc nhà.',
          accentColor: AppColors.phaseMenstrual, // Rose/Red Kỳ dâu
        );
      case CyclePhase.follicular:
      case CyclePhase.ovulation:
        return const _BehaviorModeInfo(
          badgeIcon: '✨',
          badgeLabel: 'Chế độ Kết nối & Đồng hành',
          guidanceText:
              'Năng lượng và tâm trạng của nàng đang ở mức cao nhất. Thời điểm tuyệt vời để hẹn hò, chia sẻ hoặc cùng bàn kế hoạch mới.',
          accentColor: AppColors.phaseOvulation, // Amber/Orange
        );
    }
  }
}

class _BehaviorModeInfo {
  final String badgeIcon;
  final String badgeLabel;
  final String guidanceText;
  final Color accentColor;

  const _BehaviorModeInfo({
    required this.badgeIcon,
    required this.badgeLabel,
    required this.guidanceText,
    required this.accentColor,
  });
}
