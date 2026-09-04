// lib/features/motherhood/domain/models/child_profile_model.dart
//
// Mô hình hồ sơ bé sơ sinh & trẻ nhỏ (0-36 tháng).
// Hỗ trợ Clean Architecture, serialization JSON & Hive, tính ngày tuổi và tuổi hiệu chỉnh.

class ChildProfileModel {
  final String childId;
  final String parentUid;
  final String name;
  final DateTime birthDate;
  final String gender; // 'boy' | 'girl' | 'unspecified'
  final double? birthWeightKg;
  final double? birthHeightCm;
  final double? birthHeadCircumferenceCm;
  final DateTime? estimatedDueDate; // Dành cho bé sinh non (tính tuổi hiệu chỉnh)
  final bool isBreastfeedingExclusively; // Đang bú mẹ hoàn toàn (thuật toán LAM)
  final bool isPaused; // Tạm dừng tracking (chế độ chữa lành)
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ChildProfileModel({
    required this.childId,
    required this.parentUid,
    required this.name,
    required this.birthDate,
    this.gender = 'unspecified',
    this.birthWeightKg,
    this.birthHeightCm,
    this.birthHeadCircumferenceCm,
    this.estimatedDueDate,
    this.isBreastfeedingExclusively = true,
    this.isPaused = false,
    required this.createdAt,
    this.updatedAt,
  });

  /// Tính số ngày tuổi của bé tính đến [now] (mặc định DateTime.now())
  int getAgeInDays([DateTime? now]) {
    final target = now ?? DateTime.now();
    return target.difference(birthDate).inDays.clamp(0, 3650);
  }

  /// Tính số tháng tuổi (làm tròn 30 ngày/tháng)
  int getAgeInMonths([DateTime? now]) {
    return (getAgeInDays(now) / 30.4375).floor().clamp(0, 120);
  }

  /// Tính số tuần tuổi
  int getAgeInWeeks([DateTime? now]) {
    return (getAgeInDays(now) / 7).floor().clamp(0, 520);
  }

  /// Tuổi hiệu chỉnh (tuần) cho bé sinh non nếu có [estimatedDueDate]
  int getCorrectedAgeInWeeks([DateTime? now]) {
    if (estimatedDueDate == null) return getAgeInWeeks(now);
    final target = now ?? DateTime.now();
    final diffDays = target.difference(estimatedDueDate!).inDays;
    return (diffDays / 7).floor().clamp(0, 520);
  }

  /// Chuỗi hiển thị tuổi thân thiện cho giao diện (VD: "2 tháng 15 ngày")
  String getAgeDisplay([DateTime? now]) {
    final days = getAgeInDays(now);
    if (days < 7) {
      return '$days ngày tuổi';
    } else if (days < 30) {
      final weeks = days ~/ 7;
      final remDays = days % 7;
      return remDays > 0 ? '$weeks tuần $remDays ngày' : '$weeks tuần tuổi';
    } else {
      final months = (days / 30.4375).floor();
      final remDays = (days - (months * 30.4375)).round();
      return remDays > 0 ? '$months tháng $remDays ngày' : '$months tháng tuổi';
    }
  }

  ChildProfileModel copyWith({
    String? childId,
    String? parentUid,
    String? name,
    DateTime? birthDate,
    String? gender,
    double? birthWeightKg,
    double? birthHeightCm,
    double? birthHeadCircumferenceCm,
    DateTime? estimatedDueDate,
    bool? isBreastfeedingExclusively,
    bool? isPaused,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChildProfileModel(
      childId: childId ?? this.childId,
      parentUid: parentUid ?? this.parentUid,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      birthWeightKg: birthWeightKg ?? this.birthWeightKg,
      birthHeightCm: birthHeightCm ?? this.birthHeightCm,
      birthHeadCircumferenceCm: birthHeadCircumferenceCm ?? this.birthHeadCircumferenceCm,
      estimatedDueDate: estimatedDueDate ?? this.estimatedDueDate,
      isBreastfeedingExclusively: isBreastfeedingExclusively ?? this.isBreastfeedingExclusively,
      isPaused: isPaused ?? this.isPaused,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'childId': childId,
      'parentUid': parentUid,
      'name': name,
      'birthDate': birthDate.toIso8601String(),
      'gender': gender,
      'birthWeightKg': birthWeightKg,
      'birthHeightCm': birthHeightCm,
      'birthHeadCircumferenceCm': birthHeadCircumferenceCm,
      'estimatedDueDate': estimatedDueDate?.toIso8601String(),
      'isBreastfeedingExclusively': isBreastfeedingExclusively,
      'isPaused': isPaused,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory ChildProfileModel.fromJson(Map<String, dynamic> json) {
    return ChildProfileModel(
      childId: json['childId'] as String? ?? '',
      parentUid: json['parentUid'] as String? ?? '',
      name: json['name'] as String? ?? 'Bé yêu',
      birthDate: json['birthDate'] != null
          ? DateTime.tryParse(json['birthDate'] as String) ?? DateTime.now()
          : DateTime.now(),
      gender: json['gender'] as String? ?? 'unspecified',
      birthWeightKg: (json['birthWeightKg'] as num?)?.toDouble(),
      birthHeightCm: (json['birthHeightCm'] as num?)?.toDouble(),
      birthHeadCircumferenceCm: (json['birthHeadCircumferenceCm'] as num?)?.toDouble(),
      estimatedDueDate: json['estimatedDueDate'] != null
          ? DateTime.tryParse(json['estimatedDueDate'] as String)
          : null,
      isBreastfeedingExclusively: json['isBreastfeedingExclusively'] as bool? ?? true,
      isPaused: json['isPaused'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChildProfileModel &&
          runtimeType == other.runtimeType &&
          childId == other.childId &&
          name == other.name &&
          birthDate == other.birthDate &&
          gender == other.gender &&
          isBreastfeedingExclusively == other.isBreastfeedingExclusively &&
          isPaused == other.isPaused;

  @override
  int get hashCode =>
      childId.hashCode ^
      name.hashCode ^
      birthDate.hashCode ^
      gender.hashCode ^
      isBreastfeedingExclusively.hashCode ^
      isPaused.hashCode;
}
