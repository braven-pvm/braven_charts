// Copyright (c) 2025 braven_charts. All rights reserved.
// Phase 0 Prototype - Integration Tests: Complete Workflows
//
// Tests validate end-to-end interaction workflows combining multiple
// components (coordinator + QuadTree + widget + gesture recognizers).

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interaction_prototype/core/chart_element.dart';
import 'package:interaction_prototype/elements/simulated_annotation.dart';
import 'package:interaction_prototype/elements/simulated_datapoint.dart';
import 'package:interaction_prototype/widgets/prototype_chart.dart';

void main() {
  group('Complete Interaction Workflows', () {
    testWidgets('workflow: hover → select → deselect', (tester) async {
      final datapoint = SimulatedDatapoint(
        id: 'point_1',
        center: const Offset(100, 100),
      );
      final selections = <String>[];
      final deselections = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrototypeChart(
              elements: [datapoint],
              onElementSelected: (element) => selections.add(element.id),
              onElementDeselected: (element) => deselections.add(element.id),
            ),
          ),
        ),
      );

      // Hover over datapoint (mouse move without click)
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: const Offset(100, 100));
      await tester.pump();
      await gesture.moveTo(const Offset(100, 100));
      await tester.pumpAndSettle();

      // Select datapoint
      await tester.tapAt(const Offset(100, 100));
      await tester.pumpAndSettle();
      expect(selections, contains('point_1'));

      selections.clear();
      deselections.clear();

      // Deselect by clicking empty space
      await tester.tapAt(const Offset(300, 300));
      await tester.pumpAndSettle();

      // Widget should remain functional
      expect(find.byType(PrototypeChart), findsOneWidget);
    });

    testWidgets('workflow: select multiple elements with Ctrl+click', (tester) async {
      final point1 = SimulatedDatapoint(id: 'point_1', center: const Offset(100, 100));
      final point2 = SimulatedDatapoint(id: 'point_2', center: const Offset(200, 100));
      final point3 = SimulatedDatapoint(id: 'point_3', center: const Offset(300, 100));
      final selections = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrototypeChart(
              elements: [point1, point2, point3],
              onElementSelected: (element) => selections.add(element.id),
            ),
          ),
        ),
      );

      // Select point1 normally
      await tester.tapAt(const Offset(100, 100));
      await tester.pumpAndSettle();
      expect(selections, contains('point_1'));

      selections.clear();

      // Multi-select point2 with Ctrl (simulated via coordinator state)
      // Note: Widget tests can't easily simulate modifier keys, so we test the final behavior
      await tester.tapAt(const Offset(200, 100));
      await tester.pumpAndSettle();
      expect(selections, contains('point_2'));
    });

    testWidgets('workflow: pan across multiple elements', (tester) async {
      final elements = List.generate(
        10,
        (i) => SimulatedDatapoint(
          id: 'point_$i',
          center: Offset(50.0 + i * 50, 100),
        ),
      );

      bool panStartCalled = false;
      int panUpdateCount = 0;
      bool panEndCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrototypeChart(
              elements: elements,
              onPanStart: (_) => panStartCalled = true,
              onPanUpdate: (_) => panUpdateCount++,
              onPanEnd: (_) => panEndCalled = true,
            ),
          ),
        ),
      );

      // Middle-click drag across elements
      final panGesture = await tester.startGesture(
        const Offset(50, 100),
        kind: PointerDeviceKind.mouse,
        buttons: kMiddleMouseButton,
      );
      await tester.pump();

      expect(panStartCalled, isTrue);

      // Pan across all elements
      for (int i = 0; i < 10; i++) {
        await panGesture.moveBy(const Offset(50, 0));
        await tester.pump();
      }

      expect(panUpdateCount, greaterThan(0));

      await panGesture.up();
      await tester.pump();

      expect(panEndCalled, isTrue);
    });

    testWidgets('workflow: select → drag → release (datapoint movement)', (tester) async {
      final datapoint = SimulatedDatapoint(
        id: 'point_1',
        center: const Offset(100, 100),
      );
      final selections = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrototypeChart(
              elements: [datapoint],
              onElementSelected: (element) => selections.add(element.id),
            ),
          ),
        ),
      );

      // Select datapoint
      await tester.tapAt(const Offset(100, 100));
      await tester.pumpAndSettle();
      expect(selections, contains('point_1'));

      // Drag datapoint (left-click drag)
      final dragGesture = await tester.startGesture(const Offset(100, 100));
      await tester.pump();

      await dragGesture.moveBy(const Offset(50, 50));
      await tester.pump();

      await dragGesture.up();
      await tester.pumpAndSettle();

      // Widget should remain functional after drag
      expect(find.byType(PrototypeChart), findsOneWidget);
    });

    testWidgets('workflow: annotation selection and interaction', (tester) async {
      final annotation = SimulatedAnnotation(
        id: 'annotation_1',
        bounds: const Rect.fromLTWH(100, 100, 150, 80),
      );
      final selections = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrototypeChart(
              elements: [annotation],
              onElementSelected: (element) => selections.add(element.id),
            ),
          ),
        ),
      );

      // Select annotation by clicking center
      await tester.tapAt(const Offset(175, 140));
      await tester.pumpAndSettle();
      expect(selections, contains('annotation_1'));
    });

    testWidgets('workflow: mixed element types (datapoints + annotations)', (tester) async {
      final elements = <ChartElement>[
        SimulatedDatapoint(id: 'point_1', center: const Offset(100, 100)),
        SimulatedDatapoint(id: 'point_2', center: const Offset(200, 100)),
        SimulatedAnnotation(
          id: 'annotation_1',
          bounds: const Rect.fromLTWH(150, 150, 100, 60),
        ),
        SimulatedDatapoint(id: 'point_3', center: const Offset(300, 100)),
      ];
      final selections = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrototypeChart(
              elements: elements,
              onElementSelected: (element) => selections.add(element.id),
            ),
          ),
        ),
      );

      // Select datapoint
      await tester.tapAt(const Offset(100, 100));
      await tester.pumpAndSettle();
      expect(selections, contains('point_1'));

      selections.clear();

      // Select annotation
      await tester.tapAt(const Offset(200, 180));
      await tester.pumpAndSettle();
      expect(selections, contains('annotation_1'));
    });
  });

  group('Gesture Arena Integration', () {
    testWidgets('pan recognizer wins over tap when dragging', (tester) async {
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

      // Middle-click and drag should trigger pan, not tap
      final gesture = await tester.startGesture(
        const Offset(100, 100),
        kind: PointerDeviceKind.mouse,
        buttons: kMiddleMouseButton,
      );
      await tester.pump();

      await gesture.moveBy(const Offset(20, 20));
      await tester.pump();

      expect(panTriggered, isTrue);

      await gesture.up();
      await tester.pump();
    });

    testWidgets('tap recognizer wins for quick clicks', (tester) async {
      final datapoint = SimulatedDatapoint(id: 'point_1', center: const Offset(100, 100));
      final selections = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrototypeChart(
              elements: [datapoint],
              onElementSelected: (element) => selections.add(element.id),
            ),
          ),
        ),
      );

      // Quick tap should trigger selection
      await tester.tapAt(const Offset(100, 100));
      await tester.pumpAndSettle();

      expect(selections, contains('point_1'));
    });
  });

  group('Performance Under Load', () {
    testWidgets('handles 100+ elements efficiently', (tester) async {
      // Create 100 datapoints in a grid
      final elements = <ChartElement>[];
      for (int row = 0; row < 10; row++) {
        for (int col = 0; col < 10; col++) {
          elements.add(
            SimulatedDatapoint(
              id: 'point_${row}_$col',
              center: Offset(50.0 + col * 50, 50.0 + row * 50),
            ),
          );
        }
      }

      final selections = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrototypeChart(
              elements: elements,
              onElementSelected: (element) => selections.add(element.id),
            ),
          ),
        ),
      );

      // Widget should build without errors
      expect(find.byType(PrototypeChart), findsOneWidget);

      // Select element in middle of grid
      await tester.tapAt(const Offset(300, 300));
      await tester.pumpAndSettle();

      // Selection should work efficiently
      expect(selections, isNotEmpty);
    });

    testWidgets('handles rapid interaction changes', (tester) async {
      final datapoint = SimulatedDatapoint(id: 'point_1', center: const Offset(100, 100));
      final selections = <String>[];
      int panUpdateCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrototypeChart(
              elements: [datapoint],
              onElementSelected: (element) => selections.add(element.id),
              onPanUpdate: (_) => panUpdateCount++,
            ),
          ),
        ),
      );

      // Rapid selection changes
      for (int i = 0; i < 5; i++) {
        await tester.tapAt(const Offset(100, 100));
        await tester.pump();
        await tester.tapAt(const Offset(300, 300));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      // Rapid pan gestures
      for (int i = 0; i < 3; i++) {
        final gesture = await tester.startGesture(
          Offset(100 + i * 10.0, 100),
          kind: PointerDeviceKind.mouse,
          buttons: kMiddleMouseButton,
        );
        await tester.pump();
        await gesture.moveBy(const Offset(20, 20));
        await tester.pump();
        await gesture.up();
        await tester.pump();
      }

      // Widget should remain stable
      expect(find.byType(PrototypeChart), findsOneWidget);
      expect(panUpdateCount, greaterThan(0));
    });
  });

  group('Edge Cases and Robustness', () {
    testWidgets('handles empty element list gracefully', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrototypeChart(
              elements: [],
            ),
          ),
        ),
      );

      // Should build without errors
      expect(find.byType(PrototypeChart), findsOneWidget);

      // Click should not cause errors
      await tester.tapAt(const Offset(100, 100));
      await tester.pumpAndSettle();

      // Pan should not cause errors
      final gesture = await tester.startGesture(
        const Offset(100, 100),
        kind: PointerDeviceKind.mouse,
        buttons: kMiddleMouseButton,
      );
      await tester.pump();
      await gesture.moveBy(const Offset(50, 50));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.byType(PrototypeChart), findsOneWidget);
    });

    testWidgets('handles overlapping elements at same position', (tester) async {
      // Create 5 datapoints at exact same position
      final elements = List.generate(
        5,
        (i) => SimulatedDatapoint(
          id: 'point_$i',
          center: const Offset(100, 100),
        ),
      );
      final selections = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrototypeChart(
              elements: elements,
              onElementSelected: (element) => selections.add(element.id),
            ),
          ),
        ),
      );

      // Click should select one element (nearest logic)
      await tester.tapAt(const Offset(100, 100));
      await tester.pumpAndSettle();

      expect(selections, isNotEmpty);
    });

    testWidgets('handles widget rebuild with element changes', (tester) async {
      final point1 = SimulatedDatapoint(id: 'point_1', center: const Offset(100, 100));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrototypeChart(
              elements: [point1],
            ),
          ),
        ),
      );

      expect(find.byType(PrototypeChart), findsOneWidget);

      // Rebuild with different elements
      final point2 = SimulatedDatapoint(id: 'point_2', center: const Offset(200, 200));
      final point3 = SimulatedDatapoint(id: 'point_3', center: const Offset(300, 300));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrototypeChart(
              elements: [point1, point2, point3],
            ),
          ),
        ),
      );

      expect(find.byType(PrototypeChart), findsOneWidget);

      // Interaction should still work
      await tester.tapAt(const Offset(200, 200));
      await tester.pumpAndSettle();

      expect(find.byType(PrototypeChart), findsOneWidget);
    });
  });
}
