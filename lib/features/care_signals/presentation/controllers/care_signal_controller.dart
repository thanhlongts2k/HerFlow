import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:herflow/core/constants/user_role.dart';
import 'package:herflow/core/providers/user_role_provider.dart';
import 'package:herflow/features/care_signals/domain/models/care_signal_model.dart';
import 'package:herflow/features/partner_sync/presentation/controllers/partner_sync_controller.dart';
import 'package:herflow/features/settings/presentation/controllers/nickname_controller.dart';

/// StreamProvider lắng nghe tín hiệu yêu thương mới nhất (1 bản ghi)
final latestCareSignalStreamProvider = StreamProvider<CareSignalModel?>((ref) {
  final coupleId = ref.watch(savedCoupleIdProvider) ?? '';
  if (coupleId.isEmpty) {
    return Stream.value(null);
  }
  final repository = ref.watch(partnerSyncRepositoryProvider);
  return repository.watchLatestCareSignal(coupleId);
});

/// StreamProvider lắng nghe danh sách toàn bộ tin nhắn / tín hiệu trong Hộp Thư 2 chiều (Thread)
final coupleCareSignalsStreamProvider = StreamProvider<List<CareSignalModel>>((ref) {
  final coupleId = ref.watch(savedCoupleIdProvider) ?? '';
  if (coupleId.isEmpty) {
    return Stream.value([]);
  }
  final repository = ref.watch(partnerSyncRepositoryProvider);
  return repository.watchCoupleSignalsStream(coupleId, limit: 30);
});

/// Provider quản lý gửi và phản hồi Care Signals
final careSignalControllerProvider = Provider((ref) => CareSignalService(ref));

class CareSignalService {
  final Ref _ref;
  CareSignalService(this._ref);

  /// Gửi tín hiệu hoặc lời nhắn tình cảm 2 chiều (tự động nhận diện role Vợ hoặc Chồng)
  Future<void> sendSignal(CareSignalType type, {String? customNote}) async {
    final coupleId = _ref.read(savedCoupleIdProvider) ?? '';
    final nicknameConfig = _ref.read(nicknameConfigProvider);
    final userRole = _ref.read(userRoleProvider);
    final isHusband = userRole == UserRole.husband;

    final signal = CareSignalModel(
      id: const Uuid().v4(),
      coupleId: coupleId,
      type: type,
      customNote: (customNote != null && customNote.trim().isNotEmpty) ? customNote.trim() : null,
      sentAt: DateTime.now(),
      isRead: false,
      senderRole: isHusband ? 'husband' : 'wife',
      senderNickname: nicknameConfig.selfCallAs.isNotEmpty
          ? nicknameConfig.selfCallAs
          : (isHusband ? 'Anh' : 'Em bé'),
      targetNickname: nicknameConfig.callPartnerAs.isNotEmpty
          ? nicknameConfig.callPartnerAs
          : (isHusband ? 'Em bé' : 'Anh'),
    );
    await _ref.read(partnerSyncRepositoryProvider).sendCareSignal(signal);
  }

  /// Phản hồi nhanh 1 chạm lên tín hiệu (tạo tin nhắn mới trong Thread 2 chiều)
  Future<void> respondSignal({
    required String signalId,
    required String responseMessage,
  }) async {
    final nicknameConfig = _ref.read(nicknameConfigProvider);
    final userRole = _ref.read(userRoleProvider);
    final isHusband = userRole == UserRole.husband;

    await _ref.read(partnerSyncRepositoryProvider).respondCareSignal(
      signalId: signalId,
      responseMessage: responseMessage,
      senderRole: isHusband ? 'husband' : 'wife',
      senderNickname: nicknameConfig.selfCallAs.isNotEmpty
          ? nicknameConfig.selfCallAs
          : (isHusband ? 'Anh' : 'Em bé'),
      targetNickname: nicknameConfig.callPartnerAs.isNotEmpty
          ? nicknameConfig.callPartnerAs
          : (isHusband ? 'Em bé' : 'Anh'),
    );
  }
}
