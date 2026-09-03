// lib/features/onboarding/presentation/screens/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:herflow/core/constants/app_colors.dart';
import 'package:herflow/core/constants/app_constants.dart';
import 'package:herflow/core/routes/app_routes.dart';

/// Màn hình onboarding 3 bước — thu thập ngày kỳ kinh cuối, độ dài chu kỳ và mục tiêu
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Step 1
  DateTime _lastPeriodDate = DateTime.now().subtract(const Duration(days: 14));

  // Step 2
  int _cycleLength = AppConstants.defaultCycleLength;
  int _periodDuration = AppConstants.defaultPeriodDuration;

  // Step 3
  String _selectedGoal = 'track_cycle';

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    final box = Hive.box(AppConstants.settingsBoxName);
    await box.put(AppConstants.keyLastPeriodStart, _lastPeriodDate.toIso8601String());
    await box.put(AppConstants.keyCycleLength, _cycleLength);
    await box.put(AppConstants.keyPeriodDuration, _periodDuration);
    await box.put(AppConstants.keyOnboardingGoal, _selectedGoal);
    await box.put(AppConstants.keyHasSelectedRole, true);
    await box.put(AppConstants.keyIsOnboardingCompleted, true);

    if (mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: List.generate(3, (i) => Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: i <= _currentPage ? AppColors.primary : Colors.grey.withAlpha(80),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                )),
              ),
            ),
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildStep1(theme),
                  _buildStep2(theme),
                  _buildStep3(theme),
                ],
              ),
            ),
            // Next button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: ElevatedButton(
                onPressed: _nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  _currentPage < 2 ? 'Tiếp tục →' : 'Bắt đầu Moona 🌙',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text('🌺', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text('Kỳ kinh cuối của bạn\nbắt đầu khi nào?',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Giúp Moona tính toán chu kỳ chính xác hơn.',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
          const SizedBox(height: 32),
          Center(
            child: CalendarDatePicker(
              initialDate: _lastPeriodDate,
              firstDate: DateTime.now().subtract(const Duration(days: 60)),
              lastDate: DateTime.now(),
              onDateChanged: (date) => setState(() => _lastPeriodDate = date),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text('📅', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text('Chu kỳ của bạn thường dài\nbao nhiêu ngày?',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 32),
          _buildCounterRow(
            label: 'Độ dài chu kỳ',
            value: _cycleLength,
            min: 21, max: 45,
            onDecrement: () => setState(() => _cycleLength--),
            onIncrement: () => setState(() => _cycleLength++),
          ),
          const SizedBox(height: 20),
          _buildCounterRow(
            label: 'Thời gian hành kinh',
            value: _periodDuration,
            min: 2, max: 10,
            onDecrement: () => setState(() => _periodDuration--),
            onIncrement: () => setState(() => _periodDuration++),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3(ThemeData theme) {
    final goals = [
      ('track_cycle', '📊', 'Theo dõi chu kỳ'),
      ('partner_sync', '💑', 'Đồng bộ với chồng'),
      ('health', '🌿', 'Chăm sóc sức khỏe'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text('🎯', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text('Mục tiêu chính của bạn\nkhi dùng Moona?',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 32),
          ...goals.map((g) {
            final isSelected = _selectedGoal == g.$1;
            return GestureDetector(
              onTap: () => setState(() => _selectedGoal = g.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withAlpha(20) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.grey.withAlpha(80),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(g.$2, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Text(g.$3, style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppColors.primary : null,
                    )),
                    const Spacer(),
                    if (isSelected)
                      const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCounterRow({
    required String label,
    required int value,
    required int min,
    required int max,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: value > min ? onDecrement : null,
              color: AppColors.primary,
            ),
            SizedBox(
              width: 40,
              child: Text('$value',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: value < max ? onIncrement : null,
              color: AppColors.primary,
            ),
          ],
        ),
      ],
    );
  }
}
