// lib/features/care_signals/presentation/widgets/care_signal_sheet.dart
import 'package:flutter/material.dart';
import 'package:herflow/core/constants/app_colors.dart';
import 'package:herflow/features/care_signals/domain/models/care_signal_model.dart';

/// Bottom sheet để Vợ chọn và gửi tín hiệu yêu thương cho Chồng
class CareSignalSheet extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 34),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(80),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Gửi Tín Hiệu Yêu Thương 💕',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Chọn để chồng biết bạn cần gì hôm nay',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: CareSignalType.values.map((type) {
              return InkWell(
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã gửi: ${type.label} — Tính năng đồng bộ Cloud sẽ có trong v0.4.0'),
                      backgroundColor: AppColors.primary,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withAlpha(80),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withAlpha(60)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(type.emoji, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                      Text(
                        type.label,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
