/// Contract tests for ScatterChartConfig
///
/// These tests verify that any implementation of ScatterChartConfig follows
/// the contract defined in specs/005-chart-types/contracts/scatter_chart_config.dart
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/src/charts/scatter/scatter_chart_config.dart';
import 'package:braven_charts/src/charts/base/chart_config.dart';

void main() {
  group('ScatterChartConfig Contract Tests', () {
    group('Validation Rules - Fixed Sizing Mode', () {
      test('sizingMode=fixed requires fixedSize > 0', () {
        expect(
          () => ScatterChartConfig(
            markerShape: MarkerShape.circle,
            sizingMode: MarkerSizingMode.fixed,
            fixedSize: 0.0, // INVALID: must be > 0
            markerStyle: MarkerStyle.filled,
            borderWidth: 0.0,
            enableClustering: false,
            clusterThreshold: 2,
          ),
          throwsA(isA<AssertionError>()),
          reason: 'fixedSize must be > 0 when sizingMode is fixed',
        );
      });

      test('sizingMode=fixed requires fixedSize to be non-null', () {
        expect(
          () => ScatterChartConfig(
            markerShape: MarkerShape.circle,
            sizingMode: MarkerSizingMode.fixed,
            fixedSize: null, // INVALID: required for fixed mode
            markerStyle: MarkerStyle.filled,
            borderWidth: 0.0,
            enableClustering: false,
            clusterThreshold: 2,
          ),
          throwsA(isA<AssertionError>()),
          reason: 'fixedSize must be provided when sizingMode is fixed',
        );
      });

      test('sizingMode=fixed with negative fixedSize is invalid', () {
        expect(
          () => ScatterChartConfig(
            markerShape: MarkerShape.circle,
            sizingMode: MarkerSizingMode.fixed,
            fixedSize: -5.0, // INVALID: negative
            markerStyle: MarkerStyle.filled,
            borderWidth: 0.0,
            enableClustering: false,
            clusterThreshold: 2,
          ),
          throwsA(isA<AssertionError>()),
          reason: 'fixedSize must be positive',
        );
      });
    });

    group('Validation Rules - Data-Driven Sizing Mode', () {
      test('sizingMode=dataDriven requires minSize < maxSize', () {
        final config = ScatterChartConfig(
          markerShape: MarkerShape.circle,
          sizingMode: MarkerSizingMode.dataDriven,
          minSize: 10.0,
          maxSize: 5.0, // INVALID: maxSize < minSize
          markerStyle: MarkerStyle.filled,
          borderWidth: 0.0,
          enableClustering: false,
          clusterThreshold: 2,
        );
        
        // This validation is checked in validate() method, not in constructor
        // (const constructors can't use null-aware operators in assertions)
        expect(
          () => config.validate(),
          throwsA(isA<ArgumentError>()),
          reason: 'minSize must be < maxSize for data-driven sizing',
        );
      });

      test('sizingMode=dataDriven requires minSize to be non-null', () {
        expect(
          () => ScatterChartConfig(
            markerShape: MarkerShape.circle,
            sizingMode: MarkerSizingMode.dataDriven,
            minSize: null, // INVALID: required for data-driven mode
            maxSize: 20.0,
            markerStyle: MarkerStyle.filled,
            borderWidth: 0.0,
            enableClustering: false,
            clusterThreshold: 2,
          ),
          throwsA(isA<AssertionError>()),
          reason: 'minSize must be provided when sizingMode is dataDriven',
        );
      });

      test('sizingMode=dataDriven requires maxSize to be non-null', () {
        expect(
          () => ScatterChartConfig(
            markerShape: MarkerShape.circle,
            sizingMode: MarkerSizingMode.dataDriven,
            minSize: 5.0,
            maxSize: null, // INVALID: required for data-driven mode
            markerStyle: MarkerStyle.filled,
            borderWidth: 0.0,
            enableClustering: false,
            clusterThreshold: 2,
          ),
          throwsA(isA<AssertionError>()),
          reason: 'maxSize must be provided when sizingMode is dataDriven',
        );
      });

      test('sizingMode=dataDriven with valid range is accepted', () {
        expect(
          () => ScatterChartConfig(
            markerShape: MarkerShape.circle,
            sizingMode: MarkerSizingMode.dataDriven,
            minSize: 5.0,
            maxSize: 20.0, // VALID: maxSize > minSize
            markerStyle: MarkerStyle.filled,
            borderWidth: 0.0,
            enableClustering: false,
            clusterThreshold: 2,
          ),
          returnsNormally,
        );
      });
    });

    group('Validation Rules - Clustering', () {
      test('clusterThreshold must be >= 2', () {
        expect(
          () => ScatterChartConfig(
            markerShape: MarkerShape.circle,
            sizingMode: MarkerSizingMode.fixed,
            fixedSize: 6.0,
            markerStyle: MarkerStyle.filled,
            borderWidth: 0.0,
            enableClustering: true,
            clusterThreshold: 1, // INVALID: must be >= 2
          ),
          throwsA(isA<AssertionError>()),
          reason: 'clusterThreshold must be at least 2 points',
        );
      });

      test('clusterThreshold = 2 is valid (minimum)', () {
        expect(
          () => ScatterChartConfig(
            markerShape: MarkerShape.circle,
            sizingMode: MarkerSizingMode.fixed,
            fixedSize: 6.0,
            markerStyle: MarkerStyle.filled,
            borderWidth: 0.0,
            enableClustering: true,
            clusterThreshold: 2, // VALID: minimum
          ),
          returnsNormally,
        );
      });
    });

    group('Validation Rules - Border Width', () {
      test('borderWidth must be >= 0.0', () {
        expect(
          () => ScatterChartConfig(
            markerShape: MarkerShape.circle,
            sizingMode: MarkerSizingMode.fixed,
            fixedSize: 6.0,
            markerStyle: MarkerStyle.filled,
            borderWidth: -1.0, // INVALID: negative
            enableClustering: false,
            clusterThreshold: 2,
          ),
          throwsA(isA<AssertionError>()),
          reason: 'borderWidth must be non-negative',
        );
      });
    });

    group('copyWith() behavior', () {
      test('copyWith creates new instance with modified properties', () {
        final original = ScatterChartConfig(
          markerShape: MarkerShape.circle,
          sizingMode: MarkerSizingMode.fixed,
          fixedSize: 6.0,
          markerStyle: MarkerStyle.filled,
          borderWidth: 0.0,
          enableClustering: false,
          clusterThreshold: 2,
        );

        final modified = original.copyWith(
          markerShape: MarkerShape.square,
          fixedSize: 8.0,
        );

        expect(modified.markerShape, equals(MarkerShape.square));
        expect(modified.fixedSize, equals(8.0));
        expect(modified.sizingMode, equals(original.sizingMode));
        expect(modified.markerStyle, equals(original.markerStyle));
      });

      test('copyWith without arguments returns equivalent instance', () {
        final original = ScatterChartConfig(
          markerShape: MarkerShape.circle,
          sizingMode: MarkerSizingMode.fixed,
          fixedSize: 6.0,
          markerStyle: MarkerStyle.filled,
          borderWidth: 0.0,
          enableClustering: false,
          clusterThreshold: 2,
        );

        final copy = original.copyWith();

        expect(copy.markerShape, equals(original.markerShape));
        expect(copy.sizingMode, equals(original.sizingMode));
        expect(copy.fixedSize, equals(original.fixedSize));
        expect(copy.markerStyle, equals(original.markerStyle));
        expect(copy.borderWidth, equals(original.borderWidth));
        expect(copy.enableClustering, equals(original.enableClustering));
        expect(copy.clusterThreshold, equals(original.clusterThreshold));
      });
    });

    group('validate() method', () {
      test('validate() does not throw for valid config', () {
        final config = ScatterChartConfig(
          markerShape: MarkerShape.circle,
          sizingMode: MarkerSizingMode.fixed,
          fixedSize: 6.0,
          markerStyle: MarkerStyle.filled,
          borderWidth: 0.0,
          enableClustering: false,
          clusterThreshold: 2,
        );

        expect(() => config.validate(), returnsNormally);
      });
    });
  });
}
