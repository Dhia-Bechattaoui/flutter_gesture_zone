import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gesture_zone/flutter_gesture_zone.dart';

void main() {
  group('GestureZone Tests', () {
    testWidgets('GestureZone widget can be created', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GestureZone(
            onTap: (result) {},
            child: Container(width: 100, height: 100, color: Colors.blue),
          ),
        ),
      );

      expect(find.byType(GestureZone), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
    });

    testWidgets('GestureZone with controller can be created', (
      WidgetTester tester,
    ) async {
      final controller = GestureZoneController();

      await tester.pumpWidget(
        MaterialApp(
          home: GestureZone(
            controller: controller,
            child: Container(width: 100, height: 100, color: Colors.blue),
          ),
        ),
      );

      expect(find.byType(GestureZone), findsOneWidget);
    });

    testWidgets('GestureZone with custom config can be created', (
      WidgetTester tester,
    ) async {
      final config = GestureConfig.precise();

      await tester.pumpWidget(
        MaterialApp(
          home: GestureZone(
            config: config,
            child: Container(width: 100, height: 100, color: Colors.blue),
          ),
        ),
      );

      expect(find.byType(GestureZone), findsOneWidget);
    });
  });

  group('GestureZoneController Tests', () {
    test('GestureZoneController can be created with default config', () {
      final controller = GestureZoneController();
      expect(controller, isNotNull);
      expect(controller.enabled, isTrue);
      expect(controller.showVisualFeedback, isFalse);
      expect(controller.activeTouchPointCount, equals(0));
    });

    test('GestureZoneController can be created with custom config', () {
      final config = GestureConfig.precise();
      final controller = GestureZoneController(config: config);
      expect(controller, isNotNull);
      expect(controller.config, equals(config));
    });

    test('GestureZoneController can be enabled/disabled', () {
      final controller = GestureZoneController();

      controller.setEnabled(false);
      expect(controller.enabled, isFalse);

      controller.setEnabled(true);
      expect(controller.enabled, isTrue);
    });

    test('GestureZoneController can toggle visual feedback', () {
      final controller = GestureZoneController();

      controller.setShowVisualFeedback(true);
      expect(controller.showVisualFeedback, isTrue);

      controller.setShowVisualFeedback(false);
      expect(controller.showVisualFeedback, isFalse);
    });

    test('GestureZoneController can be reset', () {
      final controller = GestureZoneController();

      controller.setEnabled(false);
      controller.setShowVisualFeedback(true);

      controller.reset();

      expect(controller.enabled, isTrue);
      expect(controller.showVisualFeedback, isFalse);
    });
  });

  group('GestureConfig Tests', () {
    test('GestureConfig default constructor works', () {
      final config = GestureConfig();
      expect(config.minDragDistance, equals(8.0));
      expect(config.minSwipeDistance, equals(50.0));
      expect(config.enableMultiTouch, isTrue);
    });

    test('GestureConfig.defaultConfig() works', () {
      final config = GestureConfig.defaultConfig();
      expect(config.minDragDistance, equals(8.0));
      expect(config.minSwipeDistance, equals(50.0));
    });

    test('GestureConfig.precise() works', () {
      final config = GestureConfig.precise();
      expect(config.minDragDistance, equals(4.0));
      expect(config.minSwipeDistance, equals(30.0));
      expect(config.enableVelocityRecognition, isTrue);
    });

    test('GestureConfig.relaxed() works', () {
      final config = GestureConfig.relaxed();
      expect(config.minDragDistance, equals(12.0));
      expect(config.minSwipeDistance, equals(80.0));
      expect(config.enableVelocityRecognition, isFalse);
    });

    test('GestureConfig.copyWith() works', () {
      final original = GestureConfig();
      final modified = original.copyWith(
        minDragDistance: 10.0,
        enableMultiTouch: false,
      );

      expect(modified.minDragDistance, equals(10.0));
      expect(modified.enableMultiTouch, isFalse);
      expect(modified.minSwipeDistance, equals(original.minSwipeDistance));
    });
  });

  group('GestureType Tests', () {
    test('GestureType display names work', () {
      expect(GestureType.tap.displayName, equals('Tap'));
      expect(GestureType.doubleTap.displayName, equals('Double Tap'));
      expect(GestureType.longPress.displayName, equals('Long Press'));
      expect(GestureType.drag.displayName, equals('Drag'));
      expect(GestureType.pinch.displayName, equals('Pinch'));
      expect(GestureType.rotation.displayName, equals('Rotation'));
      expect(GestureType.swipe.displayName, equals('Swipe'));
      expect(GestureType.swipeUp.displayName, equals('Swipe Up'));
      expect(GestureType.swipeDown.displayName, equals('Swipe Down'));
      expect(GestureType.swipeLeft.displayName, equals('Swipe Left'));
      expect(GestureType.swipeRight.displayName, equals('Swipe Right'));
      expect(GestureType.multiTouch.displayName, equals('Multi Touch'));
      expect(GestureType.custom.displayName, equals('Custom'));
    });

    test('GestureType isMultiTouch works', () {
      expect(GestureType.tap.isMultiTouch, isFalse);
      expect(GestureType.pinch.isMultiTouch, isTrue);
      expect(GestureType.rotation.isMultiTouch, isTrue);
      expect(GestureType.multiTouch.isMultiTouch, isTrue);
    });

    test('GestureType isSwipe works', () {
      expect(GestureType.tap.isSwipe, isFalse);
      expect(GestureType.swipe.isSwipe, isTrue);
      expect(GestureType.swipeUp.isSwipe, isTrue);
      expect(GestureType.swipeDown.isSwipe, isTrue);
      expect(GestureType.swipeLeft.isSwipe, isTrue);
      expect(GestureType.swipeRight.isSwipe, isTrue);
    });
  });

  group('TouchPoint Tests', () {
    test('TouchPoint can be created', () {
      final touchPoint = TouchPoint(
        pointerId: 1,
        position: const Offset(10.0, 20.0),
        timestamp: const Duration(seconds: 1),
      );

      expect(touchPoint.pointerId, equals(1));
      expect(touchPoint.position, equals(const Offset(10.0, 20.0)));
      expect(touchPoint.pressure, equals(1.0));
    });

    test('TouchPoint copyWith works', () {
      final original = TouchPoint(
        pointerId: 1,
        position: const Offset(10.0, 20.0),
        timestamp: const Duration(seconds: 1),
      );

      final modified = original.copyWith(
        position: const Offset(15.0, 25.0),
        pressure: 0.5,
      );

      expect(modified.pointerId, equals(original.pointerId));
      expect(modified.position, equals(const Offset(15.0, 25.0)));
      expect(modified.pressure, equals(0.5));
      expect(modified.timestamp, equals(original.timestamp));
    });
  });

  group('GestureRecognition Tests', () {
    test('GestureRecognition can be created', () {
      final recognition = GestureRecognition();
      expect(recognition, isNotNull);
    });

    test('GestureRecognition can be created with custom config', () {
      final config = GestureConfig.precise();
      final recognition = GestureRecognition(config: config);
      expect(recognition, isNotNull);
    });

    test('GestureRecognition validates touch points', () {
      final recognition = GestureRecognition();
      final config = GestureConfig(maxTouchPoints: 2);
      final recognition2 = GestureRecognition(config: config);

      final touchPoints = [
        TouchPoint(
          pointerId: 1,
          position: const Offset(10.0, 20.0),
          timestamp: const Duration(seconds: 1),
        ),
        TouchPoint(
          pointerId: 2,
          position: const Offset(15.0, 25.0),
          timestamp: const Duration(seconds: 1),
        ),
      ];

      expect(recognition.validateTouchPoints(touchPoints), isTrue);
      expect(recognition2.validateTouchPoints(touchPoints), isTrue);
    });
  });

  group('Extension Methods Tests', () {
    testWidgets('onTap extension method works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Container(
            width: 100,
            height: 100,
            color: Colors.blue,
          ).onTap((result) {}),
        ),
      );

      expect(find.byType(GestureZone), findsOneWidget);
    });

    testWidgets('onSwipeUp extension method works', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Container(
            width: 100,
            height: 100,
            color: Colors.blue,
          ).onSwipeUp((result) {}),
        ),
      );

      expect(find.byType(GestureZone), findsOneWidget);
    });

    testWidgets('onPinch extension method works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Container(
            width: 100,
            height: 100,
            color: Colors.blue,
          ).onPinch((result) {}),
        ),
      );

      expect(find.byType(GestureZone), findsOneWidget);
    });
  });
}
