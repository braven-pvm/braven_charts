// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HeatmapDendrogramLayout', () {
    test('projects column and row axes with matching normalized geometry', () {
      final column = HeatmapDendrogramLayout(
        data: _data(HeatmapDendrogramAxis.columns),
        size: const Size(100, 80),
        edgeInset: 0,
        automaticLevelOfDetail: false,
      );
      final row = HeatmapDendrogramLayout(
        data: _data(HeatmapDendrogramAxis.rows),
        size: const Size(80, 100),
        edgeInset: 0,
        automaticLevelOfDetail: false,
      );

      expect(_position(column, 'axis:leaf:0'), const Offset(25, 80));
      expect(_position(column, 'axis:0,1'), const Offset(50, 0));
      expect(_position(row, 'axis:leaf:0'), const Offset(80, 75));
      expect(_position(row, 'axis:0,1'), const Offset(0, 50));
    });

    test('accepts a complete merge when any segment clears automatic LOD', () {
      final layout = HeatmapDendrogramLayout(
        data: _data(HeatmapDendrogramAxis.columns),
        size: const Size(10, 10),
        edgeInset: 0,
        minimumBranchLength: 6,
      );

      expect(
        layout.segments.map((segment) => segment.segment.id),
        containsAll(<String>[
          'axis:0,1:left',
          'axis:0,1:join',
          'axis:0,1:right',
        ]),
      );
    });

    test('suppresses a complete merge when every segment fails LOD', () {
      final layout = HeatmapDendrogramLayout(
        data: _data(HeatmapDendrogramAxis.columns),
        size: const Size(10, 10),
        edgeInset: 0,
        minimumBranchLength: 11,
      );

      expect(layout.segments, isEmpty);
    });
  });

  group('HeatmapDendrogramHitTestMap', () {
    test('node anchors take precedence over overlapping branches', () {
      final layout = HeatmapDendrogramLayout(
        data: _data(HeatmapDendrogramAxis.columns),
        size: const Size(100, 100),
        edgeInset: 0,
        automaticLevelOfDetail: false,
      );

      final hit = HeatmapDendrogramHitTestMap(
        layout: layout,
      ).hitTest(const Offset(25, 100));

      expect(hit, isNotNull);
      expect(hit!.kind, HeatmapDendrogramHitKind.node);
      expect(hit.nodeId, 'axis:leaf:0');
      expect(hit.leafIndex, 0);
      expect(hit.memberCount, 1);
    });

    test('returns the nearest accepted branch and stable segment identity', () {
      final layout = HeatmapDendrogramLayout(
        data: _data(HeatmapDendrogramAxis.columns),
        size: const Size(100, 100),
        edgeInset: 0,
        automaticLevelOfDetail: false,
      );

      final hit = HeatmapDendrogramHitTestMap(
        layout: layout,
        includeLeafNodes: false,
        includeMergeNodes: false,
      ).hitTest(const Offset(26, 48), branchRadius: 4);

      expect(hit, isNotNull);
      expect(hit!.kind, HeatmapDendrogramHitKind.branch);
      expect(hit.nodeId, 'axis:0,1');
      expect(hit.segmentId, 'axis:0,1:left');
      expect(hit.distance, 1);
    });

    test('does not hit a branch suppressed by automatic LOD', () {
      final layout = HeatmapDendrogramLayout(
        data: _data(HeatmapDendrogramAxis.columns),
        size: const Size(10, 10),
        edgeInset: 0,
        minimumBranchLength: 11,
      );

      final hit = HeatmapDendrogramHitTestMap(
        layout: layout,
        includeLeafNodes: false,
        includeMergeNodes: false,
      ).hitTest(const Offset(2.5, 5), branchRadius: 2);

      expect(hit, isNull);
    });

    test('breaks exact-distance ties with stable hierarchy identity', () {
      final layout = HeatmapDendrogramLayout(
        data: _data(HeatmapDendrogramAxis.columns),
        size: const Size(100, 100),
        edgeInset: 0,
        automaticLevelOfDetail: false,
      );

      final hit = HeatmapDendrogramHitTestMap(
        layout: layout,
        includeMergeNodes: false,
      ).hitTest(const Offset(50, 100), nodeRadius: 26);

      expect(hit, isNotNull);
      expect(hit!.nodeId, 'axis:leaf:0');
    });

    test('returns no target outside both configured hit radii', () {
      final layout = HeatmapDendrogramLayout(
        data: _data(HeatmapDendrogramAxis.columns),
        size: const Size(100, 100),
        edgeInset: 0,
        automaticLevelOfDetail: false,
      );

      final hit = HeatmapDendrogramHitTestMap(
        layout: layout,
      ).hitTest(const Offset(99, 1), nodeRadius: 2, branchRadius: 2);

      expect(hit, isNull);
    });
  });

  group('HeatmapDendrogramInteractionState', () {
    test('round trips durable selection without transient hover or focus', () {
      const selected = HeatmapDendrogramTargetIdentity(
        kind: HeatmapDendrogramHitKind.branch,
        axis: HeatmapDendrogramAxis.columns,
        nodeId: 'axis:0,1',
        segmentId: 'axis:0,1:join',
      );
      const transient = HeatmapDendrogramTargetIdentity(
        kind: HeatmapDendrogramHitKind.node,
        axis: HeatmapDendrogramAxis.columns,
        nodeId: 'axis:leaf:0',
      );
      const state = HeatmapDendrogramInteractionState(
        hoveredTarget: transient,
        focusedTarget: transient,
        selectedTarget: selected,
      );

      final json = state.toJson();
      final restored = HeatmapDendrogramInteractionState.fromJson(json);

      expect(json, {
        'selectedTarget': {
          'kind': 'branch',
          'axis': 'columns',
          'nodeId': 'axis:0,1',
          'segmentId': 'axis:0,1:join',
        },
      });
      expect(restored.selectedTarget, selected);
      expect(restored.hoveredTarget, isNull);
      expect(restored.focusedTarget, isNull);
    });

    testWidgets('opt-in widget reports pointer and keyboard interaction', (
      tester,
    ) async {
      var state = const HeatmapDendrogramInteractionState();
      await tester.pumpWidget(
        MaterialApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: StatefulBuilder(
              builder: (context, setState) => SizedBox(
                width: 100,
                height: 100,
                child: HeatmapDendrogram(
                  data: _data(HeatmapDendrogramAxis.columns),
                  style: const HeatmapDendrogramStyle(
                    branchWidth: 2,
                    showLeafBaseline: false,
                    showLeafTicks: false,
                    levelOfDetailMode:
                        HeatmapDendrogramLevelOfDetailMode.disabled,
                  ),
                  interactionState: state,
                  onInteractionStateChanged: (next) {
                    setState(() => state = next);
                  },
                ),
              ),
            ),
          ),
        ),
      );
      final canvas = find.byKey(
        const ValueKey('heatmap-columns-dendrogram-canvas'),
      );
      final topLeft = tester.getTopLeft(canvas);
      final leaf = topLeft + const Offset(25.5, 99);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: topLeft);
      await mouse.moveTo(leaf);
      await tester.pump();

      expect(state.hoveredTarget?.nodeId, 'axis:leaf:0');

      await tester.tapAt(leaf);
      await tester.pump();
      expect(state.selectedTarget?.nodeId, 'axis:leaf:0');

      await tester.tapAt(leaf);
      await tester.pump();
      expect(state.selectedTarget, isNull);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(state.focusedTarget?.nodeId, 'axis:leaf:1');

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(state.selectedTarget?.nodeId, 'axis:leaf:1');

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(state.focusedTarget, isNull);
      expect(state.selectedTarget, isNull);

      await mouse.removePointer();
    });

    testWidgets('short touch selects without claiming a page scroll drag', (
      tester,
    ) async {
      var state = const HeatmapDendrogramInteractionState();
      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            height: 180,
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                children: [
                  StatefulBuilder(
                    builder: (context, setState) => SizedBox(
                      width: 100,
                      height: 100,
                      child: HeatmapDendrogram(
                        data: _data(HeatmapDendrogramAxis.columns),
                        style: const HeatmapDendrogramStyle(
                          branchWidth: 2,
                          showLeafBaseline: false,
                          showLeafTicks: false,
                          levelOfDetailMode:
                              HeatmapDendrogramLevelOfDetailMode.disabled,
                        ),
                        interactionState: state,
                        onInteractionStateChanged: (next) {
                          setState(() => state = next);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 600),
                ],
              ),
            ),
          ),
        ),
      );
      final canvas = find.byKey(
        const ValueKey('heatmap-columns-dendrogram-canvas'),
      );
      final leaf = tester.getTopLeft(canvas) + const Offset(25.5, 99);

      await tester.tapAt(leaf, kind: PointerDeviceKind.touch);
      await tester.pump();

      expect(state.selectedTarget?.nodeId, 'axis:leaf:0');
      expect(scrollController.offset, 0);

      state = const HeatmapDendrogramInteractionState();
      await tester.dragFrom(
        tester.getTopLeft(canvas) + const Offset(50, 50),
        const Offset(0, -80),
        kind: PointerDeviceKind.touch,
      );
      await tester.pumpAndSettle();

      expect(state.selectedTarget, isNull);
      expect(scrollController.offset, greaterThan(0));
    });

    testWidgets('interactive semantics describe keyboard operation', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 100,
            height: 100,
            child: HeatmapDendrogram(
              data: _data(HeatmapDendrogramAxis.rows),
              onInteractionStateChanged: (_) {},
            ),
          ),
        ),
      );

      expect(
        find.bySemanticsLabel('Row dendrogram, 2 categories'),
        findsOneWidget,
      );
      expect(
        tester.getSemantics(find.byType(HeatmapDendrogram)),
        matchesSemantics(
          isFocusable: true,
          isImage: true,
          hasEnabledState: false,
          hasTapAction: false,
          label: 'Row dendrogram, 2 categories',
          hint:
              'Use arrow keys to inspect hierarchy nodes, Enter or Space to '
              'select, and Escape to clear.',
          textDirection: TextDirection.ltr,
        ),
      );
      semantics.dispose();
    });
  });
}

Offset _position(HeatmapDendrogramLayout layout, String nodeId) => layout.nodes
    .singleWhere((projected) => projected.node.id == nodeId)
    .position;

HeatmapDendrogramData _data(HeatmapDendrogramAxis axis) =>
    HeatmapDendrogramData(
      root: HeatmapClusterNode.fromJson(const {
        'id': 'axis:0,1',
        'distance': 1,
        'memberIndices': [0, 1],
        'left': {
          'id': 'axis:leaf:0',
          'distance': 0,
          'memberIndices': [0],
          'leafIndex': 0,
        },
        'right': {
          'id': 'axis:leaf:1',
          'distance': 0,
          'memberIndices': [1],
          'leafIndex': 1,
        },
      }),
      sourceLabels: const ['First', 'Second'],
      axis: axis,
    );
