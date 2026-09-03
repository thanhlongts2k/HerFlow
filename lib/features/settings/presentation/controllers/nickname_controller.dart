// lib/features/settings/presentation/controllers/nickname_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:herflow/core/constants/app_constants.dart';
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
    _loadFromBox();
  }

  void _loadFromBox() {
    final callPartner = _settingsBox.get(keyNicknameCallPartner) as String?;
    final selfCall = _settingsBox.get(keyNicknameSelfCall) as String?;

    state = NicknameConfig(
      callPartnerAs: (callPartner != null && callPartner.trim().isNotEmpty)
          ? callPartner
          : NicknameConfig.defaultNickname,
      selfCallAs: (selfCall != null && selfCall.trim().isNotEmpty)
          ? selfCall
          : NicknameConfig.defaultNickname,
    );
  }

  Future<void> setCallPartnerAs(String name) async {
    final trimmed = name.trim();
    final value = trimmed.isNotEmpty ? trimmed : NicknameConfig.defaultNickname;
    await _settingsBox.put(keyNicknameCallPartner, value);
    state = state.copyWith(callPartnerAs: value);
    await _syncToFirestoreIfPaired();
  }

  Future<void> setSelfCallAs(String name) async {
    final trimmed = name.trim();
    final value = trimmed.isNotEmpty ? trimmed : NicknameConfig.defaultNickname;
    await _settingsBox.put(keyNicknameSelfCall, value);
    state = state.copyWith(selfCallAs: value);
    await _syncToFirestoreIfPaired();
  }

  Future<void> resetToDefault() async {
    await _settingsBox.delete(keyNicknameCallPartner);
    await _settingsBox.delete(keyNicknameSelfCall);
    state = const NicknameConfig();
    await _syncToFirestoreIfPaired();
  }

  Future<void> _syncToFirestoreIfPaired() async {
    try {
      final coupleId = _settingsBox.get('couple_id') as String?;
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
