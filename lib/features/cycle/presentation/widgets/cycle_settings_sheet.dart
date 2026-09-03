// lib/features/cycle/presentation/widgets/cycle_settings_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:herflow/core/constants/app_colors.dart';
import 'package:herflow/core/notifications/notification_service.dart';
import 'package:herflow/features/auth/services/biometric_service.dart';
import 'package:herflow/features/backup/presentation/screens/backup_screen.dart';
import '../controllers/cycle_controller.dart';

/// Sheet tùy chỉnh chu kỳ, bảo mật sinh trắc học, cảnh báo PMS và sao lưu
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
  bool _isBiometricEnabled = false;
  bool _isPmsNotificationEnabled = true;

  @override
  void initState() {
    super.initState();
    _cycleLength = widget.initialCycleLength;
    _periodDuration = widget.initialPeriodDuration;
    _isBiometricEnabled = ref.read(biometricServiceProvider).isBiometricLockEnabled();
    _isPmsNotificationEnabled = NotificationService.instance.isPmsNotificationEnabled();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 34),
      child: SingleChildScrollView(
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
              'Cài Đặt Ứng Dụng & Chu Kỳ',
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
                    Text('$_cycleLength',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
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
                    Text('$_periodDuration',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
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

            const SizedBox(height: 10),
            const Divider(),

            // 3. Khóa bảo mật sinh trắc học
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.fingerprint_rounded, color: AppColors.primary),
              title: const Text('Khóa bằng sinh trắc học', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Yêu cầu vân tay / FaceID khi mở Moona', style: TextStyle(fontSize: 12)),
              activeThumbColor: AppColors.primary,
              value: _isBiometricEnabled,
              onChanged: (val) async {
                final biometricService = ref.read(biometricServiceProvider);
                if (val) {
                  final canAuth = await biometricService.canAuthenticate();
                  if (!canAuth) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Thiết bị chưa cài đặt hoặc không hỗ trợ sinh trắc học')),
                      );
                    }
                    return;
                  }
                  final authOk =
                      await biometricService.authenticate(reason: 'Xác nhận kích hoạt khóa sinh trắc học');
                  if (!authOk) return;
                }
                setState(() => _isBiometricEnabled = val);
                await biometricService.setBiometricLockEnabled(val);
                ref.read(isAppLockedProvider.notifier).state = false;
              },
            ),

            // 4. Cảnh báo sớm PMS
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.notifications_active_rounded, color: AppColors.secondary),
              title: const Text('Cảnh báo tiền kinh nguyệt (PMS)', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Nhắc nhở chăm sóc trước ngày PMS lúc 08:00 sáng', style: TextStyle(fontSize: 12)),
              activeThumbColor: AppColors.secondary,
              value: _isPmsNotificationEnabled,
              onChanged: (val) async {
                if (val) {
                  final granted =
                      await NotificationService.instance.requestNotificationPermission();
                  if (!granted && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng cấp quyền thông báo trong Cài đặt Android')),
                    );
                    return;
                  }
                  // Lên lịch cảnh báo PMS
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

            const Divider(),

            // 5. Lối tắt đến Sao lưu & Khôi phục dữ liệu
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.shield_rounded, color: AppColors.primary),
              title: const Text('Sao lưu & Khôi phục dữ liệu', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Xuất/nhập file .moona mã hóa AES-256 an toàn', style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BackupScreen()),
                );
              },
            ),

            const SizedBox(height: 18),

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
              child: const Text('Lưu Thay Đổi'),
            ),
          ],
        ),
      ),
    );
  }
}
