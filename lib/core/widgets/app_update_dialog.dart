// lib/core/widgets/app_update_dialog.dart
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:herflow/core/constants/app_colors.dart';
import 'package:herflow/core/services/app_update_service.dart';
import 'package:herflow/core/services/ota_installer_service.dart';
import 'package:herflow/core/utils/haptic_feedback_utils.dart';
import 'package:herflow/core/widgets/moona_brand_logo.dart';

/// Hộp thoại thông báo cập nhật phiên bản mới (In-App OTA Updater với Dio & PackageInstaller)
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

class _AppUpdateDialogState extends State<AppUpdateDialog> with WidgetsBindingObserver {
  bool _isDownloading = false;
  OtaDownloadProgress? _downloadProgress;
  String? _downloadedFilePath;
  bool _isDownloaded = false;
  bool _hasPermission = true;
  bool _hasError = false;
  String? _errorMessage;

  CancelToken? _cancelToken;
  StreamSubscription<OtaDownloadProgress>? _downloadSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _downloadSubscription?.cancel();
    _cancelToken?.cancel('Dialog disposed');
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Khi người dùng quay lại từ màn hình cài đặt cấp quyền của Android
    if (state == AppLifecycleState.resumed && _isDownloaded && !_hasPermission) {
      _checkPermissionAndInstallIfReady();
    }
  }

  Future<void> _checkPermissionAndInstallIfReady() async {
    final granted = await OtaInstallerService.checkInstallPermission();
    if (!mounted) return;
    setState(() {
      _hasPermission = granted;
    });
    if (granted && _downloadedFilePath != null) {
      AppHaptics.success();
      _triggerInstall();
    }
  }

  void _startOtaDownload() {
    AppHaptics.medium();
    _cancelToken = CancelToken();

    setState(() {
      _isDownloading = true;
      _isDownloaded = false;
      _downloadProgress = const OtaDownloadProgress(
        progress: 0,
        receivedBytes: 0,
        totalBytes: 0,
        speedBytesPerSec: 0,
      );
      _hasError = false;
      _errorMessage = null;
    });

    _downloadSubscription?.cancel();
    _downloadSubscription = AppUpdateService.downloadApk(
      downloadUrl: widget.releaseInfo.downloadUrl,
      cancelToken: _cancelToken,
    ).listen(
      (progress) {
        if (!mounted) return;
        setState(() {
          _downloadProgress = progress;
        });

        if (progress.isCompleted && progress.filePath != null) {
          _handleDownloadComplete(progress.filePath!);
        }
      },
      onError: (e) {
        if (!mounted) return;
        final isCancel = e.toString().contains('hủy');
        setState(() {
          _isDownloading = false;
          if (!isCancel) {
            _hasError = true;
            _errorMessage = 'Lỗi trong lúc tải: ${e.toString().split("\n").first}';
          }
        });
      },
    );
  }

  Future<void> _handleDownloadComplete(String filePath) async {
    AppHaptics.success();
    final hasPerm = await OtaInstallerService.checkInstallPermission();
    if (!mounted) return;

    setState(() {
      _isDownloading = false;
      _isDownloaded = true;
      _downloadedFilePath = filePath;
      _hasPermission = hasPerm;
    });

    if (hasPerm) {
      await _triggerInstall();
    }
  }

  Future<void> _triggerInstall() async {
    if (_downloadedFilePath == null) return;
    try {
      await OtaInstallerService.installApk(_downloadedFilePath!);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = 'Không thể mở trình cài đặt: $e';
      });
    }
  }

  void _cancelDownload() {
    AppHaptics.light();
    _cancelToken?.cancel('User cancelled');
    _downloadSubscription?.cancel();
    setState(() {
      _isDownloading = false;
      _downloadProgress = null;
    });
  }

  Future<void> _openPermissionSettings() async {
    AppHaptics.medium();
    await OtaInstallerService.openInstallPermissionSettings();
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

            // Tiêu đề tương ứng trạng thái
            Text(
              _buildTitleText(),
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
                    color: isDark ? Colors.white10 : Colors.black.withAlpha(15),
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

            // Thân hộp thoại theo từng trạng thái
            if (_isDownloading)
              _buildDownloadingView(isDark)
            else if (_isDownloaded && !_hasPermission)
              _buildPermissionRequestView(isDark)
            else if (_isDownloaded && _hasPermission)
              _buildReadyToInstallView(isDark)
            else
              _buildInitialView(isDark),

            // Thông báo lỗi nếu có
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
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Các nút hành động
            _buildActionButtons(isDark),
          ],
        ),
      ),
    );
  }

  String _buildTitleText() {
    if (_isDownloading) return 'Đang Cập Nhật Moona...';
    if (_isDownloaded && !_hasPermission) return 'Cần Cấp Quyền Cài Đặt 🛡️';
    if (_isDownloaded) return 'Sẵn Sàng Cài Đặt! 🚀';
    return 'Đã Có Phiên Bản Mới! ✨';
  }

  /// Giao diện tiến trình tải mượt mà với Dio
  Widget _buildDownloadingView(bool isDark) {
    final progress = _downloadProgress?.progress ?? 0;
    final receivedStr = _downloadProgress?.formattedReceived ?? '0 MB';
    final totalStr = _downloadProgress?.formattedTotal ?? widget.releaseInfo.formattedSize;
    final speedStr = _downloadProgress?.formattedSpeed ?? '0 KB/s';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(8) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Đang tải gói cài đặt...',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              Text(
                '$progress%',
                style: const TextStyle(
                  fontSize: 15,
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
              value: progress / 100.0,
              minHeight: 10,
              backgroundColor: isDark ? Colors.white12 : Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$receivedStr / $totalStr',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(isDark ? 30 : 20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  speedStr,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Vui lòng không tắt ứng dụng trong lúc tải tệp',
            style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey),
          ),
        ],
      ),
    );
  }

  /// Giao diện hướng dẫn cấp quyền cài đặt ứng dụng không rõ nguồn gốc
  Widget _buildPermissionRequestView(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withAlpha(isDark ? 25 : 15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.amber.withAlpha(80)),
      ),
      child: Column(
        children: [
          const Icon(Icons.security_update_rounded, size: 36, color: Colors.amber),
          const SizedBox(height: 8),
          Text(
            'Cần Cho Phép Cài Đặt Ngoài',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Để cập nhật tự động, bạn cần bật công tắc "Cho phép từ nguồn này" trong cài đặt Android cho Moona.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  /// Giao diện khi file APK đã sẵn sàng để cài đặt
  Widget _buildReadyToInstallView(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withAlpha(isDark ? 25 : 15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.green.withAlpha(80)),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 36, color: Colors.green),
          const SizedBox(height: 8),
          Text(
            'Tải Về Hoàn Tất',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Hệ thống đang mở trình cài đặt Android để cập nhật phiên bản mới nhất cho bạn.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  /// Giao diện ban đầu hiển thị Release Notes
  Widget _buildInitialView(bool isDark) {
    return ConstrainedBox(
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
    );
  }

  /// Khối các nút hành động điều hướng
  Widget _buildActionButtons(bool isDark) {
    if (_isDownloading) {
      return TextButton.icon(
        onPressed: _cancelDownload,
        icon: const Icon(Icons.close_rounded, size: 18),
        label: const Text('Hủy tải về', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
      );
    }

    if (_isDownloaded && !_hasPermission) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openPermissionSettings,
              icon: const Icon(Icons.settings_rounded, size: 18),
              label: const Text('Mở Cài Đặt Cấp Quyền', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Để sau', style: TextStyle(color: Colors.grey)),
          ),
        ],
      );
    }

    if (_isDownloaded && _hasPermission) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _triggerInstall,
              icon: const Icon(Icons.install_mobile_rounded, size: 18),
              label: const Text('Mở Lại Trình Cài Đặt', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng', style: TextStyle(color: Colors.grey)),
          ),
        ],
      );
    }

    // Trạng thái ban đầu
    return Column(
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
    );
  }
}
