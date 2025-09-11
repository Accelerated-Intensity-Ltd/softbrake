import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

enum NotificationMode { scheduledTime, countdown }

enum CountdownInterval {
  tenMinutes,
  thirtyMinutes,
  oneHour,
  twoHours,
  custom
}

class NotificationPreferences {
  final bool isEnabled;
  final NotificationMode mode;
  final TimeOfDay? scheduledTime;
  final bool isRecurring;
  final CountdownInterval? countdownInterval;
  final int? customMinutes;
  final String title;
  final String body;
  final DateTime? nextNotificationTime;

  const NotificationPreferences({
    this.isEnabled = false,
    this.mode = NotificationMode.scheduledTime,
    this.scheduledTime,
    this.isRecurring = false,
    this.countdownInterval,
    this.customMinutes,
    this.title = 'A Gentle Reminder',
    this.body = 'Is it time to apply a soft brake?',
    this.nextNotificationTime,
  });

  NotificationPreferences copyWith({
    bool? isEnabled,
    NotificationMode? mode,
    TimeOfDay? scheduledTime,
    bool? isRecurring,
    CountdownInterval? countdownInterval,
    int? customMinutes,
    String? title,
    String? body,
    DateTime? nextNotificationTime,
  }) {
    return NotificationPreferences(
      isEnabled: isEnabled ?? this.isEnabled,
      mode: mode ?? this.mode,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isRecurring: isRecurring ?? this.isRecurring,
      countdownInterval: countdownInterval ?? this.countdownInterval,
      customMinutes: customMinutes ?? this.customMinutes,
      title: title ?? this.title,
      body: body ?? this.body,
      nextNotificationTime: nextNotificationTime ?? this.nextNotificationTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'mode': mode.index,
      'scheduledTimeHour': scheduledTime?.hour,
      'scheduledTimeMinute': scheduledTime?.minute,
      'isRecurring': isRecurring,
      'countdownInterval': countdownInterval?.index,
      'customMinutes': customMinutes,
      'title': title,
      'body': body,
      'nextNotificationTime': nextNotificationTime?.millisecondsSinceEpoch,
    };
  }

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    TimeOfDay? scheduledTime;
    if (json['scheduledTimeHour'] != null && json['scheduledTimeMinute'] != null) {
      scheduledTime = TimeOfDay(
        hour: json['scheduledTimeHour'] as int,
        minute: json['scheduledTimeMinute'] as int,
      );
    }

    DateTime? nextNotificationTime;
    if (json['nextNotificationTime'] != null) {
      nextNotificationTime = DateTime.fromMillisecondsSinceEpoch(
        json['nextNotificationTime'] as int,
      );
    }

    return NotificationPreferences(
      isEnabled: json['isEnabled'] as bool? ?? false,
      mode: NotificationMode.values[json['mode'] as int? ?? 0],
      scheduledTime: scheduledTime,
      isRecurring: json['isRecurring'] as bool? ?? false,
      countdownInterval: json['countdownInterval'] != null
          ? CountdownInterval.values[json['countdownInterval'] as int]
          : null,
      customMinutes: json['customMinutes'] as int?,
      title: json['title'] as String? ?? 'A Gentle Reminder',
      body: json['body'] as String? ?? 'Is it time to apply a soft brake?',
      nextNotificationTime: nextNotificationTime,
    );
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const int _notificationId = 1;
  static const String _prefsKey = 'notification_preferences';

  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  NotificationPreferences _currentPreferences = const NotificationPreferences();

  NotificationPreferences get currentPreferences => _currentPreferences;

  /// Initialize the notification service
  /// This should be called during app startup
  Future<bool> initialize() async {
    try {
      // Initialize timezone data
      tz.initializeTimeZones();

      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

      // Android initialization settings
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
        macOS: initializationSettingsDarwin,
      );

      final bool? initialized = await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (initialized == true) {
        await _loadPreferences();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
      return false;
    }
  }

  /// Handle notification tap events
  void _onNotificationTapped(NotificationResponse notificationResponse) {
    debugPrint('Notification tapped: ${notificationResponse.payload}');
    // Handle notification tap - could open app to specific screen
    // For now, we'll just log it
  }

  /// Request notification permissions (iOS/Android 13+)
  Future<bool> requestPermissions() async {
    bool permissionsGranted = false;

    if (Platform.isIOS || Platform.isMacOS) {
      permissionsGranted = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ?? false;
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      // Request basic notification permission
      permissionsGranted = await androidImplementation?.requestNotificationsPermission() ?? false;

      // Request exact alarm permission for Android 12+ (API level 31+)
      if (permissionsGranted) {
        try {
          await androidImplementation?.requestExactAlarmsPermission();
        } catch (e) {
          debugPrint('Error requesting exact alarm permission: $e');
          // Continue with basic notifications even if exact alarms aren't available
        }
      }
    }

    return permissionsGranted;
  }

  /// Check if notification permissions are granted
  Future<bool> arePermissionsGranted() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await androidImplementation?.areNotificationsEnabled() ?? false;
    }
    // For iOS, we assume permissions are granted if we can schedule
    return true;
  }

  /// Check if exact alarms are available on Android
  Future<bool> _canScheduleExactAlarms() async {
    if (Platform.isAndroid) {
      try {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        return await androidImplementation?.canScheduleExactNotifications() ?? false;
      } catch (e) {
        return false;
      }
    }
    return true; // iOS/macOS always support exact scheduling
  }

  /// Get appropriate Android schedule mode based on exact alarm availability
  Future<AndroidScheduleMode> _getAndroidScheduleMode() async {
    if (await _canScheduleExactAlarms()) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    } else {
      // Use alarmClock for better reliability when exact alarms aren't available
      // This will show in the user's alarm app but is more reliable
      return AndroidScheduleMode.alarmClock;
    }
  }

  /// Save notification preferences to SharedPreferences
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = _currentPreferences.toJson();
      await prefs.setString(_prefsKey, jsonString.toString());
    } catch (e) {
      debugPrint('Error saving notification preferences: $e');
    }
  }

  /// Load notification preferences from SharedPreferences
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefsKey);
      if (jsonString != null) {
        // Parse the JSON string back to Map
        final Map<String, dynamic> jsonMap = {};
        final cleanJson = jsonString.replaceAll('{', '').replaceAll('}', '');
        final pairs = cleanJson.split(', ');

        for (final pair in pairs) {
          final keyValue = pair.split(': ');
          if (keyValue.length == 2) {
            final key = keyValue[0];
            final value = keyValue[1];

            // Parse different types based on known keys
            if (key == 'isEnabled' || key == 'isRecurring') {
              jsonMap[key] = value == 'true';
            } else if (key == 'mode' || key == 'countdownInterval' ||
                       key == 'scheduledTimeHour' || key == 'scheduledTimeMinute' ||
                       key == 'customMinutes' || key == 'nextNotificationTime') {
              jsonMap[key] = value == 'null' ? null : int.tryParse(value);
            } else {
              jsonMap[key] = value == 'null' ? null : value;
            }
          }
        }

        _currentPreferences = NotificationPreferences.fromJson(jsonMap);

        // Reschedule if there was an active notification
        if (_currentPreferences.isEnabled) {
          await _scheduleNotificationFromPreferences();
        }
      }
    } catch (e) {
      debugPrint('Error loading notification preferences: $e');
    }
  }

  /// Update notification preferences and reschedule if needed
  Future<bool> updatePreferences(NotificationPreferences preferences) async {
    try {
      _currentPreferences = preferences;
      await _savePreferences();

      // Cancel existing notifications
      await cancelAllNotifications();

      // Schedule new notification if enabled
      if (preferences.isEnabled) {
        return await _scheduleNotificationFromPreferences();
      }
      return true;
    } catch (e) {
      debugPrint('Error updating notification preferences: $e');
      return false;
    }
  }

  /// Schedule notification based on current preferences
  Future<bool> _scheduleNotificationFromPreferences() async {
    final prefs = _currentPreferences;

    if (prefs.mode == NotificationMode.scheduledTime && prefs.scheduledTime != null) {
      return await _scheduleAtTime(
        prefs.scheduledTime!,
        prefs.isRecurring,
        prefs.title,
        prefs.body,
      );
    } else if (prefs.mode == NotificationMode.countdown) {
      final minutes = _getCountdownMinutes(prefs.countdownInterval, prefs.customMinutes);
      if (minutes > 0) {
        return await _scheduleCountdown(minutes, prefs.title, prefs.body);
      }
    }
    return false;
  }

  /// Get countdown minutes based on interval type
  int _getCountdownMinutes(CountdownInterval? interval, int? customMinutes) {
    switch (interval) {
      case CountdownInterval.tenMinutes:
        return 10;
      case CountdownInterval.thirtyMinutes:
        return 30;
      case CountdownInterval.oneHour:
        return 60;
      case CountdownInterval.twoHours:
        return 120;
      case CountdownInterval.custom:
        return customMinutes ?? 0;
      default:
        return 0;
    }
  }

  /// Schedule a notification at a specific time
  Future<bool> _scheduleAtTime(
    TimeOfDay scheduledTime,
    bool isRecurring,
    String title,
    String body,
  ) async {
    try {
      final now = DateTime.now();
      var scheduledDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        scheduledTime.hour,
        scheduledTime.minute,
      );

      // If the time has passed today, schedule for tomorrow
      if (scheduledDateTime.isBefore(now)) {
        scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
      }

      debugPrint('NotificationService: Scheduling ${isRecurring ? 'recurring' : 'one-time'} notification for $scheduledDateTime');

      final tz.TZDateTime scheduledTZ = tz.TZDateTime(
        tz.local,
        scheduledDateTime.year,
        scheduledDateTime.month,
        scheduledDateTime.day,
        scheduledDateTime.hour,
        scheduledDateTime.minute,
      );

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'screen_time_reminders',
        'Screen Time Reminders',
        channelDescription: 'Notifications to remind about screen time goals',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails();

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
        macOS: iOSPlatformChannelSpecifics,
      );

      final scheduleMode = await _getAndroidScheduleMode();

      if (isRecurring) {
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          _notificationId,
          title,
          body,
          scheduledTZ,
          platformChannelSpecifics,
          androidScheduleMode: scheduleMode,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } else {
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          _notificationId,
          title,
          body,
          scheduledTZ,
          platformChannelSpecifics,
          androidScheduleMode: scheduleMode,
        );
      }

      // Update preferences with next notification time
      _currentPreferences = _currentPreferences.copyWith(
        nextNotificationTime: scheduledDateTime,
      );
      await _savePreferences();

      debugPrint('NotificationService: Notification scheduled successfully for $scheduledDateTime');
      return true;
    } catch (e) {
      debugPrint('Error scheduling notification at time: $e');
      return false;
    }
  }

  /// Schedule a countdown notification
  Future<bool> _scheduleCountdown(int minutes, String title, String body) async {
    try {
      final now = DateTime.now();
      final scheduledDateTime = now.add(Duration(minutes: minutes));
      debugPrint('NotificationService: Scheduling countdown notification for $scheduledDateTime');

      final tz.TZDateTime scheduledTZ = tz.TZDateTime(
        tz.local,
        scheduledDateTime.year,
        scheduledDateTime.month,
        scheduledDateTime.day,
        scheduledDateTime.hour,
        scheduledDateTime.minute,
        scheduledDateTime.second,
      );

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'screen_time_reminders',
        'Screen Time Reminders',
        channelDescription: 'Notifications to remind about screen time goals',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails();

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
        macOS: iOSPlatformChannelSpecifics,
      );

      final scheduleMode = await _getAndroidScheduleMode();

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        _notificationId,
        title,
        body,
        scheduledTZ,
        platformChannelSpecifics,
        androidScheduleMode: scheduleMode,
      );

      // Update preferences with next notification time
      _currentPreferences = _currentPreferences.copyWith(
        nextNotificationTime: scheduledDateTime,
      );
      await _savePreferences();

      debugPrint('NotificationService: Countdown notification scheduled for $scheduledDateTime');
      return true;
    } catch (e) {
      debugPrint('Error scheduling countdown notification: $e');
      return false;
    }
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();

      // Update preferences to remove next notification time
      _currentPreferences = _currentPreferences.copyWith(
        nextNotificationTime: null,
      );
      await _savePreferences();
    } catch (e) {
      debugPrint('Error canceling notifications: $e');
    }
  }

  /// Get formatted next notification time string
  String? getNextNotificationTimeString() {
    final nextTime = _currentPreferences.nextNotificationTime;
    if (nextTime == null) return null;

    final now = DateTime.now();
    final difference = nextTime.difference(now);

    if (difference.isNegative) return null;

    if (difference.inDays > 0) {
      return 'in ${difference.inDays} day${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'in ${difference.inHours} hour${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'in ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'very soon';
    }
  }

  /// Check if there are pending notifications
  Future<bool> hasPendingNotifications() async {
    try {
      final pendingNotifications = await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
      return pendingNotifications.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking pending notifications: $e');
      return false;
    }
  }

}

// Helper extension for TimeOfDay
extension TimeOfDayExtension on TimeOfDay {
  String toFormattedString() {
    final hour = this.hour == 0
        ? 12
        : this.hour > 12
            ? this.hour - 12
            : this.hour;
    final period = this.hour < 12 ? 'AM' : 'PM';
    final minute = this.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}