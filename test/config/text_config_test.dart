import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:softbrake/config/text_config.dart';

void main() {
  group('TextConfigDialog Tests', () {
    testWidgets('Dialog displays initial text and color', (WidgetTester tester) async {
      const String initialText = 'test text';
      const Color initialColor = Colors.red;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => TextConfigDialog(
                      initialText: initialText,
                      initialTextColor: initialColor,
                      onSave: (text, color) {},
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

      expect(find.text('Text Settings'), findsOneWidget);
      expect(find.text('Custom Text'), findsOneWidget);
      expect(find.text('Text Color'), findsOneWidget);

      // Check that text field contains initial text
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      final textFieldWidget = tester.widget<TextField>(textField);
      expect(textFieldWidget.controller?.text, equals(initialText));
    });

    testWidgets('Save button triggers onSave callback', (WidgetTester tester) async {
      String savedText = '';
      Color savedColor = Colors.transparent;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => TextConfigDialog(
                      initialText: 'initial',
                      initialTextColor: Colors.white,
                      onSave: (text, color) {
                        savedText = text;
                        savedColor = color;
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

      // Make a change to enable the save button
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'changed text');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(savedText, equals('changed text'));
      expect(savedColor, equals(Colors.white));
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
                    builder: (_) => TextConfigDialog(
                      initialText: 'test',
                      initialTextColor: Colors.white,
                      onSave: (text, color) {
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
      expect(find.text('Text Settings'), findsNothing);
    });

    testWidgets('Text field allows editing', (WidgetTester tester) async {
      String savedText = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => TextConfigDialog(
                      initialText: 'initial',
                      initialTextColor: Colors.white,
                      onSave: (text, color) {
                        savedText = text;
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

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'new text');
      await tester.pumpAndSettle(); // Need this to trigger state change

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(savedText, equals('new text'));
    });

    testWidgets('Empty text defaults to "slow down"', (WidgetTester tester) async {
      String savedText = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => TextConfigDialog(
                      initialText: 'test',
                      initialTextColor: Colors.white,
                      onSave: (text, color) {
                        savedText = text;
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

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'some change'); // Make a change first
      await tester.pumpAndSettle();
      await tester.enterText(textField, '   '); // Now enter only whitespace
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(savedText, equals('slow down'));
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
                    builder: (_) => TextConfigDialog(
                      initialText: 'test',
                      initialTextColor: Colors.white,
                      onSave: (text, color) {},
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
      expect(find.text('Text Settings'), findsNothing);
    });
  });
}