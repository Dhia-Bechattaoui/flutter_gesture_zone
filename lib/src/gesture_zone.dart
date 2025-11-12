import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_gesture_zone/src/gesture_zone_controller.dart';
import 'package:flutter_gesture_zone/src/gesture_types.dart';
import 'package:flutter_gesture_zone/src/gesture_config.dart';
import 'package:flutter_gesture_zone/src/gesture_recognition.dart';

/// A widget that provides advanced gesture recognition capabilities.
///
/// This widget can recognize various gesture types including:
/// - Tap and double tap
/// - Long press
/// - Drag (pan)
/// - Pinch to zoom
/// - Rotation
/// - Swipe in all directions
/// - Multi-touch gestures
///
/// Example usage:
/// ```dart
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
class GestureZone extends StatefulWidget {
  /// Creates a new GestureZone widget.
  ///
  /// The [child] parameter is required and represents the widget that will
  /// receive gesture recognition capabilities.
  ///
  /// All gesture callback parameters are optional. You can provide any combination
  /// of gesture callbacks based on your needs.
  ///
  /// Example:
  /// ```dart
  /// GestureZone(
  ///   onTap: (result) => print('Tap detected'),
  ///   onSwipeUp: (result) => print('Swipe up detected'),
  ///   child: Container(
  ///     width: 200,
  ///     height: 200,
  ///     color: Colors.blue,
  ///   ),
  /// )
  /// ```
  const GestureZone({
    required this.child,
    super.key,
    this.controller,
    this.config,
    this.enabled = true,
    this.showVisualFeedback = false,
    this.onAnyGesture,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onDrag,
    this.onPinch,
    this.onRotation,
    this.onSwipe,
    this.onSwipeUp,
    this.onSwipeDown,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onMultiTouch,
    this.onCustom,
  });

  /// The child widget to wrap with gesture recognition.
  final Widget child;

  /// Controller for managing gesture behavior.
  final GestureZoneController? controller;

  /// Configuration for gesture recognition.
  final GestureConfig? config;

  /// Whether the gesture zone is enabled.
  final bool enabled;

  /// Whether to show visual feedback for touch points.
  final bool showVisualFeedback;

  /// Callback for any gesture.
  final GestureCallback? onAnyGesture;

  /// Callback for tap gestures.
  final GestureCallback? onTap;

  /// Callback for double tap gestures.
  final GestureCallback? onDoubleTap;

  /// Callback for long press gestures.
  final GestureCallback? onLongPress;

  /// Callback for drag gestures.
  final GestureCallback? onDrag;

  /// Callback for pinch gestures.
  final GestureCallback? onPinch;

  /// Callback for rotation gestures.
  final GestureCallback? onRotation;

  /// Callback for swipe gestures.
  final GestureCallback? onSwipe;

  /// Callback for swipe up gestures.
  final GestureCallback? onSwipeUp;

  /// Callback for swipe down gestures.
  final GestureCallback? onSwipeDown;

  /// Callback for swipe left gestures.
  final GestureCallback? onSwipeLeft;

  /// Callback for swipe right gestures.
  final GestureCallback? onSwipeRight;

  /// Callback for multi-touch gestures.
  final GestureCallback? onMultiTouch;

  /// Callback for custom gestures.
  final GestureCallback? onCustom;

  @override
  State<GestureZone> createState() => _GestureZoneState();
}

class _GestureZoneState extends State<GestureZone> {
  late GestureZoneController _controller;
  bool _isControllerProvided = false;
  late ScaleGestureRecognizer _scaleRecognizer;

  /// Track widget-managed callbacks to prevent duplicates
  final Map<GestureType, GestureCallback?> _widgetCallbacks = {};

  @override
  void initState() {
    super.initState();
    _initializeController();
    _initializeScaleRecognizer();
  }

  void _initializeScaleRecognizer() {
    _scaleRecognizer = ScaleGestureRecognizer()
      ..onStart = (details) {
        // When scale gesture starts with 2+ fingers, mark them as multi-touch
        if (_controller.activeTouchPointCount >= 2) {
          // Mark all active pointers as multi-touch to prevent tap detection
          for (final pointerId in _controller.activeTouchPoints.keys) {
            _controller.markMultiTouchPointer(pointerId);
          }

          // Trigger multi-touch callback if available
          if (widget.onMultiTouch != null) {
            final result = GestureResult(
              type: GestureType.multiTouch,
              confidence: 1.0,
              touchPoints: _controller.activeTouchPoints.values.toList(),
              duration: Duration.zero,
              data: {
                'touchPointCount': _controller.activeTouchPointCount,
                'focalPoint': details.focalPoint,
              },
            );
            widget.onMultiTouch!(result);
          }
        }
      }
      ..onUpdate = (details) {
        // Handle pinch gesture
        if (widget.onPinch != null && details.scale != 1.0) {
          final scaleChange = (details.scale - 1.0).abs();
          if (scaleChange > (_controller.config.minPinchScale)) {
            final result = GestureResult(
              type: GestureType.pinch,
              confidence: 0.95,
              touchPoints: _controller.activeTouchPoints.values.toList(),
              duration: Duration.zero,
              data: {
                'scaleFactor': details.scale,
                'isZoomIn': details.scale > 1.0,
                'center': details.focalPoint,
              },
            );
            widget.onPinch!(result);
          }
        }

        // Handle rotation gesture
        if (widget.onRotation != null &&
            details.rotation.abs() > _controller.config.minRotationAngle) {
          final result = GestureResult(
            type: GestureType.rotation,
            confidence: 0.95,
            touchPoints: _controller.activeTouchPoints.values.toList(),
            duration: Duration.zero,
            data: {
              'rotationAngle': details.rotation,
              'center': details.focalPoint,
            },
          );
          widget.onRotation!(result);
        }

        // Handle general multi-touch during movement
        if (widget.onMultiTouch != null &&
            _controller.activeTouchPointCount >= 2) {
          final result = GestureResult(
            type: GestureType.multiTouch,
            confidence: 0.9,
            touchPoints: _controller.activeTouchPoints.values.toList(),
            duration: Duration.zero,
            data: {
              'touchPointCount': _controller.activeTouchPointCount,
              'focalPoint': details.focalPoint,
              'scale': details.scale,
              'rotation': details.rotation,
            },
          );
          widget.onMultiTouch!(result);
        }
      }
      ..onEnd = (details) {
        // Multi-touch gesture ended
      };
  }

  void _initializeController() {
    if (widget.controller != null) {
      _controller = widget.controller!;
      _isControllerProvided = true;
    } else {
      _controller = GestureZoneController(config: widget.config);
      _isControllerProvided = false;
    }

    _setupCallbacks();
  }

  void _setupCallbacks() {
    // Remove old widget callbacks before adding new ones
    for (final entry in _widgetCallbacks.entries) {
      if (entry.value != null) {
        _controller.removeGestureCallback(entry.key, entry.value!);
      }
    }
    _widgetCallbacks.clear();

    // Set general callback
    _controller.setOnAnyGesture(widget.onAnyGesture);

    // Set specific callbacks and track them
    if (widget.onTap != null) {
      _controller.addGestureCallback(GestureType.tap, widget.onTap!);
      _widgetCallbacks[GestureType.tap] = widget.onTap;
    }
    if (widget.onDoubleTap != null) {
      _controller.addGestureCallback(
        GestureType.doubleTap,
        widget.onDoubleTap!,
      );
      _widgetCallbacks[GestureType.doubleTap] = widget.onDoubleTap;
    }
    if (widget.onLongPress != null) {
      _controller.addGestureCallback(
        GestureType.longPress,
        widget.onLongPress!,
      );
      _widgetCallbacks[GestureType.longPress] = widget.onLongPress;
    }
    if (widget.onDrag != null) {
      _controller.addGestureCallback(GestureType.drag, widget.onDrag!);
      _widgetCallbacks[GestureType.drag] = widget.onDrag;
    }
    if (widget.onPinch != null) {
      _controller.addGestureCallback(GestureType.pinch, widget.onPinch!);
      _widgetCallbacks[GestureType.pinch] = widget.onPinch;
    }
    if (widget.onRotation != null) {
      _controller.addGestureCallback(GestureType.rotation, widget.onRotation!);
      _widgetCallbacks[GestureType.rotation] = widget.onRotation;
    }
    if (widget.onSwipe != null) {
      _controller.addGestureCallback(GestureType.swipe, widget.onSwipe!);
      _widgetCallbacks[GestureType.swipe] = widget.onSwipe;
    }
    if (widget.onSwipeUp != null) {
      _controller.addGestureCallback(GestureType.swipeUp, widget.onSwipeUp!);
      _widgetCallbacks[GestureType.swipeUp] = widget.onSwipeUp;
    }
    if (widget.onSwipeDown != null) {
      _controller.addGestureCallback(
        GestureType.swipeDown,
        widget.onSwipeDown!,
      );
      _widgetCallbacks[GestureType.swipeDown] = widget.onSwipeDown;
    }
    if (widget.onSwipeLeft != null) {
      _controller.addGestureCallback(
        GestureType.swipeLeft,
        widget.onSwipeLeft!,
      );
      _widgetCallbacks[GestureType.swipeLeft] = widget.onSwipeLeft;
    }
    if (widget.onSwipeRight != null) {
      _controller.addGestureCallback(
        GestureType.swipeRight,
        widget.onSwipeRight!,
      );
      _widgetCallbacks[GestureType.swipeRight] = widget.onSwipeRight;
    }
    if (widget.onMultiTouch != null) {
      _controller.addGestureCallback(
        GestureType.multiTouch,
        widget.onMultiTouch!,
      );
      _widgetCallbacks[GestureType.multiTouch] = widget.onMultiTouch;
    }
    if (widget.onCustom != null) {
      _controller.addGestureCallback(GestureType.custom, widget.onCustom!);
      _widgetCallbacks[GestureType.custom] = widget.onCustom;
    }
  }

  @override
  void didUpdateWidget(GestureZone oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update controller if needed
    if (widget.controller != oldWidget.controller) {
      _initializeController();
    } else {
      // Re-setup callbacks if widget properties changed
      _setupCallbacks();
    }

    // Update enabled state
    _controller.setEnabled(widget.enabled);

    // Update visual feedback
    _controller.setShowVisualFeedback(widget.showVisualFeedback);
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: {
        ScaleGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<ScaleGestureRecognizer>(
              () => _scaleRecognizer,
              (ScaleGestureRecognizer instance) {},
            ),
      },
      behavior: HitTestBehavior.opaque,
      child: Listener(
        onPointerDown: _controller.handlePointerDown,
        onPointerMove: _controller.handlePointerMove,
        onPointerUp: _controller.handlePointerUp,
        onPointerCancel: _controller.handlePointerCancel,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              children: [
                widget.child,
                if (_controller.showVisualFeedback &&
                    _controller.activeTouchPointCount > 0)
                  ..._buildTouchPointIndicators(),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildTouchPointIndicators() {
    return _controller.activeTouchPoints.values.map((touchPoint) {
      return Positioned(
        left: touchPoint.position.dx - 20,
        top: touchPoint.position.dy - 20,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.3),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.blue, width: 2),
          ),
          child: Center(
            child: Text(
              '${touchPoint.pointerId}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  @override
  void dispose() {
    _scaleRecognizer.dispose();
    if (!_isControllerProvided) {
      _controller.dispose();
    }
    super.dispose();
  }
}

/// Extension methods for easier gesture zone usage.
extension GestureZoneExtension on Widget {
  /// Wraps this widget with a GestureZone for tap detection.
  Widget onTap(GestureCallback callback) {
    return GestureZone(onTap: callback, child: this);
  }

  /// Wraps this widget with a GestureZone for double tap detection.
  Widget onDoubleTap(GestureCallback callback) {
    return GestureZone(onDoubleTap: callback, child: this);
  }

  /// Wraps this widget with a GestureZone for long press detection.
  Widget onLongPress(GestureCallback callback) {
    return GestureZone(onLongPress: callback, child: this);
  }

  /// Wraps this widget with a GestureZone for drag detection.
  Widget onDrag(GestureCallback callback) {
    return GestureZone(onDrag: callback, child: this);
  }

  /// Wraps this widget with a GestureZone for pinch detection.
  Widget onPinch(GestureCallback callback) {
    return GestureZone(onPinch: callback, child: this);
  }

  /// Wraps this widget with a GestureZone for rotation detection.
  Widget onRotation(GestureCallback callback) {
    return GestureZone(onRotation: callback, child: this);
  }

  /// Wraps this widget with a GestureZone for swipe detection.
  Widget onSwipe(GestureCallback callback) {
    return GestureZone(onSwipe: callback, child: this);
  }

  /// Wraps this widget with a GestureZone for swipe up detection.
  Widget onSwipeUp(GestureCallback callback) {
    return GestureZone(onSwipeUp: callback, child: this);
  }

  /// Wraps this widget with a GestureZone for swipe down detection.
  Widget onSwipeDown(GestureCallback callback) {
    return GestureZone(onSwipeDown: callback, child: this);
  }

  /// Wraps this widget with a GestureZone for swipe left detection.
  Widget onSwipeLeft(GestureCallback callback) {
    return GestureZone(onSwipeLeft: callback, child: this);
  }

  /// Wraps this widget with a GestureZone for swipe right detection.
  Widget onSwipeRight(GestureCallback callback) {
    return GestureZone(onSwipeRight: callback, child: this);
  }
}
