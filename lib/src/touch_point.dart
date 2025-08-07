import 'package:flutter/material.dart';

/// Represents a single touch point with position, pressure, and timing information.
class TouchPoint {
  /// The unique identifier for this touch point.
  final int pointerId;

  /// The current position of the touch point.
  final Offset position;

  /// The pressure of the touch (0.0 to 1.0).
  final double pressure;

  /// The timestamp when this touch point was created.
  final Duration timestamp;

  /// The radius of the touch point.
  final double radius;

  /// The radius of the major axis of the touch point.
  final double radiusMajor;

  /// The radius of the minor axis of the touch point.
  final double radiusMinor;

  /// The orientation of the touch point in radians.
  final double orientation;

  const TouchPoint({
    required this.pointerId,
    required this.position,
    this.pressure = 1.0,
    required this.timestamp,
    this.radius = 0.0,
    this.radiusMajor = 0.0,
    this.radiusMinor = 0.0,
    this.orientation = 0.0,
  });

  /// Creates a TouchPoint from a PointerDownEvent.
  factory TouchPoint.fromPointerDownEvent(
    PointerDownEvent event,
    Duration timestamp,
  ) {
    return TouchPoint(
      pointerId: event.pointer,
      position: event.position,
      pressure: event.pressure,
      timestamp: timestamp,
      radius: 0.0, // Default radius for PointerDownEvent
      radiusMajor: 0.0, // Default radiusMajor for PointerDownEvent
      radiusMinor: 0.0, // Default radiusMinor for PointerDownEvent
      orientation: 0.0, // Default orientation for PointerDownEvent
    );
  }

  /// Creates a TouchPoint from a PointerMoveEvent.
  factory TouchPoint.fromPointerMoveEvent(
    PointerMoveEvent event,
    Duration timestamp,
  ) {
    return TouchPoint(
      pointerId: event.pointer,
      position: event.position,
      pressure: event.pressure,
      timestamp: timestamp,
      radius: 0.0, // Default radius for PointerMoveEvent
      radiusMajor: 0.0, // Default radiusMajor for PointerMoveEvent
      radiusMinor: 0.0, // Default radiusMinor for PointerMoveEvent
      orientation: 0.0, // Default orientation for PointerMoveEvent
    );
  }

  /// Creates a copy of this TouchPoint with updated values.
  TouchPoint copyWith({
    int? pointerId,
    Offset? position,
    double? pressure,
    Duration? timestamp,
    double? radius,
    double? radiusMajor,
    double? radiusMinor,
    double? orientation,
  }) {
    return TouchPoint(
      pointerId: pointerId ?? this.pointerId,
      position: position ?? this.position,
      pressure: pressure ?? this.pressure,
      timestamp: timestamp ?? this.timestamp,
      radius: radius ?? this.radius,
      radiusMajor: radiusMajor ?? this.radiusMajor,
      radiusMinor: radiusMinor ?? this.radiusMinor,
      orientation: orientation ?? this.orientation,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TouchPoint &&
        other.pointerId == pointerId &&
        other.position == position &&
        other.pressure == pressure &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(pointerId, position, pressure, timestamp);
  }

  @override
  String toString() {
    return 'TouchPoint(pointerId: $pointerId, position: $position, pressure: $pressure)';
  }
}
