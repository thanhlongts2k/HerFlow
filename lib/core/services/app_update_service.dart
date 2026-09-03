// lib/core/services/app_update_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:herflow/core/constants/app_constants.dart';

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

/// Dịch vụ kiểm tra và cập nhật ứng dụng qua GitHub Releases (In-App OTA)
class AppUpdateService {
  static const String _githubApiUrl =
      'https://api.github.com/repos/thanhlongts2k/HerFlow/releases/latest';
  static const String _keyLastCheckTime = 'last_ota_check_timestamp';
  static const int _checkIntervalHours = 24;

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
      return null;
    } finally {
      client?.close();
    }
  }
}
