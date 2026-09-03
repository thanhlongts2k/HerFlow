// lib/features/settings/domain/models/nickname_config.dart
import 'package:herflow/core/constants/user_role.dart';

/// Model cấu hình danh xưng thân mật giữa hai người trong Moona
class NicknameConfig {
  final String callPartnerAs; // Tôi gọi đối phương là (VD: "Anh", "Em bé", "Bé iu")
  final String selfCallAs;     // Tôi tự xưng là (VD: "Em", "Anh", "Chồng yêu")

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
  });

  /// Sinh cấu hình mặc định tinh tế dựa theo vai trò người dùng (Vợ / Chồng)
  factory NicknameConfig.defaultForRole(UserRole role) {
    if (role == UserRole.husband) {
      return const NicknameConfig(
        callPartnerAs: defaultForHusbandCallingWife, // Chàng gọi nàng là "Em bé"
        selfCallAs: defaultForHusbandCallingSelf,     // Chàng tự xưng là "Anh"
      );
    }
    return const NicknameConfig(
      callPartnerAs: defaultForWifeCallingHusband,   // Nàng gọi chàng là "Anh"
      selfCallAs: defaultForWifeCallingSelf,         // Nàng tự xưng là "Em"
    );
  }

  Map<String, dynamic> toMap() => {
    'callPartnerAs': callPartnerAs,
    'selfCallAs': selfCallAs,
  };

  factory NicknameConfig.fromMap(Map<String, dynamic> map, [UserRole? role]) {
    final defaultCfg = role != null ? NicknameConfig.defaultForRole(role) : const NicknameConfig();
    final partner = map['callPartnerAs'] as String?;
    final self = map['selfCallAs'] as String?;

    return NicknameConfig(
      callPartnerAs: (partner != null && partner.trim().isNotEmpty)
          ? partner.trim()
          : defaultCfg.callPartnerAs,
      selfCallAs: (self != null && self.trim().isNotEmpty)
          ? self.trim()
          : defaultCfg.selfCallAs,
    );
  }

  NicknameConfig copyWith({
    String? callPartnerAs,
    String? selfCallAs,
  }) {
    return NicknameConfig(
      callPartnerAs: (callPartnerAs != null && callPartnerAs.trim().isNotEmpty)
          ? callPartnerAs.trim()
          : this.callPartnerAs,
      selfCallAs: (selfCallAs != null && selfCallAs.trim().isNotEmpty)
          ? selfCallAs.trim()
          : this.selfCallAs,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NicknameConfig &&
          runtimeType == other.runtimeType &&
          callPartnerAs == other.callPartnerAs &&
          selfCallAs == other.selfCallAs;

  @override
  int get hashCode => callPartnerAs.hashCode ^ selfCallAs.hashCode;
}
