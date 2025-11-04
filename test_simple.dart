import 'package:flutter/material.dart';

void main() => runApp(const SimpleTest());

class SimpleTest extends StatelessWidget {
  const SimpleTest({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('SIMPLE NESTED MOUSEREGION TEST')),
        body: Center(
          child: Container(
            width: 500,
            height: 400,
            color: Colors.grey[300],
            child: MouseRegion(
              // NO OPAQUE PARAMETER - DEFAULTS TO TRUE
              onHover: (event) {
                print('PARENT HOVER: ${event.localPosition}');
              },
              child: Center(
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeLeftRight,
                  onEnter: (_) => print('✅ CHILD ENTER'),
                  onExit: (_) => print('❌ CHILD EXIT'),
                  onHover: (event) => print('🖱️ CHILD HOVER: ${event.localPosition}'),
                  child: Container(
                    width: 100,
                    height: 100,
                    color: Colors.blue,
                    child: const Center(
                      child: Text(
                        'HOVER ME',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
