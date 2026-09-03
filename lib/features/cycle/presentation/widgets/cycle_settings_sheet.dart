// lib/features/cycle/presentation/widgets/cycle_settings_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:herflow/core/constants/app_colors.dart';
import 'package:herflow/core/notifications/notification_service.dart';
import '../controllers/cycle_controller.dart';

/// Sheet hiệu chỉnh thông số chu kỳ kinh nguyệt.
/// CHỈ quản lý: Độ dài chu kỳ, Số ngày hành kinh, Cảnh báo PMS.
/// Cài đặt sinh trắc học đã được chuyển sang SettingsScreen (lib/features/settings/).
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
  bool _isPmsNotificationEnabled = true;

  @override
  void initState() {
    super.initState();
    _cycleLength = widget.initialCycleLength;
    _periodDuration = widget.initialPeriodDuration;
    _isPmsNotificationEnabled = NotificationService.instance.isPmsNotificationEnabled();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 34),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
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

            Row(
              children: [
                const Icon(Icons.edit_calendar_rounded, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Hiệu Chỉnh Chu Kỳ',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Điều chỉnh thông số sinh học để thuật toán 4 pha chính xác hơn.',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // 1. Độ dài chu kỳ
            _buildCounterRow(
              label: 'Độ dài chu kỳ',
              unit: 'ngày',
              value: _cycleLength,
              min: 21,
              max: 45,
              onDecrement: () => setState(() => _cycleLength--),
              onIncrement: () => setState(() => _cycleLength++),
            ),

            const SizedBox(height: 8),

            // 2. Thời lượng hành kinh
            _buildCounterRow(
              label: 'Thời gian hành kinh',
              unit: 'ngày',
              value: _periodDuration,
              min: 2,
              max: 10,
              onDecrement: () => setState(() => _periodDuration--),
              onIncrement: () => setState(() => _periodDuration++),
            ),

            const SizedBox(height: 12),
            const Divider(),

            // 3. Cảnh báo tiền kinh nguyệt (PMS) — giữ lại vì liên quan trực tiếp chu kỳ
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.notifications_active_rounded, color: AppColors.secondary),
              title: const Text('Cảnh báo tiền kinh nguyệt (PMS)', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Nhắc nhở chăm sóc trước PMS lúc 08:00 sáng', style: TextStyle(fontSize: 12)),
              activeColor: AppColors.secondary,
              value: _isPmsNotificationEnabled,
              onChanged: (val) async {
                if (val) {
                  final granted = await NotificationService.instance.requestNotificationPermission();
                  if (!granted && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng cấp quyền thông báo trong Cài đặt Android')),
                    );
                    return;
                  }
                  final cycleInfo = ref.read(cycleControllerProvider).valueOrNull;
                  if (cycleInfo != null) {
                    await NotificationService.instance
                        .schedulePmsWarning(pmsStartDate: cycleInfo.nextPmsStartDate);
                  }
                }
                setState(() => _isPmsNotificationEnabled = val);
                await NotificationService.instance.setPmsNotificationEnabled(val);
              },
            ),

            const SizedBox(height: 20),

            // Nút Lưu
            ElevatedButton(
              onPressed: () async {
                ref.read(cycleControllerProvider.notifier).setCycleLength(_cycleLength);
                ref.read(cycleControllerProvider.notifier).setPeriodDuration(_periodDuration);

                // Cập nhật lại lịch nhắc nhở PMS theo độ dài chu kỳ mới
                if (_isPmsNotificationEnabled) {
                  final cycleInfo = ref.read(cycleControllerProvider).valueOrNull;
                  if (cycleInfo != null) {
                    final updatedInfo = cycleInfo.copyWith(
                      cycleLength: _cycleLength,
                      periodDuration: _periodDuration,
                    );
                    await NotificationService.instance
                        .schedulePmsWarning(pmsStartDate: updatedInfo.nextPmsStartDate);
                  }
                }

                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Lưu Thay Đổi', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterRow({
    required String label,
    required String unit,
    required int value,
    required int min,
    required int max,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            Text('($min–$max $unit)', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: value > min ? onDecrement : null,
              color: AppColors.primary,
            ),
            SizedBox(
              width: 42,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: value < max ? onIncrement : null,
              color: AppColors.primary,
            ),
          ],
        ),
      ],
    );
  }
}
