# flutter_gesture_zone

A Flutter package for creating custom gesture zones with advanced touch handling, multi-touch support, and gesture recognition.

## Features

- **Advanced Gesture Recognition**: Supports tap, double tap, long press, drag, pinch, rotation, and swipe gestures
- **Multi-touch Support**: Handle multiple simultaneous touch points with custom logic
- **Configurable Parameters**: Fine-tune gesture recognition sensitivity and timing
- **Visual Feedback**: Optional visual indicators for touch points and gesture states
- **Flexible API**: Use as a widget wrapper or with extension methods
- **Controller Support**: Programmatic control over gesture behavior
- **Pressure Sensitivity**: Support for pressure-sensitive touch input
- **Velocity Recognition**: Velocity-based gesture detection for swipes

## Supported Gestures

- **Tap**: Single tap detection
- **Double Tap**: Double tap with configurable timing and distance
- **Long Press**: Long press with configurable duration
- **Drag**: Pan/drag gestures with distance and velocity tracking
- **Pinch**: Pinch to zoom with scale factor calculation
- **Rotation**: Two-finger rotation with angle calculation
- **Swipe**: Swipe gestures in all directions (up, down, left, right)
- **Multi-touch**: Custom multi-touch gesture handling
- **Custom**: User-defined gesture recognition

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_gesture_zone: ^0.0.4
```

## Quick Start

### Basic Usage

```dart
import 'package:flutter_gesture_zone/flutter_gesture_zone.dart';

GestureZone(
  onTap: (result) => print('Tap at ${result.data['position']}'),
  onSwipeUp: (result) => print('Swipe up detected'),
  onPinch: (result) => print('Pinch scale: ${result.data['scaleFactor']}'),
  child: Container(
    width: 200,
    height: 200,
    color: Colors.blue,
  ),
)
```

### Using Extension Methods

```dart
Container(
  width: 200,
  height: 200,
  color: Colors.blue,
)
.onTap((result) => print('Tapped!'))
.onSwipeUp((result) => print('Swiped up!'))
.onPinch((result) => print('Pinched!'));
```

## API Reference

### GestureZone Widget

The main widget that provides gesture recognition capabilities.

#### Constructor

```dart
GestureZone({
  Key? key,
  required Widget child,
  GestureZoneController? controller,
  GestureConfig? config,
  bool enabled = true,
  bool showVisualFeedback = false,
  GestureCallback? onAnyGesture,
  GestureCallback? onTap,
  GestureCallback? onDoubleTap,
  GestureCallback? onLongPress,
  GestureCallback? onDrag,
  GestureCallback? onPinch,
  GestureCallback? onRotation,
  GestureCallback? onSwipe,
  GestureCallback? onSwipeUp,
  GestureCallback? onSwipeDown,
  GestureCallback? onSwipeLeft,
  GestureCallback? onSwipeRight,
  GestureCallback? onMultiTouch,
  GestureCallback? onCustom,
})
```

#### Properties

- `child`: The widget to wrap with gesture recognition
- `controller`: Optional controller for programmatic control
- `config`: Configuration for gesture recognition parameters
- `enabled`: Whether gesture recognition is enabled
- `showVisualFeedback`: Whether to show visual touch point indicators
- `onAnyGesture`: Callback for any recognized gesture
- `onTap`, `onDoubleTap`, etc.: Callbacks for specific gesture types

### GestureZoneController

Controller for managing gesture zone behavior and state.

#### Methods

```dart
// Configuration
void setConfig(GestureConfig config)
void setEnabled(bool enabled)
void setShowVisualFeedback(bool show)

// Callbacks
void addGestureCallback(GestureType type, GestureCallback callback)
void removeGestureCallback(GestureType type, GestureCallback callback)
void setOnAnyGesture(GestureCallback? callback)

// State management
void reset()
```

#### Properties

- `config`: Current gesture configuration
- `enabled`: Whether the gesture zone is enabled
- `showVisualFeedback`: Whether visual feedback is shown
- `activeTouchPoints`: Currently active touch points
- `activeTouchPointCount`: Number of active touch points

### GestureConfig

Configuration class for gesture recognition parameters.

#### Factory Constructors

```dart
// Default configuration
GestureConfig.defaultConfig()

// Precise configuration (more sensitive)
GestureConfig.precise()

// Relaxed configuration (less sensitive)
GestureConfig.relaxed()
```

#### Properties

- `minDragDistance`: Minimum distance for drag recognition (default: 8.0)
- `minSwipeDistance`: Minimum distance for swipe recognition (default: 50.0)
- `maxSwipeTime`: Maximum time for swipe recognition (default: 300ms)
- `longPressTime`: Time required for long press (default: 500ms)
- `doubleTapTime`: Maximum time between double taps (default: 300ms)
- `doubleTapDistance`: Maximum distance between double taps (default: 40.0)
- `minPinchScale`: Minimum scale change for pinch (default: 0.1)
- `minRotationAngle`: Minimum rotation angle (default: 0.1)
- `enableMultiTouch`: Whether multi-touch is enabled (default: true)
- `maxTouchPoints`: Maximum simultaneous touch points (default: 5)
- `enablePressureSensitivity`: Whether pressure sensitivity is enabled (default: false)
- `minPressure`: Minimum pressure for touch recognition (default: 0.1)
- `enableVelocityRecognition`: Whether velocity recognition is enabled (default: true)
- `minSwipeVelocity`: Minimum velocity for swipe recognition (default: 300.0)

### GestureResult

Result object containing information about a recognized gesture.

#### Properties

- `type`: The type of gesture recognized
- `confidence`: Confidence level (0.0 to 1.0)
- `data`: Additional gesture-specific data
- `touchPoints`: Touch points used for the gesture
- `duration`: Duration of the gesture

## Examples

### Basic Gesture Handling

```dart
GestureZone(
  onTap: (result) {
    print('Tap detected at ${result.data['position']}');
  },
  onDoubleTap: (result) {
    print('Double tap detected!');
  },
  onLongPress: (result) {
    print('Long press detected!');
  },
  child: Container(
    width: 300,
    height: 200,
    color: Colors.blue,
    child: const Center(
      child: Text('Tap, double tap, or long press me!'),
    ),
  ),
)
```

### Swipe Gestures

```dart
GestureZone(
  onSwipeUp: (result) {
    print('Swiped up with velocity: ${result.data['velocity']}');
  },
  onSwipeDown: (result) {
    print('Swiped down with distance: ${result.data['distance']}');
  },
  onSwipeLeft: (result) {
    print('Swiped left!');
  },
  onSwipeRight: (result) {
    print('Swiped right!');
  },
  child: Container(
    width: 300,
    height: 200,
    color: Colors.green,
    child: const Center(
      child: Text('Swipe in any direction!'),
    ),
  ),
)
```

### Multi-touch Gestures

```dart
GestureZone(
  onPinch: (result) {
    final scaleFactor = result.data['scaleFactor'] as double;
    final isZoomIn = result.data['isZoomIn'] as bool;
    print('Pinch detected: ${isZoomIn ? 'zoom in' : 'zoom out'} (scale: $scaleFactor)');
  },
  onRotation: (result) {
    final angle = result.data['rotationAngle'] as double;
    print('Rotation detected: ${angle.toStringAsFixed(2)} radians');
  },
  child: Container(
    width: 300,
    height: 200,
    color: Colors.orange,
    child: const Center(
      child: Text('Pinch or rotate with two fingers!'),
    ),
  ),
)
```

### Using Controller

```dart
class _MyWidgetState extends State<MyWidget> {
  late GestureZoneController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GestureZoneController(
      config: GestureConfig.precise(),
    );
    
    _controller.addGestureCallback(GestureType.tap, (result) {
      print('Tap detected via controller!');
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureZone(
      controller: _controller,
      showVisualFeedback: true,
      child: Container(
        width: 300,
        height: 200,
        color: Colors.purple,
        child: const Center(
          child: Text('Controlled gesture zone'),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

### Custom Configuration

```dart
GestureZone(
  config: GestureConfig(
    minDragDistance: 10.0,
    minSwipeDistance: 60.0,
    longPressTime: Duration(milliseconds: 800),
    doubleTapTime: Duration(milliseconds: 400),
    enableMultiTouch: true,
    maxTouchPoints: 3,
    enablePressureSensitivity: true,
    minPressure: 0.5,
  ),
  onAnyGesture: (result) {
    print('Gesture detected: ${result.type.displayName}');
  },
  child: Container(
    width: 300,
    height: 200,
    color: Colors.red,
    child: const Center(
      child: Text('Custom configuration'),
    ),
  ),
)
```

## Extension Methods

The package provides convenient extension methods for quick gesture setup:

```dart
Container(
  width: 200,
  height: 200,
  color: Colors.blue,
)
.onTap((result) => print('Tapped!'))
.onSwipeUp((result) => print('Swiped up!'))
.onPinch((result) => print('Pinched!'))
.onRotation((result) => print('Rotated!'));
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details. 