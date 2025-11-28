// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Debug screen for testing keyboard and mouse events.
///
/// This screen helps diagnose event handling issues by showing
/// exactly what events are being received by Flutter.
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EventDebugScreen extends StatefulWidget {
  const EventDebugScreen({super.key});

  @override
  State<EventDebugScreen> createState() => _EventDebugScreenState();
}

class _EventDebugScreenState extends State<EventDebugScreen> {
  final List<String> _eventLog = [];
  final FocusNode _focusNode = FocusNode();
  int _eventCounter = 0;

  // Keyboard state tracking
  bool _isShiftPressed = false;
  bool _isAltPressed = false;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _logEvent(String event) {
    // Print to console/terminal so we can see it
    print(event);

    setState(() {
      _eventCounter++;
      _eventLog.insert(0, '[$_eventCounter] $event');
      if (_eventLog.length > 50) {
        _eventLog.removeLast();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Debug Screen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _eventLog.clear();
                _eventCounter = 0;
              });
            },
            tooltip: 'Clear Log',
          ),
        ],
      ),
      body: Row(
        children: [
          // Main test area
          Expanded(
            flex: 2,
            child: Listener(
              onPointerSignal: (signal) {
                if (signal is PointerScrollEvent) {
                  final delta = signal.scrollDelta;

                  print('═══════════════════════════════════════');
                  print('🖱️  SCROLL EVENT:');
                  print('   Delta: dx=${delta.dx.toStringAsFixed(1)}, dy=${delta.dy.toStringAsFixed(1)}');
                  print('   ✅ Manual SHIFT tracking: $_isShiftPressed');
                  print('   ✅ Manual ALT tracking: $_isAltPressed');
                  print('═══════════════════════════════════════');

                  _logEvent(
                    '🖱️  SCROLL: dx=${delta.dx.toStringAsFixed(1)}, '
                    'dy=${delta.dy.toStringAsFixed(1)} | '
                    'SHIFT=$_isShiftPressed, ALT=$_isAltPressed',
                  );
                }
              },
              onPointerDown: (event) {
                _logEvent(
                  '👆 POINTER DOWN: button=${event.buttons}, '
                  'pos=(${event.localPosition.dx.toInt()}, ${event.localPosition.dy.toInt()})',
                );
                // Request focus when clicked
                _focusNode.requestFocus();
              },
              onPointerMove: (event) {
                // Don't log every move, too noisy
              },
              onPointerHover: (event) {
                // Don't log every hover, too noisy
              },
              child: Focus(
                focusNode: _focusNode,
                onKeyEvent: (node, event) {
                  final keyLabel = event.logicalKey.keyLabel;
                  final eventType = event.runtimeType.toString();

                  // Manually track SHIFT and ALT state from keyboard events
                  if (event.logicalKey == LogicalKeyboardKey.shiftLeft || event.logicalKey == LogicalKeyboardKey.shiftRight) {
                    setState(() {
                      _isShiftPressed = event is KeyDownEvent || event is KeyRepeatEvent;
                    });
                    print('🔵 MANUAL SHIFT TRACKING: $_isShiftPressed (from $eventType)');
                  }
                  if (event.logicalKey == LogicalKeyboardKey.altLeft || event.logicalKey == LogicalKeyboardKey.altRight) {
                    setState(() {
                      _isAltPressed = event is KeyDownEvent || event is KeyRepeatEvent;
                    });
                    print('� MANUAL ALT TRACKING: $_isAltPressed (from $eventType)');
                  }

                  print('═══════════════════════════════════════');
                  print('🔑 KEY EVENT:');
                  print('   Type: $eventType');
                  print('   Key: $keyLabel');
                  print('   Logical Key: ${event.logicalKey}');

                  _logEvent('🔑 KEY: $eventType - $keyLabel');

                  // Log specific keys we care about
                  if (event.logicalKey == LogicalKeyboardKey.equal ||
                      event.logicalKey == LogicalKeyboardKey.add ||
                      event.logicalKey == LogicalKeyboardKey.numpadAdd) {
                    _logEvent('   ✅ PLUS/ADD KEY DETECTED');
                    print('   ✅✅✅ PLUS/ADD KEY DETECTED! ✅✅✅');
                  }
                  if (event.logicalKey == LogicalKeyboardKey.minus || event.logicalKey == LogicalKeyboardKey.numpadSubtract) {
                    _logEvent('   ✅ MINUS/SUBTRACT KEY DETECTED');
                    print('   ✅✅✅ MINUS/SUBTRACT KEY DETECTED! ✅✅✅');
                  }
                  if (event.logicalKey == LogicalKeyboardKey.shiftLeft || event.logicalKey == LogicalKeyboardKey.shiftRight) {
                    _logEvent('   ✅ SHIFT KEY DETECTED');
                    print('   ✅✅✅ SHIFT KEY DETECTED! ✅✅✅');
                  }

                  print('   Focus: ${node.hasFocus}');
                  print('═══════════════════════════════════════');

                  // Return ignored so scroll events can still reach the Listener
                  return KeyEventResult.ignored;
                },
                child: Container(
                  color: Colors.blue.shade50,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: _focusNode.hasFocus ? Colors.green.shade100 : Colors.red.shade100,
                            border: Border.all(
                              color: _focusNode.hasFocus ? Colors.green : Colors.red,
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                _focusNode.hasFocus ? Icons.check_circle : Icons.cancel,
                                size: 64,
                                color: _focusNode.hasFocus ? Colors.green : Colors.red,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _focusNode.hasFocus ? 'FOCUSED ✓' : 'NOT FOCUSED ✗',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: _focusNode.hasFocus ? Colors.green : Colors.red,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Click here to focus',
                                style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'Test Actions:',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        const Text('• Click this area to give it focus'),
                        const Text('• Press + or - keys to test zoom'),
                        const Text('• CTRL + Scroll to test zoom'),
                        const Text('• SHIFT + Scroll to test pan'),
                        const Text('• Arrow keys to test navigation'),
                      ],
                    ),
                  ),
                ),
              ), // Focus
            ), // Listener
          ), // Expanded
          // Control panel
          Container(
            width: 400,
            color: Colors.grey.shade100,
            child: Column(
              children: [
                // Modifier key status
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.blue.shade100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '⌨️  Modifier Keys (for zoom):',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _buildKeyStatus('SHIFT', _isShiftPressed),
                      _buildKeyStatus('ALT', _isAltPressed),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Focus status
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: _focusNode.hasFocus ? Colors.green.shade50 : Colors.red.shade50,
                  child: Row(
                    children: [
                      Icon(
                        _focusNode.hasFocus ? Icons.lens : Icons.lens_outlined,
                        color: _focusNode.hasFocus ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Focus: ${_focusNode.hasFocus ? "ACTIVE" : "INACTIVE"}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _focusNode.hasFocus ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Event log
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '📋 Event Log:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '$_eventCounter events',
                        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _eventLog.isEmpty
                        ? const Center(
                            child: Text(
                              'No events yet...\nClick the test area and try interactions',
                              style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.builder(
                            itemCount: _eventLog.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  _eventLog[index],
                                  style: const TextStyle(
                                    color: Color(0xFF00FF00),
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyStatus(String label, bool isPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: isPressed ? Colors.green : Colors.grey.shade400,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: isPressed ? FontWeight.bold : FontWeight.normal,
              color: isPressed ? Colors.green.shade900 : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
