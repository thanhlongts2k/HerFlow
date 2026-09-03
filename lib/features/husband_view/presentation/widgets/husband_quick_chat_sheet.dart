import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:herflow/core/constants/app_colors.dart';
import 'package:herflow/core/constants/cycle_phase.dart';
import 'package:herflow/core/utils/haptic_feedback_utils.dart';
import 'package:herflow/features/care_signals/domain/models/care_signal_model.dart';
import 'package:herflow/features/partner_sync/presentation/controllers/partner_sync_controller.dart';
import 'package:herflow/features/settings/presentation/controllers/nickname_controller.dart';

/// Modal Chat Nhanh cho phép Chồng chủ động gửi câu hỏi thăm & lời quan tâm đến Vợ
class HusbandQuickChatSheet extends ConsumerStatefulWidget {
  final CyclePhase phase;

  const HusbandQuickChatSheet({
    super.key,
    required this.phase,
  });

  /// Hiển thị Modal BottomSheet
  static Future<void> show(BuildContext context, {required CyclePhase phase}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HusbandQuickChatSheet(phase: phase),
    );
  }

  @override
  ConsumerState<HusbandQuickChatSheet> createState() => _HusbandQuickChatSheetState();
}

class _HusbandQuickChatSheetState extends ConsumerState<HusbandQuickChatSheet> {
  final TextEditingController _textController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// Danh sách câu hỏi/lời nhắn gợi ý thông minh thích ứng theo pha chu kỳ
  List<String> _getSuggestions() {
    switch (widget.phase) {
      case CyclePhase.menstrual:
      case CyclePhase.luteal:
        return [
          'Bụng còn đau nhiều không em? 🥺',
          'Anh mua đồ ăn ngon mang qua nhé? 🍲',
          'Uống nước ấm chưa em bé? 🍵',
          'Nghỉ ngơi sớm nhé nàng 🛌',
          'Cần anh chườm ấm hay massage không? 💆‍♂️',
        ];
      case CyclePhase.follicular:
      case CyclePhase.ovulation:
        return [
          'Hôm nay đi hẹn hò nhé? ✨',
          'Tan làm anh qua đón nhé? 🚗',
          'Tối nay em muốn ăn gì? 🍕',
          'Hôm nay em thấy trong người thế nào? 🥰',
          'Đi dạo hóng gió cùng anh nhé? 🍃',
        ];
    }
  }

  /// Thực hiện gửi lời nhắn lên Firestore
  Future<void> _sendQuickMessage(String messageText) async {
    final text = messageText.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    AppHaptics.selection();

    final nicknameConfig = ref.read(nicknameConfigProvider);
    final coupleId = ref.read(savedCoupleIdProvider) ?? '';
    final partnerName = nicknameConfig.callPartnerAs;

    final signal = CareSignalModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      coupleId: coupleId,
      type: CareSignalType.husbandMessage,
      customNote: text,
      sentAt: DateTime.now(),
      senderRole: 'husband',
      senderNickname: nicknameConfig.selfCallAs,
      targetNickname: partnerName,
    );

    try {
      await ref.read(partnerSyncRepositoryProvider).sendCareSignal(signal);
      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã gửi lời yêu thương đến $partnerName 💕'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.secondary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gửi thất bại: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final nicknameConfig = ref.watch(nicknameConfigProvider);
    final partnerName = nicknameConfig.callPartnerAs;
    final suggestions = _getSuggestions();

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 90 : 40),
            blurRadius: 32,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thanh kéo trên đỉnh modal
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(isDark ? 90 : 70),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Tiêu đề & Nút đóng
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gửi lời quan tâm đến $partnerName 💕',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: widget.phase.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${widget.phase.vietnameseName} • Gợi ý thích ứng thông minh',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: widget.phase.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),

          const SizedBox(height: 18),

          // NHÓM 1: GỢI Ý NHANH THEO THỂ TRẠNG NÀNG
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.secondary),
              const SizedBox(width: 6),
              Text(
                'Gợi ý nhanh theo thể trạng nàng:',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((text) {
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isSending ? null : () => _sendQuickMessage(text),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withAlpha(isDark ? 35 : 20),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.secondary.withAlpha(isDark ? 80 : 50),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          text,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // NHÓM 2: TIN NHẮN TỰ NHẬP
          Row(
            children: [
              const Icon(Icons.edit_note_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'Hoặc nhập lời nhắn gửi riêng:',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withAlpha(12) : const Color(0xFFF7F7FA),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? Colors.white24 : Colors.black12,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    minLines: 1,
                    maxLines: 3,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (val) => _sendQuickMessage(val),
                    decoration: InputDecoration(
                      hintText: 'Nhập lời nhắn gửi đến $partnerName...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withAlpha(60),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: _isSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                    onPressed: _isSending
                        ? null
                        : () => _sendQuickMessage(_textController.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
