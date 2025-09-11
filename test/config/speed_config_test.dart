import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:softbrake/config/speed_config.dart';

void main() {
  group('SpeedConfigDialog Tests', () {
    testWidgets('Dialog displays speed settings', (WidgetTester tester) async {
      const int initialDuration = 500;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => SpeedConfigDialog(
                      initialDuration: initialDuration,
                      onSave: (duration) {},
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

      expect(find.text('Speed Settings'), findsOneWidget);
      expect(find.text('Deceleration'), findsOneWidget);
      expect(find.text('${initialDuration}ms'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('Slider shows correct initial value', (WidgetTester tester) async {
      const int initialDuration = 300;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => SpeedConfigDialog(
                      initialDuration: initialDuration,
                      onSave: (duration) {},
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

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.value, equals(initialDuration.toDouble()));
    });

    testWidgets('Save button triggers onSave callback with duration', (WidgetTester tester) async {
      const int initialDuration = 200;
      int savedDuration = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => SpeedConfigDialog(
                      initialDuration: initialDuration,
                      onSave: (duration) {
                        savedDuration = duration;
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

      // Change the slider value to enable save button
      final slider = find.byType(Slider);
      await tester.drag(slider, const Offset(50, 0)); // Drag slider to change value
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(savedDuration, isNot(equals(initialDuration))); // Should be different now
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
                    builder: (_) => SpeedConfigDialog(
                      initialDuration: 100,
                      onSave: (duration) {
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

      expect(onSaveCalled, isFalse);
      expect(find.text('Speed Settings'), findsNothing);
    });

    testWidgets('Slider respects min and max values', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => SpeedConfigDialog(
                      initialDuration: 500,
                      onSave: (duration) {},
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

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.min, equals(100.0));
      expect(slider.max, equals(1000.0));
      expect(slider.divisions, equals(18));
    });

    testWidgets('Duration value updates when slider changes', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => SpeedConfigDialog(
                      initialDuration: 100,
                      onSave: (duration) {},
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

      // Initial value should be 100ms
      expect(find.text('100ms'), findsOneWidget);

      // Drag slider to a different position
      final slider = find.byType(Slider);
      await tester.drag(slider, const Offset(100, 0));
      await tester.pumpAndSettle();

      // Value should have changed (exact value depends on drag distance)
      expect(find.text('100ms'), findsNothing);
    });

    testWidgets('Dialog has proper styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => SpeedConfigDialog(
                      initialDuration: 100,
                      onSave: (duration) {},
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
                    builder: (_) => SpeedConfigDialog(
                      initialDuration: 100,
                      onSave: (duration) {},
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

      expect(onDefaultsCalled, isTrue);
      expect(find.text('Speed Settings'), findsNothing);
    });
  });
}