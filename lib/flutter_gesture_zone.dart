/// A Flutter package that provides advanced gesture recognition capabilities
/// for Flutter applications.
///
/// This package offers a comprehensive gesture recognition system that can detect
/// various types of touch gestures including:
///
/// ## Supported Gestures
/// * **Basic Gestures**: Tap, double tap, long press
/// * **Drag Gestures**: Pan/drag with velocity and distance tracking
/// * **Swipe Gestures**: Directional swipes (up, down, left, right) with velocity
/// * **Multi-touch Gestures**: Pinch-to-zoom, rotation, and custom multi-touch
/// * **Custom Gestures**: User-defined gesture patterns
///
/// ## Key Features
/// * **High Performance**: Optimized gesture recognition engine
/// * **Configurable**: Customizable sensitivity and timing parameters
/// * **Visual Feedback**: Optional touch point indicators
/// * **Controller Support**: Programmatic gesture management
/// * **Cross-platform**: Works on all Flutter platforms (iOS, Android, Web, Desktop)
///
/// ## Quick Start
/// ```dart
/// import 'package:flutter_gesture_zone/flutter_gesture_zone.dart';
///
/// GestureZone(
///   onTap: (result) => print('Tap at ${result.data['position']}'),
///   onSwipeUp: (result) => print('Swipe up detected'),
///   onPinch: (result) => print('Pinch scale: ${result.data['scaleFactor']}'),
///   child: Container(
///     width: 200,
///     height: 200,
///     color: Colors.blue,
///   ),
/// )
/// ```
///
/// ## Advanced Usage
/// ```dart
/// final controller = GestureZoneController(
///   config: GestureConfig.precise(),
/// );
///
/// GestureZone(
///   controller: controller,
///   showVisualFeedback: true,
///   onAnyGesture: (result) {
///     print('Gesture detected: ${result.type.displayName}');
///   },
///   child: YourWidget(),
/// )
/// ```
///
/// ## Configuration
/// The package provides three preset configurations:
/// * `GestureConfig.defaultConfig()` - Balanced settings for most use cases
/// * `GestureConfig.precise()` - Higher sensitivity for precise gestures
/// * `GestureConfig.relaxed()` - Lower sensitivity for casual usage
///
/// ## Extension Methods
/// For convenience, the package provides extension methods:
/// ```dart
/// Container()
///   .onTap((result) => print('Tapped!'))
///   .onSwipeUp((result) => print('Swiped up!'))
///   .onPinch((result) => print('Pinched!'))
/// ```
///
/// ## Contributing
/// Contributions are welcome! Please see the GitHub repository for more details.
///
/// ## License
/// This package is licensed under the MIT License.
library;

export 'src/gesture_zone.dart';
export 'src/gesture_zone_controller.dart';
export 'src/gesture_recognition.dart';
export 'src/gesture_types.dart';
export 'src/touch_point.dart';
export 'src/gesture_config.dart';
