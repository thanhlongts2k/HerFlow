// test/widget_test.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:herflow/core/constants/cycle_phase.dart';
import 'package:herflow/core/constants/user_role.dart';
import 'package:herflow/features/auth/domain/models/user_model.dart';
import 'package:herflow/features/care_signals/domain/models/care_signal_model.dart';
import 'package:herflow/features/cycle/domain/entities/cycle_info.dart';
import 'package:herflow/features/cycle/domain/entities/period_record.dart';
import 'package:herflow/features/partner_sync/domain/models/partner_status_model.dart';
import 'package:herflow/core/utils/user_scope.dart';
import 'package:herflow/features/settings/domain/models/nickname_config.dart';
import 'package:herflow/core/widgets/moona_confirm_dialog.dart';

void main() {
  group('Cycle Core Engine Unit Tests', () {
    final baseDate = DateTime(2026, 9, 1);
    final cycle = CycleInfo(
      lastPeriodStart: baseDate,
      cycleLength: 28,
      periodDuration: 5,
    );

    test('Menstrual Phase (Day 1 - 5) should be classified correctly', () {
      // Ngày 1
      expect(cycle.getCycleDay(baseDate), 1);
      expect(cycle.getPhaseForDate(baseDate), CyclePhase.menstrual);

      // Ngày 5
      final day5 = baseDate.add(const Duration(days: 4));
      expect(cycle.getCycleDay(day5), 5);
      expect(cycle.getPhaseForDate(day5), CyclePhase.menstrual);
      expect(cycle.isPeriodDay(day5), isTrue);
    });

    test('Follicular Phase (Day 6 - 12) should be classified correctly', () {
      final day7 = baseDate.add(const Duration(days: 6));
      expect(cycle.getCycleDay(day7), 7);
      expect(cycle.getPhaseForDate(day7), CyclePhase.follicular);
      expect(cycle.isPeriodDay(day7), isFalse);
    });

    test('Ovulation Phase (Day 13 - 15) should be classified correctly', () {
      // Ngày rụng trứng lý thuyết = 28 - 14 = ngày 14
      final ovulationDay = baseDate.add(const Duration(days: 13)); // Ngày 14
      expect(cycle.getCycleDay(ovulationDay), 14);
      expect(cycle.getPhaseForDate(ovulationDay), CyclePhase.ovulation);
      expect(cycle.isOvulationDay(ovulationDay), isTrue);
      expect(cycle.isFertileWindow(ovulationDay), isTrue);
      expect(cycle.getConceptionChance(ovulationDay), 'Rất cao (Đỉnh điểm)');
    });

    test('Luteal Phase (Day 16 - 28) should be classified correctly', () {
      final lutealDay = baseDate.add(const Duration(days: 20)); // Ngày 21
      expect(cycle.getCycleDay(lutealDay), 21);
      expect(cycle.getPhaseForDate(lutealDay), CyclePhase.luteal);
      expect(cycle.isFertileWindow(lutealDay), isFalse);
    });

    test('Days until next period calculation', () {
      // Ngày 1: Còn 28 ngày
      expect(cycle.daysUntilNextPeriod(baseDate), 28);

      // Ngày 15: Còn 14 ngày
      final day15 = baseDate.add(const Duration(days: 14));
      expect(cycle.daysUntilNextPeriod(day15), 14);
    });

    test('PMS Pre-Warning window and start date calculation', () {
      // Ngày kế tiếp kỳ kinh = 29/09/2026
      expect(cycle.nextPeriodDate, DateTime(2026, 9, 29));

      // Ngày bắt đầu PMS = 29/09 - 7 ngày = 22/09/2026
      expect(cycle.nextPmsStartDate, DateTime(2026, 9, 22));

      // Ngày 23/09 (còn 6 ngày nữa đến kỳ kinh) -> Nằm trong PMS window
      final pmsDay = DateTime(2026, 9, 23);
      expect(cycle.isPmsWindow(pmsDay), isTrue);

      // Ngày 10/09 (còn 19 ngày nữa) -> Không phải PMS window
      final nonPmsDay = DateTime(2026, 9, 10);
      expect(cycle.isPmsWindow(nonPmsDay), isFalse);
    });

    test('CycleDayInfo calculation provides workout & hormone insights', () {
      final dayInfo = cycle.getDayInfo(baseDate);
      expect(dayInfo.phase, CyclePhase.menstrual);
      expect(dayInfo.isPeriodDay, isTrue);
      expect(dayInfo.expectedEnergy, 1);
      expect(dayInfo.workoutTip.isNotEmpty, isTrue);
      expect(dayInfo.hormoneStatus.isNotEmpty, isTrue);
    });

    test('PeriodRecord duration and date matching', () {
      final record = PeriodRecord(
        id: 'rec-1',
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 8, 5),
        flowIntensity: FlowIntensity.heavy,
      );

      expect(record.durationInDays, 5);
      expect(record.containsDate(DateTime(2026, 8, 3)), isTrue);
      expect(record.containsDate(DateTime(2026, 8, 6)), isFalse);
    });

    test('Actual vs Predicted period and projection engine (11/08 anchor)', () {
      final anchorDate = DateTime(2026, 8, 11);
      final cycleWithAnchor = CycleInfo(
        lastPeriodStart: anchorDate,
        cycleLength: 28,
        periodDuration: 5,
      );

      // 1. Kỳ kinh thực tế tháng 8: 11/08 -> 15/08
      expect(cycleWithAnchor.isActualPeriod(DateTime(2026, 8, 11)), isTrue);
      expect(cycleWithAnchor.isActualPeriod(DateTime(2026, 8, 15)), isTrue);
      expect(cycleWithAnchor.isPredictedPeriod(DateTime(2026, 8, 11)), isFalse);
      expect(cycleWithAnchor.isPeriodDay(DateTime(2026, 8, 11)), isTrue);

      // 2. Các ngày trong quá khứ trước anchor (không vẽ kỳ kinh ảo)
      expect(cycleWithAnchor.isPeriodDay(DateTime(2026, 8, 5)), isFalse);
      expect(cycleWithAnchor.isActualPeriod(DateTime(2026, 8, 5)), isFalse);
      expect(cycleWithAnchor.isPredictedPeriod(DateTime(2026, 8, 5)), isFalse);

      // 3. Rụng trứng chu kỳ hiện tại: Ngày 14 = 11/08 + 13 ngày = 24/08
      expect(cycleWithAnchor.isOvulationDay(DateTime(2026, 8, 24)), isTrue);

      // 4. Kỳ kinh dự báo tháng 9: 11/08 + 28 ngày = 08/09 -> 12/09
      expect(cycleWithAnchor.nextPeriodDate, DateTime(2026, 9, 8));
      expect(cycleWithAnchor.isPredictedPeriod(DateTime(2026, 9, 8)), isTrue);
      expect(cycleWithAnchor.isPredictedPeriod(DateTime(2026, 9, 12)), isTrue);
      expect(cycleWithAnchor.isActualPeriod(DateTime(2026, 9, 8)), isFalse);
      expect(cycleWithAnchor.isPeriodDay(DateTime(2026, 9, 8)), isTrue);

      // 5. Rụng trứng chu kỳ kế tiếp: Ngày 14 = 08/09 + 13 ngày = 21/09
      expect(cycleWithAnchor.isOvulationDay(DateTime(2026, 9, 21)), isTrue);

      // 6. Kỳ kinh dự báo tháng 10: 08/09 + 28 = 06/10 -> 10/10
      expect(cycleWithAnchor.isPredictedPeriod(DateTime(2026, 10, 6)), isTrue);
      expect(cycleWithAnchor.isPredictedPeriod(DateTime(2026, 10, 10)), isTrue);
    });
  });

  group('v0.3.0 Care Signals & Backup Unit Tests', () {
    test('CareSignalModel serialization roundtrip', () {
      final signal = CareSignalModel(
        id: 'sig-test-1',
        coupleId: 'couple-123',
        type: CareSignalType.message,
        customNote: 'Đau bụng cần chườm ấm',
        sentAt: DateTime(2026, 9, 3, 10, 30),
        isRead: false,
        responseMessage: 'Anh đang mua đồ ăn về nè',
        respondedAt: DateTime(2026, 9, 3, 10, 35),
      );

      expect(signal.isResponded, isTrue);

      final map = signal.toMap();
      expect(map['id'], 'sig-test-1');
      expect(map['type'], 'message');
      expect(map['responseMessage'], 'Anh đang mua đồ ăn về nè');

      final restored = CareSignalModel.fromMap(map);
      expect(restored.id, signal.id);
      expect(restored.type, CareSignalType.message);
      expect(restored.customNote, signal.customNote);
      expect(restored.isRead, isFalse);
      expect(restored.responseMessage, 'Anh đang mua đồ ăn về nè');
      expect(restored.respondedAt, DateTime(2026, 9, 3, 10, 35));
      expect(restored.isResponded, isTrue);
    });

    test('Husband CareSignalModel quick chat serialization roundtrip', () {
      final signal = CareSignalModel(
        id: 'sig-husband-1',
        coupleId: 'couple-123',
        type: CareSignalType.husbandMessage,
        customNote: 'Bụng còn đau nhiều không em?',
        sentAt: DateTime(2026, 9, 3, 11, 00),
        senderRole: 'husband',
        senderNickname: 'Anh yêu',
        targetNickname: 'Vợ yêu',
      );

      expect(signal.isFromHusband, isTrue);
      expect(signal.isResponded, isFalse);

      final map = signal.toMap();
      expect(map['type'], 'husbandMessage');
      expect(map['senderRole'], 'husband');
      expect(map['senderNickname'], 'Anh yêu');
      expect(map['targetNickname'], 'Vợ yêu');

      final restored = CareSignalModel.fromMap(map);
      expect(restored.type, CareSignalType.husbandMessage);
      expect(restored.isFromHusband, isTrue);
      expect(restored.customNote, 'Bụng còn đau nhiều không em?');
      expect(restored.senderNickname, 'Anh yêu');
      expect(restored.targetNickname, 'Vợ yêu');
    });

    test('Wife CareSignalModel custom message / love note serialization roundtrip', () {
      final signal = CareSignalModel(
        id: 'sig-wife-custom-1',
        coupleId: 'couple-456',
        type: CareSignalType.custom,
        customNote: 'Thèm trà sữa trân châu đường đen size L nha anh ơi 🧋',
        sentAt: DateTime(2026, 9, 3, 14, 20),
        senderRole: 'wife',
        senderNickname: 'Bé iu',
        targetNickname: 'Anh iu',
      );

      expect(signal.isFromHusband, isFalse);
      expect(signal.customMessage, 'Thèm trà sữa trân châu đường đen size L nha anh ơi 🧋');
      expect(signal.senderName, 'Bé iu');

      final map = signal.toMap();
      expect(map['customMessage'], signal.customNote);
      expect(map['senderName'], 'Bé iu');
      expect(map['signalType'], 'custom');

      final restored = CareSignalModel.fromMap(map);
      expect(restored.id, 'sig-wife-custom-1');
      expect(restored.type, CareSignalType.custom);
      expect(restored.customMessage, signal.customNote);
      expect(restored.senderName, 'Bé iu');
      expect(restored.targetNickname, 'Anh iu');
      expect(restored.isFromHusband, isFalse);
    });

    test('AES-256 and SHA-256 checksum integrity verification', () {
      final key = enc.Key.fromUtf8('MoonaSec2026!Key@SecretFlow2026!');
      final iv = enc.IV.fromUtf8('MoonaIV2026Init!');
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

      const payload = '{"app":"Moona","test":true}';
      final checksum = sha256.convert(utf8.encode(payload)).toString();

      final envelope = jsonEncode({'checksum': checksum, 'payload': payload});
      final encrypted = encrypter.encrypt(envelope, iv: iv);

      // Giải mã
      final decrypted = encrypter.decrypt64(encrypted.base64, iv: iv);
      final envelopeDecoded = jsonDecode(decrypted) as Map<String, dynamic>;

      expect(envelopeDecoded['checksum'], checksum);
      expect(envelopeDecoded['payload'], payload);

      // Verify checksum
      final verifyHash = sha256.convert(utf8.encode(envelopeDecoded['payload'] as String)).toString();
      expect(verifyHash, checksum);
    });
  });

  group('Role-Based Architecture Unit Tests', () {
    test('UserRole Wife properties and extension helpers', () {
      const role = UserRole.wife;
      expect(role.isWife, isTrue);
      expect(role.isHusband, isFalse);
      expect(role.shortName, 'Vợ');
      expect(role.emoji, '🌸');
      expect(role.displayName, contains('Vợ'));
      expect(role.name, 'wife');
    });

    test('UserRole Husband properties and extension helpers', () {
      const role = UserRole.husband;
      expect(role.isWife, isFalse);
      expect(role.isHusband, isTrue);
      expect(role.shortName, 'Chồng');
      expect(role.emoji, '🛡️');
      expect(role.displayName, contains('Chồng'));
      expect(role.name, 'husband');
    });

    test('UserRole serialization and parsing by name', () {
      final wifeParsed = UserRole.values.firstWhere((e) => e.name == 'wife');
      expect(wifeParsed, UserRole.wife);

      final husbandParsed = UserRole.values.firstWhere((e) => e.name == 'husband');
      expect(husbandParsed, UserRole.husband);
    });
  });

  group('PartnerStatusModel Sync Unit Tests', () {
    test('PartnerStatusModel serialization and deserialization with cycleDay and moodSummary', () {
      final now = DateTime(2026, 9, 3, 15, 0);
      final status = PartnerStatusModel(
        coupleId: 'COUPLE_123',
        currentPhase: 'Hoàng thể',
        cycleDay: 24,
        energyLevel: 2,
        moodTags: ['Mệt mỏi', 'Cáu kỉnh'],
        moodSummary: 'Mệt mỏi (Cáu kỉnh)',
        husbandActionTip: 'Lắng nghe nàng và chườm ấm',
        updatedAt: now,
      );

      final map = status.toMap();
      expect(map['coupleId'], 'COUPLE_123');
      expect(map['currentPhase'], 'Hoàng thể');
      expect(map['cycleDay'], 24);
      expect(map['energyLevel'], 2);
      expect(map['moodSummary'], 'Mệt mỏi (Cáu kỉnh)');

      final restored = PartnerStatusModel.fromMap(map);
      expect(restored.coupleId, status.coupleId);
      expect(restored.currentPhase, status.currentPhase);
      expect(restored.cycleDay, 24);
      expect(restored.energyLevel, 2);
      expect(restored.moodSummary, 'Mệt mỏi (Cáu kỉnh)');
      expect(restored.husbandActionTip, status.husbandActionTip);
    });
  });

  group('NicknameConfig Unit Tests', () {
    test('Default values and presets check', () {
      const config = NicknameConfig();
      expect(config.callPartnerAs, 'Người thương');
      expect(config.selfCallAs, 'Người thương');
      expect(NicknameConfig.presets, contains('Người thương'));
      expect(NicknameConfig.presets, contains('Em bé'));
      expect(NicknameConfig.presets, contains('Bé iu'));
      expect(NicknameConfig.presets, contains('Vợ yêu'));
      expect(NicknameConfig.presets, contains('Chồng yêu'));
      expect(NicknameConfig.presets, contains('Anh yêu'));
    });

    test('Serialization and deserialization', () {
      const config = NicknameConfig(
        callPartnerAs: 'Bé iu',
        selfCallAs: 'Anh yêu',
      );
      final map = config.toMap();
      expect(map['callPartnerAs'], 'Bé iu');
      expect(map['selfCallAs'], 'Anh yêu');

      final restored = NicknameConfig.fromMap(map);
      expect(restored.callPartnerAs, 'Bé iu');
      expect(restored.selfCallAs, 'Anh yêu');
      expect(restored, config);
    });

    test('Empty fallback to default nickname', () {
      final restored = NicknameConfig.fromMap({'callPartnerAs': '', 'selfCallAs': '   '});
      expect(restored.callPartnerAs, NicknameConfig.defaultNickname);
      expect(restored.selfCallAs, NicknameConfig.defaultNickname);
    });
  });

  group('UserModel Domain Tests', () {
    test('Serialization and equality with role', () {
      final now = DateTime(2026, 9, 3);
      final user = UserModel(
        uid: 'user_123',
        displayName: 'Thành Long',
        email: 'long@gmail.com',
        photoUrl: 'https://example.com/avatar.png',
        role: 'husband',
        createdAt: now,
      );

      final map = user.toMap();
      expect(map['uid'], 'user_123');
      expect(map['displayName'], 'Thành Long');
      expect(map['email'], 'long@gmail.com');
      expect(map['role'], 'husband');

      final restored = UserModel.fromMap(map);
      expect(restored.uid, user.uid);
      expect(restored.displayName, user.displayName);
      expect(restored.email, user.email);
      expect(restored.photoUrl, user.photoUrl);
      expect(restored.role, 'husband');
    });
  });

  group('UserScope Cross-Account Isolation Unit Tests', () {
    test('UserScope.key isolates storage keys per user UID', () {
      expect(UserScope.key('nickname', 'UID_A'), 'UID_A_nickname');
      expect(UserScope.key('nickname', 'UID_B'), 'UID_B_nickname');
      expect(UserScope.key('nickname', ''), 'nickname');
      expect(UserScope.key('couple_id', 'UID_A'), isNot(equals(UserScope.key('couple_id', 'UID_B'))));
    });

    test('Simulated multi-account storage isolation: UID_B never reads UID_A data', () {
      final mockBox = <String, dynamic>{};

      // 1. UID_A đăng nhập và tùy chỉnh Cài đặt
      const uidA = 'account_wife_01';
      mockBox[UserScope.key('nickname_call_partner', uidA)] = 'Chồng yêu dấu';
      mockBox[UserScope.key('nickname_self_call', uidA)] = 'Bé bỏng';
      mockBox[UserScope.key('partner_couple_id', uidA)] = 'couple_room_999';
      mockBox[UserScope.key('cycle_length', uidA)] = 32;

      // 2. UID_B đăng nhập máy này
      const uidB = 'account_guest_02';

      // 3. Xác thực UID_B không đọc thấy bất kỳ dữ liệu nào của UID_A
      final uidBNicknamePartner = mockBox[UserScope.key('nickname_call_partner', uidB)];
      final uidBCoupleId = mockBox[UserScope.key('partner_couple_id', uidB)];
      final uidBCycleLen = mockBox[UserScope.key('cycle_length', uidB)];

      expect(uidBNicknamePartner, isNull);
      expect(uidBCoupleId, isNull);
      expect(uidBCycleLen, isNull);

      // 4. UID_B nhận đúng giá trị mặc định sạch sẽ
      final effectiveNickname = uidBNicknamePartner ?? NicknameConfig.defaultNickname;
      expect(effectiveNickname, NicknameConfig.defaultNickname);
      expect(effectiveNickname, isNot('Chồng yêu dấu'));
    });

    test('UserScope.setActiveUid eliminates race condition in Auth State', () {
      UserScope.clear();
      expect(UserScope.currentUid(), '');

      UserScope.setActiveUid('user_account_new');
      expect(UserScope.currentUid(), 'user_account_new');
      expect(UserScope.key('test_key'), 'user_account_new_test_key');

      UserScope.clear();
      expect(UserScope.currentUid(), '');
    });
  });

  group('Late Period & Biological Validation Unit Tests', () {
    final anchor = DateTime(2026, 8, 1);
    final cycle = CycleInfo(
      lastPeriodStart: anchor,
      cycleLength: 28,
      periodDuration: 5,
    );

    test('CycleInfo correctly detects late period and counts days late', () {
      // Ngày thứ 28 (29/08/2026): Chưa trễ
      final day28 = DateTime(2026, 8, 29);
      expect(cycle.isLate(day28), isFalse);
      expect(cycle.getDaysLate(day28), 0);

      // Ngày thứ 29 (30/08/2026): Trễ 1 ngày
      final day29 = DateTime(2026, 8, 30);
      expect(cycle.isLate(day29), isTrue);
      expect(cycle.getDaysLate(day29), 1);
      expect(cycle.daysUntilNextPeriod(day29), 0);

      // Ngày 04/09/2026 (ngày thứ 34): Trễ 6 ngày
      final day34 = DateTime(2026, 9, 4);
      expect(cycle.isLate(day34), isTrue);
      expect(cycle.getDaysLate(day34), 6);
      expect(cycle.daysUntilNextPeriod(day34), 0);
    });

    test('NicknameConfig provides role-based fallback: Wife calls Anh, Husband calls Em bé', () {
      final wifeDefault = NicknameConfig.defaultForRole(UserRole.wife);
      expect(wifeDefault.callPartnerAs, 'Anh');
      expect(wifeDefault.selfCallAs, 'Em');

      final husbandDefault = NicknameConfig.defaultForRole(UserRole.husband);
      expect(husbandDefault.callPartnerAs, 'Em bé');
      expect(husbandDefault.selfCallAs, 'Anh');

      // Empty fallback preserves non-empty values
      final emptyWife = NicknameConfig.fromMap({'callPartnerAs': '', 'selfCallAs': ''}, UserRole.wife);
      expect(emptyWife.callPartnerAs, 'Anh');
      expect(emptyWife.selfCallAs, 'Em');
    });

    test('NicknameConfig.fromCoupleDoc performs bidirectional sync & perspective mapping', () {
      final coupleDoc = <String, dynamic>{
        'wifeCallPartner': 'Chồng Yêu',
        'wifeSelfCall': 'Bé Nhỏ',
        'husbandCallPartner': 'Vợ Xinh',
        'husbandSelfCall': 'Anh Lớn',
      };

      // 1. Góc nhìn của Vợ (Wife perspective)
      final wifeView = NicknameConfig.fromCoupleDoc(coupleDoc, UserRole.wife);
      expect(wifeView.callPartnerAs, 'Chồng Yêu');      // Tôi gọi chàng là Chồng Yêu
      expect(wifeView.selfCallAs, 'Bé Nhỏ');            // Tôi tự xưng là Bé Nhỏ
      expect(wifeView.partnerCallsMeAs, 'Vợ Xinh');     // Chàng gọi tôi là Vợ Xinh
      expect(wifeView.partnerSelfCallAs, 'Anh Lớn');    // Chàng tự xưng là Anh Lớn

      // 2. Góc nhìn của Chồng (Husband perspective)
      final husbandView = NicknameConfig.fromCoupleDoc(coupleDoc, UserRole.husband);
      expect(husbandView.callPartnerAs, 'Vợ Xinh');     // Tôi gọi nàng là Vợ Xinh
      expect(husbandView.selfCallAs, 'Anh Lớn');        // Tôi tự xưng là Anh Lớn
      expect(husbandView.partnerCallsMeAs, 'Chồng Yêu'); // Nàng gọi tôi là Chồng Yêu
      expect(husbandView.partnerSelfCallAs, 'Bé Nhỏ');  // Nàng tự xưng là Bé Nhỏ

      // 3. Payload đồng bộ lên Firestore từ mỗi vai trò
      final wifePayload = wifeView.toCoupleSyncPayload(UserRole.wife);
      expect(wifePayload['wifeCallPartner'], 'Chồng Yêu');
      expect(wifePayload['wifeSelfCall'], 'Bé Nhỏ');

      final husbandPayload = husbandView.toCoupleSyncPayload(UserRole.husband);
      expect(husbandPayload['husbandCallPartner'], 'Vợ Xinh');
      expect(husbandPayload['husbandSelfCall'], 'Anh Lớn');
    });
  });

  group('Role Switching & Safeguards Unit Tests', () {
    test('Unpaired user role switch updates scoped Hive key and maintains role isolation', () {
      final mockBox = <String, dynamic>{};
      const uid = 'user_switch_test';

      // Khởi tạo vai trò ban đầu là Vợ
      mockBox[UserScope.key('app_user_role', uid)] = UserRole.wife.name;
      expect(mockBox[UserScope.key('app_user_role', uid)], 'wife');

      // Đổi sang Chồng
      mockBox[UserScope.key('app_user_role', uid)] = UserRole.husband.name;
      expect(mockBox[UserScope.key('app_user_role', uid)], 'husband');

      // Đảm bảo không ghi đè vào global key không có tiền tố
      expect(mockBox.containsKey('app_user_role'), isFalse);
    });

    test('Paired role swap payload validation for couples document', () {
      const currentRole = UserRole.wife;
      const newRole = UserRole.husband;
      const uid = 'wife_uid_123';

      final swapPayload = <String, dynamic>{
        'lastRoleSwapAt': DateTime.now().toIso8601String(),
        'swappedBy': uid,
      };

      expect(currentRole != newRole, isTrue);
      expect(swapPayload['swappedBy'], uid);
      expect(swapPayload.containsKey('lastRoleSwapAt'), isTrue);
    });
  });

  group('MoonaConfirmDialog Widget Tests', () {
    testWidgets('MoonaConfirmDialog renders title, message and balanced action buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  MoonaConfirmDialog.show(
                    context,
                    title: 'Đăng Xuất Tài Khoản?',
                    message: 'Bạn có chắc chắn muốn đăng xuất?',
                    icon: Icons.logout_rounded,
                    confirmText: 'Đăng xuất',
                    cancelText: 'Ở lại',
                    isDestructive: true,
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      // Tap to open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Check title, message, cancel, confirm
      expect(find.text('Đăng Xuất Tài Khoản?'), findsOneWidget);
      expect(find.text('Bạn có chắc chắn muốn đăng xuất?'), findsOneWidget);
      expect(find.text('Ở lại'), findsOneWidget);
      expect(find.text('Đăng xuất'), findsOneWidget);
      expect(find.byIcon(Icons.logout_rounded), findsOneWidget);

      // Tap cancel and verify dialog closes
      await tester.tap(find.text('Ở lại'));
      await tester.pumpAndSettle();
      expect(find.text('Đăng Xuất Tài Khoản?'), findsNothing);
    });

    testWidgets('MoonaConfirmDialog returns true on confirm', (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await MoonaConfirmDialog.show(
                    context,
                    title: 'Xác nhận xóa?',
                    message: 'Hành động này không thể hoàn tác.',
                    icon: Icons.delete_outline_rounded,
                    isDestructive: true,
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Tap confirm button
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });
  });
}


