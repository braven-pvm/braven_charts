// Copyright (c) 2025 braven_charts. All rights reserved.
// Phase 0 Prototype - Widget Conflict Scenario Tests
//
// Tests validate widget-level behavior through callbacks.
// Note: Gesture arena may cause multiple callback invocations - tests check final state.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interaction_prototype/core/chart_element.dart';
import 'package:interaction_prototype/elements/simulated_datapoint.dart';
import 'package:interaction_prototype/widgets/prototype_chart.dart';

void main() {
  group('Mouse Button Responsibilities', () {
    testWidgets('middle-click should trigger pan callbacks', (tester) async {
      final datapoint = SimulatedDatapoint(id: 'point_1', center: const Offset(100, 100));
      bool panTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrototypeChart(
              elements: [datapoint],
              onPanUpdate: (_) => panTriggered = true,
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        const Offset(100, 100),
        kind: PointerDeviceKind.mouse,
        buttons: kMiddleMouseButton,
      );
      await tester.pump();

      await gesture.moveBy(const Offset(50, 50));
      await tester.pump();

      expect(panTriggered, isTrue);

      await gesture.up();
      await tester.pump();
    });

    testWidgets('left-click should trigger selection callback', (tester) async {
      final datapoint = SimulatedDatapoint(id: 'point_1', center: const Offset(100, 100));
      final selections = <ChartElement>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrototypeChart(
              elements: [datapoint],
              onElementSelected: (element) => selections.add(element),
            ),
          ),
        ),
      );

      await tester.tapAt(const Offset(100, 100));
      await tester.pumpAndSettle();

      // Should have selected datapoint (may be called multiple times by gesture arena)
      expect(selections.where((e) => e.id == 'point_1'), isNotEmpty);
    });
  });

  group('Selection State Management', () {
    testWidgets('should select element on left-click', (tester) async {
      final datapoint = SimulatedDatapoint(id: 'point_1', center: const Offset(100, 100));
      final selections = <ChartElement>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrototypeChart(
              elements: [datapoint],
              onElementSelected: (element) => selections.add(element),
            ),
          ),
        ),
      );

      await tester.tapAt(const Offset(100, 100));
      await tester.pumpAndSettle();

      expect(selections, isNotEmpty);
    });

    testWidgets('should handle multiple elements', (tester) async {
      final point1 = SimulatedDatapoint(id: 'point_1', center: const Offset(100, 100));
      final point2 = SimulatedDatapoint(id: 'point_2', center: const Offset(200, 200));
      final selections = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrototypeChart(
              elements: [point1, point2],
              onElementSelected: (element) => selections.add(element.id),
            ),
          ),
        ),
      );

      // Select point1
      await tester.tapAt(const Offset(100, 100));
      await tester.pumpAndSettle();
      expect(selections, contains('point_1'));

      selections.clear();

      // Select point2
      await tester.tapAt(const Offset(200, 200));
      await tester.pumpAndSettle();
      expect(selections, contains('point_2'));
    });
  });

  group('Pan Gesture Handling', () {
    testWidgets('should call onPanStart callback', (tester) async {
      bool startCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrototypeChart(
              elements: [],
              onPanStart: (_) => startCalled = true,
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        const Offset(100, 100),
        kind: PointerDeviceKind.mouse,
        buttons: kMiddleMouseButton,
      );
      await tester.pump();

      expect(startCalled, isTrue);

      await gesture.up();
      await tester.pump();
    });

    testWidgets('should call onPanUpdate callback', (tester) async {
      bool updateCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrototypeChart(
              elements: [],
              onPanUpdate: (_) => updateCalled = true,
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        const Offset(100, 100),
        kind: PointerDeviceKind.mouse,
        buttons: kMiddleMouseButton,
      );
      await tester.pump();

      await gesture.moveBy(const Offset(50, 50));
      await tester.pump();

      expect(updateCalled, isTrue);

      await gesture.up();
      await tester.pump();
    });

    testWidgets('should call onPanEnd callback', (tester) async {
      bool endCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrototypeChart(
              elements: [],
              onPanEnd: (_) => endCalled = true,
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        const Offset(100, 100),
        kind: PointerDeviceKind.mouse,
        buttons: kMiddleMouseButton,
      );
      await tester.pump();

      await gesture.moveBy(const Offset(50, 50));
      await tester.pump();

      await gesture.up();
      await tester.pump();

      expect(endCalled, isTrue);
    });
  });

  group('Conflict Scenario Integration', () {
    testWidgets('scenario 12: pan should work with elements present', (tester) async {
      final datapoint = SimulatedDatapoint(id: 'point_1', center: const Offset(100, 100));
      bool panTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrototypeChart(
              elements: [datapoint],
              onPanUpdate: (_) => panTriggered = true,
              showDebugInfo: true,
            ),
          ),
        ),
      );

      final panGesture = await tester.startGesture(
        const Offset(100, 100),
        kind: PointerDeviceKind.mouse,
        buttons: kMiddleMouseButton,
      );
      await tester.pump();

      await panGesture.moveBy(const Offset(50, 50));
      await tester.pump();

      expect(panTriggered, isTrue);

      await panGesture.up();
      await tester.pump();
    });

    testWidgets('scenario 4: nearest datapoint selection', (tester) async {
      final point1 = SimulatedDatapoint(id: 'point_1', center: const Offset(100, 100));
      final point2 = SimulatedDatapoint(id: 'point_2', center: const Offset(102, 102));
      final selections = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrototypeChart(
              elements: [point1, point2],
              onElementSelected: (element) => selections.add(element.id),
            ),
          ),
        ),
      );

      await tester.tapAt(const Offset(100, 100));
      await tester.pumpAndSettle();

      // Should have selected point1 (nearest to click position)
      expect(selections, contains('point_1'));
    });

    testWidgets('widget lifecycle: build and dispose', (tester) async {
      final datapoint = SimulatedDatapoint(id: 'point_1', center: const Offset(100, 100));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrototypeChart(
              elements: [datapoint],
            ),
          ),
        ),
      );

      expect(find.byType(PrototypeChart), findsOneWidget);

      // Remove widget
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));

      expect(find.byType(PrototypeChart), findsNothing);
    });
  });
}
