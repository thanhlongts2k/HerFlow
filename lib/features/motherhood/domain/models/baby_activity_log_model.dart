// lib/features/motherhood/domain/models/baby_activity_log_model.dart
//
// Mô hình nhật ký hoạt động sơ sinh (Cữ bú, Giấc ngủ, Tã bỉm, v.v.)
// Hỗ trợ Clean Architecture, serialization JSON & Hive, truy vết phụ huynh ghi log.

enum ActivityType {
  feeding,
  sleep,
  diaper,
  tummyTime,
  bath,
  medicine,
}

enum FeedingType {
  breastLeft,
  breastRight,
  bottleBreastMilk,
  bottleFormula,
  solid,
}

enum DiaperType {
  wet,
  dirty,
  both,
  clean,
}

extension ActivityTypeExt on ActivityType {
  String get label {
    switch (this) {
      case ActivityType.feeding:
        return 'Cữ bú';
      case ActivityType.sleep:
        return 'Giấc ngủ';
      case ActivityType.diaper:
        return 'Thay tã';
      case ActivityType.tummyTime:
        return 'Nằm sấp (Tummy)';
      case ActivityType.bath:
        return 'Tắm bé';
      case ActivityType.medicine:
        return 'Uống thuốc/Vitamin';
    }
  }

  String get icon {
    switch (this) {
      case ActivityType.feeding:
        return '🍼';
      case ActivityType.sleep:
        return '😴';
      case ActivityType.diaper:
        return '🧷';
      case ActivityType.tummyTime:
        return '🐢';
      case ActivityType.bath:
        return '🛁';
      case ActivityType.medicine:
        return '💊';
    }
  }
}

class BabyActivityLogModel {
  final String id;
  final String childId;
  final String loggedByUid;
  final String loggedByRole; // 'wife' | 'husband'
  final ActivityType type;
  final DateTime timestamp;
  final DateTime? endTime;
  final int? durationMinutes;
  final double? amountMl; // Dành cho bú bình
  final FeedingType? feedingType;
  final DiaperType? diaperType;
  final String? notes;

  const BabyActivityLogModel({
    required this.id,
    required this.childId,
    required this.loggedByUid,
    this.loggedByRole = 'wife',
    required this.type,
    required this.timestamp,
    this.endTime,
    this.durationMinutes,
    this.amountMl,
    this.feedingType,
    this.diaperType,
    this.notes,
  });

  /// Tính thời lượng thực tế (phút)
  int get calculatedDurationMinutes {
    if (durationMinutes != null && durationMinutes! > 0) return durationMinutes!;
    if (endTime != null) {
      return endTime!.difference(timestamp).inMinutes.clamp(1, 1440);
    }
    return 0;
  }

  BabyActivityLogModel copyWith({
    String? id,
    String? childId,
    String? loggedByUid,
    String? loggedByRole,
    ActivityType? type,
    DateTime? timestamp,
    DateTime? endTime,
    int? durationMinutes,
    double? amountMl,
    FeedingType? feedingType,
    DiaperType? diaperType,
    String? notes,
  }) {
    return BabyActivityLogModel(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      loggedByUid: loggedByUid ?? this.loggedByUid,
      loggedByRole: loggedByRole ?? this.loggedByRole,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      amountMl: amountMl ?? this.amountMl,
      feedingType: feedingType ?? this.feedingType,
      diaperType: diaperType ?? this.diaperType,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'loggedByUid': loggedByUid,
      'loggedByRole': loggedByRole,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'durationMinutes': durationMinutes,
      'amountMl': amountMl,
      'feedingType': feedingType?.name,
      'diaperType': diaperType?.name,
      'notes': notes,
    };
  }

  factory BabyActivityLogModel.fromJson(Map<String, dynamic> json) {
    return BabyActivityLogModel(
      id: json['id'] as String? ?? '',
      childId: json['childId'] as String? ?? '',
      loggedByUid: json['loggedByUid'] as String? ?? '',
      loggedByRole: json['loggedByRole'] as String? ?? 'wife',
      type: ActivityType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ActivityType.feeding,
      ),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      endTime: json['endTime'] != null
          ? DateTime.tryParse(json['endTime'] as String)
          : null,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
      amountMl: (json['amountMl'] as num?)?.toDouble(),
      feedingType: json['feedingType'] != null
          ? FeedingType.values.firstWhere(
              (e) => e.name == json['feedingType'],
              orElse: () => FeedingType.breastLeft,
            )
          : null,
      diaperType: json['diaperType'] != null
          ? DiaperType.values.firstWhere(
              (e) => e.name == json['diaperType'],
              orElse: () => DiaperType.wet,
            )
          : null,
      notes: json['notes'] as String?,
    );
  }
}
