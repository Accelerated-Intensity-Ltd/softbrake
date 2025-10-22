import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../config/notification_config.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _typeKey = 'notification_type';
  static const String _titleKey = 'notification_title';
  static const String _bodyKey = 'notification_body';
  static const String _scheduleTimeKey = 'notification_schedule_time';
  static const String _countdownDurationKey = 'notification_countdown_duration';
  static const String _recurringDaysKey = 'notification_recurring_days';
  static const String _recurringTimeKey = 'notification_recurring_time';

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone data
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const DarwinInitializationSettings initializationSettingsMacOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
      macOS: initializationSettingsMacOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;

    // Request permissions for iOS/macOS
    if (Platform.isIOS || Platform.isMacOS) {
      await _requestPermissions();
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS || Platform.isMacOS) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  void _onNotificationTapped(NotificationResponse notificationResponse) {
    // Handle notification tap - could navigate to app or show something
    debugPrint('Notification tapped: ${notificationResponse.payload}');
  }

  Future<NotificationSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final typeString = prefs.getString(_typeKey) ?? 'disabled';
    final type = NotificationType.values.firstWhere(
      (e) => e.toString().split('.').last == typeString,
      orElse: () => NotificationType.disabled,
    );

    final title = prefs.getString(_titleKey) ?? 'Gentle reminder';
    final body = prefs.getString(_bodyKey) ?? 'Is it time to apply the brake?';

    DateTime? scheduleTime;
    final scheduleTimeString = prefs.getString(_scheduleTimeKey);
    if (scheduleTimeString != null) {
      scheduleTime = DateTime.tryParse(scheduleTimeString);
    }

    Duration? countdownDuration;
    final countdownMinutes = prefs.getInt(_countdownDurationKey);
    if (countdownMinutes != null) {
      countdownDuration = Duration(minutes: countdownMinutes);
    }

    List<int>? recurringDays;
    final recurringDaysString = prefs.getStringList(_recurringDaysKey);
    if (recurringDaysString != null) {
      recurringDays = recurringDaysString.map((s) => int.parse(s)).toList();
    }

    TimeOfDay? recurringTime;
    final recurringTimeString = prefs.getString(_recurringTimeKey);
    if (recurringTimeString != null) {
      final parts = recurringTimeString.split(':');
      if (parts.length == 2) {
        recurringTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    }

    return NotificationSettings(
      type: type,
      title: title,
      body: body,
      scheduleTime: scheduleTime,
      countdownDuration: countdownDuration,
      recurringDays: recurringDays,
      recurringTime: recurringTime,
    );
  }

  Future<void> saveSettings(NotificationSettings settings) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_typeKey, settings.type.toString().split('.').last);
    await prefs.setString(_titleKey, settings.title);
    await prefs.setString(_bodyKey, settings.body);

    if (settings.scheduleTime != null) {
      await prefs.setString(_scheduleTimeKey, settings.scheduleTime!.toIso8601String());
    } else {
      await prefs.remove(_scheduleTimeKey);
    }

    if (settings.countdownDuration != null) {
      await prefs.setInt(_countdownDurationKey, settings.countdownDuration!.inMinutes);
    } else {
      await prefs.remove(_countdownDurationKey);
    }

    if (settings.recurringDays != null) {
      await prefs.setStringList(_recurringDaysKey, settings.recurringDays!.map((d) => d.toString()).toList());
    } else {
      await prefs.remove(_recurringDaysKey);
    }

    if (settings.recurringTime != null) {
      await prefs.setString(_recurringTimeKey, '${settings.recurringTime!.hour}:${settings.recurringTime!.minute}');
    } else {
      await prefs.remove(_recurringTimeKey);
    }

    // Schedule notifications based on new settings
    await _scheduleNotifications(settings);
  }

  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_typeKey);
    await prefs.remove(_titleKey);
    await prefs.remove(_bodyKey);
    await prefs.remove(_scheduleTimeKey);
    await prefs.remove(_countdownDurationKey);
    await prefs.remove(_recurringDaysKey);
    await prefs.remove(_recurringTimeKey);

    // Cancel all notifications
    await cancelAllNotifications();
  }

  Future<void> _scheduleNotifications(NotificationSettings settings) async {
    // Cancel existing notifications first
    await cancelAllNotifications();

    if (settings.type == NotificationType.disabled) {
      return;
    }

    await initialize();

    switch (settings.type) {
      case NotificationType.oneTime:
        if (settings.scheduleTime != null) {
          await _scheduleOneTimeNotification(settings);
        }
        break;
      case NotificationType.countdown:
        if (settings.countdownDuration != null) {
          await _scheduleCountdownNotification(settings);
        }
        break;
      case NotificationType.recurring:
        if (settings.recurringDays != null &&
            settings.recurringTime != null &&
            settings.recurringDays!.isNotEmpty) {
          await _scheduleRecurringNotifications(settings);
        }
        break;
      case NotificationType.disabled:
        break;
    }
  }

  Future<void> _scheduleOneTimeNotification(NotificationSettings settings) async {
    if (settings.scheduleTime == null || settings.scheduleTime!.isBefore(DateTime.now())) {
      return;
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'softbrake_reminders',
      'Soft Brake Reminders',
      channelDescription: 'Gentle reminders to apply the brake',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const DarwinNotificationDetails macOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
      macOS: macOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      settings.title,
      settings.body,
      tz.TZDateTime.from(settings.scheduleTime!, tz.local),
      platformChannelSpecifics,
      payload: 'one_time_reminder',
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> _scheduleCountdownNotification(NotificationSettings settings) async {
    if (settings.countdownDuration == null) return;

    final scheduledTime = DateTime.now().add(settings.countdownDuration!);

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'softbrake_reminders',
      'Soft Brake Reminders',
      channelDescription: 'Gentle reminders to apply the brake',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const DarwinNotificationDetails macOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
      macOS: macOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      1,
      settings.title,
      settings.body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      platformChannelSpecifics,
      payload: 'countdown_reminder',
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> _scheduleRecurringNotifications(NotificationSettings settings) async {
    if (settings.recurringDays == null ||
        settings.recurringTime == null ||
        settings.recurringDays!.isEmpty) {
      return;
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'softbrake_reminders',
      'Soft Brake Reminders',
      channelDescription: 'Gentle reminders to apply the brake',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const DarwinNotificationDetails macOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
      macOS: macOSPlatformChannelSpecifics,
    );

    // Schedule for each selected day
    for (int i = 0; i < settings.recurringDays!.length; i++) {
      final dayOfWeek = settings.recurringDays![i];

      // Find the next occurrence of this day at the specified time
      final now = DateTime.now();
      DateTime scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        settings.recurringTime!.hour,
        settings.recurringTime!.minute,
      );

      // Adjust to the correct day of week
      final currentDayOfWeek = scheduledDate.weekday;
      int daysToAdd = (dayOfWeek - currentDayOfWeek) % 7;

      // If it's today but the time has already passed, schedule for next week
      if (daysToAdd == 0 && scheduledDate.isBefore(now)) {
        daysToAdd = 7;
      }

      scheduledDate = scheduledDate.add(Duration(days: daysToAdd));

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        100 + i, // Use different IDs for each recurring notification
        settings.title,
        settings.body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        platformChannelSpecifics,
        payload: 'recurring_reminder_$dayOfWeek',
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }
}