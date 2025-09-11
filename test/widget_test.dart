import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:soft_brake/main.dart';

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
      expect(opacityWidget.opacity, equals(0.2));
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

    testWidgets('Reset menu item exists', (WidgetTester tester) async {
      await tester.pumpWidget(const SoftBrakeApp());
      
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      
      expect(find.text('Reset'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
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
      
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Reset'));
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
      expect(firstTextWidget.style?.color, equals(Colors.white));
      expect(firstTextWidget.style?.fontSize, equals(32));
      expect(firstTextWidget.style?.fontFamily, equals('sans-serif'));
      expect(firstTextWidget.style?.fontWeight, equals(FontWeight.normal));
    });

    testWidgets('Main container covers entire screen', (WidgetTester tester) async {
      await tester.pumpWidget(const SoftBrakeApp());
      
      final containers = find.byType(Container);
      expect(containers, findsWidgets);
      
      bool foundFullScreenContainer = false;
      final containerList = tester.widgetList<Container>(containers).toList();
      for (int i = 0; i < containerList.length; i++) {
        final container = containerList[i];
        if (container.color == Colors.black) {
          foundFullScreenContainer = true;
          break;
        }
      }
      expect(foundFullScreenContainer, isTrue);
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