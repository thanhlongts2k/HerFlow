// lib/features/partner_sync/presentation/controllers/partner_sync_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:herflow/core/network/network_connectivity_provider.dart';
import 'package:herflow/features/cycle/presentation/controllers/cycle_controller.dart';
import 'package:herflow/features/mood/presentation/controllers/mood_controller.dart';
import 'package:herflow/features/partner_sync/data/partner_sync_repository.dart';
import 'package:herflow/features/partner_sync/domain/models/pairing_model.dart';
import 'package:herflow/features/partner_sync/domain/models/partner_status_model.dart';
import 'package:herflow/features/widgets/services/widget_update_service.dart';

/// Provider cung cấp PartnerSyncRepository
final partnerSyncRepositoryProvider = Provider<PartnerSyncRepository>((ref) {
  return PartnerSyncRepository();
});

/// Provider coupleId đã lưu trong máy
final savedCoupleIdProvider = StateProvider<String?>((ref) {
  final repo = ref.watch(partnerSyncRepositoryProvider);
  return repo.getSavedCoupleId();
});

/// Provider vai trò người dùng ('wife' hoặc 'husband')
final savedUserRoleProvider = StateProvider<String?>((ref) {
  final repo = ref.watch(partnerSyncRepositoryProvider);
  return repo.getSavedUserRole();
});

/// Provider kiểm tra cờ pending sync
final isPendingSyncProvider = Provider<bool>((ref) {
  final repo = ref.watch(partnerSyncRepositoryProvider);
  // Re-evaluate whenever online status changes
  ref.watch(isOnlineProvider);
  return repo.isPendingSync();
});

/// StreamProvider lắng nghe trực tiếp trạng thái hôm nay của đối phương theo thời gian thực
final partnerLiveStatusStreamProvider = StreamProvider<PartnerStatusModel?>((ref) {
  final repo = ref.watch(partnerSyncRepositoryProvider);
  final coupleId = ref.watch(savedCoupleIdProvider);

  if (coupleId == null || coupleId.isEmpty) {
    return Stream.value(null);
  }
  return repo.watchPartnerTodayStatus(coupleId).map((status) {
    if (status != null) {
      WidgetUpdateService.updateFromPartnerStatus(status);
    }
    return status;
  });
});

/// Trạng thái của phiên ghép đôi (State model)
class PairingState {
  final bool isLoading;
  final String? activePairingCode;
  final PairingStatus? status;
  final String? errorMessage;
  final bool isSuccess;

  const PairingState({
    this.isLoading = false,
    this.activePairingCode,
    this.status,
    this.errorMessage,
    this.isSuccess = false,
  });

  PairingState copyWith({
    bool? isLoading,
    String? activePairingCode,
    PairingStatus? status,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return PairingState(
      isLoading: isLoading ?? this.isLoading,
      activePairingCode: activePairingCode ?? this.activePairingCode,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

/// Controller quản lý luồng tạo và nhập mã ghép đôi
class PartnerSyncController extends StateNotifier<PairingState> {
  final PartnerSyncRepository _repository;
  final Ref _ref;

  PartnerSyncController(this._repository, this._ref)
      : super(PairingState(activePairingCode: _repository.getSavedPairingCode())) {
    // Lắng nghe khôi phục kết nối mạng để tự động xả hàng đợi Offline Queue
    _ref.listen<bool>(isOnlineProvider, (previous, next) {
      if (next == true && (previous == false || previous == null)) {
        _repository.flushPendingSync();
      }
    });
  }

  /// 1. Vợ tạo mã ghép đôi mới
  Future<void> generatePairingCode() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final pairing = await _repository.createPairingCode();
      state = state.copyWith(
        isLoading: false,
        activePairingCode: pairing.pairingCode,
        status: pairing.status,
      );

      // Cập nhật coupleId và vai trò
      _ref.read(savedCoupleIdProvider.notifier).state = pairing.coupleId;
      _ref.read(savedUserRoleProvider.notifier).state = 'wife';

      // Đẩy ngay trạng thái hiện tại của Vợ lên Cloud
      await syncCurrentWifeStatusToCloud();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// 2. Chồng nhập mã 6 ký tự để kết nối
  Future<bool> connectWithCode(String code) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final pairing = await _repository.connectWithPairingCode(code);
      state = state.copyWith(
        isLoading: false,
        activePairingCode: pairing.pairingCode,
        status: PairingStatus.connected,
        isSuccess: true,
      );

      _ref.read(savedCoupleIdProvider.notifier).state = pairing.coupleId;
      _ref.read(savedUserRoleProvider.notifier).state = 'husband';
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// 3. Tự động đồng bộ trạng thái hôm nay của Vợ lên Cloud Firestore (Hỗ trợ Offline Queue)
  Future<void> syncCurrentWifeStatusToCloud() async {
    final coupleId = _repository.getSavedCoupleId();
    if (coupleId == null || coupleId.isEmpty) return;

    final cycleAsync = _ref.read(cycleControllerProvider);
    final selectedDate = _ref.read(selectedCalendarDateProvider);
    final moodEntry = _ref.read(selectedDateMoodProvider);

    final phase = cycleAsync.maybeWhen(
      data: (info) => info.getPhaseForDate(selectedDate),
      orElse: () => null,
    );

    if (phase == null) return;

    final status = PartnerStatusModel(
      coupleId: coupleId,
      currentPhase: phase.vietnameseName,
      energyLevel: moodEntry.energyLevel,
      moodTags: [moodEntry.mood, ...moodEntry.symptoms],
      husbandActionTip: phase.husbandAdvice,
      updatedAt: DateTime.now(),
    );

    final isOnline = _ref.read(isOnlineProvider);
    await _repository.pushTodayStatus(status, isOnline: isOnline);
    await WidgetUpdateService.updateFromPartnerStatus(status);
  }

  /// 4. Hủy kết nối cặp đôi
  Future<void> disconnect() async {
    await _repository.disconnectCouple();
    _ref.read(savedCoupleIdProvider.notifier).state = null;
    _ref.read(savedUserRoleProvider.notifier).state = null;
    state = const PairingState();
  }
}

/// Provider quản lý PartnerSyncController
final partnerSyncControllerProvider =
    StateNotifierProvider<PartnerSyncController, PairingState>((ref) {
  final repo = ref.watch(partnerSyncRepositoryProvider);
  return PartnerSyncController(repo, ref);
});
