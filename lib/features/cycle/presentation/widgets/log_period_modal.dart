// lib/features/cycle/presentation/widgets/log_period_modal.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:herflow/core/constants/app_colors.dart';
import '../../domain/entities/period_record.dart';
import '../controllers/cycle_controller.dart';

/// Modal ghi nhận kỳ kinh nguyệt mới với tùy chọn chi tiết
class LogPeriodModal extends ConsumerStatefulWidget {
  final DateTime initialDate;

  const LogPeriodModal({
    super.key,
    required this.initialDate,
  });

  static Future<void> show(BuildContext context, DateTime initialDate) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => LogPeriodModal(initialDate: initialDate),
    );
  }

  @override
  ConsumerState<LogPeriodModal> createState() => _LogPeriodModalState();
}

class _LogPeriodModalState extends ConsumerState<LogPeriodModal> {
  late DateTime _startDate;
  DateTime? _endDate;
  bool _isOngoing = true;
  FlowIntensity _intensity = FlowIntensity.medium;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Ghi Nhận Kỳ Kinh Nguyệt',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),

          // 1. Ngày bắt đầu
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_rounded, color: AppColors.primary),
            title: const Text('Ngày bắt đầu:', style: TextStyle(fontWeight: FontWeight.w600)),
            trailing: TextButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setState(() => _startDate = picked);
                }
              },
              child: Text(
                DateFormat('dd/MM/yyyy').format(_startDate),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ),

          // 2. Trạng thái đang diễn ra
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Kỳ kinh đang diễn ra', style: TextStyle(fontWeight: FontWeight.w600)),
            value: _isOngoing,
            activeThumbColor: AppColors.primary,
            onChanged: (val) {
              setState(() {
                _isOngoing = val;
                if (val) {
                  _endDate = null;
                } else {
                  _endDate = _startDate.add(const Duration(days: 4));
                }
              });
            },
          ),

          // 3. Ngày kết thúc nếu không ongoing
          if (!_isOngoing)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_available_rounded, color: AppColors.primary),
              title: const Text('Ngày kết thúc:', style: TextStyle(fontWeight: FontWeight.w600)),
              trailing: TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _endDate ?? _startDate.add(const Duration(days: 4)),
                    firstDate: _startDate,
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() => _endDate = picked);
                  }
                },
                child: Text(
                  _endDate != null ? DateFormat('dd/MM/yyyy').format(_endDate!) : 'Chọn ngày',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ),

          const SizedBox(height: 10),

          // 4. Mức độ lượng kinh
          const Text('Lượng kinh nguyệt:', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: FlowIntensity.values.map((flow) {
              final isSel = _intensity == flow;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _intensity = flow),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSel ? AppColors.primaryContainer : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSel ? AppColors.primary : Colors.grey.withAlpha(60),
                        width: isSel ? 1.8 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        flow.vietnameseName,
                        style: TextStyle(
                          fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                          color: isSel ? AppColors.primaryDark : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // 5. Action Bar cân xứng ngang hàng
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Hủy', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(cycleControllerProvider.notifier).logPeriodRecord(
                            startDate: _startDate,
                            endDate: _isOngoing ? null : _endDate,
                            flowIntensity: _intensity,
                          );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã ghi nhận kỳ kinh bắt đầu từ ${DateFormat('dd/MM').format(_startDate)}'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Lưu Kỳ Kinh', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
