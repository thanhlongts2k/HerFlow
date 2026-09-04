import 'package:flutter/material.dart';
import 'package:herflow/core/constants/app_colors.dart';
import 'package:herflow/core/constants/cycle_phase.dart';
import 'package:herflow/core/utils/haptic_feedback_utils.dart';

/// Bảng "Bí Kíp Sinh Tồn" 1 Chạm (Do's & Don'ts Cheat-Sheet Card)
/// Dạng collapsible (gập/mở gọn gàng) cung cấp danh sách hành vi NÊN LÀM và CẦN TRÁNH
/// thích ứng trực tiếp theo từng giai đoạn chu kỳ của nàng.
class SurvivalCheatSheetCard extends StatefulWidget {
  final CyclePhase phase;
  final bool isDark;

  const SurvivalCheatSheetCard({
    super.key,
    required this.phase,
    required this.isDark,
  });

  @override
  State<SurvivalCheatSheetCard> createState() => _SurvivalCheatSheetCardState();
}

class _SurvivalCheatSheetCardState extends State<SurvivalCheatSheetCard> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final cheatSheet = _getCheatSheet(widget.phase);

    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1E2638) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: widget.isDark ? Colors.white12 : Colors.black.withAlpha(20),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(widget.isDark ? 35 : 10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header bấm để gập / mở (Collapsible Header)
          InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () {
              AppHaptics.selection();
              setState(() => _isExpanded = !_isExpanded);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withAlpha(widget.isDark ? 45 : 25),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('🛡️', style: TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bí Kíp Sinh Tồn Cho Chàng',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Do\'s & Don\'ts theo pha ${widget.phase.vietnameseName}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: widget.isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.secondary,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),

          // Nội dung có thể gập / mở mượt mà
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Khối DO: Nên chủ động làm ngay
                  _buildSectionBox(
                    title: 'NÊN CHỦ ĐỘNG LÀM NGAY',
                    badgeText: 'DO',
                    badgeColor: AppColors.success,
                    items: cheatSheet.dos,
                    icon: Icons.check_circle_rounded,
                  ),

                  const SizedBox(height: 10),

                  // Khối DON'T: Tuyệt đối tránh
                  _buildSectionBox(
                    title: 'TUYỆT ĐỐI NÊN TRÁNH',
                    badgeText: 'DON\'T',
                    badgeColor: AppColors.error,
                    items: cheatSheet.donts,
                    icon: Icons.cancel_rounded,
                  ),
                ],
              ),
            ),
            crossFadeState:
                _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 260),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionBox({
    required String title,
    required String badgeText,
    required Color badgeColor,
    required List<String> items,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: badgeColor.withAlpha(widget.isDark ? 25 : 12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: badgeColor.withAlpha(widget.isDark ? 70 : 40),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withAlpha(widget.isDark ? 45 : 30),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: widget.isDark ? Colors.white : Colors.black87,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3.5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 14, color: badgeColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                        color: widget.isDark ? Colors.white.withAlpha(230) : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  _CheatSheetData _getCheatSheet(CyclePhase phase) {
    switch (phase) {
      case CyclePhase.menstrual:
        return const _CheatSheetData(
          dos: [
            'Chủ động làm việc nhà không cần nhắc.',
            'Chuẩn bị nước ấm, túi chườm và một ly trà gừng mật ong.',
            'Hỏi thăm nhẹ nhàng: "Em còn mệt nhiều không, cần anh lấy gì không?"',
            'Ôm ấp vỗ về và cho nàng ngủ đủ giấc.',
          ],
          donts: [
            'Tranh cãi logic khi nàng giận hoặc mệt.',
            'Bắt nàng đưa ra các lựa chọn phức tạp (như: "Tối nay ăn gì?").',
            'Hỏi những câu vô tâm (như: "Có đau đến thế không?").',
          ],
        );
      case CyclePhase.luteal:
        return const _CheatSheetData(
          dos: [
            'Ưu tiên lắng nghe, nhường nhịn và đồng cảm thay vì tranh luận.',
            'Hỏi thăm nhẹ nhàng: "Ngày hôm nay của em thế nào?".',
            'Tặng đồ ngọt / trà ấm xoa dịu thần kinh.',
            'Chủ động massage nhẹ vai gáy trước khi đi ngủ.',
          ],
          donts: [
            'TUYỆT ĐỐI KHÔNG nói câu: "Em lại tới tháng rồi à?".',
            'Tránh phân bua đúng sai hoặc bàn chuyện áp lực căng thẳng.',
            'Không phàn nàn nếu nàng đổi ý đột ngột.',
          ],
        );
      case CyclePhase.follicular:
        return const _CheatSheetData(
          dos: [
            'Chủ động lên lịch một buổi hẹn hò bất ngờ ngoài trời.',
            'Cùng nàng đi dạo, tập thể thao nhẹ nhàng và chia sẻ kế hoạch mới.',
            'Khen ngợi vẻ rạng rỡ và năng lượng tích cực của nàng.',
          ],
          donts: [
            'Đừng để những ngày cuối tuần trôi qua tẻ nhạt trong nhà.',
            'Không ngắt lời khi nàng đang hào hứng chia sẻ.',
          ],
        );
      case CyclePhase.ovulation:
        return const _CheatSheetData(
          dos: [
            'Dành cho nàng sự chú ý và những cử chỉ âu yếm lãng mạn.',
            'Lên kế hoạch một bữa tối ấm cúng chỉ có hai người.',
            'Trao nhau những cái ôm siết chặt nồng nàn.',
          ],
          donts: [
            'Không lơ là hoặc thiếu tập trung khi trò chuyện cùng nàng.',
            'Đừng quên lời thì thầm ngọt ngào trước khi ngủ.',
          ],
        );
    }
  }
}

class _CheatSheetData {
  final List<String> dos;
  final List<String> donts;

  const _CheatSheetData({required this.dos, required this.donts});
}
