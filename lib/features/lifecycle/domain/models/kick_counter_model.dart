// lib/features/lifecycle/domain/models/kick_counter_model.dart
//
// Mô hình phiên đếm cử động thai theo chuẩn Cardiff "Count to 10".
// Mục tiêu: Ghi nhận 10 cử động thai nhi trong vòng tối đa 2 giờ.

import 'package:flutter/foundation.dart';

/// Trạng thái phiên đếm cử động thai
enum KickSessionStatus {
  /// Đang đếm (Timer đang chạy, chưa đủ 10 cử động)
  inProgress,

  /// Đã đủ 10 cử động (Cardiff completed — trong 2 giờ)
  completed,

  /// Hết 2 giờ mà chưa đủ 10 cử động (cảnh báo y khoa)
  timedOut,
}

/// Mô hình một phiên đếm cử động thai theo chuẩn Cardiff "Count to 10"
@immutable
class KickSessionModel {
  /// Mục tiêu Cardiff: 10 cử động mỗi phiên
  static const int targetKickCount = 10;

  /// Giới hạn thời gian Cardiff: 2 giờ (120 phút)
  static const Duration cardiffTimeLimit = Duration(hours: 2);

  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final int kickCount;
  final KickSessionStatus status;
  final String? notes;

  const KickSessionModel({
    required this.id,
    required this.startTime,
    this.endTime,
    this.kickCount = 0,
    this.status = KickSessionStatus.inProgress,
    this.notes,
  });

  bool get isCompleted => status == KickSessionStatus.completed;
  bool get isInProgress => status == KickSessionStatus.inProgress;
  bool get isTimedOut => status == KickSessionStatus.timedOut;

  /// Số phút hoàn thành phiên (null nếu đang chạy)
  int? get completionMinutes {
    if (endTime == null) return null;
    return endTime!.difference(startTime).inMinutes;
  }

  /// Thời gian đã trôi qua kể từ bắt đầu đến thời điểm [now]
  Duration elapsedDuration([DateTime? now]) {
    final effective = now ?? DateTime.now();
    if (isCompleted || isTimedOut) {
      return endTime!.difference(startTime);
    }
    return effective.difference(startTime);
  }

  /// Kiểm tra phiên có đang trong giới hạn 2 giờ không
  bool get isWithinTimeLimit {
    final elapsed = DateTime.now().difference(startTime);
    return elapsed < cardiffTimeLimit;
  }

  /// Số cử động còn lại cần để đủ 10
  int get remainingKicks => (targetKickCount - kickCount).clamp(0, targetKickCount);

  KickSessionModel copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    int? kickCount,
    KickSessionStatus? status,
    String? notes,
  }) {
    return KickSessionModel(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      kickCount: kickCount ?? this.kickCount,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'kickCount': kickCount,
      'status': status.name,
      'notes': notes,
    };
  }

  factory KickSessionModel.fromMap(Map<String, dynamic> map) {
    return KickSessionModel(
      id: map['id'] as String? ?? '',
      startTime: DateTime.parse(map['startTime'] as String),
      endTime: map['endTime'] != null
          ? DateTime.tryParse(map['endTime'] as String)
          : null,
      kickCount: map['kickCount'] as int? ?? 0,
      status: KickSessionStatus.values.firstWhere(
        (e) => e.name == (map['status'] as String? ?? 'inProgress'),
        orElse: () => KickSessionStatus.inProgress,
      ),
      notes: map['notes'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KickSessionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'KickSessionModel(id: $id, kicks: $kickCount/$targetKickCount, status: ${status.name})';
}
