// lib/features/lifecycle/presentation/controllers/pregnancy_controller.dart

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:herflow/core/constants/app_constants.dart';
import 'package:herflow/core/utils/user_scope.dart';
import 'package:herflow/features/lifecycle/domain/models/fetal_week_data.dart';
import 'package:herflow/features/lifecycle/domain/models/pregnancy_config_model.dart';
import 'package:herflow/features/lifecycle/domain/services/pregnancy_calculator_service.dart';

/// Controller quản lý cấu hình và trạng thái theo dõi thai kỳ (Pregnancy Mode)
class PregnancyController extends StateNotifier<PregnancyConfigModel?> {
  final Box _settingsBox;

  PregnancyController({Box? settingsBox})
      : _settingsBox = settingsBox ?? Hive.box(AppConstants.settingsBoxName),
        super(null) {
    _loadFromLocal();
  }

  String _k(String base, [String? uid]) => UserScope.key(base, uid);

  /// Nạp cấu hình từ Hive local theo scoped UID
  void _loadFromLocal([String? uid]) {
    final effectiveUid = uid ?? UserScope.currentUid();
    final raw = _settingsBox.get(_k(AppConstants.keyPregnancyConfig, effectiveUid));
    if (raw == null) {
      // Backward compat fallback: kiểm tra keyPregnancyDueDate nếu đã lưu trước đó
      final rawDueDate = _settingsBox.get(_k(AppConstants.keyPregnancyDueDate, effectiveUid));
      if (rawDueDate is String && rawDueDate.isNotEmpty) {
        final edd = DateTime.tryParse(rawDueDate);
        if (edd != null) {
          final lmp = PregnancyCalculatorService.calculateLMPFromDueDate(edd);
          state = PregnancyConfigModel(
            lastMenstrualPeriod: lmp,
            estimatedDueDate: edd,
            isTrackingActive: true,
          );
          return;
        }
      }
      state = null;
      return;
    }

    try {
      if (raw is String) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        state = PregnancyConfigModel.fromMap(map);
      } else if (raw is Map) {
        state = PregnancyConfigModel.fromMap(Map<String, dynamic>.from(raw));
      } else {
        state = null;
      }
    } catch (e) {
      debugPrint('[PregnancyController] Error parsing pregnancy config: $e');
      state = null;
    }
  }

  /// Thiết lập thai kỳ dựa trên ngày đầu kỳ kinh cuối (LMP)
  /// Tự động tính ngày dự sinh EDD = LMP + 280 ngày theo quy tắc Naegele
  Future<void> setPregnancyByLmp(DateTime lmp, {String? uid}) async {
    final effectiveUid = uid ?? UserScope.currentUid();
    final cleanLmp = PregnancyCalculatorService.normalizeDate(lmp);
    final calculatedEdd = PregnancyCalculatorService.calculateDueDateFromLMP(cleanLmp);

    final model = PregnancyConfigModel(
      lastMenstrualPeriod: cleanLmp,
      estimatedDueDate: calculatedEdd,
      isTrackingActive: true,
    );

    // 1. Cập nhật RAM tức thì
    state = model;

    // 2. Lưu Hive local bền vững
    await _settingsBox.put(
      _k(AppConstants.keyPregnancyConfig, effectiveUid),
      jsonEncode(model.toMap()),
    );
    await _settingsBox.put(
      _k(AppConstants.keyPregnancyDueDate, effectiveUid),
      calculatedEdd.toIso8601String(),
    );

    // 3. Sync Firestore fire-and-forget
    if (effectiveUid.isNotEmpty) {
      try {
        FirebaseFirestore.instance.collection('users').doc(effectiveUid).set(
          {
            'pregnancyConfig': model.toMap(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        ).catchError((e) {
          debugPrint('[PregnancyController] Firestore sync error (ignored): $e');
        });
      } catch (e) {
        debugPrint('[PregnancyController] Firestore sync skipped: $e');
      }
    }

    debugPrint('[PregnancyController] setPregnancyByLmp: LMP=$cleanLmp, EDD=$calculatedEdd');
  }

  /// Thiết lập thai kỳ dựa trên ngày dự sinh (EDD - Theo kết quả siêu âm)
  /// Tự động tính ngày LMP tương đương = EDD - 280 ngày
  Future<void> setPregnancyByEdd(DateTime edd, {String? uid}) async {
    final effectiveUid = uid ?? UserScope.currentUid();
    final cleanEdd = PregnancyCalculatorService.normalizeDate(edd);
    final calculatedLmp = PregnancyCalculatorService.calculateLMPFromDueDate(cleanEdd);

    final model = PregnancyConfigModel(
      lastMenstrualPeriod: calculatedLmp,
      estimatedDueDate: cleanEdd,
      isTrackingActive: true,
    );

    // 1. Cập nhật RAM tức thì
    state = model;

    // 2. Lưu Hive local bền vững
    await _settingsBox.put(
      _k(AppConstants.keyPregnancyConfig, effectiveUid),
      jsonEncode(model.toMap()),
    );
    await _settingsBox.put(
      _k(AppConstants.keyPregnancyDueDate, effectiveUid),
      cleanEdd.toIso8601String(),
    );

    // 3. Sync Firestore fire-and-forget
    if (effectiveUid.isNotEmpty) {
      try {
        FirebaseFirestore.instance.collection('users').doc(effectiveUid).set(
          {
            'pregnancyConfig': model.toMap(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        ).catchError((e) {
          debugPrint('[PregnancyController] Firestore sync error (ignored): $e');
        });
      } catch (e) {
        debugPrint('[PregnancyController] Firestore sync skipped: $e');
      }
    }

    debugPrint('[PregnancyController] setPregnancyByEdd: EDD=$cleanEdd, LMP=$calculatedLmp');
  }

  /// Xóa hoặc kết thúc theo dõi thai kỳ
  Future<void> clearPregnancy({String? uid}) async {
    final effectiveUid = uid ?? UserScope.currentUid();

    state = null;

    await _settingsBox.delete(_k(AppConstants.keyPregnancyConfig, effectiveUid));
    await _settingsBox.delete(_k(AppConstants.keyPregnancyDueDate, effectiveUid));

    if (effectiveUid.isNotEmpty) {
      try {
        FirebaseFirestore.instance.collection('users').doc(effectiveUid).set(
          {
            'pregnancyConfig': FieldValue.delete(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        ).catchError((e) {
          debugPrint('[PregnancyController] Firestore clear error (ignored): $e');
        });
      } catch (e) {
        debugPrint('[PregnancyController] Firestore clear skipped: $e');
      }
    }

    debugPrint('[PregnancyController] clearPregnancy completed');
  }

  /// Nạp cấu hình thai kỳ cho người dùng cụ thể (gọi sau login/restore)
  void loadForUser(String uid) {
    _loadFromLocal(uid);
  }
}

// ── Providers ───────────────────────────────────────────────────────────────

/// StateNotifierProvider quản lý cấu hình thai kỳ
final pregnancyConfigProvider =
    StateNotifierProvider<PregnancyController, PregnancyConfigModel?>((ref) {
  return PregnancyController();
});

/// Alias tiện lợi theo chuẩn đặt tên controller
final pregnancyControllerProvider = pregnancyConfigProvider;

/// Provider tự động tính toán tuổi thai hiện tại (GestationalAgeResult)
/// Tự động cập nhật theo state thai kỳ và thời gian hiện tại
final currentGestationalAgeProvider = Provider<GestationalAgeResult?>((ref) {
  final config = ref.watch(pregnancyConfigProvider);
  if (config == null || !config.isTrackingActive) return null;

  if (config.lastMenstrualPeriod != null) {
    return PregnancyCalculatorService.calculateGestationalAge(config.lastMenstrualPeriod!);
  } else if (config.estimatedDueDate != null) {
    final lmp = PregnancyCalculatorService.calculateLMPFromDueDate(config.estimatedDueDate!);
    return PregnancyCalculatorService.calculateGestationalAge(lmp);
  }
  return null;
});

/// Provider cung cấp dữ liệu hoa quả, kích thước và lời khuyên theo tuần thai hiện tại
final currentFetalWeekDataProvider = Provider<FetalWeekData?>((ref) {
  final age = ref.watch(currentGestationalAgeProvider);
  if (age == null) return null;

  // Lấy tuần thai đang diễn ra (currentWeekOrdinal, ví dụ 11 tuần 3 ngày là Tuần thứ 12)
  return FetalWeekData.getWeekData(age.currentWeekOrdinal);
});
