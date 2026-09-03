// lib/features/cycle/data/datasources/cycle_local_datasource.dart
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:herflow/core/constants/app_constants.dart';
import 'package:herflow/core/utils/date_utils.dart';
import 'package:herflow/core/utils/user_scope.dart';
import '../../domain/entities/period_record.dart';
import '../models/period_record_model.dart';

/// Nguồn dữ liệu cục bộ Hive cho chu kỳ kinh nguyệt
/// Đã được User-Scoped theo UID người dùng để chống rò rỉ dữ liệu chu kỳ chéo giữa các tài khoản.
class CycleLocalDataSource {
  final Box _box;
  static const String _recordsKey = 'period_records_list';
  static const String _cleanupVersionKey = 'cycle_records_cleanup_v20260903_v2';

  CycleLocalDataSource(this._box);

  String _k(String baseKey) => UserScope.key(baseKey);

  DateTime getLastPeriodStart() {
    final raw = _box.get(_k(AppConstants.keyLastPeriodStart));
    if (raw != null && raw is String) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return AppDateUtils.normalize(parsed);
    }
    // Mặc định: mốc chuẩn 11/08/2026 theo thiết lập ban đầu
    return AppDateUtils.normalize(DateTime(2026, 8, 11));
  }

  Future<void> saveLastPeriodStart(DateTime date) async {
    final now = AppDateUtils.normalize(DateTime.now());
    final validDate = date.isAfter(now) ? now : AppDateUtils.normalize(date);
    await _box.put(_k(AppConstants.keyLastPeriodStart), validDate.toIso8601String());
  }

  int getCycleLength() {
    final val = _box.get(_k(AppConstants.keyCycleLength));
    if (val != null && val is int) return val.clamp(21, 45);
    return AppConstants.defaultCycleLength;
  }

  Future<void> saveCycleLength(int days) async {
    final validDays = days.clamp(21, 45);
    await _box.put(_k(AppConstants.keyCycleLength), validDays);
  }

  int getPeriodDuration() {
    final val = _box.get(_k(AppConstants.keyPeriodDuration));
    if (val != null && val is int) return val.clamp(2, 10);
    return AppConstants.defaultPeriodDuration;
  }

  Future<void> savePeriodDuration(int days) async {
    final validDays = days.clamp(2, 10);
    await _box.put(_k(AppConstants.keyPeriodDuration), validDays);
  }

  /// Dọn dẹp dữ liệu rác mẫu cũ (02-06/08 và 28-31/08) cho user hiện tại
  void _cleanDirtyRecords() {
    final raw = _box.get(_k(_recordsKey));
    final validRecords = <PeriodRecord>[];

    if (raw is List) {
      for (final item in raw) {
        try {
          PeriodRecord r;
          if (item is String) {
            r = PeriodRecordModel.fromMap(json.decode(item));
          } else if (item is Map) {
            r = PeriodRecordModel.fromMap(Map<String, dynamic>.from(item));
          } else {
            continue;
          }

          // Loại bỏ các bản ghi mock rác ngày 02-06/08 và 28-31/08
          final startNorm = AppDateUtils.normalize(r.startDate);
          final isDirtyAugustRecord = (startNorm.month == 8 && startNorm.year == 2026) &&
              (startNorm.day <= 6 || startNorm.day >= 27);

          if (!isDirtyAugustRecord) {
            validRecords.add(r);
          }
        } catch (_) {}
      }
    }

    // Nếu không còn bản ghi nào hợp lệ, khởi tạo duy nhất mốc chuẩn 11/08 - 15/08
    if (validRecords.isEmpty) {
      final anchorStart = DateTime(2026, 8, 11);
      final duration = getPeriodDuration();
      validRecords.add(
        PeriodRecord(
          id: 'anchor_period_2026_08_11',
          startDate: anchorStart,
          endDate: anchorStart.add(Duration(days: duration - 1)),
          flowIntensity: FlowIntensity.medium,
          isOngoing: false,
        ),
      );
      saveLastPeriodStart(anchorStart);
    }

    // Sắp xếp giảm dần theo startDate
    validRecords.sort((a, b) => b.startDate.compareTo(a.startDate));
    final rawList = validRecords.map((r) => json.encode(PeriodRecordModel.toMap(r))).toList();
    _box.put(_k(_recordsKey), rawList);
    _box.put(_k(_cleanupVersionKey), true);
  }

  List<PeriodRecord> getAllPeriodRecords() {
    // Tự động dọn dẹp dữ liệu mẫu cũ nếu chưa thực hiện
    if (_box.get(_k(_cleanupVersionKey)) != true) {
      _cleanDirtyRecords();
    }

    final raw = _box.get(_k(_recordsKey));
    if (raw == null || raw is! List) {
      // Nếu chưa có, tạo bản ghi mốc chuẩn 11/08
      final defaultStart = getLastPeriodStart();
      final defaultRecord = PeriodRecord(
        id: 'anchor_period_2026_08_11',
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
    await _box.put(_k(_recordsKey), rawList);

    // Cập nhật ngày bắt đầu chu kỳ gần nhất nếu cần
    if (list.isNotEmpty) {
      await saveLastPeriodStart(list.first.startDate);
    }
  }

  Future<void> deletePeriodRecord(String id) async {
    final list = getAllPeriodRecords();
    list.removeWhere((r) => r.id == id);
    final rawList = list.map((r) => json.encode(PeriodRecordModel.toMap(r))).toList();
    await _box.put(_k(_recordsKey), rawList);

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
      // Nếu đã có: xóa kỳ kinh đó
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
