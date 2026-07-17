import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChartAnnotationDocumentCodec', () {
    test('round-trips point fields and complete portable style', () {
      final source = PointAnnotation(
        id: 'peak',
        label: 'Peak',
        style: _fullStyle,
        allowDragging: true,
        allowEditing: true,
        zIndex: 9,
        seriesId: 'power',
        dataPointIndex: 4,
        offset: const Offset(3, -2),
        markerShape: MarkerShape.diamond,
        markerSize: 14,
        markerColor: const Color(0xFFAA2244),
        labelMargin: 7,
      );

      final (document, result) = _roundTrip(source);
      final decoded = result as PointAnnotation;

      expect(document.type, 'point');
      expect(document.requiredCapabilities, {'annotation.point'});
      expect(document.payload.values['coordinateSpace']?.toJson(), 'data');
      _expectCommon(decoded, source);
      expect(decoded.seriesId, 'power');
      expect(decoded.dataPointIndex, 4);
      expect(decoded.offset, const Offset(3, -2));
      expect(decoded.markerShape, MarkerShape.diamond);
      expect(decoded.markerSize, 14);
      expect(decoded.markerColor, const Color(0xFFAA2244));
      expect(decoded.labelMargin, 7);
    });

    test('round-trips range, threshold, pin, trend, and chord fields', () {
      final range =
          _roundTrip(
                RangeAnnotation(
                  id: 'zone',
                  label: 'Tempo',
                  style: _simpleStyle,
                  snapToValue: true,
                  snapIncrement: 0.25,
                  snapTolerance: 0.08,
                  startX: 1,
                  endX: 5,
                  startY: 180,
                  endY: 260,
                  seriesId: 'power',
                  fillColor: const Color(0x332266AA),
                  borderColor: const Color(0xFF2266AA),
                  labelPosition: AnnotationLabelPosition.bottomRight,
                  labelMargin: 11,
                ),
              ).$2
              as RangeAnnotation;
      expect(range.snapToValue, isTrue);
      expect(range.snapIncrement, 0.25);
      expect(range.snapTolerance, 0.08);
      expect(
        (range.startX, range.endX, range.startY, range.endY),
        (1, 5, 180, 260),
      );
      expect(range.seriesId, 'power');
      expect(range.fillColor, const Color(0x332266AA));
      expect(range.borderColor, const Color(0xFF2266AA));
      expect(range.labelPosition, AnnotationLabelPosition.bottomRight);
      expect(range.labelMargin, 11);

      final threshold =
          _roundTrip(
                ThresholdAnnotation(
                  id: 'ftp',
                  axis: AnnotationAxis.y,
                  value: 280,
                  seriesId: 'power',
                  lineColor: const Color(0xFFE65100),
                  lineWidth: 2.5,
                  dashPattern: const [8, 4],
                  labelPosition: AnnotationLabelPosition.topRight,
                  labelMargin: 6,
                  elevation: 3,
                ),
              ).$2
              as ThresholdAnnotation;
      expect(threshold.axis, AnnotationAxis.y);
      expect(threshold.value, 280);
      expect(threshold.seriesId, 'power');
      expect(threshold.lineColor, const Color(0xFFE65100));
      expect(threshold.lineWidth, 2.5);
      expect(threshold.dashPattern, [8, 4]);
      expect(threshold.labelPosition, AnnotationLabelPosition.topRight);
      expect(threshold.labelMargin, 6);
      expect(threshold.elevation, 3);

      final pin =
          _roundTrip(
                PinAnnotation(
                  id: 'event',
                  x: 12,
                  y: 340,
                  markerShape: MarkerShape.star,
                  markerSize: 18,
                  markerColor: const Color(0xFF7B1FA2),
                  labelMargin: 5,
                ),
              ).$2
              as PinAnnotation;
      expect((pin.x, pin.y), (12, 340));
      expect(pin.markerShape, MarkerShape.star);
      expect(pin.markerSize, 18);
      expect(pin.markerColor, const Color(0xFF7B1FA2));
      expect(pin.labelMargin, 5);

      final trend =
          _roundTrip(
                TrendAnnotation(
                  id: 'rolling',
                  seriesId: 'power',
                  trendType: TrendType.movingAverage,
                  windowSize: 5,
                  degree: 3,
                  lineColor: const Color(0xFF00897B),
                  lineWidth: 3,
                  dashPattern: const [5, 2],
                  elevation: 1.5,
                ),
              ).$2
              as TrendAnnotation;
      expect(trend.seriesId, 'power');
      expect(trend.trendType, TrendType.movingAverage);
      expect((trend.windowSize, trend.degree), (5, 3));
      expect(trend.lineColor, const Color(0xFF00897B));
      expect(trend.lineWidth, 3);
      expect(trend.dashPattern, [5, 2]);
      expect(trend.elevation, 1.5);

      final chord =
          _roundTrip(
                ChordAnnotation(
                  id: 'chord',
                  style: _simpleStyle,
                  seriesId: 'lactate',
                  startIndex: 1,
                  endIndex: 8,
                  lineColor: const Color(0xFF3949AB),
                  lineWidth: 2.75,
                  dashPattern: const [3, 2],
                  elevation: 2,
                  perpendicularIndex: 5,
                  perpendicularLabel: 'Dmax',
                  perpendicularLabelOffset: const Offset(6, -4),
                  perpendicularLabelStyle: _fullStyle,
                  perpendicularLineColor: const Color(0xFFEF6C00),
                  perpendicularLineWidth: 1.5,
                  perpendicularDashPattern: const [2, 1],
                  perpendicularElevation: 4,
                ),
              ).$2
              as ChordAnnotation;
      expect((chord.startIndex, chord.endIndex), (1, 8));
      expect(chord.lineColor, const Color(0xFF3949AB));
      expect(chord.lineWidth, 2.75);
      expect(chord.dashPattern, [3, 2]);
      expect(chord.elevation, 2);
      expect(chord.perpendicularIndex, 5);
      expect(chord.perpendicularLabel, 'Dmax');
      expect(chord.perpendicularLabelOffset, const Offset(6, -4));
      expect(chord.perpendicularLabelStyle, _fullStyle);
      expect(chord.perpendicularLineColor, const Color(0xFFEF6C00));
      expect(chord.perpendicularLineWidth, 1.5);
      expect(chord.perpendicularDashPattern, [2, 1]);
      expect(chord.perpendicularElevation, 4);
    });

    test('round-trips plain and rich text with declared coordinate space', () {
      final plain = TextAnnotation(
        id: 'plain',
        text: 'Hold cadence',
        position: const Offset(120, 80),
        anchor: AnnotationAnchor.bottomCenter,
        backgroundColor: const Color(0xFFFDF6E3),
        borderColor: const Color(0xFF856404),
      );
      final (document, plainResult) = _roundTrip(plain);
      final decodedPlain = plainResult as TextAnnotation;
      expect(
        document.payload.values['coordinateSpace']?.toJson(),
        'widgetLogicalPixels',
      );
      expect(decodedPlain.text, 'Hold cadence');
      expect(decodedPlain.position, const Offset(120, 80));
      expect(decodedPlain.anchor, AnnotationAnchor.bottomCenter);

      final rich = TextAnnotation.rich(
        id: 'rich',
        richTextDelta: const [
          {
            'insert': 'Bold',
            'attributes': {'bold': true},
          },
          {'insert': '\n'},
        ],
        position: const Offset(8, 16),
      );
      final decodedRich = _roundTrip(rich).$2 as TextAnnotation;
      expect(decodedRich.richTextDelta, rich.richTextDelta);
    });

    test('round-trips legend nested models without sharing runtime state', () {
      final nestedSeries = LineChartSeries(
        id: 'power',
        name: 'Power',
        points: const [ChartDataPoint(x: 1, y: 250)],
        annotations: [PinAnnotation(id: 'nested-pin', x: 1, y: 250)],
      );
      final trend = TrendAnnotation(
        id: 'legend-trend',
        label: 'Trend',
        seriesId: 'power',
        trendType: TrendType.linear,
      );
      const style = LegendStyle(
        position: LegendPosition.bottomLeft,
        orientation: LegendOrientation.vertical,
        textStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        backgroundColor: Color(0xEEFFFFFF),
        borderColor: Color(0xFFBDBDBD),
        borderWidth: 1.5,
        borderRadius: BorderRadius.all(Radius.circular(9)),
        padding: EdgeInsets.fromLTRB(8, 6, 8, 6),
        itemSpacing: 9,
        markerSize: 15,
        markerShape: LegendMarkerShape.diamond,
        markerLineWidth: 3,
        markerLabelSpacing: 7,
        opacity: 0.92,
        offset: Offset(4, 5),
      );
      final source = LegendAnnotation(
        id: 'legend',
        label: 'Metrics',
        zIndex: 12,
        series: [nestedSeries],
        trendAnnotations: [trend],
        legendStyle: style,
        hiddenSeriesIds: const {'power'},
        customPosition: const Offset(220, 40),
      );

      final decoded = _roundTrip(source).$2 as LegendAnnotation;

      expect(decoded.legendStyle, style);
      expect(decoded.hiddenSeriesIds, {'power'});
      expect(decoded.customPosition, const Offset(220, 40));
      expect(decoded.series.single, isA<LineChartSeries>());
      expect(decoded.series.single.annotations.single, isA<PinAnnotation>());
      expect(decoded.trendAnnotations.single.id, 'legend-trend');
      expect(identical(decoded.series.single, nestedSeries), isFalse);
      expect(identical(decoded.trendAnnotations.single, trend), isFalse);
    });

    test('round-trips a nested pie series in legend annotations', () {
      final source = LegendAnnotation(
        id: 'pie-legend',
        series: [
          PieChartSeries.fromMap(
            id: 'revenue',
            unit: 'USD',
            values: const {'Subscriptions': 42, 'Services': 58},
            pieStyle: const PieChartStyle(startAngleDegrees: 20),
          ),
        ],
      );

      final decoded = _roundTrip(source).$2 as LegendAnnotation;
      final pie = decoded.series.single as PieChartSeries;

      expect(pie.points.map((point) => point.label), [
        'Subscriptions',
        'Services',
      ]);
      expect(pie.pieStyle.startAngleDegrees, 20);
      expect(pie.unit, 'USD');
    });

    test('projects nested legend series with the selected data storage', () {
      final result = ChartAnnotationDocumentCodec.encode(
        LegendAnnotation(
          series: const [
            LineChartSeries(
              id: 'power',
              points: [ChartDataPoint(x: 1, y: 250)],
            ),
          ],
        ),
        dataStorage: ChartDataStorage.inlineColumns,
      );

      expect(result, isA<ChartArtifactSuccess<ChartAnnotationDocument>>());
      final document =
          (result as ChartArtifactSuccess<ChartAnnotationDocument>).value;
      final payload = document.payload.toJson() as Map<String, Object?>;
      final series = payload['series']! as List<Object?>;
      final nested = series.single! as Map<String, Object?>;
      final data = nested['data']! as Map<String, Object?>;

      expect(data['storage'], 'inlineColumns');
      expect(data['x'], [1.0]);
      expect(data['y'], [250.0]);
      expect(data, isNot(contains('points')));
    });

    test('uses stable type and capability identifiers for all built-ins', () {
      final values = <ChartAnnotation>[
        PointAnnotation(seriesId: 's', dataPointIndex: 0),
        RangeAnnotation(startX: 0, endX: 1),
        TextAnnotation(text: 'x', position: Offset.zero),
        ThresholdAnnotation(axis: AnnotationAxis.x, value: 1),
        PinAnnotation(x: 0, y: 0),
        TrendAnnotation(trendType: TrendType.linear),
        ChordAnnotation(seriesId: 's', startIndex: 0, endIndex: 1),
        LegendAnnotation(series: const []),
      ];
      const types = [
        'point',
        'range',
        'text',
        'threshold',
        'pin',
        'trend',
        'chord',
        'legend',
      ];

      for (var index = 0; index < values.length; index++) {
        final encoded = ChartAnnotationDocumentCodec.encode(values[index]);
        final document =
            (encoded as ChartArtifactSuccess<ChartAnnotationDocument>).value;
        expect(document.type, types[index]);
        expect(document.requiredCapabilities, {'annotation.${types[index]}'});
      }
    });

    test('fails closed for callbacks, Paint styles, and unknown types', () {
      final callback =
          ChartAnnotationDocumentCodec.encode(
                LegendAnnotation(series: const [], onSeriesToggle: (_) {}),
              )
              as ChartArtifactFailure<ChartAnnotationDocument>;
      expect(
        callback.error.code,
        ChartArtifactDiagnosticCodes.runtimeBindingRequired,
      );

      final paint =
          ChartAnnotationDocumentCodec.encode(
                PinAnnotation(
                  x: 0,
                  y: 0,
                  style: AnnotationStyle(
                    textStyle: TextStyle(foreground: Paint()),
                  ),
                ),
              )
              as ChartArtifactFailure<ChartAnnotationDocument>;
      expect(
        paint.error.code,
        ChartArtifactDiagnosticCodes.unsupportedModelType,
      );

      final valid = _encode(PinAnnotation(x: 0, y: 0));
      final unknown =
          ChartAnnotationDocumentCodec.decode(
                ChartAnnotationDocument(
                  type: 'com.example.flag',
                  id: valid.id,
                  payload: valid.payload,
                ),
              )
              as ChartArtifactFailure<ChartAnnotation>;
      expect(
        unknown.error.code,
        ChartArtifactDiagnosticCodes.unsupportedModelType,
      );
    });
  });
}

const _simpleStyle = AnnotationStyle(
  textStyle: TextStyle(color: Color(0xFF102030), fontSize: 12),
  backgroundColor: Color(0xFFF5F5F5),
  borderColor: Color(0xFF607D8B),
  borderWidth: 2,
  borderRadius: BorderRadius.all(Radius.circular(6)),
  padding: EdgeInsets.fromLTRB(5, 4, 5, 4),
);

const _fullStyle = AnnotationStyle(
  textStyle: TextStyle(
    inherit: false,
    color: Color(0xFF102030),
    backgroundColor: Color(0x1100FF00),
    fontFamily: 'Inter',
    fontFamilyFallback: ['Roboto', 'Arial'],
    fontSize: 14,
    fontWeight: FontWeight.w700,
    fontStyle: FontStyle.italic,
    letterSpacing: 0.4,
    wordSpacing: 1.2,
    textBaseline: TextBaseline.alphabetic,
    height: 1.35,
    leadingDistribution: TextLeadingDistribution.even,
    locale: Locale.fromSubtags(languageCode: 'en', countryCode: 'ZA'),
    shadows: [
      Shadow(color: Color(0x55000000), offset: Offset(1, 2), blurRadius: 3),
    ],
    fontFeatures: [FontFeature('smcp')],
    fontVariations: [FontVariation('wght', 650)],
    decoration: TextDecoration.underline,
    decorationColor: Color(0xFF405060),
    decorationStyle: TextDecorationStyle.dashed,
    decorationThickness: 1.5,
    debugLabel: 'artifact-test',
    overflow: TextOverflow.fade,
  ),
  backgroundColor: Color(0xFFF5F5F5),
  borderColor: Color(0xFF607D8B),
  borderWidth: 2.5,
  borderRadius: BorderRadius.only(
    topLeft: Radius.circular(3),
    topRight: Radius.elliptical(4, 5),
    bottomLeft: Radius.circular(6),
    bottomRight: Radius.elliptical(7, 8),
  ),
  padding: EdgeInsets.fromLTRB(5, 6, 7, 8),
);

(ChartAnnotationDocument, ChartAnnotation) _roundTrip(ChartAnnotation source) {
  final document = _encode(source);
  final jsonRoundTrip = ChartAnnotationDocument.fromJson(document.toJson());
  final decoded = ChartAnnotationDocumentCodec.decode(jsonRoundTrip);
  expect(decoded, isA<ChartArtifactSuccess<ChartAnnotation>>());
  return (
    jsonRoundTrip,
    (decoded as ChartArtifactSuccess<ChartAnnotation>).value,
  );
}

ChartAnnotationDocument _encode(ChartAnnotation source) {
  final encoded = ChartAnnotationDocumentCodec.encode(source);
  expect(encoded, isA<ChartArtifactSuccess<ChartAnnotationDocument>>());
  return (encoded as ChartArtifactSuccess<ChartAnnotationDocument>).value;
}

void _expectCommon(ChartAnnotation actual, ChartAnnotation expected) {
  expect(actual.id, expected.id);
  expect(actual.label, expected.label);
  expect(actual.style, expected.style);
  expect(actual.allowDragging, expected.allowDragging);
  expect(actual.allowEditing, expected.allowEditing);
  expect(actual.zIndex, expected.zIndex);
  expect(actual.snapToValue, expected.snapToValue);
  expect(actual.snapIncrement, expected.snapIncrement);
}
