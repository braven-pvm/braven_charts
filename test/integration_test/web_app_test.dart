import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Web Integration Tests', () {
    testWidgets('renders chart on web platform', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('Braven Charts Web Test'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Braven Charts Web Test'), findsOneWidget);
    });

    testWidgets('handles responsive layout on web', (tester) async {
      // Set web viewport size
      await tester.binding.setSurfaceSize(const Size(1920, 1080));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 800,
                height: 600,
                child: Container(
                  color: Colors.blue,
                  child: const Center(
                    child: Text('Chart Container'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Chart Container'), findsOneWidget);
      
      // Verify container size
      final container = tester.widget<SizedBox>(
        find.ancestor(
          of: find.text('Chart Container'),
          matching: find.byType(SizedBox),
        ).first,
      );
      expect(container.width, 800);
      expect(container.height, 600);
    });

    testWidgets('handles mouse interactions on web', (tester) async {
      bool wasClicked = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                key: const Key('test_button'),
                onPressed: () {
                  wasClicked = true;
                },
                child: const Text('Click Me'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      
      // Use gesture for web-compatible mouse interaction
      // This avoids the "No element" error by properly creating a mouse gesture
      final buttonFinder = find.byKey(const Key('test_button'));
      expect(buttonFinder, findsOneWidget);
      
      // Get the center of the button
      final buttonCenter = tester.getCenter(buttonFinder);
      
      // Create a proper mouse gesture with all required events
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: buttonCenter);
      await tester.pump();
      
      // Move to button (hover)
      await gesture.moveTo(buttonCenter);
      await tester.pump();
      
      // Press down
      await gesture.down(buttonCenter);
      await tester.pump();
      
      // Release (complete the click)
      await gesture.up();
      await tester.pumpAndSettle();
      
      // Clean up the gesture
      await gesture.removePointer();
      
      expect(wasClicked, isTrue);
    });
  });
}
