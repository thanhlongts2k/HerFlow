// lib/features/care_signals/presentation/widgets/care_signal_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:herflow/core/constants/app_colors.dart';
import 'package:herflow/features/care_signals/domain/models/care_signal_model.dart';
import 'package:herflow/features/care_signals/presentation/controllers/care_signal_controller.dart';
import 'package:herflow/features/partner_sync/presentation/controllers/partner_sync_controller.dart';
import 'package:herflow/features/partner_sync/presentation/screens/pairing_screen.dart';

/// Bottom sheet để Vợ chọn và gửi tín hiệu yêu thương cho Chồng
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
  bool _isSending = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPaired = ref.watch(isPairedProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
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
                'Gửi Tín Hiệu Yêu Thương',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Chọn một tín hiệu để Người thương hiểu bạn đang cần gì nhất lúc này 💕',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),

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

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: CareSignalType.values
                .where((t) => t != CareSignalType.husbandMessage)
                .map((type) {
              return InkWell(
                onTap: _isSending ? null : () async {
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

                  // Khóa ngay lập tức để chống spam click multi-tap
                  setState(() => _isSending = true);

                  try {
                    Navigator.pop(context);
                    await ref.read(careSignalControllerProvider).sendSignal(type);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Text(type.emoji, style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Đã gửi tín hiệu: ${type.label} 💖',
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
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Lỗi gửi tín hiệu: ${e.toString().replaceAll("Exception: ", "")}'),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      );
                    }
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withAlpha(_isSending ? 40 : 80),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withAlpha(_isSending ? 30 : 60)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(type.emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      Text(
                        type.label,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
