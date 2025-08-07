import 'dart:async';
import 'package:flutter/material.dart';
import 'gesture_types.dart';
import 'gesture_config.dart';
import 'gesture_recognition.dart';
import 'touch_point.dart';

/// Callback function for gesture events.
typedef GestureCallback = void Function(GestureResult result);

/// Controller for managing gesture zone behavior and state.
class GestureZoneController extends ChangeNotifier {
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

  /// Previous tap for double tap detection.
  TouchPoint? _previousTap;

  /// Whether the gesture zone is enabled.
  bool _enabled = true;

  /// Whether to show visual feedback.
  bool _showVisualFeedback = false;

  /// Callbacks for different gesture types.
  final Map<GestureType, List<GestureCallback>> _gestureCallbacks = {};

  /// Callback for all gestures.
  GestureCallback? _onAnyGesture;

  GestureZoneController({GestureConfig? config})
      : _config = config ?? GestureConfig.defaultConfig() {
    _recognition = GestureRecognition(config: _config);
  }

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
    notifyListeners();
  }

  /// Enables or disables the gesture zone.
  void setEnabled(bool enabled) {
    if (_enabled != enabled) {
      _enabled = enabled;
      if (!enabled) {
        _clearAllTouchPoints();
      }
      notifyListeners();
    }
  }

  /// Sets whether to show visual feedback.
  void setShowVisualFeedback(bool show) {
    if (_showVisualFeedback != show) {
      _showVisualFeedback = show;
      notifyListeners();
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

  /// Sets a callback for all gestures.
  void setOnAnyGesture(GestureCallback? callback) {
    _onAnyGesture = callback;
  }

  /// Handles pointer down events.
  void handlePointerDown(PointerDownEvent event) {
    if (!_enabled) return;

    final touchPoint = TouchPoint.fromPointerDownEvent(
      event,
      Duration(milliseconds: event.timeStamp.inMilliseconds),
    );

    _activeTouchPoints[event.pointer] = touchPoint;
    _touchHistory[event.pointer] = [touchPoint];

    // Start long press timer for single touch
    if (_activeTouchPoints.length == 1) {
      _startLongPressTimer(touchPoint);
    }

    notifyListeners();
  }

  /// Handles pointer move events.
  void handlePointerMove(PointerMoveEvent event) {
    if (!_enabled || !_activeTouchPoints.containsKey(event.pointer)) return;

    final touchPoint = TouchPoint.fromPointerMoveEvent(
      event,
      Duration(milliseconds: event.timeStamp.inMilliseconds),
    );

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
    if (_activeTouchPoints.length == 2) {
      final multiTouchPoints = _activeTouchPoints.values.toList();
      final result = _recognition.recognizeGesture(multiTouchPoints);
      if (result != null) {
        _triggerGesture(result);
      }
    }

    notifyListeners();
  }

  /// Handles pointer up events.
  void handlePointerUp(PointerUpEvent event) {
    if (!_enabled || !_activeTouchPoints.containsKey(event.pointer)) return;

    _cancelLongPressTimer();

    final touchPoints = _touchHistory[event.pointer]!;

    // Recognize tap gestures
    if (_activeTouchPoints.length == 1 && touchPoints.length == 1) {
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

    notifyListeners();
  }

  /// Handles pointer cancel events.
  void handlePointerCancel(PointerCancelEvent event) {
    if (!_enabled) return;

    _cancelLongPressTimer();
    _activeTouchPoints.remove(event.pointer);
    _touchHistory.remove(event.pointer);
    notifyListeners();
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

  /// Clears all active touch points.
  void _clearAllTouchPoints() {
    _cancelLongPressTimer();
    _activeTouchPoints.clear();
    _touchHistory.clear();
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
    _clearAllTouchPoints();
    super.dispose();
  }
}
