// lib/features/lifecycle/domain/models/pregnancy_config_model.dart
import 'package:flutter/foundation.dart';
import 'package:herflow/features/lifecycle/domain/models/maternal_health_profile_model.dart';

/// Model cấu hình theo dõi thai kỳ (Pregnancy Mode)
@immutable
class PregnancyConfigModel {
  /// Ngày đầu tiên của kỳ kinh nguyệt cuối cùng (Last Menstrual Period)
  final DateTime? lastMenstrualPeriod;

  /// Ngày dự sinh ước tính (Estimated Due Date - LMP + 280 ngày)
  final DateTime? estimatedDueDate;

  /// Ngày thụ thai nếu biết (Conception Date)
  final DateTime? conceptionDate;

  /// Trạng thái theo dõi thai kỳ đang hoạt động
  final bool isTrackingActive;

  /// Hồ sơ thể trạng sinh học của mẹ bầu (Progressive Profiling)
  final MaternalHealthProfileModel? maternalProfile;

  const PregnancyConfigModel({
    this.lastMenstrualPeriod,
    this.estimatedDueDate,
    this.conceptionDate,
    this.isTrackingActive = true,
    this.maternalProfile,
  });

  /// Tạo bản sao với các thuộc tính thay đổi
  PregnancyConfigModel copyWith({
    DateTime? lastMenstrualPeriod,
    DateTime? estimatedDueDate,
    DateTime? conceptionDate,
    bool? isTrackingActive,
    MaternalHealthProfileModel? maternalProfile,
  }) {
    return PregnancyConfigModel(
      lastMenstrualPeriod: lastMenstrualPeriod ?? this.lastMenstrualPeriod,
      estimatedDueDate: estimatedDueDate ?? this.estimatedDueDate,
      conceptionDate: conceptionDate ?? this.conceptionDate,
      isTrackingActive: isTrackingActive ?? this.isTrackingActive,
      maternalProfile: maternalProfile ?? this.maternalProfile,
    );
  }

  /// Chuyển đổi thành Map để lưu trữ SharedPreferences / Hive / Firestore
  Map<String, dynamic> toMap() {
    return {
      'lastMenstrualPeriod': lastMenstrualPeriod?.toIso8601String(),
      'estimatedDueDate': estimatedDueDate?.toIso8601String(),
      'conceptionDate': conceptionDate?.toIso8601String(),
      'isTrackingActive': isTrackingActive,
      'maternalProfile': maternalProfile?.toMap(),
    };
  }

  /// Khởi tạo đối tượng từ Map lưu trữ (An toàn tuyệt đối với null)
  factory PregnancyConfigModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const PregnancyConfigModel();

    MaternalHealthProfileModel? parsedProfile;
    if (map['maternalProfile'] != null && map['maternalProfile'] is Map) {
      try {
        parsedProfile = MaternalHealthProfileModel.fromMap(
          Map<String, dynamic>.from(map['maternalProfile'] as Map),
        );
      } catch (e) {
        debugPrint('[PregnancyConfigModel] Error parsing maternalProfile: $e');
        parsedProfile = null;
      }
    }

    return PregnancyConfigModel(
      lastMenstrualPeriod: map['lastMenstrualPeriod'] != null
          ? DateTime.tryParse(map['lastMenstrualPeriod'].toString())
          : null,
      estimatedDueDate: map['estimatedDueDate'] != null
          ? DateTime.tryParse(map['estimatedDueDate'].toString())
          : null,
      conceptionDate: map['conceptionDate'] != null
          ? DateTime.tryParse(map['conceptionDate'].toString())
          : null,
      isTrackingActive: map['isTrackingActive'] as bool? ?? true,
      maternalProfile: parsedProfile,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PregnancyConfigModel &&
        other.lastMenstrualPeriod == lastMenstrualPeriod &&
        other.estimatedDueDate == estimatedDueDate &&
        other.conceptionDate == conceptionDate &&
        other.isTrackingActive == isTrackingActive &&
        other.maternalProfile == maternalProfile;
  }

  @override
  int get hashCode => Object.hash(
        lastMenstrualPeriod,
        estimatedDueDate,
        conceptionDate,
        isTrackingActive,
        maternalProfile,
      );

  @override
  String toString() {
    return 'PregnancyConfigModel(LMP: $lastMenstrualPeriod, EDD: $estimatedDueDate, active: $isTrackingActive, profile: $maternalProfile)';
  }
}

