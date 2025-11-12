import 'package:flutter/material.dart';
import 'package:flutter_gesture_zone/flutter_gesture_zone.dart';

void main() {
  runApp(const GestureZoneExampleApp());
}

class GestureZoneExampleApp extends StatelessWidget {
  const GestureZoneExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Gesture Zone Example',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const GestureZoneExamplePage(),
    );
  }
}

class GestureZoneExamplePage extends StatefulWidget {
  const GestureZoneExamplePage({super.key});

  @override
  State<GestureZoneExamplePage> createState() => _GestureZoneExamplePageState();
}

class _GestureZoneExamplePageState extends State<GestureZoneExamplePage> {
  final List<String> _gestureLog = [];
  late GestureZoneController _controller;
  bool _showVisualFeedback = false;
  bool _enabled = true;
  GestureConfig _currentConfig = GestureConfig.defaultConfig();
  String _configName = 'Default';

  // Track recent taps for custom gesture recognition
  final List<TouchPoint> _recentTaps = [];

  @override
  void initState() {
    super.initState();
    _controller = GestureZoneController(config: _currentConfig);

    // Track taps for custom gesture recognition
    // IMPORTANT: Only track taps if we don't have multi-touch active
    _controller.addGestureCallback(GestureType.tap, (result) {
      // Don't track taps if multi-touch was recently detected
      // Check if we currently have 2 active touch points
      if (_controller.activeTouchPointCount >= 2) {
        // Clear recent taps if multi-touch is active
        _recentTaps.clear();
        return;
      }

      final tapPoint = result.touchPoints.first;
      _recentTaps.add(tapPoint);

      // Keep only taps from the last 1 second
      final now = tapPoint.timestamp;
      _recentTaps.removeWhere(
          (tap) => (now.inMilliseconds - tap.timestamp.inMilliseconds) > 1000);

      // If we have 3 or more taps within 1 second, detect the pattern
      if (_recentTaps.length >= 3) {
        final firstTap = _recentTaps[_recentTaps.length - 3];
        final lastTap = _recentTaps.last;
        final duration = Duration(
          milliseconds: lastTap.timestamp.inMilliseconds -
              firstTap.timestamp.inMilliseconds,
        );

        if (duration.inMilliseconds < 1000) {
          // Get the 3 taps that form the pattern
          final patternTaps = List<TouchPoint>.from(
              _recentTaps.sublist(_recentTaps.length - 3));

          // Clear recent taps after detection
          _recentTaps.clear();

          // Create custom gesture result
          final customResult = GestureResult(
            type: GestureType.custom,
            confidence: 0.9,
            touchPoints: patternTaps,
            duration: duration,
            data: {
              'pattern': 'Triangle Pattern',
              'tapCount': 3,
            },
          );

          // Log the custom gesture detection
          final pattern = customResult.data['pattern'] as String?;
          final tapCount = customResult.data['tapCount'] as int?;
          _addToLog('Custom: $pattern (taps: $tapCount)');
        }
      }
    });

    // Clear recent taps when multi-touch is detected
    _controller.addGestureCallback(GestureType.multiTouch, (result) {
      _recentTaps.clear(); // Clear tap history when multi-touch is detected
    });

    // Add custom gesture callback to controller
    // This will be called along with the widget's onCustom callback
    _controller.addGestureCallback(GestureType.custom, (result) {
      final pattern = result.data['pattern'] as String?;
      final tapCount = result.data['tapCount'] as int?;
      if (pattern != null && tapCount != null) {
        _addToLog('Custom: $pattern (taps: $tapCount)');
      }
    });

    // Add custom gesture recognizer - detects triangle pattern (3 taps quickly)
    _controller.addCustomRecognizer((touchHistory) {
      // This recognizer can be used for other custom patterns
      // The 3-tap pattern is handled via tap callback above
      return null;
    });
  }

  void _addToLog(String message) {
    setState(() {
      _gestureLog.insert(
        0,
        '${DateTime.now().toString().substring(11, 19)}: $message',
      );
      if (_gestureLog.length > 30) {
        _gestureLog.removeLast();
      }
    });
  }

  void _changeConfig(GestureConfig config, String name) {
    setState(() {
      _currentConfig = config;
      _configName = name;
      _controller.setConfig(config);
      _addToLog('Config changed to: $name');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Gesture Zone Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings),
            tooltip: 'Configuration',
            onSelected: (value) {
              switch (value) {
                case 'default':
                  _changeConfig(GestureConfig.defaultConfig(), 'Default');
                  break;
                case 'precise':
                  _changeConfig(GestureConfig.precise(), 'Precise');
                  break;
                case 'relaxed':
                  _changeConfig(GestureConfig.relaxed(), 'Relaxed');
                  break;
                case 'pressure':
                  _changeConfig(
                    const GestureConfig(
                      enablePressureSensitivity: true,
                      minPressure: 0.3,
                    ),
                    'Pressure Sensitive',
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'default',
                child: Text('Default Config'),
              ),
              const PopupMenuItem(
                value: 'precise',
                child: Text('Precise Config'),
              ),
              const PopupMenuItem(
                value: 'relaxed',
                child: Text('Relaxed Config'),
              ),
              const PopupMenuItem(
                value: 'pressure',
                child: Text('Pressure Sensitive'),
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              _showVisualFeedback ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: () {
              setState(() {
                _showVisualFeedback = !_showVisualFeedback;
                _controller.setShowVisualFeedback(_showVisualFeedback);
              });
            },
            tooltip: 'Toggle Visual Feedback',
          ),
          IconButton(
            icon: Icon(_enabled ? Icons.touch_app : Icons.touch_app_outlined),
            onPressed: () {
              setState(() {
                _enabled = !_enabled;
                _controller.setEnabled(_enabled);
              });
            },
            tooltip: 'Toggle Enabled',
          ),
        ],
      ),
      body: Row(
        children: [
          // Left side - Gesture zones
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Config info
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline),
                          const SizedBox(width: 8),
                          Text(
                            'Current Config: $_configName',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Basic gestures
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Basic Gestures',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text('Tap, double tap, long press'),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 150,
                            child: GestureZone(
                              onTap: (result) => _addToLog(
                                'Tap at ${result.data['position']}',
                              ),
                              onDoubleTap: (result) => _addToLog('Double tap!'),
                              onLongPress: (result) => _addToLog('Long press!'),
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Tap, double tap, or long press me!',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Swipe gestures
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Swipe Gestures (Velocity Recognition)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text('Swipe in any direction'),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 150,
                            child: GestureZone(
                              onSwipeUp: (result) => _addToLog(
                                'Swipe up (velocity: ${result.data['velocity']?.toStringAsFixed(1)})',
                              ),
                              onSwipeDown: (result) => _addToLog(
                                'Swipe down (distance: ${result.data['distance']?.toStringAsFixed(1)})',
                              ),
                              onSwipeLeft: (result) => _addToLog('Swipe left'),
                              onSwipeRight: (result) =>
                                  _addToLog('Swipe right'),
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green),
                                ),
                                child: const Center(
                                  child: Text('Swipe in any direction!'),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Multi-touch gestures
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Multi-touch Gestures',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text('Pinch and rotate with two fingers'),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 150,
                            child: GestureZone(
                              controller: _controller,
                              showVisualFeedback: _showVisualFeedback,
                              onPinch: (result) {
                                final scaleFactor =
                                    result.data['scaleFactor'] as double;
                                final isZoomIn =
                                    result.data['isZoomIn'] as bool;
                                _addToLog(
                                  'Pinch: ${isZoomIn ? 'zoom in' : 'zoom out'} (scale: ${scaleFactor.toStringAsFixed(2)})',
                                );
                              },
                              onRotation: (result) {
                                final angle =
                                    result.data['rotationAngle'] as double;
                                _addToLog(
                                  'Rotation: ${angle.toStringAsFixed(2)} radians',
                                );
                              },
                              onMultiTouch: (result) {
                                _addToLog(
                                  'Multi-touch: ${result.touchPoints.length} fingers',
                                );
                              },
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Pinch or rotate with two fingers!',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Drag gesture
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Drag Gesture',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text('Drag to move (with velocity tracking)'),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 150,
                            child: GestureZone(
                              onDrag: (result) {
                                final delta = result.data['delta'] as Offset;
                                final velocity =
                                    result.data['velocity'] as double?;
                                _addToLog(
                                  'Drag: delta (${delta.dx.toStringAsFixed(1)}, ${delta.dy.toStringAsFixed(1)})${velocity != null ? ', velocity: ${velocity.toStringAsFixed(1)}' : ''}',
                                );
                              },
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.purple.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.purple),
                                ),
                                child: const Center(
                                  child: Text('Drag me around!'),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Custom gesture
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Custom Gesture Recognition',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tap 3 times quickly to detect triangle pattern',
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 150,
                            child: GestureZone(
                              controller: _controller,
                              onCustom: (result) {
                                final pattern =
                                    result.data['pattern'] as String?;
                                final tapCount =
                                    result.data['tapCount'] as int?;
                                _addToLog(
                                  'Custom: $pattern (taps: $tapCount)',
                                );
                              },
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Tap 3 times quickly!',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Extension methods example
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Extension Methods API',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text('Using extension methods for quick setup'),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 150,
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.teal.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.teal),
                              ),
                              child: const Center(
                                child: Text('Extension methods example'),
                              ),
                            )
                                .onTap((result) => _addToLog('Extension: Tap'))
                                .onSwipeUp(
                                  (result) => _addToLog('Extension: Swipe Up'),
                                )
                                .onPinch(
                                  (result) => _addToLog('Extension: Pinch'),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right side - Gesture log
          Expanded(
            flex: 1,
            child: Card(
              margin: const EdgeInsets.all(16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Gesture Log',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _gestureLog.clear();
                            });
                          },
                          tooltip: 'Clear Log',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: ListView.builder(
                          itemCount: _gestureLog.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                _gestureLog[index],
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
