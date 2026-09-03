// lib/features/care_signals/presentation/widgets/love_notes_thread_modal.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:herflow/core/constants/app_colors.dart';
import 'package:herflow/core/constants/user_role.dart';
import 'package:herflow/core/providers/user_role_provider.dart';
import 'package:herflow/core/utils/haptic_feedback_utils.dart';
import 'package:herflow/features/care_signals/domain/models/care_signal_model.dart';
import 'package:herflow/features/care_signals/presentation/controllers/care_signal_controller.dart';
import 'package:herflow/features/settings/presentation/controllers/nickname_controller.dart';

/// Modal BottomSheet hiển thị toàn bộ luồng hội thoại & tín hiệu yêu thương 2 chiều giữa Vợ và Chồng
class LoveNotesThreadModal extends ConsumerStatefulWidget {
  const LoveNotesThreadModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LoveNotesThreadModal(),
    );
  }

  @override
  ConsumerState<LoveNotesThreadModal> createState() => _LoveNotesThreadModalState();
}

class _LoveNotesThreadModalState extends ConsumerState<LoveNotesThreadModal> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  CareSignalType _selectedType = CareSignalType.message;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<String> _getQuickSuggestions(bool isHusband) {
    if (isHusband) {
      return [
        'Anh biết rồi nhé ❤️',
        'Anh qua với em ngay 🚗',
        'Anh đang mua đồ ăn về nè 🛵',
        'Gửi nàng cái ôm thật chặt 🫂',
        'Anh pha nước ấm cho em liền 🍵',
        'Ngoan đợi anh về nha 💖',
      ];
    } else {
      return [
        'Thèm trà sữa quá nè 🧋',
        'Cần một cái ôm thật chặt 🤗',
        'Em hơi đau bụng và mệt 🥺',
        'Mua đồ ăn vặt giúp em với 🍟',
        'Tối nay đi dạo hóng gió nhé 🍃',
        'Pha giúp em một ly nước ấm 🍵',
      ];
    }
  }

  Future<void> _handleSend({String? prefillText, CareSignalType? customType}) async {
    final textToSend = (prefillText ?? _textController.text).trim();
    if (textToSend.isEmpty && customType == null) return;

    if (_isSending) return;
    setState(() => _isSending = true);
    AppHaptics.selection();

    try {
      final type = customType ?? _selectedType;
      await ref.read(careSignalControllerProvider).sendSignal(
            type,
            customNote: textToSend.isNotEmpty ? textToSend : null,
          );

      _textController.clear();
      setState(() => _selectedType = CareSignalType.message);

      // Cuộn xuống tin nhắn mới nhất
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuad,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi gửi tin: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final userRole = ref.watch(userRoleProvider);
    final isHusband = userRole == UserRole.husband;
    final nicknameConfig = ref.watch(nicknameConfigProvider);
    final partnerName = nicknameConfig.callPartnerAs.isNotEmpty
        ? nicknameConfig.callPartnerAs
        : (isHusband ? 'Em bé' : 'Anh');

    final signalsAsync = ref.watch(coupleCareSignalsStreamProvider);
    final quickSuggestions = _getQuickSuggestions(isHusband);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 90 : 30),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // 1. HEADER & DRAG HANDLE
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 12, 8),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(80),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(isDark ? 40 : 25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hộp Thư Yêu Thương 💕',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            'Không gian nhắn nhủ & tín hiệu riêng với $partnerName',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Đóng',
                    ),
                  ],
                ),
                const Divider(height: 12),
              ],
            ),
          ),

          // 2. BODY: DANH SÁCH TIN NHẮN 2 CHIỀU (REVERSE LISTVIEW)
          Expanded(
            child: signalsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, _) => Center(
                child: Text('Lỗi tải tin nhắn: $err', style: const TextStyle(fontSize: 12)),
              ),
              data: (signals) {
                if (signals.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isHusband ? '🛡️💌' : '🌸💌',
                            style: const TextStyle(fontSize: 42),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Chưa có lời nhắn nào',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Hãy gửi một cái ôm, lời hỏi thăm hoặc nhắn điều bạn muốn đến $partnerName nhé! 💕',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: signals.length,
                  itemBuilder: (context, index) {
                    final signal = signals[index];
                    final isSenderHusband = signal.senderRole == 'husband';
                    // Xác định tin nhắn là của bản thân hay người thương
                    final isMe = (isHusband && isSenderHusband) || (!isHusband && !isSenderHusband);

                    return _buildMessageBubble(
                      context,
                      signal: signal,
                      isMe: isMe,
                      isDark: isDark,
                      partnerName: partnerName,
                    );
                  },
                );
              },
            ),
          ),

          // 3. FOOTER: THANH SOẠN THẢO VÀ QUICK CHIPS
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 10,
              bottom: bottomInset > 0 ? bottomInset + 8 : 20,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2030) : const Color(0xFFF9F6FA),
              border: Border(top: BorderSide(color: Colors.grey.withAlpha(40))),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Suggestion Chips cuộn ngang
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: quickSuggestions.map((suggestion) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8, bottom: 8),
                        child: ActionChip(
                          label: Text(suggestion, style: const TextStyle(fontSize: 12)),
                          backgroundColor: isDark ? const Color(0xFF2B2538) : Colors.white,
                          side: BorderSide(color: AppColors.primary.withAlpha(60)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          onPressed: () {
                            AppHaptics.light();
                            _handleSend(prefillText: suggestion);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Ô nhập liệu & Nút gửi
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        maxLength: 150,
                        maxLines: 2,
                        minLines: 1,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Nhắn nhủ tới $partnerName...',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                          counterText: '',
                          filled: true,
                          fillColor: isDark ? const Color(0xFF141622) : Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(color: Colors.grey.withAlpha(50)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _isSending ? null : () => _handleSend(),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(80),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    BuildContext context, {
    required CareSignalModel signal,
    required bool isMe,
    required bool isDark,
    required String partnerName,
  }) {
    final timeStr = DateFormat('HH:mm').format(signal.sentAt);
    final isSpecialSignal = signal.type != CareSignalType.message &&
        signal.type != CareSignalType.custom &&
        signal.type != CareSignalType.reply &&
        signal.type != CareSignalType.husbandMessage;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.secondary.withAlpha(isDark ? 50 : 35),
                  child: Text(
                    signal.senderRole == 'husband' ? '🛡️' : '🌸',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.76,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe
                        ? AppColors.primary
                        : (isDark ? const Color(0xFF28253B) : const Color(0xFFF2ECF4)),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(isDark ? 25 : 10),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nếu là tín hiệu hành động (Ôm, Nước ấm...)
                      if (isSpecialSignal) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(signal.type.emoji, style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                signal.type.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (signal.customNote != null && signal.customNote!.isNotEmpty)
                          const SizedBox(height: 6),
                      ],

                      // Nội dung tin nhắn văn bản
                      if (signal.customNote != null && signal.customNote!.isNotEmpty)
                        Text(
                          signal.customNote!,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
                            height: 1.35,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
              top: 3,
              left: isMe ? 0 : 36,
              right: isMe ? 4 : 0,
            ),
            child: Text(
              timeStr,
              style: const TextStyle(fontSize: 10.5, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
