// lib/core/widgets/offline_banner.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:herflow/core/network/network_connectivity_provider.dart';

/// Banner hiển thị khi ứng dụng mất kết nối mạng
/// Xuất hiện trơn tru với AnimatedContainer phía trên nội dung chính
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      height: isOnline ? 0 : 32,
      color: Colors.orange.shade700,
      child: isOnline
          ? const SizedBox.shrink()
          : const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'Đang offline — Dữ liệu sẽ đồng bộ khi có mạng',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
