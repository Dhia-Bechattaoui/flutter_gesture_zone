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

  /// Creates a new gesture result with the specified parameters.
  ///
  /// The [confidence] should be a value between 0.0 and 1.0, where 1.0 indicates
  /// complete certainty in the gesture recognition.
  ///
  /// The [data] map can contain any additional information relevant to the gesture,
  /// such as position, velocity, scale factor, etc.
  ///
  /// Example:
  /// ```dart
  /// final result = GestureResult(
  ///   type: GestureType.tap,
  ///   confidence: 1.0,
  ///   touchPoints: [touchPoint],
  ///   duration: Duration(milliseconds: 100),
  ///   data: {'position': Offset(100, 200)},
  /// );
  /// ```
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
  /// The configuration used for gesture recognition.
  final GestureConfig config;

  /// Creates a new gesture recognition engine.
  ///
  /// If no configuration is provided, a default configuration will be used.
  /// The configuration determines sensitivity, timing, and other recognition parameters.
  ///
  /// Example:
  /// ```dart
  /// final recognition = GestureRecognition();
  /// final preciseRecognition = GestureRecognition(
  ///   config: GestureConfig.precise(),
  /// );
  /// ```
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

  /// Recognizes pinch gestures from touch history.
  GestureResult? recognizePinchGesture(
    Map<int, List<TouchPoint>> touchHistory,
  ) {
    if (touchHistory.length != 2) return null;

    final touchPoints1 = touchHistory.values.first;
    final touchPoints2 = touchHistory.values.last;

    if (touchPoints1.length < 2 || touchPoints2.length < 2) return null;

    final initialPoint1 = touchPoints1.first;
    final finalPoint1 = touchPoints1.last;
    final initialPoint2 = touchPoints2.first;
    final finalPoint2 = touchPoints2.last;

    final initialDistance = _calculateDistance(
      initialPoint1.position,
      initialPoint2.position,
    );
    final finalDistance = _calculateDistance(
      finalPoint1.position,
      finalPoint2.position,
    );

    if (initialDistance == 0) return null;

    final scaleFactor = finalDistance / initialDistance;
    final duration = finalPoint1.timestamp - initialPoint1.timestamp;

    if ((scaleFactor - 1.0).abs() > config.minPinchScale) {
      return GestureResult(
        type: GestureType.pinch,
        confidence: 0.9,
        touchPoints: [finalPoint1, finalPoint2],
        duration: duration,
        data: {
          'scaleFactor': scaleFactor,
          'isZoomIn': scaleFactor > 1.0,
          'center':
              _calculateCenter(finalPoint1.position, finalPoint2.position),
        },
      );
    }

    return null;
  }

  /// Recognizes rotation gestures from touch history.
  GestureResult? recognizeRotationGesture(
    Map<int, List<TouchPoint>> touchHistory,
  ) {
    if (touchHistory.length != 2) return null;

    final touchPoints1 = touchHistory.values.first;
    final touchPoints2 = touchHistory.values.last;

    if (touchPoints1.length < 2 || touchPoints2.length < 2) return null;

    final initialPoint1 = touchPoints1.first;
    final finalPoint1 = touchPoints1.last;
    final initialPoint2 = touchPoints2.first;
    final finalPoint2 = touchPoints2.last;

    final initialAngle = _calculateAngle(
      initialPoint1.position,
      initialPoint2.position,
    );
    final finalAngle = _calculateAngle(
      finalPoint1.position,
      finalPoint2.position,
    );

    final rotationAngle = finalAngle - initialAngle;
    final duration = finalPoint1.timestamp - initialPoint1.timestamp;

    if (rotationAngle.abs() > config.minRotationAngle) {
      return GestureResult(
        type: GestureType.rotation,
        confidence: 0.9,
        touchPoints: [finalPoint1, finalPoint2],
        duration: duration,
        data: {
          'rotationAngle': rotationAngle,
          'center':
              _calculateCenter(finalPoint1.position, finalPoint2.position),
        },
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

    // For multi-touch gestures, we need to track the initial positions
    // Since we're only getting current positions here, we need to get them from history
    // This method should be called with the full touch history, not just current points

    // Calculate current distance between the two touch points
    final currentDistance = _calculateDistance(
      point1.position,
      point2.position,
    );

    // For now, we'll use a simplified approach that detects when two fingers are present
    // In a real implementation, you'd want to track the initial vs final positions
    // from the touch history to calculate actual scale and rotation changes

    // Check if this is a multi-touch gesture (two fingers present)
    if (point1.pointerId != point2.pointerId) {
      return GestureResult(
        type: GestureType.multiTouch,
        confidence: 0.8,
        touchPoints: touchPoints,
        duration: duration,
        data: {
          'currentDistance': currentDistance,
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
