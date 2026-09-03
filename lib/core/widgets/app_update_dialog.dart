// lib/core/widgets/app_update_dialog.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:herflow/core/constants/app_colors.dart';
import 'package:herflow/core/services/app_update_service.dart';
import 'package:herflow/core/utils/haptic_feedback_utils.dart';
import 'package:herflow/core/widgets/moona_brand_logo.dart';

/// Hộp thoại thông báo cập nhật phiên bản mới (In-App OTA Dialog)
class AppUpdateDialog extends StatelessWidget {
  final AppReleaseInfo releaseInfo;

  const AppUpdateDialog({
    super.key,
    required this.releaseInfo,
  });

  static Future<void> show(BuildContext context, AppReleaseInfo releaseInfo) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AppUpdateDialog(releaseInfo: releaseInfo),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1B2E) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isDark ? Colors.white.withAlpha(30) : Colors.black.withAlpha(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 120 : 40),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo Moona vầng trăng khuyết
            const MoonaBrandLogo(size: 72),
            const SizedBox(height: 16),

            // Tiêu đề
            Text(
              'Đã có phiên bản Moona mới! ✨',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),

            // Badge phiên bản & dung lượng
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(isDark ? 40 : 25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withAlpha(80)),
                  ),
                  child: Text(
                    'Phiên bản ${releaseInfo.tagName}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white10 : Colors.black.withAlpha(15)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    releaseInfo.formattedSize,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Nội dung cập nhật (Release Notes)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    releaseInfo.releaseNotes.isNotEmpty
                        ? releaseInfo.releaseNotes
                        : 'Bản cập nhật bao gồm tối ưu hiệu năng, sửa lỗi và cải tiến giao diện mượt mà.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Hai nút hành động: Để sau & Cập nhật ngay
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      AppHaptics.light();
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Để sau',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () async {
                      AppHaptics.medium();
                      Navigator.pop(context);
                      final uri = Uri.parse(releaseInfo.downloadUrl);
                      try {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } catch (e) {
                        debugPrint('AppUpdateDialog could not launch url: $e');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.download_rounded, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Cập nhật ngay',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                        ),
                      ],
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
