// lib/core/providers/app_version_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Model thông tin phiên bản ứng dụng
class AppVersionInfo {
  final String appName;
  final String version;
  final String buildNumber;

  const AppVersionInfo({
    required this.appName,
    required this.version,
    required this.buildNumber,
  });

  /// Ví dụ: "0.3.0"
  String get shortVersion => version;

  /// Ví dụ: "Moona v0.3.0 (Build 3)"
  String get displayString => '$appName v$version (Build $buildNumber)';
}

/// FutureProvider đọc thông tin phiên bản từ hệ thống (Single Source of Truth: pubspec.yaml)
final appVersionProvider = FutureProvider<AppVersionInfo>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return AppVersionInfo(
    appName: info.appName.isEmpty ? 'Moona' : info.appName,
    version: info.version.isEmpty ? '0.3.0' : info.version,
    buildNumber: info.buildNumber.isEmpty ? '3' : info.buildNumber,
  );
});
