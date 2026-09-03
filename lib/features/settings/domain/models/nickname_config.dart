// lib/features/settings/domain/models/nickname_config.dart
import 'package:herflow/core/constants/user_role.dart';

/// Model cấu hình danh xưng thân mật giữa hai người trong Moona (hỗ trợ đồng bộ 2 chiều)
class NicknameConfig {
  final String callPartnerAs;    // Tôi gọi đối phương là (VD: "Anh", "Em bé", "Bé iu")
  final String selfCallAs;        // Tôi tự xưng là (VD: "Em", "Anh", "Chồng yêu")
  final String partnerCallsMeAs;  // Đối phương gọi tôi là (VD: Chàng gọi Nàng là "Em bé")
  final String partnerSelfCallAs; // Đối phương tự xưng là (VD: Chàng tự xưng là "Anh")

  static const String defaultNickname = 'Người thương';
  static const String defaultForWifeCallingHusband = 'Anh';
  static const String defaultForWifeCallingSelf = 'Em';
  static const String defaultForHusbandCallingWife = 'Em bé';
  static const String defaultForHusbandCallingSelf = 'Anh';

  static const List<String> presets = [
    'Người thương',
    'Anh',
    'Em bé',
    'Bé iu',
    'Vợ yêu',
    'Chồng yêu',
    'Anh yêu',
    'Bạn đời',
  ];

  const NicknameConfig({
    this.callPartnerAs = defaultNickname,
    this.selfCallAs = defaultNickname,
    this.partnerCallsMeAs = defaultNickname,
    this.partnerSelfCallAs = defaultNickname,
  });

  /// Sinh cấu hình mặc định tinh tế dựa theo vai trò người dùng (Vợ / Chồng)
  factory NicknameConfig.defaultForRole(UserRole role) {
    if (role == UserRole.husband) {
      return const NicknameConfig(
        callPartnerAs: defaultForHusbandCallingWife,     // Chàng gọi nàng là "Em bé"
        selfCallAs: defaultForHusbandCallingSelf,         // Chàng tự xưng là "Anh"
        partnerCallsMeAs: defaultForWifeCallingHusband,   // Nàng gọi chàng là "Anh"
        partnerSelfCallAs: defaultForWifeCallingSelf,     // Nàng tự xưng là "Em"
      );
    }
    return const NicknameConfig(
      callPartnerAs: defaultForWifeCallingHusband,       // Nàng gọi chàng là "Anh"
      selfCallAs: defaultForWifeCallingSelf,             // Nàng tự xưng là "Em"
      partnerCallsMeAs: defaultForHusbandCallingWife,     // Chàng gọi nàng là "Em bé"
      partnerSelfCallAs: defaultForHusbandCallingSelf,   // Chàng tự xưng là "Anh"
    );
  }

  Map<String, dynamic> toMap() => {
    'callPartnerAs': callPartnerAs,
    'selfCallAs': selfCallAs,
    'partnerCallsMeAs': partnerCallsMeAs,
    'partnerSelfCallAs': partnerSelfCallAs,
  };

  /// Tạo map cập nhật theo đúng vai trò lên document couples/{coupleId}
  Map<String, dynamic> toCoupleSyncPayload(UserRole myRole) {
    if (myRole == UserRole.husband) {
      return {
        'husbandCallPartner': callPartnerAs,
        'husbandSelfCall': selfCallAs,
      };
    }
    return {
      'wifeCallPartner': callPartnerAs,
      'wifeSelfCall': selfCallAs,
    };
  }

  factory NicknameConfig.fromMap(Map<String, dynamic> map, [UserRole? role]) {
    final defaultCfg = role != null ? NicknameConfig.defaultForRole(role) : const NicknameConfig();
    final partner = map['callPartnerAs'] as String?;
    final self = map['selfCallAs'] as String?;
    final partnerCallsMe = map['partnerCallsMeAs'] as String?;
    final partnerSelf = map['partnerSelfCallAs'] as String?;

    return NicknameConfig(
      callPartnerAs: (partner != null && partner.trim().isNotEmpty)
          ? partner.trim()
          : defaultCfg.callPartnerAs,
      selfCallAs: (self != null && self.trim().isNotEmpty)
          ? self.trim()
          : defaultCfg.selfCallAs,
      partnerCallsMeAs: (partnerCallsMe != null && partnerCallsMe.trim().isNotEmpty)
          ? partnerCallsMe.trim()
          : defaultCfg.partnerCallsMeAs,
      partnerSelfCallAs: (partnerSelf != null && partnerSelf.trim().isNotEmpty)
          ? partnerSelf.trim()
          : defaultCfg.partnerSelfCallAs,
    );
  }

  /// Nạp danh xưng từ Document couples/{coupleId} theo đúng góc nhìn xưng hô (Perspective Mapping)
  factory NicknameConfig.fromCoupleDoc(
    Map<String, dynamic> data,
    UserRole myRole, {
    NicknameConfig? currentConfig,
  }) {
    final defaultCfg = NicknameConfig.defaultForRole(myRole);
    final fallback = currentConfig ?? defaultCfg;

    if (myRole == UserRole.wife) {
      // Góc nhìn của Vợ:
      final wifeCall = (data['wifeCallPartner'] as String?)?.trim();
      final wifeSelf = (data['wifeSelfCall'] as String?)?.trim();
      final husbandCall = (data['husbandCallPartner'] as String?)?.trim();
      final husbandSelf = (data['husbandSelfCall'] as String?)?.trim();

      return NicknameConfig(
        callPartnerAs: (wifeCall != null && wifeCall.isNotEmpty)
            ? wifeCall
            : fallback.callPartnerAs,
        selfCallAs: (wifeSelf != null && wifeSelf.isNotEmpty)
            ? wifeSelf
            : fallback.selfCallAs,
        partnerCallsMeAs: (husbandCall != null && husbandCall.isNotEmpty)
            ? husbandCall
            : defaultCfg.partnerCallsMeAs, // Chàng gọi Nàng là gì
        partnerSelfCallAs: (husbandSelf != null && husbandSelf.isNotEmpty)
            ? husbandSelf
            : defaultCfg.partnerSelfCallAs, // Chàng xưng là gì
      );
    } else {
      // Góc nhìn của Chồng:
      final husbandCall = (data['husbandCallPartner'] as String?)?.trim();
      final husbandSelf = (data['husbandSelfCall'] as String?)?.trim();
      final wifeCall = (data['wifeCallPartner'] as String?)?.trim();
      final wifeSelf = (data['wifeSelfCall'] as String?)?.trim();

      return NicknameConfig(
        callPartnerAs: (husbandCall != null && husbandCall.isNotEmpty)
            ? husbandCall
            : fallback.callPartnerAs,
        selfCallAs: (husbandSelf != null && husbandSelf.isNotEmpty)
            ? husbandSelf
            : fallback.selfCallAs,
        partnerCallsMeAs: (wifeCall != null && wifeCall.isNotEmpty)
            ? wifeCall
            : defaultCfg.partnerCallsMeAs, // Nàng gọi Chàng là gì
        partnerSelfCallAs: (wifeSelf != null && wifeSelf.isNotEmpty)
            ? wifeSelf
            : defaultCfg.partnerSelfCallAs, // Nàng xưng là gì
      );
    }
  }

  NicknameConfig copyWith({
    String? callPartnerAs,
    String? selfCallAs,
    String? partnerCallsMeAs,
    String? partnerSelfCallAs,
  }) {
    return NicknameConfig(
      callPartnerAs: (callPartnerAs != null && callPartnerAs.trim().isNotEmpty)
          ? callPartnerAs.trim()
          : this.callPartnerAs,
      selfCallAs: (selfCallAs != null && selfCallAs.trim().isNotEmpty)
          ? selfCallAs.trim()
          : this.selfCallAs,
      partnerCallsMeAs: (partnerCallsMeAs != null && partnerCallsMeAs.trim().isNotEmpty)
          ? partnerCallsMeAs.trim()
          : this.partnerCallsMeAs,
      partnerSelfCallAs: (partnerSelfCallAs != null && partnerSelfCallAs.trim().isNotEmpty)
          ? partnerSelfCallAs.trim()
          : this.partnerSelfCallAs,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NicknameConfig &&
          runtimeType == other.runtimeType &&
          callPartnerAs == other.callPartnerAs &&
          selfCallAs == other.selfCallAs &&
          partnerCallsMeAs == other.partnerCallsMeAs &&
          partnerSelfCallAs == other.partnerSelfCallAs;

  @override
  int get hashCode =>
      callPartnerAs.hashCode ^
      selfCallAs.hashCode ^
      partnerCallsMeAs.hashCode ^
      partnerSelfCallAs.hashCode;
}
