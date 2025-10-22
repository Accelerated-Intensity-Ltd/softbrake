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
  static const String _isDailyKey = 'notification_is_daily';

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

    // Create notification channel for Android
    if (Platform.isAndroid) {
      await _createNotificationChannel();
    }

    _isInitialized = true;

    // Request permissions for iOS/macOS/Android
    await _requestPermissions();
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'softbrake_reminders',
      'Soft Brake Reminders',
      description: 'Gentle reminders to apply the brake',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      // Request notification permission
      final notificationResult = await androidImplementation?.requestNotificationsPermission();
      debugPrint('NotificationService: Notification permission result: $notificationResult');

      // Request exact alarm permission (Android 12+)
      final exactAlarmResult = await androidImplementation?.requestExactAlarmsPermission();
      debugPrint('NotificationService: Exact alarm permission result: $exactAlarmResult');

      // Check if exact alarm permission is granted
      final hasExactAlarmPermission = await androidImplementation?.canScheduleExactNotifications();
      debugPrint('NotificationService: Can schedule exact notifications: $hasExactAlarmPermission');

      if (hasExactAlarmPermission == false) {
        debugPrint('NotificationService: Exact alarm permission denied - notifications may not work reliably');
      }
    } else if (Platform.isIOS || Platform.isMacOS) {
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
      final parsedTime = DateTime.tryParse(scheduleTimeString);
      // Only use the scheduled time if it's in the future
      if (parsedTime != null && parsedTime.isAfter(DateTime.now())) {
        scheduleTime = parsedTime;
      }
    }

    Duration? countdownDuration;
    final countdownMinutes = prefs.getInt(_countdownDurationKey);
    if (countdownMinutes != null) {
      countdownDuration = Duration(minutes: countdownMinutes);
    }

    final isDaily = prefs.getBool(_isDailyKey) ?? false;

    return NotificationSettings(
      type: type,
      title: title,
      body: body,
      scheduleTime: scheduleTime,
      countdownDuration: countdownDuration,
      isDaily: isDaily,
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

    await prefs.setBool(_isDailyKey, settings.isDaily);

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
    await prefs.remove(_isDailyKey);

    // Cancel all notifications
    await cancelAllNotifications();
  }

  Future<void> _scheduleNotifications(NotificationSettings settings) async {
    // Cancel existing notifications first
    await cancelAllNotifications();

    if (settings.type == NotificationType.disabled) {
      debugPrint('NotificationService: Notifications disabled, skipping scheduling');
      return;
    }

    await initialize();
    debugPrint('NotificationService: Scheduling ${settings.type} notification');

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
      case NotificationType.disabled:
        break;
    }
  }

  Future<void> _scheduleOneTimeNotification(NotificationSettings settings) async {
    if (settings.scheduleTime == null ||
        settings.scheduleTime!.isBefore(DateTime.now().add(const Duration(minutes: 1)))) {
      debugPrint('NotificationService: Invalid schedule time for notification');
      return;
    }

    if (settings.isDaily) {
      debugPrint('NotificationService: Scheduling daily notification for ${TimeOfDay.fromDateTime(settings.scheduleTime!)}');
      await _scheduleDailyNotification(settings);
    } else {
      debugPrint('NotificationService: Scheduling one-time notification for ${settings.scheduleTime}');
      await _scheduleOneTimeSingleNotification(settings);
    }
  }

  Future<void> _scheduleOneTimeSingleNotification(NotificationSettings settings) async {

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'softbrake_reminders',
      'Soft Brake Reminders',
      channelDescription: 'Gentle reminders to apply the brake',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
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

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        0,
        settings.title,
        settings.body,
        tz.TZDateTime.from(settings.scheduleTime!, tz.local),
        platformChannelSpecifics,
        payload: 'one_time_reminder',
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      debugPrint('NotificationService: One-time notification scheduled successfully');
    } catch (e) {
      debugPrint('NotificationService: Failed to schedule one-time notification: $e');
    }
  }

  Future<void> _scheduleCountdownNotification(NotificationSettings settings) async {
    if (settings.countdownDuration == null) {
      debugPrint('NotificationService: No countdown duration specified');
      return;
    }

    final scheduledTime = DateTime.now().add(settings.countdownDuration!);
    debugPrint('NotificationService: Scheduling countdown notification for $scheduledTime (${settings.countdownDuration!.inMinutes} minutes from now)');

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'softbrake_reminders',
      'Soft Brake Reminders',
      channelDescription: 'Gentle reminders to apply the brake',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
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

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        1,
        settings.title,
        settings.body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        platformChannelSpecifics,
        payload: 'countdown_reminder',
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      debugPrint('NotificationService: Countdown notification scheduled successfully');
    } catch (e) {
      debugPrint('NotificationService: Failed to schedule countdown notification: $e');
    }
  }

  Future<void> _scheduleDailyNotification(NotificationSettings settings) async {

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'softbrake_reminders',
      'Soft Brake Reminders',
      channelDescription: 'Gentle reminders to apply the brake',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
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

    // Schedule daily notification starting from the selected time
    final now = DateTime.now();
    final timeOfDay = TimeOfDay.fromDateTime(settings.scheduleTime!);
    DateTime scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );

    // If the time has already passed today, start tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        100, // ID for daily notification
        settings.title,
        settings.body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        platformChannelSpecifics,
        payload: 'daily_reminder',
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint('NotificationService: Daily notification scheduled successfully for ${timeOfDay.hour.toString().padLeft(2, '0')}:${timeOfDay.minute.toString().padLeft(2, '0')}');
    } catch (e) {
      debugPrint('NotificationService: Failed to schedule daily notification: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }

  Future<bool> hasRequiredPermissions() async {
    if (Platform.isAndroid) {
      final androidImplementation = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation == null) return false;

      // Check if we can schedule exact notifications (includes both notification and exact alarm permissions)
      final canScheduleExact = await androidImplementation.canScheduleExactNotifications() ?? false;
      return canScheduleExact;
    }
    return true; // iOS/macOS permissions are handled differently
  }

  Future<void> requestPermissions() async {
    await _requestPermissions();
  }
}