/// Configuration for gesture recognition parameters.
class GestureConfig {
  /// Minimum distance required for a drag gesture to be recognized.
  final double minDragDistance;

  /// Minimum distance required for a swipe gesture to be recognized.
  final double minSwipeDistance;

  /// Maximum time allowed for a swipe gesture to be recognized.
  final Duration maxSwipeTime;

  /// Minimum time required for a long press gesture to be recognized.
  final Duration longPressTime;

  /// Maximum time allowed between taps for a double tap to be recognized.
  final Duration doubleTapTime;

  /// Maximum distance allowed between taps for a double tap to be recognized.
  final double doubleTapDistance;

  /// Minimum scale factor change required for pinch gesture recognition.
  final double minPinchScale;

  /// Minimum rotation angle required for rotation gesture recognition.
  final double minRotationAngle;

  /// Whether to enable multi-touch gestures.
  final bool enableMultiTouch;

  /// Maximum number of simultaneous touch points allowed.
  final int maxTouchPoints;

  /// Whether to enable pressure sensitivity.
  final bool enablePressureSensitivity;

  /// Minimum pressure required for touch recognition.
  final double minPressure;

  /// Whether to enable velocity-based gesture recognition.
  final bool enableVelocityRecognition;

  /// Minimum velocity required for swipe gesture recognition.
  final double minSwipeVelocity;

  const GestureConfig({
    this.minDragDistance = 8.0,
    this.minSwipeDistance = 50.0,
    this.maxSwipeTime = const Duration(milliseconds: 300),
    this.longPressTime = const Duration(milliseconds: 500),
    this.doubleTapTime = const Duration(milliseconds: 300),
    this.doubleTapDistance = 40.0,
    this.minPinchScale = 0.1,
    this.minRotationAngle = 0.1,
    this.enableMultiTouch = true,
    this.maxTouchPoints = 5,
    this.enablePressureSensitivity = false,
    this.minPressure = 0.1,
    this.enableVelocityRecognition = true,
    this.minSwipeVelocity = 300.0,
  });

  /// Creates a default configuration suitable for most use cases.
  factory GestureConfig.defaultConfig() {
    return const GestureConfig();
  }

  /// Creates a configuration optimized for precise gesture recognition.
  factory GestureConfig.precise() {
    return const GestureConfig(
      minDragDistance: 4.0,
      minSwipeDistance: 30.0,
      maxSwipeTime: Duration(milliseconds: 200),
      longPressTime: Duration(milliseconds: 400),
      doubleTapTime: Duration(milliseconds: 250),
      doubleTapDistance: 20.0,
      minPinchScale: 0.05,
      minRotationAngle: 0.05,
      enableVelocityRecognition: true,
      minSwipeVelocity: 200.0,
    );
  }

  /// Creates a configuration optimized for relaxed gesture recognition.
  factory GestureConfig.relaxed() {
    return const GestureConfig(
      minDragDistance: 12.0,
      minSwipeDistance: 80.0,
      maxSwipeTime: Duration(milliseconds: 500),
      longPressTime: Duration(milliseconds: 800),
      doubleTapTime: Duration(milliseconds: 400),
      doubleTapDistance: 60.0,
      minPinchScale: 0.2,
      minRotationAngle: 0.2,
      enableVelocityRecognition: false,
    );
  }

  /// Creates a copy of this configuration with updated values.
  GestureConfig copyWith({
    double? minDragDistance,
    double? minSwipeDistance,
    Duration? maxSwipeTime,
    Duration? longPressTime,
    Duration? doubleTapTime,
    double? doubleTapDistance,
    double? minPinchScale,
    double? minRotationAngle,
    bool? enableMultiTouch,
    int? maxTouchPoints,
    bool? enablePressureSensitivity,
    double? minPressure,
    bool? enableVelocityRecognition,
    double? minSwipeVelocity,
  }) {
    return GestureConfig(
      minDragDistance: minDragDistance ?? this.minDragDistance,
      minSwipeDistance: minSwipeDistance ?? this.minSwipeDistance,
      maxSwipeTime: maxSwipeTime ?? this.maxSwipeTime,
      longPressTime: longPressTime ?? this.longPressTime,
      doubleTapTime: doubleTapTime ?? this.doubleTapTime,
      doubleTapDistance: doubleTapDistance ?? this.doubleTapDistance,
      minPinchScale: minPinchScale ?? this.minPinchScale,
      minRotationAngle: minRotationAngle ?? this.minRotationAngle,
      enableMultiTouch: enableMultiTouch ?? this.enableMultiTouch,
      maxTouchPoints: maxTouchPoints ?? this.maxTouchPoints,
      enablePressureSensitivity:
          enablePressureSensitivity ?? this.enablePressureSensitivity,
      minPressure: minPressure ?? this.minPressure,
      enableVelocityRecognition:
          enableVelocityRecognition ?? this.enableVelocityRecognition,
      minSwipeVelocity: minSwipeVelocity ?? this.minSwipeVelocity,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GestureConfig &&
        other.minDragDistance == minDragDistance &&
        other.minSwipeDistance == minSwipeDistance &&
        other.maxSwipeTime == maxSwipeTime &&
        other.longPressTime == longPressTime &&
        other.doubleTapTime == doubleTapTime &&
        other.doubleTapDistance == doubleTapDistance &&
        other.minPinchScale == minPinchScale &&
        other.minRotationAngle == minRotationAngle &&
        other.enableMultiTouch == enableMultiTouch &&
        other.maxTouchPoints == maxTouchPoints &&
        other.enablePressureSensitivity == enablePressureSensitivity &&
        other.minPressure == minPressure &&
        other.enableVelocityRecognition == enableVelocityRecognition &&
        other.minSwipeVelocity == minSwipeVelocity;
  }

  @override
  int get hashCode {
    return Object.hash(
      minDragDistance,
      minSwipeDistance,
      maxSwipeTime,
      longPressTime,
      doubleTapTime,
      doubleTapDistance,
      minPinchScale,
      minRotationAngle,
      enableMultiTouch,
      maxTouchPoints,
      enablePressureSensitivity,
      minPressure,
      enableVelocityRecognition,
      minSwipeVelocity,
    );
  }

  @override
  String toString() {
    return 'GestureConfig('
        'minDragDistance: $minDragDistance, '
        'minSwipeDistance: $minSwipeDistance, '
        'maxSwipeTime: $maxSwipeTime, '
        'longPressTime: $longPressTime, '
        'doubleTapTime: $doubleTapTime, '
        'doubleTapDistance: $doubleTapDistance, '
        'minPinchScale: $minPinchScale, '
        'minRotationAngle: $minRotationAngle, '
        'enableMultiTouch: $enableMultiTouch, '
        'maxTouchPoints: $maxTouchPoints, '
        'enablePressureSensitivity: $enablePressureSensitivity, '
        'minPressure: $minPressure, '
        'enableVelocityRecognition: $enableVelocityRecognition, '
        'minSwipeVelocity: $minSwipeVelocity)';
  }
}
