// lib/features/cycle/presentation/widgets/cycle_settings_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:herflow/core/constants/app_colors.dart';
import '../controllers/cycle_controller.dart';

/// Sheet tùy chỉnh độ dài chu kỳ và thời lượng hành kinh
class CycleSettingsSheet extends ConsumerStatefulWidget {
  final int initialCycleLength;
  final int initialPeriodDuration;

  const CycleSettingsSheet({
    super.key,
    required this.initialCycleLength,
    required this.initialPeriodDuration,
  });

  static Future<void> show(BuildContext context, int cycleLength, int duration) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => CycleSettingsSheet(
        initialCycleLength: cycleLength,
        initialPeriodDuration: duration,
      ),
    );
  }

  @override
  ConsumerState<CycleSettingsSheet> createState() => _CycleSettingsSheetState();
}

class _CycleSettingsSheetState extends ConsumerState<CycleSettingsSheet> {
  late int _cycleLength;
  late int _periodDuration;

  @override
  void initState() {
    super.initState();
    _cycleLength = widget.initialCycleLength;
    _periodDuration = widget.initialPeriodDuration;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 34),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
          const SizedBox(height: 16),
          Text(
            'Cài Đặt Chu Kỳ Sinh Học',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 18),

          // 1. Chu kỳ trung bình
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Độ dài chu kỳ (ngày):', style: TextStyle(fontWeight: FontWeight.w600)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () {
                      if (_cycleLength > 21) setState(() => _cycleLength--);
                    },
                  ),
                  Text('$_cycleLength', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () {
                      if (_cycleLength < 45) setState(() => _cycleLength++);
                    },
                  ),
                ],
              ),
            ],
          ),

          // 2. Thời lượng hành kinh
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Thời gian hành kinh (ngày):', style: TextStyle(fontWeight: FontWeight.w600)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () {
                      if (_periodDuration > 2) setState(() => _periodDuration--);
                    },
                  ),
                  Text('$_periodDuration', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () {
                      if (_periodDuration < 10) setState(() => _periodDuration++);
                    },
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: () {
              ref.read(cycleControllerProvider.notifier).setCycleLength(_cycleLength);
              ref.read(cycleControllerProvider.notifier).setPeriodDuration(_periodDuration);
              Navigator.pop(context);
            },
            child: const Text('Lưu Thay Đổi'),
          ),
        ],
      ),
    );
  }
}
