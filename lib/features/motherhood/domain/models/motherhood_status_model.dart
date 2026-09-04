// lib/features/motherhood/domain/models/motherhood_status_model.dart
//
// Mô hình trạng thái tóm tắt giai đoạn Nuôi con (Motherhood Status)
// Phục vụ đồng bộ Cloud Firestore sang máy Bạn đời tại:
// `couples/{coupleId}/motherhoodStatus/today`
//
// Tuân thủ Data Boundary (Rule 6): Chỉ đồng bộ dữ liệu tóm tắt cần thiết
// để Bạn đời nắm được nhịp sinh hoạt của bé và chủ động đỡ đần.

class MotherhoodStatusModel {
  final String coupleId;
  final String? activeChildId;
  final String? activeChildName;
  final String? activeChildAgeDisplay;
  final DateTime? lastFeedingTime;
  final String? lastFeedingSummary;
  final DateTime? lastDiaperTime;
  final String? lastDiaperSummary;
  final DateTime? lastSleepTime;
  final int? lastSleepDurationMinutes;
  final bool isStormPeriod;
  final String? currentLeapTitle;
  final String? careTip;
  final DateTime updatedAt;
  final String updatedByUid;
  final String updatedByRole; // 'wife' | 'husband'

  const MotherhoodStatusModel({
    required this.coupleId,
    this.activeChildId,
    this.activeChildName,
    this.activeChildAgeDisplay,
    this.lastFeedingTime,
    this.lastFeedingSummary,
    this.lastDiaperTime,
    this.lastDiaperSummary,
    this.lastSleepTime,
    this.lastSleepDurationMinutes,
    this.isStormPeriod = false,
    this.currentLeapTitle,
    this.careTip,
    required this.updatedAt,
    this.updatedByUid = '',
    this.updatedByRole = 'wife',
  });

  Map<String, dynamic> toMap() {
    return {
      'coupleId': coupleId,
      'activeChildId': activeChildId,
      'activeChildName': activeChildName,
      'activeChildAgeDisplay': activeChildAgeDisplay,
      'lastFeedingTime': lastFeedingTime?.toIso8601String(),
      'lastFeedingSummary': lastFeedingSummary,
      'lastDiaperTime': lastDiaperTime?.toIso8601String(),
      'lastDiaperSummary': lastDiaperSummary,
      'lastSleepTime': lastSleepTime?.toIso8601String(),
      'lastSleepDurationMinutes': lastSleepDurationMinutes,
      'isStormPeriod': isStormPeriod,
      'currentLeapTitle': currentLeapTitle,
      'careTip': careTip,
      'updatedAt': updatedAt.toIso8601String(),
      'updatedByUid': updatedByUid,
      'updatedByRole': updatedByRole,
    };
  }

  factory MotherhoodStatusModel.fromMap(Map<String, dynamic> map) {
    return MotherhoodStatusModel(
      coupleId: map['coupleId'] as String? ?? '',
      activeChildId: map['activeChildId'] as String?,
      activeChildName: map['activeChildName'] as String?,
      activeChildAgeDisplay: map['activeChildAgeDisplay'] as String?,
      lastFeedingTime: map['lastFeedingTime'] != null
          ? DateTime.tryParse(map['lastFeedingTime'] as String)
          : null,
      lastFeedingSummary: map['lastFeedingSummary'] as String?,
      lastDiaperTime: map['lastDiaperTime'] != null
          ? DateTime.tryParse(map['lastDiaperTime'] as String)
          : null,
      lastDiaperSummary: map['lastDiaperSummary'] as String?,
      lastSleepTime: map['lastSleepTime'] != null
          ? DateTime.tryParse(map['lastSleepTime'] as String)
          : null,
      lastSleepDurationMinutes: (map['lastSleepDurationMinutes'] as num?)?.toInt(),
      isStormPeriod: map['isStormPeriod'] as bool? ?? false,
      currentLeapTitle: map['currentLeapTitle'] as String?,
      careTip: map['careTip'] as String?,
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedByUid: map['updatedByUid'] as String? ?? '',
      updatedByRole: map['updatedByRole'] as String? ?? 'wife',
    );
  }

  MotherhoodStatusModel copyWith({
    String? coupleId,
    String? activeChildId,
    String? activeChildName,
    String? activeChildAgeDisplay,
    DateTime? lastFeedingTime,
    String? lastFeedingSummary,
    DateTime? lastDiaperTime,
    String? lastDiaperSummary,
    DateTime? lastSleepTime,
    int? lastSleepDurationMinutes,
    bool? isStormPeriod,
    String? currentLeapTitle,
    String? careTip,
    DateTime? updatedAt,
    String? updatedByUid,
    String? updatedByRole,
  }) {
    return MotherhoodStatusModel(
      coupleId: coupleId ?? this.coupleId,
      activeChildId: activeChildId ?? this.activeChildId,
      activeChildName: activeChildName ?? this.activeChildName,
      activeChildAgeDisplay: activeChildAgeDisplay ?? this.activeChildAgeDisplay,
      lastFeedingTime: lastFeedingTime ?? this.lastFeedingTime,
      lastFeedingSummary: lastFeedingSummary ?? this.lastFeedingSummary,
      lastDiaperTime: lastDiaperTime ?? this.lastDiaperTime,
      lastDiaperSummary: lastDiaperSummary ?? this.lastDiaperSummary,
      lastSleepTime: lastSleepTime ?? this.lastSleepTime,
      lastSleepDurationMinutes:
          lastSleepDurationMinutes ?? this.lastSleepDurationMinutes,
      isStormPeriod: isStormPeriod ?? this.isStormPeriod,
      currentLeapTitle: currentLeapTitle ?? this.currentLeapTitle,
      careTip: careTip ?? this.careTip,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedByUid: updatedByUid ?? this.updatedByUid,
      updatedByRole: updatedByRole ?? this.updatedByRole,
    );
  }
}
