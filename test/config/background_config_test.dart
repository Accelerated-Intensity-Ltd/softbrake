import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:softbrake/config/background_config.dart';

void main() {
  group('BackgroundConfigDialog Tests', () {
    testWidgets('Dialog displays background settings', (WidgetTester tester) async {
      const Color initialBgColor = Colors.red;
      const Color initialTextColor = Colors.blue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => BackgroundConfigDialog(
                      initialBackgroundColor: initialBgColor,
                      initialImagePath: null,
                      initialTextColor: initialTextColor,
                      initialBackgroundType: BackgroundType.color,
                      onSave: (bgColor, imagePath, textColor, backgroundType) {},
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

      expect(find.text('Background Settings'), findsOneWidget);
      expect(find.text('Background Type'), findsOneWidget);
      expect(find.text('Color'), findsOneWidget);
      expect(find.text('Image'), findsOneWidget);
      expect(find.text('Text Color'), findsOneWidget);
      expect(find.byType(Radio<BackgroundType>), findsNWidgets(2));
    });

    testWidgets('Save button triggers onSave callback with background settings', (WidgetTester tester) async {
      const Color initialBgColor = Colors.red;
      const Color initialTextColor = Colors.blue;
      Color? savedBgColor;
      String? savedImagePath;
      Color? savedTextColor;
      BackgroundType? savedBackgroundType;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => BackgroundConfigDialog(
                      initialBackgroundColor: initialBgColor,
                      initialImagePath: null,
                      initialTextColor: initialTextColor,
                      initialBackgroundType: BackgroundType.color,
                      onSave: (bgColor, imagePath, textColor, backgroundType) {
                        savedBgColor = bgColor;
                        savedImagePath = imagePath;
                        savedTextColor = textColor;
                        savedBackgroundType = backgroundType;
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

      // Make a change to enable the save button (change to image type)
      final imageRadio = find.byWidgetPredicate(
        (widget) => widget is Radio<BackgroundType> && widget.value == BackgroundType.image,
      );
      await tester.tap(imageRadio);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(savedBgColor, isNull); // Should be null for image type
      expect(savedImagePath, isNull); // No image selected
      expect(savedTextColor, equals(initialTextColor));
      expect(savedBackgroundType, equals(BackgroundType.image));
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
                    builder: (_) => BackgroundConfigDialog(
                      initialBackgroundColor: Colors.black,
                      initialImagePath: null,
                      initialTextColor: Colors.white,
                      initialBackgroundType: BackgroundType.color,
                      onSave: (bgColor, imagePath, textColor, backgroundType) {
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
      expect(find.text('Background Settings'), findsNothing);
    });

    testWidgets('Background type can be changed between color and image', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => BackgroundConfigDialog(
                      initialBackgroundColor: Colors.black,
                      initialImagePath: null,
                      initialTextColor: Colors.white,
                      initialBackgroundType: BackgroundType.color,
                      onSave: (bgColor, imagePath, textColor, backgroundType) {},
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

      // Find the radio buttons
      final colorRadio = find.byWidgetPredicate(
        (widget) => widget is Radio<BackgroundType> && widget.value == BackgroundType.color,
      );
      final imageRadio = find.byWidgetPredicate(
        (widget) => widget is Radio<BackgroundType> && widget.value == BackgroundType.image,
      );

      expect(colorRadio, findsOneWidget);
      expect(imageRadio, findsOneWidget);

      // Test switching to image type
      await tester.tap(imageRadio);
      await tester.pumpAndSettle();

      // Should now show image-related UI elements
      expect(find.text('Background Image'), findsOneWidget);
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
                    builder: (_) => BackgroundConfigDialog(
                      initialBackgroundColor: Colors.black,
                      initialImagePath: null,
                      initialTextColor: Colors.white,
                      initialBackgroundType: BackgroundType.color,
                      onSave: (bgColor, imagePath, textColor, backgroundType) {},
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
                    builder: (_) => BackgroundConfigDialog(
                      initialBackgroundColor: Colors.black,
                      initialImagePath: null,
                      initialTextColor: Colors.white,
                      initialBackgroundType: BackgroundType.color,
                      onSave: (bgColor, imagePath, textColor, backgroundType) {},
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
      expect(find.text('Background Settings'), findsNothing);
    });
  });
}