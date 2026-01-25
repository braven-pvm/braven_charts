// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

// @orchestra-task: 2

@Tags(['tdd-red'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/src/agentic/models/models.dart';

void main() {
  group('AxisType', () {
    test('has all required enum values', () {
      expect(AxisType.values.contains(AxisType.numeric), isTrue);
      expect(AxisType.values.contains(AxisType.time), isTrue);
      expect(AxisType.values.contains(AxisType.category), isTrue);
    });
  });

  group('AxisPosition', () {
    test('has all required enum values', () {
      expect(AxisPosition.values.contains(AxisPosition.left), isTrue);
      expect(AxisPosition.values.contains(AxisPosition.right), isTrue);
    });
  });

  group('XAxisConfig', () {
    group('constructor', () {
      test('creates instance with default parameters', () {
        final config = XAxisConfig();

        expect(config.label, isNull);
        expect(config.unit, isNull);
        expect(config.type, equals(AxisType.numeric));
        expect(config.autoRange, isTrue);
        expect(config.showTicks, isTrue);
        expect(config.showAxisLine, isTrue);
        expect(config.showGridLines, isTrue);
      });

      test('creates instance with all parameters', () {
        final config = XAxisConfig(
          label: 'Time',
          unit: 'seconds',
          type: AxisType.time,
          min: 0,
          max: 3600,
          autoRange: false,
          paddingPercent: 5.0,
          tickCount: 10,
          tickFormat: 'HH:mm:ss',
          tickRotation: 45.0,
          showTicks: true,
          showAxisLine: true,
          showGridLines: false,
          gridColor: '#CCCCCC',
          gridDash: [5.0, 3.0],
        );

        expect(config.label, equals('Time'));
        expect(config.unit, equals('seconds'));
        expect(config.type, equals(AxisType.time));
        expect(config.min, equals(0));
        expect(config.max, equals(3600));
        expect(config.autoRange, isFalse);
        expect(config.paddingPercent, equals(5.0));
        expect(config.tickCount, equals(10));
        expect(config.tickFormat, equals('HH:mm:ss'));
        expect(config.tickRotation, equals(45.0));
        expect(config.showGridLines, isFalse);
        expect(config.gridColor, equals('#CCCCCC'));
        expect(config.gridDash, equals([5.0, 3.0]));
      });

      test('creates numeric axis configuration', () {
        final config = XAxisConfig(
          label: 'Distance',
          unit: 'km',
          type: AxisType.numeric,
          min: 0,
          max: 100,
        );

        expect(config.type, equals(AxisType.numeric));
        expect(config.label, equals('Distance'));
        expect(config.unit, equals('km'));
      });

      test('creates time axis configuration', () {
        final config = XAxisConfig(
          label: 'Time',
          type: AxisType.time,
          tickFormat: 'HH:mm',
        );

        expect(config.type, equals(AxisType.time));
        expect(config.tickFormat, equals('HH:mm'));
      });

      test('creates category axis configuration', () {
        final config = XAxisConfig(
          label: 'Day',
          type: AxisType.category,
          showGridLines: false,
        );

        expect(config.type, equals(AxisType.category));
        expect(config.showGridLines, isFalse);
      });

      test('throws assertion error when min > max', () {
        expect(
          () => XAxisConfig(
            min: 100,
            max: 50,
          ),
          throwsAssertionError,
        );
      });

      test('throws assertion error when paddingPercent is negative', () {
        expect(
          () => XAxisConfig(
            paddingPercent: -5.0,
          ),
          throwsAssertionError,
        );
      });

      test('throws assertion error when tickCount is less than 2', () {
        expect(
          () => XAxisConfig(
            tickCount: 1,
          ),
          throwsAssertionError,
        );
      });

      test('allows tickCount of 2', () {
        final config = XAxisConfig(tickCount: 2);
        expect(config.tickCount, equals(2));
      });
    });

    group('JSON serialization', () {
      test('toJson converts to map correctly', () {
        final config = XAxisConfig(
          label: 'Time',
          type: AxisType.time,
          min: 0,
          max: 3600,
          showGridLines: false,
        );

        final json = config.toJson();

        expect(json['label'], equals('Time'));
        expect(json['type'], equals('time'));
        expect(json['min'], equals(0));
        expect(json['max'], equals(3600));
        expect(json['showGridLines'], isFalse);
      });

      test('fromJson creates instance from map', () {
        final json = {
          'label': 'Distance',
          'unit': 'km',
          'type': 'numeric',
          'min': 0.0,
          'max': 50.0,
          'autoRange': false,
        };

        final config = XAxisConfig.fromJson(json);

        expect(config.label, equals('Distance'));
        expect(config.unit, equals('km'));
        expect(config.type, equals(AxisType.numeric));
        expect(config.min, equals(0.0));
        expect(config.max, equals(50.0));
        expect(config.autoRange, isFalse);
      });

      test('JSON round-trip preserves data', () {
        final original = XAxisConfig(
          label: 'Elapsed Time',
          unit: 's',
          type: AxisType.time,
          min: 0,
          max: 7200,
          autoRange: false,
          paddingPercent: 2.0,
          tickCount: 8,
          tickFormat: 'HH:mm:ss',
          tickRotation: 30.0,
          showTicks: true,
          showAxisLine: true,
          showGridLines: true,
          gridColor: '#E0E0E0',
          gridDash: [4.0, 2.0],
        );

        final json = original.toJson();
        final restored = XAxisConfig.fromJson(json);

        expect(restored.label, equals(original.label));
        expect(restored.unit, equals(original.unit));
        expect(restored.type, equals(original.type));
        expect(restored.min, equals(original.min));
        expect(restored.max, equals(original.max));
        expect(restored.paddingPercent, equals(original.paddingPercent));
        expect(restored.tickCount, equals(original.tickCount));
        expect(restored.tickFormat, equals(original.tickFormat));
      });
    });

    group('copyWith', () {
      test('creates copy with updated label', () {
        final original = XAxisConfig(label: 'Original');
        final copy = original.copyWith(label: 'Updated');

        expect(copy.label, equals('Updated'));
        expect(original.label, equals('Original'));
      });

      test('creates copy with updated min and max', () {
        final original = XAxisConfig(min: 0, max: 100);
        final copy = original.copyWith(min: 10, max: 90);

        expect(copy.min, equals(10));
        expect(copy.max, equals(90));
      });

      test('creates copy with toggled visibility options', () {
        final original = XAxisConfig(
          showTicks: true,
          showAxisLine: true,
          showGridLines: true,
        );

        final copy = original.copyWith(
          showTicks: false,
          showGridLines: false,
        );

        expect(copy.showTicks, isFalse);
        expect(copy.showAxisLine, isTrue);
        expect(copy.showGridLines, isFalse);
      });
    });

    group('equality', () {
      test('equal configurations have same hash code', () {
        final config1 = XAxisConfig(
          label: 'Time',
          type: AxisType.time,
          min: 0,
          max: 3600,
        );

        final config2 = XAxisConfig(
          label: 'Time',
          type: AxisType.time,
          min: 0,
          max: 3600,
        );

        expect(config1, equals(config2));
        expect(config1.hashCode, equals(config2.hashCode));
      });
    });
  });

  group('YAxisConfig', () {
    group('constructor', () {
      test('creates instance with default parameters', () {
        final config = YAxisConfig(
          position: AxisPosition.left,
        );

        expect(config.id, isNull);
        expect(config.label, isNull);
        expect(config.unit, isNull);
        expect(config.position, equals(AxisPosition.left));
        expect(config.autoRange, isTrue);
        expect(config.includeZero, isFalse);
        expect(config.showTicks, isTrue);
        expect(config.showAxisLine, isTrue);
        expect(config.showGridLines, isTrue);
      });

      test('creates instance with all parameters', () {
        final config = YAxisConfig(
          id: 'y-axis-1',
          label: 'Power',
          unit: 'W',
          position: AxisPosition.left,
          min: 0,
          max: 500,
          autoRange: false,
          includeZero: true,
          paddingPercent: 10.0,
          tickCount: 6,
          tickFormat: '0.0',
          showTicks: true,
          showAxisLine: true,
          showGridLines: true,
          gridColor: '#DDDDDD',
          color: '#FF0000',
        );

        expect(config.id, equals('y-axis-1'));
        expect(config.label, equals('Power'));
        expect(config.unit, equals('W'));
        expect(config.position, equals(AxisPosition.left));
        expect(config.min, equals(0));
        expect(config.max, equals(500));
        expect(config.autoRange, isFalse);
        expect(config.includeZero, isTrue);
        expect(config.paddingPercent, equals(10.0));
        expect(config.tickCount, equals(6));
        expect(config.tickFormat, equals('0.0'));
        expect(config.gridColor, equals('#DDDDDD'));
        expect(config.color, equals('#FF0000'));
      });

      test('creates left-positioned axis', () {
        final config = YAxisConfig(
          id: 'y-left',
          label: 'Power',
          position: AxisPosition.left,
        );

        expect(config.position, equals(AxisPosition.left));
      });

      test('creates right-positioned axis', () {
        final config = YAxisConfig(
          id: 'y-right',
          label: 'Heart Rate',
          position: AxisPosition.right,
        );

        expect(config.position, equals(AxisPosition.right));
      });

      test('creates axis with includeZero option', () {
        final config = YAxisConfig(
          position: AxisPosition.left,
          includeZero: true,
        );

        expect(config.includeZero, isTrue);
      });

      test('throws assertion error when min > max', () {
        expect(
          () => YAxisConfig(
            position: AxisPosition.left,
            min: 100,
            max: 50,
          ),
          throwsAssertionError,
        );
      });

      test('throws assertion error when paddingPercent is negative', () {
        expect(
          () => YAxisConfig(
            position: AxisPosition.left,
            paddingPercent: -5.0,
          ),
          throwsAssertionError,
        );
      });

      test('throws assertion error when tickCount is less than 2', () {
        expect(
          () => YAxisConfig(
            position: AxisPosition.left,
            tickCount: 1,
          ),
          throwsAssertionError,
        );
      });
    });

    group('JSON serialization', () {
      test('toJson converts to map correctly', () {
        final config = YAxisConfig(
          id: 'y-1',
          label: 'Power',
          unit: 'W',
          position: AxisPosition.left,
          min: 0,
          max: 400,
          includeZero: true,
        );

        final json = config.toJson();

        expect(json['id'], equals('y-1'));
        expect(json['label'], equals('Power'));
        expect(json['unit'], equals('W'));
        expect(json['position'], equals('left'));
        expect(json['min'], equals(0));
        expect(json['max'], equals(400));
        expect(json['includeZero'], isTrue);
      });

      test('fromJson creates instance from map', () {
        final json = {
          'id': 'y-2',
          'label': 'Heart Rate',
          'unit': 'bpm',
          'position': 'right',
          'min': 100.0,
          'max': 200.0,
          'autoRange': false,
        };

        final config = YAxisConfig.fromJson(json);

        expect(config.id, equals('y-2'));
        expect(config.label, equals('Heart Rate'));
        expect(config.unit, equals('bpm'));
        expect(config.position, equals(AxisPosition.right));
        expect(config.min, equals(100.0));
        expect(config.max, equals(200.0));
        expect(config.autoRange, isFalse);
      });

      test('JSON round-trip preserves data', () {
        final original = YAxisConfig(
          id: 'y-power',
          label: 'Power Output',
          unit: 'watts',
          position: AxisPosition.left,
          min: 0,
          max: 500,
          autoRange: false,
          includeZero: true,
          paddingPercent: 5.0,
          tickCount: 6,
          tickFormat: '0',
          showTicks: true,
          showAxisLine: true,
          showGridLines: true,
          gridColor: '#E5E5E5',
          color: '#0000FF',
        );

        final json = original.toJson();
        final restored = YAxisConfig.fromJson(json);

        expect(restored.id, equals(original.id));
        expect(restored.label, equals(original.label));
        expect(restored.unit, equals(original.unit));
        expect(restored.position, equals(original.position));
        expect(restored.min, equals(original.min));
        expect(restored.max, equals(original.max));
        expect(restored.includeZero, equals(original.includeZero));
        expect(restored.paddingPercent, equals(original.paddingPercent));
        expect(restored.color, equals(original.color));
      });
    });

    group('copyWith', () {
      test('creates copy with updated label', () {
        final original = YAxisConfig(
          position: AxisPosition.left,
          label: 'Original',
        );
        final copy = original.copyWith(label: 'Updated');

        expect(copy.label, equals('Updated'));
        expect(original.label, equals('Original'));
      });

      test('creates copy with updated min and max', () {
        final original = YAxisConfig(
          position: AxisPosition.left,
          min: 0,
          max: 100,
        );
        final copy = original.copyWith(min: 50, max: 150);

        expect(copy.min, equals(50));
        expect(copy.max, equals(150));
      });

      test('creates copy with changed position', () {
        final original = YAxisConfig(
          position: AxisPosition.left,
        );
        final copy = original.copyWith(position: AxisPosition.right);

        expect(copy.position, equals(AxisPosition.right));
        expect(original.position, equals(AxisPosition.left));
      });

      test('creates copy with toggled includeZero', () {
        final original = YAxisConfig(
          position: AxisPosition.left,
          includeZero: false,
        );
        final copy = original.copyWith(includeZero: true);

        expect(copy.includeZero, isTrue);
        expect(original.includeZero, isFalse);
      });
    });

    group('equality', () {
      test('equal configurations have same hash code', () {
        final config1 = YAxisConfig(
          id: 'y-1',
          label: 'Power',
          position: AxisPosition.left,
          min: 0,
          max: 500,
        );

        final config2 = YAxisConfig(
          id: 'y-1',
          label: 'Power',
          position: AxisPosition.left,
          min: 0,
          max: 500,
        );

        expect(config1, equals(config2));
        expect(config1.hashCode, equals(config2.hashCode));
      });

      test('different positions produce different configurations', () {
        final config1 = YAxisConfig(
          id: 'y-1',
          position: AxisPosition.left,
        );

        final config2 = YAxisConfig(
          id: 'y-1',
          position: AxisPosition.right,
        );

        expect(config1, isNot(equals(config2)));
      });
    });

    group('multi-axis support', () {
      test('creates multiple y-axes with unique ids', () {
        final axis1 = YAxisConfig(
          id: 'y-power',
          label: 'Power',
          position: AxisPosition.left,
        );

        final axis2 = YAxisConfig(
          id: 'y-hr',
          label: 'Heart Rate',
          position: AxisPosition.right,
        );

        expect(axis1.id, equals('y-power'));
        expect(axis2.id, equals('y-hr'));
        expect(axis1.position, equals(AxisPosition.left));
        expect(axis2.position, equals(AxisPosition.right));
      });

      test('allows up to 4 y-axes in a configuration', () {
        final axes = [
          YAxisConfig(id: 'y1', position: AxisPosition.left),
          YAxisConfig(id: 'y2', position: AxisPosition.right),
          YAxisConfig(id: 'y3', position: AxisPosition.left),
          YAxisConfig(id: 'y4', position: AxisPosition.right),
        ];

        expect(axes.length, equals(4));
        expect(axes.every((a) => a.id != null), isTrue);
      });
    });
  });

  group('axis integration', () {
    test('x-axis and y-axis work together in chart configuration', () {
      final xAxis = XAxisConfig(
        label: 'Time',
        type: AxisType.time,
        min: 0,
        max: 3600,
      );

      final yAxis1 = YAxisConfig(
        id: 'y-power',
        label: 'Power',
        position: AxisPosition.left,
        min: 0,
        max: 500,
      );

      final yAxis2 = YAxisConfig(
        id: 'y-hr',
        label: 'Heart Rate',
        position: AxisPosition.right,
        min: 100,
        max: 200,
      );

      expect(xAxis.label, equals('Time'));
      expect(yAxis1.label, equals('Power'));
      expect(yAxis2.label, equals('Heart Rate'));
      expect(yAxis1.position, equals(AxisPosition.left));
      expect(yAxis2.position, equals(AxisPosition.right));
    });
  });
}
