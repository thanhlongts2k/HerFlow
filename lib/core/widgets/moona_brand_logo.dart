import 'package:flutter/material.dart';

/// Biểu tượng thương hiệu Moona chính thức (Logo vầng trăng khuyết nghệ thuật)
class MoonaBrandLogo extends StatelessWidget {
  final double size;
  final bool hasShadow;

  const MoonaBrandLogo({
    super.key,
    this.size = 100,
    this.hasShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: const Color(0xFFE55C8A).withAlpha(isDark ? 85 : 60),
                  blurRadius: size * 0.28,
                  offset: Offset(0, size * 0.08),
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/icons/moona_logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
