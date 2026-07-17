import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChartSeriesDocumentCodec', () {
    test('round-trips every base and line-series field', () {
      final source = LineChartSeries(
        id: 'power',
        name: 'Power',
        points: [
          ChartDataPoint(
            x: double.nan,
            y: double.infinity,
            timestamp: DateTime.utc(2026, 7, 14, 9, 15),
            label: 'surge',
            metadata: const {'quality': 'verified', 'lap': 3},
            segmentStyle: const SegmentStyle(
              color: Color(0xFFAA1122),
              strokeWidth: 3.5,
            ),
            pointStyle: const PointStyle(color: Color(0xFF1144AA), size: 7.25),
          ),
        ],
        color: const Color(0xFF123456),
        style: SeriesStyle.line,
        isXOrdered: true,
        metadata: const {'source': 'erg', 'channel': 2},
        yAxisId: 'shared-power',
        yAxisConfig: YAxisConfig(
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
          labelDisplay: AxisLabelDisplay.tickUnitOnly,
          minWidth: 12,
          maxWidth: 92,
          tickLabelPadding: 6,
          axisLabelPadding: 7,
          axisMargin: 9,
          tickCount: 7,
          showMinorTicks: true,
          minorTickCount: 3,
          minorTickLength: 2.5,
        ).copyWith(id: 'inline-power'),
        unit: 'W',
        interpolation: LineInterpolation.monotone,
        strokeWidth: 4.5,
        tension: 0.6,
        showDataPointMarkers: true,
        dataPointMarkerRadius: 5.5,
        dataPointMarkerStyle: DataPointMarkerStyle.hollow,
        dataPointMarkerBackground: const Color(0xFFFAFAFA),
        lineGlow: 2.25,
        dataPointLabels: const DataPointLabelConfig(
          show: true,
          position: DataPointLabelPosition.left,
          offsetX: 1.5,
          offsetY: -2.5,
          labelColor: Color(0xFF101010),
          fontSize: 13,
          fontWeight: FontWeight.w800,
          showUnit: true,
          background: Color(0xFFECECEC),
          backgroundOpacity: 0.7,
        ),
        inlineLabel: const SeriesInlineLabelConfig(
          text: 'FTP',
          position: SeriesLabelPosition.center,
          offsetY: -4,
          color: Color(0xFF202020),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          background: SeriesLabelBackground(
            color: Color(0xFFF0F0F0),
            cornerRadius: 6,
            padding: EdgeInsets.fromLTRB(3, 4, 5, 6),
            borderColor: Color(0xFF303030),
            borderWidth: 2,
          ),
        ),
      );

      final decoded = _roundTrip(source) as LineChartSeries;

      expect(decoded.id, source.id);
      expect(decoded.name, source.name);
      expect(decoded.color, source.color);
      expect(decoded.style, source.style);
      expect(decoded.isXOrdered, isTrue);
      expect(decoded.metadata, source.metadata);
      expect(decoded.yAxisId, source.yAxisId);
      expect(decoded.yAxisConfig, source.yAxisConfig);
      expect(decoded.unit, source.unit);
      expect(decoded.interpolation, source.interpolation);
      expect(decoded.strokeWidth, source.strokeWidth);
      expect(decoded.tension, source.tension);
      expect(decoded.showDataPointMarkers, isTrue);
      expect(decoded.dataPointMarkerRadius, source.dataPointMarkerRadius);
      expect(decoded.dataPointMarkerStyle, source.dataPointMarkerStyle);
      expect(
        decoded.dataPointMarkerBackground,
        source.dataPointMarkerBackground,
      );
      expect(decoded.lineGlow, source.lineGlow);
      expect(decoded.dataPointLabels, source.dataPointLabels);
      expect(decoded.inlineLabel, source.inlineLabel);
      expect(decoded.points.single.x.isNaN, isTrue);
      expect(decoded.points.single.y, double.infinity);
      expect(decoded.points.single.timestamp, source.points.single.timestamp);
      expect(decoded.points.single.label, 'surge');
      expect(decoded.points.single.metadata, source.points.single.metadata);
      expect(
        decoded.points.single.segmentStyle,
        source.points.single.segmentStyle,
      );
      expect(decoded.points.single.pointStyle, source.points.single.pointStyle);
    });

    test('round-trips every area-series field', () {
      const source = AreaChartSeries(
        id: 'load',
        points: [ChartDataPoint(x: 1, y: 2)],
        color: Color(0xFF335577),
        style: SeriesStyle.area,
        interpolation: LineInterpolation.bezier,
        strokeWidth: 3,
        tension: 0.45,
        fillOpacity: 0.55,
        showDataPointMarkers: true,
        dataPointMarkerRadius: 6,
        dataPointMarkerStyle: DataPointMarkerStyle.hollow,
        dataPointMarkerBackground: Color(0xFFF8F8F8),
        lineGlow: 1.5,
        dataPointLabels: DataPointLabelConfig(show: true),
        inlineLabel: SeriesInlineLabelConfig(text: 'Load'),
        baselineValue: 0,
        aboveBaselineFillColor: Color(0xFF00AA00),
        belowBaselineFillColor: Color(0xFFAA0000),
      );

      final decoded = _roundTrip(source) as AreaChartSeries;

      expect(decoded.style, SeriesStyle.area);
      expect(decoded.interpolation, LineInterpolation.bezier);
      expect(decoded.strokeWidth, 3);
      expect(decoded.tension, 0.45);
      expect(decoded.fillOpacity, 0.55);
      expect(decoded.showDataPointMarkers, isTrue);
      expect(decoded.dataPointMarkerRadius, 6);
      expect(decoded.dataPointMarkerStyle, DataPointMarkerStyle.hollow);
      expect(decoded.dataPointMarkerBackground, const Color(0xFFF8F8F8));
      expect(decoded.lineGlow, 1.5);
      expect(decoded.dataPointLabels, source.dataPointLabels);
      expect(decoded.inlineLabel, source.inlineLabel);
      expect(decoded.baselineValue, 0);
      expect(decoded.aboveBaselineFillColor, const Color(0xFF00AA00));
      expect(decoded.belowBaselineFillColor, const Color(0xFFAA0000));
    });

    test('round-trips every pie-series field', () {
      final source = PieChartSeries(
        id: 'revenue-mix',
        name: 'Revenue mix',
        points: const [
          ChartDataPoint(
            x: 0,
            y: 42,
            label: 'Subscriptions',
            metadata: {'channel': 'recurring'},
            pointStyle: PointStyle(color: Color(0xFF6750A4), size: 357022),
          ),
          ChartDataPoint(
            x: 1,
            y: 0,
            label: 'Services',
            pointStyle: PointStyle(size: 505990),
          ),
        ],
        color: const Color(0xFF123456),
        metadata: const {'source': 'ledger'},
        unit: 'USD',
        pieStyle: const PieChartStyle(
          startAngleDegrees: 25,
          clockwise: false,
          radiusFactor: 0.75,
          sliceGap: 4,
          borderWidth: 2,
          borderColor: Color(0xFF223344),
          borderColorMode: PieBorderColorMode.slice,
          borderHueShiftDegrees: 24,
          borderSaturationShift: -0.1,
          borderLightnessShift: -0.18,
          gradient: PieGradientStyle(
            type: PieGradientType.radial,
            startColor: Color(0xFFE8F1FF),
            endColor: Color(0xFF123456),
            startLightnessShift: 0.22,
            endLightnessShift: -0.16,
            angleDegrees: 35,
          ),
          selectionExplodeOffset: 12,
          opacity: 0.76,
          cornerRadius: 9,
          cornerTreatment: PieCornerTreatment.outerOnly,
          shadow: PieElevationStyle(
            color: Color(0x55000000),
            blurRadius: 7,
            spreadRadius: 1,
            offset: Offset(0, 3),
            opacity: 0.8,
          ),
          selectedElevation: PieElevationStyle(
            blurRadius: 12,
            spreadRadius: 2,
            opacity: 0.45,
          ),
          animationMode: PieAnimationMode.none,
        ),
        dataLabels: const PieDataLabelConfig(
          isVisible: false,
          position: PieDataLabelPosition.inside,
          content: PieDataLabelContent.categoryValueAndPercentage,
          minimumShare: 0.05,
          minimumSweepDegrees: 12,
          padding: 8,
          outsideOffset: 18,
          connectorLength: 16,
          connectorWidth: 2,
          connectorColor: Color(0xFF556677),
          collisionStrategy: PieDataLabelCollisionStrategy.shift,
          calloutStyle: LabelStyle(
            textStyle: TextStyle(color: Colors.white, fontSize: 12),
            backgroundColor: Color(0xDD223344),
            borderColor: Color(0xFF556677),
            borderWidth: 1,
            borderRadius: 6,
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            shadowColor: Color(0x44000000),
            shadowBlurRadius: 4,
          ),
        ),
        sliceRadiusConfig: const PieSliceRadiusConfig(
          minimumFactor: 0.4,
          scale: PieSliceRadiusScale.linear,
          label: 'Total area',
          unit: 'km²',
        ),
      );

      final decoded = _roundTrip(source) as PieChartSeries;

      expect(decoded.id, source.id);
      expect(decoded.name, source.name);
      expect(decoded.points, source.points);
      expect(decoded.color, source.color);
      expect(decoded.metadata, source.metadata);
      expect(decoded.unit, source.unit);
      expect(decoded.pieStyle, source.pieStyle);
      expect(decoded.dataLabels, source.dataLabels);
      expect(decoded.sliceRadiusConfig, source.sliceRadiusConfig);
      expect(decoded.visiblePointIndices, [0]);
    });

    test('variable-radius pie documents advertise their capability', () {
      final encoded = ChartSeriesDocumentCodec.encode(
        PieChartSeries.fromMap(
          id: 'countries',
          values: const {'Germany': 233, 'Spain': 96},
          radiusValues: const {'Germany': 357022, 'Spain': 505990},
          sliceRadiusConfig: const PieSliceRadiusConfig(
            label: 'Total area',
            unit: 'km²',
          ),
        ),
      );

      expect(encoded, isA<ChartArtifactSuccess<ChartSeriesDocument>>());
      final document =
          (encoded as ChartArtifactSuccess<ChartSeriesDocument>).value;
      expect(
        document.requiredCapabilities,
        contains('series.pie.variable-radius.v1'),
      );

      final decoded = ChartSeriesDocumentCodec.decode(document);
      expect(decoded, isA<ChartArtifactSuccess<ChartSeries>>());
      final series =
          (decoded as ChartArtifactSuccess<ChartSeries>).value
              as PieChartSeries;
      expect(series.points.first.pointStyle?.size, 357022);
      expect(series.sliceRadiusConfig?.label, 'Total area');
    });

    test('round-trips first-class Donut geometry and capabilities', () {
      final source = DonutChartSeries.fromMap(
        id: 'donut',
        name: 'Registrations',
        unit: 'vehicles',
        values: const {'EV': 24, 'Hybrid': 13, 'Diesel': 37, 'Petrol': 26},
        radiusValues: const {'EV': 4, 'Hybrid': 2, 'Diesel': 5, 'Petrol': 3},
        sliceRadiusConfig: const RadialSliceRadiusConfig(
          minimumFactor: 0.3,
          scale: PieSliceRadiusScale.linear,
          label: 'Fleet size',
        ),
        donutStyle: const DonutChartStyle(
          innerRadiusFactor: 0.62,
          sweepAngleDegrees: 270,
          startAngleDegrees: -135,
          sliceGap: 4,
          cornerRadius: 6,
          cornerTreatment: PieCornerTreatment.roundAll,
        ),
        centerContent: const DonutCenterContent(
          label: 'Total vehicles',
          valueMode: DonutCenterValueMode.selectedOrTotal,
          labelStyle: LabelStyle(
            textStyle: TextStyle(color: Color(0xFF445566), fontSize: 12),
            backgroundColor: Color(0x00000000),
            borderColor: Color(0x00000000),
            borderWidth: 0,
            borderRadius: 0,
            padding: EdgeInsets.zero,
          ),
          valueStyle: LabelStyle(
            textStyle: TextStyle(
              color: Color(0xFF112233),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            backgroundColor: Color(0xFFF5F7FA),
            borderColor: Color(0xFFCCDDEE),
            borderWidth: 1,
            borderRadius: 8,
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
        ),
      );

      final encoded = ChartSeriesDocumentCodec.encode(source);
      expect(encoded, isA<ChartArtifactSuccess<ChartSeriesDocument>>());
      final document =
          (encoded as ChartArtifactSuccess<ChartSeriesDocument>).value;
      expect(document.type, 'donut');
      expect(document.requiredCapabilities, {
        'series.donut',
        'series.donut.style.v1',
        'series.donut.center-content.v1',
        'series.donut.variable-radius.v1',
      });

      final decoded = ChartSeriesDocumentCodec.decode(document);
      expect(decoded, isA<ChartArtifactSuccess<ChartSeries>>());
      final restored =
          (decoded as ChartArtifactSuccess<ChartSeries>).value
              as DonutChartSeries;
      expect(restored.points, source.points);
      expect(restored.donutStyle, source.donutStyle);
      expect(restored.centerContent, source.centerContent);
      expect(restored.dataLabels, source.dataLabels);
      expect(restored.sliceRadiusConfig, source.sliceRadiusConfig);
    });

    test('defaults older Donut documents to hidden center content', () {
      final encoded =
          ChartSeriesDocumentCodec.encode(
                DonutChartSeries.fromMap(
                  id: 'legacy-donut',
                  values: const {'A': 2, 'B': 1},
                  centerContent: const DonutCenterContent(
                    label: 'Total',
                    valueMode: DonutCenterValueMode.total,
                  ),
                ),
              )
              as ChartArtifactSuccess<ChartSeriesDocument>;
      final json = Map<String, Object?>.from(encoded.value.toJson());
      final style = Map<String, Object?>.from(json['style']! as Map)
        ..remove('centerContent');
      json['style'] = style;
      json['requiredCapabilities'] = ['series.donut', 'series.donut.style.v1'];

      final decoded =
          ChartSeriesDocumentCodec.decode(ChartSeriesDocument.fromJson(json))
              as ChartArtifactSuccess<ChartSeries>;

      expect(
        (decoded.value as DonutChartSeries).centerContent,
        DonutCenterContent.hidden,
      );
    });

    test(
      'defaults compact labels when an older pie document has no offset',
      () {
        final encoded = ChartSeriesDocumentCodec.encode(
          PieChartSeries.fromMap(
            id: 'legacy-pie',
            values: const {'A': 2, 'B': 1},
          ),
        );
        expect(encoded, isA<ChartArtifactSuccess<ChartSeriesDocument>>());
        final document =
            (encoded as ChartArtifactSuccess<ChartSeriesDocument>).value;
        final json = Map<String, Object?>.from(document.toJson());
        final style = Map<String, Object?>.from(json['style']! as Map);
        final labels = Map<String, Object?>.from(style['dataLabels']! as Map)
          ..remove('outsideOffset');
        style['dataLabels'] = labels;
        json['style'] = style;

        final decoded = ChartSeriesDocumentCodec.decode(
          ChartSeriesDocument.fromJson(json),
        );

        expect(decoded, isA<ChartArtifactSuccess<ChartSeries>>());
        final series = (decoded as ChartArtifactSuccess<ChartSeries>).value;
        expect((series as PieChartSeries).dataLabels.outsideOffset, 0);
      },
    );

    test('round-trips scatter, bar, and concrete base series', () {
      final scatter =
          _roundTrip(
                const ScatterChartSeries(
                  id: 'scatter',
                  points: [ChartDataPoint(x: 1, y: 3)],
                  style: SeriesStyle.scatter,
                  markerRadius: 8.5,
                ),
              )
              as ScatterChartSeries;
      expect(scatter.style, SeriesStyle.scatter);
      expect(scatter.markerRadius, 8.5);

      final bar =
          _roundTrip(
                const BarChartSeries(
                  id: 'bar',
                  points: [ChartDataPoint(x: 1, y: 3)],
                  style: SeriesStyle.bar,
                  barWidthPixels: 14,
                  minWidth: 5,
                  maxWidth: 42,
                  barGap: 6,
                  layoutMode: BarLayoutMode.normalizedStacked,
                  groupId: 'actual',
                  overlayWidthFactor: 0.62,
                  overlayOffsetFactor: 0.14,
                  baselineValue: -2,
                  minBarLength: 4,
                  barStyle: BarChartStyle(
                    cornerRadius: 7,
                    cornerRadiusPolicy: BarCornerRadiusPolicy.all,
                    opacity: 0.85,
                    gradient: BarGradient(
                      colors: [Color(0xFF123456), Color(0xFF65AADD)],
                      stops: [0, 1],
                    ),
                    border: BarBorderStyle(color: Color(0xFF0A0A0A), width: 2),
                    interaction: BarInteractionStyle(
                      hoverColor: Color(0xFFFFFFFF),
                      hoverOpacity: 0.2,
                      hoverBorderWidth: 3,
                      pressedColor: Color(0xFF111827),
                      pressedOpacity: 0.24,
                      selectionColor: Color(0xFF2563EB),
                      selectionOpacity: 0.18,
                      selectionBorderWidth: 4,
                      focusColor: Color(0xFFF59E0B),
                      focusBorderWidth: 3,
                      focusGap: 5,
                      dimmedOpacity: 0.3,
                    ),
                  ),
                  trackStyle: BarTrackStyle(
                    color: Color(0xFFE0E0E0),
                    value: 10,
                    opacity: 0.6,
                    cornerRadius: 9,
                    border: BarBorderStyle(color: Color(0xFFB0B0B0)),
                  ),
                  labelStyle: BarLabelStyle(
                    show: true,
                    position: BarLabelPosition.insideEnd,
                    valueMode: BarLabelValueMode.percentage,
                    color: Color(0xFFFFFFFF),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    showUnit: true,
                    padding: 5,
                  ),
                ),
              )
              as BarChartSeries;
      expect(bar.style, SeriesStyle.bar);
      expect(bar.barWidthPercent, isNull);
      expect(bar.barWidthPixels, 14);
      expect(bar.minWidth, 5);
      expect(bar.maxWidth, 42);
      expect(bar.barGap, 6);
      expect(bar.layoutMode, BarLayoutMode.normalizedStacked);
      expect(bar.groupId, 'actual');
      expect(bar.overlayWidthFactor, 0.62);
      expect(bar.overlayOffsetFactor, 0.14);
      expect(bar.baselineValue, -2);
      expect(bar.minBarLength, 4);
      expect(bar.barStyle.cornerRadius, 7);
      expect(bar.barStyle.cornerRadiusPolicy, BarCornerRadiusPolicy.all);
      expect(bar.barStyle.opacity, 0.85);
      expect(bar.barStyle.gradient?.colors, const [
        Color(0xFF123456),
        Color(0xFF65AADD),
      ]);
      expect(bar.barStyle.gradient?.stops, const [0, 1]);
      expect(bar.barStyle.border?.width, 2);
      expect(
        bar.barStyle.interaction,
        const BarInteractionStyle(
          hoverColor: Color(0xFFFFFFFF),
          hoverOpacity: 0.2,
          hoverBorderWidth: 3,
          pressedColor: Color(0xFF111827),
          pressedOpacity: 0.24,
          selectionColor: Color(0xFF2563EB),
          selectionOpacity: 0.18,
          selectionBorderWidth: 4,
          focusColor: Color(0xFFF59E0B),
          focusBorderWidth: 3,
          focusGap: 5,
          dimmedOpacity: 0.3,
        ),
      );
      expect(bar.trackStyle?.value, 10);
      expect(bar.trackStyle?.border?.color, const Color(0xFFB0B0B0));
      expect(bar.labelStyle.show, isTrue);
      expect(bar.labelStyle.position, BarLabelPosition.insideEnd);
      expect(bar.labelStyle.valueMode, BarLabelValueMode.percentage);
      expect(bar.labelStyle.fontWeight, FontWeight.w700);
      expect(bar.labelStyle.padding, 5);

      final base = _roundTrip(
        const ChartSeries(
          id: 'base',
          points: [ChartDataPoint(x: 1, y: 4)],
          style: SeriesStyle.line,
        ),
      );
      expect(base.runtimeType, ChartSeries);
      expect(base.style, SeriesStyle.line);
    });

    test('round-trips floating range bars and range labels', () {
      final source = const BarChartSeries(
        id: 'temperature-range',
        points: [
          ChartDataPoint(x: 0, y: 25),
          ChartDataPoint(x: 1, y: 29),
          ChartDataPoint(x: 2, y: 27),
        ],
        barWidthPercent: 0.7,
        rangeStartValues: [14, null, 15],
        labelStyle: BarLabelStyle(
          show: true,
          position: BarLabelPosition.rangeEnds,
          valueMode: BarLabelValueMode.range,
          showUnit: true,
        ),
      );

      final decoded = _roundTrip(source) as BarChartSeries;

      expect(decoded.rangeStartValues, const [14, null, 15]);
      expect(decoded.rangeStartValueFor(0), 14);
      expect(decoded.rangeStartValueFor(1), decoded.baselineValue);
      expect(decoded.labelStyle.position, BarLabelPosition.rangeEnds);
      expect(decoded.labelStyle.valueMode, BarLabelValueMode.range);
    });

    test('round-trips waterfall totals, semantic colors, and connectors', () {
      const source = BarChartSeries(
        id: 'profit-bridge',
        points: [
          ChartDataPoint(x: 0, y: 120),
          ChartDataPoint(x: 1, y: -35),
          ChartDataPoint(x: 2, y: 0),
        ],
        barWidthPercent: 0.72,
        layoutMode: BarLayoutMode.waterfall,
        waterfallTotalIndices: {2},
        waterfallStyle: BarWaterfallStyle(
          increaseColor: Color(0xFF168AAD),
          decreaseColor: Color(0xFFF9735B),
          totalColor: Color(0xFF3D3560),
          connector: BarWaterfallConnectorStyle(
            color: Color(0xFF737373),
            width: 1.5,
          ),
        ),
        labelStyle: BarLabelStyle(
          show: true,
          valueMode: BarLabelValueMode.waterfall,
        ),
      );

      final decoded = _roundTrip(source) as BarChartSeries;

      expect(decoded.layoutMode, BarLayoutMode.waterfall);
      expect(decoded.waterfallTotalIndices, const {2});
      expect(decoded.waterfallStyle.increaseColor, const Color(0xFF168AAD));
      expect(decoded.waterfallStyle.decreaseColor, const Color(0xFFF9735B));
      expect(decoded.waterfallStyle.totalColor, const Color(0xFF3D3560));
      expect(decoded.waterfallStyle.connector.color, const Color(0xFF737373));
      expect(decoded.waterfallStyle.connector.width, 1.5);
      expect(decoded.labelStyle.valueMode, BarLabelValueMode.waterfall);
    });

    test('round-trips horizontal bar orientation', () {
      const source = BarChartSeries(
        id: 'ranked',
        points: [ChartDataPoint(x: 0, y: 96), ChartDataPoint(x: 1, y: 84)],
        barWidthPercent: 0.72,
        orientation: BarOrientation.horizontal,
      );

      final decoded = _roundTrip(source) as BarChartSeries;

      expect(decoded.orientation, BarOrientation.horizontal);
      expect(decoded, source);
    });

    test('uses stable built-in type and capability identifiers', () {
      final cases = <(ChartSeries, (String, String))>[
        (
          const LineChartSeries(id: 'line', points: []),
          ('line', 'series.line'),
        ),
        (
          const ScatterChartSeries(id: 'scatter', points: []),
          ('scatter', 'series.scatter'),
        ),
        (
          const AreaChartSeries(id: 'area', points: []),
          ('area', 'series.area'),
        ),
        (
          const BarChartSeries(id: 'bar', points: [], barWidthPercent: 0.5),
          ('bar', 'series.bar'),
        ),
        (PieChartSeries(id: 'pie', points: const []), ('pie', 'series.pie')),
        (
          DonutChartSeries(id: 'donut', points: const []),
          ('donut', 'series.donut'),
        ),
        (const ChartSeries(id: 'base', points: []), ('base', 'series.base')),
      ];

      for (final (series, expected) in cases) {
        final encoded = ChartSeriesDocumentCodec.encode(series);
        expect(encoded, isA<ChartArtifactSuccess<ChartSeriesDocument>>());
        final document =
            (encoded as ChartArtifactSuccess<ChartSeriesDocument>).value;
        expect(document.type, expected.$1);
        expect(document.requiredCapabilities, {
          expected.$2,
          if (series is PieChartSeries) 'series.pie.style.v2',
          if (series is PieChartSeries) 'series.pie.corner-treatment.v1',
          if (series is DonutChartSeries) 'series.donut.style.v1',
        });
      }
    });

    test('encodes and hydrates every point field through inline columns', () {
      final source = LineChartSeries(
        id: 'columnar',
        points: [
          ChartDataPoint(
            x: 1,
            y: 240,
            timestamp: DateTime.utc(2026, 7, 15, 8),
            label: 'work',
            metadata: const {'lap': 2},
            segmentStyle: const SegmentStyle(strokeWidth: 3),
            pointStyle: const PointStyle(size: 8),
          ),
        ],
      );

      final encoded =
          ChartSeriesDocumentCodec.encode(
                source,
                dataStorage: ChartDataStorage.inlineColumns,
              )
              as ChartArtifactSuccess<ChartSeriesDocument>;
      final payload = encoded.value.data as InlineColumnarPayload;
      final roundTripped = ChartSeriesDocument.fromJson(encoded.value.toJson());
      final decoded =
          ChartSeriesDocumentCodec.decode(roundTripped)
              as ChartArtifactSuccess<ChartSeries>;

      expect(payload.pointCount, 1);
      expect(payload.labels, ['work']);
      expect(decoded.value.points.single, source.points.single);
    });

    test('fails closed for runtime callbacks', () {
      final labelFormatter =
          ChartSeriesDocumentCodec.encode(
                LineChartSeries(
                  id: 'callback',
                  points: const [],
                  dataPointLabels: DataPointLabelConfig(
                    formatter: (point) => point.y.toString(),
                  ),
                ),
              )
              as ChartArtifactFailure<ChartSeriesDocument>;
      expect(
        labelFormatter.error.code,
        ChartArtifactDiagnosticCodes.runtimeBindingRequired,
      );
      expect(labelFormatter.error.path, contains('formatter'));

      final axisFormatter =
          ChartSeriesDocumentCodec.encode(
                LineChartSeries(
                  id: 'axis-callback',
                  points: const [],
                  yAxisConfig: YAxisConfig(
                    position: YAxisPosition.left,
                    labelFormatter: (value) => '$value W',
                  ),
                ),
              )
              as ChartArtifactFailure<ChartSeriesDocument>;
      expect(
        axisFormatter.error.code,
        ChartArtifactDiagnosticCodes.runtimeBindingRequired,
      );

      final barFormatter =
          ChartSeriesDocumentCodec.encode(
                BarChartSeries(
                  id: 'bar-callback',
                  points: const [],
                  barWidthPercent: 0.7,
                  labelStyle: BarLabelStyle(
                    formatter: (point) => point.y.toString(),
                  ),
                ),
              )
              as ChartArtifactFailure<ChartSeriesDocument>;
      expect(
        barFormatter.error.code,
        ChartArtifactDiagnosticCodes.runtimeBindingRequired,
      );
      expect(barFormatter.error.path, contains('barLabels.formatter'));
    });

    test('round-trips series-level annotations', () {
      final source = LineChartSeries(
        id: 'annotated',
        points: const [],
        annotations: [PinAnnotation(id: 'pin', x: 1, y: 2)],
      );

      final decoded = _roundTrip(source) as LineChartSeries;

      expect(decoded.annotations, hasLength(1));
      expect(decoded.annotations.single, isA<PinAnnotation>());
      expect(decoded.annotations.single.id, 'pin');
    });

    test('rejects metadata that is not recursively JSON-safe', () {
      final result = ChartSeriesDocumentCodec.encode(
        LineChartSeries(
          id: 'unsafe',
          points: const [],
          metadata: {'createdAt': DateTime.utc(2026)},
        ),
      );

      expect(result, isA<ChartArtifactFailure<ChartSeriesDocument>>());
      expect(
        (result as ChartArtifactFailure<ChartSeriesDocument>).error.code,
        ChartArtifactDiagnosticCodes.metadataValueNotJsonSafe,
      );
    });

    test('subtype copyWith preserves base style and annotations', () {
      final annotation = PinAnnotation(id: 'pin', x: 1, y: 2);
      final source = LineChartSeries(
        id: 'line',
        points: const [],
        style: SeriesStyle.line,
        annotations: [annotation],
      );

      final copy = source.copyWith(name: 'copy');

      expect(copy.style, SeriesStyle.line);
      expect(copy.annotations, [annotation]);
    });

    test('rejects cyclic series and annotation model graphs', () {
      final annotations = <ChartAnnotation>[];
      final series = LineChartSeries(
        id: 'cycle',
        points: const [],
        annotations: annotations,
      );
      annotations.add(LegendAnnotation(id: 'legend', series: [series]));

      final result = ChartSeriesDocumentCodec.encode(series);

      expect(result, isA<ChartArtifactFailure<ChartSeriesDocument>>());
      final failure = result as ChartArtifactFailure<ChartSeriesDocument>;
      expect(
        failure.error.code,
        ChartArtifactDiagnosticCodes.validationLimitExceeded,
      );
      expect(failure.error.message, contains('Cyclic'));
    });

    test('returns a structured failure for unknown series types', () {
      final result = ChartSeriesDocumentCodec.decode(
        ChartSeriesDocument(
          type: 'com.example.heatmap',
          id: 'custom',
          data: InlinePointPayload(const []),
          style: JsonValue.fromJson({'isXOrdered': false}) as JsonObjectValue,
        ),
      );

      expect(result, isA<ChartArtifactFailure<ChartSeries>>());
      final failure = result as ChartArtifactFailure<ChartSeries>;
      expect(
        failure.error.code,
        ChartArtifactDiagnosticCodes.unsupportedModelType,
      );
      expect(failure.error.path, r'$.type');
    });
  });
}

ChartSeries _roundTrip(ChartSeries source) {
  final encoded = ChartSeriesDocumentCodec.encode(source);
  expect(encoded, isA<ChartArtifactSuccess<ChartSeriesDocument>>());
  final document = (encoded as ChartArtifactSuccess<ChartSeriesDocument>).value;
  final jsonRoundTrip = ChartSeriesDocument.fromJson(document.toJson());
  final decoded = ChartSeriesDocumentCodec.decode(jsonRoundTrip);
  expect(decoded, isA<ChartArtifactSuccess<ChartSeries>>());
  return (decoded as ChartArtifactSuccess<ChartSeries>).value;
}
