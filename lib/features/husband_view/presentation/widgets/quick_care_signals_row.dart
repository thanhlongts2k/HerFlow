import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:herflow/core/constants/app_colors.dart';
import 'package:herflow/core/utils/haptic_feedback_utils.dart';
import 'package:herflow/features/care_signals/domain/models/care_signal_model.dart';
import 'package:herflow/features/partner_sync/presentation/controllers/partner_sync_controller.dart';
import 'package:herflow/features/partner_sync/presentation/screens/pairing_screen.dart';
import 'package:herflow/features/settings/presentation/controllers/nickname_controller.dart';

/// Hàng phím tắt "Cứu nguy 1 chạm" (Quick Care Signals)
/// Giúp Chồng gửi tức thì các hành động chăm sóc thiết thực mà không cần gõ phím.
class QuickCareSignalsRow extends ConsumerStatefulWidget {
  final String partnerName;
  final bool isDark;

  const QuickCareSignalsRow({
    super.key,
    required this.partnerName,
    required this.isDark,
  });

  @override
  ConsumerState<QuickCareSignalsRow> createState() => _QuickCareSignalsRowState();
}

class _QuickCareSignalsRowState extends ConsumerState<QuickCareSignalsRow> {
  bool _isSending = false;

  Future<void> _sendSignal({
    required String emoji,
    required String label,
    required String fullNote,
  }) async {
    if (_isSending) return;
    AppHaptics.medium();

    final coupleId = ref.read(savedCoupleIdProvider);
    if (coupleId == null || coupleId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng kết nối với Vợ để gửi tín hiệu yêu thương 💕'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.secondary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          action: SnackBarAction(
            label: 'Ghép đôi',
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PairingScreen(initialIndex: 1)),
              );
            },
          ),
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    final nicknameConfig = ref.read(nicknameConfigProvider);
    final signal = CareSignalModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      coupleId: coupleId,
      type: CareSignalType.husbandMessage,
      customNote: fullNote,
      sentAt: DateTime.now(),
      senderRole: 'husband',
      senderNickname: nicknameConfig.selfCallAs,
      targetNickname: widget.partnerName,
    );

    try {
      await ref.read(partnerSyncRepositoryProvider).sendCareSignal(signal);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Đã gửi tới ${widget.partnerName}: "$fullNote" 💕',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.secondary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gửi tín hiệu thất bại: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              const Text('⚡', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                'Cứu Nguy 1 Chạm Tới ${widget.partnerName}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              if (_isSending)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
                  ),
                ),
            ],
          ),
        ),
        Row(
          children: [
            // 1. Mua đồ ngọt
            Expanded(
              child: _buildQuickButton(
                emoji: '🧋',
                title: 'Mua đồ ngọt',
                subtitle: 'Trà sữa / bánh',
                note: 'Anh mua đồ ngọt / trà sữa mang qua cho em nhé 🧋',
                accentColor: const Color(0xFFFF9800),
              ),
            ),
            const SizedBox(width: 8),

            // 2. Massage thư giãn
            Expanded(
              child: _buildQuickButton(
                emoji: '💆‍♂️',
                title: 'Massage',
                subtitle: 'Vai gáy & lưng',
                note: 'Tối nay anh massage vai gáy cho em thư giãn nha 💆‍♂️',
                accentColor: const Color(0xFF9C27B0),
              ),
            ),
            const SizedBox(width: 8),

            // 3. Cái ôm sạc pin
            Expanded(
              child: _buildQuickButton(
                emoji: '🫂',
                title: 'Ôm sạc pin',
                subtitle: 'Nạp năng lượng',
                note: 'Gửi em một cái ôm thật chặt để sạc pin năng lượng nhé 🫂',
                accentColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickButton({
    required String emoji,
    required String title,
    required String subtitle,
    required String note,
    required Color accentColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _isSending
            ? null
            : () => _sendSignal(emoji: emoji, label: title, fullNote: note),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: widget.isDark
                ? accentColor.withAlpha(25)
                : accentColor.withAlpha(15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accentColor.withAlpha(widget.isDark ? 80 : 50),
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: widget.isDark ? Colors.white : accentColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: widget.isDark ? Colors.white54 : Colors.black45,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
