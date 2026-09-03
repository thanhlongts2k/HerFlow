// lib/features/care_signals/presentation/controllers/care_signal_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:herflow/features/care_signals/domain/models/care_signal_model.dart';
import 'package:herflow/features/partner_sync/presentation/controllers/partner_sync_controller.dart';
import 'package:herflow/features/settings/presentation/controllers/nickname_controller.dart';

/// StreamProvider lắng nghe tín hiệu yêu thương mới nhất từ Vợ (phía Chồng)
final latestCareSignalStreamProvider = StreamProvider<CareSignalModel?>((ref) {
  final coupleId = ref.watch(savedCoupleIdProvider) ?? '';
  if (coupleId.isEmpty) {
    return Stream.value(null);
  }
  final repository = ref.watch(partnerSyncRepositoryProvider);
  return repository.watchLatestCareSignal(coupleId);
});

/// Provider quản lý gửi và phản hồi Care Signals
final careSignalControllerProvider = Provider((ref) => CareSignalService(ref));

class CareSignalService {
  final Ref _ref;
  CareSignalService(this._ref);

  /// Vợ gửi tín hiệu yêu thương (kèm customNote tùy chọn và danh xưng)
  Future<void> sendSignal(CareSignalType type, {String? customNote}) async {
    final coupleId = _ref.read(savedCoupleIdProvider) ?? '';
    final nicknameConfig = _ref.read(nicknameConfigProvider);

    final signal = CareSignalModel(
      id: const Uuid().v4(),
      coupleId: coupleId,
      type: type,
      customNote: (customNote != null && customNote.trim().isNotEmpty) ? customNote.trim() : null,
      sentAt: DateTime.now(),
      isRead: false,
      senderRole: 'wife',
      senderNickname: nicknameConfig.selfCallAs.isNotEmpty ? nicknameConfig.selfCallAs : 'Em bé',
      targetNickname: nicknameConfig.callPartnerAs.isNotEmpty ? nicknameConfig.callPartnerAs : 'Anh',
    );
    await _ref.read(partnerSyncRepositoryProvider).sendCareSignal(signal);
  }

  /// Chồng phản hồi nhanh 1 chạm lên tín hiệu của Vợ
  Future<void> respondSignal({
    required String signalId,
    required String responseMessage,
  }) async {
    await _ref.read(partnerSyncRepositoryProvider).respondCareSignal(
      signalId: signalId,
      responseMessage: responseMessage,
    );
  }
}
