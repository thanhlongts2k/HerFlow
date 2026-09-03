// lib/features/cycle/presentation/controllers/cycle_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:herflow/core/constants/app_constants.dart';
import 'package:herflow/core/utils/date_utils.dart';
import '../../data/datasources/cycle_local_datasource.dart';
import '../../data/repositories/cycle_repository_impl.dart';
import '../../domain/entities/cycle_day_info.dart';
import '../../domain/entities/cycle_info.dart';
import '../../domain/entities/period_record.dart';
import '../../domain/repositories/cycle_repository.dart';

/// Provider cung cấp DataSource cục bộ Hive cho chu kỳ
final cycleLocalDataSourceProvider = Provider<CycleLocalDataSource>((ref) {
  final box = Hive.box(AppConstants.cycleBoxName);
  return CycleLocalDataSource(box);
});

/// Provider cung cấp Repository chu kỳ
final cycleRepositoryProvider = Provider<CycleRepository>((ref) {
  final dataSource = ref.watch(cycleLocalDataSourceProvider);
  return CycleRepositoryImpl(dataSource);
});

/// Ngày đang được chọn trên Lịch (Mặc định là hôm nay)
final selectedCalendarDateProvider = StateProvider<DateTime>((ref) {
  return AppDateUtils.normalize(DateTime.now());
});

/// Tháng đang focus trên Lịch
final focusedCalendarMonthProvider = StateProvider<DateTime>((ref) {
  return AppDateUtils.normalize(DateTime.now());
});

/// Controller quản lý trạng thái chu kỳ (Riverpod StateNotifier)
class CycleController extends StateNotifier<AsyncValue<CycleInfo>> {
  final CycleRepository _repository;

  CycleController(this._repository) : super(const AsyncValue.loading()) {
    loadCycleInfo();
  }

  Future<void> loadCycleInfo() async {
    try {
      final info = await _repository.getCycleInfo();
      state = AsyncValue.data(info);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setLastPeriodStart(DateTime date) async {
    await _repository.updateLastPeriodStart(date);
    await loadCycleInfo();
  }

  Future<void> setCycleLength(int days) async {
    await _repository.updateCycleLength(days);
    await loadCycleInfo();
  }

  Future<void> setPeriodDuration(int days) async {
    await _repository.updatePeriodDuration(days);
    await loadCycleInfo();
  }

  /// 1-Chạm: Đánh dấu hoặc hủy đánh dấu ngày hành kinh
  Future<void> togglePeriodDay(DateTime date) async {
    await _repository.togglePeriodDay(date);
    await loadCycleInfo();
  }

  /// Ghi nhận một kỳ kinh nguyệt mới hoàn chỉnh
  Future<void> logPeriodRecord({
    required DateTime startDate,
    DateTime? endDate,
    FlowIntensity flowIntensity = FlowIntensity.medium,
  }) async {
    final record = PeriodRecord(
      id: const Uuid().v4(),
      startDate: AppDateUtils.normalize(startDate),
      endDate: endDate != null ? AppDateUtils.normalize(endDate) : null,
      flowIntensity: flowIntensity,
      isOngoing: endDate == null,
    );
    await _repository.savePeriodRecord(record);
    await loadCycleInfo();
  }

  /// Xóa một kỳ kinh trong lịch sử
  Future<void> deletePeriodRecord(String id) async {
    await _repository.deletePeriodRecord(id);
    await loadCycleInfo();
  }
}

/// Provider cung cấp CycleController cho UI
final cycleControllerProvider = StateNotifierProvider<CycleController, AsyncValue<CycleInfo>>((ref) {
  final repo = ref.watch(cycleRepositoryProvider);
  return CycleController(repo);
});

/// Provider cung cấp thông tin sinh học chi tiết cho ngày đang được chọn trên Lịch
final selectedCycleDayInfoProvider = Provider<CycleDayInfo?>((ref) {
  final cycleAsync = ref.watch(cycleControllerProvider);
  final selectedDate = ref.watch(selectedCalendarDateProvider);

  return cycleAsync.maybeWhen(
    data: (info) => info.getDayInfo(selectedDate),
    orElse: () => null,
  );
});
