/// Enumeration of all supported gesture types.
enum GestureType {
  /// Single tap gesture
  tap,

  /// Double tap gesture
  doubleTap,

  /// Long press gesture
  longPress,

  /// Drag gesture (pan)
  drag,

  /// Pinch to zoom gesture
  pinch,

  /// Rotation gesture
  rotation,

  /// Swipe gesture in any direction
  swipe,

  /// Swipe up gesture
  swipeUp,

  /// Swipe down gesture
  swipeDown,

  /// Swipe left gesture
  swipeLeft,

  /// Swipe right gesture
  swipeRight,

  /// Multi-touch gesture with custom logic
  multiTouch,

  /// Custom gesture defined by the user
  custom,
}

/// Extension to provide additional functionality for GestureType.
extension GestureTypeExtension on GestureType {
  /// Returns a human-readable name for the gesture type.
  String get displayName {
    switch (this) {
      case GestureType.tap:
        return 'Tap';
      case GestureType.doubleTap:
        return 'Double Tap';
      case GestureType.longPress:
        return 'Long Press';
      case GestureType.drag:
        return 'Drag';
      case GestureType.pinch:
        return 'Pinch';
      case GestureType.rotation:
        return 'Rotation';
      case GestureType.swipe:
        return 'Swipe';
      case GestureType.swipeUp:
        return 'Swipe Up';
      case GestureType.swipeDown:
        return 'Swipe Down';
      case GestureType.swipeLeft:
        return 'Swipe Left';
      case GestureType.swipeRight:
        return 'Swipe Right';
      case GestureType.multiTouch:
        return 'Multi Touch';
      case GestureType.custom:
        return 'Custom';
    }
  }

  /// Returns whether this gesture type requires multiple touch points.
  bool get isMultiTouch {
    switch (this) {
      case GestureType.pinch:
      case GestureType.rotation:
      case GestureType.multiTouch:
        return true;
      default:
        return false;
    }
  }

  /// Returns whether this gesture type is a swipe variant.
  bool get isSwipe {
    switch (this) {
      case GestureType.swipe:
      case GestureType.swipeUp:
      case GestureType.swipeDown:
      case GestureType.swipeLeft:
      case GestureType.swipeRight:
        return true;
      default:
        return false;
    }
  }
}
