// lib/features/lifecycle/presentation/widgets/prenatal_appointments_card.dart
//
// Thẻ Lịch Khám Thai Mốc Vàng — hiển thị 7 mốc khám chuẩn y tế Việt Nam
// dưới dạng timeline tương tác: tick hoàn thành, mốc hiện tại được highlight.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:herflow/core/constants/app_colors.dart';
import 'package:herflow/core/utils/haptic_feedback_utils.dart';
import 'package:herflow/features/lifecycle/domain/models/prenatal_appointment_model.dart';
import 'package:herflow/features/lifecycle/presentation/controllers/kick_counter_controller.dart';

/// Card hiển thị toàn bộ lịch khám thai mốc vàng dưới dạng timeline tương tác
class PrenatalAppointmentsCard extends ConsumerWidget {
  /// Tuần thai hiện tại (dùng để highlight mốc đang trong giai đoạn hiện tại)
  final int currentWeek;
  final bool isDark;

  const PrenatalAppointmentsCard({
    super.key,
    required this.currentWeek,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointments = ref.watch(kickCounterProvider).appointments;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(18) : Colors.black.withAlpha(10),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.secondary.withAlpha(isDark ? 60 : 40),
                        AppColors.secondaryLight.withAlpha(isDark ? 40 : 30),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('📅', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lịch Khám Thai Mốc Vàng',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black87,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        '7 mốc chuẩn y tế Việt Nam',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildProgressBadge(appointments, isDark),
              ],
            ),
          ),
          Divider(
            color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(8),
            height: 1,
            indent: 18,
            endIndent: 18,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: List.generate(appointments.length, (i) {
                final appt = appointments[i];
                final isLast = i == appointments.length - 1;
                final status = appt.statusFor(currentWeek);
                return _AppointmentTile(
                  appointment: appt,
                  status: status,
                  isLast: isLast,
                  isDark: isDark,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBadge(
      List<PrenatalAppointmentModel> appointments, bool isDark) {
    final doneCount = appointments.where((a) => a.isDone).length;
    final total = appointments.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: doneCount == total
            ? AppColors.success.withAlpha(isDark ? 50 : 30)
            : AppColors.secondary.withAlpha(isDark ? 40 : 25),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$doneCount/$total',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: doneCount == total ? AppColors.success : AppColors.secondary,
        ),
      ),
    );
  }
}

class _AppointmentTile extends ConsumerWidget {
  final PrenatalAppointmentModel appointment;
  final AppointmentStatus status;
  final bool isLast;
  final bool isDark;

  const _AppointmentTile({
    required this.appointment,
    required this.status,
    required this.isLast,
    required this.isDark,
  });

  Color get _accentColor {
    switch (status) {
      case AppointmentStatus.current:
        return AppColors.primary;
      case AppointmentStatus.done:
        return AppColors.success;
      case AppointmentStatus.upcoming:
        return isDark ? Colors.white30 : Colors.black26;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCurrent = status == AppointmentStatus.current;
    final isUpcoming = status == AppointmentStatus.upcoming && !appointment.isDone;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: () => _toggleDone(ref),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutBack,
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: appointment.isDone
                          ? AppColors.success
                          : (isCurrent
                              ? AppColors.primary
                              : (isDark ? Colors.white10 : Colors.black.withAlpha(20))),
                      border: Border.all(color: _accentColor, width: 2),
                      boxShadow: (appointment.isDone || isCurrent)
                          ? [BoxShadow(color: _accentColor.withAlpha(60), blurRadius: 8)]
                          : null,
                    ),
                    child: appointment.isDone
                        ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                        : (isCurrent
                            ? const Icon(Icons.circle, size: 8, color: Colors.white)
                            : null),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                        color: appointment.isDone
                            ? AppColors.success.withAlpha(60)
                            : (isDark ? Colors.white12 : Colors.black.withAlpha(20)),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? AppColors.primary.withAlpha(isDark ? 25 : 12)
                      : (appointment.isDone
                          ? AppColors.success.withAlpha(isDark ? 15 : 8)
                          : Colors.transparent),
                  borderRadius: BorderRadius.circular(14),
                  border: isCurrent
                      ? Border.all(
                          color: AppColors.primary.withAlpha(isDark ? 80 : 60),
                          width: 1.2)
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: _accentColor.withAlpha(isDark ? 45 : 30),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            appointment.weekRangeLabel,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: _accentColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(appointment.emoji, style: const TextStyle(fontSize: 14)),
                        if (isCurrent) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'HIỆN TẠI',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      appointment.title,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isUpcoming
                            ? (isDark ? Colors.white38 : Colors.black38)
                            : (isDark ? Colors.white.withAlpha(222) : Colors.black87),
                        decoration:
                            appointment.isDone ? TextDecoration.lineThrough : null,
                        decorationColor: AppColors.success.withAlpha(isDark ? 120 : 90),
                      ),
                    ),
                    if (!appointment.isDone && !isUpcoming) ...[
                      const SizedBox(height: 4),
                      Text(
                        appointment.description,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.45,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    if (appointment.isDone || isCurrent)
                      GestureDetector(
                        onTap: () => _toggleDone(ref),
                        child: Text(
                          appointment.isDone
                              ? '✅ Đã khám — Nhấn để bỏ tick'
                              : '👆 Nhấn để đánh dấu đã khám',
                          style: TextStyle(
                            fontSize: 11,
                            color: appointment.isDone
                                ? AppColors.success.withAlpha(isDark ? 160 : 120)
                                : AppColors.primary.withAlpha(isDark ? 200 : 170),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleDone(WidgetRef ref) {
    AppHaptics.medium();
    ref.read(kickCounterProvider.notifier).toggleAppointmentDone(appointment.id);
  }
}
