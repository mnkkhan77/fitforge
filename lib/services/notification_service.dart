import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Schedules the optional daily "time to train" reminder (#2).
///
/// Uses inexact scheduling so it never needs the SCHEDULE_EXACT_ALARM
/// permission, and repeats daily at the chosen time. All plugin calls are
/// guarded so the rest of the app keeps working if notifications are
/// unavailable (e.g. unit tests, unsupported platforms).
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _inited = false;
  static const int _id = 1001;

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'workout_reminders',
      'Workout Reminders',
      channelDescription: 'Daily reminder to do your FitForge workout',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  static Future<void> init() async {
    if (_inited) return;
    try {
      tzdata.initializeTimeZones();
      try {
        final name = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(name));
      } catch (_) {
        // Fall back to UTC if the device timezone can't be resolved.
      }
      const init = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );
      await _plugin.initialize(init);
      _inited = true;
    } catch (e) {
      debugPrint('NotificationService.init failed: $e');
    }
  }

  /// Asks for the Android 13+ notification permission. Returns true if granted
  /// (or not required on this OS version).
  static Future<bool> requestPermission() async {
    try {
      await init();
      final android = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> scheduleDaily(int hour, int minute) async {
    try {
      await init();
      if (!_inited) return;
      await _plugin.cancel(_id);
      final now = tz.TZDateTime.now(tz.local);
      var when = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      if (!when.isAfter(now)) when = when.add(const Duration(days: 1));
      await _plugin.zonedSchedule(
        _id,
        '💪 Time to train',
        'Your FitForge workout is waiting — keep your streak alive!',
        when,
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('NotificationService.scheduleDaily failed: $e');
    }
  }

  static Future<void> cancel() async {
    try {
      await init();
      await _plugin.cancel(_id);
    } catch (_) {}
  }
}
