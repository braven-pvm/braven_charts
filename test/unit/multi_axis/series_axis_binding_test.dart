import 'package:braven_charts/src/models/series_axis_binding.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SeriesAxisBinding', () {
    group('construction', () {
      test('creates with valid IDs', () {
        final binding = const SeriesAxisBinding(
          seriesId: 'power',
          yAxisId: 'power-axis',
        );

        expect(binding.seriesId, equals('power'));
        expect(binding.yAxisId, equals('power-axis'));
      });

      test('is const-constructible', () {
        // Verify const constructor works
        const binding = SeriesAxisBinding(
          seriesId: 'test-series',
          yAxisId: 'test-axis',
        );

        expect(binding.seriesId, equals('test-series'));
        expect(binding.yAxisId, equals('test-axis'));
      });

      test('multiple series can reference same axis', () {
        const binding1 = SeriesAxisBinding(
          seriesId: 'heartrate',
          yAxisId: 'shared-axis',
        );

        const binding2 = SeriesAxisBinding(
          seriesId: 'cadence',
          yAxisId: 'shared-axis',
        );

        expect(binding1.yAxisId, equals(binding2.yAxisId));
        expect(binding1.seriesId, isNot(equals(binding2.seriesId)));
      });
    });

    group('validation', () {
      test('throws assertion error for empty seriesId', () {
        expect(
          () => SeriesAxisBinding(seriesId: '', yAxisId: 'valid-axis'),
          throwsA(isA<AssertionError>()),
        );
      });

      test('throws assertion error for empty yAxisId', () {
        expect(
          () => SeriesAxisBinding(seriesId: 'valid-series', yAxisId: ''),
          throwsA(isA<AssertionError>()),
        );
      });

      test('throws assertion error for both empty', () {
        expect(
          () => SeriesAxisBinding(seriesId: '', yAxisId: ''),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('equality', () {
      test('same IDs are equal', () {
        const binding1 = SeriesAxisBinding(
          seriesId: 'power',
          yAxisId: 'power-axis',
        );

        const binding2 = SeriesAxisBinding(
          seriesId: 'power',
          yAxisId: 'power-axis',
        );

        expect(binding1, equals(binding2));
      });

      test('different seriesId are not equal', () {
        const binding1 = SeriesAxisBinding(
          seriesId: 'power',
          yAxisId: 'shared-axis',
        );

        const binding2 = SeriesAxisBinding(
          seriesId: 'heartrate',
          yAxisId: 'shared-axis',
        );

        expect(binding1, isNot(equals(binding2)));
      });

      test('different yAxisId are not equal', () {
        const binding1 = SeriesAxisBinding(
          seriesId: 'power',
          yAxisId: 'left-axis',
        );

        const binding2 = SeriesAxisBinding(
          seriesId: 'power',
          yAxisId: 'right-axis',
        );

        expect(binding1, isNot(equals(binding2)));
      });

      test('hashCode is consistent with equality', () {
        const binding1 = SeriesAxisBinding(
          seriesId: 'power',
          yAxisId: 'power-axis',
        );

        const binding2 = SeriesAxisBinding(
          seriesId: 'power',
          yAxisId: 'power-axis',
        );

        expect(binding1.hashCode, equals(binding2.hashCode));
      });

      test('identical objects are equal', () {
        const binding = SeriesAxisBinding(
          seriesId: 'test',
          yAxisId: 'test-axis',
        );

        expect(binding, equals(binding));
      });
    });

    group('toString', () {
      test('contains seriesId', () {
        const binding = SeriesAxisBinding(
          seriesId: 'power-series',
          yAxisId: 'left-axis',
        );

        expect(binding.toString(), contains('power-series'));
      });

      test('contains yAxisId', () {
        const binding = SeriesAxisBinding(
          seriesId: 'power-series',
          yAxisId: 'left-axis',
        );

        expect(binding.toString(), contains('left-axis'));
      });

      test('contains class name', () {
        const binding = SeriesAxisBinding(
          seriesId: 'test',
          yAxisId: 'test-axis',
        );

        expect(binding.toString(), contains('SeriesAxisBinding'));
      });
    });
  });
}
