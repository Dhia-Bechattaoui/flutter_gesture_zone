import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_gesture_zone/src/gesture_types.dart';
import 'package:flutter_gesture_zone/src/gesture_config.dart';
import 'package:flutter_gesture_zone/src/gesture_recognition.dart';
import 'package:flutter_gesture_zone/src/touch_point.dart';

/// Callback function for gesture events.
typedef GestureCallback = void Function(GestureResult result);

/// Controller for managing gesture zone behavior and state.
class GestureZoneController extends ChangeNotifier {
  /// Creates a new GestureZoneController.
  ///
  /// The [config] parameter is optional. If not provided, a default configuration
  /// will be used that provides balanced gesture recognition settings.
  ///
  /// Example:
  /// ```dart
  /// // Using default configuration
  /// final controller = GestureZoneController();
  ///
  /// // Using custom configuration
  /// final controller = GestureZoneController(
  ///   config: GestureConfig.precise(),
  /// );
  /// ```
  GestureZoneController({GestureConfig? config})
    : _config = config ?? GestureConfig.defaultConfig() {
    _recognition = GestureRecognition(config: _config);
  }

  /// Configuration for gesture recognition.
  GestureConfig _config;

  /// The gesture recognition engine.
  late GestureRecognition _recognition;

  /// Currently active touch points.
  final Map<int, TouchPoint> _activeTouchPoints = {};

  /// History of touch points for gesture recognition.
  final Map<int, List<TouchPoint>> _touchHistory = {};

  /// Timer for long press detection.
  Timer? _longPressTimer;

  /// Timer for multi-touch detection (to detect held multi-touch).
  Timer? _multiTouchTimer;

  /// Previous tap for double tap detection.
  TouchPoint? _previousTap;

  /// Timestamp of the last multi-touch gesture to prevent tap detection immediately after.
  DateTime? _lastMultiTouchTime;

  /// Timestamp when we last had 2 active touch points (to prevent false tap detection).
  DateTime? _lastTwoFingerTime;

  /// Set of pointer IDs that were part of a multi-touch gesture.
  /// Used to prevent tap detection on these pointers even after they're lifted.
  final Set<int> _multiTouchPointers = {};

  /// Whether the gesture zone is enabled.
  bool _enabled = true;

  /// Whether to show visual feedback.
  bool _showVisualFeedback = false;

  /// Callbacks for different gesture types.
  final Map<GestureType, List<GestureCallback>> _gestureCallbacks = {};

  /// Callback for all gestures.
  GestureCallback? _onAnyGesture;

  /// Custom gesture recognizers registered by the user.
  final List<CustomGestureRecognizer> _customRecognizers = [];

  /// Configuration for gesture recognition.
  GestureConfig get config => _config;

  /// Whether the gesture zone is enabled.
  bool get enabled => _enabled;

  /// Whether to show visual feedback.
  bool get showVisualFeedback => _showVisualFeedback;

  /// Currently active touch points.
  Map<int, TouchPoint> get activeTouchPoints =>
      Map.unmodifiable(_activeTouchPoints);

  /// Number of active touch points.
  int get activeTouchPointCount => _activeTouchPoints.length;

  /// Sets the configuration for gesture recognition.
  void setConfig(GestureConfig config) {
    _config = config;
    _recognition = GestureRecognition(config: config);
    // Defer notification to avoid calling during build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  /// Enables or disables the gesture zone.
  void setEnabled(bool enabled) {
    if (_enabled != enabled) {
      _enabled = enabled;
      if (!enabled) {
        _clearAllTouchPoints();
      }
      // Defer notification to avoid calling during build
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  /// Sets whether to show visual feedback.
  void setShowVisualFeedback(bool show) {
    if (_showVisualFeedback != show) {
      _showVisualFeedback = show;
      // Defer notification to avoid calling during build
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  /// Adds a callback for a specific gesture type.
  void addGestureCallback(GestureType type, GestureCallback callback) {
    _gestureCallbacks.putIfAbsent(type, () => []).add(callback);
  }

  /// Removes a callback for a specific gesture type.
  void removeGestureCallback(GestureType type, GestureCallback callback) {
    _gestureCallbacks[type]?.remove(callback);
  }

  /// Clears all callbacks for a specific gesture type.
  void clearGestureCallbacks(GestureType type) {
    _gestureCallbacks[type]?.clear();
  }

  /// Clears all gesture callbacks.
  void clearAllGestureCallbacks() {
    _gestureCallbacks.clear();
  }

  /// Sets a callback for all gestures.
  void setOnAnyGesture(GestureCallback? callback) {
    _onAnyGesture = callback;
  }

  /// Registers a custom gesture recognizer.
  ///
  /// Custom recognizers allow you to define your own gesture patterns
  /// by analyzing touch history. They are called during gesture recognition
  /// and can return a GestureResult if a custom pattern is detected.
  ///
  /// Example:
  /// ```dart
  /// controller.addCustomRecognizer((touchHistory) {
  ///   // Analyze touch history to detect custom pattern
  ///   if (touchHistory.length == 2) {
  ///     final points1 = touchHistory.values.first;
  ///     final points2 = touchHistory.values.last;
  ///     // Detect custom two-finger pattern
  ///     if (/* pattern detected */) {
  ///       return GestureResult(
  ///         type: GestureType.custom,
  ///         confidence: 0.9,
  ///         touchPoints: [points1.last, points2.last],
  ///         duration: points1.last.timestamp - points1.first.timestamp,
  ///         data: {'customPattern': 'detected'},
  ///       );
  ///     }
  ///   }
  ///   return null;
  /// });
  /// ```
  void addCustomRecognizer(CustomGestureRecognizer recognizer) {
    _recognition.addCustomRecognizer(recognizer);
    _customRecognizers.add(recognizer);
  }

  /// Removes a custom gesture recognizer.
  void removeCustomRecognizer(CustomGestureRecognizer recognizer) {
    _recognition.removeCustomRecognizer(recognizer);
    _customRecognizers.remove(recognizer);
  }

  /// Marks a pointer as part of a multi-touch gesture.
  /// This prevents tap detection on this pointer.
  void markMultiTouchPointer(int pointerId) {
    _multiTouchPointers.add(pointerId);
    _lastTwoFingerTime = DateTime.now();
    _lastMultiTouchTime = DateTime.now();
  }

  /// Clears all custom gesture recognizers.
  void clearCustomRecognizers() {
    _recognition.clearCustomRecognizers();
    _customRecognizers.clear();
  }

  /// Handles pointer down events.
  void handlePointerDown(PointerDownEvent event) {
    if (!_enabled) return;

    final touchPoint = TouchPoint.fromPointerDownEvent(
      event,
      Duration(milliseconds: event.timeStamp.inMilliseconds),
    );

    // Validate touch points (pressure sensitivity check)
    final allTouchPoints = [..._activeTouchPoints.values, touchPoint];
    if (!_recognition.validateTouchPoints(allTouchPoints)) {
      return;
    }

    _activeTouchPoints[event.pointer] = touchPoint;
    _touchHistory[event.pointer] = [touchPoint];

    // Start long press timer for single touch
    if (_activeTouchPoints.length == 1) {
      _startLongPressTimer(touchPoint);
    }

    // Detect multi-touch when second finger is placed
    // This should trigger IMMEDIATELY when 2 fingers are detected
    if (_activeTouchPoints.length == 2 && _config.enableMultiTouch) {
      // Record that we have 2 fingers active
      _lastTwoFingerTime = DateTime.now();
      _lastMultiTouchTime =
          DateTime.now(); // Also record multi-touch time immediately

      // Mark all current pointers as part of multi-touch
      _multiTouchPointers.addAll(_activeTouchPoints.keys);

      final multiTouchPoints = _activeTouchPoints.values.toList();
      const duration = Duration.zero; // Just started, no duration yet

      // Create a multi-touch gesture result
      final multiTouchResult = GestureResult(
        type: GestureType.multiTouch,
        confidence: 0.95, // Higher confidence for immediate detection
        touchPoints: multiTouchPoints,
        duration: duration,
        data: {
          'touchPointCount': multiTouchPoints.length,
          'center': _calculateCenter(
            multiTouchPoints[0].position,
            multiTouchPoints[1].position,
          ),
        },
      );
      _triggerGesture(multiTouchResult);

      // Start a timer to detect held multi-touch (if fingers stay down)
      _startMultiTouchTimer();
    } else if (_activeTouchPoints.length != 2) {
      // Cancel multi-touch timer if we don't have 2 fingers anymore
      _cancelMultiTouchTimer();
    }

    // Defer notification to avoid calling during build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  /// Handles pointer move events.
  void handlePointerMove(PointerMoveEvent event) {
    if (!_enabled || !_activeTouchPoints.containsKey(event.pointer)) return;

    final touchPoint = TouchPoint.fromPointerMoveEvent(
      event,
      Duration(milliseconds: event.timeStamp.inMilliseconds),
    );

    // Validate touch points (pressure sensitivity check)
    final allTouchPoints = [..._activeTouchPoints.values, touchPoint];
    if (!_recognition.validateTouchPoints(allTouchPoints)) {
      return;
    }

    _activeTouchPoints[event.pointer] = touchPoint;
    _touchHistory[event.pointer]!.add(touchPoint);

    // Cancel long press timer on movement
    _cancelLongPressTimer();

    // Recognize drag gesture
    if (_activeTouchPoints.length == 1) {
      final dragResult = _recognition.recognizeDragGesture(
        _touchHistory[event.pointer]!,
      );
      if (dragResult != null) {
        _triggerGesture(dragResult);
      }
    }

    // Recognize multi-touch gestures
    if (_activeTouchPoints.length == 2 && _config.enableMultiTouch) {
      // Record that we have 2 fingers active
      _lastTwoFingerTime = DateTime.now();
      _lastMultiTouchTime = DateTime.now();

      // Mark all current pointers as part of multi-touch
      _multiTouchPointers.addAll(_activeTouchPoints.keys);

      // Try to recognize pinch gesture first (takes precedence)
      // Pinch requires movement, so only check if we have enough history
      final pinchResult = _recognition.recognizePinchGesture(_touchHistory);
      if (pinchResult != null) {
        _triggerGesture(pinchResult);
        _cancelMultiTouchTimer(); // Cancel timer since we detected a specific gesture
      } else {
        // Try to recognize rotation gesture
        // Rotation requires movement, so only check if we have enough history
        final rotationResult = _recognition.recognizeRotationGesture(
          _touchHistory,
        );
        if (rotationResult != null) {
          _triggerGesture(rotationResult);
          _cancelMultiTouchTimer(); // Cancel timer since we detected a specific gesture
        } else {
          // If no pinch/rotation detected, trigger general multi-touch immediately
          // Use touch history to get proper duration
          final allTouchPoints = <TouchPoint>[];
          for (final history in _touchHistory.values) {
            if (history.isNotEmpty) {
              allTouchPoints.add(history.last);
            }
          }

          if (allTouchPoints.length == 2) {
            // Calculate duration from touch history
            final firstTouch = allTouchPoints
                .map((tp) => tp.timestamp)
                .reduce((a, b) => a < b ? a : b);
            final lastTouch = allTouchPoints
                .map((tp) => tp.timestamp)
                .reduce((a, b) => a > b ? a : b);
            final duration = lastTouch - firstTouch;

            // Trigger multi-touch immediately when moving (no delay needed)
            final multiTouchResult = GestureResult(
              type: GestureType.multiTouch,
              confidence: 0.9,
              touchPoints: allTouchPoints,
              duration: duration,
              data: {
                'touchPointCount': allTouchPoints.length,
                'center': _calculateCenter(
                  allTouchPoints[0].position,
                  allTouchPoints[1].position,
                ),
              },
            );
            _triggerGesture(multiTouchResult);

            // Record the time of multi-touch to prevent tap detection immediately after
            _lastMultiTouchTime = DateTime.now();
          }
        }
      }
    } else if (_activeTouchPoints.length != 2) {
      // Cancel multi-touch timer if we don't have 2 fingers anymore
      _cancelMultiTouchTimer();
    }

    // Try to recognize custom gestures
    _tryRecognizeCustomGestures();

    // Defer notification to avoid calling during build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  /// Handles pointer up events.
  void handlePointerUp(PointerUpEvent event) {
    if (!_enabled || !_activeTouchPoints.containsKey(event.pointer)) return;

    _cancelLongPressTimer();

    final touchPoints = _touchHistory[event.pointer]!;

    // CRITICAL: Check if this pointer was part of a multi-touch gesture
    // If so, completely block tap detection for this pointer
    final wasMultiTouchPointer = _multiTouchPointers.contains(event.pointer);

    // Detect multi-touch BEFORE removing the touch point
    // Check if we have 2 active touch points (this one + another)
    if (_activeTouchPoints.length == 2 && _config.enableMultiTouch) {
      // Record that we had 2 fingers active
      _lastTwoFingerTime = DateTime.now();
      _lastMultiTouchTime = DateTime.now();

      // Mark all current pointers as part of multi-touch
      _multiTouchPointers.addAll(_activeTouchPoints.keys);

      final multiTouchPoints = _activeTouchPoints.values.toList();
      // Calculate duration from the touch histories
      final allHistories = _touchHistory.values.toList();
      if (allHistories.length == 2 &&
          allHistories[0].isNotEmpty &&
          allHistories[1].isNotEmpty) {
        final firstTouch =
            allHistories[0].first.timestamp < allHistories[1].first.timestamp
            ? allHistories[0].first.timestamp
            : allHistories[1].first.timestamp;
        final lastTouch =
            allHistories[0].last.timestamp > allHistories[1].last.timestamp
            ? allHistories[0].last.timestamp
            : allHistories[1].last.timestamp;
        final duration = lastTouch - firstTouch;

        final multiTouchResult = GestureResult(
          type: GestureType.multiTouch,
          confidence: 0.9,
          touchPoints: multiTouchPoints,
          duration: duration,
          data: {
            'touchPointCount': multiTouchPoints.length,
            'center': _calculateCenter(
              multiTouchPoints[0].position,
              multiTouchPoints[1].position,
            ),
          },
        );
        _triggerGesture(multiTouchResult);

        // Clean up touch point
        _activeTouchPoints.remove(event.pointer);
        _touchHistory.remove(event.pointer);
        _cancelMultiTouchTimer(); // Cancel timer when finger is lifted
        // Defer notification to avoid calling during build
        SchedulerBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return; // Don't process tap gestures when multi-touch is detected
      }
    }

    // Recognize tap gestures (only if single touch)
    // IMPORTANT: Completely block taps if:
    // 1. This pointer was part of a multi-touch gesture
    // 2. We have 2 fingers active or recently had multi-touch
    if (_activeTouchPoints.length == 1 &&
        touchPoints.length == 1 &&
        !wasMultiTouchPointer) {
      final now = DateTime.now();
      final timeSinceMultiTouch = _lastMultiTouchTime != null
          ? now.difference(_lastMultiTouchTime!)
          : const Duration(days: 1);
      final timeSinceTwoFingers = _lastTwoFingerTime != null
          ? now.difference(_lastTwoFingerTime!)
          : const Duration(days: 1);

      // Skip tap detection if:
      // 1. Multi-touch happened recently (within 500ms)
      // 2. Two fingers were active recently (within 500ms)
      // This prevents false tap detection when spamming with 2 fingers
      if (timeSinceMultiTouch.inMilliseconds < 500 ||
          timeSinceTwoFingers.inMilliseconds < 500) {
        // Clean up touch point without triggering tap
        _activeTouchPoints.remove(event.pointer);
        _touchHistory.remove(event.pointer);
        // Defer notification to avoid calling during build
        SchedulerBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return;
      }

      final tapPoint = touchPoints.first;

      // Check for double tap
      if (_recognition.isDoubleTap(tapPoint, _previousTap)) {
        final doubleTapResult = GestureResult(
          type: GestureType.doubleTap,
          confidence: 1.0,
          touchPoints: [_previousTap!, tapPoint],
          duration: tapPoint.timestamp - _previousTap!.timestamp,
          data: {'position': tapPoint.position},
        );
        _triggerGesture(doubleTapResult);

        // Also trigger tap event for the second tap so it counts in custom gestures
        final secondTapResult = GestureResult(
          type: GestureType.tap,
          confidence: 1.0,
          touchPoints: [tapPoint],
          duration: Duration.zero,
          data: {'position': tapPoint.position},
        );
        _triggerGesture(secondTapResult);

        _previousTap = null;
      } else {
        // Single tap
        final tapResult = GestureResult(
          type: GestureType.tap,
          confidence: 1.0,
          touchPoints: [tapPoint],
          duration: Duration.zero,
          data: {'position': tapPoint.position},
        );
        _triggerGesture(tapResult);
        _previousTap = tapPoint;
      }
    }

    // Recognize swipe gestures
    if (touchPoints.length > 1) {
      final swipeResult = _recognition.recognizeSwipeGesture(touchPoints);
      if (swipeResult != null) {
        _triggerGesture(swipeResult);
      }
    }

    // Clean up touch point
    _activeTouchPoints.remove(event.pointer);
    _touchHistory.remove(event.pointer);

    // Defer notification to avoid calling during build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  /// Handles pointer cancel events.
  void handlePointerCancel(PointerCancelEvent event) {
    if (!_enabled) return;

    _cancelLongPressTimer();
    _cancelMultiTouchTimer();
    _activeTouchPoints.remove(event.pointer);
    _touchHistory.remove(event.pointer);
    // Defer notification to avoid calling during build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  /// Starts the long press timer.
  void _startLongPressTimer(TouchPoint touchPoint) {
    _cancelLongPressTimer();
    _longPressTimer = Timer(_config.longPressTime, () {
      if (_activeTouchPoints.length == 1 &&
          _activeTouchPoints.containsValue(touchPoint)) {
        final longPressResult = GestureResult(
          type: GestureType.longPress,
          confidence: 1.0,
          touchPoints: [touchPoint],
          duration: _config.longPressTime,
          data: {'position': touchPoint.position},
        );
        _triggerGesture(longPressResult);
      }
    });
  }

  /// Cancels the long press timer.
  void _cancelLongPressTimer() {
    _longPressTimer?.cancel();
    _longPressTimer = null;
  }

  /// Starts the multi-touch timer to detect held multi-touch.
  void _startMultiTouchTimer() {
    _cancelMultiTouchTimer();
    _multiTouchTimer = Timer(const Duration(milliseconds: 100), () {
      if (_activeTouchPoints.length == 2 && _config.enableMultiTouch) {
        final multiTouchPoints = _activeTouchPoints.values.toList();
        final allHistories = _touchHistory.values.toList();
        if (allHistories.length == 2 &&
            allHistories[0].isNotEmpty &&
            allHistories[1].isNotEmpty) {
          final firstTouch =
              allHistories[0].first.timestamp < allHistories[1].first.timestamp
              ? allHistories[0].first.timestamp
              : allHistories[1].first.timestamp;
          final lastTouch =
              allHistories[0].last.timestamp > allHistories[1].last.timestamp
              ? allHistories[0].last.timestamp
              : allHistories[1].last.timestamp;
          final duration = lastTouch - firstTouch;

          final multiTouchResult = GestureResult(
            type: GestureType.multiTouch,
            confidence: 0.9,
            touchPoints: multiTouchPoints,
            duration: duration,
            data: {
              'touchPointCount': multiTouchPoints.length,
              'center': _calculateCenter(
                multiTouchPoints[0].position,
                multiTouchPoints[1].position,
              ),
            },
          );
          _triggerGesture(multiTouchResult);

          // Record the time of multi-touch to prevent tap detection immediately after
          _lastMultiTouchTime = DateTime.now();
        }
      }
    });
  }

  /// Cancels the multi-touch timer.
  void _cancelMultiTouchTimer() {
    _multiTouchTimer?.cancel();
    _multiTouchTimer = null;
  }

  /// Clears all active touch points.
  void _clearAllTouchPoints() {
    _cancelLongPressTimer();
    _cancelMultiTouchTimer();
    _activeTouchPoints.clear();
    _touchHistory.clear();
    _multiTouchPointers.clear(); // Clear multi-touch pointer tracking
  }

  /// Calculates the center point between two points.
  Offset _calculateCenter(Offset point1, Offset point2) {
    return Offset((point1.dx + point2.dx) / 2, (point1.dy + point2.dy) / 2);
  }

  /// Tries to recognize custom gestures from current touch history.
  void _tryRecognizeCustomGestures() {
    if (_customRecognizers.isEmpty) return;

    final customResult = _recognition.recognizeCustomGestures(_touchHistory);
    if (customResult != null) {
      _triggerGesture(customResult);
    }
  }

  /// Triggers gesture callbacks.
  void _triggerGesture(GestureResult result) {
    // Call specific gesture callbacks
    final callbacks = _gestureCallbacks[result.type];
    if (callbacks != null) {
      for (final callback in callbacks) {
        callback(result);
      }
    }

    // Call general gesture callback
    _onAnyGesture?.call(result);
  }

  /// Resets the controller state.
  void reset() {
    _clearAllTouchPoints();
    _previousTap = null;
    _enabled = true;
    _showVisualFeedback = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelLongPressTimer();
    _cancelMultiTouchTimer();
    _clearAllTouchPoints();
    super.dispose();
  }
}
