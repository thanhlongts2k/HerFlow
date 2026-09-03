// lib/core/notifications/notification_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:herflow/core/constants/app_constants.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

/// Dịch vụ thông báo cục bộ — lên lịch cảnh báo PMS, quản lý quyền
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  static const _kPmsNotifKey = 'pms_notification_enabled';
  static const _kPmsNotifId = 1001;

  Future<void> initialize() async {
    tz.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(requestAlertPermission: false);
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings);
  }

  bool isPmsNotificationEnabled() {
    final box = Hive.box(AppConstants.settingsBoxName);
    return box.get(_kPmsNotifKey, defaultValue: true) as bool;
  }

  Future<void> setPmsNotificationEnabled(bool enabled) async {
    final box = Hive.box(AppConstants.settingsBoxName);
    await box.put(_kPmsNotifKey, enabled);
    if (!enabled) await cancelPmsWarning();
  }

  /// Yêu cầu quyền thông báo (Android 13+)
  Future<bool> requestNotificationPermission() async {
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        return granted ?? false;
      }
      return true;
    } catch (e) {
      debugPrint('NotificationService: requestPermission error: $e');
      return false;
    }
  }

  /// Lên lịch cảnh báo PMS lúc 08:00 sáng ngày bắt đầu PMS
  Future<void> schedulePmsWarning({required DateTime pmsStartDate}) async {
    if (!isPmsNotificationEnabled()) return;

    try {
      final scheduledDate = tz.TZDateTime.from(
        DateTime(pmsStartDate.year, pmsStartDate.month, pmsStartDate.day, 8, 0),
        tz.local,
      );

      if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

      await _plugin.zonedSchedule(
        _kPmsNotifId,
        '💜 Giai đoạn PMS sắp bắt đầu',
        'Hôm nay là ngày đầu của giai đoạn tiền kinh nguyệt. Hãy tự chăm sóc bản thân nhé! 🌙',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'moona_pms_channel',
            'Cảnh báo PMS',
            channelDescription: 'Nhắc nhở chăm sóc sức khỏe trong giai đoạn tiền kinh nguyệt',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('NotificationService: schedulePmsWarning error: $e');
    }
  }

  Future<void> cancelPmsWarning() async {
    await _plugin.cancel(_kPmsNotifId);
  }
}
