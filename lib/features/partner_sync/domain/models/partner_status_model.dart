// lib/features/partner_sync/domain/models/partner_status_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Mô hình dữ liệu trạng thái thể trạng & cảm xúc tóm tắt của Vợ đồng bộ lên Cloud cho Chồng xem
class PartnerStatusModel {
  final String coupleId;
  final String currentPhase;
  final int energyLevel;
  final List<String> moodTags;
  final String husbandActionTip;
  final DateTime updatedAt;

  const PartnerStatusModel({
    required this.coupleId,
    required this.currentPhase,
    required this.energyLevel,
    required this.moodTags,
    required this.husbandActionTip,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'coupleId': coupleId,
      'currentPhase': currentPhase,
      'energyLevel': energyLevel,
      'moodTags': moodTags,
      'husbandActionTip': husbandActionTip,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory PartnerStatusModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return PartnerStatusModel(
      coupleId: map['coupleId'] as String? ?? '',
      currentPhase: map['currentPhase'] as String? ?? 'Nang trứng',
      energyLevel: map['energyLevel'] as int? ?? 3,
      moodTags: List<String>.from(map['moodTags'] ?? []),
      husbandActionTip: map['husbandActionTip'] as String? ?? '',
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  factory PartnerStatusModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return PartnerStatusModel.fromMap(data);
  }

  PartnerStatusModel copyWith({
    String? coupleId,
    String? currentPhase,
    int? energyLevel,
    List<String>? moodTags,
    String? husbandActionTip,
    DateTime? updatedAt,
  }) {
    return PartnerStatusModel(
      coupleId: coupleId ?? this.coupleId,
      currentPhase: currentPhase ?? this.currentPhase,
      energyLevel: energyLevel ?? this.energyLevel,
      moodTags: moodTags ?? this.moodTags,
      husbandActionTip: husbandActionTip ?? this.husbandActionTip,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
