// lib/features/care_signals/presentation/widgets/care_signal_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:herflow/core/constants/app_colors.dart';
import 'package:herflow/core/utils/haptic_feedback_utils.dart';
import 'package:herflow/features/care_signals/domain/models/care_signal_model.dart';
import 'package:herflow/features/care_signals/presentation/controllers/care_signal_controller.dart';
import 'package:herflow/features/partner_sync/presentation/controllers/partner_sync_controller.dart';
import 'package:herflow/features/partner_sync/presentation/screens/pairing_screen.dart';
import 'package:herflow/features/settings/presentation/controllers/nickname_controller.dart';

/// Bottom sheet để Vợ chọn biểu tượng và tự gõ tin nhắn yêu thương (Custom Love Note) cho Chồng
class CareSignalSheet extends ConsumerStatefulWidget {
  const CareSignalSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const CareSignalSheet(),
    );
  }

  @override
  ConsumerState<CareSignalSheet> createState() => _CareSignalSheetState();
}

class _CareSignalSheetState extends ConsumerState<CareSignalSheet> {
  final TextEditingController _customNoteController = TextEditingController();
  CareSignalType _selectedType = CareSignalType.hug;
  bool _isSending = false;

  static const List<String> _quickSuggestions = [
    'Thèm trà sữa quá nè 🧋',
    'Cần một cái ôm thật chặt 🤗',
    'Em hơi đau bụng và mệt 🥺',
    'Mua đồ ăn vặt giúp em với 🍟',
    'Tối nay đi dạo hóng gió nhé 🍃',
    'Pha giúp em một ly nước ấm 🍵',
  ];

  @override
  void dispose() {
    _customNoteController.dispose();
    super.dispose();
  }

  Future<void> _handleSendSignal(String partnerName) async {
    final isPaired = ref.read(isPairedProvider);

    if (!isPaired) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng ghép đôi để gửi tín hiệu đến Người thương! 💕'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
      return;
    }

    if (_isSending) return;

    setState(() => _isSending = true);
    AppHaptics.selection();

    final customText = _customNoteController.text.trim();

    try {
      Navigator.pop(context);
      await ref.read(careSignalControllerProvider).sendSignal(
            _selectedType,
            customNote: customText.isNotEmpty ? customText : null,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Text(_selectedType.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Đã gửi lời nhắn đến $partnerName rồi nè 💕',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi gửi tín hiệu: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
    final isPaired = ref.watch(isPairedProvider);
    final nicknameConfig = ref.watch(nicknameConfigProvider);
    final partnerName = nicknameConfig.callPartnerAs.isNotEmpty
        ? nicknameConfig.callPartnerAs
        : 'Anh';

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thanh kéo handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tiêu đề
            Row(
              children: [
                const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Nhắn Nhủ Tới $partnerName',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Gửi yêu cầu hoặc nhắn bất cứ điều gì nàng đang muốn với chàng 💕',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 16),

            // Cảnh báo khi chưa ghép đôi
            if (!isPaired)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withAlpha(25),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.secondary.withAlpha(80)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.secondary, size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Bạn chưa ghép đôi với Người thương. Hãy ghép đôi để gửi tín hiệu 2 chiều nhé!',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PairingScreen(initialIndex: 0)),
                        );
                      },
                      child: const Text('Ghép đôi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),

            // 1. HÀNG BIỂU TƯỢNG TÍN HIỆU NHANH
            Text(
              'Chọn biểu tượng tín hiệu:',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: CareSignalType.values
                    .where((t) => t != CareSignalType.husbandMessage)
                    .map((type) {
                  final isSelected = _selectedType == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: isSelected,
                      avatar: Text(type.emoji, style: const TextStyle(fontSize: 16)),
                      label: Text(type.label),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AppColors.primaryDark : null,
                      ),
                      selectedColor: AppColors.primaryContainer,
                      backgroundColor: isDark ? const Color(0xFF232538) : const Color(0xFFF9F5F8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : Colors.grey.withAlpha(50),
                        ),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          AppHaptics.selection();
                          setState(() => _selectedType = type);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // 2. GỢI Ý NHANH (QUICK CHIPS)
            Text(
              'Gợi ý lời nhắn nhanh:',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickSuggestions.map((suggestion) {
                return ActionChip(
                  label: Text(suggestion, style: const TextStyle(fontSize: 12)),
                  backgroundColor: isDark ? const Color(0xFF262035) : const Color(0xFFFFF1F4),
                  side: BorderSide(color: AppColors.primary.withAlpha(50)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onPressed: () {
                    AppHaptics.light();
                    setState(() {
                      _customNoteController.text = suggestion;
                      _customNoteController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _customNoteController.text.length),
                      );
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // 3. Ô NHẬP LIỆU TÙY BIẾN (CUSTOM NOTE TEXT FIELD)
            Text(
              'Lời nhắn riêng của nàng (tùy chọn):',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _customNoteController,
              maxLength: 150,
              maxLines: 3,
              minLines: 2,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Nhắn điều nàng đang muốn với chàng (thèm đồ ăn, cần ôm, tâm sự...)...',
                hintStyle: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E2030) : const Color(0xFFF9F7FA),
                counterStyle: const TextStyle(fontSize: 11),
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.withAlpha(60)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 4. NÚT HÀNH ĐỘNG GỬI CHO ANH
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSending ? null : () => _handleSendSignal(partnerName),
                icon: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded, size: 20),
                label: Text(
                  _isSending ? 'Đang gửi lời nhắn...' : 'Gửi cho $partnerName 💕',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
