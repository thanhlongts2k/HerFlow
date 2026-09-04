// lib/core/services/ota_installer_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Dịch vụ giao tiếp với Native Android (MethodChannel) để kiểm tra quyền và kích hoạt PackageInstaller
class OtaInstallerService {
  static const MethodChannel _channel = MethodChannel('com.herflow.app/installer');

  /// Kiểm tra xem ứng dụng đã được cấp quyền "Cài đặt ứng dụng không rõ nguồn gốc" (REQUEST_INSTALL_PACKAGES) hay chưa
  static Future<bool> checkInstallPermission() async {
    if (!Platform.isAndroid) return false;
    try {
      final bool hasPermission = await _channel.invokeMethod('checkInstallPermission') ?? false;
      return hasPermission;
    } catch (e) {
      debugPrint('OtaInstallerService.checkInstallPermission error: $e');
      return false;
    }
  }

  /// Điều hướng người dùng tới trang Cài đặt để bật quyền cài đặt APK cho Moona
  static Future<bool> openInstallPermissionSettings() async {
    if (!Platform.isAndroid) return false;
    try {
      final bool success = await _channel.invokeMethod('openInstallPermissionSettings') ?? false;
      return success;
    } catch (e) {
      debugPrint('OtaInstallerService.openInstallPermissionSettings error: $e');
      return false;
    }
  }

  /// Kích hoạt Intent PackageInstaller của hệ thống để cài đặt file APK đã tải về
  static Future<bool> installApk(String filePath) async {
    if (!Platform.isAndroid) return false;
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File APK không tồn tại tại: $filePath');
      }

      final bool success = await _channel.invokeMethod('installApk', {
        'filePath': filePath,
      }) ?? false;
      return success;
    } catch (e) {
      debugPrint('OtaInstallerService.installApk error: $e');
      rethrow;
    }
  }
}
