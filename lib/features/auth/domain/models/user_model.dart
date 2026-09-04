// lib/features/auth/domain/models/user_model.dart
import 'package:herflow/features/lifecycle/domain/models/life_stage.dart';

/// Model đại diện cho người dùng đăng nhập bằng Google hoặc định danh Moona.
///
/// BACKWARD COMPAT: Mọi field mới đều là nullable/có default — không bao giờ
/// gây crash với dữ liệu Hive/Firestore của bản v0.6.6/v0.6.7 cũ.
class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final String? role;           // 'wife' | 'husband' — giữ nguyên backward compat
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  // ─── Phase 1: LifeStage fields (tất cả optional, default an toàn) ────────
  /// Tên enum LifeStage dạng string để lưu Hive/Firestore.
  /// Null ở user v0.6.6/v0.6.7 — được xử lý bởi [currentLifeStage] getter.
  final String? lifeStage;

  /// Cờ tạm dừng — kích hoạt khi có biến cố thai kỳ (thai lưu, sẩy thai...).
  /// Mặc định false; không bao giờ null để tránh NPE.
  final bool isPaused;

  /// Lý do tạm dừng: 'loss' | 'medical' | 'personal'. Null khi isPaused = false.
  final String? pauseReason;
  // ─────────────────────────────────────────────────────────────────────────

  const UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.role,
    this.createdAt,
    this.lastLoginAt,
    // Phase 1 fields
    this.lifeStage,
    this.isPaused = false,
    this.pauseReason,
  });

  // ── Computed getters ──────────────────────────────────────────────────────

  /// Trả về LifeStage hiện tại của người dùng.
  ///
  /// BACKWARD COMPAT LOGIC (DP-01):
  ///   - User mới (có lifeStage): parse từ string.
  ///   - User v0.6.6/v0.6.7 (lifeStage == null):
  ///       * Có role == 'husband' → couple (chồng trong cặp đôi)
  ///       * Sẽ được auto-migrate bởi HiveMigrationValidator khi app khởi động
  ///   - Fallback cuối cùng: solo (an toàn nhất)
  LifeStage get currentLifeStage {
    // 1. Nếu đã có lifeStage được lưu — parse trực tiếp
    if (lifeStage != null && lifeStage!.isNotEmpty) {
      return LifeStageExt.fromString(lifeStage);
    }
    // 2. Backward compat: Husband role → couple mode
    if (role == 'husband') return LifeStage.couple;
    // 3. Default an toàn cho mọi trường hợp còn lại
    return LifeStage.solo;
  }

  /// Tiện ích kiểm tra có đang ở chế độ cặp đôi không.
  bool get isCoupleMode => currentLifeStage == LifeStage.couple;

  /// Tiện ích kiểm tra có đang trong giai đoạn thai kỳ/nuôi con không.
  bool get isBabyPhase =>
      currentLifeStage == LifeStage.pregnancy ||
      currentLifeStage == LifeStage.motherhood;

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'displayName': displayName,
    'email': email,
    'photoUrl': photoUrl,
    'role': role,
    'createdAt': createdAt?.toIso8601String(),
    'lastLoginAt': lastLoginAt?.toIso8601String(),
    // Phase 1 fields
    'lifeStage': lifeStage,
    'isPaused': isPaused,
    'pauseReason': pauseReason,
  };

  /// Deserialize từ Map (Firestore hoặc Hive).
  ///
  /// BACKWARD COMPAT (DP-01): Mọi field đều có null-safe fallback.
  /// Không bao giờ throw exception với dữ liệu thiếu field của bản cũ.
  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
    uid: map['uid'] as String? ?? '',
    displayName: map['displayName'] as String? ?? 'Người dùng Moona',
    email: map['email'] as String? ?? '',
    photoUrl: map['photoUrl'] as String?,
    role: map['role'] as String?,
    createdAt: map['createdAt'] != null
        ? DateTime.tryParse(map['createdAt'] as String)
        : null,
    lastLoginAt: map['lastLoginAt'] != null
        ? DateTime.tryParse(map['lastLoginAt'] as String)
        : null,
    // Phase 1 fields — tất cả an toàn với dữ liệu cũ không có key này
    lifeStage:   map['lifeStage'] as String?,          // null OK → solo (qua getter)
    isPaused:    map['isPaused'] as bool? ?? false,    // null → false, không crash
    pauseReason: map['pauseReason'] as String?,        // null OK
  );

  UserModel copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? photoUrl,
    String? role,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    // Phase 1 fields
    String? lifeStage,
    bool? isPaused,
    String? pauseReason,
    bool clearPauseReason = false, // Dùng để xóa pauseReason về null
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      // Phase 1 fields
      lifeStage:   lifeStage ?? this.lifeStage,
      isPaused:    isPaused ?? this.isPaused,
      pauseReason: clearPauseReason ? null : (pauseReason ?? this.pauseReason),
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
