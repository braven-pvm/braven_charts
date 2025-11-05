/// Isolated test case for nested MouseRegion with opaque parameter
///
/// This test validates whether setting `opaque: false` on a parent MouseRegion
/// allows child MouseRegions to receive hover events.
///
/// Test scenarios:
/// 1. Parent opaque: true (default) - child should NOT receive events
/// 2. Parent opaque: false - child SHOULD receive events
///
/// Expected behavior with opaque: false:
/// - Cursor changes to resize arrows when hovering blue box
/// - Console shows "CHILD: Mouse ENTER" when entering blue box
/// - Console shows "CHILD: Mouse EXIT" when leaving blue box
/// - Console shows "PARENT: Hover at ..." for all movements
///
/// Run with: flutter run -d chrome test_mouseregion_opaque.dart
library;

import 'package:flutter/material.dart';

void main() => runApp(const MouseRegionOpaqueTest());

class MouseRegionOpaqueTest extends StatelessWidget {
  const MouseRegionOpaqueTest({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MouseRegion Opaque Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const TestPage(),
    );
  }
}

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  bool _parentOpaque = true;
  bool _childHovering = false;
  int _parentHoverCount = 0;
  int _childEnterCount = 0;
  int _childExitCount = 0;
  Offset? _lastHoverPosition;

  void _resetCounters() {
    setState(() {
      _parentHoverCount = 0;
      _childEnterCount = 0;
      _childExitCount = 0;
      _lastHoverPosition = null;
      _childHovering = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nested MouseRegion Opaque Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Control Panel
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Test Configuration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: SwitchListTile(
                            title: const Text('Parent MouseRegion opaque'),
                            subtitle: Text(
                              _parentOpaque ? 'TRUE (default) - blocks child MouseRegions' : 'FALSE - allows child MouseRegions',
                            ),
                            value: _parentOpaque,
                            onChanged: (value) {
                              setState(() {
                                _parentOpaque = value;
                              });
                              _resetCounters();
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _resetCounters,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reset Counters'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Stats Panel
            Card(
              color: Colors.grey[100],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Event Statistics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Parent Hover Events',
                            _parentHoverCount.toString(),
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Child Enter Events',
                            _childEnterCount.toString(),
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Child Exit Events',
                            _childExitCount.toString(),
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Child Hovering',
                            _childHovering ? 'YES' : 'NO',
                            _childHovering ? Colors.green : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_lastHoverPosition != null)
                      Text(
                        'Last hover position: (${_lastHoverPosition!.dx.toStringAsFixed(1)}, ${_lastHoverPosition!.dy.toStringAsFixed(1)})',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Test Area
            const Text(
              'Test Area - Move mouse over grey area and blue box:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Center(
                child: MouseRegion(
                  opaque: _parentOpaque, // ← THE KEY PARAMETER BEING TESTED
                  onHover: (event) {
                    setState(() {
                      _parentHoverCount++;
                      _lastHoverPosition = event.localPosition;
                    });
                    print('PARENT: Hover at ${event.localPosition}');
                  },
                  child: Container(
                    width: 500,
                    height: 400,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: Center(
                      child: MouseRegion(
                        cursor: SystemMouseCursors.resizeLeftRight,
                        onEnter: (_) {
                          setState(() {
                            _childEnterCount++;
                            _childHovering = true;
                          });
                          print('✅ CHILD: Mouse ENTER');
                        },
                        onExit: (_) {
                          setState(() {
                            _childExitCount++;
                            _childHovering = false;
                          });
                          print('❌ CHILD: Mouse EXIT');
                        },
                        onHover: (event) {
                          print('🖱️ CHILD: Hover at ${event.localPosition}');
                        },
                        child: Container(
                          width: 40,
                          height: 100,
                          decoration: BoxDecoration(
                            color: _childHovering ? Colors.blue[700] : Colors.blue,
                            border: Border.all(
                              color: _childHovering ? Colors.white : Colors.blue[900]!,
                              width: 3,
                            ),
                            boxShadow: _childHovering
                                ? [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.5),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.drag_indicator,
                                  color: Colors.white,
                                  size: _childHovering ? 32 : 24,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'HANDLE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: _childHovering ? 10 : 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Expected Results
            Card(
              color: _parentOpaque ? Colors.red[50] : Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _parentOpaque ? Icons.cancel : Icons.check_circle,
                          color: _parentOpaque ? Colors.red : Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _parentOpaque ? 'Expected: Child events BLOCKED' : 'Expected: Child events WORKING',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _parentOpaque ? Colors.red[900] : Colors.green[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _parentOpaque
                          ? '• Cursor should NOT change over blue box\n'
                              '• Child Enter/Exit counts should be 0\n'
                              '• Console should NOT show child messages\n'
                              '• Blue box should NOT highlight on hover'
                          : '• Cursor SHOULD change to resize arrows over blue box\n'
                              '• Child Enter/Exit counts should increment\n'
                              '• Console SHOULD show "✅ CHILD: Mouse ENTER" messages\n'
                              '• Blue box SHOULD highlight on hover',
                      style: TextStyle(
                        fontSize: 12,
                        color: _parentOpaque ? Colors.red[800] : Colors.green[800],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
