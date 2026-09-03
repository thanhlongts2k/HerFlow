// lib/core/network/network_connectivity_provider.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider theo dõi trạng thái kết nối mạng theo thời gian thực
final isOnlineProvider = StateNotifierProvider<_ConnectivityNotifier, bool>((ref) {
  return _ConnectivityNotifier();
});

class _ConnectivityNotifier extends StateNotifier<bool> {
  StreamSubscription<List<ConnectivityResult>>? _sub;

  _ConnectivityNotifier() : super(true) {
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      state = results.any((r) => r != ConnectivityResult.none);
    });
    // Kiểm tra ngay trạng thái ban đầu
    Connectivity().checkConnectivity().then((results) {
      state = results.any((r) => r != ConnectivityResult.none);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
