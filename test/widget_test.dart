// test/widget_test.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_test/flutter_test.dart';
import 'package:herflow/core/constants/cycle_phase.dart';
import 'package:herflow/core/constants/user_role.dart';
import 'package:herflow/features/auth/domain/models/user_model.dart';
import 'package:herflow/features/care_signals/domain/models/care_signal_model.dart';
import 'package:herflow/features/cycle/domain/entities/cycle_info.dart';
import 'package:herflow/features/cycle/domain/entities/period_record.dart';
import 'package:herflow/features/partner_sync/domain/models/partner_status_model.dart';
import 'package:herflow/features/settings/domain/models/nickname_config.dart';

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
}
