import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:softbrake/config/notification_config.dart';
import 'package:softbrake/services/notification_service.dart';

void main() {
  group('NotificationConfigDialog Tests', () {
    testWidgets('Dialog displays notification settings', (WidgetTester tester) async {
      const initialPreferences = NotificationPreferences(
        isEnabled: true,
        mode: NotificationMode.scheduledTime,
        scheduledTime: TimeOfDay(hour: 21, minute: 0),
        isRecurring: true,
        title: 'Test Title',
        body: 'Test Body',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => NotificationConfigDialog(
                      initialPreferences: initialPreferences,
                      onSave: (preferences) {},
                      onDefaults: () {},
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Notification Settings'), findsOneWidget);
      expect(find.text('Enable Notifications'), findsOneWidget);
      expect(find.text('Notification Mode'), findsOneWidget);
      expect(find.text('Scheduled Time'), findsOneWidget);
      expect(find.text('Countdown'), findsOneWidget);
      expect(find.byType(Switch), findsWidgets);
    });

    testWidgets('Enable/disable toggle works correctly', (WidgetTester tester) async {
      const initialPreferences = NotificationPreferences(isEnabled: false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => NotificationConfigDialog(
                      initialPreferences: initialPreferences,
                      onSave: (preferences) {},
                      onDefaults: () {},
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Find the enable switch and verify it's initially off
      final enableSwitch = find.byType(Switch).first;
      expect(tester.widget<Switch>(enableSwitch).value, false);

      // Tap the switch to enable
      await tester.tap(enableSwitch);
      await tester.pumpAndSettle();

      // Verify additional options appear when enabled
      expect(find.text('Notification Mode'), findsOneWidget);
    });

    testWidgets('Mode selection between scheduled time and countdown works', (WidgetTester tester) async {
      const initialPreferences = NotificationPreferences(
        isEnabled: true,
        mode: NotificationMode.scheduledTime,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => NotificationConfigDialog(
                      initialPreferences: initialPreferences,
                      onSave: (preferences) {},
                      onDefaults: () {},
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Find scheduled time radio button (should be selected)
      final scheduledRadio = find.byWidgetPredicate(
        (widget) => widget is Radio<NotificationMode> &&
                     widget.value == NotificationMode.scheduledTime,
      );
      final countdownRadio = find.byWidgetPredicate(
        (widget) => widget is Radio<NotificationMode> &&
                     widget.value == NotificationMode.countdown,
      );

      expect(scheduledRadio, findsOneWidget);
      expect(countdownRadio, findsOneWidget);

      // Tap countdown mode
      await tester.tap(countdownRadio);
      await tester.pumpAndSettle();

      // Should now show countdown options
      expect(find.text('Countdown Interval'), findsOneWidget);
      expect(find.text('10 minutes'), findsOneWidget);
      expect(find.text('30 minutes'), findsOneWidget);
      expect(find.text('1 hour'), findsOneWidget);
      expect(find.text('2 hours'), findsOneWidget);
      expect(find.text('Custom duration'), findsOneWidget);
    });

    testWidgets('Time picker works for scheduled time mode', (WidgetTester tester) async {
      const initialPreferences = NotificationPreferences(
        isEnabled: true,
        mode: NotificationMode.scheduledTime,
        scheduledTime: TimeOfDay(hour: 9, minute: 0),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => NotificationConfigDialog(
                      initialPreferences: initialPreferences,
                      onSave: (preferences) {},
                      onDefaults: () {},
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Should display the initial time
      expect(find.text('9:00 AM'), findsOneWidget);

      // Should have a time selection interface
      expect(find.text('Time'), findsOneWidget);
      expect(find.text('Daily Recurring'), findsOneWidget);
    });

    testWidgets('Custom countdown duration input works', (WidgetTester tester) async {
      const initialPreferences = NotificationPreferences(
        isEnabled: true,
        mode: NotificationMode.countdown,
        countdownInterval: CountdownInterval.custom,
        customMinutes: 45,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => NotificationConfigDialog(
                      initialPreferences: initialPreferences,
                      onSave: (preferences) {},
                      onDefaults: () {},
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Should show custom duration input
      expect(find.text('Minutes: '), findsOneWidget);

      // Find text fields and verify we have the custom minutes field
      final textFields = find.byType(TextField);
      expect(textFields, findsWidgets);

      // There should be at least 3 text fields (title, body, custom minutes)
      expect(tester.widgetList(textFields).length, greaterThanOrEqualTo(3));
    });

    testWidgets('Save button triggers onSave callback with correct preferences', (WidgetTester tester) async {
      const initialPreferences = NotificationPreferences(
        isEnabled: true,
        mode: NotificationMode.scheduledTime,
        scheduledTime: TimeOfDay(hour: 21, minute: 0),
        isRecurring: true,
      );

      NotificationPreferences? savedPreferences;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => NotificationConfigDialog(
                      initialPreferences: initialPreferences,
                      onSave: (preferences) {
                        savedPreferences = preferences;
                      },
                      onDefaults: () {},
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Make a change to enable the save button (change title text)
      final titleField = find.byType(TextField).first;
      await tester.enterText(titleField, 'Changed Title');
      await tester.pumpAndSettle();

      // Scroll to make sure Save button is visible
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -200));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(savedPreferences, isNotNull);
      expect(savedPreferences!.isEnabled, true);
      expect(savedPreferences!.mode, NotificationMode.scheduledTime);
      expect(savedPreferences!.isRecurring, true);
      expect(savedPreferences!.title, 'Changed Title');
    });

    testWidgets('Cancel button closes dialog without saving', (WidgetTester tester) async {
      bool onSaveCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => NotificationConfigDialog(
                      initialPreferences: const NotificationPreferences(),
                      onSave: (preferences) {
                        onSaveCalled = true;
                      },
                      onDefaults: () {},
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(onSaveCalled, false);
      expect(find.text('Notification Settings'), findsNothing);
    });

    testWidgets('Defaults button triggers onDefaults callback', (WidgetTester tester) async {
      bool onDefaultsCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => NotificationConfigDialog(
                      initialPreferences: const NotificationPreferences(),
                      onSave: (preferences) {},
                      onDefaults: () {
                        onDefaultsCalled = true;
                      },
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Defaults'));
      await tester.pumpAndSettle();

      expect(onDefaultsCalled, true);
      expect(find.text('Notification Settings'), findsNothing);
    });

    testWidgets('Custom message fields work correctly', (WidgetTester tester) async {
      const initialPreferences = NotificationPreferences(
        isEnabled: true,
        title: 'Custom Title',
        body: 'Custom Body Message',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => NotificationConfigDialog(
                      initialPreferences: initialPreferences,
                      onSave: (preferences) {},
                      onDefaults: () {},
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Notification Message'), findsOneWidget);

      // Find text fields by type - there should be at least 2 text fields for title and body
      final textFields = find.byType(TextField);
      expect(textFields, findsWidgets);

      // Verify we have at least 2 text fields (title and body)
      expect(tester.widgetList(textFields).length, greaterThanOrEqualTo(2));
    });

    testWidgets('Next notification info displays correctly for scheduled time', (WidgetTester tester) async {
      const initialPreferences = NotificationPreferences(
        isEnabled: true,
        mode: NotificationMode.scheduledTime,
        scheduledTime: TimeOfDay(hour: 21, minute: 0),
        isRecurring: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => NotificationConfigDialog(
                      initialPreferences: initialPreferences,
                      onSave: (preferences) {},
                      onDefaults: () {},
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Should show next notification info
      expect(find.textContaining('Next:'), findsOneWidget);
      expect(find.textContaining('Daily at'), findsOneWidget);
    });

    testWidgets('Dialog has proper styling', (WidgetTester tester) async {
      const initialPreferences = NotificationPreferences();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => NotificationConfigDialog(
                      initialPreferences: initialPreferences,
                      onSave: (preferences) {},
                      onDefaults: () {},
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final dialog = find.byType(Dialog);
      expect(dialog, findsOneWidget);

      final dialogWidget = tester.widget<Dialog>(dialog);
      expect(dialogWidget.backgroundColor, equals(Colors.black));
    });
  });

  group('NotificationPreferences Tests', () {
    test('toJson and fromJson work correctly', () {
      const preferences = NotificationPreferences(
        isEnabled: true,
        mode: NotificationMode.countdown,
        scheduledTime: TimeOfDay(hour: 15, minute: 30),
        isRecurring: false,
        countdownInterval: CountdownInterval.oneHour,
        customMinutes: 90,
        title: 'Test Title',
        body: 'Test Body',
      );

      final json = preferences.toJson();
      final restored = NotificationPreferences.fromJson(json);

      expect(restored.isEnabled, preferences.isEnabled);
      expect(restored.mode, preferences.mode);
      expect(restored.scheduledTime?.hour, preferences.scheduledTime?.hour);
      expect(restored.scheduledTime?.minute, preferences.scheduledTime?.minute);
      expect(restored.isRecurring, preferences.isRecurring);
      expect(restored.countdownInterval, preferences.countdownInterval);
      expect(restored.customMinutes, preferences.customMinutes);
      expect(restored.title, preferences.title);
      expect(restored.body, preferences.body);
    });

    test('copyWith works correctly', () {
      const original = NotificationPreferences(
        isEnabled: false,
        mode: NotificationMode.scheduledTime,
        title: 'Original Title',
      );

      final updated = original.copyWith(
        isEnabled: true,
        title: 'Updated Title',
      );

      expect(updated.isEnabled, true);
      expect(updated.mode, NotificationMode.scheduledTime); // unchanged
      expect(updated.title, 'Updated Title');
    });

    test('default values are correct', () {
      const preferences = NotificationPreferences();

      expect(preferences.isEnabled, false);
      expect(preferences.mode, NotificationMode.scheduledTime);
      expect(preferences.scheduledTime, isNull);
      expect(preferences.isRecurring, false);
      expect(preferences.countdownInterval, isNull);
      expect(preferences.customMinutes, isNull);
      expect(preferences.title, 'A Gentle Reminder');
      expect(preferences.body, 'Is it time to apply a soft brake?');
      expect(preferences.nextNotificationTime, isNull);
    });
  });
}