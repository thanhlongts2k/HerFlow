// lib/features/cycle/presentation/widgets/cycle_phase_legend.dart
import 'package:flutter/material.dart';
import 'package:herflow/core/constants/cycle_phase.dart';

/// Widget chú thích màu sắc của 4 pha sinh học chu kỳ
class CyclePhaseLegend extends StatelessWidget {
  const CyclePhaseLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceAround,
      spacing: 12,
      runSpacing: 8,
      children: CyclePhase.values.map((p) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: p.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              p.shortTitle,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        );
      }).toList(),
    );
  }
}
