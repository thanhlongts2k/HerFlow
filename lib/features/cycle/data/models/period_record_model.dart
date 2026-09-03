// lib/features/cycle/data/models/period_record_model.dart
import '../../domain/entities/period_record.dart';

/// Model hỗ trợ chuyển đổi PeriodRecord sang Map/JSON để lưu trữ vào Hive
class PeriodRecordModel {
  static Map<String, dynamic> toMap(PeriodRecord entity) {
    return {
      'id': entity.id,
      'startDate': entity.startDate.toIso8601String(),
      'endDate': entity.endDate?.toIso8601String(),
      'flowIntensity': entity.flowIntensity.name,
      'isOngoing': entity.isOngoing,
    };
  }

  static PeriodRecord fromMap(Map<String, dynamic> map) {
    return PeriodRecord(
      id: map['id'] as String,
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate'] as String) : null,
      flowIntensity: FlowIntensity.values.firstWhere(
        (e) => e.name == map['flowIntensity'],
        orElse: () => FlowIntensity.medium,
      ),
      isOngoing: map['isOngoing'] as bool? ?? false,
    );
  }
}
