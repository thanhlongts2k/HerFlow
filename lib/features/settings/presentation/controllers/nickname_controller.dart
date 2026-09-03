// lib/features/settings/presentation/controllers/nickname_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:herflow/core/constants/app_constants.dart';
import 'package:herflow/core/constants/user_role.dart';
import 'package:herflow/core/utils/user_scope.dart';
import 'package:herflow/features/settings/domain/models/nickname_config.dart';

const String keyNicknameCallPartner = 'nickname_call_partner';
const String keyNicknameSelfCall = 'nickname_self_call';

class NicknameController extends StateNotifier<NicknameConfig> {
  final Box _settingsBox;
  final FirebaseFirestore _firestore;

  NicknameController({Box? settingsBox, FirebaseFirestore? firestore})
      : _settingsBox = settingsBox ?? Hive.box(AppConstants.settingsBoxName),
        _firestore = firestore ?? FirebaseFirestore.instance,
        super(const NicknameConfig()) {
    loadForUser();
  }

  UserRole _resolveRole([String? explicitUid]) {
    final uid = explicitUid ?? UserScope.currentUid();
    final roleName = _settingsBox.get(UserScope.key('app_user_role', uid)) as String?;
    if (roleName == 'husband') return UserRole.husband;
    return UserRole.wife;
  }

  /// Nạp cấu hình danh xưng cho người dùng (ưu tiên local scoped -> Firestore -> Mặc định tinh tế theo vai trò)
  Future<void> loadForUser([String? explicitUid]) async {
    final uid = explicitUid ?? UserScope.currentUid();
    final role = _resolveRole(uid);
    final defaultCfg = NicknameConfig.defaultForRole(role);

    final callPartner = _settingsBox.get(UserScope.key(keyNicknameCallPartner, uid)) as String?;
    final selfCall = _settingsBox.get(UserScope.key(keyNicknameSelfCall, uid)) as String?;

    if (callPartner != null || selfCall != null) {
      state = NicknameConfig(
        callPartnerAs: (callPartner != null && callPartner.trim().isNotEmpty)
            ? callPartner.trim()
            : defaultCfg.callPartnerAs,
        selfCallAs: (selfCall != null && selfCall.trim().isNotEmpty)
            ? selfCall.trim()
            : defaultCfg.selfCallAs,
      );
      return;
    }

    // Nếu local chưa có cấu hình cho UID này, thử tải từ Firestore users/{uid}
    if (uid.isNotEmpty) {
      try {
        final doc = await _firestore.collection('users').doc(uid).get().timeout(const Duration(seconds: 4));
        if (doc.exists) {
          final data = doc.data();
          if (data != null && data['nicknames'] != null) {
            final map = Map<String, dynamic>.from(data['nicknames'] as Map);
            final config = NicknameConfig.fromMap(map, role);
            await _settingsBox.put(UserScope.key(keyNicknameCallPartner, uid), config.callPartnerAs);
            await _settingsBox.put(UserScope.key(keyNicknameSelfCall, uid), config.selfCallAs);
            state = config;
            return;
          }
        }
      } catch (e) {
        debugPrint('Load nicknames from Firestore notice: $e');
      }
    }

    // Mặc định tinh tế theo vai trò (Nàng gọi "Anh", Chàng gọi "Em bé")
    state = defaultCfg;
  }

  Future<void> setCallPartnerAs(String name) async {
    final uid = UserScope.currentUid();
    final role = _resolveRole(uid);
    final defaultName = role == UserRole.husband
        ? NicknameConfig.defaultForHusbandCallingWife
        : NicknameConfig.defaultForWifeCallingHusband;

    final trimmed = name.trim();
    final value = trimmed.isNotEmpty ? trimmed : defaultName;

    await _settingsBox.put(UserScope.key(keyNicknameCallPartner, uid), value);
    state = state.copyWith(callPartnerAs: value);
    await _syncToCloud();
  }

  Future<void> setSelfCallAs(String name) async {
    final uid = UserScope.currentUid();
    final role = _resolveRole(uid);
    final defaultName = role == UserRole.husband
        ? NicknameConfig.defaultForHusbandCallingSelf
        : NicknameConfig.defaultForWifeCallingSelf;

    final trimmed = name.trim();
    final value = trimmed.isNotEmpty ? trimmed : defaultName;

    await _settingsBox.put(UserScope.key(keyNicknameSelfCall, uid), value);
    state = state.copyWith(selfCallAs: value);
    await _syncToCloud();
  }

  Future<void> applyConfig(NicknameConfig config, [String? explicitUid]) async {
    final uid = explicitUid ?? UserScope.currentUid();
    final role = _resolveRole(uid);
    final defaultCfg = NicknameConfig.defaultForRole(role);

    final safePartner = config.callPartnerAs.trim().isNotEmpty
        ? config.callPartnerAs.trim()
        : defaultCfg.callPartnerAs;
    final safeSelf = config.selfCallAs.trim().isNotEmpty
        ? config.selfCallAs.trim()
        : defaultCfg.selfCallAs;

    final safeConfig = NicknameConfig(
      callPartnerAs: safePartner,
      selfCallAs: safeSelf,
    );

    await _settingsBox.put(UserScope.key(keyNicknameCallPartner, uid), safeConfig.callPartnerAs);
    await _settingsBox.put(UserScope.key(keyNicknameSelfCall, uid), safeConfig.selfCallAs);
    state = safeConfig;
  }

  Future<void> resetToDefault() async {
    final uid = UserScope.currentUid();
    final role = _resolveRole(uid);
    await _settingsBox.delete(UserScope.key(keyNicknameCallPartner, uid));
    await _settingsBox.delete(UserScope.key(keyNicknameSelfCall, uid));
    state = NicknameConfig.defaultForRole(role);
    await _syncToCloud();
  }

  /// Đặt lại state trong RAM khi Đăng xuất (Purge RAM state)
  void resetState() {
    state = const NicknameConfig();
  }

  Future<void> _syncToCloud() async {
    final uid = UserScope.currentUid();
    if (uid.isEmpty) return;

    try {
      // 1. Lưu vào hồ sơ người dùng users/{uid}
      await _firestore.collection('users').doc(uid).set({
        'nicknames': state.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2. Nếu đã ghép đôi, đồng bộ vào couples/{coupleId}
      final coupleId = _settingsBox.get(UserScope.key('partner_couple_id', uid)) as String?;
      if (coupleId != null && coupleId.isNotEmpty) {
        await _firestore.collection('couples').doc(coupleId).set({
          'nicknames': state.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Sync nicknames to Firestore notice: $e');
    }
  }
}

final nicknameConfigProvider =
    StateNotifierProvider<NicknameController, NicknameConfig>((ref) {
  return NicknameController();
});
