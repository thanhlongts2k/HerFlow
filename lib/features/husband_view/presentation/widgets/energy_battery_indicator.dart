import 'package:flutter/material.dart';
import 'package:herflow/core/constants/app_colors.dart';

/// Widget Chỉ Số "Pin Năng Lượng" (Energy Battery Indicator)
/// Hiển thị thanh pin năng lượng 5 vạch đồng bộ trực tiếp từ thể trạng của Vợ
/// kèm lời giải thích trực quan về khả năng vận động và nhu cầu nghỉ ngơi.
class EnergyBatteryIndicator extends StatelessWidget {
  final int energyLevel;
  final String partnerName;
  final bool isDark;

  const EnergyBatteryIndicator({
    super.key,
    required this.energyLevel,
    required this.partnerName,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final clampedLevel = energyLevel.clamp(1, 5);
    final batteryData = _getBatteryData(clampedLevel);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2433).withAlpha(150) : Colors.white.withAlpha(200),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: batteryData.color.withAlpha(isDark ? 80 : 50),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề và nhãn tình trạng pin
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    batteryData.icon,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Pin năng lượng của $partnerName',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: batteryData.color.withAlpha(isDark ? 45 : 25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: batteryData.color.withAlpha(70)),
                ),
                child: Text(
                  '$clampedLevel/5 • ${batteryData.statusLabel}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: batteryData.color,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Thanh hiển thị pin 5 vạch (Segmented Battery Bar)
          Row(
            children: [
              // Khung pin chính với 5 vạch
              Expanded(
                child: Container(
                  height: 14,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: isDark ? Colors.white30 : Colors.black26,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: List.generate(5, (index) {
                      final isFilled = index < clampedLevel;
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.only(
                            right: index < 4 ? 2.0 : 0.0,
                          ),
                          decoration: BoxDecoration(
                            color: isFilled
                                ? batteryData.color
                                : (isDark ? Colors.white10 : Colors.black.withAlpha(15)),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(width: 3),
              // Đầu cực pin (Battery terminal nub)
              Container(
                width: 3,
                height: 7,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white30 : Colors.black26,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(2)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Lời chú thích hướng dẫn hành động tương ứng với mức pin
          Text(
            batteryData.caption,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              height: 1.35,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  _BatteryData _getBatteryData(int level) {
    switch (level) {
      case 1:
        return const _BatteryData(
          icon: '🪫',
          statusLabel: 'Cạn kiệt',
          caption: 'Pin cạn (1/5): Nàng kiệt sức, cần nghỉ ngơi tuyệt đối, hạn chế di chuyển nhiều.',
          color: AppColors.error,
        );
      case 2:
        return const _BatteryData(
          icon: '🪫',
          statusLabel: 'Pin yếu',
          caption: 'Pin yếu (2/5): Thể trạng mệt mỏi, nàng cần nghỉ ngơi, uống nước ấm và hạn chế việc nặng.',
          color: Color(0xFFFF9800),
        );
      case 3:
        return const _BatteryData(
          icon: '🔋',
          statusLabel: 'Trung bình',
          caption: 'Pin ổn định (3/5): Nàng đang hồi phục năng lượng, thích hợp với các hoạt động nhẹ nhàng.',
          color: AppColors.secondary,
        );
      case 4:
        return const _BatteryData(
          icon: '🔋',
          statusLabel: 'Dồi dào',
          caption: 'Pin tốt (4/5): Nàng thoải mái, khỏe khoắn, sẵn sàng cho các hoạt động thường ngày cùng bạn.',
          color: Color(0xFF4CAF50),
        );
      case 5:
      default:
        return const _BatteryData(
          icon: '⚡',
          statusLabel: 'Cực đại',
          caption: 'Pin cực đại (5/5): Năng lượng và tinh thần nàng đạt đỉnh! Thời điểm tuyệt vời để cùng trải nghiệm.',
          color: Color(0xFF00E676),
        );
    }
  }
}

class _BatteryData {
  final String icon;
  final String statusLabel;
  final String caption;
  final Color color;

  const _BatteryData({
    required this.icon,
    required this.statusLabel,
    required this.caption,
    required this.color,
  });
}
