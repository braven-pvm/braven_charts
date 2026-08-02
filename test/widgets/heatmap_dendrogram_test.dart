// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('style is immutable and JSON portable per hierarchy axis', () {
    const style = HeatmapDendrogramStyle(
      branchColor: Color(0xFF2563EB),
      branchWidth: 2.5,
      branchCap: StrokeCap.square,
      branchJoin: StrokeJoin.bevel,
      baselineColor: Color(0xFF94A3B8),
      baselineWidth: 1.25,
      showLeafBaseline: false,
      tickColor: Color(0xFF0F766E),
      tickWidth: 1.5,
      tickLength: 7,
      showLeafTicks: true,
      elbowRadius: 8,
      showLeafMarkers: true,
      leafMarkerColor: Color(0xFF0284C7),
      leafMarkerRadius: 4,
      leafMarkerShape: HeatmapDendrogramMarkerShape.square,
      leafMarkerFill: HeatmapDendrogramMarkerFill.hollow,
      leafMarkerBorderColor: Color(0xFF0C4A6E),
      leafMarkerBorderWidth: 1.5,
      showMergeMarkers: true,
      mergeMarkerColor: Color(0xFFF97316),
      mergeMarkerRadius: 5,
      mergeMarkerShape: HeatmapDendrogramMarkerShape.triangle,
      mergeMarkerFill: HeatmapDendrogramMarkerFill.solid,
      mergeMarkerBorderColor: Color(0xFF7C2D12),
      mergeMarkerBorderWidth: 2,
      showLeafLabels: true,
      showMergeDistanceLabels: true,
      labelColor: Color(0xFF111827),
      labelBackgroundColor: Color(0xFFF8FAFC),
      labelFontSize: 11,
      labelPadding: 3,
      labelRadius: 4,
      labelOffset: 5,
      labelDensity: HeatmapDendrogramLabelDensity.sparse,
      labelPlacement: HeatmapDendrogramLabelPlacement.after,
      maxLabelCharacters: 10,
      mergeDistanceFractionDigits: 3,
      levelOfDetailMode: HeatmapDendrogramLevelOfDetailMode.disabled,
      minimumBranchLength: 1.25,
      minimumLeafGuideSpacing: 4,
      minimumLeafMarkerSpacing: 9,
      minimumMergeMarkerSpacing: 7,
      minimumLabelSpacing: 28,
    );

    final restored = HeatmapDendrogramStyle.fromJson(style.toJson());

    expect(restored, style);
    expect(
      style.metadataFor(HeatmapDendrogramAxis.rows),
      containsPair('heatmapDendrogramRowStyle', style.toJson()),
    );
    expect(
      style.metadataFor(HeatmapDendrogramAxis.columns),
      containsPair('heatmapDendrogramColumnStyle', style.toJson()),
    );
    expect(
      () => HeatmapDendrogramStyle.fromJson({
        ...style.toJson(),
        'elbowRadius': -1,
      }),
      throwsFormatException,
    );
    expect(
      () => HeatmapDendrogramStyle.fromJson({
        ...style.toJson(),
        'minimumLabelSpacing': -1,
      }),
      throwsFormatException,
    );
  });

  testWidgets('renders row and column hierarchy canvases with semantics', (
    tester,
  ) async {
    final root = HeatmapClusterNode.fromJson(const {
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
    });
    final rowData = HeatmapDendrogramData(
      root: root,
      sourceLabels: const ['North', 'South'],
      axis: HeatmapDendrogramAxis.rows,
    );
    final columnData = HeatmapDendrogramData(
      root: root,
      sourceLabels: const ['Morning', 'Evening'],
      axis: HeatmapDendrogramAxis.columns,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            SizedBox(height: 80, child: HeatmapDendrogram(data: columnData)),
            Expanded(
              child: Row(
                children: [
                  SizedBox(width: 80, child: HeatmapDendrogram(data: rowData)),
                  const Expanded(child: ColoredBox(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('heatmap-columns-dendrogram-canvas')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('heatmap-rows-dendrogram-canvas')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Column dendrogram, 2 categories'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Row dendrogram, 2 categories'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('automatic LOD suppresses crowded leaf markers', (tester) async {
    final root = HeatmapClusterNode.fromJson(_balancedRootJson(0, 16));
    final data = HeatmapDendrogramData(
      root: root,
      sourceLabels: [for (var index = 0; index < 16; index++) 'Leaf $index'],
      axis: HeatmapDendrogramAxis.columns,
      distanceScale: HeatmapDendrogramDistanceScale.structural,
    );

    Future<ByteData> capture(HeatmapDendrogramLevelOfDetailMode mode) async {
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: boundaryKey,
              child: SizedBox(
                width: 160,
                height: 80,
                child: ColoredBox(
                  color: Colors.white,
                  child: HeatmapDendrogram(
                    data: data,
                    style: HeatmapDendrogramStyle(
                      branchColor: Colors.transparent,
                      showLeafBaseline: false,
                      showLeafTicks: false,
                      showLeafMarkers: true,
                      leafMarkerColor: const Color(0xFFFF0000),
                      leafMarkerRadius: 4,
                      leafMarkerBorderWidth: 0,
                      levelOfDetailMode: mode,
                      minimumLeafMarkerSpacing: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final boundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await tester.runAsync(
        () => boundary.toImage(pixelRatio: 1),
      );
      return (await tester.runAsync(
        () => image!.toByteData(format: ui.ImageByteFormat.rawRgba),
      ))!;
    }

    final automatic = await capture(
      HeatmapDendrogramLevelOfDetailMode.automatic,
    );
    expect(_pixelAt(automatic, 160, 6, 76), _isWhite);

    final disabled = await capture(HeatmapDendrogramLevelOfDetailMode.disabled);
    expect(_pixelAt(disabled, 160, 6, 76), _isRed);
  });

  testWidgets('presentation changes invalidate the standalone painter', (
    tester,
  ) async {
    final root = HeatmapClusterNode.fromJson(const {
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
    });
    final data = HeatmapDendrogramData(
      root: root,
      sourceLabels: const ['First', 'Second'],
      axis: HeatmapDendrogramAxis.columns,
    );

    Future<CustomPainter> pumpStyle(HeatmapDendrogramStyle style) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 240,
            height: 100,
            child: HeatmapDendrogram(data: data, style: style),
          ),
        ),
      );
      final paint = tester.widget<CustomPaint>(
        find.byKey(const ValueKey('heatmap-columns-dendrogram-canvas')),
      );
      return paint.painter!;
    }

    final exactPainter = await pumpStyle(
      const HeatmapDendrogramStyle(
        showLeafBaseline: false,
        showLeafTicks: false,
      ),
    );
    final roundedPainter = await pumpStyle(
      const HeatmapDendrogramStyle(
        branchColor: Colors.deepPurple,
        branchWidth: 3,
        baselineColor: Colors.blueGrey,
        baselineWidth: 2,
        tickColor: Colors.orange,
        tickWidth: 2,
        tickLength: 9,
        elbowRadius: 10,
        showLeafMarkers: true,
        leafMarkerRadius: 4,
        leafMarkerShape: HeatmapDendrogramMarkerShape.square,
        leafMarkerFill: HeatmapDendrogramMarkerFill.hollow,
        leafMarkerBorderColor: Colors.indigo,
        leafMarkerBorderWidth: 2,
        showMergeMarkers: true,
        mergeMarkerRadius: 5,
        mergeMarkerShape: HeatmapDendrogramMarkerShape.diamond,
        mergeMarkerBorderColor: Colors.deepOrange,
        mergeMarkerBorderWidth: 1.5,
        showLeafLabels: true,
        showMergeDistanceLabels: true,
        labelDensity: HeatmapDendrogramLabelDensity.sparse,
      ),
    );

    expect(roundedPainter.shouldRepaint(exactPainter), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('accepts a zero-sized layout without painting errors', (
    tester,
  ) async {
    final root = HeatmapClusterNode.fromJson(const {
      'id': 'axis:leaf:0',
      'distance': 0,
      'memberIndices': [0],
      'leafIndex': 0,
    });
    final data = HeatmapDendrogramData(
      root: root,
      sourceLabels: const ['Only'],
      axis: HeatmapDendrogramAxis.columns,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox.shrink(child: HeatmapDendrogram(data: data)),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('single-leaf hierarchies retain alignment guides', (
    tester,
  ) async {
    final root = HeatmapClusterNode.fromJson(const {
      'id': 'axis:leaf:0',
      'distance': 0,
      'memberIndices': [0],
      'leafIndex': 0,
    });
    final data = HeatmapDendrogramData(
      root: root,
      sourceLabels: const ['Only'],
      axis: HeatmapDendrogramAxis.columns,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 200,
          height: 80,
          child: HeatmapDendrogram(
            data: data,
            style: const HeatmapDendrogramStyle(
              showLeafBaseline: true,
              showLeafTicks: true,
            ),
          ),
        ),
      ),
    );

    expect(data.segments, isEmpty);
    expect(
      find.byKey(const ValueKey('heatmap-columns-dendrogram-canvas')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('bounds marker and label presentation in both orientations', (
    tester,
  ) async {
    final root = HeatmapClusterNode.fromJson(const {
      'id': 'axis:0,1',
      'distance': 12.3456,
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
    });
    const style = HeatmapDendrogramStyle(
      showLeafMarkers: true,
      leafMarkerShape: HeatmapDendrogramMarkerShape.triangle,
      leafMarkerFill: HeatmapDendrogramMarkerFill.hollow,
      leafMarkerBorderColor: Colors.blue,
      leafMarkerBorderWidth: 2,
      showMergeMarkers: true,
      mergeMarkerShape: HeatmapDendrogramMarkerShape.diamond,
      mergeMarkerBorderColor: Colors.orange,
      mergeMarkerBorderWidth: 1.5,
      showLeafLabels: true,
      showMergeDistanceLabels: true,
      labelPlacement: HeatmapDendrogramLabelPlacement.after,
      maxLabelCharacters: 6,
      mergeDistanceFractionDigits: 3,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 240,
          height: 180,
          child: Column(
            children: [
              SizedBox(
                height: 70,
                child: HeatmapDendrogram(
                  data: HeatmapDendrogramData(
                    root: root,
                    sourceLabels: const [
                      'Extremely long first category',
                      'Extremely long second category',
                    ],
                    axis: HeatmapDendrogramAxis.columns,
                    distanceScale: HeatmapDendrogramDistanceScale.structural,
                  ),
                  style: style,
                ),
              ),
              Expanded(
                child: HeatmapDendrogram(
                  data: HeatmapDendrogramData(
                    root: root,
                    sourceLabels: const [
                      'Extremely long first category',
                      'Extremely long second category',
                    ],
                    axis: HeatmapDendrogramAxis.rows,
                    distanceScale: HeatmapDendrogramDistanceScale.structural,
                  ),
                  style: style,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('heatmap-columns-dendrogram-canvas')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('heatmap-rows-dendrogram-canvas')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('clips leaf markers on the matrix-facing baseline half', (
    tester,
  ) async {
    final root = HeatmapClusterNode.fromJson(const {
      'id': 'axis:leaf:0',
      'distance': 0,
      'memberIndices': [0],
      'leafIndex': 0,
    });
    const style = HeatmapDendrogramStyle(
      showLeafBaseline: false,
      showLeafTicks: false,
      showLeafMarkers: true,
      leafMarkerColor: Color(0xFFFF0000),
      leafMarkerRadius: 6,
      leafMarkerBorderWidth: 0,
    );

    Future<ByteData> capture(HeatmapDendrogramAxis axis) async {
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: boundaryKey,
              child: SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Positioned.fill(
                      child: ColoredBox(color: Colors.white),
                    ),
                    Positioned(
                      left: 0,
                      top: 0,
                      width: 80,
                      height: 80,
                      child: HeatmapDendrogram(
                        data: HeatmapDendrogramData(
                          root: root,
                          sourceLabels: const ['Only'],
                          axis: axis,
                        ),
                        style: style,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      final boundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await tester.runAsync(
        () => boundary.toImage(pixelRatio: 1),
      );
      return (await tester.runAsync(
        () => image!.toByteData(format: ui.ImageByteFormat.rawRgba),
      ))!;
    }

    final columnPixels = await capture(HeatmapDendrogramAxis.columns);
    expect(_pixelAt(columnPixels, 100, 40, 76), _isRed);
    expect(_pixelAt(columnPixels, 100, 40, 82), _isWhite);

    final rowPixels = await capture(HeatmapDendrogramAxis.rows);
    expect(_pixelAt(rowPixels, 100, 76, 40), _isRed);
    expect(_pixelAt(rowPixels, 100, 82, 40), _isWhite);
  });
}

Map<String, dynamic> _balancedRootJson(int start, int end) {
  if (end - start == 1) {
    return {
      'id': 'axis:leaf:$start',
      'distance': 0,
      'memberIndices': [start],
      'leafIndex': start,
    };
  }
  final middle = (start + end) ~/ 2;
  return {
    'id': 'axis:$start-${end - 1}',
    'distance': (end - start).toDouble(),
    'memberIndices': [for (var index = start; index < end; index++) index],
    'left': _balancedRootJson(start, middle),
    'right': _balancedRootJson(middle, end),
  };
}

Color _pixelAt(ByteData bytes, int width, int x, int y) {
  final offset = (y * width + x) * 4;
  return Color.fromARGB(
    bytes.getUint8(offset + 3),
    bytes.getUint8(offset),
    bytes.getUint8(offset + 1),
    bytes.getUint8(offset + 2),
  );
}

final _isRed = predicate<Color>(
  (color) => color.r > 0.8 && color.g < 0.2 && color.b < 0.2,
  'is a red marker pixel',
);

final _isWhite = predicate<Color>(
  (color) => color.r > 0.95 && color.g > 0.95 && color.b > 0.95,
  'is an untouched white pixel',
);
