// lib/features/auth/presentation/screens/biometric_lock_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:herflow/core/constants/app_constants.dart';
import 'package:herflow/core/constants/app_colors.dart';

/// Màn hình khóa sinh trắc học bao bọc toàn bộ nội dung app.
/// Hiển thị màn hình xác thực khi:
///   - Người dùng đã bật tính năng khóa sinh trắc học
///   - App mới khởi động hoặc resume từ background
class BiometricLockScreen extends StatefulWidget {
  final Widget child;

  const BiometricLockScreen({super.key, required this.child});

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen>
    with WidgetsBindingObserver {
  final _auth = LocalAuthentication();
  bool _isLocked = false;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAndLock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndLock();
    }
  }

  bool _isBiometricEnabled() {
    final box = Hive.box(AppConstants.settingsBoxName);
    return box.get(AppConstants.keyIsBiometricEnabled, defaultValue: false) as bool;
  }

  Future<void> _checkAndLock() async {
    if (!_isBiometricEnabled()) return;
    if (!mounted) return;

    final canAuth = await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    if (!canAuth) return;

    setState(() => _isLocked = true);
    await _authenticate();
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);

    try {
      final didAuth = await _auth.authenticate(
        localizedReason: 'Xác thực để mở Moona',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      if (mounted && didAuth) {
        setState(() {
          _isLocked = false;
          _isAuthenticating = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLocked) return widget.child;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.fingerprint_rounded, size: 64, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            const Text(
              'Moona',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Xác thực để tiếp tục',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isAuthenticating ? null : _authenticate,
              icon: _isAuthenticating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.lock_open_rounded, size: 18),
              label: Text(_isAuthenticating ? 'Đang xác thực...' : 'Mở khóa'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
