// lib/core/widgets/moona_confirm_dialog.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:herflow/core/constants/app_colors.dart';
import 'package:herflow/core/utils/haptic_feedback_utils.dart';

/// Hộp thoại xác nhận chuẩn hóa toàn hệ thống Moona (Material 3 / Soft Glassmorphic)
/// Hỗ trợ bộ đếm ngược chống hành vi bốc đồng (Cooldown Timer) cho các hành động nhạy cảm như Hủy kết nối.
class MoonaConfirmDialog extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final String cancelText;
  final String confirmText;
  final String? cooldownConfirmText;
  final int cooldownSeconds;
  final bool isDestructive;
  final Color? customColor;

  const MoonaConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.cancelText = 'Hủy',
    this.confirmText = 'Xác nhận',
    this.cooldownConfirmText,
    this.cooldownSeconds = 0,
    this.isDestructive = false,
    this.customColor,
  });

  /// Hàm tiện ích tĩnh gọi nhanh MoonaConfirmDialog từ bất kỳ màn hình nào
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
    String cancelText = 'Hủy',
    String confirmText = 'Xác nhận',
    String? cooldownConfirmText,
    int cooldownSeconds = 0,
    bool isDestructive = false,
    Color? customColor,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => MoonaConfirmDialog(
        title: title,
        message: message,
        icon: icon,
        cancelText: cancelText,
        confirmText: confirmText,
        cooldownConfirmText: cooldownConfirmText,
        cooldownSeconds: cooldownSeconds,
        isDestructive: isDestructive,
        customColor: customColor,
      ),
    );
  }

  @override
  State<MoonaConfirmDialog> createState() => _MoonaConfirmDialogState();
}

class _MoonaConfirmDialogState extends State<MoonaConfirmDialog> {
  late int _remainingSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.cooldownSeconds;
    if (_remainingSeconds > 0) {
      _startCooldownTimer();
    }
  }

  void _startCooldownTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() => _remainingSeconds = 0);
        AppHaptics.medium();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Màu chủ đạo cho dialog: Nếu destructive -> Đỏ san hô, nếu không -> customColor hoặc AppColors.primary
    final effectiveColor = widget.isDestructive
        ? const Color(0xFFE05353)
        : (widget.customColor ?? AppColors.primary);

    final isCountingDown = _remainingSeconds > 0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1B2E) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isDark ? Colors.white.withAlpha(25) : Colors.black.withAlpha(15),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 140 : 35),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Header Icon container tròn bo góc mềm (~56x56)
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: effectiveColor.withAlpha(isDark ? 40 : 25),
                shape: BoxShape.circle,
                border: Border.all(
                  color: effectiveColor.withAlpha(isDark ? 80 : 60),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Icon(
                  widget.icon,
                  color: effectiveColor,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // 2. Title: Bold 19sp, căn giữa, tương phản cao
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 10),

            // 3. Message: 14sp, màu chữ phụ (subtext), căn giữa, padding hợp lý
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                widget.message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.48,
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 26),

            // 4. Action Bar: Cân xứng ngang hàng (Row) 50:50, cao cố định 48px
            Row(
              children: [
                // Nút Phụ (Hủy / Ở lại / Giữ kết nối)
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () {
                        AppHaptics.light();
                        Navigator.pop(context, false);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? Colors.white70 : Colors.black87,
                        side: BorderSide(
                          color: isDark ? Colors.white24 : Colors.grey.shade300,
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        widget.cancelText,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Nút Chính (Xác nhận / Đăng xuất / Hủy kết nối)
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isCountingDown
                          ? null
                          : () {
                              if (widget.isDestructive) {
                                AppHaptics.medium();
                              } else {
                                AppHaptics.light();
                              }
                              Navigator.pop(context, true);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCountingDown
                            ? (isDark ? Colors.white.withAlpha(20) : Colors.grey.shade300)
                            : effectiveColor,
                        disabledBackgroundColor: isDark
                            ? Colors.white.withAlpha(18)
                            : Colors.grey.shade300,
                        foregroundColor: isCountingDown
                            ? (isDark ? Colors.white38 : Colors.grey.shade600)
                            : Colors.white,
                        disabledForegroundColor: isDark
                            ? Colors.white38
                            : Colors.grey.shade600,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          isCountingDown
                              ? 'Xác nhận hủy (${_remainingSeconds}s)...'
                              : (widget.cooldownConfirmText ?? widget.confirmText),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isCountingDown ? FontWeight.w600 : FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
