import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:softbrake/main.dart';

void main() {
  group('SlowDown App Tests', () {
    testWidgets('App displays "slow down" text initially', (WidgetTester tester) async {
      await tester.pumpWidget(const SoftBrakeApp());
      
      expect(find.text('slow down'), findsAtLeastNWidgets(1));
      expect(find.byType(SoftBrakeScreen), findsOneWidget);
    });

    testWidgets('App has black background', (WidgetTester tester) async {
      await tester.pumpWidget(const SoftBrakeApp());
      
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(Colors.black));
    });

    testWidgets('Hamburger menu button is present with reduced opacity', (WidgetTester tester) async {
      await tester.pumpWidget(const SoftBrakeApp());
      
      final menuButton = find.byIcon(Icons.menu);
      expect(menuButton, findsOneWidget);
      
      final opacityWidget = tester.widget<Opacity>(
        find.ancestor(of: menuButton, matching: find.byType(Opacity))
      );
      expect(opacityWidget.opacity, equals(0.8));
    });

    testWidgets('Text opacity starts at 100%', (WidgetTester tester) async {
      await tester.pumpWidget(const SoftBrakeApp());
      
      final textWidgets = find.text('slow down');
      expect(textWidgets, findsAtLeastNWidgets(1));
      
      final opacityWidgets = find.byType(Opacity);
      bool foundFullOpacity = false;
      for (final widget in tester.widgetList<Opacity>(opacityWidgets)) {
        if (widget.opacity == 1.0) {
          foundFullOpacity = true;
          break;
        }
      }
      expect(foundFullOpacity, isTrue);
    });

    testWidgets('Menu items exist with icons and configure grouping', (WidgetTester tester) async {
      await tester.pumpWidget(const SoftBrakeApp());

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Check that menu items exist
      expect(find.text('Text'), findsOneWidget);
      expect(find.text('Background'), findsOneWidget);
      expect(find.text('Speed'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);

      // Check that Configure heading exists
      expect(find.text('Configure'), findsOneWidget);

      // Check that icons are present
      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.byIcon(Icons.text_fields), findsOneWidget);
      expect(find.byIcon(Icons.image), findsOneWidget);
      expect(find.byIcon(Icons.speed), findsOneWidget);
      expect(find.byIcon(Icons.notifications), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('Menu icons have proper accessibility support', (WidgetTester tester) async {
      await tester.pumpWidget(const SoftBrakeApp());

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Check that icons exist with semantic properties for assistive technologies
      // Verify all required icons are present in the menu
      final settingsIcon = find.byIcon(Icons.settings);
      final textFieldsIcon = find.byIcon(Icons.text_fields);
      final imageIcon = find.byIcon(Icons.image);
      final speedIcon = find.byIcon(Icons.speed);
      final notificationsIcon = find.byIcon(Icons.notifications);
      final infoIcon = find.byIcon(Icons.info_outline);

      expect(settingsIcon, findsOneWidget);
      expect(textFieldsIcon, findsOneWidget);
      expect(imageIcon, findsOneWidget);
      expect(speedIcon, findsOneWidget);
      expect(notificationsIcon, findsOneWidget);
      expect(infoIcon, findsOneWidget);

      // Verify icons have semantic labels by checking widget properties
      final settingsIconWidget = tester.widget<Icon>(settingsIcon);
      final textFieldsIconWidget = tester.widget<Icon>(textFieldsIcon);
      final imageIconWidget = tester.widget<Icon>(imageIcon);
      final speedIconWidget = tester.widget<Icon>(speedIcon);
      final notificationsIconWidget = tester.widget<Icon>(notificationsIcon);
      final infoIconWidget = tester.widget<Icon>(infoIcon);

      expect(settingsIconWidget.semanticLabel, equals('Configure settings'));
      expect(textFieldsIconWidget.semanticLabel, equals('Text settings'));
      expect(imageIconWidget.semanticLabel, equals('Background settings'));
      expect(speedIconWidget.semanticLabel, equals('Speed settings'));
      expect(notificationsIconWidget.semanticLabel, equals('Notification settings'));
      expect(infoIconWidget.semanticLabel, equals('About information'));
    });

    testWidgets('Reset button exists', (WidgetTester tester) async {
      await tester.pumpWidget(const SoftBrakeApp());

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('About dialog shows copyright information', (WidgetTester tester) async {
      await tester.pumpWidget(const SoftBrakeApp());
      
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('About'));
      await tester.pumpAndSettle();
      
      expect(find.text('© Accelerated Intensity Ltd 2025'), findsOneWidget);
      expect(find.text('https://accelerated-intensity.io'), findsOneWidget);
    });

    testWidgets('About dialog shows version number', (WidgetTester tester) async {
      await tester.pumpWidget(const SoftBrakeApp());
      
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('About'));
      await tester.pumpAndSettle();
      
      // Wait for FutureBuilder to complete
      await tester.pump();
      
      expect(find.text('v0.0.1'), findsOneWidget);
    });

    testWidgets('About dialog shows app name and logo', (WidgetTester tester) async {
      await tester.pumpWidget(const SoftBrakeApp());
      
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('About'));
      await tester.pumpAndSettle();
      
      // Wait for FutureBuilder to complete
      await tester.pump();
      
      expect(find.text('slow down'), findsAtLeastNWidgets(1));
      expect(find.byType(Opacity), findsAtLeastNWidgets(1));
    });

    testWidgets('Reset functionality works', (WidgetTester tester) async {
      await tester.pumpWidget(const SoftBrakeApp());

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      final textWidgets = find.text('slow down');
      expect(textWidgets, findsAtLeastNWidgets(1));

      final opacityWidgets = find.byType(Opacity);
      bool foundFullOpacity = false;
      for (final widget in tester.widgetList<Opacity>(opacityWidgets)) {
        if (widget.opacity == 1.0) {
          foundFullOpacity = true;
          break;
        }
      }
      expect(foundFullOpacity, isTrue);
    });

    testWidgets('App theme is dark with black background', (WidgetTester tester) async {
      await tester.pumpWidget(const SoftBrakeApp());
      
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme?.scaffoldBackgroundColor, equals(Colors.black));
      expect(materialApp.title, equals('soft brake'));
    });

    testWidgets('Text uses correct styling', (WidgetTester tester) async {
      await tester.pumpWidget(const SoftBrakeApp());

      final textWidgets = find.text('slow down');
      expect(textWidgets, findsAtLeastNWidgets(1));

      final firstTextWidget = tester.widgetList<Text>(textWidgets).first;
      expect(firstTextWidget.style?.fontSize, equals(32));
      expect(firstTextWidget.style?.fontFamily, equals('sans-serif'));
      expect(firstTextWidget.style?.fontWeight, equals(FontWeight.normal));
    });

    testWidgets('App has proper screen coverage', (WidgetTester tester) async {
      await tester.pumpWidget(const SoftBrakeApp());

      final scaffold = find.byType(Scaffold);
      expect(scaffold, findsOneWidget);

      final animatedContainers = find.byType(AnimatedContainer);
      expect(animatedContainers, findsWidgets);
    });
  });

  group('SlowDownScreen Integration Tests', () {
    testWidgets('Text is present and centered', (WidgetTester tester) async {
      await tester.pumpWidget(const SoftBrakeApp());
      
      final textWidgets = find.text('slow down');
      expect(textWidgets, findsAtLeastNWidgets(1));
      
      final centerWidgets = find.byType(Center);
      expect(centerWidgets, findsWidgets);
      
      bool textIsInCenter = false;
      final centerList = tester.widgetList<Center>(centerWidgets).toList();
      for (int i = 0; i < centerList.length; i++) {
        final center = centerWidgets.at(i);
        final textInCenter = find.descendant(
          of: center,
          matching: find.text('slow down'),
        );
        if (tester.any(textInCenter)) {
          textIsInCenter = true;
          break;
        }
      }
      expect(textIsInCenter, isTrue);
    });
  });
}