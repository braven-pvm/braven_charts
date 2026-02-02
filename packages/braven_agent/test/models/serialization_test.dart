import 'package:braven_agent/src/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ============================================================
  // DataPoint Tests
  // ============================================================
  group('DataPoint', () {
    test('fromJson creates correct instance from Map', () {
      final json = {'x': 1.0, 'y': 2.5};
      final point = DataPoint.fromJson(json);

      expect(point.x, equals(1.0));
      expect(point.y, equals(2.5));
    });

    test('fromJson handles int values by converting to double', () {
      final json = {'x': 1, 'y': 2};
      final point = DataPoint.fromJson(json);

      expect(point.x, equals(1.0));
      expect(point.y, equals(2.0));
    });

    test('toJson produces correct Map', () {
      const point = DataPoint(x: 3.5, y: 4.5);
      final json = point.toJson();

      expect(json['x'], equals(3.5));
      expect(json['y'], equals(4.5));
    });

    test('round-trip: fromJson(toJson()) equals original', () {
      const original = DataPoint(x: 10.0, y: 20.0);
      final restored = DataPoint.fromJson(original.toJson());

      expect(restored, equals(original));
    });

    test('copyWith with no args returns equal instance', () {
      const original = DataPoint(x: 5.0, y: 6.0);
      final copy = original.copyWith();

      expect(copy, equals(original));
    });

    test('copyWith with args updates only specified fields', () {
      const original = DataPoint(x: 5.0, y: 6.0);
      final updated = original.copyWith(x: 10.0);

      expect(updated.x, equals(10.0));
      expect(updated.y, equals(6.0));
    });

    test('equality: same values are equal', () {
      const point1 = DataPoint(x: 1.0, y: 2.0);
      const point2 = DataPoint(x: 1.0, y: 2.0);

      expect(point1, equals(point2));
      expect(point1.hashCode, equals(point2.hashCode));
    });

    test('equality: different values are not equal', () {
      const point1 = DataPoint(x: 1.0, y: 2.0);
      const point2 = DataPoint(x: 1.0, y: 3.0);

      expect(point1, isNot(equals(point2)));
    });
  });

  // ============================================================
  // Enum Serialization Tests
  // ============================================================
  group('Enums', () {
    group('ChartType', () {
      test('all values serialize correctly', () {
        for (final value in ChartType.values) {
          final name = value.name;
          final restored = ChartType.values.byName(name);
          expect(restored, equals(value));
        }
      });

      test('individual values have correct names', () {
        expect(ChartType.line.name, equals('line'));
        expect(ChartType.area.name, equals('area'));
        expect(ChartType.bar.name, equals('bar'));
        expect(ChartType.scatter.name, equals('scatter'));
      });
    });

    group('MarkerStyle', () {
      test('all values serialize correctly', () {
        for (final value in MarkerStyle.values) {
          final name = value.name;
          final restored = MarkerStyle.values.byName(name);
          expect(restored, equals(value));
        }
      });

      test('individual values have correct names', () {
        expect(MarkerStyle.none.name, equals('none'));
        expect(MarkerStyle.circle.name, equals('circle'));
        expect(MarkerStyle.square.name, equals('square'));
        expect(MarkerStyle.triangle.name, equals('triangle'));
        expect(MarkerStyle.diamond.name, equals('diamond'));
      });
    });

    group('Interpolation', () {
      test('all values serialize correctly', () {
        for (final value in Interpolation.values) {
          final name = value.name;
          final restored = Interpolation.values.byName(name);
          expect(restored, equals(value));
        }
      });

      test('individual values have correct names', () {
        expect(Interpolation.linear.name, equals('linear'));
        expect(Interpolation.bezier.name, equals('bezier'));
        expect(Interpolation.stepped.name, equals('stepped'));
        expect(Interpolation.monotone.name, equals('monotone'));
      });
    });

    group('AxisType', () {
      test('all values serialize correctly', () {
        for (final value in AxisType.values) {
          final name = value.name;
          final restored = AxisType.values.byName(name);
          expect(restored, equals(value));
        }
      });

      test('individual values have correct names', () {
        expect(AxisType.numeric.name, equals('numeric'));
        expect(AxisType.time.name, equals('time'));
        expect(AxisType.category.name, equals('category'));
      });
    });

    group('AxisPosition', () {
      test('all values serialize correctly', () {
        for (final value in AxisPosition.values) {
          final name = value.name;
          final restored = AxisPosition.values.byName(name);
          expect(restored, equals(value));
        }
      });

      test('individual values have correct names', () {
        expect(AxisPosition.left.name, equals('left'));
        expect(AxisPosition.right.name, equals('right'));
      });
    });

    group('NormalizationModeConfig', () {
      test('all values serialize correctly', () {
        for (final value in NormalizationModeConfig.values) {
          final name = value.name;
          final restored = NormalizationModeConfig.values.byName(name);
          expect(restored, equals(value));
        }
      });

      test('individual values have correct names', () {
        expect(NormalizationModeConfig.none.name, equals('none'));
        expect(NormalizationModeConfig.auto.name, equals('auto'));
        expect(NormalizationModeConfig.perSeries.name, equals('perSeries'));
      });
    });

    group('LegendPosition', () {
      test('all values serialize correctly', () {
        for (final value in LegendPosition.values) {
          final name = value.name;
          final restored = LegendPosition.values.byName(name);
          expect(restored, equals(value));
        }
      });

      test('individual values have correct names', () {
        expect(LegendPosition.top.name, equals('top'));
        expect(LegendPosition.bottom.name, equals('bottom'));
        expect(LegendPosition.left.name, equals('left'));
        expect(LegendPosition.right.name, equals('right'));
        expect(LegendPosition.topLeft.name, equals('topLeft'));
        expect(LegendPosition.topRight.name, equals('topRight'));
        expect(LegendPosition.bottomLeft.name, equals('bottomLeft'));
        expect(LegendPosition.bottomRight.name, equals('bottomRight'));
      });
    });

    group('AnnotationType', () {
      test('all values serialize correctly', () {
        for (final value in AnnotationType.values) {
          final name = value.name;
          final restored = AnnotationType.values.byName(name);
          expect(restored, equals(value));
        }
      });

      test('individual values have correct names', () {
        expect(AnnotationType.referenceLine.name, equals('referenceLine'));
        expect(AnnotationType.zone.name, equals('zone'));
        expect(AnnotationType.textLabel.name, equals('textLabel'));
        expect(AnnotationType.marker.name, equals('marker'));
      });
    });

    group('Orientation', () {
      test('all values serialize correctly', () {
        for (final value in Orientation.values) {
          final name = value.name;
          final restored = Orientation.values.byName(name);
          expect(restored, equals(value));
        }
      });

      test('individual values have correct names', () {
        expect(Orientation.horizontal.name, equals('horizontal'));
        expect(Orientation.vertical.name, equals('vertical'));
      });
    });

    group('AnnotationPosition', () {
      test('all values serialize correctly', () {
        for (final value in AnnotationPosition.values) {
          final name = value.name;
          final restored = AnnotationPosition.values.byName(name);
          expect(restored, equals(value));
        }
      });

      test('individual values have correct names', () {
        expect(AnnotationPosition.topLeft.name, equals('topLeft'));
        expect(AnnotationPosition.topCenter.name, equals('topCenter'));
        expect(AnnotationPosition.topRight.name, equals('topRight'));
        expect(AnnotationPosition.centerLeft.name, equals('centerLeft'));
        expect(AnnotationPosition.center.name, equals('center'));
        expect(AnnotationPosition.centerRight.name, equals('centerRight'));
        expect(AnnotationPosition.bottomLeft.name, equals('bottomLeft'));
        expect(AnnotationPosition.bottomCenter.name, equals('bottomCenter'));
        expect(AnnotationPosition.bottomRight.name, equals('bottomRight'));
      });
    });
  });

  // ============================================================
  // SeriesConfig Tests
  // ============================================================
  group('SeriesConfig', () {
    SeriesConfig createFullSeriesConfig() {
      return const SeriesConfig(
        id: 'series1',
        name: 'Temperature',
        data: [
          DataPoint(x: 0, y: 20),
          DataPoint(x: 1, y: 22),
          DataPoint(x: 2, y: 21),
        ],
        color: '#FF5733',
        strokeWidth: 3.0,
        strokeDash: [5.0, 3.0],
        fillOpacity: 0.5,
        markerStyle: MarkerStyle.circle,
        markerSize: 6.0,
        interpolation: Interpolation.bezier,
        tension: 0.5,
        showPoints: true,
        // Use nested yAxis instead of flat fields per FR-001/FR-002
        yAxis: YAxisConfig(
          position: AxisPosition.left,
          label: 'Temp',
          unit: '°C',
          color: '#333333',
          min: 0.0,
          max: 100.0,
        ),
        barWidthPercent: 0.8,
        barWidthPixels: 20.0,
        barMinWidth: 5.0,
        barMaxWidth: 50.0,
        visible: true,
        legendVisible: true,
        unit: 'W',
      );
    }

    test('fromJson creates correct instance from Map', () {
      final json = {
        'id': 'series1',
        'name': 'Temperature',
        'data': [
          {'x': 0.0, 'y': 20.0},
          {'x': 1.0, 'y': 22.0},
        ],
        'color': '#FF5733',
        'strokeWidth': 3.0,
        'markerStyle': 'circle',
        'interpolation': 'bezier',
      };

      final series = SeriesConfig.fromJson(json);

      expect(series.id, equals('series1'));
      expect(series.name, equals('Temperature'));
      expect(series.data.length, equals(2));
      expect(series.data[0].x, equals(0.0));
      expect(series.data[0].y, equals(20.0));
      expect(series.color, equals('#FF5733'));
      expect(series.strokeWidth, equals(3.0));
      expect(series.markerStyle, equals(MarkerStyle.circle));
      expect(series.interpolation, equals(Interpolation.bezier));
    });

    test('fromJson applies default values for missing fields', () {
      final json = {
        'id': 'minimal',
        'data': <Map<String, dynamic>>[],
      };

      final series = SeriesConfig.fromJson(json);

      expect(series.strokeWidth, equals(2.0));
      expect(series.fillOpacity, equals(0.0));
      expect(series.markerStyle, equals(MarkerStyle.none));
      expect(series.markerSize, equals(4.0));
      expect(series.interpolation, equals(Interpolation.linear));
      expect(series.tension, equals(0.4));
      expect(series.showPoints, isFalse);
      expect(series.visible, isTrue);
      expect(series.legendVisible, isTrue);
    });

    test('toJson produces correct Map', () {
      final series = createFullSeriesConfig();
      final json = series.toJson();

      expect(json['id'], equals('series1'));
      expect(json['name'], equals('Temperature'));
      expect(json['data'], isList);
      expect((json['data'] as List).length, equals(3));
      expect(json['color'], equals('#FF5733'));
      expect(json['strokeWidth'], equals(3.0));
      expect(json['strokeDash'], equals([5.0, 3.0]));
      expect(json['markerStyle'], equals('circle'));
      expect(json['interpolation'], equals('bezier'));
    });

    test('round-trip: fromJson(toJson()) equals original', () {
      final original = createFullSeriesConfig();
      final restored = SeriesConfig.fromJson(original.toJson());

      expect(restored, equals(original));
    });

    test('nested DataPoint list serializes correctly in round-trip', () {
      const original = SeriesConfig(
        id: 'test',
        data: [
          DataPoint(x: 0, y: 10),
          DataPoint(x: 1, y: 20),
          DataPoint(x: 2, y: 30),
        ],
      );

      final json = original.toJson();
      final restored = SeriesConfig.fromJson(json);

      expect(restored.data.length, equals(3));
      expect(restored.data[0], equals(const DataPoint(x: 0, y: 10)));
      expect(restored.data[1], equals(const DataPoint(x: 1, y: 20)));
      expect(restored.data[2], equals(const DataPoint(x: 2, y: 30)));
    });

    test('copyWith with no args returns equal instance', () {
      final original = createFullSeriesConfig();
      final copy = original.copyWith();

      expect(copy, equals(original));
    });

    test('copyWith with args updates only specified fields', () {
      final original = createFullSeriesConfig();
      final updated = original.copyWith(
        name: 'Updated Name',
        strokeWidth: 5.0,
      );

      expect(updated.name, equals('Updated Name'));
      expect(updated.strokeWidth, equals(5.0));
      expect(updated.id, equals(original.id));
      expect(updated.color, equals(original.color));
    });

    test('equality: same values are equal', () {
      final series1 = createFullSeriesConfig();
      final series2 = createFullSeriesConfig();

      expect(series1, equals(series2));
    });

    test('equality: different values are not equal', () {
      final series1 = createFullSeriesConfig();
      final series2 = series1.copyWith(id: 'different-id');

      expect(series1, isNot(equals(series2)));
    });
  });

  // ============================================================
  // XAxisConfig Tests
  // ============================================================
  group('XAxisConfig', () {
    XAxisConfig createFullXAxisConfig() {
      return const XAxisConfig(
        label: 'Time',
        unit: 'seconds',
        type: AxisType.time,
        min: 0.0,
        max: 100.0,
        autoRange: false,
        paddingPercent: 0.1,
        tickCount: 10,
        tickFormat: '%.1f',
        tickRotation: 45.0,
        showTicks: true,
        showAxisLine: true,
        showGridLines: true,
        gridColor: '#CCCCCC',
        gridDash: [5.0, 3.0],
      );
    }

    test('fromJson creates correct instance from Map', () {
      final json = {
        'label': 'Time',
        'unit': 'seconds',
        'type': 'time',
        'min': 0.0,
        'max': 100.0,
        'autoRange': false,
        'tickCount': 10,
      };

      final xAxis = XAxisConfig.fromJson(json);

      expect(xAxis.label, equals('Time'));
      expect(xAxis.unit, equals('seconds'));
      expect(xAxis.type, equals(AxisType.time));
      expect(xAxis.min, equals(0.0));
      expect(xAxis.max, equals(100.0));
      expect(xAxis.autoRange, isFalse);
      expect(xAxis.tickCount, equals(10));
    });

    test('fromJson applies default values for missing fields', () {
      final json = <String, dynamic>{};

      final xAxis = XAxisConfig.fromJson(json);

      expect(xAxis.type, equals(AxisType.numeric));
      expect(xAxis.autoRange, isTrue);
      expect(xAxis.paddingPercent, equals(0.0));
      expect(xAxis.tickRotation, equals(0.0));
      expect(xAxis.showTicks, isTrue);
      expect(xAxis.showAxisLine, isTrue);
      expect(xAxis.showGridLines, isTrue);
    });

    test('toJson produces correct Map', () {
      final xAxis = createFullXAxisConfig();
      final json = xAxis.toJson();

      expect(json['label'], equals('Time'));
      expect(json['unit'], equals('seconds'));
      expect(json['type'], equals('time'));
      expect(json['min'], equals(0.0));
      expect(json['max'], equals(100.0));
      expect(json['autoRange'], isFalse);
      expect(json['gridDash'], equals([5.0, 3.0]));
    });

    test('toJson omits null optional fields', () {
      const xAxis = XAxisConfig();
      final json = xAxis.toJson();

      expect(json.containsKey('label'), isFalse);
      expect(json.containsKey('unit'), isFalse);
      expect(json.containsKey('min'), isFalse);
      expect(json.containsKey('max'), isFalse);
    });

    test('round-trip: fromJson(toJson()) equals original', () {
      final original = createFullXAxisConfig();
      final restored = XAxisConfig.fromJson(original.toJson());

      expect(restored, equals(original));
    });

    test('copyWith with no args returns equal instance', () {
      final original = createFullXAxisConfig();
      final copy = original.copyWith();

      expect(copy, equals(original));
    });

    test('copyWith with args updates only specified fields', () {
      final original = createFullXAxisConfig();
      final updated = original.copyWith(
        label: 'Updated Label',
        type: AxisType.category,
      );

      expect(updated.label, equals('Updated Label'));
      expect(updated.type, equals(AxisType.category));
      expect(updated.unit, equals(original.unit));
      expect(updated.min, equals(original.min));
    });

    test('equality: same values are equal', () {
      final xAxis1 = createFullXAxisConfig();
      final xAxis2 = createFullXAxisConfig();

      expect(xAxis1, equals(xAxis2));
    });

    test('equality: different values are not equal', () {
      final xAxis1 = createFullXAxisConfig();
      final xAxis2 = xAxis1.copyWith(label: 'Different');

      expect(xAxis1, isNot(equals(xAxis2)));
    });
  });

  // ============================================================
  // YAxisConfig Tests
  // ============================================================
  group('YAxisConfig', () {
    YAxisConfig createFullYAxisConfig() {
      return const YAxisConfig(
        id: 'y1',
        label: 'Temperature',
        unit: '°C',
        position: AxisPosition.left,
        min: 0.0,
        max: 100.0,
        autoRange: false,
        includeZero: true,
        paddingPercent: 0.1,
        tickCount: 10,
        tickFormat: '%.1f',
        showTicks: true,
        showAxisLine: true,
        showGridLines: true,
        gridColor: '#CCCCCC',
        color: '#333333',
      );
    }

    test('fromJson creates correct instance from Map', () {
      final json = {
        'id': 'y1',
        'label': 'Temperature',
        'unit': '°C',
        'position': 'right',
        'min': 0.0,
        'max': 100.0,
        'includeZero': true,
      };

      final yAxis = YAxisConfig.fromJson(json);

      expect(yAxis.id, equals('y1'));
      expect(yAxis.label, equals('Temperature'));
      expect(yAxis.unit, equals('°C'));
      expect(yAxis.position, equals(AxisPosition.right));
      expect(yAxis.min, equals(0.0));
      expect(yAxis.max, equals(100.0));
      expect(yAxis.includeZero, isTrue);
    });

    test('fromJson applies default values for missing fields', () {
      final json = <String, dynamic>{};

      final yAxis = YAxisConfig.fromJson(json);

      expect(yAxis.position, equals(AxisPosition.left));
      expect(yAxis.autoRange, isTrue);
      expect(yAxis.includeZero, isFalse);
      expect(yAxis.paddingPercent, equals(0.0));
      expect(yAxis.showTicks, isTrue);
      expect(yAxis.showAxisLine, isTrue);
      expect(yAxis.showGridLines, isTrue);
    });

    test('toJson produces correct Map', () {
      final yAxis = createFullYAxisConfig();
      final json = yAxis.toJson();

      expect(json['id'], equals('y1'));
      expect(json['label'], equals('Temperature'));
      expect(json['unit'], equals('°C'));
      expect(json['position'], equals('left'));
      expect(json['min'], equals(0.0));
      expect(json['max'], equals(100.0));
      expect(json['includeZero'], isTrue);
      expect(json['color'], equals('#333333'));
    });

    test('toJson omits null optional fields', () {
      const yAxis = YAxisConfig();
      final json = yAxis.toJson();

      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('label'), isFalse);
      expect(json.containsKey('unit'), isFalse);
      expect(json.containsKey('min'), isFalse);
      expect(json.containsKey('max'), isFalse);
    });

    test('round-trip: fromJson(toJson()) equals original', () {
      final original = createFullYAxisConfig();
      final restored = YAxisConfig.fromJson(original.toJson());

      expect(restored, equals(original));
    });

    test('copyWith with no args returns equal instance', () {
      final original = createFullYAxisConfig();
      final copy = original.copyWith();

      expect(copy, equals(original));
    });

    test('copyWith with args updates only specified fields', () {
      final original = createFullYAxisConfig();
      final updated = original.copyWith(
        label: 'Updated Label',
        position: AxisPosition.right,
      );

      expect(updated.label, equals('Updated Label'));
      expect(updated.position, equals(AxisPosition.right));
      expect(updated.id, equals(original.id));
      expect(updated.unit, equals(original.unit));
    });

    test('equality: same values are equal', () {
      final yAxis1 = createFullYAxisConfig();
      final yAxis2 = createFullYAxisConfig();

      expect(yAxis1, equals(yAxis2));
    });

    test('equality: different values are not equal', () {
      final yAxis1 = createFullYAxisConfig();
      final yAxis2 = yAxis1.copyWith(id: 'different-id');

      expect(yAxis1, isNot(equals(yAxis2)));
    });
  });

  // ============================================================
  // AnnotationConfig Tests
  // ============================================================
  group('AnnotationConfig', () {
    group('referenceLine annotation', () {
      test('fromJson creates correct instance', () {
        final json = {
          'type': 'referenceLine',
          'orientation': 'horizontal',
          'value': 50.0,
          'label': 'Threshold',
          'color': '#FF0000',
        };

        final annotation = AnnotationConfig.fromJson(json);

        expect(annotation.type, equals(AnnotationType.referenceLine));
        expect(annotation.orientation, equals(Orientation.horizontal));
        expect(annotation.value, equals(50.0));
        expect(annotation.label, equals('Threshold'));
        expect(annotation.color, equals('#FF0000'));
      });

      test('toJson produces correct Map', () {
        const annotation = AnnotationConfig(
          type: AnnotationType.referenceLine,
          orientation: Orientation.horizontal,
          value: 50.0,
          label: 'Threshold',
          color: '#FF0000',
        );

        final json = annotation.toJson();

        expect(json['type'], equals('referenceLine'));
        expect(json['orientation'], equals('horizontal'));
        expect(json['value'], equals(50.0));
        expect(json['label'], equals('Threshold'));
      });

      test('round-trip preserves values', () {
        const original = AnnotationConfig(
          type: AnnotationType.referenceLine,
          orientation: Orientation.vertical,
          value: 100.0,
          label: 'Max',
          color: '#00FF00',
          opacity: 0.8,
        );

        final restored = AnnotationConfig.fromJson(original.toJson());
        expect(restored, equals(original));
      });
    });

    group('zone annotation', () {
      test('fromJson creates correct instance', () {
        final json = {
          'type': 'zone',
          'minValue': 80.0,
          'maxValue': 120.0,
          'color': '#00FF00',
          'opacity': 0.3,
        };

        final annotation = AnnotationConfig.fromJson(json);

        expect(annotation.type, equals(AnnotationType.zone));
        expect(annotation.minValue, equals(80.0));
        expect(annotation.maxValue, equals(120.0));
        expect(annotation.color, equals('#00FF00'));
        expect(annotation.opacity, equals(0.3));
      });

      test('toJson produces correct Map', () {
        const annotation = AnnotationConfig(
          type: AnnotationType.zone,
          minValue: 80.0,
          maxValue: 120.0,
          color: '#00FF00',
          opacity: 0.3,
        );

        final json = annotation.toJson();

        expect(json['type'], equals('zone'));
        expect(json['minValue'], equals(80.0));
        expect(json['maxValue'], equals(120.0));
      });

      test('round-trip preserves values', () {
        const original = AnnotationConfig(
          type: AnnotationType.zone,
          minValue: 50.0,
          maxValue: 75.0,
          color: '#FFFF00',
          opacity: 0.5,
          label: 'Warning Zone',
        );

        final restored = AnnotationConfig.fromJson(original.toJson());
        expect(restored, equals(original));
      });
    });

    group('textLabel annotation', () {
      test('fromJson creates correct instance', () {
        final json = {
          'type': 'textLabel',
          'text': 'Peak Value',
          'position': 'topRight',
          'x': 50.0,
          'y': 100.0,
        };

        final annotation = AnnotationConfig.fromJson(json);

        expect(annotation.type, equals(AnnotationType.textLabel));
        expect(annotation.text, equals('Peak Value'));
        expect(annotation.position, equals(AnnotationPosition.topRight));
        expect(annotation.x, equals(50.0));
        expect(annotation.y, equals(100.0));
      });

      test('toJson produces correct Map', () {
        const annotation = AnnotationConfig(
          type: AnnotationType.textLabel,
          text: 'Peak Value',
          position: AnnotationPosition.topCenter,
          x: 50.0,
          y: 100.0,
        );

        final json = annotation.toJson();

        expect(json['type'], equals('textLabel'));
        expect(json['text'], equals('Peak Value'));
        expect(json['position'], equals('topCenter'));
      });

      test('round-trip preserves values', () {
        const original = AnnotationConfig(
          type: AnnotationType.textLabel,
          text: 'Important Note',
          position: AnnotationPosition.center,
          color: '#333333',
        );

        final restored = AnnotationConfig.fromJson(original.toJson());
        expect(restored, equals(original));
      });
    });

    group('marker annotation', () {
      test('fromJson creates correct instance', () {
        final json = {
          'type': 'marker',
          'x': 25.0,
          'y': 75.0,
          'label': 'Max Point',
          'color': '#0000FF',
        };

        final annotation = AnnotationConfig.fromJson(json);

        expect(annotation.type, equals(AnnotationType.marker));
        expect(annotation.x, equals(25.0));
        expect(annotation.y, equals(75.0));
        expect(annotation.label, equals('Max Point'));
        expect(annotation.color, equals('#0000FF'));
      });

      test('toJson produces correct Map', () {
        const annotation = AnnotationConfig(
          type: AnnotationType.marker,
          x: 25.0,
          y: 75.0,
          label: 'Max Point',
          seriesId: 'series1',
        );

        final json = annotation.toJson();

        expect(json['type'], equals('marker'));
        expect(json['x'], equals(25.0));
        expect(json['y'], equals(75.0));
        expect(json['seriesId'], equals('series1'));
      });

      test('round-trip preserves values', () {
        const original = AnnotationConfig(
          type: AnnotationType.marker,
          x: 10.0,
          y: 90.0,
          position: AnnotationPosition.bottomLeft,
          seriesId: 'temp',
        );

        final restored = AnnotationConfig.fromJson(original.toJson());
        expect(restored, equals(original));
      });
    });

    test('copyWith with no args returns equal instance', () {
      const original = AnnotationConfig(
        type: AnnotationType.referenceLine,
        orientation: Orientation.horizontal,
        value: 50.0,
      );

      final copy = original.copyWith();
      expect(copy, equals(original));
    });

    test('copyWith with args updates only specified fields', () {
      const original = AnnotationConfig(
        type: AnnotationType.referenceLine,
        orientation: Orientation.horizontal,
        value: 50.0,
        label: 'Original',
      );

      final updated = original.copyWith(
        label: 'Updated',
        color: '#FF0000',
      );

      expect(updated.label, equals('Updated'));
      expect(updated.color, equals('#FF0000'));
      expect(updated.type, equals(original.type));
      expect(updated.value, equals(original.value));
    });

    test('equality: same values are equal', () {
      const annotation1 = AnnotationConfig(
        type: AnnotationType.zone,
        minValue: 10.0,
        maxValue: 20.0,
      );
      const annotation2 = AnnotationConfig(
        type: AnnotationType.zone,
        minValue: 10.0,
        maxValue: 20.0,
      );

      expect(annotation1, equals(annotation2));
    });

    test('equality: different values are not equal', () {
      const annotation1 = AnnotationConfig(
        type: AnnotationType.zone,
        minValue: 10.0,
        maxValue: 20.0,
      );
      const annotation2 = AnnotationConfig(
        type: AnnotationType.zone,
        minValue: 10.0,
        maxValue: 30.0,
      );

      expect(annotation1, isNot(equals(annotation2)));
    });
  });

  // ============================================================
  // ChartStyleConfig Tests
  // ============================================================
  group('ChartStyleConfig', () {
    ChartStyleConfig createFullChartStyleConfig() {
      return const ChartStyleConfig(
        backgroundColor: '#FFFFFF',
        gridColor: '#E0E0E0',
        axisColor: '#333333',
        fontFamily: 'Roboto',
        fontSize: 12.0,
        paddingTop: 16.0,
        paddingBottom: 16.0,
        paddingLeft: 24.0,
        paddingRight: 24.0,
      );
    }

    test('fromJson creates correct instance from Map', () {
      final json = {
        'backgroundColor': '#FFFFFF',
        'gridColor': '#E0E0E0',
        'axisColor': '#333333',
        'fontFamily': 'Roboto',
        'fontSize': 12.0,
        'paddingTop': 16.0,
        'paddingBottom': 16.0,
        'paddingLeft': 24.0,
        'paddingRight': 24.0,
      };

      final style = ChartStyleConfig.fromJson(json);

      expect(style.backgroundColor, equals('#FFFFFF'));
      expect(style.gridColor, equals('#E0E0E0'));
      expect(style.axisColor, equals('#333333'));
      expect(style.fontFamily, equals('Roboto'));
      expect(style.fontSize, equals(12.0));
      expect(style.paddingTop, equals(16.0));
      expect(style.paddingBottom, equals(16.0));
      expect(style.paddingLeft, equals(24.0));
      expect(style.paddingRight, equals(24.0));
    });

    test('fromJson handles all null fields gracefully', () {
      final json = <String, dynamic>{};

      final style = ChartStyleConfig.fromJson(json);

      expect(style.backgroundColor, isNull);
      expect(style.gridColor, isNull);
      expect(style.axisColor, isNull);
      expect(style.fontFamily, isNull);
      expect(style.fontSize, isNull);
      expect(style.paddingTop, isNull);
      expect(style.paddingBottom, isNull);
      expect(style.paddingLeft, isNull);
      expect(style.paddingRight, isNull);
    });

    test('toJson produces correct Map', () {
      final style = createFullChartStyleConfig();
      final json = style.toJson();

      expect(json['backgroundColor'], equals('#FFFFFF'));
      expect(json['gridColor'], equals('#E0E0E0'));
      expect(json['axisColor'], equals('#333333'));
      expect(json['fontFamily'], equals('Roboto'));
      expect(json['fontSize'], equals(12.0));
    });

    test('toJson omits null fields', () {
      const style = ChartStyleConfig(
        backgroundColor: '#FFFFFF',
      );

      final json = style.toJson();

      expect(json.containsKey('backgroundColor'), isTrue);
      expect(json.containsKey('gridColor'), isFalse);
      expect(json.containsKey('axisColor'), isFalse);
      expect(json.containsKey('fontFamily'), isFalse);
      expect(json.containsKey('fontSize'), isFalse);
      expect(json.containsKey('paddingTop'), isFalse);
    });

    test('round-trip: fromJson(toJson()) equals original', () {
      final original = createFullChartStyleConfig();
      final restored = ChartStyleConfig.fromJson(original.toJson());

      expect(restored, equals(original));
    });

    test('round-trip with partial fields', () {
      const original = ChartStyleConfig(
        backgroundColor: '#000000',
        fontSize: 14.0,
      );

      final restored = ChartStyleConfig.fromJson(original.toJson());
      expect(restored, equals(original));
    });

    test('copyWith with no args returns equal instance', () {
      final original = createFullChartStyleConfig();
      final copy = original.copyWith();

      expect(copy, equals(original));
    });

    test('copyWith with args updates only specified fields', () {
      final original = createFullChartStyleConfig();
      final updated = original.copyWith(
        backgroundColor: '#000000',
        fontSize: 14.0,
      );

      expect(updated.backgroundColor, equals('#000000'));
      expect(updated.fontSize, equals(14.0));
      expect(updated.gridColor, equals(original.gridColor));
      expect(updated.fontFamily, equals(original.fontFamily));
    });

    test('equality: same values are equal', () {
      final style1 = createFullChartStyleConfig();
      final style2 = createFullChartStyleConfig();

      expect(style1, equals(style2));
    });

    test('equality: different values are not equal', () {
      final style1 = createFullChartStyleConfig();
      final style2 = style1.copyWith(backgroundColor: '#000000');

      expect(style1, isNot(equals(style2)));
    });

    test('empty instances are equal', () {
      const style1 = ChartStyleConfig();
      const style2 = ChartStyleConfig();

      expect(style1, equals(style2));
    });
  });

  // ============================================================
  // ChartConfiguration Tests
  // ============================================================
  group('ChartConfiguration', () {
    ChartConfiguration createFullChartConfiguration() {
      return const ChartConfiguration(
        id: 'chart1',
        title: 'Temperature Over Time',
        subtitle: 'Daily readings',
        series: [
          SeriesConfig(
            id: 'temp',
            name: 'Temperature',
            data: [
              DataPoint(x: 0, y: 20),
              DataPoint(x: 1, y: 22),
              DataPoint(x: 2, y: 21),
            ],
            color: '#FF5733',
            // Per FR-001: nested yAxis instead of flat fields
            yAxis: YAxisConfig(
              position: AxisPosition.left,
              label: 'Temperature',
              unit: '°C',
            ),
          ),
          SeriesConfig(
            id: 'humidity',
            name: 'Humidity',
            data: [
              DataPoint(x: 0, y: 60),
              DataPoint(x: 1, y: 65),
              DataPoint(x: 2, y: 62),
            ],
            color: '#3366FF',
            // Per FR-001: nested yAxis instead of flat fields
            yAxis: YAxisConfig(
              position: AxisPosition.right,
              label: 'Humidity',
              unit: '%',
            ),
          ),
        ],
        xAxis: XAxisConfig(
          label: 'Time',
          unit: 'hours',
          type: AxisType.time,
        ),
        // Per FR-003: yAxes removed from ChartConfiguration
        annotations: [
          AnnotationConfig(
            id: 'annotation1',
            type: AnnotationType.referenceLine,
            orientation: Orientation.horizontal,
            value: 25.0,
            label: 'Target',
          ),
        ],
        style: ChartStyleConfig(
          backgroundColor: '#FFFFFF',
          fontFamily: 'Roboto',
        ),
        showGrid: true,
        showLegend: true,
        legendPosition: LegendPosition.bottom,
        useDarkTheme: false,
        showScrollbar: true,
        normalizationMode: NormalizationModeConfig.auto,
        width: 800.0,
        height: 400.0,
      );
    }

    test('fromJson creates correct instance from Map', () {
      final json = {
        'id': 'chart1',
        'title': 'Test Chart',
        'series': [
          {
            'id': 'series1',
            'data': [
              {'x': 0.0, 'y': 10.0},
            ],
          },
        ],
        'showGrid': true,
        'showLegend': true,
        'legendPosition': 'top',
      };

      final chart = ChartConfiguration.fromJson(json);

      expect(chart.id, equals('chart1'));
      expect(chart.title, equals('Test Chart'));
      expect(chart.series.length, equals(1));
      expect(chart.showGrid, isTrue);
      expect(chart.showLegend, isTrue);
      expect(chart.legendPosition, equals(LegendPosition.top));
    });

    test('fromJson applies default values for missing fields', () {
      final json = {
        'series': <Map<String, dynamic>>[],
      };

      final chart = ChartConfiguration.fromJson(json);

      expect(chart.id, isNull);
      expect(chart.title, isNull);
      expect(chart.subtitle, isNull);
      expect(chart.showGrid, isTrue);
      expect(chart.showLegend, isTrue);
      expect(chart.legendPosition, equals(LegendPosition.bottom));
      expect(chart.useDarkTheme, isFalse);
      expect(chart.showScrollbar, isFalse);
      expect(chart.normalizationMode, equals(NormalizationModeConfig.none));
    });

    test('fromJson parses nested xAxis correctly', () {
      final json = {
        'series': <Map<String, dynamic>>[],
        'xAxis': {
          'label': 'Time',
          'type': 'time',
        },
      };

      final chart = ChartConfiguration.fromJson(json);

      expect(chart.xAxis, isNotNull);
      expect(chart.xAxis!.label, equals('Time'));
      expect(chart.xAxis!.type, equals(AxisType.time));
    });

    test('fromJson parses nested series yAxis correctly', () {
      // Per FR-001/FR-003: yAxes are on series, not ChartConfiguration
      final json = {
        'series': [
          {
            'id': 'series1',
            'data': [
              {'x': 0.0, 'y': 10.0}
            ],
            'yAxis': {
              'position': 'left',
              'label': 'Values',
            }
          },
          {
            'id': 'series2',
            'data': [
              {'x': 0.0, 'y': 20.0}
            ],
            'yAxis': {
              'position': 'right',
              'label': 'Other',
            }
          },
        ],
      };

      final chart = ChartConfiguration.fromJson(json);

      expect(chart.series.length, equals(2));
      expect(chart.series[0].yAxis, isNotNull);
      expect(chart.series[0].yAxis!.position, equals(AxisPosition.left));
      expect(chart.series[0].yAxis!.label, equals('Values'));
      expect(chart.series[1].yAxis, isNotNull);
      expect(chart.series[1].yAxis!.position, equals(AxisPosition.right));
      expect(chart.series[1].yAxis!.label, equals('Other'));
    });

    test('fromJson parses nested annotations correctly', () {
      final json = {
        'series': <Map<String, dynamic>>[],
        'annotations': [
          {'type': 'referenceLine', 'value': 50.0},
          {'type': 'zone', 'minValue': 10.0, 'maxValue': 20.0},
        ],
      };

      final chart = ChartConfiguration.fromJson(json);

      expect(chart.annotations.length, equals(2));
      expect(chart.annotations[0].type, equals(AnnotationType.referenceLine));
      expect(chart.annotations[1].type, equals(AnnotationType.zone));
    });

    test('fromJson parses nested style correctly', () {
      final json = {
        'series': <Map<String, dynamic>>[],
        'style': {
          'backgroundColor': '#FFFFFF',
          'fontFamily': 'Arial',
        },
      };

      final chart = ChartConfiguration.fromJson(json);

      expect(chart.style, isNotNull);
      expect(chart.style!.backgroundColor, equals('#FFFFFF'));
      expect(chart.style!.fontFamily, equals('Arial'));
    });

    test('toJson produces correct Map', () {
      final chart = createFullChartConfiguration();
      final json = chart.toJson();

      expect(json['id'], equals('chart1'));
      expect(json['title'], equals('Temperature Over Time'));
      expect(json['subtitle'], equals('Daily readings'));
      expect(json['series'], isList);
      expect((json['series'] as List).length, equals(2));
      expect(json['xAxis'], isMap);
      // Per FR-003: yAxes removed from ChartConfiguration - yAxis is now nested in each series
      expect(json.containsKey('yAxes'), isFalse,
          reason: 'FR-003: yAxes should not be in ChartConfiguration');
      // Instead, verify series have yAxis
      final series0 = (json['series'] as List)[0] as Map<String, dynamic>;
      expect(series0.containsKey('yAxis'), isTrue,
          reason: 'FR-001: series should have nested yAxis');
      expect(json['annotations'], isList);
      expect((json['annotations'] as List).length, equals(1));
      expect(json['style'], isMap);
      expect(json['showGrid'], isTrue);
      expect(json['showLegend'], isTrue);
      expect(json['legendPosition'], equals('bottom'));
      expect(json['normalizationMode'], equals('auto'));
      expect(json['width'], equals(800.0));
      expect(json['height'], equals(400.0));
    });

    test('toJson omits null optional fields', () {
      const chart = ChartConfiguration(
        series: [],
      );

      final json = chart.toJson();

      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('title'), isFalse);
      expect(json.containsKey('subtitle'), isFalse);
      expect(json.containsKey('xAxis'), isFalse);
      expect(json.containsKey('style'), isFalse);
      expect(json.containsKey('width'), isFalse);
      expect(json.containsKey('height'), isFalse);
    });

    test('round-trip: fromJson(toJson()) equals original', () {
      final original = createFullChartConfiguration();
      final restored = ChartConfiguration.fromJson(original.toJson());

      expect(restored, equals(original));
    });

    test('round-trip preserves all nested structures', () {
      final original = createFullChartConfiguration();
      final json = original.toJson();
      final restored = ChartConfiguration.fromJson(json);

      // Verify nested series
      expect(restored.series.length, equals(original.series.length));
      expect(restored.series[0].id, equals(original.series[0].id));
      expect(restored.series[0].data.length,
          equals(original.series[0].data.length));

      // Verify nested xAxis
      expect(restored.xAxis, equals(original.xAxis));

      // Verify nested yAxis on series (FR-001: yAxis is now on series, not ChartConfiguration)
      expect(restored.series[0].yAxis, equals(original.series[0].yAxis));
      expect(restored.series[1].yAxis, equals(original.series[1].yAxis));

      // Verify nested annotations
      expect(restored.annotations.length, equals(original.annotations.length));
      expect(restored.annotations[0], equals(original.annotations[0]));

      // Verify nested style
      expect(restored.style, equals(original.style));
    });

    test('copyWith with no args returns equal instance', () {
      final original = createFullChartConfiguration();
      final copy = original.copyWith();

      expect(copy, equals(original));
    });

    test('copyWith with args updates only specified fields', () {
      final original = createFullChartConfiguration();
      final updated = original.copyWith(
        title: 'Updated Title',
        showLegend: false,
      );

      expect(updated.title, equals('Updated Title'));
      expect(updated.showLegend, isFalse);
      expect(updated.id, equals(original.id));
      expect(updated.series.length, equals(original.series.length));
      expect(updated.xAxis, equals(original.xAxis));
    });

    test('copyWith can replace nested collections', () {
      final original = createFullChartConfiguration();
      final newSeries = [
        const SeriesConfig(
          id: 'new-series',
          data: [DataPoint(x: 0, y: 100)],
        ),
      ];

      final updated = original.copyWith(series: newSeries);

      expect(updated.series.length, equals(1));
      expect(updated.series[0].id, equals('new-series'));
    });

    test('equality: same values are equal', () {
      final chart1 = createFullChartConfiguration();
      final chart2 = createFullChartConfiguration();

      expect(chart1, equals(chart2));
    });

    test('equality: different values are not equal', () {
      final chart1 = createFullChartConfiguration();
      final chart2 = chart1.copyWith(title: 'Different Title');

      expect(chart1, isNot(equals(chart2)));
    });

    test('minimal configuration round-trip', () {
      const original = ChartConfiguration(
        series: [
          SeriesConfig(
            id: 'minimal',
            type: ChartType.scatter,
            data: [DataPoint(x: 1, y: 1)],
          ),
        ],
      );

      final restored = ChartConfiguration.fromJson(original.toJson());
      expect(restored, equals(original));
    });

    test('all series types serialize correctly', () {
      for (final chartType in ChartType.values) {
        final chart = ChartConfiguration(
          series: [
            SeriesConfig(
              id: 'test',
              type: chartType,
              data: const [],
            ),
          ],
        );

        final json = chart.toJson();
        final restored = ChartConfiguration.fromJson(json);

        expect(restored.series.first.type, equals(chartType));
      }
    });

    test('all legend positions serialize correctly', () {
      for (final position in LegendPosition.values) {
        final chart = ChartConfiguration(
          series: const [],
          legendPosition: position,
        );

        final json = chart.toJson();
        final restored = ChartConfiguration.fromJson(json);

        expect(restored.legendPosition, equals(position));
      }
    });

    test('all normalization modes serialize correctly', () {
      for (final mode in NormalizationModeConfig.values) {
        final chart = ChartConfiguration(
          series: const [],
          normalizationMode: mode,
        );

        final json = chart.toJson();
        final restored = ChartConfiguration.fromJson(json);

        expect(restored.normalizationMode, equals(mode));
      }
    });
  });
}
