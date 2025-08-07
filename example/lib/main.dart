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

  @override
  void initState() {
    super.initState();
    _controller = GestureZoneController(config: GestureConfig.precise());

    // Add controller callback
    _controller.setOnAnyGesture((result) {
      _addToLog('Controller: ${result.type.displayName}');
    });
  }

  void _addToLog(String message) {
    setState(() {
      _gestureLog.insert(
        0,
        '${DateTime.now().toString().substring(11, 19)}: $message',
      );
      if (_gestureLog.length > 20) {
        _gestureLog.removeLast();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Gesture Zone Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
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
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Basic gestures
                  Expanded(
                    child: Card(
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
                            Expanded(
                              child: GestureZone(
                                onTap: (result) => _addToLog(
                                  'Tap at ${result.data['position']}',
                                ),
                                onDoubleTap: (result) =>
                                    _addToLog('Double tap!'),
                                onLongPress: (result) =>
                                    _addToLog('Long press!'),
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
                  ),
                  const SizedBox(height: 16),

                  // Swipe gestures
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Swipe Gestures',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text('Swipe in any direction'),
                            const SizedBox(height: 16),
                            Expanded(
                              child: GestureZone(
                                onSwipeUp: (result) => _addToLog(
                                  'Swipe up (velocity: ${result.data['velocity']?.toStringAsFixed(1)})',
                                ),
                                onSwipeDown: (result) => _addToLog(
                                  'Swipe down (distance: ${result.data['distance']?.toStringAsFixed(1)})',
                                ),
                                onSwipeLeft: (result) =>
                                    _addToLog('Swipe left'),
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
                  ),
                ],
              ),
            ),
          ),

          // Right side - Multi-touch and log
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Multi-touch gestures
                  Expanded(
                    child: Card(
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
                            Expanded(
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
                  ),
                  const SizedBox(height: 16),

                  // Drag gesture
                  Expanded(
                    child: Card(
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
                            const Text('Drag to move'),
                            const SizedBox(height: 16),
                            Expanded(
                              child: GestureZone(
                                onDrag: (result) {
                                  final delta = result.data['delta'] as Offset;
                                  _addToLog(
                                    'Drag: delta (${delta.dx.toStringAsFixed(1)}, ${delta.dy.toStringAsFixed(1)})',
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
                  ),
                ],
              ),
            ),
          ),

          // Rightmost side - Gesture log
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
                        const Text(
                          'Gesture Log',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
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
