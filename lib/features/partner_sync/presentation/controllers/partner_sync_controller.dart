// lib/features/partner_sync/presentation/controllers/partner_sync_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:herflow/core/constants/user_role.dart';
import 'package:herflow/core/network/network_connectivity_provider.dart';
import 'package:herflow/core/providers/user_role_provider.dart';
import 'package:herflow/features/cycle/presentation/controllers/cycle_controller.dart';
import 'package:herflow/features/mood/presentation/controllers/mood_controller.dart';
import 'package:herflow/features/partner_sync/data/partner_sync_repository.dart';
import 'package:herflow/features/partner_sync/domain/models/pairing_model.dart';
import 'package:herflow/features/partner_sync/domain/models/partner_status_model.dart';

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
  return repo.watchPartnerTodayStatus(coupleId);
});

/// Trạng thái của phiên ghép đôi (State model)
class PairingState {
  final bool isLoading;
  final String? activePairingCode;
  final PairingStatus? status;
  final String? errorMessage;
  final bool isSuccess;
  /// true = mã được tạo cục bộ do Firestore không khả dụng (chế độ thử nghiệm)
  final bool isOfflineCode;

  const PairingState({
    this.isLoading = false,
    this.activePairingCode,
    this.status,
    this.errorMessage,
    this.isSuccess = false,
    this.isOfflineCode = false,
  });

  PairingState copyWith({
    bool? isLoading,
    String? activePairingCode,
    PairingStatus? status,
    String? errorMessage,
    bool? isSuccess,
    bool? isOfflineCode,
  }) {
    return PairingState(
      isLoading: isLoading ?? this.isLoading,
      activePairingCode: activePairingCode ?? this.activePairingCode,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
      isOfflineCode: isOfflineCode ?? this.isOfflineCode,
    );
  }
}

/// Controller quản lý luồng tạo và nhập mã ghép đôi
class PartnerSyncController extends StateNotifier<PairingState> {
  final PartnerSyncRepository _repository;
  final Ref _ref;

  PartnerSyncController(this._repository, this._ref)
      : super(PairingState(
          activePairingCode: _ref
              .read(partnerSyncRepositoryProvider)
              .getSavedPairingCode(),
          isOfflineCode: _ref
              .read(partnerSyncRepositoryProvider)
              .isOfflineCode,
        )) {
    // Lắng nghe khôi phục kết nối mạng để tự động xả hàng đợi Offline Queue
    _ref.listen<bool>(isOnlineProvider, (previous, next) {
      if (next == true && (previous == false || previous == null)) {
        _repository.flushPendingSync();
      }
    });
  }

  /// 1. Vợ tạo mã ghép đôi mới
  /// Đảm bảo isLoading = false trong mọi trường hợp (try-catch-finally)
  Future<void> generatePairingCode() async {
    state = state.copyWith(isLoading: true, errorMessage: null, isOfflineCode: false);
    try {
      final result = await _repository.createPairingCode();

      // Cập nhật coupleId và vai trò
      _ref.read(savedCoupleIdProvider.notifier).state = result.pairing.coupleId;
      _ref.read(savedUserRoleProvider.notifier).state = 'wife';

      state = state.copyWith(
        activePairingCode: result.pairing.pairingCode,
        status: result.pairing.status,
        isOfflineCode: result.isOffline,
      );

      // Chỉ đẩy trạng thái Vợ lên Cloud nếu thực sự online
      if (!result.isOffline) {
        await syncCurrentWifeStatusToCloud();
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      // BẮT BUỘC: luôn reset isLoading trong finally để không bị treo UI
      state = state.copyWith(isLoading: false);
    }
  }

  /// 2. Chồng nhập mã 6 ký tự để kết nối
  Future<bool> connectWithCode(String code) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final pairing = await _repository.connectWithPairingCode(code);

      _ref.read(savedCoupleIdProvider.notifier).state = pairing.coupleId;
      _ref.read(savedUserRoleProvider.notifier).state = 'husband';

      // Tự động nhận diện vai trò Chồng: lưu vào Hive & State chuyển layout Chồng tức thì
      await _ref.read(userRoleProvider.notifier).setRole(UserRole.husband);

      state = state.copyWith(
        activePairingCode: pairing.pairingCode,
        status: PairingStatus.connected,
        isSuccess: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
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

    final cycleDay = cycleAsync.maybeWhen(
      data: (info) => info.getCycleDay(selectedDate),
      orElse: () => 1,
    );

    final moodSummary = moodEntry.mood.isNotEmpty
        ? (moodEntry.symptoms.isNotEmpty
            ? '${moodEntry.mood} (${moodEntry.symptoms.join(", ")})'
            : moodEntry.mood)
        : (moodEntry.symptoms.isNotEmpty
            ? moodEntry.symptoms.join(", ")
            : 'Bình thường');

    final status = PartnerStatusModel(
      coupleId: coupleId,
      currentPhase: phase.vietnameseName,
      cycleDay: cycleDay,
      energyLevel: moodEntry.energyLevel,
      moodTags: [if (moodEntry.mood.isNotEmpty) moodEntry.mood, ...moodEntry.symptoms],
      moodSummary: moodSummary,
      husbandActionTip: phase.husbandAdvice,
      updatedAt: DateTime.now(),
    );

    final isOnline = _ref.read(isOnlineProvider);
    await _repository.pushTodayStatus(status, isOnline: isOnline);
  }

  /// Alias tiện lợi để các Controller khác gọi đồng bộ
  Future<void> syncTodayStatus() => syncCurrentWifeStatusToCloud();

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
