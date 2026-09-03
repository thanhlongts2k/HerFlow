// lib/features/auth/domain/models/user_model.dart

/// Model đại diện cho người dùng đăng nhập bằng Google hoặc định danh Moona
class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  const UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.createdAt,
    this.lastLoginAt,
  });

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'displayName': displayName,
    'email': email,
    'photoUrl': photoUrl,
    'createdAt': createdAt?.toIso8601String(),
    'lastLoginAt': lastLoginAt?.toIso8601String(),
  };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
    uid: map['uid'] as String? ?? '',
    displayName: map['displayName'] as String? ?? 'Người dùng Moona',
    email: map['email'] as String? ?? '',
    photoUrl: map['photoUrl'] as String?,
    createdAt: map['createdAt'] != null
        ? DateTime.tryParse(map['createdAt'] as String)
        : null,
    lastLoginAt: map['lastLoginAt'] != null
        ? DateTime.tryParse(map['lastLoginAt'] as String)
        : null,
  );

  UserModel copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          email == other.email;

  @override
  int get hashCode => uid.hashCode ^ email.hashCode;
}
