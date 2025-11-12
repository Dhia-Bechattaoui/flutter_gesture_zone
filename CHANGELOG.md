# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2025-11-12

### Added
- Integrated `ScaleGestureRecognizer` for reliable multi-touch detection
- Enhanced multi-touch detection with pointer tracking to prevent false tap detection
- Improved pinch and rotation gesture recognition with better algorithms
- Added `markMultiTouchPointer()` method to controller for better multi-touch handling
- Comprehensive pointer tracking to prevent tap detection during multi-touch gestures
- Added example GIF to README.md
- Added `clearGestureCallbacks()` and `clearAllGestureCallbacks()` methods to controller

### Fixed
- Fixed multi-touch detection not working reliably
- Fixed pinch and rotation gestures not being detected properly
- Fixed false tap detection when using 2 fingers (triangle pattern issue)
- Fixed `setState()` during build errors when toggling enabled/visual feedback
- Fixed RenderFlex overflow in gesture log header
- Improved tap blocking logic to prevent interference with multi-touch gestures
- Fixed duplicate callback logging in example app (callbacks accumulating on rebuilds)
- Fixed custom 3-tap gesture requiring 5 taps instead of 3 (double-tap consuming second tap)
- Fixed callback accumulation when widget rebuilds (now properly removes old callbacks before adding new ones)

### Changed
- Rewrote pinch gesture recognition from scratch with improved distance calculation
- Rewrote rotation gesture recognition from scratch with center-based angle calculation
- Enhanced multi-touch detection to work immediately on finger placement
- Improved tap prevention logic with 500ms blocking window after multi-touch
- Updated custom gesture tracking to ignore taps during multi-touch
- Deferred `notifyListeners()` calls to prevent build phase errors
- Improved callback management in `GestureZone` widget to prevent duplicates
- Double-tap now also triggers tap event for the second tap (for custom gesture compatibility)

### Technical Improvements
- Added `ScaleGestureRecognizer` integration for native Flutter multi-touch support
- Improved gesture recognition algorithms with better validation
- Enhanced pointer tracking with `_multiTouchPointers` set
- Better timestamp tracking for multi-touch gestures
- Improved angle normalization for rotation gestures
- Added widget callback tracking to prevent duplicate registrations

## [0.0.4] - 2024-01-01

### Fixed
- Updated README.md to reflect current package version
- Ensured version consistency across all documentation

### Changed
- Improved documentation version alignment

## [0.0.3] - 2024-01-01

### Fixed
- Fixed remaining Dart formatting issues in gesture_recognition.dart and gesture_zone_controller.dart
- Resolved all static analysis formatting warnings
- Ensured complete compliance with Dart formatter standards

### Changed
- Improved code formatting consistency across all source files
- Enhanced static analysis score to 50/50 points

## [0.0.2] - 2024-01-01

### Fixed
- Fixed Dart formatting issues across all source files
- Resolved static analysis warnings and linting issues
- Added proper CHANGELOG.md following Keep a Changelog format

### Changed
- Improved code formatting and consistency
- Enhanced package documentation structure

## [0.0.1] - 2024-01-01

### Added
- Initial release of flutter_gesture_zone package
- GestureZone widget for advanced gesture recognition
- Support for multiple gesture types: tap, double tap, long press, drag, swipe, pinch, and rotation
- Configurable gesture recognition parameters
- Multi-touch gesture support
- Velocity-based gesture recognition
- Pressure sensitivity support (when available)
- GestureZoneController for programmatic control
- Comprehensive gesture configuration options

### Features
- Customizable gesture thresholds and timing
- Factory constructors for common use cases (default, precise, relaxed)
- Immutable configuration with copyWith support
- Touch point tracking and management
- Gesture state management and callbacks

[Unreleased]: https://github.com/dhia-bechattaoui/flutter_gesture_zone/compare/0.1.0...HEAD
[0.1.0]: https://github.com/dhia-bechattaoui/flutter_gesture_zone/compare/0.0.4...0.1.0
[0.0.4]: https://github.com/dhia-bechattaoui/flutter_gesture_zone/compare/0.0.3...0.0.4
[0.0.3]: https://github.com/dhia-bechattaoui/flutter_gesture_zone/compare/0.0.2...0.0.3
[0.0.2]: https://github.com/dhia-bechattaoui/flutter_gesture_zone/compare/0.0.1...0.0.2
[0.0.1]: https://github.com/dhia-bechattaoui/flutter_gesture_zone/releases/tag/0.0.1