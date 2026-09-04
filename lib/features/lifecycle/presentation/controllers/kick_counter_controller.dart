// lib/features/lifecycle/presentation/controllers/kick_counter_controller.dart
//
// State management cho Bộ Đếm Cử Động Thai (Kick Counter).
// Lưu trữ Hive user-scoped, hỗ trợ Cardiff "Count to 10" và Prenatal Appointments.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:herflow/core/constants/app_constants.dart';
import 'package:herflow/core/utils/user_scope.dart';
import 'package:herflow/features/lifecycle/domain/models/kick_counter_model.dart';
import 'package:herflow/features/lifecycle/domain/models/prenatal_appointment_model.dart';

// ── State Class ────────────────────────────────────────────────────────────────

/// Trạng thái toàn bộ hệ thống Kick Counter
@immutable
class KickCounterState {
  /// Danh sách phiên đếm gần nhất (tối đa 30 phiên trong 7 ngày qua)
  final List<KickSessionModel> recentSessions;

  /// Danh sách mốc khám thai vàng (đã merge trạng thái của người dùng)
  final List<PrenatalAppointmentModel> appointments;

  const KickCounterState({
    this.recentSessions = const [],
    this.appointments = const [],
  });

  KickCounterState copyWith({
    List<KickSessionModel>? recentSessions,
    List<PrenatalAppointmentModel>? appointments,
  }) {
    return KickCounterState(
      recentSessions: recentSessions ?? this.recentSessions,
      appointments: appointments ?? this.appointments,
    );
  }

  // ── Computed getters ────────────────────────────────────────────────────────

  /// Tổng cử động đã ghi nhận hôm nay (tất cả phiên trong ngày)
  int get todayTotalKicks {
    final today = DateTime.now();
    return recentSessions
        .where((s) =>
            s.startTime.year == today.year &&
            s.startTime.month == today.month &&
            s.startTime.day == today.day)
        .fold(0, (sum, s) => sum + s.kickCount);
  }

  /// Phiên gần nhất đã hoàn thành hôm nay (null nếu chưa có)
  KickSessionModel? get latestCompletedToday {
    final today = DateTime.now();
    final todayDone = recentSessions
        .where((s) =>
            s.isCompleted &&
            s.startTime.year == today.year &&
            s.startTime.month == today.month &&
            s.startTime.day == today.day)
        .toList();
    if (todayDone.isEmpty) return null;
    todayDone.sort((a, b) => b.startTime.compareTo(a.startTime));
    return todayDone.first;
  }

  /// Số phiên hoàn thành hôm nay
  int get todayCompletedSessionCount {
    final today = DateTime.now();
    return recentSessions
        .where((s) =>
            s.isCompleted &&
            s.startTime.year == today.year &&
            s.startTime.month == today.month &&
            s.startTime.day == today.day)
        .length;
  }

  /// Mốc khám tiếp theo (tuần hiện tại >= weekStart và chưa done)
  PrenatalAppointmentModel? nextAppointment(int currentWeek) {
    final upcoming = appointments
        .where((a) => !a.isDone && a.weekEnd >= currentWeek)
        .toList();
    if (upcoming.isEmpty) return null;
    upcoming.sort((a, b) => a.weekStart.compareTo(b.weekStart));
    return upcoming.first;
  }
}

// ── Controller ──────────────────────────────────────────────────────────────────

/// StateNotifier quản lý phiên đếm cử động thai và lịch khám vàng
class KickCounterController extends StateNotifier<KickCounterState> {
  final Box _settingsBox;

  KickCounterController({Box? settingsBox})
      : _settingsBox = settingsBox ?? Hive.box(AppConstants.settingsBoxName),
        super(const KickCounterState()) {
    _loadFromLocal();
  }

  String _k(String base, [String? uid]) => UserScope.key(base, uid);

  // ── Load ────────────────────────────────────────────────────────────────────

  void _loadFromLocal([String? uid]) {
    final effectiveUid = uid ?? UserScope.currentUid();

    // Load kick sessions
    final sessionsRaw = _settingsBox.get(_k(AppConstants.keyKickSessions, effectiveUid));
    List<KickSessionModel> sessions = [];
    if (sessionsRaw is String && sessionsRaw.isNotEmpty) {
      try {
        final list = jsonDecode(sessionsRaw) as List<dynamic>;
        sessions = list
            .map((e) => KickSessionModel.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();
      } catch (e) {
        debugPrint('[KickCounterController] Error parsing sessions: $e');
      }
    }

    // Chỉ giữ các phiên trong 7 ngày gần nhất
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    sessions = sessions.where((s) => s.startTime.isAfter(cutoff)).toList();
    sessions.sort((a, b) => b.startTime.compareTo(a.startTime));

    // Load prenatal appointments user data
    final appointmentsRaw =
        _settingsBox.get(_k(AppConstants.keyPrenatalAppointments, effectiveUid));
    Map<String, Map<String, dynamic>> userDataMap = {};
    if (appointmentsRaw is String && appointmentsRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(appointmentsRaw) as List<dynamic>;
        for (final item in decoded) {
          final map = Map<String, dynamic>.from(item as Map);
          final id = map['id'] as String? ?? '';
          if (id.isNotEmpty) userDataMap[id] = map;
        }
      } catch (e) {
        debugPrint('[KickCounterController] Error parsing appointments: $e');
      }
    }

    final appointments = PrenatalAppointmentModel.goldenCheckups
        .map((base) => PrenatalAppointmentModel.mergeUserData(base, userDataMap[base.id]))
        .toList();

    state = KickCounterState(
      recentSessions: sessions,
      appointments: appointments,
    );
  }

  void loadForUser(String uid) => _loadFromLocal(uid);

  // ── Kick Session Logic ─────────────────────────────────────────────────────

  /// Bắt đầu phiên đếm cử động mới
  Future<KickSessionModel> startSession() async {
    final now = DateTime.now();
    final session = KickSessionModel(
      id: 'kick_${now.millisecondsSinceEpoch}',
      startTime: now,
    );
    // Thêm vào đầu danh sách
    final updated = [session, ...state.recentSessions];
    state = state.copyWith(recentSessions: updated);
    await _persistSessions();
    return session;
  }

  /// Thêm một cú đạp vào phiên đang chạy (khi tap nút đếm)
  /// Trả về phiên đã cập nhật (hoặc đã tự complete nếu kickCount == 10)
  Future<KickSessionModel?> addKick(String sessionId) async {
    final sessions = [...state.recentSessions];
    final idx = sessions.indexWhere((s) => s.id == sessionId);
    if (idx == -1) return null;

    final current = sessions[idx];
    if (!current.isInProgress) return current;

    final newCount = current.kickCount + 1;
    KickSessionModel updated;

    if (newCount >= KickSessionModel.targetKickCount) {
      // Cardiff complete!
      updated = current.copyWith(
        kickCount: newCount,
        status: KickSessionStatus.completed,
        endTime: DateTime.now(),
      );
    } else {
      updated = current.copyWith(kickCount: newCount);
    }

    sessions[idx] = updated;
    state = state.copyWith(recentSessions: sessions);
    await _persistSessions();
    return updated;
  }

  /// Kết thúc phiên sớm do hết 2 giờ (timedOut)
  Future<KickSessionModel?> timeoutSession(String sessionId) async {
    final sessions = [...state.recentSessions];
    final idx = sessions.indexWhere((s) => s.id == sessionId);
    if (idx == -1) return null;

    final current = sessions[idx];
    if (!current.isInProgress) return current;

    final updated = current.copyWith(
      status: KickSessionStatus.timedOut,
      endTime: DateTime.now(),
    );
    sessions[idx] = updated;
    state = state.copyWith(recentSessions: sessions);
    await _persistSessions();
    return updated;
  }

  /// Xóa một phiên đếm (undo nhầm)
  Future<void> deleteSession(String sessionId) async {
    final sessions = state.recentSessions.where((s) => s.id != sessionId).toList();
    state = state.copyWith(recentSessions: sessions);
    await _persistSessions();
  }

  Future<void> _persistSessions([String? uid]) async {
    final effectiveUid = uid ?? UserScope.currentUid();
    final json = jsonEncode(state.recentSessions.map((s) => s.toMap()).toList());
    await _settingsBox.put(_k(AppConstants.keyKickSessions, effectiveUid), json);
  }

  // ── Prenatal Appointments Logic ────────────────────────────────────────────

  /// Tick hoàn thành / bỏ tick một mốc khám
  Future<void> toggleAppointmentDone(String appointmentId) async {
    final appointments = state.appointments.map((a) {
      if (a.id == appointmentId) return a.copyWith(isDone: !a.isDone);
      return a;
    }).toList();
    state = state.copyWith(appointments: appointments);
    await _persistAppointments();
  }

  /// Lưu ngày hẹn thực tế cho một mốc khám
  Future<void> setAppointmentDate(String appointmentId, DateTime date) async {
    final appointments = state.appointments.map((a) {
      if (a.id == appointmentId) return a.copyWith(appointmentDate: date);
      return a;
    }).toList();
    state = state.copyWith(appointments: appointments);
    await _persistAppointments();
  }

  Future<void> _persistAppointments([String? uid]) async {
    final effectiveUid = uid ?? UserScope.currentUid();
    final json = jsonEncode(
      state.appointments.map((a) => a.toUserDataMap()).toList(),
    );
    await _settingsBox.put(
        _k(AppConstants.keyPrenatalAppointments, effectiveUid), json);
  }
}

// ── Providers ───────────────────────────────────────────────────────────────────

/// Provider chính quản lý toàn bộ trạng thái Kick Counter + Appointments
final kickCounterProvider =
    StateNotifierProvider<KickCounterController, KickCounterState>((ref) {
  return KickCounterController();
});

/// Provider tóm tắt cử động hôm nay (dùng trong HusbandViewScreen)
final todayKickSummaryProvider = Provider<({int totalKicks, int sessions, String lastSessionTime})>((ref) {
  final state = ref.watch(kickCounterProvider);
  final lastSession = state.latestCompletedToday;
  String lastTime = '';
  if (lastSession != null) {
    final mins = lastSession.completionMinutes;
    lastTime = mins != null
        ? 'Phiên cuối: ${mins < 60 ? "$mins phút" : "${(mins / 60).toStringAsFixed(1)} giờ"}'
        : '';
  }
  return (
    totalKicks: state.todayTotalKicks,
    sessions: state.todayCompletedSessionCount,
    lastSessionTime: lastTime,
  );
});
