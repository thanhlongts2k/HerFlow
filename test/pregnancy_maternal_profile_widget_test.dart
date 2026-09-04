// test/pregnancy_maternal_profile_widget_test.dart
//
// Widget tests cho Phân hệ Hồ sơ Thể Trạng Mẹ Bầu & Tăng cân chuẩn IOM:
// - Kiểm thử MaternalHealthSummaryCard khi chưa hoàn thiện (Progressive Profiling).
// - Kiểm thử MaternalHealthSummaryCard khi đã hoàn thiện (BMI, chuẩn IOM tuần thai, lời khuyên y khoa).
// - Kiểm thử MaternalProfileSheet mở và hiển thị các trường nhập liệu.
//
// Tuân thủ Điều 10 AGENTS.md: Thiết lập Viewport 1080x2400.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:herflow/core/utils/user_scope.dart';
import 'package:herflow/features/lifecycle/domain/models/life_stage.dart';
import 'package:herflow/features/lifecycle/domain/models/maternal_health_profile_model.dart';
import 'package:herflow/features/lifecycle/domain/models/pregnancy_config_model.dart';
import 'package:herflow/features/lifecycle/presentation/controllers/life_stage_controller.dart';
import 'package:herflow/features/lifecycle/presentation/controllers/pregnancy_controller.dart';
import 'package:herflow/features/lifecycle/presentation/widgets/maternal_health_summary_card.dart';
import 'package:herflow/features/lifecycle/presentation/widgets/maternal_profile_sheet.dart';

// ignore: subtype_of_sealed_class
class _FakeBox extends Fake implements Box {
  final Map<dynamic, dynamic> _data = {};

  @override
  dynamic get(dynamic key, {dynamic defaultValue}) =>
      _data.containsKey(key) ? _data[key] : defaultValue;

  @override
  Future<void> put(dynamic key, dynamic value) async {
    _data[key] = value;
  }

  @override
  Future<void> delete(dynamic key) async {
    _data.remove(key);
  }

  @override
  Future<int> clear() async {
    _data.clear();
    return 0;
  }

  @override
  bool containsKey(dynamic key) => _data.containsKey(key);

  @override
  bool get isOpen => true;
}

void main() {
  late _FakeBox fakeBox;

  setUpAll(() async {
    await initializeDateFormatting('vi', null);
  });

  setUp(() async {
    fakeBox = _FakeBox();
    UserScope.setActiveUid('test_maternal_user');
  });

  Widget buildTestApp({
    required Widget child,
    PregnancyConfigModel? config,
    LifeStageState lifeStageState = const LifeStageState(currentStage: LifeStage.pregnancy),
  }) {
    final pregnancyCtrl = PregnancyController(settingsBox: fakeBox);
    if (config != null) {
      pregnancyCtrl.state = config;
    }

    final lifeStageCtrl = LifeStageController(settingsBox: fakeBox);
    lifeStageCtrl.state = lifeStageState;

    return ProviderScope(
      overrides: [
        pregnancyConfigProvider.overrideWith((ref) => pregnancyCtrl),
        lifeStageControllerProvider.overrideWith((ref) => lifeStageCtrl),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('MaternalHealthSummaryCard - PROGRESSIVE PROFILING TESTS', () {
    testWidgets('Hiển thị thanh tiến trình khi chưa hoàn thiện hồ sơ (< 100%)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final lmp = DateTime.now().subtract(const Duration(days: 70)); // ~Tuần 10
      final config = PregnancyConfigModel(
        lastMenstrualPeriod: lmp,
        estimatedDueDate: lmp.add(const Duration(days: 280)),
        isTrackingActive: true,
      );

      await tester.pumpWidget(
        buildTestApp(
          config: config,
          child: const Scaffold(
            body: SingleChildScrollView(
              child: MaternalHealthSummaryCard(currentWeek: 10, isDark: false),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hồ Sơ Thể Trạng Của Mẹ'), findsOneWidget);
      expect(find.text('Đã xong 0%'), findsOneWidget);
      expect(find.text('Hoàn thiện hồ sơ thể trạng'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('Bấm Hoàn thiện hồ sơ thể trạng -> mở MaternalProfileSheet', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final lmp = DateTime.now().subtract(const Duration(days: 70));
      final config = PregnancyConfigModel(
        lastMenstrualPeriod: lmp,
        estimatedDueDate: lmp.add(const Duration(days: 280)),
        isTrackingActive: true,
      );

      await tester.pumpWidget(
        buildTestApp(
          config: config,
          child: const Scaffold(
            body: SingleChildScrollView(
              child: MaternalHealthSummaryCard(currentWeek: 10, isDark: false),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Bấm nút mở sheet
      await tester.tap(find.text('Hoàn thiện hồ sơ thể trạng'));
      await tester.pumpAndSettle();

      // Modal Sheet xuất hiện
      expect(find.byType(MaternalProfileSheet), findsOneWidget);
      expect(find.text('1. Năm sinh của Mẹ'), findsOneWidget);
      expect(find.text('2. Chiều cao & Cân nặng trước bầu'), findsOneWidget);
      expect(find.text('Lưu Hồ Sơ Thể Trạng'), findsOneWidget);
    });

    testWidgets('Hiển thị đầy đủ BMI, dải chuẩn IOM và cảnh báo tuổi mẹ >= 35 khi đã hoàn thiện', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final lmp = DateTime.now().subtract(const Duration(days: 112)); // Tuần 16
      final profile = MaternalHealthProfileModel(
        birthYear: DateTime.now().year - 36, // 36 tuổi (AMA)
        heightCm: 160.0,
        prePregnancyWeightKg: 52.0, // BMI = 20.3 (Bình thường)
        currentWeightKg: 54.5,     // Tăng +2.5 kg
        parity: 'Con so (Con đầu)',
        deliveryPlan: 'Sinh thường',
        targetHospital: 'BV Phụ Sản Hà Nội',
      );

      final config = PregnancyConfigModel(
        lastMenstrualPeriod: lmp,
        estimatedDueDate: lmp.add(const Duration(days: 280)),
        isTrackingActive: true,
        maternalProfile: profile,
      );

      await tester.pumpWidget(
        buildTestApp(
          config: config,
          child: const Scaffold(
            body: SingleChildScrollView(
              child: MaternalHealthSummaryCard(currentWeek: 16, isDark: false),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Đã chuyển sang trạng thái Complete
      expect(find.text('Thể Trạng & Cân Nặng Thai Kỳ'), findsOneWidget);
      expect(find.textContaining('20.3'), findsOneWidget);
      expect(find.textContaining('Mẹ 36 tuổi'), findsOneWidget);
      expect(find.textContaining('Thực tế:'), findsOneWidget);
      expect(find.textContaining('+2.5 kg'), findsOneWidget);

      // Cảnh báo y khoa mẹ >= 35 tuổi
      expect(find.textContaining('Mẹ từ 35 tuổi trở lên'), findsOneWidget);
      expect(find.textContaining('NIPT'), findsOneWidget);
    });
  });
}
