import 'package:flutter/gestures.dart' show PointerScrollEvent;
import 'package:flutter/material.dart';

/// TEST: Stack with Listener + MouseRegion parent, and MouseRegion children on top
///
/// This replicates the EXACT BravenChart structure:
/// - Stack at root
/// - Child 0: Listener wrapping MouseRegion (chart layer)
/// - Child 1: MouseRegion handle (annotation layer)
///
/// Purpose: Determine if Listener blocks MouseRegion handles in Stack children

void main() => runApp(const StackListenerTest());

class StackListenerTest extends StatefulWidget {
  const StackListenerTest({super.key});

  @override
  State<StackListenerTest> createState() => _StackListenerTestState();
}

class _StackListenerTestState extends State<StackListenerTest> {
  bool _hoveringHandle = false;
  String _draggingEdge = '';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('STACK + LISTENER + MOUSEREGION TEST'),
          backgroundColor: Colors.deepPurple,
        ),
        body: Center(
          child: Container(
            width: 600,
            height: 400,
            color: Colors.grey[200],
            child: Stack(
              children: [
                // LAYER 0: Chart layer (Listener wrapping MouseRegion)
                // This replicates BravenChart's interaction wrapper
                Positioned.fill(
                  child: MouseRegion(
                    // DEFAULT opaque: true
                    onHover: (event) {
                      print('🎯 CHART LAYER: MouseRegion hover at ${event.localPosition}');
                    },
                    child: Listener(
                      onPointerDown: (event) {
                        print('👇 CHART LAYER: Listener pointer down at ${event.localPosition}');
                      },
                      onPointerMove: (event) {
                        print('👆 CHART LAYER: Listener pointer move at ${event.localPosition}');
                      },
                      onPointerSignal: (signal) {
                        if (signal is PointerScrollEvent) {
                          print('📜 CHART LAYER: Listener scroll event');
                        }
                      },
                      child: Container(
                        color: Colors.blue.withOpacity(0.1),
                        child: const Center(
                          child: Text(
                            'CHART AREA\n(Listener + MouseRegion)',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // LAYER 1: Annotation handle (MouseRegion on top in Stack)
                // This replicates BravenChart's range annotation handles
                Positioned(
                  left: 50,
                  top: 100,
                  width: 20,
                  height: 200,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeLeftRight,
                    onEnter: (_) {
                      print('✅ HANDLE: Mouse ENTER');
                      setState(() => _hoveringHandle = true);
                    },
                    onExit: (_) {
                      print('❌ HANDLE: Mouse EXIT');
                      setState(() => _hoveringHandle = false);
                    },
                    onHover: (event) {
                      print('🖱️ HANDLE: Mouse HOVER at ${event.localPosition}');
                    },
                    child: Listener(
                      onPointerDown: (event) {
                        print('👇 HANDLE: Pointer DOWN');
                        setState(() => _draggingEdge = 'left');
                      },
                      onPointerMove: (event) {
                        if (_draggingEdge == 'left') {
                          print('👆 HANDLE: Pointer MOVE (dragging)');
                        }
                      },
                      onPointerUp: (event) {
                        if (_draggingEdge == 'left') {
                          print('👆 HANDLE: Pointer UP');
                          setState(() => _draggingEdge = '');
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: _hoveringHandle ? Colors.red.withOpacity(0.6) : Colors.red.withOpacity(0.3),
                          border: Border.all(
                            color: Colors.red,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 8,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Info panel
                Positioned(
                  right: 20,
                  top: 20,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TEST STRUCTURE:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        const Text('Stack {', style: TextStyle(fontFamily: 'monospace')),
                        const Text('  [0]: MouseRegion + Listener (chart)', style: TextStyle(fontFamily: 'monospace', fontSize: 12)),
                        const Text('  [1]: MouseRegion + Listener (handle)', style: TextStyle(fontFamily: 'monospace', fontSize: 12)),
                        const Text('}', style: TextStyle(fontFamily: 'monospace')),
                        const SizedBox(height: 12),
                        Text(
                          'Handle Hovering: ${_hoveringHandle ? "YES ✅" : "NO ❌"}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _hoveringHandle ? Colors.green : Colors.red,
                          ),
                        ),
                        Text(
                          'Dragging: ${_draggingEdge.isNotEmpty ? "YES ($_draggingEdge)" : "NO"}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'EXPECTED BEHAVIOR:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        const Text(
                          '• Cursor should change over red handle',
                          style: TextStyle(fontSize: 11),
                        ),
                        const Text(
                          '• Handle should receive mouse events',
                          style: TextStyle(fontSize: 11),
                        ),
                        const Text(
                          '• Console should show HANDLE messages',
                          style: TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
