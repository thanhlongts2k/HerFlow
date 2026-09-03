// lib/features/auth/presentation/screens/biometric_lock_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:herflow/core/constants/app_constants.dart';
import 'package:herflow/core/constants/app_colors.dart';

/// Màn hình khóa sinh trắc học bao bọc toàn bộ nội dung app.
/// Cơ chế chống Lifecycle Loop:
///   1. isPromptingBiometrics: Chặn hoàn toàn sự kiện lifecycle do chính native dialog vân tay sinh ra.
///   2. shouldLock: Chỉ khóa khi app thực sự rơi vào background (paused) từ người dùng.
///   3. lastAuthSuccessTime: Miễn trừ khóa trong 3 giây sau khi vừa xác thực thành công.
class BiometricLockScreen extends StatefulWidget {
  final Widget child;

  const BiometricLockScreen({super.key, required this.child});

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen>
    with WidgetsBindingObserver {
  final _auth = LocalAuthentication();

  // Trạng thái hiển thị giao diện khóa
  bool _isLocked = false;
  bool _isAuthenticating = false;
  bool _hasFailed = false;
  String _statusMessage = 'Xác thực để tiếp tục';

  // ── CÁC CỜ BẢO VỆ CHỐNG VÒNG LẶP LIFECYCLE (ANTI-LOOP FLAGS) ──
  /// Đang hiển thị native dialog vân tay của hệ điều hành
  static bool _isPromptingBiometrics = false;

  /// Đánh dấu app đã từng bị paused (ra ngoài background thực sự)
  static bool _shouldLock = false;

  /// Thời điểm app rơi vào paused
  static DateTime? _pausedTime;

  /// Thời điểm xác thực thành công gần nhất
  static DateTime? _lastAuthSuccessTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Khi app vừa khởi động lần đầu
    if (_isBiometricEnabled()) {
      _isLocked = true;
      _shouldLock = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startAuthentication();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 1. Nếu sự kiện lifecycle do chính dialog vân tay sinh ra -> BỎ QUA HOÀN TOÀN
    if (_isPromptingBiometrics) {
      return;
    }

    // 2. Khi người dùng thực sự thoát ra ngoài (Home/Recents/Khóa màn hình máy)
    if (state == AppLifecycleState.paused) {
      if (_isBiometricEnabled()) {
        _shouldLock = true;
        _pausedTime = DateTime.now();
      }
      return;
    }

    // 3. Khi người dùng quay trở lại app (resumed)
    if (state == AppLifecycleState.resumed) {
      // Nếu vừa mới mở khóa thành công trong 3 giây -> bỏ qua
      if (_lastAuthSuccessTime != null) {
        final secondsSinceAuth = DateTime.now().difference(_lastAuthSuccessTime!).inSeconds;
        if (secondsSinceAuth < 3) {
          _shouldLock = false;
          return;
        }
      }

      // Kiểm tra cấu hình thời gian tự động khóa (auto_lock_minutes)
      if (_shouldLock && _isBiometricEnabled()) {
        final box = Hive.box(AppConstants.settingsBoxName);
        final autoLockMinutes = box.get('auto_lock_minutes', defaultValue: 0) as int;

        if (autoLockMinutes > 0 && _pausedTime != null) {
          final elapsedMinutes = DateTime.now().difference(_pausedTime!).inMinutes;
          if (elapsedMinutes < autoLockMinutes) {
            _shouldLock = false;
            return;
          }
        }

        // Kích hoạt khóa app và bắt đầu xác thực
        setState(() {
          _isLocked = true;
          _hasFailed = false;
          _statusMessage = 'Xác thực để tiếp tục';
        });
        _shouldLock = false;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _startAuthentication();
        });
      }
    }
  }

  bool _isBiometricEnabled() {
    final box = Hive.box(AppConstants.settingsBoxName);
    return box.get(AppConstants.keyIsBiometricEnabled, defaultValue: false) as bool;
  }

  /// Bắt đầu quy trình xác thực sinh trắc học được bảo vệ chặt chẽ
  Future<void> _startAuthentication({bool biometricOnly = false}) async {
    if (_isAuthenticating || _isPromptingBiometrics) return;

    final canCheck = await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    if (!canCheck) {
      // Thiết bị không hỗ trợ -> mở khóa ngay để không làm kẹt người dùng
      if (mounted) {
        setState(() {
          _isLocked = false;
          _isAuthenticating = false;
        });
      }
      return;
    }

    if (!mounted) return;
    setState(() {
      _isAuthenticating = true;
      _statusMessage = 'Đang xác thực...';
    });

    // Đánh dấu đang mở native dialog để chặn toàn bộ lifecycle event
    _isPromptingBiometrics = true;

    try {
      final didAuth = await _auth.authenticate(
        localizedReason: 'Xác thực bảo mật để truy cập Moona',
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: biometricOnly,
          useErrorDialogs: true,
        ),
      );

      if (mounted) {
        if (didAuth) {
          _lastAuthSuccessTime = DateTime.now();
          _shouldLock = false;
          setState(() {
            _isLocked = false;
            _hasFailed = false;
            _statusMessage = 'Xác thực thành công';
          });
        } else {
          setState(() {
            _hasFailed = true;
            _statusMessage = 'Xác thực không thành công';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasFailed = true;
          _statusMessage = 'Lỗi xác thực hoặc đã hủy';
        });
      }
    } finally {
      // BẮT BUỘC: Luôn hạ cả 2 cờ trong finally để mở khóa UI
      _isPromptingBiometrics = false;
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  /// Cơ chế thoát hiểm: Mở khóa phiên làm việc hiện tại
  void _bypassLock() {
    _lastAuthSuccessTime = DateTime.now();
    _shouldLock = false;
    _isPromptingBiometrics = false;
    setState(() {
      _isLocked = false;
      _isAuthenticating = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã mở khóa tạm thời cho phiên này.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLocked) return widget.child;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon vân tay
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: (_hasFailed ? AppColors.error : AppColors.primary).withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.fingerprint_rounded,
                    size: 64,
                    color: _hasFailed ? AppColors.error : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Moona',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : AppColors.primaryDark,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _hasFailed ? AppColors.error : Colors.grey,
                    fontSize: 14,
                    fontWeight: _hasFailed ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 36),

                // Nút mở khóa chính (Chạm để thử lại / Đang xác thực)
                ElevatedButton.icon(
                  onPressed: _isAuthenticating ? null : () => _startAuthentication(),
                  icon: _isAuthenticating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _hasFailed ? Icons.refresh_rounded : Icons.lock_open_rounded,
                          size: 20,
                        ),
                  label: Text(
                    _isAuthenticating
                        ? 'Đang xác thực...'
                        : (_hasFailed ? 'Chạm để thử lại' : 'Mở khóa vân tay'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // NÚT THOÁT HIỂM 1: Dùng mật mã máy (Device PIN/Pattern)
                OutlinedButton.icon(
                  onPressed: _isAuthenticating
                      ? null
                      : () => _startAuthentication(biometricOnly: false),
                  icon: const Icon(Icons.pin_rounded, size: 18),
                  label: const Text('Mở khóa bằng mật mã máy'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white70 : AppColors.textPrimaryLight,
                    side: BorderSide(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                    ),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // NÚT THOÁT HIỂM 2: Bỏ qua xác thực để không bao giờ bị kẹt
                TextButton(
                  onPressed: _isAuthenticating ? null : _bypassLock,
                  child: const Text(
                    'Bỏ qua xác thực (Vào app)',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
