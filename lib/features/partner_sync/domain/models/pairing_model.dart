// lib/features/partner_sync/domain/models/pairing_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Trạng thái của mã kết nối ghép đôi
enum PairingStatus {
  pending,
  connected,
  expired;

  static PairingStatus fromString(String? value) {
    switch (value) {
      case 'connected':
        return PairingStatus.connected;
      case 'expired':
        return PairingStatus.expired;
      case 'pending':
      default:
        return PairingStatus.pending;
    }
  }
}

/// Thực thể dữ liệu quản lý mã ghép đôi giữa Vợ và Chồng
class PairingModel {
  final String pairingCode;
  final String wifeUserId;
  final String coupleId;
  final PairingStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;

  const PairingModel({
    required this.pairingCode,
    required this.wifeUserId,
    required this.coupleId,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
  });

  /// Kiểm tra mã kết nối đã quá hạn 24 giờ chưa
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toMap() {
    return {
      'pairingCode': pairingCode,
      'wifeUserId': wifeUserId,
      'coupleId': coupleId,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
    };
  }

  factory PairingModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return PairingModel(
      pairingCode: map['pairingCode'] as String? ?? '',
      wifeUserId: map['wifeUserId'] as String? ?? '',
      coupleId: map['coupleId'] as String? ?? '',
      status: PairingStatus.fromString(map['status'] as String?),
      createdAt: parseDate(map['createdAt']),
      expiresAt: parseDate(map['expiresAt']),
    );
  }

  factory PairingModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return PairingModel.fromMap(data);
  }

  PairingModel copyWith({
    String? pairingCode,
    String? wifeUserId,
    String? coupleId,
    PairingStatus? status,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return PairingModel(
      pairingCode: pairingCode ?? this.pairingCode,
      wifeUserId: wifeUserId ?? this.wifeUserId,
      coupleId: coupleId ?? this.coupleId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
