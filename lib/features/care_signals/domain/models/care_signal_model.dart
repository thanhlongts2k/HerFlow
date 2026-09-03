// lib/features/care_signals/domain/models/care_signal_model.dart

/// Các loại tín hiệu yêu thương Vợ gửi cho Chồng
enum CareSignalType {
  hug,        // Ôm
  kiss,       // Hôn
  coffee,     // Pha cà phê
  cuddle,     // Snuggle
  message,    // Tin nhắn yêu thương
  remind,     // Nhắc nhở nhẹ nhàng
}

extension CareSignalTypeExt on CareSignalType {
  String get label {
    switch (this) {
      case CareSignalType.hug:      return 'Muốn được ôm 🤗';
      case CareSignalType.kiss:     return 'Muốn được hôn 💋';
      case CareSignalType.coffee:   return 'Pha cà phê nhé ☕';
      case CareSignalType.cuddle:   return 'Ngồi snuggle cùng nhau 🛋️';
      case CareSignalType.message:  return 'Nhắn tin thương yêu 💌';
      case CareSignalType.remind:   return 'Nhắc nhở nhẹ nhàng 🔔';
    }
  }

  String get emoji {
    switch (this) {
      case CareSignalType.hug:      return '🤗';
      case CareSignalType.kiss:     return '💋';
      case CareSignalType.coffee:   return '☕';
      case CareSignalType.cuddle:   return '🛋️';
      case CareSignalType.message:  return '💌';
      case CareSignalType.remind:   return '🔔';
    }
  }
}

/// Model tín hiệu yêu thương từ Vợ gửi Chồng qua Cloud Firestore
class CareSignalModel {
  final String id;
  final String coupleId;
  final CareSignalType type;
  final String? customNote;
  final DateTime sentAt;
  final bool isRead;

  const CareSignalModel({
    required this.id,
    required this.coupleId,
    required this.type,
    this.customNote,
    required this.sentAt,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'coupleId': coupleId,
    'type': type.name,
    'customNote': customNote,
    'sentAt': sentAt.toIso8601String(),
    'isRead': isRead,
  };

  factory CareSignalModel.fromMap(Map<String, dynamic> map) => CareSignalModel(
    id: map['id'] as String? ?? '',
    coupleId: map['coupleId'] as String? ?? '',
    type: CareSignalType.values.firstWhere(
      (e) => e.name == map['type'],
      orElse: () => CareSignalType.hug,
    ),
    customNote: map['customNote'] as String?,
    sentAt: DateTime.tryParse(map['sentAt'] as String? ?? '') ?? DateTime.now(),
    isRead: map['isRead'] as bool? ?? false,
  );
}
