// lib/features/care_signals/presentation/widgets/care_signal_banner_card.dart
import 'package:flutter/material.dart';
import 'package:herflow/features/care_signals/domain/models/care_signal_model.dart';
import 'package:herflow/core/constants/app_colors.dart';

/// Thẻ hiển thị tín hiệu yêu thương mới nhất từ Vợ trên dashboard Chồng
class CareSignalBannerCard extends StatelessWidget {
  final CareSignalModel signal;
  final VoidCallback? onDismiss;

  const CareSignalBannerCard({
    super.key,
    required this.signal,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.secondary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(signal.type.emoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tín hiệu yêu thương 💕',
                    style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    signal.type.label,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  if (signal.customNote != null && signal.customNote!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        signal.customNote!,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),
            if (onDismiss != null)
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                onPressed: onDismiss,
              ),
          ],
        ),
      ),
    );
  }
}
