// lib/features/cycle/data/repositories/cycle_repository_impl.dart
import '../../domain/entities/cycle_info.dart';
import '../../domain/entities/period_record.dart';
import '../../domain/repositories/cycle_repository.dart';
import '../datasources/cycle_local_datasource.dart';

/// Triển khai thực tế CycleRepository sử dụng Local DataSource
class CycleRepositoryImpl implements CycleRepository {
  final CycleLocalDataSource _localDataSource;

  CycleRepositoryImpl(this._localDataSource);

  @override
  Future<CycleInfo> getCycleInfo() async {
    final start = _localDataSource.getLastPeriodStart();
    final length = _localDataSource.getCycleLength();
    final duration = _localDataSource.getPeriodDuration();
    final records = _localDataSource.getAllPeriodRecords();

    return CycleInfo(
      lastPeriodStart: start,
      cycleLength: length,
      periodDuration: duration,
      records: records,
    );
  }

  @override
  Future<void> updateLastPeriodStart(DateTime date) async {
    await _localDataSource.saveLastPeriodStart(date);
  }

  @override
  Future<void> updateCycleLength(int days) async {
    await _localDataSource.saveCycleLength(days);
  }

  @override
  Future<void> updatePeriodDuration(int days) async {
    await _localDataSource.savePeriodDuration(days);
  }

  @override
  Future<void> savePeriodRecord(PeriodRecord record) async {
    await _localDataSource.savePeriodRecord(record);
  }

  @override
  Future<void> deletePeriodRecord(String id) async {
    await _localDataSource.deletePeriodRecord(id);
  }

  @override
  Future<List<PeriodRecord>> getAllPeriodRecords() async {
    return _localDataSource.getAllPeriodRecords();
  }

  @override
  Future<void> togglePeriodDay(DateTime date) async {
    await _localDataSource.togglePeriodDay(date);
  }
}
