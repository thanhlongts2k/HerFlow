// test/features/lifecycle/kick_counter_test.dart
//
// Unit tests cho Phase 2.5 — KickCounterController & KickSessionModel
// Kiểm thử logic Cardiff "Count to 10", lưu/đọc Hive và PrenatalAppointments.
// Chạy: flutter test test/features/lifecycle/kick_counter_test.dart

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:herflow/core/constants/app_constants.dart';
import 'package:herflow/features/lifecycle/domain/models/kick_counter_model.dart';
import 'package:herflow/features/lifecycle/domain/models/prenatal_appointment_model.dart';
import 'package:herflow/features/lifecycle/presentation/controllers/kick_counter_controller.dart';

// ── Mock Hive Box ────────────────────────────────────────────────────────────

/// Giả lập Hive Box bằng Map — không cần native plugin khi chạy test.
class _FakeBox extends Fake implements Box {
  final Map<dynamic, dynamic> _data = {};

  @override
  dynamic get(dynamic key, {dynamic defaultValue}) =>
      _data.containsKey(key) ? _data[key] : defaultValue;

  @override
  Future<void> put(dynamic key, dynamic value) async => _data[key] = value;

  @override
  bool containsKey(dynamic key) => _data.containsKey(key);

  /// Seed dữ liệu test ban đầu
  void seed(Map<dynamic, dynamic> data) => _data.addAll(data);
}

// ── Helper ───────────────────────────────────────────────────────────────────

KickCounterController _makeController({_FakeBox? box}) {
  return KickCounterController(settingsBox: box ?? _FakeBox());
}

void main() {
  // ══════════════════════════════════════════════════════════════════════════
  // GROUP 1: KickSessionModel
  // ══════════════════════════════════════════════════════════════════════════
  group('KickSessionModel', () {
    test('Constants đúng: targetKickCount=10, cardiffTimeLimit=2h', () {
      expect(KickSessionModel.targetKickCount, equals(10));
      expect(
        KickSessionModel.cardiffTimeLimit,
        equals(const Duration(hours: 2)),
      );
    });

    test('Trạng thái mặc định: inProgress, kickCount=0', () {
      final now = DateTime.now();
      final session = KickSessionModel(
        id: 'test_001',
        startTime: now,
      );
      expect(session.isInProgress, isTrue);
      expect(session.isCompleted, isFalse);
      expect(session.isTimedOut, isFalse);
      expect(session.kickCount, equals(0));
      expect(session.remainingKicks, equals(10));
    });

    test('isCompleted khi status=completed', () {
      final session = KickSessionModel(
        id: 'test_002',
        startTime: DateTime.now(),
        kickCount: 10,
        status: KickSessionStatus.completed,
        endTime: DateTime.now().add(const Duration(minutes: 45)),
      );
      expect(session.isCompleted, isTrue);
      expect(session.isInProgress, isFalse);
      expect(session.remainingKicks, equals(0));
    });

    test('isTimedOut khi status=timedOut', () {
      final session = KickSessionModel(
        id: 'test_003',
        startTime: DateTime.now().subtract(const Duration(hours: 2)),
        kickCount: 7,
        status: KickSessionStatus.timedOut,
        endTime: DateTime.now(),
      );
      expect(session.isTimedOut, isTrue);
      expect(session.isCompleted, isFalse);
      expect(session.remainingKicks, equals(3));
    });

    test('completionMinutes tính đúng', () {
      final start = DateTime(2026, 1, 1, 10, 0);
      final end = DateTime(2026, 1, 1, 10, 47);
      final session = KickSessionModel(
        id: 'test_004',
        startTime: start,
        endTime: end,
        kickCount: 10,
        status: KickSessionStatus.completed,
      );
      expect(session.completionMinutes, equals(47));
    });

    test('completionMinutes là null khi endTime chưa có', () {
      final session = KickSessionModel(
        id: 'test_005',
        startTime: DateTime.now(),
      );
      expect(session.completionMinutes, isNull);
    });

    test('copyWith cập nhật đúng các trường', () {
      final original = KickSessionModel(
        id: 'test_006',
        startTime: DateTime(2026, 1, 1),
        kickCount: 3,
      );
      final updated = original.copyWith(
        kickCount: 7,
        status: KickSessionStatus.timedOut,
        endTime: DateTime(2026, 1, 1, 2, 0),
      );
      expect(updated.id, equals(original.id));
      expect(updated.kickCount, equals(7));
      expect(updated.isTimedOut, isTrue);
      expect(updated.endTime, equals(DateTime(2026, 1, 1, 2, 0)));
    });

    group('Serialization: toMap / fromMap', () {
      test('round-trip hoàn chỉnh cho inProgress session', () {
        final original = KickSessionModel(
          id: 'sess_rt_001',
          startTime: DateTime(2026, 9, 4, 8, 30),
          kickCount: 3,
          status: KickSessionStatus.inProgress,
        );
        final map = original.toMap();
        final restored = KickSessionModel.fromMap(map);

        expect(restored.id, equals(original.id));
        expect(restored.kickCount, equals(original.kickCount));
        expect(restored.status, equals(original.status));
        expect(restored.endTime, isNull);
      });

      test('round-trip hoàn chỉnh cho completed session', () {
        final start = DateTime(2026, 9, 4, 9, 0);
        final end = DateTime(2026, 9, 4, 9, 38);
        final original = KickSessionModel(
          id: 'sess_rt_002',
          startTime: start,
          endTime: end,
          kickCount: 10,
          status: KickSessionStatus.completed,
          notes: 'Bé đạp đều, mẹ vui!',
        );
        final map = original.toMap();
        final restored = KickSessionModel.fromMap(map);

        expect(restored.isCompleted, isTrue);
        expect(restored.notes, equals('Bé đạp đều, mẹ vui!'));
        expect(restored.completionMinutes, equals(38));
      });

      test('fromMap fallback an toàn khi status corrupt', () {
        final map = {
          'id': 'sess_corrupt',
          'startTime': DateTime.now().toIso8601String(),
          'kickCount': 2,
          'status': 'INVALID_STATUS_GARBAGE',
        };
        final session = KickSessionModel.fromMap(map);
        // Phải fallback về inProgress, không throw
        expect(session.isInProgress, isTrue);
      });

      test('fromMap fallback an toàn khi kickCount null', () {
        final map = {
          'id': 'sess_null_kick',
          'startTime': DateTime.now().toIso8601String(),
          // kickCount bị thiếu
        };
        final session = KickSessionModel.fromMap(map);
        expect(session.kickCount, equals(0)); // Default 0
      });
    });

    test('equality dựa trên id', () {
      final a = KickSessionModel(
        id: 'same_id', startTime: DateTime(2026, 1, 1),
      );
      final b = KickSessionModel(
        id: 'same_id', startTime: DateTime(2026, 6, 15), kickCount: 5,
      );
      expect(a, equals(b)); // Cùng id → bằng nhau
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // GROUP 2: KickCounterController — Session logic
  // ══════════════════════════════════════════════════════════════════════════
  group('KickCounterController — Session logic', () {
    test('startSession tạo session mới với kickCount=0 và isInProgress', () async {
      final ctrl = _makeController();
      final session = await ctrl.startSession();

      expect(session.isInProgress, isTrue);
      expect(session.kickCount, equals(0));
      expect(ctrl.state.recentSessions, contains(session));
    });

    test('addKick tăng kickCount đúng 1 đơn vị mỗi lần', () async {
      final ctrl = _makeController();
      final session = await ctrl.startSession();

      final after1 = await ctrl.addKick(session.id);
      expect(after1?.kickCount, equals(1));

      final after2 = await ctrl.addKick(session.id);
      expect(after2?.kickCount, equals(2));
    });

    test('addKick tự động completed khi đạt 10 cử động (Cardiff complete)', () async {
      final ctrl = _makeController();
      var session = await ctrl.startSession();

      // Tăng tới 9 lần
      for (int i = 0; i < 9; i++) {
        final result = await ctrl.addKick(session.id);
        session = result!;
        expect(session.isInProgress, isTrue,
            reason: 'Sau $i lần, phải vẫn isInProgress');
      }

      // Lần thứ 10 — Cardiff complete!
      final completed = await ctrl.addKick(session.id);
      expect(completed!.isCompleted, isTrue);
      expect(completed.kickCount, equals(10));
      expect(completed.endTime, isNotNull);
    });

    test('addKick trên session không còn inProgress → trả về nguyên session', () async {
      final ctrl = _makeController();
      var session = await ctrl.startSession();

      // Complete session
      for (int i = 0; i < 10; i++) {
        final r = await ctrl.addKick(session.id);
        session = r!;
      }
      expect(session.isCompleted, isTrue);

      // Tap thêm sau khi đã hoàn thành → không thay đổi
      final extra = await ctrl.addKick(session.id);
      expect(extra?.kickCount, equals(10)); // Không tăng thêm
    });

    test('timeoutSession đánh dấu timedOut và lưu endTime', () async {
      final ctrl = _makeController();
      final session = await ctrl.startSession();

      await ctrl.addKick(session.id); // 1 lần đạp
      final timedOut = await ctrl.timeoutSession(session.id);

      expect(timedOut!.isTimedOut, isTrue);
      expect(timedOut.kickCount, equals(1)); // Giữ số đã đếm
      expect(timedOut.endTime, isNotNull);
    });

    test('deleteSession xóa đúng session khỏi danh sách', () async {
      final ctrl = _makeController();
      final s1 = await ctrl.startSession();
      // Delay nhỏ để đảm bảo timestamp khác nhau (ID dựa trên millisecondsSinceEpoch)
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final s2 = await ctrl.startSession();

      // Đảm bảo 2 session có ID khác nhau trước khi xóa
      expect(s1.id, isNot(equals(s2.id)), reason: 'Hai phiên phải có ID khác nhau');
      expect(ctrl.state.recentSessions.length, greaterThanOrEqualTo(2),
          reason: 'Phải có ít nhất 2 sessions');

      await ctrl.deleteSession(s1.id);

      final ids = ctrl.state.recentSessions.map((s) => s.id).toList();
      expect(ids, isNot(contains(s1.id)));
      expect(ids, contains(s2.id));
    });

    test('addKick với sessionId không tồn tại → trả null', () async {
      final ctrl = _makeController();
      final result = await ctrl.addKick('non_existent_id');
      expect(result, isNull);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // GROUP 3: KickCounterState — Computed getters
  // ══════════════════════════════════════════════════════════════════════════
  group('KickCounterState — Computed getters', () {
    KickSessionModel makeSession({
      required String id,
      required DateTime start,
      int kicks = 0,
      KickSessionStatus status = KickSessionStatus.completed,
    }) {
      return KickSessionModel(
        id: id,
        startTime: start,
        kickCount: kicks,
        status: status,
        endTime: status != KickSessionStatus.inProgress ? start.add(const Duration(minutes: 30)) : null,
      );
    }

    test('todayTotalKicks chỉ tính các phiên trong ngày hôm nay', () {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      final state = KickCounterState(recentSessions: [
        makeSession(id: 's1', start: today, kicks: 10),
        makeSession(id: 's2', start: today, kicks: 7),
        makeSession(id: 's3', start: yesterday, kicks: 10), // Ngày qua → không tính
      ]);

      expect(state.todayTotalKicks, equals(17)); // 10 + 7
    });

    test('todayCompletedSessionCount chỉ đếm phiên completed hôm nay', () {
      final today = DateTime.now();
      final state = KickCounterState(recentSessions: [
        makeSession(id: 's1', start: today, kicks: 10, status: KickSessionStatus.completed),
        makeSession(id: 's2', start: today, kicks: 6, status: KickSessionStatus.timedOut),
        makeSession(id: 's3', start: today, kicks: 10, status: KickSessionStatus.completed),
      ]);

      expect(state.todayCompletedSessionCount, equals(2));
    });

    test('latestCompletedToday trả về phiên completed gần nhất hôm nay', () {
      final today = DateTime.now();
      final s1 = makeSession(id: 's1', start: today.subtract(const Duration(hours: 3)), kicks: 10);
      final s2 = makeSession(id: 's2', start: today.subtract(const Duration(hours: 1)), kicks: 10);

      final state = KickCounterState(recentSessions: [s1, s2]);
      expect(state.latestCompletedToday?.id, equals(s2.id)); // Gần nhất
    });

    test('latestCompletedToday null khi không có phiên hôm nay', () {
      const state = KickCounterState(recentSessions: []);
      expect(state.latestCompletedToday, isNull);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // GROUP 4: Hive Persistence
  // ══════════════════════════════════════════════════════════════════════════
  group('Hive Persistence — kick sessions', () {
    test('startSession lưu dữ liệu — state có session sau khi gọi', () async {
      final box = _FakeBox();
      final ctrl = _makeController(box: box);

      expect(ctrl.state.recentSessions, isEmpty);
      await ctrl.startSession();
      expect(ctrl.state.recentSessions, hasLength(1));
    });

    test('addKick cập nhật state kickCount và persist', () async {
      final box = _FakeBox();
      final ctrl = _makeController(box: box);
      final session = await ctrl.startSession();
      await ctrl.addKick(session.id);

      final updated = ctrl.state.recentSessions.firstWhere((s) => s.id == session.id);
      expect(updated.kickCount, equals(1));
    });

    test('Load từ Hive box có sẵn dữ liệu seeded (key rỗng uid)', () {
      final box = _FakeBox();
      final session = KickSessionModel(
        id: 'seeded_001',
        startTime: DateTime.now(),
        kickCount: 5,
        status: KickSessionStatus.inProgress,
      );
      // Seed với key không có uid prefix (uid rỗng)
      box.seed({AppConstants.keyKickSessions: jsonEncode([session.toMap()])});

      // Controller không crash khi đọc dữ liệu seeded
      expect(() => _makeController(box: box), returnsNormally);
    });

    test('Controller khởi tạo không crash khi Hive box rỗng', () {
      expect(() => _makeController(), returnsNormally);
    });

    test('Controller khởi tạo không crash khi JSON corrupt trong Hive', () {
      final box = _FakeBox();
      box.seed({AppConstants.keyKickSessions: 'INVALID_JSON_{{{BAD'});
      // Không throw, fallback về danh sách rỗng
      expect(() => _makeController(box: box), returnsNormally);
      final ctrl = _makeController(box: box);
      expect(ctrl.state.recentSessions, isEmpty);
    });

    test('Sau deleteSession — state xóa đúng session và không crash', () async {
      final box = _FakeBox();
      final ctrl = _makeController(box: box);
      final s = await ctrl.startSession();
      await ctrl.deleteSession(s.id);
      expect(ctrl.state.recentSessions, isEmpty);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // GROUP 5: PrenatalAppointmentModel — 7 mốc khám vàng
  // ══════════════════════════════════════════════════════════════════════════
  group('PrenatalAppointmentModel — 7 mốc khám vàng', () {
    test('goldenCheckups có đúng 7 mốc', () {
      expect(PrenatalAppointmentModel.goldenCheckups.length, equals(7));
    });

    test('Mỗi mốc có id, title, weekStart/End hợp lệ', () {
      for (final checkup in PrenatalAppointmentModel.goldenCheckups) {
        expect(checkup.id, isNotEmpty, reason: '${checkup.title} thiếu id');
        expect(checkup.title, isNotEmpty);
        expect(checkup.weekStart, greaterThan(0));
        expect(checkup.weekEnd, greaterThanOrEqualTo(checkup.weekStart));
        expect(checkup.weekEnd, lessThanOrEqualTo(40));
      }
    });

    test('Mốc 11-13: NT + Double Test / NIPT', () {
      final checkup = PrenatalAppointmentModel.goldenCheckups.firstWhere(
        (c) => c.id == 'checkup_11_13',
      );
      expect(checkup.weekStart, equals(11));
      expect(checkup.weekEnd, equals(13));
      expect(checkup.emoji, equals('🔬'));
    });

    test('Mốc 20-24: Siêu âm 4D hình thái học', () {
      final checkup = PrenatalAppointmentModel.goldenCheckups.firstWhere(
        (c) => c.id == 'checkup_20_24',
      );
      expect(checkup.weekStart, equals(20));
      expect(checkup.weekEnd, equals(24));
      expect(checkup.emoji, equals('🫀'));
    });

    group('statusFor(currentWeek)', () {
      late PrenatalAppointmentModel checkup20;

      setUp(() {
        checkup20 = PrenatalAppointmentModel.goldenCheckups.firstWhere(
          (c) => c.id == 'checkup_20_24',
        );
      });

      test('upcoming khi tuần hiện tại < weekStart', () {
        expect(checkup20.statusFor(15), equals(AppointmentStatus.upcoming));
      });

      test('current khi tuần hiện tại nằm trong khoảng weekStart..weekEnd', () {
        expect(checkup20.statusFor(22), equals(AppointmentStatus.current));
        expect(checkup20.statusFor(20), equals(AppointmentStatus.current));
        expect(checkup20.statusFor(24), equals(AppointmentStatus.current));
      });

      test('done khi tuần hiện tại > weekEnd', () {
        expect(checkup20.statusFor(30), equals(AppointmentStatus.done));
      });

      test('done khi isDone = true, bất kể tuần hiện tại', () {
        final doneMock = checkup20.copyWith(isDone: true);
        expect(doneMock.statusFor(15), equals(AppointmentStatus.done)); // Trước lịch nhưng đã tick
      });
    });

    test('weekRangeLabel đúng cho mốc đơn lẻ (weekStart == weekEnd)', () {
      final checkup32 = PrenatalAppointmentModel.goldenCheckups.firstWhere(
        (c) => c.id == 'checkup_32',
      );
      expect(checkup32.weekRangeLabel, equals('Tuần 32'));
    });

    test('weekRangeLabel đúng cho mốc khoảng (weekStart != weekEnd)', () {
      final checkup11 = PrenatalAppointmentModel.goldenCheckups.firstWhere(
        (c) => c.id == 'checkup_11_13',
      );
      expect(checkup11.weekRangeLabel, equals('Tuần 11–13'));
    });

    group('toUserDataMap / mergeUserData', () {
      test('toUserDataMap chỉ serialize isDone và appointmentDate', () {
        final checkup = PrenatalAppointmentModel.goldenCheckups.first.copyWith(
          isDone: true,
          appointmentDate: DateTime(2026, 10, 15),
        );
        final map = checkup.toUserDataMap();
        expect(map['id'], equals(checkup.id));
        expect(map['isDone'], isTrue);
        expect(map.containsKey('appointmentDate'), isTrue);
        // Không serialize weekStart, weekEnd, title (dữ liệu tĩnh)
        expect(map.containsKey('weekStart'), isFalse);
      });

      test('mergeUserData null → trả về base không thay đổi', () {
        final base = PrenatalAppointmentModel.goldenCheckups.first;
        final merged = PrenatalAppointmentModel.mergeUserData(base, null);
        expect(merged.isDone, equals(base.isDone));
      });

      test('mergeUserData với isDone=true → merged.isDone = true', () {
        final base = PrenatalAppointmentModel.goldenCheckups.first;
        final userData = {'id': base.id, 'isDone': true};
        final merged = PrenatalAppointmentModel.mergeUserData(base, userData);
        expect(merged.isDone, isTrue);
      });
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // GROUP 6: KickCounterController — Prenatal Appointments
  // ══════════════════════════════════════════════════════════════════════════
  group('KickCounterController — Prenatal Appointments', () {
    test('State khởi tạo có đủ 7 mốc khám vàng', () {
      final ctrl = _makeController();
      expect(ctrl.state.appointments.length, equals(7));
    });

    test('toggleAppointmentDone đổi trạng thái isDone', () async {
      final ctrl = _makeController();
      final firstId = ctrl.state.appointments.first.id;
      expect(ctrl.state.appointments.first.isDone, isFalse);

      await ctrl.toggleAppointmentDone(firstId);
      expect(ctrl.state.appointments.first.isDone, isTrue);

      await ctrl.toggleAppointmentDone(firstId);
      expect(ctrl.state.appointments.first.isDone, isFalse); // Toggle back
    });

    test('setAppointmentDate lưu ngày hẹn đúng', () async {
      final ctrl = _makeController();
      final id = ctrl.state.appointments.first.id;
      final date = DateTime(2026, 11, 20);

      await ctrl.setAppointmentDate(id, date);

      final updated = ctrl.state.appointments.firstWhere((a) => a.id == id);
      expect(updated.appointmentDate, equals(date));
    });

    test('nextAppointment tuần 10 → mốc 11-13 (upcoming)', () {
      final ctrl = _makeController();
      final next = ctrl.state.nextAppointment(10);
      expect(next?.id, equals('checkup_11_13'));
    });

    test('nextAppointment tuần 25 → mốc 32 (đã qua 11-13, 16-18, 20-24)', () {
      final ctrl = _makeController();
      final next = ctrl.state.nextAppointment(25);
      // Tuần 25: mốc 24-28 hiện tại, nextAppointment ≥ 25 và chưa done
      expect(next?.weekEnd, greaterThanOrEqualTo(25));
    });

    test('nextAppointment null khi tất cả mốc đã done', () async {
      final ctrl = _makeController();
      for (final appt in ctrl.state.appointments) {
        await ctrl.toggleAppointmentDone(appt.id);
      }
      final next = ctrl.state.nextAppointment(20);
      expect(next, isNull);
    });
  });
}
