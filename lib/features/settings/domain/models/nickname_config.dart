// lib/features/settings/domain/models/nickname_config.dart

/// Model cấu hình danh xưng thân mật giữa hai người trong Moona
class NicknameConfig {
  final String callPartnerAs; // Tôi gọi đối phương là (VD: "Bé iu", "Vợ yêu")
  final String selfCallAs;     // Tôi tự xưng là (VD: "Anh", "Chồng yêu")

  static const String defaultNickname = 'Người thương';

  static const List<String> presets = [
    'Người thương',
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

  Map<String, dynamic> toMap() => {
    'callPartnerAs': callPartnerAs,
    'selfCallAs': selfCallAs,
  };

  factory NicknameConfig.fromMap(Map<String, dynamic> map) => NicknameConfig(
    callPartnerAs: (map['callPartnerAs'] as String?)?.trim().isNotEmpty == true
        ? map['callPartnerAs'] as String
        : defaultNickname,
    selfCallAs: (map['selfCallAs'] as String?)?.trim().isNotEmpty == true
        ? map['selfCallAs'] as String
        : defaultNickname,
  );

  NicknameConfig copyWith({
    String? callPartnerAs,
    String? selfCallAs,
  }) {
    return NicknameConfig(
      callPartnerAs: callPartnerAs ?? this.callPartnerAs,
      selfCallAs: selfCallAs ?? this.selfCallAs,
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
