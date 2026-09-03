// lib/features/auth/presentation/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:herflow/core/constants/app_colors.dart';
import 'package:herflow/core/constants/app_constants.dart';
import 'package:herflow/core/routes/app_routes.dart';
import 'package:herflow/core/utils/haptic_feedback_utils.dart';
import '../controllers/auth_controller.dart';

/// Màn hình Đăng Nhập Moona — Google Sign-In & Nhận Diện Cặp Đôi
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  static const String routeName = '/login';

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    AppHaptics.mediumImpact();

    try {
      final user = await ref.read(authControllerProvider.notifier).signInWithGoogle();
      if (user != null && mounted) {
        _navigateAfterAuth();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Đăng nhập Google chưa thành công. Bạn có thể chọn "Dùng thử chế độ Demo" bên dưới.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi đăng nhập: ${e.toString().split('\n').first}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleDemoSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    AppHaptics.mediumImpact();

    try {
      await ref.read(authControllerProvider.notifier).signInAsDemo(
        displayName: 'Thành Long',
        email: 'long.thanh@gmail.com',
      );
      if (mounted) {
        _navigateAfterAuth();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateAfterAuth() {
    final settingsBox = Hive.box(AppConstants.settingsBoxName);
    final hasSelectedRole = settingsBox.get(AppConstants.keyHasSelectedRole, defaultValue: false) as bool;
    final isOnboardingCompleted = settingsBox.get(AppConstants.keyIsOnboardingCompleted, defaultValue: false) as bool;

    if (!hasSelectedRole || !isOnboardingCompleted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.roleSelection);
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient sang trọng
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1F1122), const Color(0xFF0F172A), const Color(0xFF0A0F1D)]
                    : [const Color(0xFFFFF0F5), const Color(0xFFF6F8FD), const Color(0xFFFFFFFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 2),

                  // Moona Logo & Biểu tượng mặt trăng hoa
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(isDark ? 90 : 70),
                            blurRadius: 28,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text('🌙', style: TextStyle(fontSize: 48)),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Tên ứng dụng
                  Center(
                    child: Text(
                      'Moona',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        fontSize: 34,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Center(
                    child: Text(
                      'Thấu Hiểu Chu Kỳ • Đồng Hành Yêu Thương',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black54,
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Mô tả xác thực
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withAlpha(12)
                          : Colors.black.withAlpha(8),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_user_rounded, color: AppColors.success, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Đăng nhập bằng Google để định danh tài khoản, lưu ảnh đại diện và đồng bộ thời gian thực với người thương.',
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.4,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(fontSize: 12, color: AppColors.error),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Nút Đăng nhập Google lớn
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : Colors.white,
                      foregroundColor: Colors.black87,
                      minimumSize: const Size.fromHeight(56),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(color: Colors.grey.withAlpha(60)),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Google G logo mini
                              Container(
                                width: 26,
                                height: 26,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  'G',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF4285F4),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Text(
                                'Tiếp tục với Google',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                  ),

                  const SizedBox(height: 12),

                  // Nút đăng nhập thử nghiệm / Demo
                  TextButton.icon(
                    onPressed: _isLoading ? null : _handleDemoSignIn,
                    icon: const Icon(Icons.flash_on_rounded, size: 16, color: AppColors.secondary),
                    label: const Text(
                      'Dùng thử nhanh (Chế độ Demo / Khách)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),

                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
