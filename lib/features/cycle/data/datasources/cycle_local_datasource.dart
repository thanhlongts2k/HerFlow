// lib/features/cycle/data/datasources/cycle_local_datasource.dart
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:herflow/core/constants/app_constants.dart';
import 'package:herflow/core/utils/date_utils.dart';
import '../../domain/entities/period_record.dart';
import '../models/period_record_model.dart';

/// Nguồn dữ liệu cục bộ Hive cho chu kỳ kinh nguyệt
class CycleLocalDataSource {
  final Box _box;
  static const String _recordsKey = 'period_records_list';

  CycleLocalDataSource(this._box);

  DateTime getLastPeriodStart() {
    final raw = _box.get(AppConstants.keyLastPeriodStart);
    if (raw != null && raw is String) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return AppDateUtils.normalize(parsed);
    }
    // Mặc định: ngày 1 của chu kỳ gần nhất cách đây 5 ngày
    return AppDateUtils.normalize(DateTime.now().subtract(const Duration(days: 4)));
  }

  Future<void> saveLastPeriodStart(DateTime date) async {
    await _box.put(AppConstants.keyLastPeriodStart, AppDateUtils.normalize(date).toIso8601String());
  }

  int getCycleLength() {
    final val = _box.get(AppConstants.keyCycleLength);
    if (val != null && val is int) return val;
    return AppConstants.defaultCycleLength;
  }

  Future<void> saveCycleLength(int days) async {
    await _box.put(AppConstants.keyCycleLength, days);
  }

  int getPeriodDuration() {
    final val = _box.get(AppConstants.keyPeriodDuration);
    if (val != null && val is int) return val;
    return AppConstants.defaultPeriodDuration;
  }

  Future<void> savePeriodDuration(int days) async {
    await _box.put(AppConstants.keyPeriodDuration, days);
  }

  List<PeriodRecord> getAllPeriodRecords() {
    final raw = _box.get(_recordsKey);
    if (raw == null || raw is! List) {
      // Nếu chưa có, tạo bản ghi mặc định cho chu kỳ gần nhất
      final defaultStart = getLastPeriodStart();
      final defaultRecord = PeriodRecord(
        id: 'initial_default_period',
        startDate: defaultStart,
        endDate: defaultStart.add(Duration(days: getPeriodDuration() - 1)),
        flowIntensity: FlowIntensity.medium,
        isOngoing: false,
      );
      return [defaultRecord];
    }

    try {
      return raw.map((item) {
        if (item is String) {
          final map = json.decode(item) as Map<String, dynamic>;
          return PeriodRecordModel.fromMap(map);
        } else if (item is Map) {
          return PeriodRecordModel.fromMap(Map<String, dynamic>.from(item));
        }
        throw Exception('Invalid record format');
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> savePeriodRecord(PeriodRecord record) async {
    final list = getAllPeriodRecords();
    final index = list.indexWhere((r) => r.id == record.id);

    if (index >= 0) {
      list[index] = record;
    } else {
      list.add(record);
    }

    // Sắp xếp theo ngày giảm dần
    list.sort((a, b) => b.startDate.compareTo(a.startDate));

    final rawList = list.map((r) => json.encode(PeriodRecordModel.toMap(r))).toList();
    await _box.put(_recordsKey, rawList);

    // Cập nhật ngày bắt đầu chu kỳ gần nhất nếu cần
    if (list.isNotEmpty) {
      await saveLastPeriodStart(list.first.startDate);
    }
  }

  Future<void> deletePeriodRecord(String id) async {
    final list = getAllPeriodRecords();
    list.removeWhere((r) => r.id == id);
    final rawList = list.map((r) => json.encode(PeriodRecordModel.toMap(r))).toList();
    await _box.put(_recordsKey, rawList);

    if (list.isNotEmpty) {
      await saveLastPeriodStart(list.first.startDate);
    }
  }

  /// 1-Chạm: Bật/Tắt ngày hành kinh
  Future<void> togglePeriodDay(DateTime date) async {
    final normDate = AppDateUtils.normalize(date);
    final list = getAllPeriodRecords();

    // Tìm xem ngày này đã nằm trong kỳ nào chưa
    PeriodRecord? matched;
    for (final r in list) {
      if (r.containsDate(normDate)) {
        matched = r;
        break;
      }
    }

    if (matched != null) {
      // Nếu đã có: xóa hoặc cắt ngắn kỳ kinh đó
      await deletePeriodRecord(matched.id);
    } else {
      // Nếu chưa có: tạo một kỳ kinh mới bắt đầu từ ngày này
      final duration = getPeriodDuration();
      final newRecord = PeriodRecord(
        id: const Uuid().v4(),
        startDate: normDate,
        endDate: normDate.add(Duration(days: duration - 1)),
        flowIntensity: FlowIntensity.medium,
        isOngoing: false,
      );
      await savePeriodRecord(newRecord);
    }
  }
}
