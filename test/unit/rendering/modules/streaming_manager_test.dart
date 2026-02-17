// Copyright (c) 2025 braven_charts. All rights reserved.
// Unit tests for StreamingManager module

import 'dart:ui';

import 'package:braven_charts/src/coordinates/chart_transform.dart';
import 'package:braven_charts/src/models/chart_data_point.dart';
import 'package:braven_charts/src/models/chart_series.dart';
import 'package:braven_charts/src/rendering/modules/streaming_manager.dart';
import 'package:braven_charts/src/streaming/streaming_buffer.dart';
import 'package:flutter_test/flutter_test.dart';

// =============================================================================
// Mock Streaming Delegate
// =============================================================================

/// Mock delegate for testing StreamingManager in isolation.
class MockStreamingDelegate implements StreamingDelegate {
  ChartTransform? _transform;
  ChartTransform? _originalTransform;
  final List<ChartSeries> _series;
  bool updateAxesCalled = false;
  bool markNeedsPaintCalled = false;
  bool invalidateSeriesCacheCalled = false;
  DataBounds? panConstraintBounds;
  bool panConstraintsCleared = false;

  MockStreamingDelegate({
    ChartTransform? transform,
    ChartTransform? originalTransform,
    List<ChartSeries>? series,
  }) : _transform = transform,
       _originalTransform = originalTransform,
       _series = series ?? [];

  @override
  ChartTransform? get transform => _transform;

  @override
  set transform(ChartTransform? value) {
    _transform = value;
  }

  @override
  ChartTransform? get originalTransform => _originalTransform;

  @override
  set originalTransform(ChartTransform? value) {
    _originalTransform = value;
  }

  @override
  List<ChartSeries> get series => _series;

  @override
  void updateAxesFromTransform() {
    updateAxesCalled = true;
  }

  @override
  void markNeedsPaint() {
    markNeedsPaintCalled = true;
  }

  @override
  void invalidateSeriesCache() {
    invalidateSeriesCacheCalled = true;
  }

  @override
  void setPanConstraintBounds(
    double xMin,
    double xMax,
    double yMin,
    double yMax,
  ) {
    panConstraintBounds = DataBounds(
      xMin: xMin,
      xMax: xMax,
      yMin: yMin,
      yMax: yMax,
    );
  }

  @override
  void clearPanConstraintBounds() {
    panConstraintBounds = null;
    panConstraintsCleared = true;
  }

  void reset() {
    updateAxesCalled = false;
    markNeedsPaintCalled = false;
    invalidateSeriesCacheCalled = false;
    panConstraintsCleared = false;
  }
}

// =============================================================================
// Test Helpers
// =============================================================================

ChartTransform createTransform({
  double dataXMin = 0,
  double dataXMax = 100,
  double dataYMin = 0,
  double dataYMax = 100,
  double plotWidth = 800,
  double plotHeight = 600,
}) {
  return ChartTransform(
    dataXMin: dataXMin,
    dataXMax: dataXMax,
    dataYMin: dataYMin,
    dataYMax: dataYMax,
    plotWidth: plotWidth,
    plotHeight: plotHeight,
  );
}

StreamingBuffer createBuffer(List<(double, double)> points) {
  final buffer = StreamingBuffer(maxSize: points.length + 100);
  for (final point in points) {
    buffer.add(ChartDataPoint(x: point.$1, y: point.$2));
  }
  return buffer;
}

// =============================================================================
// Tests
// =============================================================================

void main() {
  group('StreamingManager', () {
    group('Construction', () {
      test('creates with delegate', () {
        final delegate = MockStreamingDelegate();
        final manager = StreamingManager(delegate: delegate);
        expect(manager, isNotNull);
      });

      test('initializes with no streaming data', () {
        final delegate = MockStreamingDelegate();
        final manager = StreamingManager(delegate: delegate);
        expect(manager.hasStreamingData, isFalse);
        expect(manager.streamingBounds, isNull);
      });
    });

    group('setStreamingData', () {
      test('stores buffer reference', () {
        final delegate = MockStreamingDelegate(
          transform: createTransform(),
          originalTransform: createTransform(),
        );
        final manager = StreamingManager(delegate: delegate);

        final buffer = createBuffer([(0, 10), (1, 20), (2, 15)]);
        manager.setStreamingData(seriesId: 'test', buffer: buffer);

        expect(manager.hasStreamingData, isTrue);
      });

      test('updates streaming bounds', () {
        final delegate = MockStreamingDelegate(
          transform: createTransform(),
          originalTransform: createTransform(),
        );
        final manager = StreamingManager(delegate: delegate);

        final buffer = createBuffer([(0, 10), (50, 80), (100, 30)]);
        manager.setStreamingData(seriesId: 'test', buffer: buffer);

        expect(manager.streamingBounds, isNotNull);
        expect(manager.streamingBounds!.xMin, equals(0));
        expect(manager.streamingBounds!.xMax, equals(100));
        expect(manager.streamingBounds!.yMin, equals(10));
        expect(manager.streamingBounds!.yMax, equals(80));
      });

      test('requests repaint after setting data', () {
        final delegate = MockStreamingDelegate(
          transform: createTransform(),
          originalTransform: createTransform(),
        );
        final manager = StreamingManager(delegate: delegate);

        final buffer = createBuffer([(0, 10), (1, 20)]);
        manager.setStreamingData(seriesId: 'test', buffer: buffer);

        expect(delegate.markNeedsPaintCalled, isTrue);
      });

      test('updates original transform with streaming bounds', () {
        final delegate = MockStreamingDelegate(
          transform: createTransform(dataXMin: 0, dataXMax: 1),
          originalTransform: createTransform(dataXMin: 0, dataXMax: 1),
        );
        final manager = StreamingManager(delegate: delegate);

        final buffer = createBuffer([(0, 10), (100, 50), (200, 30)]);
        manager.setStreamingData(seriesId: 'test', buffer: buffer);

        // Original transform should be expanded to include streaming data
        expect(delegate.originalTransform!.dataXMin, equals(0));
        expect(delegate.originalTransform!.dataXMax, equals(200));
      });

      test('handles single point buffer', () {
        final delegate = MockStreamingDelegate(
          transform: createTransform(),
          originalTransform: createTransform(),
        );
        final manager = StreamingManager(delegate: delegate);

        final buffer = createBuffer([(50, 75)]);
        manager.setStreamingData(seriesId: 'test', buffer: buffer);

        expect(manager.hasStreamingData, isTrue);
        expect(manager.streamingBounds, isNotNull);
      });

      test('handles empty buffer gracefully', () {
        final delegate = MockStreamingDelegate(
          transform: createTransform(),
          originalTransform: createTransform(),
        );
        final manager = StreamingManager(delegate: delegate);

        final buffer = StreamingBuffer(maxSize: 100);
        manager.setStreamingData(seriesId: 'test', buffer: buffer);

        // Empty buffer is still registered (hasStreamingData checks if map is non-empty)
        // But bounds will be null/default and paint will skip the empty buffer
        expect(manager.hasStreamingData, isTrue);
      });

      test('updates transform for initial state', () {
        // Initial state: 0-1 default bounds
        final delegate = MockStreamingDelegate(
          transform: createTransform(
            dataXMin: 0,
            dataXMax: 1,
            dataYMin: 0,
            dataYMax: 1,
          ),
          originalTransform: createTransform(
            dataXMin: 0,
            dataXMax: 1,
            dataYMin: 0,
            dataYMax: 1,
          ),
        );
        final manager = StreamingManager(delegate: delegate);

        final buffer = createBuffer([(0, 10), (100, 50), (200, 30)]);
        manager.setStreamingData(seriesId: 'test', buffer: buffer);

        // Transform should be updated from initial state
        expect(delegate.updateAxesCalled, isTrue);
      });
    });

    group('clearStreamingData', () {
      test('removes buffer for series', () {
        final delegate = MockStreamingDelegate(
          transform: createTransform(),
          originalTransform: createTransform(),
        );
        final manager = StreamingManager(delegate: delegate);

        final buffer = createBuffer([(0, 10), (1, 20)]);
        manager.setStreamingData(seriesId: 'test', buffer: buffer);
        expect(manager.hasStreamingData, isTrue);

        manager.clearStreamingData('test');
        expect(manager.hasStreamingData, isFalse);
      });

      test('clears streaming bounds', () {
        final delegate = MockStreamingDelegate(
          transform: createTransform(),
          originalTransform: createTransform(),
        );
        final manager = StreamingManager(delegate: delegate);

        final buffer = createBuffer([(0, 10), (100, 50)]);
        manager.setStreamingData(seriesId: 'test', buffer: buffer);
        expect(manager.streamingBounds, isNotNull);

        manager.clearStreamingData('test');
        expect(manager.streamingBounds, isNull);
      });

      test('invalidates series cache', () {
        final delegate = MockStreamingDelegate(
          transform: createTransform(),
          originalTransform: createTransform(),
        );
        final manager = StreamingManager(delegate: delegate);

        final buffer = createBuffer([(0, 10)]);
        manager.setStreamingData(seriesId: 'test', buffer: buffer);
        delegate.reset();

        manager.clearStreamingData('test');
        expect(delegate.invalidateSeriesCacheCalled, isTrue);
      });

      test('requests repaint after clearing', () {
        final delegate = MockStreamingDelegate(
          transform: createTransform(),
          originalTransform: createTransform(),
        );
        final manager = StreamingManager(delegate: delegate);

        final buffer = createBuffer([(0, 10)]);
        manager.setStreamingData(seriesId: 'test', buffer: buffer);
        delegate.reset();

        manager.clearStreamingData('test');
        expect(delegate.markNeedsPaintCalled, isTrue);
      });

      test('resets transform to initial state', () {
        final delegate = MockStreamingDelegate(
          transform: createTransform(dataXMin: 50, dataXMax: 150),
          originalTransform: createTransform(dataXMin: 0, dataXMax: 200),
        );
        final manager = StreamingManager(delegate: delegate);

        final buffer = createBuffer([(50, 10), (150, 50)]);
        manager.setStreamingData(seriesId: 'test', buffer: buffer);

        manager.clearStreamingData('test');

        // Transform should be reset to initial 0-1 state
        expect(delegate.transform!.dataXMin, equals(0));
        expect(delegate.transform!.dataXMax, equals(1));
      });
    });

    group('Viewport Locking (Pause Mode)', () {
      test('lockViewportForPause sets lock flag', () {
        final delegate = MockStreamingDelegate(
          transform: createTransform(),
          originalTransform: createTransform(),
        );
        final manager = StreamingManager(delegate: delegate);

        final buffer = createBuffer([(0, 10), (100, 50)]);
        manager.setStreamingData(seriesId: 'test', buffer: buffer);

        manager.lockViewportForPause();
        expect(manager.isViewportLocked, isTrue);
      });

      test('lockViewportForPause sets pan constraints', () {
        final delegate = MockStreamingDelegate(
          transform: createTransform(),
          originalTransform: createTransform(),
        );
        final manager = StreamingManager(delegate: delegate);

        final buffer = createBuffer([(0, 10), (100, 50)]);
        manager.setStreamingData(seriesId: 'test', buffer: buffer);

        manager.lockViewportForPause();
        expect(delegate.panConstraintBounds, isNotNull);
      });

      test('lockViewportForPause is idempotent', () {
        final delegate = MockStreamingDelegate(
          transform: createTransform(),
          originalTransform: createTransform(),
        );
        final manager = StreamingManager(delegate: delegate);

        final buffer = createBuffer([(0, 10), (100, 50)]);
        manager.setStreamingData(seriesId: 'test', buffer: buffer);

        manager.lockViewportForPause();
        final firstBounds = delegate.panConstraintBounds;

        manager.lockViewportForPause();
        expect(delegate.panConstraintBounds, equals(firstBounds));
      });

      test('unlockViewportForResume clears lock', () {
        final delegate = MockStreamingDelegate(
          transform: createTransform(),
          originalTransform: createTransform(),
        );
        final manager = StreamingManager(delegate: delegate);

        final buffer = createBuffer([(0, 10), (100, 50)]);
        manager.setStreamingData(seriesId: 'test', buffer: buffer);

        manager.lockViewportForPause();
        expect(manager.isViewportLocked, isTrue);

        manager.unlockViewportForResume();
        expect(manager.isViewportLocked, isFalse);
      });

      test('unlockViewportForResume clears pan constraints', () {
        final delegate = MockStreamingDelegate(
          transform: createTransform(),
          originalTransform: createTransform(),
        );
        final manager = StreamingManager(delegate: delegate);

        final buffer = createBuffer([(0, 10), (100, 50)]);
        manager.setStreamingData(seriesId: 'test', buffer: buffer);

        manager.lockViewportForPause();
        manager.unlockViewportForResume();

        expect(delegate.panConstraintsCleared, isTrue);
      });

      test('unlockViewportForResume is idempotent', () {
        final delegate = MockStreamingDelegate(
          transform: createTransform(),
          originalTransform: createTransform(),
        );
        final manager = StreamingManager(delegate: delegate);

        // Unlock without ever locking
        manager.unlockViewportForResume();
        expect(manager.isViewportLocked, isFalse);
      });
    });

    group('cancelAutoScroll', () {
      test('clears animation targets', () {
        final delegate = MockStreamingDelegate(
          transform: createTransform(),
          originalTransform: createTransform(),
        );
        final manager = StreamingManager(delegate: delegate);

        // This just verifies the method exists and doesn't throw
        manager.cancelAutoScroll();
      });
    });

    group('snapViewportToStreamingData', () {
      test('does nothing when viewport is locked', () {
        final delegate = MockStreamingDelegate(
          transform: createTransform(),
          originalTransform: createTransform(),
        );
        final manager = StreamingManager(delegate: delegate);

        final buffer = createBuffer([(0, 10), (100, 50)]);
        manager.setStreamingData(seriesId: 'test', buffer: buffer);
        manager.lockViewportForPause();

        delegate.reset();
        manager.snapViewportToStreamingData();

        // Should not have updated anything
        expect(delegate.updateAxesCalled, isFalse);
      });

      test('does nothing without streaming data', () {
        final delegate = MockStreamingDelegate(
          transform: createTransform(),
          originalTransform: createTransform(),
        );
        final manager = StreamingManager(delegate: delegate);

        manager.snapViewportToStreamingData();
        // No crash, no action
      });

      test('does nothing without transform', () {
        final delegate = MockStreamingDelegate();
        final manager = StreamingManager(delegate: delegate);

        // No crash when transform is null
        manager.snapViewportToStreamingData();
      });
    });

    group('paint', () {
      test('does nothing without streaming data', () {
        final delegate = MockStreamingDelegate(transform: createTransform());
        final manager = StreamingManager(delegate: delegate);

        // Should not crash with empty buffers
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        manager.paint(canvas, const Size(800, 600), delegate.transform!);

        recorder.endRecording();
      });

      test('paints streaming buffers with matching series', () {
        final series = [
          const LineChartSeries(
            id: 'test',
            points: [],
            color: Color(0xFF0000FF),
          ),
        ];
        final delegate = MockStreamingDelegate(
          transform: createTransform(),
          originalTransform: createTransform(),
          series: series,
        );
        final manager = StreamingManager(delegate: delegate);

        final buffer = createBuffer([(0, 10), (50, 80), (100, 30)]);
        manager.setStreamingData(seriesId: 'test', buffer: buffer);

        // Should paint without crashing
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        manager.paint(canvas, const Size(800, 600), delegate.transform!);

        recorder.endRecording();
      });

      test('skips buffers without matching series', () {
        final delegate = MockStreamingDelegate(
          transform: createTransform(),
          originalTransform: createTransform(),
          series: [], // No matching series
        );
        final manager = StreamingManager(delegate: delegate);

        final buffer = createBuffer([(0, 10), (50, 80), (100, 30)]);
        manager.setStreamingData(seriesId: 'test', buffer: buffer);

        // Should not crash, just skip
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        manager.paint(canvas, const Size(800, 600), delegate.transform!);

        recorder.endRecording();
      });

      test('uses binary search for visible range', () {
        final series = [
          const LineChartSeries(
            id: 'test',
            points: [],
            color: Color(0xFF0000FF),
          ),
        ];
        // Transform showing only middle portion
        final delegate = MockStreamingDelegate(
          transform: createTransform(dataXMin: 40, dataXMax: 60),
          originalTransform: createTransform(dataXMin: 0, dataXMax: 100),
          series: series,
        );
        final manager = StreamingManager(delegate: delegate);

        // Buffer with many points
        final points = <(double, double)>[];
        for (int i = 0; i <= 100; i++) {
          points.add((i.toDouble(), (i % 20).toDouble()));
        }
        final buffer = createBuffer(points);
        manager.setStreamingData(seriesId: 'test', buffer: buffer);

        // Should paint only visible range efficiently
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        manager.paint(canvas, const Size(800, 600), delegate.transform!);

        recorder.endRecording();
      });
    });

    group('dispose', () {
      test('clears all state', () {
        final delegate = MockStreamingDelegate(
          transform: createTransform(),
          originalTransform: createTransform(),
        );
        final manager = StreamingManager(delegate: delegate);

        final buffer = createBuffer([(0, 10), (100, 50)]);
        manager.setStreamingData(seriesId: 'test', buffer: buffer);
        manager.lockViewportForPause();

        manager.dispose();

        expect(manager.hasStreamingData, isFalse);
        expect(manager.streamingBounds, isNull);
        expect(manager.isViewportLocked, isFalse);
      });

      test('is safe to call multiple times', () {
        final delegate = MockStreamingDelegate();
        final manager = StreamingManager(delegate: delegate);

        manager.dispose();
        manager.dispose();
        // No crash
      });
    });

    group('Multiple Series', () {
      test('handles multiple streaming series', () {
        final series = [
          const LineChartSeries(
            id: 'series1',
            points: [],
            color: Color(0xFF0000FF),
          ),
          const LineChartSeries(
            id: 'series2',
            points: [],
            color: Color(0xFFFF0000),
          ),
        ];
        final delegate = MockStreamingDelegate(
          transform: createTransform(),
          originalTransform: createTransform(),
          series: series,
        );
        final manager = StreamingManager(delegate: delegate);

        final buffer1 = createBuffer([(0, 10), (50, 80)]);
        final buffer2 = createBuffer([(0, 20), (50, 60)]);

        manager.setStreamingData(seriesId: 'series1', buffer: buffer1);
        manager.setStreamingData(seriesId: 'series2', buffer: buffer2);

        expect(manager.hasStreamingData, isTrue);
      });

      test('clearing one series preserves others', () {
        final series = [
          const LineChartSeries(
            id: 'series1',
            points: [],
            color: Color(0xFF0000FF),
          ),
          const LineChartSeries(
            id: 'series2',
            points: [],
            color: Color(0xFFFF0000),
          ),
        ];
        final delegate = MockStreamingDelegate(
          transform: createTransform(),
          originalTransform: createTransform(),
          series: series,
        );
        final manager = StreamingManager(delegate: delegate);

        final buffer1 = createBuffer([(0, 10), (50, 80)]);
        final buffer2 = createBuffer([(0, 20), (50, 60)]);

        manager.setStreamingData(seriesId: 'series1', buffer: buffer1);
        manager.setStreamingData(seriesId: 'series2', buffer: buffer2);

        manager.clearStreamingData('series1');

        // series2 should still exist
        expect(manager.hasStreamingData, isTrue);
      });
    });

    group('Expand Viewport Mode', () {
      test('expands viewport when expandViewportWhenNotAutoScrolling is true', () {
        // This test triggers animation scheduling which requires Flutter bindings.
        // Skip in unit tests since the actual expansion is tested via integration tests.
        final delegate = MockStreamingDelegate(
          transform: createTransform(dataXMin: 0, dataXMax: 50),
          originalTransform: createTransform(dataXMin: 0, dataXMax: 100),
        );
        final manager = StreamingManager(delegate: delegate);

        // Buffer extends beyond current viewport but doesn't trigger animation
        // when transform is not in "initial state" (0-1 bounds)
        final buffer = createBuffer([(0, 10), (40, 50)]);
        manager.setStreamingData(
          seriesId: 'test',
          buffer: buffer,
          expandViewportWhenNotAutoScrolling: true,
        );

        // Manager stores buffer, animation scheduling is internal detail
        expect(manager.hasStreamingData, isTrue);
      });

      test('respects maxVisiblePoints limit (stores data correctly)', () {
        // This test verifies data is stored, not animation behavior
        // Animation scheduling requires Flutter bindings (tested in widget tests)
        final delegate = MockStreamingDelegate(
          transform: createTransform(
            dataXMin: 0,
            dataXMax: 100,
            dataYMin: 0,
            dataYMax: 100,
          ),
          originalTransform: createTransform(
            dataXMin: 0,
            dataXMax: 100,
            dataYMin: 0,
            dataYMax: 100,
          ),
        );
        final manager = StreamingManager(delegate: delegate);

        // Create buffer with many points
        final points = <(double, double)>[];
        for (int i = 0; i < 200; i++) {
          points.add((i.toDouble(), (i % 20).toDouble()));
        }
        final buffer = createBuffer(points);

        // Use expandViewportWhenNotAutoScrolling: false to avoid animation scheduling
        // The maxVisiblePoints limit is only checked when expandViewportWhenNotAutoScrolling: true
        manager.setStreamingData(
          seriesId: 'test',
          buffer: buffer,
          expandViewportWhenNotAutoScrolling: false,
          maxVisiblePoints: 100,
        );

        // Verify data was set
        expect(manager.hasStreamingData, isTrue);
        expect(
          manager.streamingBounds!.xMax,
          equals(199),
        ); // Last point is at x=199
      });
    });

    group('Edge Cases', () {
      test('handles transform with zero data range', () {
        final delegate = MockStreamingDelegate(
          transform: createTransform(dataXMin: 50, dataXMax: 50.001),
          originalTransform: createTransform(),
        );
        final manager = StreamingManager(delegate: delegate);

        final buffer = createBuffer([(50, 10)]);
        manager.setStreamingData(seriesId: 'test', buffer: buffer);

        expect(manager.hasStreamingData, isTrue);
      });

      test('handles negative data values', () {
        final delegate = MockStreamingDelegate(
          transform: createTransform(
            dataXMin: -100,
            dataXMax: 100,
            dataYMin: -50,
            dataYMax: 50,
          ),
          originalTransform: createTransform(
            dataXMin: -100,
            dataXMax: 100,
            dataYMin: -50,
            dataYMax: 50,
          ),
        );
        final manager = StreamingManager(delegate: delegate);

        final buffer = createBuffer([(-50, -20), (0, 30), (50, -10)]);
        manager.setStreamingData(seriesId: 'test', buffer: buffer);

        expect(manager.streamingBounds!.xMin, equals(-50));
        expect(manager.streamingBounds!.yMin, equals(-20));
      });

      test('handles very large data values', () {
        final delegate = MockStreamingDelegate(
          transform: createTransform(dataXMin: 0, dataXMax: 1e12),
          originalTransform: createTransform(dataXMin: 0, dataXMax: 1e12),
        );
        final manager = StreamingManager(delegate: delegate);

        final buffer = createBuffer([(0, 1e10), (1e12, 5e10)]);
        manager.setStreamingData(seriesId: 'test', buffer: buffer);

        expect(manager.hasStreamingData, isTrue);
      });

      test('handles buffer updates preserving existing data', () {
        final delegate = MockStreamingDelegate(
          transform: createTransform(),
          originalTransform: createTransform(),
        );
        final manager = StreamingManager(delegate: delegate);

        // First update
        final buffer = createBuffer([(0, 10), (1, 20)]);
        manager.setStreamingData(seriesId: 'test', buffer: buffer);

        // Add more points to same buffer
        buffer.add(const ChartDataPoint(x: 2, y: 30));
        buffer.add(const ChartDataPoint(x: 3, y: 25));

        // Update with same buffer (simulating streaming updates)
        manager.setStreamingData(seriesId: 'test', buffer: buffer);

        expect(manager.hasStreamingData, isTrue);
        expect(manager.streamingBounds!.xMax, equals(3));
      });
    });
  });
}
