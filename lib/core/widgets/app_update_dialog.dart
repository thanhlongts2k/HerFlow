// lib/core/widgets/app_update_dialog.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ota_update/ota_update.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:herflow/core/constants/app_colors.dart';
import 'package:herflow/core/services/app_update_service.dart';
import 'package:herflow/core/utils/haptic_feedback_utils.dart';
import 'package:herflow/core/widgets/moona_brand_logo.dart';

/// Hộp thoại thông báo cập nhật phiên bản mới (Native In-App OTA Dialog với % tải thực tế)
class AppUpdateDialog extends StatefulWidget {
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
  State<AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<AppUpdateDialog> {
  bool _isDownloading = false;
  int _progress = 0;
  String _statusMessage = '';
  bool _hasError = false;
  String? _errorMessage;
  StreamSubscription<OtaEvent>? _otaSubscription;

  @override
  void dispose() {
    _otaSubscription?.cancel();
    super.dispose();
  }

  void _startOtaDownload() {
    AppHaptics.medium();
    setState(() {
      _isDownloading = true;
      _progress = 0;
      _statusMessage = 'Đang chuẩn bị tải về...';
      _hasError = false;
      _errorMessage = null;
    });

    try {
      _otaSubscription?.cancel();
      _otaSubscription = AppUpdateService.executeOtaDownload(widget.releaseInfo.downloadUrl).listen(
        (OtaEvent event) {
          if (!mounted) return;
          switch (event.status) {
            case OtaStatus.DOWNLOADING:
              final p = int.tryParse(event.value ?? '0') ?? _progress;
              setState(() {
                _progress = p;
                _statusMessage = 'Đang tải bản cập nhật ($p%)...';
              });
              break;
            case OtaStatus.INSTALLING:
              setState(() {
                _progress = 100;
                _statusMessage = 'Đang mở trình cài đặt Android... 🚀';
              });
              break;
            case OtaStatus.ALREADY_RUNNING_ERROR:
            case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
            case OtaStatus.INTERNAL_ERROR:
            case OtaStatus.DOWNLOAD_ERROR:
            case OtaStatus.CHECKSUM_ERROR:
              setState(() {
                _hasError = true;
                _isDownloading = false;
                _errorMessage = 'Tải tự động không thành công (${event.status.name}). Bạn có thể tải qua trình duyệt.';
              });
              break;
          }
        },
        onError: (e) {
          if (!mounted) return;
          setState(() {
            _hasError = true;
            _isDownloading = false;
            _errorMessage = 'Lỗi kết nối: ${e.toString().split("\n").first}';
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isDownloading = false;
        _errorMessage = 'Lỗi khởi chạy cập nhật: $e';
      });
    }
  }

  Future<void> _fallbackDownloadInBrowser() async {
    AppHaptics.light();
    final uri = Uri.parse(widget.releaseInfo.downloadUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('AppUpdateDialog could not launch browser: $e');
    }
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
            // Logo Moona
            const MoonaBrandLogo(size: 64),
            const SizedBox(height: 16),

            // Tiêu đề
            Text(
              _isDownloading ? 'Đang Cập Nhật Moona...' : 'Đã Có Phiên Bản Mới! ✨',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),

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
                    'Phiên bản ${widget.releaseInfo.tagName}',
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
                    widget.releaseInfo.formattedSize,
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

            if (_isDownloading) ...[
              // Giao diện thanh tiến trình tải Native
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withAlpha(8) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _statusMessage,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '$_progress%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: _progress / 100.0,
                        minHeight: 10,
                        backgroundColor: isDark ? Colors.white12 : Colors.grey.shade300,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vui lòng không tắt ứng dụng trong lúc tải tệp',
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Nội dung cập nhật (Release Notes)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 160),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      widget.releaseInfo.releaseNotes.isNotEmpty
                          ? widget.releaseInfo.releaseNotes
                          : 'Bản cập nhật tối ưu hóa hiệu năng, sửa lỗi và cải tiến giao diện mượt mà.',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ],

            if (_hasError && _errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 11.5, color: AppColors.error, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Các nút hành động
            if (_isDownloading)
              TextButton(
                onPressed: () {
                  _otaSubscription?.cancel();
                  setState(() => _isDownloading = false);
                },
                child: const Text('Hủy tiến trình tải', style: TextStyle(color: Colors.grey)),
              )
            else
              Column(
                children: [
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
                        child: ElevatedButton.icon(
                          onPressed: _startOtaDownload,
                          icon: const Icon(Icons.system_update_rounded, size: 18),
                          label: const Text(
                            'Cập nhật ngay',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_hasError) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _fallbackDownloadInBrowser,
                      icon: const Icon(Icons.open_in_browser_rounded, size: 16),
                      label: const Text('Tải thủ công qua trình duyệt web', style: TextStyle(fontSize: 12.5)),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}
