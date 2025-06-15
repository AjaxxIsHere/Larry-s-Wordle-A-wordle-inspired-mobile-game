import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Request notification permission for Android 13 (API 33) and above
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation != null) {
      final bool? granted =
          await androidImplementation.requestNotificationsPermission();
      if (granted != null && granted) {
        print('Notification permissions granted');
      } else {
        print('Notification permissions denied');
      }
    }
  }

  Future<void> scheduleDailyNotifications() async {
    // Helper to schedule a notification with fallback
    Future<void> scheduleWithFallback({
      required int id,
      required String title,
      required String body,
      required tz.TZDateTime scheduledDate,
      required String channelId,
      required String channelName,
      required String channelDescription,
    }) async {
      try {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channelId,
              channelName,
              channelDescription: channelDescription,
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          matchDateTimeComponents: DateTimeComponents.time,
          androidScheduleMode: AndroidScheduleMode.exact,
        );
      } on PlatformException catch (e) {
        if (e.code == 'exact_alarms_not_permitted') {
          // Fallback to inexact
          await flutterLocalNotificationsPlugin.zonedSchedule(
            id,
            title,
            body,
            scheduledDate,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channelId,
                channelName,
                channelDescription: channelDescription,
                importance: Importance.max,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
              ),
            ),
            matchDateTimeComponents: DateTimeComponents.time,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
        } else {
          rethrow;
        }
      }
    }

    // Notification 1: New daily challenge (e.g., 8:00 AM)
    await scheduleWithFallback(
      id: 0,
      title: '🙀 New Daily Challenge!',
      body: 'A new wordle challenge is ready. Play now!',
      scheduledDate: _nextInstanceOfTime(8, 0),
      channelId: 'daily_challenge_channel',
      channelName: 'Daily Challenge',
      channelDescription: 'Notification for new daily challenge',
    );
    // Notification 2: Reminder to come back (e.g., 7:00 PM)
    await scheduleWithFallback(
      id: 1,
      title: '😿 Come Back to Larry\'s Wordle!',
      body: 'Don\'t forget to play today\'s challenge!',
      scheduledDate: _nextInstanceOfTime(14, 0),
      channelId: 'reminder_channel',
      channelName: 'Reminder',
      channelDescription: 'Reminder to come back to the game',
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    // Defensive: tz.local should be initialized in main.dart before using NotificationService
    // If not, this will throw a runtime error, so document this requirement for maintainers.
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
