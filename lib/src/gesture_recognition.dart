import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_gesture_zone/src/gesture_types.dart';
import 'package:flutter_gesture_zone/src/gesture_config.dart';
import 'package:flutter_gesture_zone/src/touch_point.dart';

/// Function type for custom gesture recognizers.
///
/// Custom recognizers analyze touch history and return a GestureResult
/// if a custom gesture pattern is detected, or null otherwise.
///
/// Example:
/// ```dart
/// GestureResult? myCustomRecognizer(Map<int, List<TouchPoint>> touchHistory) {
///   // Analyze touch history and detect custom pattern
///   if (/* custom pattern detected */) {
///     return GestureResult(
///       type: GestureType.custom,
///       confidence: 0.9,
///       touchPoints: [...],
///       duration: Duration(milliseconds: 100),
///       data: {'customData': 'value'},
///     );
///   }
///   return null;
/// }
/// ```
typedef CustomGestureRecognizer =
    GestureResult? Function(Map<int, List<TouchPoint>> touchHistory);

/// Result of a recognized gesture.
class GestureResult {
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
    required this.touchPoints,
    required this.duration,
    this.data = const {},
  });

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

  @override
  String toString() {
    return 'GestureResult(type: $type, confidence: $confidence, duration: $duration)';
  }
}

/// Engine for recognizing gestures from touch data.
class GestureRecognition {
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

  /// The configuration used for gesture recognition.
  final GestureConfig config;

  /// Custom gesture recognizers registered by the user.
  final List<CustomGestureRecognizer> _customRecognizers = [];

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
  ///
  /// Pinch gestures are detected when two fingers move closer together (zoom out)
  /// or farther apart (zoom in). The method tracks the distance between the two
  /// touch points over time and calculates the scale factor.
  GestureResult? recognizePinchGesture(
    Map<int, List<TouchPoint>> touchHistory,
  ) {
    if (touchHistory.length != 2) return null;

    final histories = touchHistory.values.toList();
    final touchPoints1 = histories[0];
    final touchPoints2 = histories[1];

    // Need at least 2 points in each history to calculate scale change
    if (touchPoints1.length < 2 || touchPoints2.length < 2) return null;

    // Get the initial and current positions for both touch points
    final initialPoint1 = touchPoints1.first;
    final currentPoint1 = touchPoints1.last;
    final initialPoint2 = touchPoints2.first;
    final currentPoint2 = touchPoints2.last;

    // Calculate the initial distance between the two touch points
    final initialDistance = _calculateDistance(
      initialPoint1.position,
      initialPoint2.position,
    );

    // Calculate the current distance between the two touch points
    final currentDistance = _calculateDistance(
      currentPoint1.position,
      currentPoint2.position,
    );

    // Avoid division by zero
    if (initialDistance < 1.0) return null;

    // Calculate scale factor (ratio of current distance to initial distance)
    final scaleFactor = currentDistance / initialDistance;

    // Calculate the change in distance
    final distanceChange = (currentDistance - initialDistance).abs();

    // Calculate duration
    final startTime = initialPoint1.timestamp;
    final endTime = currentPoint1.timestamp;
    final duration = Duration(
      milliseconds: endTime.inMilliseconds - startTime.inMilliseconds,
    );

    // Detect pinch if:
    // 1. The scale change is significant (above threshold)
    // 2. The distance change is significant (at least 10 pixels)
    // 3. The gesture has been ongoing for at least 16ms (one frame)
    if (duration.inMilliseconds >= 16 &&
        distanceChange >= 10.0 &&
        (scaleFactor - 1.0).abs() > config.minPinchScale) {
      // Calculate the center point between the two touch points
      final center = _calculateCenter(
        currentPoint1.position,
        currentPoint2.position,
      );

      // Determine if it's zoom in (scale > 1) or zoom out (scale < 1)
      final isZoomIn = scaleFactor > 1.0;

      return GestureResult(
        type: GestureType.pinch,
        confidence: 0.95,
        touchPoints: [currentPoint1, currentPoint2],
        duration: duration,
        data: {
          'scaleFactor': scaleFactor,
          'isZoomIn': isZoomIn,
          'initialDistance': initialDistance,
          'currentDistance': currentDistance,
          'distanceChange': distanceChange,
          'center': center,
        },
      );
    }

    return null;
  }

  /// Recognizes rotation gestures from touch history.
  ///
  /// Rotation gestures are detected when two fingers rotate around a center point.
  /// The method calculates the angle between the two touch points and tracks how
  /// this angle changes over time.
  GestureResult? recognizeRotationGesture(
    Map<int, List<TouchPoint>> touchHistory,
  ) {
    if (touchHistory.length != 2) return null;

    final histories = touchHistory.values.toList();
    final touchPoints1 = histories[0];
    final touchPoints2 = histories[1];

    // Need at least 2 points in each history to calculate rotation
    if (touchPoints1.length < 2 || touchPoints2.length < 2) return null;

    // Get the initial and current positions for both touch points
    final initialPoint1 = touchPoints1.first;
    final currentPoint1 = touchPoints1.last;
    final initialPoint2 = touchPoints2.first;
    final currentPoint2 = touchPoints2.last;

    // Calculate the center point (pivot point for rotation)
    final center = _calculateCenter(
      initialPoint1.position,
      initialPoint2.position,
    );

    // Calculate initial angle from center to point1
    final initialAngle1 = _calculateAngleFromCenter(
      center,
      initialPoint1.position,
    );

    // Calculate initial angle from center to point2
    final initialAngle2 = _calculateAngleFromCenter(
      center,
      initialPoint2.position,
    );

    // Calculate current angle from center to point1
    final currentAngle1 = _calculateAngleFromCenter(
      center,
      currentPoint1.position,
    );

    // Calculate current angle from center to point2
    final currentAngle2 = _calculateAngleFromCenter(
      center,
      currentPoint2.position,
    );

    // Calculate the rotation angle for each point
    final rotation1 = _normalizeAngle(currentAngle1 - initialAngle1);
    final rotation2 = _normalizeAngle(currentAngle2 - initialAngle2);

    // Average the rotations (both points should rotate similarly)
    final averageRotation = (rotation1 + rotation2) / 2.0;

    // Calculate duration
    final startTime = initialPoint1.timestamp;
    final endTime = currentPoint1.timestamp;
    final duration = Duration(
      milliseconds: endTime.inMilliseconds - startTime.inMilliseconds,
    );

    // Detect rotation if:
    // 1. The rotation angle is significant (above threshold)
    // 2. Both points rotated in the same direction (similar rotation angles)
    // 3. The gesture has been ongoing for at least 16ms (one frame)
    final rotationDifference = (rotation1 - rotation2).abs();
    if (duration.inMilliseconds >= 16 &&
        rotationDifference < 0.5 && // Both points rotated similarly
        averageRotation.abs() > config.minRotationAngle) {
      return GestureResult(
        type: GestureType.rotation,
        confidence: 0.95,
        touchPoints: [currentPoint1, currentPoint2],
        duration: duration,
        data: {
          'rotationAngle': averageRotation,
          'rotation1': rotation1,
          'rotation2': rotation2,
          'center': center,
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

  /// Calculates the angle between two points (in radians).
  /// Returns the angle from point1 to point2.
  /// Calculates the angle between two points (in radians).
  /// Returns the angle from point1 to point2.
  double _calculateAngle(Offset point1, Offset point2) {
    final dx = point2.dx - point1.dx;
    final dy = point2.dy - point1.dy;
    return math.atan2(dy, dx);
  }

  /// Calculates the angle from a center point to a target point (in radians).
  /// Returns the angle in radians, where 0 is right, π/2 is down, π is left, -π/2 is up.
  double _calculateAngleFromCenter(Offset center, Offset point) {
    final dx = point.dx - center.dx;
    final dy = point.dy - center.dy;
    return math.atan2(dy, dx);
  }

  /// Normalizes an angle to the range [-π, π].
  double _normalizeAngle(double angle) {
    while (angle > math.pi) {
      angle -= 2 * math.pi;
    }
    while (angle < -math.pi) {
      angle += 2 * math.pi;
    }
    return angle;
  }

  /// Calculates the center point between two points.
  Offset _calculateCenter(Offset point1, Offset point2) {
    return Offset((point1.dx + point2.dx) / 2, (point1.dy + point2.dy) / 2);
  }

  /// Determines the swipe direction based on angle.
  GestureType _getSwipeDirection(double angle) {
    // Convert angle to degrees and normalize to 0-360
    final degrees = (angle * 180 / math.pi + 360) % 360;

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

  /// Registers a custom gesture recognizer.
  ///
  /// Custom recognizers are called during gesture recognition to detect
  /// user-defined gesture patterns. They receive the full touch history
  /// and can return a GestureResult if a custom pattern is detected.
  ///
  /// Example:
  /// ```dart
  /// recognition.addCustomRecognizer((touchHistory) {
  ///   // Detect custom pattern
  ///   if (/* pattern detected */) {
  ///     return GestureResult(...);
  ///   }
  ///   return null;
  /// });
  /// ```
  void addCustomRecognizer(CustomGestureRecognizer recognizer) {
    _customRecognizers.add(recognizer);
  }

  /// Removes a custom gesture recognizer.
  void removeCustomRecognizer(CustomGestureRecognizer recognizer) {
    _customRecognizers.remove(recognizer);
  }

  /// Clears all custom gesture recognizers.
  void clearCustomRecognizers() {
    _customRecognizers.clear();
  }

  /// Tries to recognize custom gestures from touch history.
  ///
  /// Returns the first custom gesture result found, or null if none match.
  GestureResult? recognizeCustomGestures(
    Map<int, List<TouchPoint>> touchHistory,
  ) {
    for (final recognizer in _customRecognizers) {
      final result = recognizer(touchHistory);
      if (result != null) {
        return result;
      }
    }
    return null;
  }
}
