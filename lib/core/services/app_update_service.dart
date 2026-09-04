// lib/core/services/app_update_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:herflow/core/constants/app_constants.dart';
import 'package:herflow/core/services/ota_installer_service.dart';

/// Model thông tin bản phát hành từ GitHub Release
class AppReleaseInfo {
  final String tagName;
  final String versionName;
  final String releaseNotes;
  final String downloadUrl;
  final int fileSize;
  final DateTime publishedAt;

  const AppReleaseInfo({
    required this.tagName,
    required this.versionName,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.fileSize,
    required this.publishedAt,
  });

  /// Dung lượng hiển thị theo MB (Ví dụ: "27.1 MB")
  String get formattedSize {
    if (fileSize <= 0) return 'Đang cập nhật';
    final mb = fileSize / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }
}

/// Trạng thái tiến trình tải file APK cập nhật
class OtaDownloadProgress {
  final int progress; // 0 -> 100
  final int receivedBytes;
  final int totalBytes;
  final double speedBytesPerSec; // Bytes per second
  final String? filePath;
  final bool isCompleted;
  final String? errorMessage;

  const OtaDownloadProgress({
    required this.progress,
    required this.receivedBytes,
    required this.totalBytes,
    required this.speedBytesPerSec,
    this.filePath,
    this.isCompleted = false,
    this.errorMessage,
  });

  /// Định dạng tốc độ tải (KB/s hoặc MB/s)
  String get formattedSpeed {
    if (speedBytesPerSec <= 0) return '0 KB/s';
    final kb = speedBytesPerSec / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(1)} KB/s';
    }
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB/s';
  }

  /// Định dạng dung lượng đã tải (MB)
  String get formattedReceived {
    final mb = receivedBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  /// Định dạng tổng dung lượng file (MB)
  String get formattedTotal {
    if (totalBytes <= 0) return '-- MB';
    final mb = totalBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }
}

/// Dịch vụ kiểm tra và cập nhật ứng dụng qua GitHub Releases (In-App OTA Updater)
class AppUpdateService {
  static const String _githubApiUrl =
      'https://api.github.com/repos/thanhlongts2k/HerFlow/releases/latest';
  static const String _keyLastCheckTime = 'last_ota_check_timestamp';
  static const int _checkIntervalHours = 24;

  /// Stream tải tệp APK qua Dio với luồng báo cáo tiến trình chi tiết (% • MB/s • MB/MB)
  static Stream<OtaDownloadProgress> downloadApk({
    required String downloadUrl,
    CancelToken? cancelToken,
  }) async* {
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/moona_update.apk';
    final file = File(filePath);

    // Xóa file cũ nếu đã tồn tại để tránh xung đột hoặc corrupt
    if (await file.exists()) {
      try {
        await file.delete();
      } catch (e) {
        debugPrint('AppUpdateService: Không thể xóa file APK cũ: $e');
      }
    }

    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(minutes: 5),
        followRedirects: true,
        maxRedirects: 5,
      ),
    );
    final streamController = StreamController<OtaDownloadProgress>();

    int lastReceived = 0;
    DateTime lastTime = DateTime.now();
    double currentSpeed = 0.0;

    // Phát sự kiện khởi đầu 0%
    streamController.add(
      const OtaDownloadProgress(
        progress: 0,
        receivedBytes: 0,
        totalBytes: 0,
        speedBytesPerSec: 0,
      ),
    );

    dio.download(
      downloadUrl,
      filePath,
      cancelToken: cancelToken,
      deleteOnError: true,
      onReceiveProgress: (received, total) {
        final now = DateTime.now();
        final elapsedMs = now.difference(lastTime).inMilliseconds;

        // Tính toán tốc độ mỗi 300ms để hiển thị mượt mà không bị giật số
        if (elapsedMs >= 300) {
          final bytesDiff = received - lastReceived;
          if (elapsedMs > 0 && bytesDiff >= 0) {
            currentSpeed = bytesDiff / (elapsedMs / 1000.0);
          }
          lastReceived = received;
          lastTime = now;
        }

        final progress = total > 0 ? ((received / total) * 100).clamp(0, 100).toInt() : 0;

        streamController.add(
          OtaDownloadProgress(
            progress: progress,
            receivedBytes: received,
            totalBytes: total,
            speedBytesPerSec: currentSpeed,
          ),
        );
      },
    ).then((_) {
      streamController.add(
        OtaDownloadProgress(
          progress: 100,
          receivedBytes: lastReceived,
          totalBytes: lastReceived,
          speedBytesPerSec: 0,
          filePath: filePath,
          isCompleted: true,
        ),
      );
      streamController.close();
    }).catchError((err) {
      if (err is DioException && err.type == DioExceptionType.cancel) {
        streamController.addError(Exception('Đã hủy tiến trình tải bản cập nhật.'));
      } else {
        streamController.addError(err);
      }
      streamController.close();
    });

    yield* streamController.stream;
  }

  /// Tải tệp APK và tự động kích hoạt PackageInstaller khi hoàn tất
  static Future<void> downloadAndInstallApk({
    required String downloadUrl,
    void Function(OtaDownloadProgress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    String? downloadedFilePath;
    await for (final progress in downloadApk(downloadUrl: downloadUrl, cancelToken: cancelToken)) {
      onProgress?.call(progress);
      if (progress.isCompleted && progress.filePath != null) {
        downloadedFilePath = progress.filePath;
      }
    }

    if (downloadedFilePath != null) {
      await OtaInstallerService.installApk(downloadedFilePath);
    }
  }

  /// So sánh Semantic Versioning: trả về true nếu `latestVer` mới hơn `currentVer`
  static bool isNewerVersion(String currentVer, String latestVer) {
    try {
      final curClean = currentVer.trim().replaceAll('v', '').split('+').first;
      final latClean = latestVer.trim().replaceAll('v', '').split('+').first;

      final curParts = curClean.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final latParts = latClean.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      for (int i = 0; i < 3; i++) {
        final c = i < curParts.length ? curParts[i] : 0;
        final l = i < latParts.length ? latParts[i] : 0;
        if (l > c) return true;
        if (l < c) return false;
      }
    } catch (e) {
      debugPrint('AppUpdateService.isNewerVersion error: $e');
    }
    return false;
  }

  /// Kiểm tra xem đã đủ 24h kể từ lần kiểm tra tự động trước hay chưa
  static bool shouldCheckAutomatically() {
    try {
      final box = Hive.box(AppConstants.settingsBoxName);
      final lastCheckMs = box.get(_keyLastCheckTime, defaultValue: 0) as int;
      if (lastCheckMs == 0) return true;

      final lastCheck = DateTime.fromMillisecondsSinceEpoch(lastCheckMs);
      final diff = DateTime.now().difference(lastCheck);
      return diff.inHours >= _checkIntervalHours;
    } catch (e) {
      return true;
    }
  }

  /// Ghi nhận thời điểm kiểm tra tự động gần nhất
  static void markAutoChecked() {
    try {
      final box = Hive.box(AppConstants.settingsBoxName);
      box.put(_keyLastCheckTime, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('AppUpdateService.markAutoChecked error: $e');
    }
  }

  /// Kiểm tra bản cập nhật mới từ GitHub Releases
  /// [forceCheck] = true khi người dùng bấm nút kiểm tra thủ công trong Cài đặt
  static Future<AppReleaseInfo?> checkForUpdate({bool forceCheck = false}) async {
    if (!forceCheck && !shouldCheckAutomatically()) {
      return null;
    }

    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
      final request = await client.getUrl(Uri.parse(_githubApiUrl));
      request.headers.set('User-Agent', 'MoonaApp-Android');
      request.headers.set('Accept', 'application/vnd.github.v3+json');

      final response = await request.close();
      if (response.statusCode != 200) {
        debugPrint('AppUpdateService: GitHub API returned status ${response.statusCode}');
        return null;
      }

      final bodyStr = await response.transform(utf8.decoder).join();
      final Map<String, dynamic> data = jsonDecode(bodyStr);

      final tagName = data['tag_name'] as String? ?? '';
      final body = data['body'] as String? ?? 'Bản cập nhật tối ưu hóa hiệu năng và giao diện.';
      final publishedAtStr = data['published_at'] as String?;
      final publishedAt = publishedAtStr != null ? DateTime.tryParse(publishedAtStr) ?? DateTime.now() : DateTime.now();

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      if (!isNewerVersion(currentVersion, tagName)) {
        if (!forceCheck) markAutoChecked();
        return null;
      }

      // Quét tìm asset file APK tải về (ưu tiên arm64-v8a tối ưu)
      final assets = data['assets'] as List<dynamic>? ?? [];
      String downloadUrl = '';
      int fileSize = 0;

      for (final asset in assets) {
        final name = (asset['name'] as String? ?? '').toLowerCase();
        final url = asset['browser_download_url'] as String? ?? '';
        final size = asset['size'] as int? ?? 0;

        if (name.contains('arm64-v8a') && name.endsWith('.apk')) {
          downloadUrl = url;
          fileSize = size;
          break; // Ưu tiên số 1: arm64-v8a tối ưu nhất
        } else if (name.contains('universal') && name.endsWith('.apk')) {
          downloadUrl = url;
          fileSize = size;
        } else if (downloadUrl.isEmpty && name.endsWith('.apk')) {
          downloadUrl = url;
          fileSize = size;
        }
      }

      if (downloadUrl.isEmpty) {
        // Fallback sang link HTML release nếu chưa có assets đính kèm
        downloadUrl = data['html_url'] as String? ?? 'https://github.com/thanhlongts2k/HerFlow/releases';
      }

      if (!forceCheck) markAutoChecked();

      return AppReleaseInfo(
        tagName: tagName,
        versionName: tagName.replaceAll('v', ''),
        releaseNotes: body,
        downloadUrl: downloadUrl,
        fileSize: fileSize,
        publishedAt: publishedAt,
      );
    } catch (e) {
      debugPrint('AppUpdateService error during check: $e');
      if (forceCheck) rethrow;
      return null;
    } finally {
      client?.close();
    }
  }
}
