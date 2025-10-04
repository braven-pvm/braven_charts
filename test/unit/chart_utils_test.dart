import 'package:flutter_test/flutter_test.dart';
import '../test_utils.dart';

/// Unit tests for chart utility functions and data processing
void main() {
  group('Chart Utilities', () {
    test('should process chart data correctly', () {
      final data = TestUtils.getTestChartData();
      
      expect(data, hasLength(5));
      expect(data.first['x'], 0);
      expect(data.first['y'], 10);
      expect(data.last['x'], 4);
      expect(data.last['y'], 25);
    });

    test('should handle empty data sets', () {
      final emptyData = <Map<String, dynamic>>[];
      
      expect(emptyData, isEmpty);
      expect(() => emptyData.first, throwsStateError);
    });

    test('should validate data format', () {
      final validData = [
        {'x': 0, 'y': 10, 'label': 'Point 1'},
        {'x': 1, 'y': 20, 'label': 'Point 2'},
      ];
      
      for (final point in validData) {
        expect(point, containsPair('x', isA<int>()));
        expect(point, containsPair('y', isA<int>()));
        expect(point, containsPair('label', isA<String>()));
      }
    });

    test('should calculate data ranges', () {
      final data = TestUtils.getTestChartData();
      
      final xValues = data.map((point) => point['x'] as num).toList();
      final yValues = data.map((point) => point['y'] as num).toList();
      
      expect(xValues.reduce((a, b) => a < b ? a : b), 0); // min x
      expect(xValues.reduce((a, b) => a > b ? a : b), 4); // max x
      expect(yValues.reduce((a, b) => a < b ? a : b), 10); // min y
      expect(yValues.reduce((a, b) => a > b ? a : b), 30); // max y
    });

    test('should generate large datasets efficiently', () {
      final sizes = [100, 1000, 10000];
      
      for (final size in sizes) {
        final stopwatch = Stopwatch()..start();
        final data = TestUtils.getLargeTestDataset(size);
        stopwatch.stop();
        
        expect(data, hasLength(size));
        expect(stopwatch.elapsedMilliseconds, lessThan(100)); // Should be fast
        
        // Verify data structure
        expect(data.first, containsPair('x', 0));
        expect(data.last, containsPair('x', size - 1));
      }
    });

    test('should handle mathematical operations on chart data', () {
      final data = TestUtils.getTestChartData();
      
      // Calculate sum of y values
      final sum = data.fold<num>(0, (sum, point) => sum + (point['y'] as num));
      expect(sum, 100); // 10 + 20 + 15 + 30 + 25
      
      // Calculate average
      final average = sum / data.length;
      expect(average, 20.0);
      
      // Find maximum y value
      final maxY = data.map((p) => p['y'] as num).reduce((a, b) => a > b ? a : b);
      expect(maxY, 30);
    });

    test('should handle floating point precision', () {
      final preciseData = [
        {'x': 0.1, 'y': 10.123456789},
        {'x': 0.2, 'y': 20.987654321},
      ];
      
      final point1 = preciseData[0];
      final point2 = preciseData[1];
      
      expect(point1['y'], TestUtils.closeTo(10.123, tolerance: 0.001));
      expect(point2['y'], TestUtils.closeTo(20.988, tolerance: 0.001));
    });

    test('should validate custom matcher functionality', () {
      expect(1.0, TestUtils.closeTo(1.0, tolerance: 0.001));
      expect(1.0005, TestUtils.closeTo(1.0, tolerance: 0.001));
      expect(1.002, isNot(TestUtils.closeTo(1.0, tolerance: 0.001)));
      
      expect(3.14159, TestUtils.closeTo(3.14, tolerance: 0.01));
      expect(3.15, isNot(TestUtils.closeTo(3.14, tolerance: 0.001)));
    });
  });

  group('Data Transformation', () {
    test('should normalize data points', () {
      final data = TestUtils.getTestChartData();
      final yValues = data.map((p) => p['y'] as num).toList();
      
      final minY = yValues.reduce((a, b) => a < b ? a : b);
      final maxY = yValues.reduce((a, b) => a > b ? a : b);
      final range = maxY - minY;
      
      expect(minY, 10);
      expect(maxY, 30);
      expect(range, 20);
      
      // Normalize to 0-1 range
      final normalized = yValues.map((y) => (y - minY) / range).toList();
      
      expect(normalized.first, 0.0); // (10-10)/20 = 0
      expect(normalized[1], 0.5); // (20-10)/20 = 0.5
      expect(normalized.last, TestUtils.closeTo(0.75)); // (25-10)/20 = 0.75
    });

    test('should interpolate between data points', () {
      final point1 = {'x': 0, 'y': 10};
      final point2 = {'x': 10, 'y': 20};
      
      // Linear interpolation at x = 5 (midpoint)
      final x1 = point1['x'] as num;
      final y1 = point1['y'] as num;
      final x2 = point2['x'] as num;
      final y2 = point2['y'] as num;
      
      final x = 5;
      final y = y1 + (y2 - y1) * (x - x1) / (x2 - x1);
      
      expect(y, 15); // Should be exactly halfway between 10 and 20
    });

    test('should handle data smoothing concepts', () {
      final noisyData = [
        {'x': 0, 'y': 10},
        {'x': 1, 'y': 12},
        {'x': 2, 'y': 8}, // outlier
        {'x': 3, 'y': 14},
        {'x': 4, 'y': 16},
      ];
      
      // Simple moving average with window size 3
      final smoothed = <Map<String, dynamic>>[];
      for (int i = 1; i < noisyData.length - 1; i++) {
        final prev = noisyData[i - 1]['y'] as num;
        final curr = noisyData[i]['y'] as num;
        final next = noisyData[i + 1]['y'] as num;
        
        final avgY = (prev + curr + next) / 3;
        smoothed.add({'x': noisyData[i]['x'], 'y': avgY});
      }
      
      expect(smoothed, hasLength(3));
      expect(smoothed[1]['y'], TestUtils.closeTo(11.33, tolerance: 0.01)); // (12+8+14)/3
    });
  });
}