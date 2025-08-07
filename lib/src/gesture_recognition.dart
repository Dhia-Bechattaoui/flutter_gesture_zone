import 'dart:math';
import 'package:flutter/material.dart';
import 'gesture_types.dart';
import 'gesture_config.dart';
import 'touch_point.dart';

/// Result of a recognized gesture.
class GestureResult {
  /// The type of gesture that was recognized.
  final GestureType type;

  /// The confidence level of the recognition (0.0 to 1.0).
  final double confidence;

  /// Additional data specific to the gesture type.
  final Map<String, dynamic> data;

  /// The touch points that were used for this gesture.
  final List<TouchPoint> touchPoints;

  /// The duration of the gesture.
  final Duration duration;

  const GestureResult({
    required this.type,
    required this.confidence,
    this.data = const {},
    required this.touchPoints,
    required this.duration,
  });

  @override
  String toString() {
    return 'GestureResult(type: $type, confidence: $confidence, duration: $duration)';
  }
}

/// Engine for recognizing gestures from touch data.
class GestureRecognition {
  final GestureConfig config;

  GestureRecognition({GestureConfig? config})
      : config = config ?? GestureConfig.defaultConfig();

  /// Recognizes gestures from a sequence of touch points.
  GestureResult? recognizeGesture(List<TouchPoint> touchPoints) {
    if (touchPoints.isEmpty) return null;

    final duration = touchPoints.last.timestamp - touchPoints.first.timestamp;

    // Single touch gestures
    if (touchPoints.length == 1) {
      return _recognizeSingleTouchGesture(touchPoints.first, duration);
    }

    // Multi-touch gestures
    if (config.enableMultiTouch && touchPoints.length > 1) {
      return _recognizeMultiTouchGesture(touchPoints, duration);
    }

    return null;
  }

  /// Recognizes single touch gestures.
  GestureResult? _recognizeSingleTouchGesture(
    TouchPoint touchPoint,
    Duration duration,
  ) {
    // Check for tap
    if (duration.inMilliseconds < 200) {
      return GestureResult(
        type: GestureType.tap,
        confidence: 1.0,
        touchPoints: [touchPoint],
        duration: duration,
        data: {'position': touchPoint.position},
      );
    }

    // Check for long press
    if (duration >= config.longPressTime) {
      return GestureResult(
        type: GestureType.longPress,
        confidence: 1.0,
        touchPoints: [touchPoint],
        duration: duration,
        data: {'position': touchPoint.position},
      );
    }

    return null;
  }

  /// Recognizes multi-touch gestures.
  GestureResult? _recognizeMultiTouchGesture(
    List<TouchPoint> touchPoints,
    Duration duration,
  ) {
    if (touchPoints.length != 2) return null;

    final point1 = touchPoints[0];
    final point2 = touchPoints[1];

    // Calculate initial and final distances
    final initialDistance = _calculateDistance(
      point1.position,
      point2.position,
    );
    final finalDistance = _calculateDistance(point1.position, point2.position);

    // Calculate scale factor
    final scaleFactor = finalDistance / initialDistance;

    // Check for pinch gesture
    if ((scaleFactor - 1.0).abs() > config.minPinchScale) {
      return GestureResult(
        type: GestureType.pinch,
        confidence: 0.9,
        touchPoints: touchPoints,
        duration: duration,
        data: {
          'scaleFactor': scaleFactor,
          'isZoomIn': scaleFactor > 1.0,
          'center': _calculateCenter(point1.position, point2.position),
        },
      );
    }

    // Calculate rotation angle
    final initialAngle = _calculateAngle(point1.position, point2.position);
    final finalAngle = _calculateAngle(point1.position, point2.position);
    final rotationAngle = finalAngle - initialAngle;

    // Check for rotation gesture
    if (rotationAngle.abs() > config.minRotationAngle) {
      return GestureResult(
        type: GestureType.rotation,
        confidence: 0.9,
        touchPoints: touchPoints,
        duration: duration,
        data: {
          'rotationAngle': rotationAngle,
          'center': _calculateCenter(point1.position, point2.position),
        },
      );
    }

    return null;
  }

  /// Recognizes drag gestures from a sequence of touch points.
  GestureResult? recognizeDragGesture(List<TouchPoint> touchPoints) {
    if (touchPoints.length < 2) return null;

    final startPoint = touchPoints.first;
    final endPoint = touchPoints.last;
    final distance = _calculateDistance(startPoint.position, endPoint.position);

    if (distance >= config.minDragDistance) {
      final duration = endPoint.timestamp - startPoint.timestamp;
      final velocity = config.enableVelocityRecognition
          ? distance / duration.inMilliseconds * 1000
          : 0.0;

      return GestureResult(
        type: GestureType.drag,
        confidence: 0.95,
        touchPoints: touchPoints,
        duration: duration,
        data: {
          'startPosition': startPoint.position,
          'endPosition': endPoint.position,
          'distance': distance,
          'velocity': velocity,
          'delta': endPoint.position - startPoint.position,
        },
      );
    }

    return null;
  }

  /// Recognizes swipe gestures from a sequence of touch points.
  GestureResult? recognizeSwipeGesture(List<TouchPoint> touchPoints) {
    if (touchPoints.length < 2) return null;

    final startPoint = touchPoints.first;
    final endPoint = touchPoints.last;
    final duration = endPoint.timestamp - startPoint.timestamp;

    // Check if swipe is within time limit
    if (duration > config.maxSwipeTime) return null;

    final distance = _calculateDistance(startPoint.position, endPoint.position);
    if (distance < config.minSwipeDistance) return null;

    final velocity = distance / duration.inMilliseconds * 1000;

    // Check minimum velocity if enabled
    if (config.enableVelocityRecognition &&
        velocity < config.minSwipeVelocity) {
      return null;
    }

    // Determine swipe direction
    final angle = _calculateAngle(startPoint.position, endPoint.position);
    final direction = _getSwipeDirection(angle);

    return GestureResult(
      type: direction,
      confidence: 0.9,
      touchPoints: touchPoints,
      duration: duration,
      data: {
        'startPosition': startPoint.position,
        'endPosition': endPoint.position,
        'distance': distance,
        'velocity': velocity,
        'angle': angle,
        'direction': direction,
      },
    );
  }

  /// Calculates the distance between two points.
  double _calculateDistance(Offset point1, Offset point2) {
    return (point2 - point1).distance;
  }

  /// Calculates the angle between two points.
  double _calculateAngle(Offset point1, Offset point2) {
    return atan2(point2.dy - point1.dy, point2.dx - point1.dx);
  }

  /// Calculates the center point between two points.
  Offset _calculateCenter(Offset point1, Offset point2) {
    return Offset((point1.dx + point2.dx) / 2, (point1.dy + point2.dy) / 2);
  }

  /// Determines the swipe direction based on angle.
  GestureType _getSwipeDirection(double angle) {
    // Convert angle to degrees and normalize to 0-360
    final degrees = (angle * 180 / pi + 360) % 360;

    if (degrees >= 315 || degrees < 45) {
      return GestureType.swipeRight;
    } else if (degrees >= 45 && degrees < 135) {
      return GestureType.swipeDown;
    } else if (degrees >= 135 && degrees < 225) {
      return GestureType.swipeLeft;
    } else {
      return GestureType.swipeUp;
    }
  }

  /// Checks if a double tap has occurred.
  bool isDoubleTap(TouchPoint currentTap, TouchPoint? previousTap) {
    if (previousTap == null) return false;

    final timeDiff = currentTap.timestamp - previousTap.timestamp;
    final distance = _calculateDistance(
      currentTap.position,
      previousTap.position,
    );

    return timeDiff <= config.doubleTapTime &&
        distance <= config.doubleTapDistance;
  }

  /// Validates touch points based on configuration.
  bool validateTouchPoints(List<TouchPoint> touchPoints) {
    if (touchPoints.length > config.maxTouchPoints) return false;

    if (config.enablePressureSensitivity) {
      for (final point in touchPoints) {
        if (point.pressure < config.minPressure) return false;
      }
    }

    return true;
  }
}
