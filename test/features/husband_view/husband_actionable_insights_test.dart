import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:herflow/core/constants/cycle_phase.dart';
import 'package:herflow/features/husband_view/presentation/widgets/contextual_behavior_banner.dart';
import 'package:herflow/features/husband_view/presentation/widgets/energy_battery_indicator.dart';
import 'package:herflow/features/husband_view/presentation/widgets/quick_care_signals_row.dart';
import 'package:herflow/features/husband_view/presentation/widgets/survival_cheat_sheet_card.dart';

void main() {
  group('Actionable Husband Insights Widgets Tests', () {
    testWidgets('ContextualBehaviorBanner displays correct content for Menstrual phase', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ContextualBehaviorBanner(
              phase: CyclePhase.menstrual,
              partnerName: 'Vợ yêu',
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.textContaining('Chế độ Chăm sóc & Tiếp sức'), findsOneWidget);
      expect(find.textContaining('Chuẩn bị nước ấm, túi chườm'), findsOneWidget);
    });

    testWidgets('ContextualBehaviorBanner displays correct content for Luteal phase', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ContextualBehaviorBanner(
              phase: CyclePhase.luteal,
              partnerName: 'Vợ yêu',
              isDark: true,
            ),
          ),
        ),
      );

      expect(find.textContaining('Chế độ Cưng chiều & Nhường nhịn'), findsOneWidget);
      expect(find.textContaining('Nội tiết tố đang sụt giảm'), findsOneWidget);
    });

    testWidgets('ContextualBehaviorBanner displays correct content for Follicular & Ovulation phase', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ContextualBehaviorBanner(
              phase: CyclePhase.ovulation,
              partnerName: 'Bé iu',
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.textContaining('Chế độ Kết nối & Đồng hành'), findsOneWidget);
      expect(find.textContaining('Thời điểm tuyệt vời để hẹn hò'), findsOneWidget);
    });

    testWidgets('EnergyBatteryIndicator renders segmented bar and visual caption correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnergyBatteryIndicator(
              energyLevel: 2,
              partnerName: 'Em bé',
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.text('Pin năng lượng của Em bé'), findsOneWidget);
      expect(find.textContaining('2/5 • Pin yếu'), findsOneWidget);
      expect(find.textContaining('nàng cần nghỉ ngơi, uống nước ấm'), findsOneWidget);
    });

    testWidgets('EnergyBatteryIndicator clamps extreme levels gracefully', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnergyBatteryIndicator(
              energyLevel: 99,
              partnerName: 'Nàng',
              isDark: true,
            ),
          ),
        ),
      );

      expect(find.textContaining('5/5 • Cực đại'), findsOneWidget);
      expect(find.textContaining('Năng lượng và tinh thần nàng đạt đỉnh!'), findsOneWidget);
    });

    testWidgets('SurvivalCheatSheetCard expands and collapses on tap', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SurvivalCheatSheetCard(
                phase: CyclePhase.luteal,
                isDark: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Bí Kíp Sinh Tồn Cho Chàng'), findsOneWidget);
      expect(find.text('NÊN CHỦ ĐỘNG LÀM NGAY'), findsOneWidget);
      expect(find.text('TUYỆT ĐỐI NÊN TRÁNH'), findsOneWidget);
      expect(find.textContaining('TUYỆT ĐỐI KHÔNG nói câu: "Em lại tới tháng rồi à?"'), findsOneWidget);

      // Tap header to collapse
      await tester.tap(find.text('Bí Kíp Sinh Tồn Cho Chàng'));
      await tester.pumpAndSettle();

      // Tap again to re-expand
      await tester.tap(find.text('Bí Kíp Sinh Tồn Cho Chàng'));
      await tester.pumpAndSettle();

      expect(find.text('NÊN CHỦ ĐỘNG LÀM NGAY'), findsOneWidget);
    });

    testWidgets('QuickCareSignalsRow renders 3 one-tap rescue shortcuts', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: QuickCareSignalsRow(
                partnerName: 'Vợ iu',
                isDark: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Cứu Nguy 1 Chạm Tới Vợ iu'), findsOneWidget);
      expect(find.text('Mua đồ ngọt'), findsOneWidget);
      expect(find.text('Massage'), findsOneWidget);
      expect(find.text('Ôm sạc pin'), findsOneWidget);
    });
  });
}
