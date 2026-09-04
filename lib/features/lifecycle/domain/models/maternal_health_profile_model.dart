// lib/features/lifecycle/domain/models/maternal_health_profile_model.dart
import 'package:flutter/foundation.dart';

/// Mô hình dữ liệu hồ sơ thể trạng và sức khỏe của mẹ bầu (Maternal Health Profile)
@immutable
class MaternalHealthProfileModel {
  /// Năm sinh của mẹ (để tính tuổi sinh học)
  final int? birthYear;

  /// Ngày tháng năm sinh chi tiết (nếu có)
  final DateTime? dateOfBirth;

  /// Chiều cao của mẹ (cm)
  final double? heightCm;

  /// Cân nặng trước khi mang thai (kg)
  final double? prePregnancyWeightKg;

  /// Cân nặng ghi nhận gần nhất trong thai kỳ (kg)
  final double? currentWeightKg;

  /// Tiền sử sinh con (Con so / Con rạ / Con thứ 3+)
  final String? parity;

  /// Kế hoạch sinh nở (Sinh thường / Sinh mổ / Đang cân nhắc)
  final String? deliveryPlan;

  /// Bệnh viện dự định sinh
  final String? targetHospital;

  /// Cờ xác định mang đa thai (sinh đôi, sinh ba) hay thai đơn (mặc định false: thai đơn - singleton)
  final bool isMultiplePregnancy;

  /// Thời điểm cập nhật cuối cùng
  final DateTime? updatedAt;

  const MaternalHealthProfileModel({
    this.birthYear,
    this.dateOfBirth,
    this.heightCm,
    this.prePregnancyWeightKg,
    this.currentWeightKg,
    this.parity,
    this.deliveryPlan,
    this.targetHospital,
    this.isMultiplePregnancy = false,
    this.updatedAt,
  });

  /// Tính tuổi sinh học của mẹ tại thời điểm hiện tại
  int? get maternalAge {
    if (birthYear != null && birthYear! > 1900) {
      return DateTime.now().year - birthYear!;
    }
    if (dateOfBirth != null) {
      final now = DateTime.now();
      int age = now.year - dateOfBirth!.year;
      if (now.month < dateOfBirth!.month ||
          (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
        age--;
      }
      return age;
    }
    return null;
  }

  /// Tính chỉ số BMI trước khi mang thai (Pre-pregnancy BMI)
  /// Đảm bảo an toàn tuyệt đối với phép chia cho 0
  double? get prePregnancyBmi {
    if (heightCm == null || heightCm! <= 0 || prePregnancyWeightKg == null || prePregnancyWeightKg! <= 0) {
      return null;
    }
    final heightM = heightCm! / 100.0;
    final rawBmi = prePregnancyWeightKg! / (heightM * heightM);
    return double.tryParse(rawBmi.toStringAsFixed(1));
  }

  /// Mức tăng cân thực tế ghi nhận đến thời điểm hiện tại (kg)
  double? get actualGainKg {
    if (currentWeightKg == null || prePregnancyWeightKg == null) {
      return null;
    }
    return double.tryParse((currentWeightKg! - prePregnancyWeightKg!).toStringAsFixed(1));
  }

  /// Đánh giá xem đã hoàn thiện các trường dữ liệu sinh học cơ bản (Chiều cao, Cân nặng, Tuổi)
  bool get isBiometricsComplete {
    final hasHeight = heightCm != null && heightCm! > 0;
    final hasWeight = prePregnancyWeightKg != null && prePregnancyWeightKg! > 0;
    final hasAge = (birthYear != null && birthYear! > 1900) || dateOfBirth != null;
    return hasHeight && hasWeight && hasAge;
  }

  /// Tính tỷ lệ % hoàn thiện hồ sơ thể trạng (0 - 100%) dựa trên 6 trường thông tin cốt lõi
  int get completionPercentage {
    int filledCount = 0;
    if ((birthYear != null && birthYear! > 1900) || dateOfBirth != null) filledCount++;
    if (heightCm != null && heightCm! > 0) filledCount++;
    if (prePregnancyWeightKg != null && prePregnancyWeightKg! > 0) filledCount++;
    if (parity != null && parity!.trim().isNotEmpty) filledCount++;
    if (deliveryPlan != null && deliveryPlan!.trim().isNotEmpty) filledCount++;
    if (targetHospital != null && targetHospital!.trim().isNotEmpty) filledCount++;

    return ((filledCount / 6.0) * 100).round();
  }

  /// Tạo bản sao có điều chỉnh thuộc tính
  MaternalHealthProfileModel copyWith({
    int? birthYear,
    DateTime? dateOfBirth,
    double? heightCm,
    double? prePregnancyWeightKg,
    double? currentWeightKg,
    String? parity,
    String? deliveryPlan,
    String? targetHospital,
    bool? isMultiplePregnancy,
    DateTime? updatedAt,
  }) {
    return MaternalHealthProfileModel(
      birthYear: birthYear ?? this.birthYear,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      heightCm: heightCm ?? this.heightCm,
      prePregnancyWeightKg: prePregnancyWeightKg ?? this.prePregnancyWeightKg,
      currentWeightKg: currentWeightKg ?? this.currentWeightKg,
      parity: parity ?? this.parity,
      deliveryPlan: deliveryPlan ?? this.deliveryPlan,
      targetHospital: targetHospital ?? this.targetHospital,
      isMultiplePregnancy: isMultiplePregnancy ?? this.isMultiplePregnancy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Chuyển đổi thành Map lưu trữ an toàn (Hive / Firestore)
  Map<String, dynamic> toMap() {
    return {
      'birthYear': birthYear,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'heightCm': heightCm,
      'prePregnancyWeightKg': prePregnancyWeightKg,
      'currentWeightKg': currentWeightKg,
      'parity': parity,
      'deliveryPlan': deliveryPlan,
      'targetHospital': targetHospital,
      'isMultiplePregnancy': isMultiplePregnancy,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Khởi tạo từ Map với cơ chế phòng thủ null-safety tuyệt đối
  factory MaternalHealthProfileModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const MaternalHealthProfileModel();

    return MaternalHealthProfileModel(
      birthYear: (map['birthYear'] as num?)?.toInt(),
      dateOfBirth: map['dateOfBirth'] != null
          ? DateTime.tryParse(map['dateOfBirth'].toString())
          : null,
      heightCm: (map['heightCm'] as num?)?.toDouble(),
      prePregnancyWeightKg: (map['prePregnancyWeightKg'] as num?)?.toDouble(),
      currentWeightKg: (map['currentWeightKg'] as num?)?.toDouble(),
      parity: map['parity'] as String?,
      deliveryPlan: map['deliveryPlan'] as String?,
      targetHospital: map['targetHospital'] as String?,
      isMultiplePregnancy: map['isMultiplePregnancy'] as bool? ?? false,
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString())
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MaternalHealthProfileModel &&
        other.birthYear == birthYear &&
        other.dateOfBirth == dateOfBirth &&
        other.heightCm == heightCm &&
        other.prePregnancyWeightKg == prePregnancyWeightKg &&
        other.currentWeightKg == currentWeightKg &&
        other.parity == parity &&
        other.deliveryPlan == deliveryPlan &&
        other.targetHospital == targetHospital &&
        other.isMultiplePregnancy == isMultiplePregnancy;
  }

  @override
  int get hashCode => Object.hash(
        birthYear,
        dateOfBirth,
        heightCm,
        prePregnancyWeightKg,
        currentWeightKg,
        parity,
        deliveryPlan,
        targetHospital,
        isMultiplePregnancy,
      );

  @override
  String toString() {
    return 'MaternalHealthProfileModel(age: $maternalAge, height: $heightCm, preWeight: $prePregnancyWeightKg, BMI: $prePregnancyBmi, complete: $completionPercentage%)';
  }
}
