// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:braven_charts/src/elements/heatmap_raster_element.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HeatmapRasterElement', () {
    test('paints mounted image at transformed finite data bounds', () async {
      final resource = _solidImageResource(const Color(0xFFFF0000));
      final element = HeatmapRasterElement(
        snapshot: _snapshot(resource),
        transform: _transform(),
        filterQuality: ui.FilterQuality.none,
      );

      final image = _paintElement(element);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      expect(_pixel(bytes!, image.width, 30, 60), const <int>[255, 0, 0, 255]);
      expect(_pixel(bytes, image.width, 10, 10), const <int>[0, 0, 0, 0]);
      expect(resource.isDisposed, isFalse);

      image.dispose();
      resource.dispose();
    });

    test('follows an updated Cartesian transform without owning disposal', () {
      final resource = _solidImageResource(const Color(0xFF00FF00));
      final element = HeatmapRasterElement(
        snapshot: _snapshot(resource),
        transform: _transform(),
      );
      expect(element.bounds, const Rect.fromLTRB(20, 50, 40, 70));

      element.updateTransform(
        const ChartTransform(
          dataXMin: 0,
          dataXMax: 5,
          dataYMin: 0,
          dataYMax: 10,
          plotWidth: 100,
          plotHeight: 100,
        ),
      );
      expect(element.bounds, const Rect.fromLTRB(40, 50, 80, 70));
      expect(resource.isDisposed, isFalse);

      resource.dispose();
    });

    testWidgets('raster controller keeps an otherwise empty chart mounted', (
      tester,
    ) async {
      final source = _RasterSource();
      final controller = HeatmapRasterViewportController(
        source: source,
        maxCachedTiles: 1,
        maxTilesPerViewport: 1,
      );
      await controller.loadViewport(
        const HeatmapViewportRequest(
          minimumX: -0.5,
          maximumX: 1.5,
          minimumY: -0.5,
          maximumY: 1.5,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChartPlus(
              series: const [],
              width: 300,
              height: 200,
              heatmapRasterViewportController: controller,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('braven_chart_empty_state')),
        findsNothing,
      );
      expect(source.resource!.isDisposed, isFalse);

      await tester.pumpWidget(const SizedBox.shrink());
      expect(source.resource!.isDisposed, isFalse);
      controller.dispose();
      expect(source.resource!.isDisposed, isTrue);
    });
  });
}

HeatmapRasterImageResource _solidImageResource(Color color) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(const Rect.fromLTWH(0, 0, 2, 2), Paint()..color = color);
  return HeatmapRasterImageResource(
    image: recorder.endRecording().toImageSync(2, 2),
  );
}

HeatmapRasterViewportSnapshot _snapshot(HeatmapRasterImageResource resource) {
  const viewport = HeatmapViewportRequest(
    minimumX: 2,
    maximumX: 4,
    minimumY: 3,
    maximumY: 5,
  );
  return HeatmapRasterViewportSnapshot(
    generation: 1,
    requestedViewport: viewport,
    mountedViewport: viewport,
    requestedTileKeys: const [HeatmapTileKey(column: 0, row: 0)],
    mountedTiles: [
      HeatmapRasterTile(
        key: const HeatmapTileKey(column: 0, row: 0),
        bounds: viewport,
        resource: resource,
      ),
    ],
    semanticDescriptor: null,
    isLoading: false,
    diagnostics: const HeatmapRasterViewportDiagnostics(
      generation: 1,
      cachedTileCount: 1,
      decodedCacheBytes: 16,
      cacheHits: 0,
      cacheMisses: 1,
      loadsStarted: 1,
      evictions: 0,
      resourcesDisposed: 0,
      stalePublicationsRejected: 0,
    ),
  );
}

ChartTransform _transform() => const ChartTransform(
  dataXMin: 0,
  dataXMax: 10,
  dataYMin: 0,
  dataYMax: 10,
  plotWidth: 100,
  plotHeight: 100,
);

ui.Image _paintElement(HeatmapRasterElement element) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  element.paint(canvas, const Size(100, 100));
  return recorder.endRecording().toImageSync(100, 100);
}

List<int> _pixel(ByteData bytes, int width, int x, int y) {
  final offset = (y * width + x) * 4;
  return <int>[
    bytes.getUint8(offset),
    bytes.getUint8(offset + 1),
    bytes.getUint8(offset + 2),
    bytes.getUint8(offset + 3),
  ];
}

final class _RasterSource implements HeatmapRasterTileSource {
  @override
  final HeatmapMatrixDomain domain = HeatmapMatrixDomain(
    columnCount: 2,
    rowCount: 2,
  );

  @override
  int get tileColumnCount => 2;

  @override
  int get tileRowCount => 2;

  HeatmapRasterImageResource? resource;

  @override
  Future<HeatmapRasterTile> loadTile(HeatmapTileRequest request) async {
    final next = _solidImageResource(const Color(0xFF123456));
    resource = next;
    return HeatmapRasterTile(
      key: request.key,
      bounds: domain.fullBounds,
      resource: next,
    );
  }
}
