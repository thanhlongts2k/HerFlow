// test/core/services/app_update_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:herflow/core/services/app_update_service.dart';

void main() {
  group('AppUpdateService & OtaDownloadProgress Unit Tests', () {
    test('isNewerVersion accurately compares Semantic Version strings', () {
      expect(AppUpdateService.isNewerVersion('1.0.0', '1.0.1'), isTrue);
      expect(AppUpdateService.isNewerVersion('v1.0.0', 'v1.0.1'), isTrue);
      expect(AppUpdateService.isNewerVersion('1.0.8+8', '1.0.9+9'), isTrue);
      expect(AppUpdateService.isNewerVersion('1.0.8', '1.0.8'), isFalse);
      expect(AppUpdateService.isNewerVersion('1.0.9', '1.0.8'), isFalse);
      expect(AppUpdateService.isNewerVersion('2.0.0', '1.9.9'), isFalse);
      expect(AppUpdateService.isNewerVersion('1.2.0', '1.1.9'), isFalse);
      expect(AppUpdateService.isNewerVersion('1.0.8', '2.0.0'), isTrue);
    });

    test('AppReleaseInfo calculates formattedSize accurately', () {
      final release = AppReleaseInfo(
        tagName: 'v1.0.9',
        versionName: '1.0.9',
        releaseNotes: 'Bản cập nhật mới',
        downloadUrl: 'https://example.com/app.apk',
        fileSize: 28416400, // ~27.1 MB
        publishedAt: DateTime.now(),
      );

      expect(release.formattedSize, '27.1 MB');

      final emptyRelease = AppReleaseInfo(
        tagName: 'v1.0.9',
        versionName: '1.0.9',
        releaseNotes: '',
        downloadUrl: '',
        fileSize: 0,
        publishedAt: DateTime.now(),
      );
      expect(emptyRelease.formattedSize, 'Đang cập nhật');
    });

    test('OtaDownloadProgress formats speed, received, and total bytes properly', () {
      const progress = OtaDownloadProgress(
        progress: 50,
        receivedBytes: 15 * 1024 * 1024, // 15 MB
        totalBytes: 30 * 1024 * 1024,    // 30 MB
        speedBytesPerSec: 2.5 * 1024 * 1024, // 2.5 MB/s
      );

      expect(progress.progress, 50);
      expect(progress.formattedReceived, '15.0 MB');
      expect(progress.formattedTotal, '30.0 MB');
      expect(progress.formattedSpeed, '2.5 MB/s');

      const kbProgress = OtaDownloadProgress(
        progress: 10,
        receivedBytes: 1024 * 500,
        totalBytes: 0,
        speedBytesPerSec: 350 * 1024, // 350 KB/s
      );
      expect(kbProgress.formattedSpeed, '350.0 KB/s');
      expect(kbProgress.formattedTotal, '-- MB');
    });
  });
}
