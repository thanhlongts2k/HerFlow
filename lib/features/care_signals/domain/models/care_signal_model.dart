// lib/features/care_signals/domain/models/care_signal_model.dart

/// Các loại tín hiệu yêu thương Vợ gửi cho Chồng
enum CareSignalType {
  hug,            // Ôm
  kiss,           // Hôn
  coffee,         // Pha cà phê
  cuddle,         // Snuggle
  message,        // Tin nhắn yêu thương
  remind,         // Nhắc nhở nhẹ nhàng
  husbandMessage, // Lời hỏi thăm từ Người thương
}

extension CareSignalTypeExt on CareSignalType {
  String get label {
    switch (this) {
      case CareSignalType.hug:            return 'Muốn được ôm 🤗';
      case CareSignalType.kiss:           return 'Muốn được hôn 💋';
      case CareSignalType.coffee:         return 'Pha cà phê nhé ☕';
      case CareSignalType.cuddle:         return 'Ngồi snuggle cùng nhau 🛋️';
      case CareSignalType.message:        return 'Nhắn tin thương yêu 💌';
      case CareSignalType.remind:         return 'Nhắc nhở nhẹ nhàng 🔔';
      case CareSignalType.husbandMessage: return 'Hỏi thăm & Nhắn nhủ nàng 💬';
    }
  }

  String get emoji {
    switch (this) {
      case CareSignalType.hug:            return '🤗';
      case CareSignalType.kiss:           return '💋';
      case CareSignalType.coffee:         return '☕';
      case CareSignalType.cuddle:         return '🛋️';
      case CareSignalType.message:        return '💌';
      case CareSignalType.remind:         return '🔔';
      case CareSignalType.husbandMessage: return '💬';
    }
  }
}

/// Model tín hiệu yêu thương từ Vợ gửi Chồng qua Cloud Firestore & phản hồi 2 chiều
class CareSignalModel {
  final String id;
  final String coupleId;
  final CareSignalType type;
  final String? customNote;
  final DateTime sentAt;
  final bool isRead;
  final String? responseMessage;
  final DateTime? respondedAt;
  final String? senderRole;      // 'wife' hoặc 'husband'
  final String? senderNickname;  // Danh xưng người gửi (VD: Anh yêu, Vợ yêu)
  final String? targetNickname;  // Danh xưng người nhận

  const CareSignalModel({
    required this.id,
    required this.coupleId,
    required this.type,
    this.customNote,
    required this.sentAt,
    this.isRead = false,
    this.responseMessage,
    this.respondedAt,
    this.senderRole,
    this.senderNickname,
    this.targetNickname,
  });

  /// Kiểm tra xem đã có người bấm phản hồi hay chưa
  bool get isResponded => responseMessage != null && responseMessage!.isNotEmpty;

  /// Kiểm tra xem tín hiệu này có xuất phát từ Chồng không
  bool get isFromHusband => senderRole == 'husband' || type == CareSignalType.husbandMessage;

  Map<String, dynamic> toMap() => {
    'id': id,
    'coupleId': coupleId,
    'type': type.name,
    'customNote': customNote,
    'sentAt': sentAt.toIso8601String(),
    'isRead': isRead,
    'responseMessage': responseMessage,
    'respondedAt': respondedAt?.toIso8601String(),
    'senderRole': senderRole,
    'senderNickname': senderNickname,
    'targetNickname': targetNickname,
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
    responseMessage: map['responseMessage'] as String?,
    respondedAt: map['respondedAt'] != null
        ? DateTime.tryParse(map['respondedAt'] as String)
        : null,
    senderRole: map['senderRole'] as String?,
    senderNickname: map['senderNickname'] as String?,
    targetNickname: map['targetNickname'] as String?,
  );

  CareSignalModel copyWith({
    String? id,
    String? coupleId,
    CareSignalType? type,
    String? customNote,
    DateTime? sentAt,
    bool? isRead,
    String? responseMessage,
    DateTime? respondedAt,
    String? senderRole,
    String? senderNickname,
    String? targetNickname,
  }) {
    return CareSignalModel(
      id: id ?? this.id,
      coupleId: coupleId ?? this.coupleId,
      type: type ?? this.type,
      customNote: customNote ?? this.customNote,
      sentAt: sentAt ?? this.sentAt,
      isRead: isRead ?? this.isRead,
      responseMessage: responseMessage ?? this.responseMessage,
      respondedAt: respondedAt ?? this.respondedAt,
      senderRole: senderRole ?? this.senderRole,
      senderNickname: senderNickname ?? this.senderNickname,
      targetNickname: targetNickname ?? this.targetNickname,
    );
  }
}
