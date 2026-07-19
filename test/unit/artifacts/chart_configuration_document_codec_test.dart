import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChartAxisDocumentCodec', () {
    test('round-trips a self-contained categorical X-axis', () {
      const source = XAxisConfig(
        label: 'Market',
        maxHeight: 88,
        categoryAxis: CategoryAxisConfig(
          categories: ['Enterprise', 'Mid-market', 'Small business'],
          labelDensity: CategoryLabelDensity.showAll,
          labelOverflow: CategoryLabelOverflow.ellipsis,
          minimumCategoryExtent: 72,
          maximumLabelExtent: 120,
          maxLabelLines: 3,
          labelRotationDegrees: -30,
          autoViewport: false,
        ),
      );

      final document = _success(ChartAxisDocumentCodec.encodeXAxis(source));
      final json = document.toJson();
      final decoded = _success(
        ChartAxisDocumentCodec.decodeXAxis(ChartAxisDocument.fromJson(json)),
      );

      expect(json['categories'], source.categoryAxis!.categories);
      expect(json.containsKey('formatter'), isFalse);
      expect(decoded, source);
    });

    test('round-trips every X-axis field', () {
      const source = XAxisConfig(
        color: Color(0xFF123456),
        label: 'Elapsed time',
        unit: 'min',
        min: -1,
        max: 12,
        renderMin: 0,
        renderMax: 10,
        visible: false,
        showAxisLine: false,
        showTicks: false,
        showTickLabels: false,
        showCrosshairLabel: false,
        crosshairLabelPosition: CrosshairLabelPosition.insidePlot,
        labelDisplay: AxisLabelDisplay.tickUnitOnly,
        minHeight: 14,
        maxHeight: 72,
        tickLabelPadding: 6,
        axisLabelPadding: 7,
        axisMargin: 9,
        tickCount: 8,
        showMinorTicks: true,
        minorTickCount: 3,
        minorTickLength: 2.5,
      );

      final document = _success(
        ChartAxisDocumentCodec.encodeXAxis(source, id: 'elapsed'),
      );
      final decoded = _success(
        ChartAxisDocumentCodec.decodeXAxis(
          ChartAxisDocument.fromJson(document.toJson()),
        ),
      );

      expect(document.axisType, 'x');
      expect(document.id, 'elapsed');
      expect(document.position, 'bottom');
      expect(decoded, source);
    });

    test('round-trips every Y-axis field', () {
      final source = YAxisConfig(
        position: YAxisPosition.right,
        color: const Color(0xFF654321),
        label: 'Power',
        unit: 'W',
        min: 100,
        max: 500,
        renderMin: 120,
        renderMax: 480,
        visible: false,
        showAxisLine: false,
        showTicks: false,
        showTickLabels: false,
        showCrosshairLabel: false,
        crosshairLabelPosition: CrosshairLabelPosition.insidePlot,
        labelDisplay: AxisLabelDisplay.labelAndTickUnit,
        minWidth: 12,
        maxWidth: 92,
        tickLabelPadding: 6,
        axisLabelPadding: 7,
        axisMargin: 9,
        tickCount: 7,
        showMinorTicks: true,
        minorTickCount: 3,
        minorTickLength: 2.5,
      ).copyWith(id: 'power-axis');

      final document = _success(ChartAxisDocumentCodec.encodeYAxis(source));
      final decoded = _success(
        ChartAxisDocumentCodec.decodeYAxis(
          ChartAxisDocument.fromJson(document.toJson()),
        ),
      );

      expect(document.axisType, 'y');
      expect(decoded, source);
    });

    test('requires a descriptor for formatter callbacks', () {
      final failure = ChartAxisDocumentCodec.encodeXAxis(
        XAxisConfig(labelFormatter: (value) => value.toStringAsFixed(1)),
      );
      expect(failure, isA<ChartArtifactFailure<ChartAxisDocument>>());
      expect(
        (failure as ChartArtifactFailure<ChartAxisDocument>).error.code,
        ChartArtifactDiagnosticCodes.runtimeBindingRequired,
      );

      final descriptor =
          JsonValue.fromJson({'id': 'elapsed.minutes'}) as JsonObjectValue;
      final document = _success(
        ChartAxisDocumentCodec.encodeXAxis(
          XAxisConfig(labelFormatter: (value) => '$value min'),
          formatter: descriptor,
        ),
      );
      expect(document.formatter?.toJson(), {'id': 'elapsed.minutes'});
      final decoded = _success(
        ChartAxisDocumentCodec.decodeXAxis(
          document,
          formatter: (value) => '$value min',
        ),
      );
      expect(decoded.labelFormatter?.call(5), '5.0 min');
    });

    test('rejects an axis document with the wrong discriminator', () {
      final result = ChartAxisDocumentCodec.decodeXAxis(
        ChartAxisDocument(id: 'y', axisType: 'y', position: 'left'),
      );
      expect(result, isA<ChartArtifactFailure<XAxisConfig>>());
      expect(
        (result as ChartArtifactFailure<XAxisConfig>).error.code,
        ChartArtifactDiagnosticCodes.invalidArtifact,
      );
    });
  });

  group('ChartConfigurationDocumentCodec', () {
    test('round-trips complete grid configuration', () {
      const source = GridConfig(
        horizontal: false,
        vertical: true,
        horizontalColor: Color(0x11223344),
        verticalColor: Color(0x55667788),
        horizontalStrokeWidth: 1.25,
        verticalStrokeWidth: 2.5,
      );

      final document = ChartConfigurationDocumentCodec.encodeGrid(source);
      final decoded = _success(
        ChartConfigurationDocumentCodec.decodeGrid(
          ChartGridDocument.fromJson(document.toJson()),
        ),
      );

      expect(decoded, source);
    });

    test('round-trips legend visibility and portable style', () {
      const style = LegendStyle(
        position: LegendPosition.bottomLeft,
        orientation: LegendOrientation.vertical,
        textStyle: TextStyle(
          color: Color(0xFF102030),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        backgroundColor: Color(0xEEFFFFFF),
        borderColor: Color(0xFF405060),
        borderWidth: 2,
        borderRadius: BorderRadius.all(Radius.circular(8)),
        padding: EdgeInsets.fromLTRB(4, 5, 6, 7),
        itemSpacing: 9,
        markerSize: 18,
        markerShape: LegendMarkerShape.diamond,
        markerLineWidth: 3,
        markerLabelSpacing: 7,
        allowDragging: false,
        opacity: 0.8,
        offset: Offset(3, 4),
      );

      final document = _success(
        ChartConfigurationDocumentCodec.encodeLegend(
          visible: true,
          style: style,
        ),
      );
      final decoded = _success(
        ChartConfigurationDocumentCodec.decodeLegend(
          ChartLegendDocument.fromJson(document.toJson()),
        ),
      );

      expect(decoded.visible, isTrue);
      expect(decoded.style, style);
    });

    test('round-trips every normalization mode with its threshold', () {
      for (final mode in NormalizationMode.values) {
        final document = ChartConfigurationDocumentCodec.encodeNormalization(
          mode,
          autoRangeRatioThreshold: 12.5,
        );
        final jsonRoundTrip = ChartNormalizationDocument.fromJson(
          document.toJson(),
        );

        expect(
          _success(
            ChartConfigurationDocumentCodec.decodeNormalization(jsonRoundTrip),
          ),
          mode,
        );
        expect(jsonRoundTrip.autoRangeRatioThreshold.asDouble, 12.5);
      }
    });

    test('layout document preserves chart chrome fields', () {
      final source = ChartLayoutDocument(
        width: ChartNumberDocument.fromDouble(640),
        height: ChartNumberDocument.fromDouble(360),
        backgroundColor: const Color(0xFFFAFAFA).toARGB32(),
        showToolbar: true,
        interactiveAnnotations: false,
        maxAxesPerSide: 4,
        axisSwapMode: AxisSwapMode.revert.name,
      );

      final decoded = ChartLayoutDocument.fromJson(source.toJson());

      expect(decoded.width?.asDouble, 640);
      expect(decoded.height?.asDouble, 360);
      expect(decoded.backgroundColor, const Color(0xFFFAFAFA).toARGB32());
      expect(decoded.showToolbar, isTrue);
      expect(decoded.interactiveAnnotations, isFalse);
      expect(decoded.maxAxesPerSide, 4);
      expect(decoded.axisSwapMode, AxisSwapMode.revert.name);
    });

    test('round-trips Concentric Donut composition and portable center', () {
      const source = ConcentricDonutConfig(
        innerRadiusFactor: 0.2,
        outerRadiusFactor: 0.9,
        ringGap: 6,
        order: ConcentricRingOrder.innerToOuter,
        ringWeights: {'outer': 2, 'inner': 1},
        legendMode: ConcentricDonutLegendMode.flat,
        centerContent: DonutCenterContent(
          label: 'Periods',
          valueMode: DonutCenterValueMode.custom,
          customValue: '2 rings',
        ),
      );

      final encoded = _success(
        ChartConfigurationDocumentCodec.encodeConcentricDonut(source),
      );
      final transported =
          JsonValue.fromJson(encoded.toJson()) as JsonObjectValue;
      final decoded = _success(
        ChartConfigurationDocumentCodec.decodeConcentricDonut(transported),
      );

      expect(decoded, source);
    });

    test('reports a path-specific invalid concentric radius', () {
      final result = ChartConfigurationDocumentCodec.decodeConcentricDonut(
        JsonValue.fromJson({
              'concentricDonut': {
                'innerRadiusFactor': 0.9,
                'outerRadiusFactor': 0.5,
                'ringGap': 4,
                'order': 'outerToInner',
                'ringWeights': <String, Object?>{},
                'legendMode': 'groupedByRing',
                'centerContent': {'isVisible': true, 'valueMode': 'total'},
              },
            })
            as JsonObjectValue,
      );

      expect(result, isA<ChartArtifactFailure<ConcentricDonutConfig?>>());
      expect(
        (result as ChartArtifactFailure<ConcentricDonutConfig?>).error.path,
        r'$.configuration.concentricDonut.innerRadiusFactor',
      );
    });

    test(
      'requires and restores a descriptor for a custom center formatter',
      () {
        final missing = ChartConfigurationDocumentCodec.encodeConcentricDonut(
          ConcentricDonutConfig(
            centerContent: DonutCenterContent(
              valueFormatter: (value) => value.toStringAsFixed(1),
            ),
          ),
        );
        expect(missing, isA<ChartArtifactFailure<JsonObjectValue>>());
        expect(
          (missing as ChartArtifactFailure<JsonObjectValue>).error.code,
          ChartArtifactDiagnosticCodes.runtimeBindingRequired,
        );

        final descriptor = ChartFormatterDescriptor(
          id: 'braven.number.fixed',
          arguments: {'decimals': JsonNumberValue(1)},
        ).toDocument();
        final encoded = _success(
          ChartConfigurationDocumentCodec.encodeConcentricDonut(
            ConcentricDonutConfig(
              centerContent: DonutCenterContent(
                valueFormatter: (value) => value.toStringAsFixed(1),
              ),
            ),
            centerFormatterDescriptor: descriptor,
          ),
        );
        final decoded = _success(
          ChartConfigurationDocumentCodec.decodeConcentricDonut(
            encoded,
            centerFormatter: (value) => value.toStringAsFixed(1),
          ),
        );

        expect(decoded?.centerContent.valueFormatter?.call(12.34), '12.3');
      },
    );
  });
}

T _success<T>(ChartArtifactResult<T> result) {
  expect(result, isA<ChartArtifactSuccess<T>>());
  return (result as ChartArtifactSuccess<T>).value;
}
