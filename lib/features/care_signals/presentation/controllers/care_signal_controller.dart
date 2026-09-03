// lib/features/care_signals/presentation/controllers/care_signal_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:herflow/features/care_signals/domain/models/care_signal_model.dart';

/// StreamProvider lắng nghe tín hiệu yêu thương mới nhất từ Vợ (phía Chồng)
/// Hiện tại trả về null — sẽ kết nối Firestore trong v0.4.0
final latestCareSignalStreamProvider = StreamProvider<CareSignalModel?>((ref) {
  return Stream.value(null);
});
