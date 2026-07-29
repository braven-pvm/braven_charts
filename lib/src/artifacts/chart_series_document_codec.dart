import 'package:flutter/foundation.dart' show internal;
import 'package:flutter/material.dart';

import '../models/chart_annotation.dart';
import '../models/bar_chart_style.dart';
import '../models/candlestick_chart_series.dart';
import '../models/candlestick_chart_style.dart';
import '../models/candlestick_data_point.dart';
import '../models/candlestick_density_grouping.dart';
import '../models/chart_data_point.dart';
import '../models/chart_series.dart';
import '../models/data_point_label_config.dart';
import '../models/donut_chart_config.dart';
import '../models/donut_chart_series.dart';
import '../models/gauge_chart_series.dart';
import '../models/pie_chart_config.dart';
import '../models/pie_chart_series.dart';
import '../models/path_animation_style.dart';
import '../models/polar_chart_config.dart';
import '../models/polar_column_chart_series.dart';
import '../models/radial_bar_chart_series.dart';
import '../models/radial_category_series.dart';
import '../models/radial_selection_style.dart';
import '../models/range_area_chart_series.dart';
import '../models/range_area_data_point.dart';
import '../models/range_area_style.dart';
import '../models/scatter_marker_style.dart';
import '../models/scatter_render_config.dart';
import '../models/segment_style.dart';
import '../models/series_inline_label_config.dart';
import '../models/y_axis_config.dart';
import '../models/y_axis_position.dart';
import '../theming/components/series_theme.dart' show SeriesMarkerShape;
import 'chart_annotation_document.dart';
import 'chart_annotation_document_codec.dart';
import 'chart_artifact_diagnostics.dart';
import 'chart_data_payload.dart';
import 'chart_data_storage.dart';
import 'chart_model_codec_context.dart';
import 'chart_style_document_codec.dart';
import 'donut_center_content_document_codec.dart';
import 'json_value.dart';
import 'radial_formatter_document_descriptors.dart';

/// Audited adapter between public built-in series models and schema-v1
/// [ChartSeriesDocument] values.
///
/// This codec is intentionally separate from the legacy `ChartSeries.toJson`
/// shape. It preserves every point and rendering-relevant property supported
/// by the built-in series models. Executable callbacks fail closed until their
/// runtime binding descriptors are supplied.
abstract final class ChartSeriesDocumentCodec {
  static ChartArtifactResult<ChartSeriesDocument> encode(
    ChartSeries series, {
    JsonObjectValue? inlineAxisFormatter,
    RadialFormatterDocumentDescriptors? radialFormatterDescriptors,
    ChartDataStorage dataStorage = ChartDataStorage.inlinePoints,
  }) => encodeWithContext(
    series,
    ChartModelCodecContext(dataStorage: dataStorage),
    inlineAxisFormatter: inlineAxisFormatter,
    radialFormatterDescriptors: radialFormatterDescriptors,
  );

  @internal
  static ChartArtifactResult<ChartSeriesDocument> encodeWithContext(
    ChartSeries series,
    ChartModelCodecContext context, {
    JsonObjectValue? inlineAxisFormatter,
    RadialFormatterDocumentDescriptors? radialFormatterDescriptors,
  }) {
    var entered = false;
    try {
      context.enter(series);
      entered = true;
      if (series.yAxisConfig?.labelFormatter != null &&
          inlineAxisFormatter == null) {
        throw const _RuntimeBindingException(
          'Y-axis label formatters must be represented by a runtime binding descriptor.',
          r'$.inlineAxis.labelFormatter',
        );
      }

      final dataPointLabels = switch (series) {
        LineChartSeries() => series.dataPointLabels,
        AreaChartSeries() => series.dataPointLabels,
        ScatterChartSeries() => series.dataPointLabels,
        RangeAreaChartSeries() => series.labelConfig.labels,
        _ => null,
      };
      if (dataPointLabels?.formatter != null) {
        throw const _RuntimeBindingException(
          'Data-point label formatters must be represented by a runtime binding descriptor.',
          r'$.style.dataPointLabels.formatter',
        );
      }
      if (series is BarChartSeries && series.labelStyle.formatter != null) {
        throw const _RuntimeBindingException(
          'Bar label formatters must be represented by a runtime binding descriptor.',
          r'$.style.barLabels.formatter',
        );
      }
      if (series is RangeAreaChartSeries &&
          series.labelConfig.formatter != null) {
        throw const _RuntimeBindingException(
          'Range Area label formatters must be represented by a runtime binding descriptor.',
          r'$.style.labelConfig.formatter',
        );
      }
      if (series case final RadialCategorySeries radial) {
        _requireRadialFormatterDescriptor(
          formatter: radial.dataLabels.valueFormatter,
          descriptor: radialFormatterDescriptors?.value,
          path: r'$.style.dataLabels.valueFormatter',
          label: 'Radial value',
        );
        _requireRadialFormatterDescriptor(
          formatter: radial.dataLabels.percentageFormatter,
          descriptor: radialFormatterDescriptors?.percentage,
          path: r'$.style.dataLabels.percentageFormatter',
          label: 'Radial percentage',
        );
        _requireRadialFormatterDescriptor(
          formatter: radial.sliceRadiusConfig?.formatter,
          descriptor: radialFormatterDescriptors?.radius,
          path: r'$.style.sliceRadiusConfig.formatter',
          label: 'Radial radius',
        );
        _requireRadialFormatterDescriptor(
          formatter: radial is DonutChartSeries
              ? radial.centerContent.valueFormatter
              : null,
          descriptor: radialFormatterDescriptors?.center,
          path: r'$.style.centerContent.valueFormatter',
          label: 'Donut center',
        );
      }

      final points = [
        for (var index = 0; index < series.points.length; index++)
          _encodePoint(series.points[index], index),
      ];
      return ChartArtifactSuccess(
        value: ChartSeriesDocument(
          type: _typeOf(series),
          id: series.id,
          name: series.name,
          unit: series.unit,
          axisId: series.yAxisId,
          inlineAxis: _encodeAxis(
            series.yAxisConfig,
            formatter: inlineAxisFormatter,
          ),
          style: _jsonObject(
            _encodeSeriesStyle(series, radialFormatterDescriptors),
            path: r'$.style',
          ),
          metadata: _jsonObjectOrNull(series.metadata, path: r'$.metadata'),
          annotations: [
            for (final annotation in series.annotations)
              _encodeAnnotationOrThrow(annotation, context),
          ],
          data: switch (context.dataStorage) {
            ChartDataStorage.inlinePoints => InlinePointPayload(points),
            ChartDataStorage.inlineColumns => InlineColumnarPayload.fromPoints(
              points,
            ),
          },
          requiredCapabilities: {
            'series.${_typeOf(series)}',
            if (series is RangeAreaChartSeries) 'series.rangeArea.interval.v1',
            if (series is CandlestickChartSeries) 'series.candlestick.ohlc.v1',
            if (series is CandlestickChartSeries &&
                series.animation != const CandlestickAnimationStyle())
              'series.candlestick.motion.v1',
            if (series is CandlestickChartSeries &&
                series.densityGrouping.enabled)
              'series.candlestick.density-grouping.v1',
            if (series is BarChartSeries && series.barStyle.pattern != null)
              'series.bar.pattern.v1',
            if (series is BarChartSeries && series.bulletStyle != null)
              'series.bar.bullet.v1',
            if (series is BarChartSeries && series.lollipopStyle != null)
              'series.bar.lollipop.v1',
            if (series is BarChartSeries &&
                series.layoutMode == BarLayoutMode.divergingStacked)
              'series.bar.diverging.v1',
            if (series is ScatterChartSeries &&
                (series.markerStyle != null ||
                    series.points.any(
                      (point) => point.pointStyle?.scatterMarkerStyle != null,
                    )))
              'series.scatter.marker-style.v1',
            if (series is ScatterChartSeries &&
                series.interactionStyle != const ScatterInteractionStyle())
              'series.scatter.interaction.v1',
            if (series is ScatterChartSeries && series.sizeEncoding != null)
              'series.scatter.size-encoding.v1',
            if (series is ScatterChartSeries && series.colorEncoding != null)
              'series.scatter.color-encoding.v1',
            if (series is ScatterChartSeries && series.opacityEncoding != null)
              'series.scatter.opacity-encoding.v1',
            if (series is ScatterChartSeries && series.categoryEncoding != null)
              'series.scatter.category-encoding.v1',
            if (series is ScatterChartSeries &&
                series.jitter != const ScatterJitterConfig())
              'series.scatter.jitter.v1',
            if (series is ScatterChartSeries &&
                series.renderMode == ScatterRenderMode.clusters)
              'series.scatter.clusters.v1',
            if (series is ScatterChartSeries &&
                (series.renderMode == ScatterRenderMode.rectangularBins ||
                    series.renderMode == ScatterRenderMode.hexbin))
              'series.scatter.bins.v1',
            if (series is ScatterChartSeries &&
                series.renderMode == ScatterRenderMode.density)
              'series.scatter.density.v1',
            if (series is PieChartSeries) 'series.pie.style.v2',
            if (series is PieChartSeries) 'series.pie.corner-treatment.v1',
            if (series is PieChartSeries && series.hasVariableSliceRadius)
              'series.pie.variable-radius.v1',
            if (series is DonutChartSeries) 'series.donut.style.v1',
            if (series is DonutChartSeries && series.centerContent.isVisible)
              'series.donut.center-content.v1',
            if (series is DonutChartSeries && series.hasVariableSliceRadius)
              'series.donut.variable-radius.v1',
            if (series is PolarColumnChartSeries) 'series.polar.column.v1',
            if (series is PolarColumnChartSeries &&
                series.polarStyle.cornerRadiusMode !=
                    PolarColumnCornerRadiusMode.outerEnd)
              PolarColumnChartSeries.cornerRadiusModeCapability,
            if (series is PolarColumnChartSeries &&
                series.polarStyle.hasAdvancedAppearance)
              PolarColumnChartSeries.appearanceCapability,
            if (series is PolarColumnChartSeries &&
                series.targetValues.isNotEmpty)
              'series.polar.column.targets.v1',
            if (series is PolarColumnChartSeries && series.hasIntervals)
              'series.polar.column.intervals.v1',
            if (series is RadialBarChartSeries) 'series.radial.bar.v1',
            if (series is GaugeChartSeries) 'series.gauge.v1',
            if (series is RadialCategorySeries &&
                series.sliceGroupingConfig != null)
              'series.radial.grouping.v1',
            if (series is RadialCategorySeries &&
                series.sliceGroupingConfig?.radiusAggregation != null)
              'series.radial.grouped-variable-radius.v1',
            if (series is RadialCategorySeries &&
                radialFormatterDescriptors?.isNotEmpty == true)
              'series.radial.formatters.v1',
            if (series is RadialCategorySeries &&
                series.radialStyle.dataTransitionMode ==
                    RadialDataTransitionMode.automatic)
              'series.radial.data-transitions.v1',
            if (series is RadialCategorySeries &&
                series.selectionStyle.effect == RadialSelectionEffect.lift)
              'series.radial.selection-lift.v1',
            if (series is RadialCategorySeries &&
                series.dataLabels.secondaryContent != null)
              'series.radial.dual-labels.v1',
            if ((series is LineChartSeries ||
                    series is AreaChartSeries ||
                    series is RangeAreaChartSeries) &&
                _pathAnimationFor(series) != const PathAnimationStyle())
              'series.path-motion.v1',
            if ((series is LineChartSeries ||
                    series is AreaChartSeries ||
                    series is RangeAreaChartSeries) &&
                _hasNonDefaultPathTiming(_pathAnimationFor(series)!))
              'series.path-motion-timing.v1',
            if (series is AreaChartSeries && series.fillGradient != null)
              'series.area.gradient.v1',
            if (series is RangeAreaChartSeries && series.fillGradient != null)
              'series.rangeArea.gradient.v1',
            if ((series is LineChartSeries ||
                    series is AreaChartSeries ||
                    series is RangeAreaChartSeries) &&
                _hasPathDashCapability(series))
              'series.path-dash.v1',
          },
        ),
      );
    } on _RuntimeBindingException catch (error) {
      return ChartArtifactFailure(
        error: ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.runtimeBindingRequired,
          message: error.message,
          path: error.path,
        ),
      );
    } on _UnsupportedModelException catch (error) {
      return ChartArtifactFailure(
        error: ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.unsupportedModelType,
          message: error.message,
          path: error.path,
        ),
      );
    } on _NestedCodecException catch (error) {
      return ChartArtifactFailure(error: error.error);
    } on ChartModelGraphException catch (error) {
      return ChartArtifactFailure(
        error: ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.validationLimitExceeded,
          message: error.message,
          path: r'$.annotations',
        ),
      );
    } on ArgumentError catch (error) {
      return ChartArtifactFailure(
        error: ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.metadataValueNotJsonSafe,
          message: error.message?.toString() ?? 'Metadata is not JSON-safe.',
        ),
      );
    } on FormatException catch (error) {
      return ChartArtifactFailure(
        error: ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.metadataValueNotJsonSafe,
          message: error.message,
        ),
      );
    } finally {
      if (entered) context.exit(series);
    }
  }

  static ChartArtifactResult<ChartSeries> decode(
    ChartSeriesDocument document, {
    YAxisLabelFormatter? inlineAxisFormatter,
    RadialValueFormatter? radialValueFormatter,
    RadialValueFormatter? radialPercentageFormatter,
    RadialValueFormatter? radialRadiusFormatter,
    RadialValueFormatter? donutCenterFormatter,
  }) {
    try {
      final payload = document.data;
      if (payload is! InlineChartDataPayload) {
        throw _UnsupportedModelException(
          'Unsupported data payload: ${payload.storage}.',
          r'$.data.storage',
        );
      }

      final style = _objectMap(document.style);
      final points = payload.points
          .map(switch (document.type) {
            'candlestick' => _decodeCandlestickPoint,
            'rangeArea' => _decodeRangeAreaPoint,
            _ => _decodePoint,
          })
          .toList(growable: false);
      final metadata = _dynamicMap(document.metadata);
      final axis = _decodeAxis(
        document.inlineAxis,
        formatter: inlineAxisFormatter,
      );
      final annotations = [
        for (final annotation in document.annotations)
          _decodeAnnotationOrThrow(annotation),
      ];
      final commonStyle = _optionalEnum(
        style['seriesStyle'],
        SeriesStyle.values,
        r'$.style.seriesStyle',
      );
      final showInLegend = _bool(style, 'showInLegend', fallback: true);
      final showTrackingAxisLabel = _bool(
        style,
        'showTrackingAxisLabel',
        fallback: true,
      );

      final series = switch (document.type) {
        'base' => ChartSeries(
          id: document.id,
          name: document.name,
          points: points,
          color: _optionalColor(style['color'], r'$.style.color'),
          style: commonStyle,
          isXOrdered: _bool(style, 'isXOrdered', fallback: false),
          metadata: metadata,
          annotations: annotations,
          yAxisId: document.axisId,
          yAxisConfig: axis,
          unit: document.unit,
          showInLegend: showInLegend,
          showTrackingAxisLabel: showTrackingAxisLabel,
        ),
        'line' => LineChartSeries(
          id: document.id,
          name: document.name,
          points: points,
          color: _optionalColor(style['color'], r'$.style.color'),
          style: commonStyle,
          isXOrdered: _bool(style, 'isXOrdered', fallback: false),
          metadata: metadata,
          annotations: annotations,
          yAxisId: document.axisId,
          yAxisConfig: axis,
          unit: document.unit,
          showInLegend: showInLegend,
          showTrackingAxisLabel: showTrackingAxisLabel,
          interpolation: _enum(
            style,
            'interpolation',
            LineInterpolation.values,
          ),
          strokeWidth: _double(style, 'strokeWidth'),
          tension: _double(style, 'tension'),
          showDataPointMarkers: _bool(style, 'showDataPointMarkers'),
          dataPointMarkerRadius: _double(style, 'dataPointMarkerRadius'),
          dataPointMarkerStyle: _enum(
            style,
            'dataPointMarkerStyle',
            DataPointMarkerStyle.values,
          ),
          dataPointMarkerBackground: _color(style, 'dataPointMarkerBackground'),
          lineGlow: _double(style, 'lineGlow'),
          dataPointLabels: _decodeDataPointLabels(
            _optionalMap(style, 'dataPointLabels'),
          ),
          inlineLabel: _decodeInlineLabel(_optionalMap(style, 'inlineLabel')),
          pathAnimation: _decodePathAnimation(
            _optionalMap(style, 'pathAnimation'),
          ),
          dashPattern: _decodeDashPattern(style['dashPattern']),
        ),
        'scatter' => ScatterChartSeries(
          id: document.id,
          name: document.name,
          points: points,
          color: _optionalColor(style['color'], r'$.style.color'),
          style: commonStyle,
          isXOrdered: _bool(style, 'isXOrdered', fallback: false),
          metadata: metadata,
          annotations: annotations,
          yAxisId: document.axisId,
          yAxisConfig: axis,
          unit: document.unit,
          showInLegend: showInLegend,
          showTrackingAxisLabel: showTrackingAxisLabel,
          markerRadius: _double(style, 'markerRadius'),
          markerShape:
              _optionalEnum(
                style['markerShape'],
                SeriesMarkerShape.values,
                r'$.style.markerShape',
              ) ??
              SeriesMarkerShape.circle,
          markerStyle: _decodeScatterMarkerStyle(
            _optionalMap(style, 'markerStyle'),
          ),
          sizeEncoding: _decodeScatterSizeEncoding(
            _optionalMap(style, 'sizeEncoding'),
          ),
          colorEncoding: _decodeScatterColorEncoding(
            _optionalMap(style, 'colorEncoding'),
          ),
          opacityEncoding: _decodeScatterOpacityEncoding(
            _optionalMap(style, 'opacityEncoding'),
          ),
          categoryEncoding: _decodeScatterCategoryEncoding(
            _optionalMap(style, 'categoryEncoding'),
          ),
          jitter: _decodeScatterJitter(_optionalMap(style, 'jitter')),
          renderMode:
              _optionalEnum(
                style['renderMode'],
                ScatterRenderMode.values,
                r'$.style.renderMode',
              ) ??
              ScatterRenderMode.points,
          clusterConfig: _decodeScatterClusterConfig(
            _optionalMap(style, 'clusterConfig'),
          ),
          binConfig: _decodeScatterBinConfig(_optionalMap(style, 'binConfig')),
          densityConfig: _decodeScatterDensityConfig(
            _optionalMap(style, 'densityConfig'),
          ),
          dataPointLabels: _decodeDataPointLabels(
            _optionalMap(style, 'dataPointLabels'),
          ),
          interactionStyle: _decodeScatterInteraction(
            _optionalMap(style, 'interaction'),
          ),
        ),
        'area' => AreaChartSeries(
          id: document.id,
          name: document.name,
          points: points,
          color: _optionalColor(style['color'], r'$.style.color'),
          style: commonStyle,
          isXOrdered: _bool(style, 'isXOrdered', fallback: false),
          metadata: metadata,
          annotations: annotations,
          yAxisId: document.axisId,
          yAxisConfig: axis,
          unit: document.unit,
          showInLegend: showInLegend,
          showTrackingAxisLabel: showTrackingAxisLabel,
          interpolation: _enum(
            style,
            'interpolation',
            LineInterpolation.values,
          ),
          strokeWidth: _double(style, 'strokeWidth'),
          tension: _double(style, 'tension'),
          fillOpacity: _double(style, 'fillOpacity'),
          fillGradient: _decodeAreaGradient(
            _optionalMap(style, 'fillGradient'),
          ),
          showDataPointMarkers: _bool(style, 'showDataPointMarkers'),
          dataPointMarkerRadius: _double(style, 'dataPointMarkerRadius'),
          dataPointMarkerStyle: _enum(
            style,
            'dataPointMarkerStyle',
            DataPointMarkerStyle.values,
          ),
          dataPointMarkerBackground: _color(style, 'dataPointMarkerBackground'),
          lineGlow: _double(style, 'lineGlow'),
          dataPointLabels: _decodeDataPointLabels(
            _optionalMap(style, 'dataPointLabels'),
          ),
          inlineLabel: _decodeInlineLabel(_optionalMap(style, 'inlineLabel')),
          baselineValue: _optionalDouble(style['baselineValue']),
          aboveBaselineFillColor: _optionalColor(
            style['aboveBaselineFillColor'],
            r'$.style.aboveBaselineFillColor',
          ),
          belowBaselineFillColor: _optionalColor(
            style['belowBaselineFillColor'],
            r'$.style.belowBaselineFillColor',
          ),
          dashPattern: _decodeDashPattern(style['dashPattern']),
          pathAnimation: _decodePathAnimation(
            _optionalMap(style, 'pathAnimation'),
          ),
        ),
        'rangeArea' => RangeAreaChartSeries(
          id: document.id,
          name: document.name,
          points: points.cast<RangeAreaDataPoint>(),
          color: _optionalColor(style['color'], r'$.style.color'),
          metadata: metadata,
          annotations: annotations,
          yAxisId: document.axisId,
          yAxisConfig: axis,
          unit: document.unit,
          showInLegend: showInLegend,
          showTrackingAxisLabel: showTrackingAxisLabel,
          interpolation: _enum(
            style,
            'interpolation',
            LineInterpolation.values,
          ),
          tension: _double(style, 'tension'),
          fillOpacity: _double(style, 'fillOpacity'),
          fillGradient: _decodeAreaGradient(
            _optionalMap(style, 'fillGradient'),
          ),
          borderMode: _enum(style, 'borderMode', RangeAreaBorderMode.values),
          upperBoundaryStyle: _decodeRangeAreaBoundaryStyle(
            _optionalMap(style, 'upperBoundaryStyle'),
          ),
          lowerBoundaryStyle: _decodeRangeAreaBoundaryStyle(
            _optionalMap(style, 'lowerBoundaryStyle'),
          ),
          connectGaps: _bool(style, 'connectGaps'),
          showBoundaryMarkers: _bool(style, 'showBoundaryMarkers'),
          markerRadius: _double(style, 'markerRadius'),
          labelConfig: _decodeRangeAreaLabelConfig(
            _optionalMap(style, 'labelConfig'),
          ),
          hitTestMode: _enum(style, 'hitTestMode', RangeAreaHitTestMode.values),
          pathAnimation: _decodePathAnimation(
            _optionalMap(style, 'pathAnimation'),
          ),
        ),
        'bar' => BarChartSeries(
          id: document.id,
          name: document.name,
          points: points,
          color: _optionalColor(style['color'], r'$.style.color'),
          style: commonStyle,
          isXOrdered: _bool(style, 'isXOrdered', fallback: false),
          metadata: metadata,
          annotations: annotations,
          yAxisId: document.axisId,
          yAxisConfig: axis,
          unit: document.unit,
          showInLegend: showInLegend,
          showTrackingAxisLabel: showTrackingAxisLabel,
          barWidthPercent: _optionalDouble(style['barWidthPercent']),
          barWidthPixels: _optionalDouble(style['barWidthPixels']),
          minWidth: _double(style, 'minWidth'),
          maxWidth: _double(style, 'maxWidth'),
          barGap: _optionalDouble(style['barGap']) ?? 2.0,
          orientation:
              _optionalEnum(
                style['barOrientation'],
                BarOrientation.values,
                r'$.style.barOrientation',
              ) ??
              BarOrientation.vertical,
          layoutMode:
              _optionalEnum(
                style['barLayoutMode'],
                BarLayoutMode.values,
                r'$.style.barLayoutMode',
              ) ??
              BarLayoutMode.grouped,
          groupId: _optionalString(style['barGroupId']),
          divergingRole:
              _optionalEnum(
                style['barDivergingRole'],
                BarDivergingRole.values,
                r'$.style.barDivergingRole',
              ) ??
              BarDivergingRole.positive,
          divergingStyle: _decodeBarDivergingStyle(
            _optionalMap(style, 'barDivergingStyle'),
          ),
          overlayWidthFactor:
              _optionalDouble(style['barOverlayWidthFactor']) ?? 1.0,
          overlayOffsetFactor:
              _optionalDouble(style['barOverlayOffsetFactor']) ?? 0.0,
          baselineValue: _optionalDouble(style['baselineValue']) ?? 0.0,
          rangeStartValues: _decodeOptionalDoubleList(
            style['barRangeStartValues'],
            r'$.style.barRangeStartValues',
          ),
          waterfallTotalIndices: _decodeIntSet(
            style['barWaterfallTotalIndices'],
            r'$.style.barWaterfallTotalIndices',
          ),
          waterfallStyle: _decodeBarWaterfallStyle(
            _optionalMap(style, 'barWaterfallStyle'),
          ),
          minBarLength: _optionalDouble(style['minBarLength']) ?? 0.0,
          barStyle: _decodeBarStyle(_optionalMap(style, 'barStyle')),
          trackStyle: _decodeBarTrack(_optionalMap(style, 'barTrack')),
          lollipopStyle: _decodeBarLollipop(_optionalMap(style, 'barLollipop')),
          bulletStyle: _decodeBarBullet(_optionalMap(style, 'barBullet')),
          targetValues: _decodeOptionalDoubleList(
            style['barTargetValues'],
            r'$.style.barTargetValues',
          ),
          targetMarkerStyle: _decodeBarTargetMarker(
            _optionalMap(style, 'barTargetMarker'),
          ),
          errorLowerValues: _decodeOptionalDoubleList(
            style['barErrorLowerValues'],
            r'$.style.barErrorLowerValues',
          ),
          errorUpperValues: _decodeOptionalDoubleList(
            style['barErrorUpperValues'],
            r'$.style.barErrorUpperValues',
          ),
          errorBarStyle: _decodeBarErrorBar(_optionalMap(style, 'barErrorBar')),
          labelStyle: _decodeBarLabels(_optionalMap(style, 'barLabels')),
        ),
        'candlestick' => CandlestickChartSeries(
          id: document.id,
          name: document.name,
          points: points.cast<CandlestickDataPoint>(),
          color: _optionalColor(style['color'], r'$.style.color'),
          metadata: metadata,
          annotations: annotations,
          yAxisId: document.axisId,
          yAxisConfig: axis,
          unit: document.unit,
          showInLegend: showInLegend,
          showTrackingAxisLabel: showTrackingAxisLabel,
          candlestickStyle: _decodeCandlestickStyle(
            _optionalMap(style, 'candlestickStyle'),
          ),
          animation: _decodeCandlestickAnimation(
            _optionalMap(style, 'candlestickAnimation'),
          ),
          densityGrouping: _decodeCandlestickDensityGrouping(
            _optionalMap(style, 'candlestickDensityGrouping'),
          ),
        ),
        'pie' => PieChartSeries(
          id: document.id,
          name: document.name,
          points: points,
          color: _optionalColor(style['color'], r'$.style.color'),
          metadata: metadata,
          unit: document.unit,
          showInLegend: showInLegend,
          showTrackingAxisLabel: showTrackingAxisLabel,
          pieStyle: _decodePieStyle(_map(style, 'pieStyle')),
          selectionStyle: _optionalMap(style, 'selectionStyle') == null
              ? const RadialSelectionStyle()
              : _decodeRadialSelectionStyle(_map(style, 'selectionStyle')),
          dataLabels: _decodePieDataLabels(
            _map(style, 'dataLabels'),
            valueFormatter: radialValueFormatter,
            percentageFormatter: radialPercentageFormatter,
          ),
          sliceRadiusConfig: _optionalMap(style, 'sliceRadiusConfig') == null
              ? null
              : _decodePieSliceRadiusConfig(
                  _map(style, 'sliceRadiusConfig'),
                  formatter: radialRadiusFormatter,
                ),
          sliceGroupingConfig:
              _optionalMap(style, 'sliceGroupingConfig') == null
              ? null
              : _decodeRadialSliceGroupingConfig(
                  _map(style, 'sliceGroupingConfig'),
                ),
        ),
        'donut' => DonutChartSeries(
          id: document.id,
          name: document.name,
          points: points,
          color: _optionalColor(style['color'], r'$.style.color'),
          metadata: metadata,
          unit: document.unit,
          showInLegend: showInLegend,
          showTrackingAxisLabel: showTrackingAxisLabel,
          donutStyle: _decodeDonutStyle(_map(style, 'donutStyle')),
          selectionStyle: _optionalMap(style, 'selectionStyle') == null
              ? const RadialSelectionStyle()
              : _decodeRadialSelectionStyle(_map(style, 'selectionStyle')),
          centerContent: _optionalMap(style, 'centerContent') == null
              ? DonutCenterContent.hidden
              : DonutCenterContentDocumentCodec.decode(
                  _map(style, 'centerContent'),
                  valueFormatter: donutCenterFormatter,
                ),
          dataLabels: _decodePieDataLabels(
            _map(style, 'dataLabels'),
            valueFormatter: radialValueFormatter,
            percentageFormatter: radialPercentageFormatter,
          ),
          sliceRadiusConfig: _optionalMap(style, 'sliceRadiusConfig') == null
              ? null
              : _decodePieSliceRadiusConfig(
                  _map(style, 'sliceRadiusConfig'),
                  formatter: radialRadiusFormatter,
                ),
          sliceGroupingConfig:
              _optionalMap(style, 'sliceGroupingConfig') == null
              ? null
              : _decodeRadialSliceGroupingConfig(
                  _map(style, 'sliceGroupingConfig'),
                ),
        ),
        'polarColumn' => PolarColumnChartSeries(
          id: document.id,
          name: document.name,
          points: points,
          color: _optionalColor(style['color'], r'$.style.color'),
          metadata: metadata,
          unit: document.unit,
          showInLegend: showInLegend,
          showTrackingAxisLabel: showTrackingAxisLabel,
          preset: _enum(style, 'preset', PolarColumnPreset.values),
          polarStyle: _decodePolarColumnStyle(_map(style, 'polarStyle')),
          selectionStyle: _optionalMap(style, 'selectionStyle') == null
              ? const RadialSelectionStyle()
              : _decodeRadialSelectionStyle(_map(style, 'selectionStyle')),
          targetValues: _decodeOptionalDoubleList(
            style['polarTargetValues'],
            r'$.style.polarTargetValues',
          ),
          targetMarkerStyle: _optionalMap(style, 'polarTargetMarker') == null
              ? const PolarColumnTargetMarkerStyle()
              : _decodePolarColumnTargetMarker(
                  _map(style, 'polarTargetMarker'),
                ),
          intervalLowerValues: _decodeOptionalDoubleList(
            style['polarIntervalLowerValues'],
            r'$.style.polarIntervalLowerValues',
          ),
          intervalUpperValues: _decodeOptionalDoubleList(
            style['polarIntervalUpperValues'],
            r'$.style.polarIntervalUpperValues',
          ),
          intervalStyle: _optionalMap(style, 'polarIntervalStyle') == null
              ? const PolarColumnIntervalStyle()
              : _decodePolarColumnIntervalStyle(
                  _map(style, 'polarIntervalStyle'),
                ),
        ),
        'radialBar' => RadialBarChartSeries(
          id: document.id,
          name: document.name,
          points: points,
          color: _optionalColor(style['color'], r'$.style.color'),
          metadata: metadata,
          unit: document.unit,
          showInLegend: showInLegend,
          showTrackingAxisLabel: showTrackingAxisLabel,
          minimum: _double(style, 'radialBarMinimum'),
          maximum: _double(style, 'radialBarMaximum'),
          baseline: _double(style, 'radialBarBaseline'),
          radialBarStyle: _decodeRadialBarStyle(_map(style, 'radialBarStyle')),
          selectionStyle: _optionalMap(style, 'selectionStyle') == null
              ? const RadialSelectionStyle()
              : _decodeRadialSelectionStyle(_map(style, 'selectionStyle')),
        ),
        'gauge' => _decodeGaugeSeries(
          document: document,
          points: points,
          style: style,
          metadata: metadata,
          showInLegend: showInLegend,
          showTrackingAxisLabel: showTrackingAxisLabel,
        ),
        final type => throw _UnsupportedModelException(
          'Unsupported built-in series type: $type.',
          r'$.type',
        ),
      };

      if (series case final BarChartSeries barSeries) {
        barSeries.validateConfiguration();
      }

      return ChartArtifactSuccess(value: series);
    } on _UnsupportedModelException catch (error) {
      return ChartArtifactFailure(
        error: ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.unsupportedModelType,
          message: error.message,
          path: error.path,
        ),
      );
    } on _NestedCodecException catch (error) {
      return ChartArtifactFailure(error: error.error);
    } on Object catch (error) {
      return ChartArtifactFailure(
        error: ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.invalidArtifact,
          message: 'Invalid built-in series document: $error',
          path: r'$.series',
        ),
      );
    }
  }
}

void _requireRadialFormatterDescriptor({
  required RadialValueFormatter? formatter,
  required JsonObjectValue? descriptor,
  required String path,
  required String label,
}) {
  if (formatter != null && descriptor == null) {
    throw _RuntimeBindingException(
      '$label formatters must be represented by a runtime binding descriptor.',
      path,
    );
  }
}

String _typeOf(ChartSeries series) => switch (series) {
  LineChartSeries() => 'line',
  ScatterChartSeries() => 'scatter',
  AreaChartSeries() => 'area',
  RangeAreaChartSeries() => 'rangeArea',
  BarChartSeries() => 'bar',
  CandlestickChartSeries() => 'candlestick',
  PieChartSeries() => 'pie',
  DonutChartSeries() => 'donut',
  PolarColumnChartSeries() => 'polarColumn',
  RadialBarChartSeries() => 'radialBar',
  GaugeChartSeries() => 'gauge',
  ChartSeries() => 'base',
};

const _candlestickPointExtensionKey = 'candlestick.ohlc.v1';
const _rangeAreaPointExtensionKey = 'rangeArea.interval.v1';

ChartPointDocument _encodePoint(ChartDataPoint point, int index) =>
    ChartPointDocument(
      x: ChartNumberDocument.fromDouble(point.x),
      y: ChartNumberDocument.fromDouble(point.y),
      pointKey: point.pointKey,
      magnitude: point.magnitude == null
          ? null
          : ChartNumberDocument.fromDouble(point.magnitude!),
      colorValue: point.colorValue == null
          ? null
          : ChartNumberDocument.fromDouble(point.colorValue!),
      opacityValue: point.opacityValue == null
          ? null
          : ChartNumberDocument.fromDouble(point.opacityValue!),
      categoryValue: point.categoryValue,
      timestamp: point.timestamp,
      label: point.label,
      metadata: _jsonObjectOrNull(
        point.metadata,
        path: r'$.data.points[' + index.toString() + r'].metadata',
      ),
      segmentStyle: point.segmentStyle == null
          ? null
          : _jsonObject({
              if (point.segmentStyle!.color != null)
                'color': point.segmentStyle!.color!.toARGB32(),
              if (point.segmentStyle!.strokeWidth != null)
                'strokeWidth': _number(point.segmentStyle!.strokeWidth!),
              if (point.segmentStyle!.dashPattern != null)
                'dashPattern': [
                  for (final interval in point.segmentStyle!.dashPattern!)
                    _number(interval),
                ],
            }, path: r'$.data.points[$index].segmentStyle'),
      pointStyle: point.pointStyle == null
          ? null
          : _jsonObject({
              if (point.pointStyle!.color != null)
                'color': point.pointStyle!.color!.toARGB32(),
              if (point.pointStyle!.size != null)
                'size': _number(point.pointStyle!.size!),
              if (point.pointStyle!.scatterMarkerShape != null)
                'scatterMarkerShape':
                    point.pointStyle!.scatterMarkerShape!.name,
              if (point.pointStyle!.scatterMarkerStyle != null)
                'scatterMarkerStyle': _encodeScatterMarkerStyle(
                  point.pointStyle!.scatterMarkerStyle!,
                ),
            }, path: r'$.data.points[$index].pointStyle'),
      extensions: {
        if (point is CandlestickDataPoint)
          _candlestickPointExtensionKey: _jsonObject({
            'open': _number(point.open),
            'high': _number(point.high),
            'low': _number(point.low),
            'close': _number(point.close),
            if (point.candlestickStyle case final style?)
              'style': _encodeCandlestickPointStyle(style),
          }, path: r'$.data.points[$index].extensions.candlestick'),
        if (point is RangeAreaDataPoint)
          _rangeAreaPointExtensionKey: _jsonObject({
            'isGap': point.isGap,
            if (!point.isGap) ...{
              'low': _number(point.low!),
              'high': _number(point.high!),
            },
          }, path: r'$.data.points[$index].extensions.rangeArea'),
      },
    );

ChartDataPoint _decodePoint(ChartPointDocument point) {
  final segmentStyle = _objectMap(point.segmentStyle);
  final pointStyle = _objectMap(point.pointStyle);
  return ChartDataPoint(
    x: point.x.asDouble,
    y: point.y.asDouble,
    pointKey: point.pointKey,
    magnitude: point.magnitude?.asDouble,
    colorValue: point.colorValue?.asDouble,
    opacityValue: point.opacityValue?.asDouble,
    categoryValue: point.categoryValue,
    timestamp: point.timestamp,
    label: point.label,
    metadata: _dynamicMap(point.metadata),
    segmentStyle: point.segmentStyle == null
        ? null
        : SegmentStyle(
            color: _optionalColor(
              segmentStyle['color'],
              r'$.data.point.segmentStyle.color',
            ),
            strokeWidth: _optionalDouble(segmentStyle['strokeWidth']),
            dashPattern: segmentStyle.containsKey('dashPattern')
                ? _decodeDashPattern(segmentStyle['dashPattern'])
                : null,
          ),
    pointStyle: point.pointStyle == null
        ? null
        : PointStyle(
            color: _optionalColor(
              pointStyle['color'],
              r'$.data.point.pointStyle.color',
            ),
            size: _optionalDouble(pointStyle['size']),
            scatterMarkerShape: _optionalEnum(
              pointStyle['scatterMarkerShape'],
              SeriesMarkerShape.values,
              r'$.data.point.pointStyle.scatterMarkerShape',
            ),
            scatterMarkerStyle: _decodeScatterMarkerStyle(
              _optionalMap(pointStyle, 'scatterMarkerStyle'),
            ),
          ),
  );
}

CandlestickDataPoint _decodeCandlestickPoint(ChartPointDocument point) {
  final extension = point.extensions[_candlestickPointExtensionKey];
  if (extension is! JsonObjectValue) {
    throw const FormatException(
      'Candlestick points require a candlestick.ohlc.v1 object extension.',
    );
  }
  final values = extension.values;
  final base = _decodePoint(point);
  final close = _requiredExtensionDouble(values, 'close');
  if (close != base.y) {
    throw const FormatException(
      'Candlestick point close must equal its canonical y value.',
    );
  }
  return CandlestickDataPoint(
    x: base.x,
    pointKey: base.pointKey,
    open: _requiredExtensionDouble(values, 'open'),
    high: _requiredExtensionDouble(values, 'high'),
    low: _requiredExtensionDouble(values, 'low'),
    close: close,
    magnitude: base.magnitude,
    colorValue: base.colorValue,
    opacityValue: base.opacityValue,
    categoryValue: base.categoryValue,
    timestamp: base.timestamp,
    label: base.label,
    metadata: base.metadata,
    segmentStyle: base.segmentStyle,
    pointStyle: base.pointStyle,
    candlestickStyle: _decodeCandlestickPointStyle(
      _optionalMap(_objectMap(extension), 'style'),
    ),
  );
}

RangeAreaDataPoint _decodeRangeAreaPoint(ChartPointDocument point) {
  final extension = point.extensions[_rangeAreaPointExtensionKey];
  if (extension is! JsonObjectValue) {
    throw const FormatException(
      'Range Area points require a rangeArea.interval.v1 object extension.',
    );
  }
  final base = _decodePoint(point);
  final isGapValue = extension.values['isGap']?.toJson();
  if (isGapValue is! bool) {
    throw const FormatException('Range Area point isGap must be boolean.');
  }
  if (isGapValue) {
    if (extension.values.containsKey('low') ||
        extension.values.containsKey('high')) {
      throw const FormatException(
        'Range Area gaps cannot include low or high values.',
      );
    }
    if (base.y != 0) {
      throw const FormatException(
        'Range Area gap canonical y must use the zero placeholder.',
      );
    }
    return RangeAreaDataPoint.gap(
      x: base.x,
      pointKey: base.pointKey,
      timestamp: base.timestamp,
      label: base.label,
      metadata: base.metadata,
    );
  }
  final low = _requiredExtensionDouble(extension.values, 'low');
  final high = _requiredExtensionDouble(extension.values, 'high');
  final midpoint = (low + high) / 2;
  if (base.y != midpoint) {
    throw const FormatException(
      'Range Area point midpoint must equal its canonical y value.',
    );
  }
  return RangeAreaDataPoint(
    x: base.x,
    pointKey: base.pointKey,
    low: low,
    high: high,
    magnitude: base.magnitude,
    colorValue: base.colorValue,
    opacityValue: base.opacityValue,
    categoryValue: base.categoryValue,
    timestamp: base.timestamp,
    label: base.label,
    metadata: base.metadata,
    segmentStyle: base.segmentStyle,
    pointStyle: base.pointStyle,
  );
}

double _requiredExtensionDouble(Map<String, JsonValue> values, String key) {
  final value = values[key]?.toJson();
  if (value is! num) {
    throw FormatException('Point extension $key must be numeric.');
  }
  return value.toDouble();
}

Map<String, Object?> _encodeSeriesStyle(
  ChartSeries series,
  RadialFormatterDocumentDescriptors? radialFormatters,
) {
  if (series case final BarChartSeries barSeries) {
    barSeries.validateRangeConfiguration();
  }
  final result = <String, Object?>{
    if (series.color != null) 'color': series.color!.toARGB32(),
    if (series.style != null) 'seriesStyle': series.style!.name,
    'isXOrdered': series.isXOrdered,
    if (!series.showInLegend) 'showInLegend': false,
    if (!series.showTrackingAxisLabel) 'showTrackingAxisLabel': false,
  };
  switch (series) {
    case LineChartSeries():
      result.addAll(
        _encodeLineStyle(
          interpolation: series.interpolation,
          strokeWidth: series.strokeWidth,
          tension: series.tension,
          showDataPointMarkers: series.showDataPointMarkers,
          dataPointMarkerRadius: series.dataPointMarkerRadius,
          dataPointMarkerStyle: series.dataPointMarkerStyle,
          dataPointMarkerBackground: series.dataPointMarkerBackground,
          lineGlow: series.lineGlow,
          dataPointLabels: series.dataPointLabels,
          inlineLabel: series.inlineLabel,
          dashPattern: series.dashPattern,
        ),
      );
      result['pathAnimation'] = _encodePathAnimation(series.pathAnimation);
    case ScatterChartSeries():
      result
        ..['markerRadius'] = _number(series.markerRadius)
        ..['markerShape'] = series.markerShape.name;
      if (series.markerStyle != null) {
        result['markerStyle'] = _encodeScatterMarkerStyle(series.markerStyle!);
      }
      if (series.sizeEncoding != null) {
        result['sizeEncoding'] = _encodeScatterSizeEncoding(
          series.sizeEncoding!,
        );
      }
      if (series.colorEncoding != null) {
        result['colorEncoding'] = _encodeScatterColorEncoding(
          series.colorEncoding!,
        );
      }
      if (series.opacityEncoding != null) {
        result['opacityEncoding'] = _encodeScatterOpacityEncoding(
          series.opacityEncoding!,
        );
      }
      if (series.categoryEncoding != null) {
        if (!series.categoryEncoding!.hasValidConfiguration) {
          throw const FormatException(
            'Scatter category encodings require unique non-empty keys and at least one color or shape per category.',
          );
        }
        result['categoryEncoding'] = _encodeScatterCategoryEncoding(
          series.categoryEncoding!,
        );
      }
      if (series.jitter != const ScatterJitterConfig()) {
        result['jitter'] = _encodeScatterJitter(series.jitter);
      }
      if (series.renderMode != ScatterRenderMode.points) {
        result['renderMode'] = series.renderMode.name;
      }
      if (series.clusterConfig != const ScatterClusterConfig()) {
        result['clusterConfig'] = _encodeScatterClusterConfig(
          series.clusterConfig,
        );
      }
      if (series.binConfig != const ScatterBinConfig()) {
        result['binConfig'] = _encodeScatterBinConfig(series.binConfig);
      }
      if (series.densityConfig != const ScatterDensityConfig()) {
        result['densityConfig'] = _encodeScatterDensityConfig(
          series.densityConfig,
        );
      }
      if (series.dataPointLabels != null) {
        result['dataPointLabels'] = _encodeDataPointLabels(
          series.dataPointLabels!,
        );
      }
      if (series.interactionStyle != const ScatterInteractionStyle()) {
        result['interaction'] = _encodeScatterInteraction(
          series.interactionStyle,
        );
      }
    case AreaChartSeries():
      result
        ..addAll(
          _encodeLineStyle(
            interpolation: series.interpolation,
            strokeWidth: series.strokeWidth,
            tension: series.tension,
            showDataPointMarkers: series.showDataPointMarkers,
            dataPointMarkerRadius: series.dataPointMarkerRadius,
            dataPointMarkerStyle: series.dataPointMarkerStyle,
            dataPointMarkerBackground: series.dataPointMarkerBackground,
            lineGlow: series.lineGlow,
            dataPointLabels: series.dataPointLabels,
            inlineLabel: series.inlineLabel,
            dashPattern: series.dashPattern,
          ),
        )
        ..['fillOpacity'] = _number(series.fillOpacity)
        ..['fillGradient'] = series.fillGradient == null
            ? null
            : _encodeAreaGradient(series.fillGradient!)
        ..['baselineValue'] = series.baselineValue == null
            ? null
            : _number(series.baselineValue!)
        ..['aboveBaselineFillColor'] = series.aboveBaselineFillColor?.toARGB32()
        ..['belowBaselineFillColor'] = series.belowBaselineFillColor?.toARGB32()
        ..['pathAnimation'] = _encodePathAnimation(series.pathAnimation);
    case RangeAreaChartSeries():
      result
        ..['interpolation'] = series.interpolation.name
        ..['tension'] = _number(series.tension)
        ..['fillOpacity'] = _number(series.fillOpacity)
        ..['fillGradient'] = series.fillGradient == null
            ? null
            : _encodeAreaGradient(series.fillGradient!)
        ..['borderMode'] = series.borderMode.name
        ..['upperBoundaryStyle'] = _encodeRangeAreaBoundaryStyle(
          series.upperBoundaryStyle,
        )
        ..['lowerBoundaryStyle'] = _encodeRangeAreaBoundaryStyle(
          series.lowerBoundaryStyle,
        )
        ..['connectGaps'] = series.connectGaps
        ..['showBoundaryMarkers'] = series.showBoundaryMarkers
        ..['markerRadius'] = _number(series.markerRadius)
        ..['labelConfig'] = _encodeRangeAreaLabelConfig(series.labelConfig)
        ..['hitTestMode'] = series.hitTestMode.name
        ..['pathAnimation'] = _encodePathAnimation(series.pathAnimation);
    case BarChartSeries():
      result
        ..['barWidthPercent'] = series.barWidthPercent == null
            ? null
            : _number(series.barWidthPercent!)
        ..['barWidthPixels'] = series.barWidthPixels == null
            ? null
            : _number(series.barWidthPixels!)
        ..['minWidth'] = _number(series.minWidth)
        ..['maxWidth'] = _number(series.maxWidth)
        ..['barGap'] = _number(series.barGap)
        ..['barOrientation'] = series.orientation.name
        ..['barLayoutMode'] = series.layoutMode.name
        ..['barGroupId'] = series.groupId
        ..['barDivergingRole'] =
            series.layoutMode == BarLayoutMode.divergingStacked
            ? series.divergingRole.name
            : null
        ..['barDivergingStyle'] =
            series.layoutMode == BarLayoutMode.divergingStacked
            ? _encodeBarDivergingStyle(series.divergingStyle)
            : null
        ..['barOverlayWidthFactor'] = _number(series.overlayWidthFactor)
        ..['barOverlayOffsetFactor'] = _number(series.overlayOffsetFactor)
        ..['baselineValue'] = _number(series.baselineValue)
        ..['barRangeStartValues'] = series.rangeStartValues.isEmpty
            ? null
            : [
                for (final value in series.rangeStartValues)
                  value == null ? null : _number(value),
              ]
        ..['barWaterfallTotalIndices'] = series.waterfallTotalIndices.isEmpty
            ? null
            : (series.waterfallTotalIndices.toList()..sort())
        ..['barWaterfallStyle'] = series.layoutMode == BarLayoutMode.waterfall
            ? _encodeBarWaterfallStyle(series.waterfallStyle)
            : null
        ..['minBarLength'] = _number(series.minBarLength)
        ..['barStyle'] = _encodeBarStyle(series.barStyle)
        ..['barTrack'] = series.trackStyle == null
            ? null
            : _encodeBarTrack(series.trackStyle!)
        ..['barLollipop'] = series.lollipopStyle == null
            ? null
            : _encodeBarLollipop(series.lollipopStyle!)
        ..['barBullet'] = series.bulletStyle == null
            ? null
            : _encodeBarBullet(series.bulletStyle!)
        ..['barTargetValues'] = series.targetValues.isEmpty
            ? null
            : [
                for (final value in series.targetValues)
                  value == null ? null : _number(value),
              ]
        ..['barTargetMarker'] = series.targetValues.isEmpty
            ? null
            : _encodeBarTargetMarker(series.targetMarkerStyle)
        ..['barErrorLowerValues'] = series.errorLowerValues.isEmpty
            ? null
            : [
                for (final value in series.errorLowerValues)
                  value == null ? null : _number(value),
              ]
        ..['barErrorUpperValues'] = series.errorUpperValues.isEmpty
            ? null
            : [
                for (final value in series.errorUpperValues)
                  value == null ? null : _number(value),
              ]
        ..['barErrorBar'] = series.errorLowerValues.isEmpty
            ? null
            : _encodeBarErrorBar(series.errorBarStyle)
        ..['barLabels'] = _encodeBarLabels(series.labelStyle);
    case CandlestickChartSeries():
      result
        ..['candlestickStyle'] = _encodeCandlestickStyle(
          series.candlestickStyle,
        )
        ..['candlestickAnimation'] = _encodeCandlestickAnimation(
          series.animation,
        )
        ..['candlestickDensityGrouping'] = _encodeCandlestickDensityGrouping(
          series.densityGrouping,
        );
    case PieChartSeries():
      result
        ..['pieStyle'] = _encodePieStyle(series.pieStyle)
        ..['selectionStyle'] = _encodeRadialSelectionStyle(
          series.selectionStyle,
        )
        ..['dataLabels'] = _encodePieDataLabels(
          series.dataLabels,
          valueFormatter: radialFormatters?.value,
          percentageFormatter: radialFormatters?.percentage,
        );
      if (series.sliceRadiusConfig case final radiusConfig?) {
        result['sliceRadiusConfig'] = _encodePieSliceRadiusConfig(
          radiusConfig,
          formatter: radialFormatters?.radius,
        );
      }
      if (series.sliceGroupingConfig case final groupingConfig?) {
        result['sliceGroupingConfig'] = _encodeRadialSliceGroupingConfig(
          groupingConfig,
        );
      }
    case DonutChartSeries():
      result
        ..['donutStyle'] = _encodeDonutStyle(series.donutStyle)
        ..['selectionStyle'] = _encodeRadialSelectionStyle(
          series.selectionStyle,
        )
        ..['centerContent'] = DonutCenterContentDocumentCodec.encode(
          series.centerContent,
          valueFormatter: radialFormatters?.center,
        )
        ..['dataLabels'] = _encodePieDataLabels(
          series.dataLabels,
          valueFormatter: radialFormatters?.value,
          percentageFormatter: radialFormatters?.percentage,
        );
      if (series.sliceRadiusConfig case final radiusConfig?) {
        result['sliceRadiusConfig'] = _encodePieSliceRadiusConfig(
          radiusConfig,
          formatter: radialFormatters?.radius,
        );
      }
      if (series.sliceGroupingConfig case final groupingConfig?) {
        result['sliceGroupingConfig'] = _encodeRadialSliceGroupingConfig(
          groupingConfig,
        );
      }
    case PolarColumnChartSeries():
      result
        ..['preset'] = series.preset.name
        ..['polarStyle'] = _encodePolarColumnStyle(series.polarStyle)
        ..['selectionStyle'] = _encodeRadialSelectionStyle(
          series.selectionStyle,
        )
        ..['polarTargetValues'] = series.targetValues.isEmpty
            ? null
            : [
                for (final value in series.targetValues)
                  value == null ? null : _number(value),
              ]
        ..['polarTargetMarker'] = series.targetValues.isEmpty
            ? null
            : _encodePolarColumnTargetMarker(series.targetMarkerStyle)
        ..['polarIntervalLowerValues'] = series.intervalLowerValues.isEmpty
            ? null
            : [
                for (final value in series.intervalLowerValues)
                  value == null ? null : _number(value),
              ]
        ..['polarIntervalUpperValues'] = series.intervalUpperValues.isEmpty
            ? null
            : [
                for (final value in series.intervalUpperValues)
                  value == null ? null : _number(value),
              ]
        ..['polarIntervalStyle'] = series.hasIntervals
            ? _encodePolarColumnIntervalStyle(series.intervalStyle)
            : null;
    case RadialBarChartSeries():
      result
        ..['radialBarMinimum'] = _number(series.minimum)
        ..['radialBarMaximum'] = _number(series.maximum)
        ..['radialBarBaseline'] = _number(series.baseline)
        ..['radialBarStyle'] = _encodeRadialBarStyle(series.radialBarStyle)
        ..['selectionStyle'] = _encodeRadialSelectionStyle(
          series.selectionStyle,
        );
    case GaugeChartSeries():
      result
        ..['gaugeMetric'] = series.metric
        ..['gaugeMinimum'] = _number(series.minimum)
        ..['gaugeMaximum'] = _number(series.maximum)
        ..['gaugeTarget'] = series.target == null
            ? null
            : _encodeGaugeTarget(series.target!)
        ..['gaugeZones'] = [
          for (final zone in series.zones) _encodeGaugeZone(zone),
        ]
        ..['gaugeThresholds'] = [
          for (final threshold in series.thresholds)
            _encodeGaugeThreshold(threshold),
        ]
        ..['gaugeIndicatorStyle'] = _encodeGaugeIndicatorStyle(
          series.indicatorStyle,
        );
    case ChartSeries():
      break;
  }
  result.removeWhere((_, value) => value == null);
  return result;
}

Map<String, Object?> _encodeCandlestickPointStyle(
  CandlestickPointStyle style,
) => {
  if (style.bodyFillColor != null)
    'bodyFillColor': style.bodyFillColor!.toARGB32(),
  if (style.borderColor != null) 'borderColor': style.borderColor!.toARGB32(),
  if (style.wickColor != null) 'wickColor': style.wickColor!.toARGB32(),
};

CandlestickPointStyle? _decodeCandlestickPointStyle(
  Map<String, Object?>? value,
) => value == null
    ? null
    : CandlestickPointStyle(
        bodyFillColor: _optionalColor(
          value['bodyFillColor'],
          r'$.data.point.extensions.candlestick.style.bodyFillColor',
        ),
        borderColor: _optionalColor(
          value['borderColor'],
          r'$.data.point.extensions.candlestick.style.borderColor',
        ),
        wickColor: _optionalColor(
          value['wickColor'],
          r'$.data.point.extensions.candlestick.style.wickColor',
        ),
      );

Map<String, Object?> _encodeCandlestickStyle(CandlestickChartStyle style) => {
  if (style.risingBodyFillColor != null)
    'risingBodyFillColor': style.risingBodyFillColor!.toARGB32(),
  if (style.fallingBodyFillColor != null)
    'fallingBodyFillColor': style.fallingBodyFillColor!.toARGB32(),
  if (style.dojiBodyFillColor != null)
    'dojiBodyFillColor': style.dojiBodyFillColor!.toARGB32(),
  if (style.risingBorderColor != null)
    'risingBorderColor': style.risingBorderColor!.toARGB32(),
  if (style.fallingBorderColor != null)
    'fallingBorderColor': style.fallingBorderColor!.toARGB32(),
  if (style.dojiBorderColor != null)
    'dojiBorderColor': style.dojiBorderColor!.toARGB32(),
  if (style.risingWickColor != null)
    'risingWickColor': style.risingWickColor!.toARGB32(),
  if (style.fallingWickColor != null)
    'fallingWickColor': style.fallingWickColor!.toARGB32(),
  if (style.dojiWickColor != null)
    'dojiWickColor': style.dojiWickColor!.toARGB32(),
  'bodyFillMode': style.bodyFillMode.name,
  'bodyWidthFactor': _number(style.bodyWidthFactor),
  'minBodyWidth': _number(style.minBodyWidth),
  'maxBodyWidth': _number(style.maxBodyWidth),
  'bodyBorderWidth': _number(style.bodyBorderWidth),
  'wickWidth': _number(style.wickWidth),
  'showBodyBorder': style.showBodyBorder,
  'showWicks': style.showWicks,
  'bodyCornerRadius': _number(style.bodyCornerRadius),
  'minimumBodyHeight': _number(style.minimumBodyHeight),
};

CandlestickChartStyle _decodeCandlestickStyle(Map<String, Object?>? value) {
  if (value == null) return const CandlestickChartStyle();
  return CandlestickChartStyle(
    risingBodyFillColor: _optionalColor(
      value['risingBodyFillColor'],
      r'$.style.candlestickStyle.risingBodyFillColor',
    ),
    fallingBodyFillColor: _optionalColor(
      value['fallingBodyFillColor'],
      r'$.style.candlestickStyle.fallingBodyFillColor',
    ),
    dojiBodyFillColor: _optionalColor(
      value['dojiBodyFillColor'],
      r'$.style.candlestickStyle.dojiBodyFillColor',
    ),
    risingBorderColor: _optionalColor(
      value['risingBorderColor'],
      r'$.style.candlestickStyle.risingBorderColor',
    ),
    fallingBorderColor: _optionalColor(
      value['fallingBorderColor'],
      r'$.style.candlestickStyle.fallingBorderColor',
    ),
    dojiBorderColor: _optionalColor(
      value['dojiBorderColor'],
      r'$.style.candlestickStyle.dojiBorderColor',
    ),
    risingWickColor: _optionalColor(
      value['risingWickColor'],
      r'$.style.candlestickStyle.risingWickColor',
    ),
    fallingWickColor: _optionalColor(
      value['fallingWickColor'],
      r'$.style.candlestickStyle.fallingWickColor',
    ),
    dojiWickColor: _optionalColor(
      value['dojiWickColor'],
      r'$.style.candlestickStyle.dojiWickColor',
    ),
    bodyFillMode:
        _optionalEnum(
          value['bodyFillMode'],
          CandlestickBodyFillMode.values,
          r'$.style.candlestickStyle.bodyFillMode',
        ) ??
        CandlestickBodyFillMode.hollowRising,
    bodyWidthFactor: _optionalDouble(value['bodyWidthFactor']) ?? .7,
    minBodyWidth: _optionalDouble(value['minBodyWidth']) ?? 1,
    maxBodyWidth: _optionalDouble(value['maxBodyWidth']) ?? 18,
    bodyBorderWidth: _optionalDouble(value['bodyBorderWidth']) ?? 1,
    wickWidth: _optionalDouble(value['wickWidth']) ?? 1,
    showBodyBorder: _optionalBool(value['showBodyBorder']) ?? true,
    showWicks: _optionalBool(value['showWicks']) ?? true,
    bodyCornerRadius: _optionalDouble(value['bodyCornerRadius']) ?? 0,
    minimumBodyHeight: _optionalDouble(value['minimumBodyHeight']) ?? 1,
  );
}

Map<String, Object?> _encodeCandlestickAnimation(
  CandlestickAnimationStyle animation,
) => {
  'mode': animation.mode.name,
  'staggerFraction': _number(animation.staggerFraction),
  'dataUpdateMode': animation.dataUpdateMode.name,
};

CandlestickAnimationStyle _decodeCandlestickAnimation(
  Map<String, Object?>? value,
) {
  if (value == null) return const CandlestickAnimationStyle();
  return CandlestickAnimationStyle(
    mode:
        _optionalEnum(
          value['mode'],
          CandlestickAnimationMode.values,
          r'$.style.candlestickAnimation.mode',
        ) ??
        CandlestickAnimationMode.reveal,
    staggerFraction: _optionalDouble(value['staggerFraction']) ?? 0,
    dataUpdateMode:
        _optionalEnum(
          value['dataUpdateMode'],
          CandlestickDataUpdateAnimationMode.values,
          r'$.style.candlestickAnimation.dataUpdateMode',
        ) ??
        CandlestickDataUpdateAnimationMode.interpolate,
  );
}

Map<String, Object?> _encodeCandlestickDensityGrouping(
  CandlestickDensityGrouping grouping,
) => {
  'enabled': grouping.enabled,
  'targetGroupWidth': _number(grouping.targetGroupWidth),
  'minimumPointsPerGroup': grouping.minimumPointsPerGroup,
};

CandlestickDensityGrouping _decodeCandlestickDensityGrouping(
  Map<String, Object?>? value,
) {
  if (value == null) return const CandlestickDensityGrouping();
  return CandlestickDensityGrouping(
    enabled: _optionalBool(value['enabled']) ?? false,
    targetGroupWidth: _optionalDouble(value['targetGroupWidth']) ?? 5,
    minimumPointsPerGroup: _optionalInt(value['minimumPointsPerGroup']) ?? 2,
  );
}

PathAnimationStyle? _pathAnimationFor(ChartSeries series) => switch (series) {
  LineChartSeries() => series.pathAnimation,
  AreaChartSeries() => series.pathAnimation,
  RangeAreaChartSeries() => series.pathAnimation,
  _ => null,
};

List<double> _dashPatternFor(ChartSeries series) => switch (series) {
  LineChartSeries() => series.dashPattern,
  AreaChartSeries() => series.dashPattern,
  RangeAreaChartSeries() => [
    ...series.upperBoundaryStyle.dashPattern,
    ...series.lowerBoundaryStyle.dashPattern,
  ],
  _ => const [],
};

bool _hasPathDashCapability(ChartSeries series) =>
    _dashPatternFor(series).isNotEmpty ||
    series.points.any((point) => point.segmentStyle?.dashPattern != null);

Map<String, Object?> _encodePathAnimation(PathAnimationStyle style) => {
  'entranceMode': style.entranceMode.name,
  'dataUpdateMode': style.dataUpdateMode.name,
  if (style.entranceTiming != const PathAnimationTiming())
    'entranceTiming': _encodePathAnimationTiming(style.entranceTiming),
  if (style.dataUpdateTiming != const PathAnimationTiming())
    'dataUpdateTiming': _encodePathAnimationTiming(style.dataUpdateTiming),
};

bool _hasNonDefaultPathTiming(PathAnimationStyle style) =>
    style.entranceTiming != const PathAnimationTiming() ||
    style.dataUpdateTiming != const PathAnimationTiming();

Map<String, Object?> _encodeAreaGradient(AreaGradient gradient) => {
  'colors': [for (final color in gradient.colors) color.toARGB32()],
  if (gradient.stops != null)
    'stops': [for (final stop in gradient.stops!) _number(stop)],
  'begin': {'x': _number(gradient.begin.x), 'y': _number(gradient.begin.y)},
  'end': {'x': _number(gradient.end.x), 'y': _number(gradient.end.y)},
};

Map<String, Object?> _encodeRangeAreaBoundaryStyle(
  RangeAreaBoundaryStyle style,
) => {
  'visible': style.visible,
  if (style.color != null) 'color': style.color!.toARGB32(),
  'strokeWidth': _number(style.strokeWidth),
  'dashPattern': [for (final interval in style.dashPattern) _number(interval)],
  'glowRadius': _number(style.glowRadius),
};

RangeAreaBoundaryStyle _decodeRangeAreaBoundaryStyle(
  Map<String, Object?>? value,
) {
  if (value == null) return const RangeAreaBoundaryStyle();
  return RangeAreaBoundaryStyle(
    visible: _optionalBool(value['visible']) ?? true,
    color: _optionalColor(value['color'], r'$.style.boundary.color'),
    strokeWidth: _optionalDouble(value['strokeWidth']) ?? 1.5,
    dashPattern: value['dashPattern'] == null
        ? const []
        : _decodeDashPattern(value['dashPattern']),
    glowRadius: _optionalDouble(value['glowRadius']) ?? 0,
  );
}

Map<String, Object?> _encodeRangeAreaLabelConfig(RangeAreaLabelConfig config) =>
    {
      'value': config.value.name,
      'labels': _encodeDataPointLabels(config.labels),
      'boundaryGap': _number(config.boundaryGap),
    };

RangeAreaLabelConfig _decodeRangeAreaLabelConfig(Map<String, Object?>? value) {
  if (value == null) return const RangeAreaLabelConfig();
  return RangeAreaLabelConfig(
    value:
        _optionalEnum(
          value['value'],
          RangeAreaLabelValue.values,
          r'$.style.labelConfig.value',
        ) ??
        RangeAreaLabelValue.none,
    labels:
        _decodeDataPointLabels(_optionalMap(value, 'labels')) ??
        const DataPointLabelConfig(),
    boundaryGap: _optionalDouble(value['boundaryGap']) ?? 4,
  );
}

AreaGradient? _decodeAreaGradient(Map<String, Object?>? value) {
  if (value == null) return null;
  final colorsValue = value['colors'];
  if (colorsValue is! List) {
    throw const FormatException('Expected Area gradient colors list.');
  }
  final colors = [
    for (var index = 0; index < colorsValue.length; index++)
      _optionalColor(colorsValue[index], r'$.style.fillGradient.colors') ??
          (throw const FormatException('Expected Area gradient color.')),
  ];
  if (colors.length < 2) {
    throw const FormatException(
      'An Area gradient requires at least two colors.',
    );
  }

  final stopsValue = value['stops'];
  final stops = stopsValue == null
      ? null
      : stopsValue is List
      ? [
          for (final stop in stopsValue)
            _optionalDouble(stop) ??
                (throw const FormatException(
                  'Expected numeric Area gradient stop.',
                )),
        ]
      : throw const FormatException('Expected Area gradient stops list.');
  if (stops != null && stops.length != colors.length) {
    throw const FormatException(
      'Area gradient stops must match the number of colors.',
    );
  }
  if (stops != null) {
    for (var index = 0; index < stops.length; index++) {
      final stop = stops[index];
      if (stop < 0 || stop > 1 || (index > 0 && stop < stops[index - 1])) {
        throw const FormatException(
          'Area gradient stops must be ordered between 0 and 1.',
        );
      }
    }
  }

  return AreaGradient(
    colors: colors,
    stops: stops,
    begin: _decodeAreaGradientAlignment(
      _optionalMap(value, 'begin'),
      fallback: Alignment.topCenter,
    ),
    end: _decodeAreaGradientAlignment(
      _optionalMap(value, 'end'),
      fallback: Alignment.bottomCenter,
    ),
  );
}

Alignment _decodeAreaGradientAlignment(
  Map<String, Object?>? value, {
  required Alignment fallback,
}) {
  if (value == null) return fallback;
  final x = _optionalDouble(value['x']);
  final y = _optionalDouble(value['y']);
  if (x == null || y == null) {
    throw const FormatException(
      'Area gradient alignment requires numeric x and y values.',
    );
  }
  return Alignment(x, y);
}

Map<String, Object?> _encodePathAnimationTiming(PathAnimationTiming timing) => {
  if (timing.delay != Duration.zero) 'delayMicros': timing.delay.inMicroseconds,
  if (timing.duration case final duration?)
    'durationMicros': duration.inMicroseconds,
};

PathAnimationStyle _decodePathAnimation(Map<String, Object?>? value) {
  if (value == null) return const PathAnimationStyle();
  return PathAnimationStyle(
    entranceMode:
        _optionalEnum(
          value['entranceMode'],
          PathEntranceAnimationMode.values,
          r'$.style.pathAnimation.entranceMode',
        ) ??
        PathEntranceAnimationMode.none,
    dataUpdateMode:
        _optionalEnum(
          value['dataUpdateMode'],
          PathDataUpdateAnimationMode.values,
          r'$.style.pathAnimation.dataUpdateMode',
        ) ??
        PathDataUpdateAnimationMode.none,
    entranceTiming: _decodePathAnimationTiming(
      _optionalMap(value, 'entranceTiming'),
      r'$.style.pathAnimation.entranceTiming',
    ),
    dataUpdateTiming: _decodePathAnimationTiming(
      _optionalMap(value, 'dataUpdateTiming'),
      r'$.style.pathAnimation.dataUpdateTiming',
    ),
  );
}

PathAnimationTiming _decodePathAnimationTiming(
  Map<String, Object?>? value,
  String path,
) {
  if (value == null) return const PathAnimationTiming();
  final delayMicros = _optionalInt(value['delayMicros']) ?? 0;
  final durationMicros = _optionalInt(value['durationMicros']);
  if (delayMicros < 0) {
    throw FormatException(
      'Expected non-negative integer at $path.delayMicros.',
    );
  }
  if (durationMicros != null && durationMicros < 0) {
    throw FormatException(
      'Expected non-negative integer at $path.durationMicros.',
    );
  }
  return PathAnimationTiming(
    delay: Duration(microseconds: delayMicros),
    duration: durationMicros == null
        ? null
        : Duration(microseconds: durationMicros),
  );
}

Map<String, Object?> _encodeBarStyle(BarChartStyle style) => {
  'cornerRadius': _number(style.cornerRadius),
  'cornerRadiusPolicy': style.cornerRadiusPolicy.name,
  'opacity': _number(style.opacity),
  if (style.gradient != null)
    'gradient': {
      'colors': [for (final color in style.gradient!.colors) color.toARGB32()],
      if (style.gradient!.stops != null)
        'stops': [for (final stop in style.gradient!.stops!) _number(stop)],
    },
  if (style.pattern != null)
    'pattern': {
      'type': style.pattern!.pattern.name,
      if (style.pattern!.color != null)
        'color': style.pattern!.color!.toARGB32(),
      'spacing': _number(style.pattern!.spacing),
      'strokeWidth': _number(style.pattern!.strokeWidth),
      'opacity': _number(style.pattern!.opacity),
    },
  if (style.border != null) 'border': _encodeBarBorder(style.border!),
  'interaction': _encodeBarInteraction(style.interaction),
  'animationMode': style.animationMode.name,
  'motion': {
    'order': style.motion.order.name,
    'staggerFraction': _number(style.motion.staggerFraction),
  },
};

BarChartStyle _decodeBarStyle(Map<String, Object?>? value) {
  if (value == null) return const BarChartStyle();
  return BarChartStyle(
    cornerRadius: _optionalDouble(value['cornerRadius']) ?? 0.0,
    cornerRadiusPolicy:
        _optionalEnum(
          value['cornerRadiusPolicy'],
          BarCornerRadiusPolicy.values,
          r'$.style.barStyle.cornerRadiusPolicy',
        ) ??
        BarCornerRadiusPolicy.valueEnd,
    opacity: _optionalDouble(value['opacity']) ?? 1.0,
    gradient: _decodeBarGradient(_optionalMap(value, 'gradient')),
    pattern: _decodeBarPattern(_optionalMap(value, 'pattern')),
    border: _decodeBarBorder(_optionalMap(value, 'border')),
    interaction: _decodeBarInteraction(_optionalMap(value, 'interaction')),
    animationMode:
        _optionalEnum(
          value['animationMode'],
          BarAnimationMode.values,
          r'$.style.barStyle.animationMode',
        ) ??
        BarAnimationMode.grow,
    motion: _decodeBarMotion(_optionalMap(value, 'motion')),
  );
}

BarPatternStyle? _decodeBarPattern(Map<String, Object?>? value) {
  if (value == null) return null;
  final spacing = _optionalDouble(value['spacing']) ?? 8.0;
  final strokeWidth = _optionalDouble(value['strokeWidth']) ?? 1.5;
  final opacity = _optionalDouble(value['opacity']) ?? 0.55;
  if (spacing <= 0 || strokeWidth <= 0 || opacity < 0 || opacity > 1) {
    throw const FormatException(
      'Bar pattern spacing and strokeWidth must be positive and opacity must be between 0 and 1.',
    );
  }
  return BarPatternStyle(
    pattern:
        _optionalEnum(
          value['type'],
          BarFillPattern.values,
          r'$.style.barStyle.pattern.type',
        ) ??
        BarFillPattern.diagonalUp,
    color: _optionalColor(value['color'], r'$.style.barStyle.pattern.color'),
    spacing: spacing,
    strokeWidth: strokeWidth,
    opacity: opacity,
  );
}

BarMotionStyle _decodeBarMotion(Map<String, Object?>? value) {
  if (value == null) return const BarMotionStyle();
  final stagger = _optionalDouble(value['staggerFraction']) ?? 0.0;
  if (stagger < 0 || stagger >= 1) {
    throw const FormatException(
      'Bar motion staggerFraction must be at least 0 and less than 1.',
    );
  }
  return BarMotionStyle(
    order:
        _optionalEnum(
          value['order'],
          BarAnimationOrder.values,
          r'$.style.barStyle.motion.order',
        ) ??
        BarAnimationOrder.together,
    staggerFraction: stagger,
  );
}

Map<String, Object?> _encodeScatterMarkerStyle(ScatterMarkerStyle style) => {
  if (style.fillColor != null) 'fillColor': style.fillColor!.toARGB32(),
  if (style.strokeColor != null) 'strokeColor': style.strokeColor!.toARGB32(),
  if (style.strokeWidth != null) 'strokeWidth': _number(style.strokeWidth!),
  if (style.opacity != null) 'opacity': _number(style.opacity!),
  if (style.width != null) 'width': _number(style.width!),
  if (style.height != null) 'height': _number(style.height!),
  if (style.rotationDegrees != null)
    'rotationDegrees': _number(style.rotationDegrees!),
};

ScatterMarkerStyle? _decodeScatterMarkerStyle(Map<String, Object?>? value) {
  if (value == null) return null;
  final strokeWidth = _optionalDouble(value['strokeWidth']);
  final opacity = _optionalDouble(value['opacity']);
  final width = _optionalDouble(value['width']);
  final height = _optionalDouble(value['height']);
  final rotationDegrees = _optionalDouble(value['rotationDegrees']);
  if ((strokeWidth != null && (!strokeWidth.isFinite || strokeWidth < 0)) ||
      (opacity != null && (!opacity.isFinite || opacity < 0 || opacity > 1)) ||
      (width != null && (!width.isFinite || width < 0)) ||
      (height != null && (!height.isFinite || height < 0)) ||
      (rotationDegrees != null && !rotationDegrees.isFinite)) {
    throw const FormatException(
      'Scatter marker dimensions and stroke must be non-negative, opacity must be between 0 and 1, and rotation must be finite.',
    );
  }
  return ScatterMarkerStyle(
    fillColor: _optionalColor(
      value['fillColor'],
      r'$.style.markerStyle.fillColor',
    ),
    strokeColor: _optionalColor(
      value['strokeColor'],
      r'$.style.markerStyle.strokeColor',
    ),
    strokeWidth: strokeWidth,
    opacity: opacity,
    width: width,
    height: height,
    rotationDegrees: rotationDegrees,
  );
}

Map<String, Object?> _encodeScatterSizeEncoding(ScatterSizeEncoding encoding) =>
    {
      'minimumRadius': _number(encoding.minimumRadius),
      'maximumRadius': _number(encoding.maximumRadius),
      'minimumValue': _number(encoding.minimumValue),
      if (encoding.maximumValue != null)
        'maximumValue': _number(encoding.maximumValue!),
      'label': encoding.label,
      if (encoding.unit != null) 'unit': encoding.unit,
      'showLegend': encoding.showLegend,
    };

ScatterSizeEncoding? _decodeScatterSizeEncoding(Map<String, Object?>? value) {
  if (value == null) return null;
  final minimumRadius = _optionalDouble(value['minimumRadius']) ?? 4;
  final maximumRadius = _optionalDouble(value['maximumRadius']) ?? 24;
  final minimumValue = _optionalDouble(value['minimumValue']) ?? 0;
  final maximumValue = _optionalDouble(value['maximumValue']);
  if (!minimumRadius.isFinite ||
      minimumRadius < 0 ||
      !maximumRadius.isFinite ||
      maximumRadius < minimumRadius ||
      !minimumValue.isFinite ||
      minimumValue < 0 ||
      (maximumValue != null &&
          (!maximumValue.isFinite || maximumValue < minimumValue))) {
    throw const FormatException(
      'Scatter size encoding radii and domain must be finite, non-negative, and ordered.',
    );
  }
  final label = value['label'];
  final unit = value['unit'];
  final showLegend = value['showLegend'];
  if (label != null && label is! String ||
      unit != null && unit is! String ||
      showLegend != null && showLegend is! bool) {
    throw const FormatException(
      'Scatter size encoding label and unit must be strings and showLegend must be a boolean.',
    );
  }
  return ScatterSizeEncoding(
    minimumRadius: minimumRadius,
    maximumRadius: maximumRadius,
    minimumValue: minimumValue,
    maximumValue: maximumValue,
    label: label as String? ?? 'Magnitude',
    unit: unit as String?,
    showLegend: showLegend as bool? ?? true,
  );
}

Map<String, Object?> _encodeScatterColorEncoding(
  ScatterColorEncoding encoding,
) => {
  'colors': [for (final color in encoding.colors) color.toARGB32()],
  'scaleType': encoding.scaleType.name,
  if (encoding.thresholds.isNotEmpty)
    'thresholds': [
      for (final threshold in encoding.thresholds) _number(threshold),
    ],
  if (encoding.bandLabels.isNotEmpty) 'bandLabels': encoding.bandLabels,
  if (encoding.minimumValue != null)
    'minimumValue': _number(encoding.minimumValue!),
  if (encoding.maximumValue != null)
    'maximumValue': _number(encoding.maximumValue!),
  'label': encoding.label,
  if (encoding.unit != null) 'unit': encoding.unit,
  'showLegend': encoding.showLegend,
};

ScatterColorEncoding? _decodeScatterColorEncoding(Map<String, Object?>? value) {
  if (value == null) return null;
  final rawColors = value['colors'];
  if (rawColors is! List || rawColors.length < 2) {
    throw const FormatException(
      'Scatter color encoding requires at least two colors.',
    );
  }
  final colors = <Color>[];
  for (var index = 0; index < rawColors.length; index++) {
    final color = _optionalColor(
      rawColors[index],
      r'$.style.colorEncoding.colors['
      '${index.toString()}]',
    );
    if (color == null) {
      throw FormatException(
        r'$.style.colorEncoding.colors['
        '${index.toString()}] must be a color.',
      );
    }
    colors.add(color);
  }
  final minimumValue = _optionalDouble(value['minimumValue']);
  final maximumValue = _optionalDouble(value['maximumValue']);
  if ((minimumValue != null && !minimumValue.isFinite) ||
      (maximumValue != null && !maximumValue.isFinite) ||
      (minimumValue != null &&
          maximumValue != null &&
          maximumValue < minimumValue)) {
    throw const FormatException(
      'Scatter color encoding domain must be finite and ordered.',
    );
  }
  final label = value['label'];
  final unit = value['unit'];
  final showLegend = value['showLegend'];
  final rawScaleType = value['scaleType'];
  final scaleType = switch (rawScaleType) {
    null || 'continuous' => ScatterColorScaleType.continuous,
    'piecewise' => ScatterColorScaleType.piecewise,
    _ => throw const FormatException(
      'Scatter color encoding scaleType must be continuous or piecewise.',
    ),
  };
  final rawThresholds = value['thresholds'];
  final thresholds = <double>[];
  if (rawThresholds != null) {
    if (rawThresholds is! List) {
      throw const FormatException(
        'Scatter color encoding thresholds must be a list.',
      );
    }
    for (final threshold in rawThresholds) {
      final number = _optionalDouble(threshold);
      if (number == null) {
        throw const FormatException(
          'Scatter color encoding thresholds must be numbers.',
        );
      }
      thresholds.add(number);
    }
  }
  final rawBandLabels = value['bandLabels'];
  final bandLabels = <String>[];
  if (rawBandLabels != null) {
    if (rawBandLabels is! List ||
        rawBandLabels.any((item) => item is! String)) {
      throw const FormatException(
        'Scatter color encoding bandLabels must be strings.',
      );
    }
    bandLabels.addAll(rawBandLabels.cast<String>());
  }
  if (label != null && label is! String ||
      unit != null && unit is! String ||
      showLegend != null && showLegend is! bool) {
    throw const FormatException(
      'Scatter color encoding label and unit must be strings and showLegend must be a boolean.',
    );
  }
  final encoding = ScatterColorEncoding(
    colors: colors,
    scaleType: scaleType,
    thresholds: thresholds,
    bandLabels: bandLabels,
    minimumValue: minimumValue,
    maximumValue: maximumValue,
    label: label as String? ?? 'Color value',
    unit: unit as String?,
    showLegend: showLegend as bool? ?? true,
  );
  if (!encoding.hasValidPiecewiseConfiguration) {
    throw const FormatException(
      'Piecewise Scatter color scales require one fewer strictly ordered finite thresholds than colors and, when supplied, one label per color.',
    );
  }
  return encoding;
}

Map<String, Object?> _encodeScatterOpacityEncoding(
  ScatterOpacityEncoding encoding,
) => {
  'minimumOpacity': _number(encoding.minimumOpacity),
  'maximumOpacity': _number(encoding.maximumOpacity),
  if (encoding.minimumValue != null)
    'minimumValue': _number(encoding.minimumValue!),
  if (encoding.maximumValue != null)
    'maximumValue': _number(encoding.maximumValue!),
  'label': encoding.label,
  if (encoding.unit != null) 'unit': encoding.unit,
  'showLegend': encoding.showLegend,
};

ScatterOpacityEncoding? _decodeScatterOpacityEncoding(
  Map<String, Object?>? value,
) {
  if (value == null) return null;
  final minimumOpacity = _optionalDouble(value['minimumOpacity']) ?? 0.2;
  final maximumOpacity = _optionalDouble(value['maximumOpacity']) ?? 1;
  final minimumValue = _optionalDouble(value['minimumValue']);
  final maximumValue = _optionalDouble(value['maximumValue']);
  if (!minimumOpacity.isFinite ||
      minimumOpacity < 0 ||
      minimumOpacity > 1 ||
      !maximumOpacity.isFinite ||
      maximumOpacity < minimumOpacity ||
      maximumOpacity > 1 ||
      (minimumValue != null && !minimumValue.isFinite) ||
      (maximumValue != null && !maximumValue.isFinite) ||
      (minimumValue != null &&
          maximumValue != null &&
          maximumValue < minimumValue)) {
    throw const FormatException(
      'Scatter opacity encoding visual range and domain must be finite and ordered.',
    );
  }
  final label = value['label'];
  final unit = value['unit'];
  final showLegend = value['showLegend'];
  if (label != null && label is! String ||
      unit != null && unit is! String ||
      showLegend != null && showLegend is! bool) {
    throw const FormatException(
      'Scatter opacity encoding label and unit must be strings and showLegend must be a boolean.',
    );
  }
  return ScatterOpacityEncoding(
    minimumOpacity: minimumOpacity,
    maximumOpacity: maximumOpacity,
    minimumValue: minimumValue,
    maximumValue: maximumValue,
    label: label as String? ?? 'Opacity value',
    unit: unit as String?,
    showLegend: showLegend as bool? ?? true,
  );
}

Map<String, Object?> _encodeScatterCategoryEncoding(
  ScatterCategoryEncoding encoding,
) => {
  'label': encoding.label,
  'showLegend': encoding.showLegend,
  'categories': [
    for (final category in encoding.categories)
      {
        'key': category.key,
        if (category.label != null) 'label': category.label,
        if (category.color != null) 'color': category.color!.toARGB32(),
        if (category.shape != null) 'shape': category.shape!.name,
      },
  ],
};

ScatterCategoryEncoding? _decodeScatterCategoryEncoding(
  Map<String, Object?>? value,
) {
  if (value == null) return null;
  final rawCategories = value['categories'];
  if (rawCategories is! List || rawCategories.isEmpty) {
    throw const FormatException(
      'Scatter category encoding requires at least one category.',
    );
  }
  final categories = <ScatterCategoryStyle>[];
  for (var index = 0; index < rawCategories.length; index++) {
    final raw = rawCategories[index];
    if (raw is! Map) {
      throw FormatException(
        'Scatter category encoding categories[$index] must be an object.',
      );
    }
    final category = Map<String, Object?>.from(raw);
    final key = category['key'];
    final label = category['label'];
    final rawShape = category['shape'];
    if (key is! String ||
        key.isEmpty ||
        label != null && label is! String ||
        rawShape != null && rawShape is! String) {
      throw FormatException(
        'Scatter category encoding categories[$index] has invalid key, label, or shape.',
      );
    }
    final shape = rawShape == null
        ? null
        : _optionalEnum(
            rawShape,
            SeriesMarkerShape.values,
            r'$.style.categoryEncoding.categories['
            '${index.toString()}].shape',
          );
    final color = _optionalColor(
      category['color'],
      r'$.style.categoryEncoding.categories['
      '${index.toString()}].color',
    );
    categories.add(
      ScatterCategoryStyle(
        key: key,
        label: label as String?,
        color: color,
        shape: shape,
      ),
    );
  }
  final label = value['label'];
  final showLegend = value['showLegend'];
  if (label != null && label is! String ||
      showLegend != null && showLegend is! bool) {
    throw const FormatException(
      'Scatter category encoding label must be a string and showLegend must be a boolean.',
    );
  }
  final encoding = ScatterCategoryEncoding(
    categories: categories,
    label: label as String? ?? 'Category',
    showLegend: showLegend as bool? ?? true,
  );
  if (!encoding.hasValidConfiguration) {
    throw const FormatException(
      'Scatter category encodings require unique non-empty keys and at least one color or shape per category.',
    );
  }
  return encoding;
}

Map<String, Object?> _encodeScatterJitter(ScatterJitterConfig jitter) => {
  'xAmplitude': _number(jitter.xAmplitude),
  'yAmplitude': _number(jitter.yAmplitude),
  'seed': jitter.seed,
};

ScatterJitterConfig _decodeScatterJitter(Map<String, Object?>? value) {
  if (value == null) return const ScatterJitterConfig();
  final xAmplitude = _optionalDouble(value['xAmplitude']) ?? 0;
  final yAmplitude = _optionalDouble(value['yAmplitude']) ?? 0;
  final seed = value['seed'] ?? 0;
  if (!xAmplitude.isFinite ||
      xAmplitude < 0 ||
      !yAmplitude.isFinite ||
      yAmplitude < 0 ||
      seed is! int) {
    throw const FormatException(
      'Scatter jitter amplitudes must be finite and non-negative and seed must be an integer.',
    );
  }
  return ScatterJitterConfig(
    xAmplitude: xAmplitude,
    yAmplitude: yAmplitude,
    seed: seed,
  );
}

Map<String, Object?> _encodeScatterClusterConfig(ScatterClusterConfig config) =>
    {
      'cellSize': _number(config.cellSize),
      'minimumPointCount': config.minimumPointCount,
      'minimumRadius': _number(config.minimumRadius),
      'maximumRadius': _number(config.maximumRadius),
      'showCountLabels': config.showCountLabels,
      'labelMinimumPointCount': config.labelMinimumPointCount,
      'showZones': config.showZones,
      'zoneOpacity': _number(config.zoneOpacity),
      'drillOnTap': config.drillOnTap,
      'drillPadding': _number(config.drillPadding),
    };

ScatterClusterConfig _decodeScatterClusterConfig(Map<String, Object?>? value) {
  if (value == null) return const ScatterClusterConfig();
  final cellSize = _optionalDouble(value['cellSize']) ?? 40;
  final minimumPointCount = _optionalInt(value['minimumPointCount']) ?? 2;
  final minimumRadius = _optionalDouble(value['minimumRadius']) ?? 8;
  final maximumRadius = _optionalDouble(value['maximumRadius']) ?? 24;
  final showCountLabels = value['showCountLabels'] as bool? ?? true;
  final labelMinimumPointCount =
      _optionalInt(value['labelMinimumPointCount']) ?? 2;
  final showZones = value['showZones'] as bool? ?? false;
  final zoneOpacity = _optionalDouble(value['zoneOpacity']) ?? 0.08;
  final drillOnTap = value['drillOnTap'] as bool? ?? true;
  final drillPadding = _optionalDouble(value['drillPadding']) ?? 0.18;
  if (cellSize < 8 ||
      cellSize > 256 ||
      minimumPointCount < 2 ||
      minimumRadius <= 0 ||
      minimumRadius > maximumRadius ||
      maximumRadius > 128 ||
      labelMinimumPointCount < 2 ||
      zoneOpacity < 0 ||
      zoneOpacity > 1 ||
      drillPadding < 0 ||
      drillPadding > 1) {
    throw const FormatException(
      'Scatter cluster configuration is outside its supported bounds.',
    );
  }
  return ScatterClusterConfig(
    cellSize: cellSize,
    minimumPointCount: minimumPointCount,
    minimumRadius: minimumRadius,
    maximumRadius: maximumRadius,
    showCountLabels: showCountLabels,
    labelMinimumPointCount: labelMinimumPointCount,
    showZones: showZones,
    zoneOpacity: zoneOpacity,
    drillOnTap: drillOnTap,
    drillPadding: drillPadding,
  );
}

Map<String, Object?> _encodeScatterBinConfig(ScatterBinConfig config) => {
  'cellSize': _number(config.cellSize),
  'gap': _number(config.gap),
  'minimumPointCount': config.minimumPointCount,
  'minimumOpacity': _number(config.minimumOpacity),
  'maximumOpacity': _number(config.maximumOpacity),
  'aggregate': config.aggregate.name,
  'valueSource': config.valueSource.name,
  'showLabels': config.showLabels,
  'labelMinimumPointCount': config.labelMinimumPointCount,
};

ScatterBinConfig _decodeScatterBinConfig(Map<String, Object?>? value) {
  if (value == null) return const ScatterBinConfig();
  final cellSize = _optionalDouble(value['cellSize']) ?? 36;
  final gap = _optionalDouble(value['gap']) ?? 1;
  final minimumPointCount = _optionalInt(value['minimumPointCount']) ?? 1;
  final minimumOpacity = _optionalDouble(value['minimumOpacity']) ?? 0.2;
  final maximumOpacity = _optionalDouble(value['maximumOpacity']) ?? 0.95;
  final aggregate = value.containsKey('aggregate')
      ? _enum(value, 'aggregate', ScatterBinAggregate.values)
      : ScatterBinAggregate.count;
  final valueSource = value.containsKey('valueSource')
      ? _enum(value, 'valueSource', ScatterBinValueSource.values)
      : ScatterBinValueSource.y;
  final showLabels = value['showLabels'] as bool? ?? false;
  final labelMinimumPointCount =
      _optionalInt(value['labelMinimumPointCount']) ?? 10;
  if (!cellSize.isFinite ||
      cellSize < 12 ||
      cellSize > 256 ||
      !gap.isFinite ||
      gap < 0 ||
      gap > 16 ||
      minimumPointCount < 1 ||
      !minimumOpacity.isFinite ||
      minimumOpacity < 0 ||
      minimumOpacity > 1 ||
      !maximumOpacity.isFinite ||
      maximumOpacity < minimumOpacity ||
      maximumOpacity > 1 ||
      labelMinimumPointCount < 1) {
    throw const FormatException(
      'Scatter bin configuration is outside its supported bounds.',
    );
  }
  return ScatterBinConfig(
    cellSize: cellSize,
    gap: gap,
    minimumPointCount: minimumPointCount,
    minimumOpacity: minimumOpacity,
    maximumOpacity: maximumOpacity,
    aggregate: aggregate,
    valueSource: valueSource,
    showLabels: showLabels,
    labelMinimumPointCount: labelMinimumPointCount,
  );
}

Map<String, Object?> _encodeScatterDensityConfig(ScatterDensityConfig config) =>
    {
      'gridCellSize': _number(config.gridCellSize),
      'bandwidth': _number(config.bandwidth),
      'contourCount': config.contourCount,
      'minimumDensity': _number(config.minimumDensity),
      'minimumOpacity': _number(config.minimumOpacity),
      'maximumOpacity': _number(config.maximumOpacity),
      'lineWidth': _number(config.lineWidth),
      'showPoints': config.showPoints,
    };

ScatterDensityConfig _decodeScatterDensityConfig(Map<String, Object?>? value) {
  if (value == null) return const ScatterDensityConfig();
  final gridCellSize = _optionalDouble(value['gridCellSize']) ?? 8;
  final bandwidth = _optionalDouble(value['bandwidth']) ?? 32;
  final contourCount = _optionalInt(value['contourCount']) ?? 6;
  final minimumDensity = _optionalDouble(value['minimumDensity']) ?? 0.08;
  final minimumOpacity = _optionalDouble(value['minimumOpacity']) ?? 0.28;
  final maximumOpacity = _optionalDouble(value['maximumOpacity']) ?? 0.9;
  final lineWidth = _optionalDouble(value['lineWidth']) ?? 1.5;
  final showPoints = value['showPoints'] as bool? ?? false;
  if (!gridCellSize.isFinite ||
      gridCellSize < 4 ||
      gridCellSize > 64 ||
      !bandwidth.isFinite ||
      bandwidth < 4 ||
      bandwidth > 256 ||
      contourCount < 2 ||
      contourCount > 12 ||
      !minimumDensity.isFinite ||
      minimumDensity <= 0 ||
      minimumDensity >= 1 ||
      !minimumOpacity.isFinite ||
      minimumOpacity < 0 ||
      minimumOpacity > 1 ||
      !maximumOpacity.isFinite ||
      maximumOpacity < minimumOpacity ||
      maximumOpacity > 1 ||
      !lineWidth.isFinite ||
      lineWidth <= 0 ||
      lineWidth > 12) {
    throw const FormatException(
      'Scatter density configuration is outside its supported bounds.',
    );
  }
  return ScatterDensityConfig(
    gridCellSize: gridCellSize,
    bandwidth: bandwidth,
    contourCount: contourCount,
    minimumDensity: minimumDensity,
    minimumOpacity: minimumOpacity,
    maximumOpacity: maximumOpacity,
    lineWidth: lineWidth,
    showPoints: showPoints,
  );
}

Map<String, Object?> _encodeScatterInteraction(ScatterInteractionStyle style) =>
    {
      if (style.hoverColor != null) 'hoverColor': style.hoverColor!.toARGB32(),
      'hoverScale': _number(style.hoverScale),
      'hoverStrokeWidth': _number(style.hoverStrokeWidth),
      'pressedColor': style.pressedColor.toARGB32(),
      'pressedScale': _number(style.pressedScale),
      'pressedOpacity': _number(style.pressedOpacity),
      if (style.selectionColor != null)
        'selectionColor': style.selectionColor!.toARGB32(),
      'selectionScale': _number(style.selectionScale),
      'selectionOpacity': _number(style.selectionOpacity),
      'selectionStrokeWidth': _number(style.selectionStrokeWidth),
      if (style.focusColor != null) 'focusColor': style.focusColor!.toARGB32(),
      'focusGap': _number(style.focusGap),
      'focusStrokeWidth': _number(style.focusStrokeWidth),
      'dimmedOpacity': _number(style.dimmedOpacity),
    };

ScatterInteractionStyle _decodeScatterInteraction(Map<String, Object?>? value) {
  if (value == null) return const ScatterInteractionStyle();
  final hoverScale = _optionalDouble(value['hoverScale']) ?? 1.35;
  final hoverStrokeWidth = _optionalDouble(value['hoverStrokeWidth']) ?? 2.0;
  final pressedScale = _optionalDouble(value['pressedScale']) ?? 1.15;
  final pressedOpacity = _optionalDouble(value['pressedOpacity']) ?? 0.12;
  final selectionScale = _optionalDouble(value['selectionScale']) ?? 1.25;
  final selectionOpacity = _optionalDouble(value['selectionOpacity']) ?? 0.14;
  final selectionStrokeWidth =
      _optionalDouble(value['selectionStrokeWidth']) ?? 2.5;
  final focusGap = _optionalDouble(value['focusGap']) ?? 4.0;
  final focusStrokeWidth = _optionalDouble(value['focusStrokeWidth']) ?? 2.5;
  final dimmedOpacity = _optionalDouble(value['dimmedOpacity']) ?? 0.32;
  if (hoverScale < 1 ||
      !hoverScale.isFinite ||
      hoverStrokeWidth < 0 ||
      !hoverStrokeWidth.isFinite ||
      pressedScale <= 0 ||
      !pressedScale.isFinite ||
      pressedOpacity < 0 ||
      pressedOpacity > 1 ||
      selectionScale < 1 ||
      !selectionScale.isFinite ||
      selectionOpacity < 0 ||
      selectionOpacity > 1 ||
      selectionStrokeWidth < 0 ||
      !selectionStrokeWidth.isFinite ||
      focusGap < 0 ||
      !focusGap.isFinite ||
      focusStrokeWidth < 0 ||
      !focusStrokeWidth.isFinite ||
      dimmedOpacity < 0 ||
      dimmedOpacity > 1) {
    throw const FormatException(
      'Scatter interaction scales, widths, gaps, and opacities are outside their supported ranges.',
    );
  }
  return ScatterInteractionStyle(
    hoverColor: _optionalColor(
      value['hoverColor'],
      r'$.style.interaction.hoverColor',
    ),
    hoverScale: hoverScale,
    hoverStrokeWidth: hoverStrokeWidth,
    pressedColor:
        _optionalColor(
          value['pressedColor'],
          r'$.style.interaction.pressedColor',
        ) ??
        const Color(0xFF000000),
    pressedScale: pressedScale,
    pressedOpacity: pressedOpacity,
    selectionColor: _optionalColor(
      value['selectionColor'],
      r'$.style.interaction.selectionColor',
    ),
    selectionScale: selectionScale,
    selectionOpacity: selectionOpacity,
    selectionStrokeWidth: selectionStrokeWidth,
    focusColor: _optionalColor(
      value['focusColor'],
      r'$.style.interaction.focusColor',
    ),
    focusGap: focusGap,
    focusStrokeWidth: focusStrokeWidth,
    dimmedOpacity: dimmedOpacity,
  );
}

Map<String, Object?> _encodeBarInteraction(BarInteractionStyle style) => {
  if (style.hoverColor != null) 'hoverColor': style.hoverColor!.toARGB32(),
  'hoverOpacity': _number(style.hoverOpacity),
  'hoverBorderWidth': _number(style.hoverBorderWidth),
  'pressedColor': style.pressedColor.toARGB32(),
  'pressedOpacity': _number(style.pressedOpacity),
  if (style.selectionColor != null)
    'selectionColor': style.selectionColor!.toARGB32(),
  'selectionOpacity': _number(style.selectionOpacity),
  'selectionBorderWidth': _number(style.selectionBorderWidth),
  if (style.focusColor != null) 'focusColor': style.focusColor!.toARGB32(),
  'focusBorderWidth': _number(style.focusBorderWidth),
  'focusGap': _number(style.focusGap),
  'dimmedOpacity': _number(style.dimmedOpacity),
};

BarInteractionStyle _decodeBarInteraction(Map<String, Object?>? value) {
  if (value == null) return const BarInteractionStyle();
  return BarInteractionStyle(
    hoverColor: _optionalColor(
      value['hoverColor'],
      r'$.style.barStyle.interaction.hoverColor',
    ),
    hoverOpacity: _optionalDouble(value['hoverOpacity']) ?? 0.12,
    hoverBorderWidth: _optionalDouble(value['hoverBorderWidth']) ?? 2.0,
    pressedColor:
        _optionalColor(
          value['pressedColor'],
          r'$.style.barStyle.interaction.pressedColor',
        ) ??
        const Color(0xFF000000),
    pressedOpacity: _optionalDouble(value['pressedOpacity']) ?? 0.16,
    selectionColor: _optionalColor(
      value['selectionColor'],
      r'$.style.barStyle.interaction.selectionColor',
    ),
    selectionOpacity: _optionalDouble(value['selectionOpacity']) ?? 0.14,
    selectionBorderWidth: _optionalDouble(value['selectionBorderWidth']) ?? 2.5,
    focusColor: _optionalColor(
      value['focusColor'],
      r'$.style.barStyle.interaction.focusColor',
    ),
    focusBorderWidth: _optionalDouble(value['focusBorderWidth']) ?? 2.5,
    focusGap: _optionalDouble(value['focusGap']) ?? 3.0,
    dimmedOpacity: _optionalDouble(value['dimmedOpacity']) ?? 0.42,
  );
}

Map<String, Object?> _encodeBarWaterfallStyle(BarWaterfallStyle style) => {
  if (style.increaseColor != null)
    'increaseColor': style.increaseColor!.toARGB32(),
  if (style.decreaseColor != null)
    'decreaseColor': style.decreaseColor!.toARGB32(),
  if (style.totalColor != null) 'totalColor': style.totalColor!.toARGB32(),
  'connector': {
    'show': style.connector.show,
    'color': style.connector.color.toARGB32(),
    'width': _number(style.connector.width),
  },
};

BarWaterfallStyle _decodeBarWaterfallStyle(Map<String, Object?>? value) {
  if (value == null) return const BarWaterfallStyle();
  final connector = _optionalMap(value, 'connector');
  return BarWaterfallStyle(
    increaseColor: _optionalColor(
      value['increaseColor'],
      r'$.style.barWaterfallStyle.increaseColor',
    ),
    decreaseColor: _optionalColor(
      value['decreaseColor'],
      r'$.style.barWaterfallStyle.decreaseColor',
    ),
    totalColor: _optionalColor(
      value['totalColor'],
      r'$.style.barWaterfallStyle.totalColor',
    ),
    connector: connector == null
        ? const BarWaterfallConnectorStyle()
        : BarWaterfallConnectorStyle(
            show: _bool(connector, 'show', fallback: true),
            color:
                _optionalColor(
                  connector['color'],
                  r'$.style.barWaterfallStyle.connector.color',
                ) ??
                const Color(0xFF9CA3AF),
            width: _optionalDouble(connector['width']) ?? 1.0,
          ),
  );
}

BarGradient? _decodeBarGradient(Map<String, Object?>? value) {
  if (value == null) return null;
  final colorsValue = value['colors'];
  if (colorsValue is! List) {
    throw const FormatException('Expected gradient colors list.');
  }
  final colors = [
    for (var index = 0; index < colorsValue.length; index++)
      _optionalColor(colorsValue[index], r'$.style.barStyle.gradient.colors') ??
          (throw const FormatException('Expected gradient color.')),
  ];
  final stopsValue = value['stops'];
  final stops = stopsValue == null
      ? null
      : stopsValue is List
      ? [for (final stop in stopsValue) _optionalDouble(stop)!]
      : throw const FormatException('Expected gradient stops list.');
  if (colors.length < 2) {
    throw const FormatException('A bar gradient requires at least two colors.');
  }
  if (stops != null && stops.length != colors.length) {
    throw const FormatException(
      'Bar gradient stops must match the number of colors.',
    );
  }
  return BarGradient(colors: colors, stops: stops);
}

Map<String, Object?> _encodeBarBorder(BarBorderStyle border) => {
  'color': border.color.toARGB32(),
  'width': _number(border.width),
};

BarBorderStyle? _decodeBarBorder(Map<String, Object?>? value) {
  if (value == null) return null;
  return BarBorderStyle(
    color: _color(value, 'color'),
    width: _optionalDouble(value['width']) ?? 1.0,
  );
}

Map<String, Object?> _encodeBarTrack(BarTrackStyle track) => {
  'color': track.color.toARGB32(),
  if (track.value != null) 'value': _number(track.value!),
  'opacity': _number(track.opacity),
  if (track.cornerRadius != null) 'cornerRadius': _number(track.cornerRadius!),
  if (track.border != null) 'border': _encodeBarBorder(track.border!),
};

BarTrackStyle? _decodeBarTrack(Map<String, Object?>? value) {
  if (value == null) return null;
  return BarTrackStyle(
    color: _color(value, 'color'),
    value: _optionalDouble(value['value']),
    opacity: _optionalDouble(value['opacity']) ?? 1.0,
    cornerRadius: _optionalDouble(value['cornerRadius']),
    border: _decodeBarBorder(_optionalMap(value, 'border')),
  );
}

Map<String, Object?> _encodeBarLollipop(BarLollipopStyle style) => {
  'stemWidth': _number(style.stemWidth),
  'headRadius': _number(style.headRadius),
  if (style.stemColor != null) 'stemColor': style.stemColor!.toARGB32(),
  if (style.headColor != null) 'headColor': style.headColor!.toARGB32(),
  if (style.headBorder != null)
    'headBorder': _encodeBarBorder(style.headBorder!),
};

BarLollipopStyle? _decodeBarLollipop(Map<String, Object?>? value) {
  if (value == null) return null;
  return BarLollipopStyle(
    stemWidth: _optionalDouble(value['stemWidth']) ?? 3,
    headRadius: _optionalDouble(value['headRadius']) ?? 7,
    stemColor: _optionalColor(
      value['stemColor'],
      r'$.style.barLollipop.stemColor',
    ),
    headColor: _optionalColor(
      value['headColor'],
      r'$.style.barLollipop.headColor',
    ),
    headBorder: _decodeBarBorder(_optionalMap(value, 'headBorder')),
  );
}

Map<String, Object?> _encodeBarDivergingStyle(BarDivergingStyle style) => {
  'showCenterLine': style.showCenterLine,
  'centerLineColor': style.centerLineColor.toARGB32(),
  'centerLineWidth': _number(style.centerLineWidth),
  'centerLineOpacity': _number(style.centerLineOpacity),
};

BarDivergingStyle _decodeBarDivergingStyle(Map<String, Object?>? value) {
  if (value == null) return const BarDivergingStyle();
  return BarDivergingStyle(
    showCenterLine: _bool(value, 'showCenterLine', fallback: true),
    centerLineColor:
        _optionalColor(
          value['centerLineColor'],
          r'$.style.barDivergingStyle.centerLineColor',
        ) ??
        const Color(0xFF64748B),
    centerLineWidth: _optionalDouble(value['centerLineWidth']) ?? 1.25,
    centerLineOpacity: _optionalDouble(value['centerLineOpacity']) ?? 0.7,
  );
}

Map<String, Object?> _encodeBarBullet(BarBulletStyle bullet) => {
  'ranges': [
    for (final range in bullet.ranges)
      {
        'endValue': _number(range.endValue),
        'color': range.color.toARGB32(),
        if (range.label != null) 'label': range.label,
      },
  ],
  'measureThicknessFactor': _number(bullet.measureThicknessFactor),
  'cornerRadius': _number(bullet.cornerRadius),
};

BarBulletStyle? _decodeBarBullet(Map<String, Object?>? value) {
  if (value == null) return null;
  final rawRanges = value['ranges'];
  if (rawRanges is! List) {
    throw const FormatException('Expected bullet range list.');
  }
  return BarBulletStyle(
    ranges: [
      for (var index = 0; index < rawRanges.length; index++)
        if (rawRanges[index] case final Map range)
          BarBulletRange(
            endValue: _double(Map<String, Object?>.from(range), 'endValue'),
            color: _color(Map<String, Object?>.from(range), 'color'),
            label: _optionalString(range['label']),
          )
        else
          throw FormatException(
            'Expected bullet range object at ranges[$index].',
          ),
    ],
    measureThicknessFactor:
        _optionalDouble(value['measureThicknessFactor']) ?? 0.45,
    cornerRadius: _optionalDouble(value['cornerRadius']) ?? 3.0,
  );
}

Map<String, Object?> _encodeBarTargetMarker(BarTargetMarkerStyle marker) => {
  if (marker.color != null) 'color': marker.color!.toARGB32(),
  'width': _number(marker.width),
  'lengthFactor': _number(marker.lengthFactor),
  'opacity': _number(marker.opacity),
};

BarTargetMarkerStyle _decodeBarTargetMarker(Map<String, Object?>? value) {
  if (value == null) return const BarTargetMarkerStyle();
  return BarTargetMarkerStyle(
    color: _optionalColor(value['color'], r'$.style.barTargetMarker.color'),
    width: _optionalDouble(value['width']) ?? 2.0,
    lengthFactor: _optionalDouble(value['lengthFactor']) ?? 1.3,
    opacity: _optionalDouble(value['opacity']) ?? 1.0,
  );
}

Map<String, Object?> _encodeBarErrorBar(BarErrorBarStyle style) => {
  if (style.color != null) 'color': style.color!.toARGB32(),
  'width': _number(style.width),
  'capLengthFactor': _number(style.capLengthFactor),
  'opacity': _number(style.opacity),
};

BarErrorBarStyle _decodeBarErrorBar(Map<String, Object?>? value) {
  if (value == null) return const BarErrorBarStyle();
  return BarErrorBarStyle(
    color: _optionalColor(value['color'], r'$.style.barErrorBar.color'),
    width: _optionalDouble(value['width']) ?? 1.5,
    capLengthFactor: _optionalDouble(value['capLengthFactor']) ?? 0.6,
    opacity: _optionalDouble(value['opacity']) ?? 1.0,
  );
}

Map<String, Object?> _encodeBarLabels(BarLabelStyle labels) => {
  'show': labels.show,
  'position': labels.position.name,
  'valueMode': labels.valueMode.name,
  if (labels.color != null) 'color': labels.color!.toARGB32(),
  'fontSize': _number(labels.fontSize),
  'fontWeightIndex': FontWeight.values.indexOf(labels.fontWeight),
  'showUnit': labels.showUnit,
  'padding': _number(labels.padding),
  'collisionPolicy': labels.collisionPolicy.name,
  'plotEdgeAware': labels.plotEdgeAware,
  'collisionPadding': _number(labels.collisionPadding),
  if (labels.backgroundColor != null)
    'backgroundColor': labels.backgroundColor!.toARGB32(),
  if (labels.borderColor != null) 'borderColor': labels.borderColor!.toARGB32(),
  'borderWidth': _number(labels.borderWidth),
  'borderRadius': _number(labels.borderRadius),
  'backgroundPadding': _number(labels.backgroundPadding),
  'callout': {
    'show': labels.callout.show,
    if (labels.callout.color != null) 'color': labels.callout.color!.toARGB32(),
    'width': _number(labels.callout.width),
    'minimumLength': _number(labels.callout.minimumLength),
  },
  'showStackTotal': labels.showStackTotal,
};

BarLabelStyle _decodeBarLabels(Map<String, Object?>? value) {
  if (value == null) return const BarLabelStyle();
  return BarLabelStyle(
    show: _bool(value, 'show', fallback: false),
    position:
        _optionalEnum(
          value['position'],
          BarLabelPosition.values,
          r'$.style.barLabels.position',
        ) ??
        BarLabelPosition.auto,
    valueMode:
        _optionalEnum(
          value['valueMode'],
          BarLabelValueMode.values,
          r'$.style.barLabels.valueMode',
        ) ??
        BarLabelValueMode.value,
    color: _optionalColor(value['color'], r'$.style.barLabels.color'),
    fontSize: _optionalDouble(value['fontSize']) ?? 10.0,
    fontWeight: value['fontWeightIndex'] == null
        ? FontWeight.w600
        : _fontWeight(value, 'fontWeightIndex'),
    showUnit: _bool(value, 'showUnit', fallback: false),
    padding: _optionalDouble(value['padding']) ?? 4.0,
    collisionPolicy:
        _optionalEnum(
          value['collisionPolicy'],
          BarLabelCollisionPolicy.values,
          r'$.style.barLabels.collisionPolicy',
        ) ??
        BarLabelCollisionPolicy.none,
    plotEdgeAware: _bool(value, 'plotEdgeAware', fallback: true),
    collisionPadding: _optionalDouble(value['collisionPadding']) ?? 2.0,
    backgroundColor: _optionalColor(
      value['backgroundColor'],
      r'$.style.barLabels.backgroundColor',
    ),
    borderColor: _optionalColor(
      value['borderColor'],
      r'$.style.barLabels.borderColor',
    ),
    borderWidth: _optionalDouble(value['borderWidth']) ?? 0.0,
    borderRadius: _optionalDouble(value['borderRadius']) ?? 4.0,
    backgroundPadding: _optionalDouble(value['backgroundPadding']) ?? 3.0,
    callout: _decodeBarLabelCallout(_optionalMap(value, 'callout')),
    showStackTotal: _bool(value, 'showStackTotal', fallback: false),
  );
}

BarLabelCalloutStyle _decodeBarLabelCallout(Map<String, Object?>? value) {
  if (value == null) return const BarLabelCalloutStyle();
  return BarLabelCalloutStyle(
    show: _bool(value, 'show', fallback: false),
    color: _optionalColor(value['color'], r'$.style.barLabels.callout.color'),
    width: _optionalDouble(value['width']) ?? 1.0,
    minimumLength: _optionalDouble(value['minimumLength']) ?? 4.0,
  );
}

Map<String, Object?> _encodePieStyle(RadialChartStyle style) => {
  'startAngleDegrees': _number(style.startAngleDegrees),
  'clockwise': style.clockwise,
  'radiusFactor': _number(style.radiusFactor),
  'sliceGap': _number(style.sliceGap),
  'borderWidth': _number(style.borderWidth),
  if (style.borderColor != null) 'borderColor': style.borderColor!.toARGB32(),
  if (style.borderColorMode != null)
    'borderColorMode': style.borderColorMode!.name,
  if (style.borderHueShiftDegrees != null)
    'borderHueShiftDegrees': _number(style.borderHueShiftDegrees!),
  if (style.borderSaturationShift != null)
    'borderSaturationShift': _number(style.borderSaturationShift!),
  if (style.borderLightnessShift != null)
    'borderLightnessShift': _number(style.borderLightnessShift!),
  if (style.gradient != null) 'gradient': _encodePieGradient(style.gradient!),
  'selectionExplodeOffset': _number(style.selectionExplodeOffset),
  if (style.opacity != null) 'opacity': _number(style.opacity!),
  if (style.cornerRadius != null) 'cornerRadius': _number(style.cornerRadius!),
  if (style.cornerTreatment != null)
    'cornerTreatment': style.cornerTreatment!.name,
  if (style.shadow != null) 'shadow': _encodePieElevation(style.shadow!),
  if (style.selectedElevation != null)
    'selectedElevation': _encodePieElevation(style.selectedElevation!),
  if (style.animationMode != null) 'animationMode': style.animationMode!.name,
  'dataTransitionMode': style.dataTransitionMode.name,
};

Map<String, Object?> _encodeDonutStyle(DonutChartStyle style) => {
  ..._encodePieStyle(style),
  'innerRadiusFactor': _number(style.innerRadiusFactor),
  'sweepAngleDegrees': _number(style.sweepAngleDegrees),
};

Map<String, Object?> _encodeRadialSelectionStyle(RadialSelectionStyle style) =>
    {
      'effect': style.effect.name,
      'liftScale': _number(style.liftScale),
      'liftOffset': _number(style.liftOffset),
      'backdropBlur': _number(style.backdropBlur),
    };

RadialSelectionStyle _decodeRadialSelectionStyle(Map<String, Object?> value) {
  const defaults = RadialSelectionStyle();
  return RadialSelectionStyle(
    effect: _enum(value, 'effect', RadialSelectionEffect.values),
    liftScale: _double(value, 'liftScale'),
    liftOffset: _optionalDouble(value['liftOffset']) ?? defaults.liftOffset,
    backdropBlur: _double(value, 'backdropBlur'),
  );
}

Map<String, Object?> _encodeRadialBarStyle(RadialBarStyle style) => {
  'cornerRadius': _number(style.cornerRadius),
  'opacity': _number(style.opacity),
  if (style.borderColor != null) 'borderColor': style.borderColor!.toARGB32(),
  'borderWidth': _number(style.borderWidth),
  if (style.trackColor != null) 'trackColor': style.trackColor!.toARGB32(),
  'trackOpacity': _number(style.trackOpacity),
  if (style.gradient != null)
    'gradient': _encodeRadialBarGradient(style.gradient!),
  'showDataLabels': style.showDataLabels,
  'dataLabels': _encodeRadialBarDataLabels(style.dataLabels),
};

RadialBarStyle _decodeRadialBarStyle(Map<String, Object?> value) =>
    RadialBarStyle(
      cornerRadius: _double(value, 'cornerRadius'),
      opacity: _double(value, 'opacity'),
      borderColor: _optionalColor(
        value['borderColor'],
        r'$.style.radialBarStyle.borderColor',
      ),
      borderWidth: _double(value, 'borderWidth'),
      trackColor: _optionalColor(
        value['trackColor'],
        r'$.style.radialBarStyle.trackColor',
      ),
      trackOpacity: _double(value, 'trackOpacity'),
      gradient: value['gradient'] == null
          ? null
          : _decodeRadialBarGradient(_map(value, 'gradient')),
      showDataLabels: _bool(value, 'showDataLabels'),
      dataLabels: value['dataLabels'] == null
          ? const RadialBarDataLabelConfig()
          : _decodeRadialBarDataLabels(_map(value, 'dataLabels')),
    );

Map<String, Object?> _encodeRadialBarGradient(
  RadialBarGradientStyle gradient,
) => {
  'enabled': gradient.enabled,
  'type': gradient.type.name,
  if (gradient.startColor != null)
    'startColor': gradient.startColor!.toARGB32(),
  if (gradient.endColor != null) 'endColor': gradient.endColor!.toARGB32(),
  'startLightnessShift': _number(gradient.startLightnessShift),
  'endLightnessShift': _number(gradient.endLightnessShift),
};

RadialBarGradientStyle _decodeRadialBarGradient(Map<String, Object?> value) =>
    RadialBarGradientStyle(
      enabled: _bool(value, 'enabled'),
      type: _enum(value, 'type', RadialBarGradientType.values),
      startColor: _optionalColor(
        value['startColor'],
        r'$.style.radialBarStyle.gradient.startColor',
      ),
      endColor: _optionalColor(
        value['endColor'],
        r'$.style.radialBarStyle.gradient.endColor',
      ),
      startLightnessShift: _double(value, 'startLightnessShift'),
      endLightnessShift: _double(value, 'endLightnessShift'),
    );

Map<String, Object?> _encodeRadialBarDataLabels(
  RadialBarDataLabelConfig config,
) => {
  'position': config.position.name,
  'content': config.content.name,
  'colorMode': config.colorMode.name,
  'textStyle': _encodePolarLabelStyle(config.textStyle),
  'offset': _number(config.offset),
  'showPanel': config.showPanel,
  if (config.panelStyle != null)
    'panelStyle': ChartStyleDocumentCodec.encodeLabelStyle(
      config.panelStyle!,
    ).toJson(),
  'connectorLength': _number(config.connectorLength),
  'connectorWidth': _number(config.connectorWidth),
  if (config.connectorColor != null)
    'connectorColor': config.connectorColor!.toARGB32(),
};

RadialBarDataLabelConfig _decodeRadialBarDataLabels(
  Map<String, Object?> value,
) => RadialBarDataLabelConfig(
  position: _enum(value, 'position', RadialBarDataLabelPosition.values),
  content: _enum(value, 'content', RadialBarDataLabelContent.values),
  colorMode: _enum(value, 'colorMode', RadialBarDataLabelColorMode.values),
  textStyle: _decodePolarLabelStyle(value['textStyle']),
  offset: _double(value, 'offset'),
  showPanel: _optionalBool(value['showPanel']) ?? false,
  panelStyle: value['panelStyle'] == null
      ? null
      : ChartStyleDocumentCodec.decodeLabelStyle(
          JsonValue.fromJson(_map(value, 'panelStyle')) as JsonObjectValue,
        ),
  connectorLength: _double(value, 'connectorLength'),
  connectorWidth: _double(value, 'connectorWidth'),
  connectorColor: _optionalColor(
    value['connectorColor'],
    r'$.style.radialBarStyle.dataLabels.connectorColor',
  ),
);

GaugeChartSeries _decodeGaugeSeries({
  required ChartSeriesDocument document,
  required List<ChartDataPoint> points,
  required Map<String, Object?> style,
  required Map<String, dynamic>? metadata,
  required bool showInLegend,
  required bool showTrackingAxisLabel,
}) {
  if (points.length != 1) {
    throw const _UnsupportedModelException(
      'Gauge documents must contain exactly one canonical measurement point.',
      r'$.data',
    );
  }
  final indicator = _decodeGaugeIndicatorStyle(
    _map(style, 'gaugeIndicatorStyle'),
  );
  final common = (
    id: document.id,
    name: document.name,
    metric: _string(style, 'gaugeMetric'),
    value: points.single.y,
    minimum: _double(style, 'gaugeMinimum'),
    maximum: _double(style, 'gaugeMaximum'),
    color: _optionalColor(style['color'], r'$.style.color'),
    metadata: metadata,
    unit: document.unit,
    target: _optionalMap(style, 'gaugeTarget') == null
        ? null
        : _decodeGaugeTarget(_map(style, 'gaugeTarget')),
    zones: _decodeGaugeZones(style['gaugeZones']),
    thresholds: _decodeGaugeThresholds(style['gaugeThresholds']),
  );
  return GaugeChartSeries(
    id: common.id,
    name: common.name,
    metric: common.metric,
    value: common.value,
    minimum: common.minimum,
    maximum: common.maximum,
    color: common.color,
    metadata: common.metadata,
    unit: common.unit,
    showInLegend: showInLegend,
    showTrackingAxisLabel: showTrackingAxisLabel,
    target: common.target,
    zones: common.zones,
    thresholds: common.thresholds,
    indicatorStyle: indicator,
  );
}

Map<String, Object?> _encodeGaugeZone(GaugeZone zone) => {
  'from': _number(zone.from),
  'to': _number(zone.to),
  'status': zone.status,
  if (zone.color != null) 'color': zone.color!.toARGB32(),
};

GaugeZone _decodeGaugeZone(Map<String, Object?> value, String path) =>
    GaugeZone(
      from: _double(value, 'from'),
      to: _double(value, 'to'),
      status: _string(value, 'status'),
      color: _optionalColor(value['color'], '$path.color'),
    );

List<GaugeZone> _decodeGaugeZones(Object? value) {
  if (value is! List) {
    throw const _UnsupportedModelException(
      'Gauge zones must be a list.',
      r'$.style.gaugeZones',
    );
  }
  return <GaugeZone>[
    for (final (index, raw) in value.indexed)
      if (raw is Map<String, Object?>)
        _decodeGaugeZone(raw, '\$.style.gaugeZones[$index]')
      else
        throw _UnsupportedModelException(
          'Gauge zone must be an object.',
          '\$.style.gaugeZones[$index]',
        ),
  ];
}

Map<String, Object?> _encodeGaugeTarget(GaugeTarget target) => {
  'value': _number(target.value),
  if (target.label != null) 'label': target.label,
  if (target.color != null) 'color': target.color!.toARGB32(),
  'width': _number(target.width),
};

GaugeTarget _decodeGaugeTarget(Map<String, Object?> value) => GaugeTarget(
  value: _double(value, 'value'),
  label: _optionalString(value['label']),
  color: _optionalColor(value['color'], r'$.style.gaugeTarget.color'),
  width: _double(value, 'width'),
);

Map<String, Object?> _encodeGaugeThreshold(GaugeThreshold threshold) => {
  'value': _number(threshold.value),
  if (threshold.label != null) 'label': threshold.label,
  if (threshold.color != null) 'color': threshold.color!.toARGB32(),
  'width': _number(threshold.width),
  'dashPattern': [
    for (final interval in threshold.dashPattern) _number(interval),
  ],
};

List<GaugeThreshold> _decodeGaugeThresholds(Object? value) {
  if (value is! List) {
    throw const _UnsupportedModelException(
      'Gauge thresholds must be a list.',
      r'$.style.gaugeThresholds',
    );
  }
  return <GaugeThreshold>[
    for (final (index, raw) in value.indexed)
      if (raw is Map<String, Object?>)
        GaugeThreshold(
          value: _double(raw, 'value'),
          label: _optionalString(raw['label']),
          color: _optionalColor(
            raw['color'],
            '\$.style.gaugeThresholds[$index].color',
          ),
          width: _double(raw, 'width'),
          dashPattern: _decodeDashPattern(raw['dashPattern']),
        )
      else
        throw _UnsupportedModelException(
          'Gauge threshold must be an object.',
          '\$.style.gaugeThresholds[$index]',
        ),
  ];
}

Map<String, Object?> _encodeGaugeIndicatorStyle(
  GaugeIndicatorStyle style,
) => switch (style) {
  NeedleGaugeStyle() => {
    'type': 'needle',
    'needleLengthFactor': _number(style.needleLengthFactor),
    'needleWidth': _number(style.needleWidth),
    'needleTipWidth': _number(style.needleTipWidth),
    if (style.needleColor != null) 'needleColor': style.needleColor!.toARGB32(),
    'pivotRadius': _number(style.pivotRadius),
    if (style.pivotColor != null) 'pivotColor': style.pivotColor!.toARGB32(),
    if (style.pivotBorderColor != null)
      'pivotBorderColor': style.pivotBorderColor!.toARGB32(),
    'pivotBorderWidth': _number(style.pivotBorderWidth),
    'axisThickness': _number(style.axisThickness),
    if (style.axisColor != null) 'axisColor': style.axisColor!.toARGB32(),
    'axisOpacity': _number(style.axisOpacity),
  },
  SolidGaugeStyle() => {
    'type': 'solid',
    if (style.trackColor != null) 'trackColor': style.trackColor!.toARGB32(),
    'trackOpacity': _number(style.trackOpacity),
    'cornerRadius': _number(style.cornerRadius),
    if (style.borderColor != null) 'borderColor': style.borderColor!.toARGB32(),
    'borderWidth': _number(style.borderWidth),
    'opacity': _number(style.opacity),
    if (style.gradient != null)
      'gradient': _encodeGaugeGradient(style.gradient!),
  },
};

Map<String, Object?> _encodeGaugeGradient(GaugeGradientStyle gradient) => {
  'enabled': gradient.enabled,
  'type': gradient.type.name,
  if (gradient.startColor != null)
    'startColor': gradient.startColor!.toARGB32(),
  if (gradient.endColor != null) 'endColor': gradient.endColor!.toARGB32(),
  'startLightnessShift': _number(gradient.startLightnessShift),
  'endLightnessShift': _number(gradient.endLightnessShift),
};

GaugeGradientStyle _decodeGaugeGradient(Map<String, Object?> value) =>
    GaugeGradientStyle(
      enabled: _bool(value, 'enabled'),
      type: GaugeGradientType.values.byName(_string(value, 'type')),
      startColor: _optionalColor(
        value['startColor'],
        r'$.style.gaugeIndicatorStyle.gradient.startColor',
      ),
      endColor: _optionalColor(
        value['endColor'],
        r'$.style.gaugeIndicatorStyle.gradient.endColor',
      ),
      startLightnessShift: _double(value, 'startLightnessShift'),
      endLightnessShift: _double(value, 'endLightnessShift'),
    );

GaugeIndicatorStyle _decodeGaugeIndicatorStyle(Map<String, Object?> value) =>
    switch (_string(value, 'type')) {
      'needle' => NeedleGaugeStyle(
        needleLengthFactor: _double(value, 'needleLengthFactor'),
        needleWidth: _double(value, 'needleWidth'),
        needleTipWidth: _optionalDouble(value['needleTipWidth']) ?? 0,
        needleColor: _optionalColor(
          value['needleColor'],
          r'$.style.gaugeIndicatorStyle.needleColor',
        ),
        pivotRadius: _double(value, 'pivotRadius'),
        pivotColor: _optionalColor(
          value['pivotColor'],
          r'$.style.gaugeIndicatorStyle.pivotColor',
        ),
        pivotBorderColor: _optionalColor(
          value['pivotBorderColor'],
          r'$.style.gaugeIndicatorStyle.pivotBorderColor',
        ),
        pivotBorderWidth: _optionalDouble(value['pivotBorderWidth']) ?? 0,
        axisThickness: _double(value, 'axisThickness'),
        axisColor: _optionalColor(
          value['axisColor'],
          r'$.style.gaugeIndicatorStyle.axisColor',
        ),
        axisOpacity: _double(value, 'axisOpacity'),
      ),
      'solid' => SolidGaugeStyle(
        trackColor: _optionalColor(
          value['trackColor'],
          r'$.style.gaugeIndicatorStyle.trackColor',
        ),
        trackOpacity: _double(value, 'trackOpacity'),
        cornerRadius: _double(value, 'cornerRadius'),
        borderColor: _optionalColor(
          value['borderColor'],
          r'$.style.gaugeIndicatorStyle.borderColor',
        ),
        borderWidth: _double(value, 'borderWidth'),
        opacity: _double(value, 'opacity'),
        gradient: value['gradient'] == null
            ? null
            : _decodeGaugeGradient(_map(value, 'gradient')),
      ),
      final type => throw _UnsupportedModelException(
        'Unsupported Gauge indicator type "$type".',
        r'$.style.gaugeIndicatorStyle.type',
      ),
    };

Map<String, Object?> _encodePolarColumnStyle(PolarColumnStyle style) => {
  'cornerRadius': _number(style.cornerRadius),
  'cornerRadiusMode': style.cornerRadiusMode.name,
  'opacity': _number(style.opacity),
  if (style.borderColor != null) 'borderColor': style.borderColor!.toARGB32(),
  'borderWidth': _number(style.borderWidth),
  'showDataLabels': style.showDataLabels,
  'maximumVisibleDataLabels': style.maximumVisibleDataLabels,
  'dataLabelRadialPosition': _number(style.dataLabelRadialPosition),
  'dataLabelStyle': _encodePolarLabelStyle(style.dataLabelStyle),
  if (style.gradient != null)
    'gradient': _encodePolarColumnGradient(style.gradient!),
  'shadow': _encodePolarColumnShadow(style.shadow),
  'animationMode': style.animationMode.name,
};

PolarColumnStyle _decodePolarColumnStyle(Map<String, Object?> value) =>
    PolarColumnStyle(
      cornerRadius: _double(value, 'cornerRadius'),
      cornerRadiusMode: value['cornerRadiusMode'] == null
          ? PolarColumnCornerRadiusMode.outerEnd
          : _enum(
              value,
              'cornerRadiusMode',
              PolarColumnCornerRadiusMode.values,
            ),
      opacity: _double(value, 'opacity'),
      borderColor: _optionalColor(
        value['borderColor'],
        r'$.style.polarStyle.borderColor',
      ),
      borderWidth: _double(value, 'borderWidth'),
      showDataLabels: _bool(value, 'showDataLabels'),
      maximumVisibleDataLabels:
          _optionalInt(value['maximumVisibleDataLabels']) ?? 24,
      dataLabelRadialPosition:
          _optionalDouble(value['dataLabelRadialPosition']) ?? 0.5,
      dataLabelStyle: _decodePolarLabelStyle(value['dataLabelStyle']),
      gradient: _optionalMap(value, 'gradient') == null
          ? null
          : _decodePolarColumnGradient(_map(value, 'gradient')),
      shadow: _optionalMap(value, 'shadow') == null
          ? const PolarColumnShadowStyle()
          : _decodePolarColumnShadow(_map(value, 'shadow')),
      animationMode: value['animationMode'] == null
          ? PolarColumnAnimationMode.none
          : _enum(value, 'animationMode', PolarColumnAnimationMode.values),
    );

Map<String, Object?> _encodePolarLabelStyle(PolarLabelStyle style) => {
  if (style.color != null) 'color': style.color!.toARGB32(),
  if (style.fontSize != null) 'fontSize': _number(style.fontSize!),
  if (style.fontWeight != null)
    'fontWeightIndex': FontWeight.values.indexOf(style.fontWeight!),
};

PolarLabelStyle _decodePolarLabelStyle(Object? value) {
  if (value == null) return const PolarLabelStyle();
  if (value is! Map) {
    throw const FormatException('Polar label style must be an object.');
  }
  final map = value.cast<String, Object?>();
  final weightIndex = _optionalInt(map['fontWeightIndex']);
  if (weightIndex != null &&
      (weightIndex < 0 || weightIndex >= FontWeight.values.length)) {
    throw const FormatException('Polar label font weight index is invalid.');
  }
  return PolarLabelStyle(
    color: _optionalColor(map['color'], r'$.style.polarStyle.labelStyle.color'),
    fontSize: _optionalDouble(map['fontSize']),
    fontWeight: weightIndex == null ? null : FontWeight.values[weightIndex],
  );
}

Map<String, Object?> _encodePolarColumnGradient(
  PolarColumnGradientStyle style,
) => {
  'enabled': style.enabled,
  if (style.startColor != null) 'startColor': style.startColor!.toARGB32(),
  if (style.endColor != null) 'endColor': style.endColor!.toARGB32(),
  'startLightnessShift': _number(style.startLightnessShift),
  'endLightnessShift': _number(style.endLightnessShift),
};

PolarColumnGradientStyle _decodePolarColumnGradient(
  Map<String, Object?> value,
) => PolarColumnGradientStyle(
  enabled: _bool(value, 'enabled'),
  startColor: _optionalColor(
    value['startColor'],
    r'$.style.polarStyle.gradient.startColor',
  ),
  endColor: _optionalColor(
    value['endColor'],
    r'$.style.polarStyle.gradient.endColor',
  ),
  startLightnessShift: _double(value, 'startLightnessShift'),
  endLightnessShift: _double(value, 'endLightnessShift'),
);

Map<String, Object?> _encodePolarColumnShadow(PolarColumnShadowStyle style) => {
  if (style.color != null) 'color': style.color!.toARGB32(),
  'blurRadius': _number(style.blurRadius),
  'spreadRadius': _number(style.spreadRadius),
  'offsetX': _number(style.offset.dx),
  'offsetY': _number(style.offset.dy),
  'opacity': _number(style.opacity),
};

PolarColumnShadowStyle _decodePolarColumnShadow(Map<String, Object?> value) =>
    PolarColumnShadowStyle(
      color: _optionalColor(value['color'], r'$.style.polarStyle.shadow.color'),
      blurRadius: _double(value, 'blurRadius'),
      spreadRadius: _double(value, 'spreadRadius'),
      offset: Offset(_double(value, 'offsetX'), _double(value, 'offsetY')),
      opacity: _double(value, 'opacity'),
    );

Map<String, Object?> _encodePolarColumnTargetMarker(
  PolarColumnTargetMarkerStyle style,
) => {
  if (style.color != null) 'color': style.color!.toARGB32(),
  'width': _number(style.width),
  'lengthFactor': _number(style.lengthFactor),
  'opacity': _number(style.opacity),
};

PolarColumnTargetMarkerStyle _decodePolarColumnTargetMarker(
  Map<String, Object?> value,
) => PolarColumnTargetMarkerStyle(
  color: _optionalColor(value['color'], r'$.style.polarTargetMarker.color'),
  width: _double(value, 'width'),
  lengthFactor: _double(value, 'lengthFactor'),
  opacity: _double(value, 'opacity'),
);

Map<String, Object?> _encodePolarColumnIntervalStyle(
  PolarColumnIntervalStyle style,
) => {
  'display': style.display.name,
  if (style.color != null) 'color': style.color!.toARGB32(),
  'width': _number(style.width),
  'capLengthFactor': _number(style.capLengthFactor),
  'bandLengthFactor': _number(style.bandLengthFactor),
  'opacity': _number(style.opacity),
};

PolarColumnIntervalStyle _decodePolarColumnIntervalStyle(
  Map<String, Object?> value,
) => PolarColumnIntervalStyle(
  display: _enum(value, 'display', PolarColumnIntervalDisplay.values),
  color: _optionalColor(value['color'], r'$.style.polarIntervalStyle.color'),
  width: _double(value, 'width'),
  capLengthFactor: _double(value, 'capLengthFactor'),
  bandLengthFactor: _double(value, 'bandLengthFactor'),
  opacity: _double(value, 'opacity'),
);

Map<String, Object?> _encodePieSliceRadiusConfig(
  PieSliceRadiusConfig config, {
  JsonObjectValue? formatter,
}) => {
  'minimumFactor': _number(config.minimumFactor),
  'scale': config.scale.name,
  'label': config.label,
  if (config.unit != null) 'unit': config.unit,
  if (formatter != null) 'formatter': formatter.toJson(),
};

PieSliceRadiusConfig _decodePieSliceRadiusConfig(
  Map<String, Object?> value, {
  RadialValueFormatter? formatter,
}) => PieSliceRadiusConfig(
  minimumFactor: _double(value, 'minimumFactor'),
  scale: _enum(value, 'scale', PieSliceRadiusScale.values),
  label: _string(value, 'label'),
  unit: _optionalString(value['unit']),
  formatter: formatter,
);

PieChartStyle _decodePieStyle(Map<String, Object?> value) => PieChartStyle(
  startAngleDegrees: _double(value, 'startAngleDegrees'),
  clockwise: _bool(value, 'clockwise'),
  radiusFactor: _double(value, 'radiusFactor'),
  sliceGap: _double(value, 'sliceGap'),
  borderWidth: _double(value, 'borderWidth'),
  borderColor: _optionalColor(
    value['borderColor'],
    r'$.style.pieStyle.borderColor',
  ),
  borderColorMode: _optionalEnum(
    value['borderColorMode'],
    PieBorderColorMode.values,
    r'$.style.pieStyle.borderColorMode',
  ),
  borderHueShiftDegrees: _optionalDouble(value['borderHueShiftDegrees']),
  borderSaturationShift: _optionalDouble(value['borderSaturationShift']),
  borderLightnessShift: _optionalDouble(value['borderLightnessShift']),
  gradient: _optionalMap(value, 'gradient') == null
      ? null
      : _decodePieGradient(_map(value, 'gradient')),
  selectionExplodeOffset: _double(value, 'selectionExplodeOffset'),
  opacity: _optionalDouble(value['opacity']),
  cornerRadius: _optionalDouble(value['cornerRadius']),
  cornerTreatment: _optionalEnum(
    value['cornerTreatment'],
    PieCornerTreatment.values,
    r'$.style.pieStyle.cornerTreatment',
  ),
  shadow: _optionalMap(value, 'shadow') == null
      ? null
      : _decodePieElevation(_map(value, 'shadow')),
  selectedElevation: _optionalMap(value, 'selectedElevation') == null
      ? null
      : _decodePieElevation(_map(value, 'selectedElevation')),
  animationMode: _optionalEnum(
    value['animationMode'],
    PieAnimationMode.values,
    r'$.style.pieStyle.animationMode',
  ),
  dataTransitionMode:
      _optionalEnum(
        value['dataTransitionMode'],
        RadialDataTransitionMode.values,
        r'$.style.pieStyle.dataTransitionMode',
      ) ??
      RadialDataTransitionMode.automatic,
);

DonutChartStyle _decodeDonutStyle(Map<String, Object?> value) =>
    DonutChartStyle.fromRadialStyle(
      _decodePieStyle(value),
      innerRadiusFactor: _double(value, 'innerRadiusFactor'),
      sweepAngleDegrees: _double(value, 'sweepAngleDegrees'),
    );

Map<String, Object?> _encodePieGradient(PieGradientStyle style) => {
  'enabled': style.enabled,
  'type': style.type.name,
  if (style.startColor != null) 'startColor': style.startColor!.toARGB32(),
  if (style.endColor != null) 'endColor': style.endColor!.toARGB32(),
  'startLightnessShift': _number(style.startLightnessShift),
  'endLightnessShift': _number(style.endLightnessShift),
  'angleDegrees': _number(style.angleDegrees),
};

PieGradientStyle _decodePieGradient(Map<String, Object?> value) =>
    PieGradientStyle(
      enabled: _bool(value, 'enabled'),
      type: _enum(value, 'type', PieGradientType.values),
      startColor: _optionalColor(
        value['startColor'],
        r'$.style.pieStyle.gradient.startColor',
      ),
      endColor: _optionalColor(
        value['endColor'],
        r'$.style.pieStyle.gradient.endColor',
      ),
      startLightnessShift: _double(value, 'startLightnessShift'),
      endLightnessShift: _double(value, 'endLightnessShift'),
      angleDegrees: _double(value, 'angleDegrees'),
    );

Map<String, Object?> _encodePieElevation(PieElevationStyle style) => {
  if (style.color != null) 'color': style.color!.toARGB32(),
  'blurRadius': _number(style.blurRadius),
  'spreadRadius': _number(style.spreadRadius),
  'offsetX': _number(style.offset.dx),
  'offsetY': _number(style.offset.dy),
  'opacity': _number(style.opacity),
};

PieElevationStyle _decodePieElevation(Map<String, Object?> value) =>
    PieElevationStyle(
      color: _optionalColor(value['color'], r'$.style.pieElevation.color'),
      blurRadius: _double(value, 'blurRadius'),
      spreadRadius: _double(value, 'spreadRadius'),
      offset: Offset(_double(value, 'offsetX'), _double(value, 'offsetY')),
      opacity: _double(value, 'opacity'),
    );

Map<String, Object?> _encodePieDataLabels(
  PieDataLabelConfig config, {
  JsonObjectValue? valueFormatter,
  JsonObjectValue? percentageFormatter,
}) => {
  'isVisible': config.isVisible,
  'position': config.position.name,
  'content': config.content.name,
  if (config.secondaryContent != null)
    'secondaryContent': config.secondaryContent!.name,
  if (config.secondaryContent != null)
    'secondaryPosition': config.secondaryPosition.name,
  'minimumShare': _number(config.minimumShare),
  'minimumSweepDegrees': _number(config.minimumSweepDegrees),
  'padding': _number(config.padding),
  'insideOffset': _number(config.insideOffset),
  'outsideOffset': _number(config.outsideOffset),
  'connectorLength': _number(config.connectorLength),
  'connectorWidth': _number(config.connectorWidth),
  if (config.connectorColor != null)
    'connectorColor': config.connectorColor!.toARGB32(),
  'collisionStrategy': config.collisionStrategy.name,
  if (config.calloutStyle != null)
    'calloutStyle': ChartStyleDocumentCodec.encodeLabelStyle(
      config.calloutStyle!,
    ).toJson(),
  if (config.secondaryCalloutStyle != null)
    'secondaryCalloutStyle': ChartStyleDocumentCodec.encodeLabelStyle(
      config.secondaryCalloutStyle!,
    ).toJson(),
  if (valueFormatter != null) 'valueFormatter': valueFormatter.toJson(),
  if (percentageFormatter != null)
    'percentageFormatter': percentageFormatter.toJson(),
};

PieDataLabelConfig _decodePieDataLabels(
  Map<String, Object?> value, {
  RadialValueFormatter? valueFormatter,
  RadialValueFormatter? percentageFormatter,
}) => PieDataLabelConfig(
  isVisible: _bool(value, 'isVisible'),
  position: _enum(value, 'position', PieDataLabelPosition.values),
  content: _enum(value, 'content', PieDataLabelContent.values),
  secondaryContent: _optionalEnum(
    value['secondaryContent'],
    PieDataLabelContent.values,
    r'$.style.dataLabels.secondaryContent',
  ),
  secondaryPosition:
      _optionalEnum(
        value['secondaryPosition'],
        PieDataLabelPosition.values,
        r'$.style.dataLabels.secondaryPosition',
      ) ??
      PieDataLabelPosition.inside,
  minimumShare: _double(value, 'minimumShare'),
  minimumSweepDegrees: _double(value, 'minimumSweepDegrees'),
  padding: _double(value, 'padding'),
  insideOffset: _optionalDouble(value['insideOffset']) ?? 0,
  outsideOffset: _optionalDouble(value['outsideOffset']) ?? 0,
  connectorLength: _double(value, 'connectorLength'),
  connectorWidth: _double(value, 'connectorWidth'),
  connectorColor: _optionalColor(
    value['connectorColor'],
    r'$.style.dataLabels.connectorColor',
  ),
  collisionStrategy: _enum(
    value,
    'collisionStrategy',
    PieDataLabelCollisionStrategy.values,
  ),
  calloutStyle: _optionalMap(value, 'calloutStyle') == null
      ? null
      : ChartStyleDocumentCodec.decodeLabelStyle(
          _jsonObject(
            _map(value, 'calloutStyle'),
            path: r'$.style.dataLabels.calloutStyle',
          ),
        ),
  secondaryCalloutStyle: _optionalMap(value, 'secondaryCalloutStyle') == null
      ? null
      : ChartStyleDocumentCodec.decodeLabelStyle(
          _jsonObject(
            _map(value, 'secondaryCalloutStyle'),
            path: r'$.style.dataLabels.secondaryCalloutStyle',
          ),
        ),
  valueFormatter: valueFormatter,
  percentageFormatter: percentageFormatter,
);

Map<String, Object?> _encodeRadialSliceGroupingConfig(
  RadialSliceGroupingConfig config,
) => {
  'minimumShare': _number(config.minimumShare),
  'minimumSourceCount': config.minimumSourceCount,
  'label': config.label,
  if (config.color != null) 'color': config.color!.toARGB32(),
  if (config.radiusAggregation != null)
    'radiusAggregation': config.radiusAggregation!.name,
};

RadialSliceGroupingConfig _decodeRadialSliceGroupingConfig(
  Map<String, Object?> value,
) => RadialSliceGroupingConfig(
  minimumShare: _double(value, 'minimumShare'),
  minimumSourceCount: _int(value, 'minimumSourceCount'),
  label: _string(value, 'label'),
  color: _optionalColor(value['color'], r'$.style.sliceGroupingConfig.color'),
  radiusAggregation: _optionalEnum(
    value['radiusAggregation'],
    RadialSliceRadiusAggregation.values,
    r'$.style.sliceGroupingConfig.radiusAggregation',
  ),
);

Map<String, Object?> _encodeLineStyle({
  required LineInterpolation interpolation,
  required double strokeWidth,
  required double tension,
  required bool showDataPointMarkers,
  required double dataPointMarkerRadius,
  required DataPointMarkerStyle dataPointMarkerStyle,
  required Color dataPointMarkerBackground,
  required double lineGlow,
  required DataPointLabelConfig? dataPointLabels,
  required SeriesInlineLabelConfig? inlineLabel,
  required List<double> dashPattern,
}) => {
  'interpolation': interpolation.name,
  'strokeWidth': _number(strokeWidth),
  'tension': _number(tension),
  'showDataPointMarkers': showDataPointMarkers,
  'dataPointMarkerRadius': _number(dataPointMarkerRadius),
  'dataPointMarkerStyle': dataPointMarkerStyle.name,
  'dataPointMarkerBackground': dataPointMarkerBackground.toARGB32(),
  'lineGlow': _number(lineGlow),
  if (dataPointLabels != null)
    'dataPointLabels': _encodeDataPointLabels(dataPointLabels),
  if (inlineLabel != null) 'inlineLabel': _encodeInlineLabel(inlineLabel),
  if (dashPattern.isNotEmpty)
    'dashPattern': [for (final interval in dashPattern) _number(interval)],
};

Map<String, Object?> _encodeDataPointLabels(DataPointLabelConfig config) => {
  'show': config.show,
  'position': config.position.name,
  'content': config.content.name,
  'offsetX': _number(config.offsetX),
  'offsetY': _number(config.offsetY),
  'markerGap': _number(config.markerGap),
  'collisionPolicy': config.collisionPolicy.name,
  'collisionPadding': _number(config.collisionPadding),
  'plotEdgeAware': config.plotEdgeAware,
  if (config.labelColor != null) 'labelColor': config.labelColor!.toARGB32(),
  'fontSize': _number(config.fontSize),
  'fontWeightIndex': FontWeight.values.indexOf(config.fontWeight),
  'showUnit': config.showUnit,
  if (config.background != null) 'background': config.background!.toARGB32(),
  'backgroundOpacity': _number(config.backgroundOpacity),
};

DataPointLabelConfig? _decodeDataPointLabels(Map<String, Object?>? value) {
  if (value == null) return null;
  return DataPointLabelConfig(
    show: _bool(value, 'show'),
    position: _enum(value, 'position', DataPointLabelPosition.values),
    content:
        _optionalEnum(
          value['content'],
          DataPointLabelContent.values,
          r'$.style.dataPointLabels.content',
        ) ??
        DataPointLabelContent.value,
    offsetX: _double(value, 'offsetX'),
    offsetY: _double(value, 'offsetY'),
    markerGap: _optionalDouble(value['markerGap']) ?? 4,
    collisionPolicy:
        _optionalEnum(
          value['collisionPolicy'],
          DataPointLabelCollisionPolicy.values,
          r'$.style.dataPointLabels.collisionPolicy',
        ) ??
        DataPointLabelCollisionPolicy.none,
    collisionPadding: _optionalDouble(value['collisionPadding']) ?? 2,
    plotEdgeAware: _bool(value, 'plotEdgeAware', fallback: true),
    labelColor: _optionalColor(
      value['labelColor'],
      r'$.style.dataPointLabels.labelColor',
    ),
    fontSize: _double(value, 'fontSize'),
    fontWeight: _fontWeight(value, 'fontWeightIndex'),
    showUnit: _bool(value, 'showUnit'),
    background: _optionalColor(
      value['background'],
      r'$.style.dataPointLabels.background',
    ),
    backgroundOpacity: _double(value, 'backgroundOpacity'),
  );
}

Map<String, Object?> _encodeInlineLabel(SeriesInlineLabelConfig config) => {
  'text': config.text,
  'position': config.position.name,
  'offsetY': _number(config.offsetY),
  if (config.color != null) 'color': config.color!.toARGB32(),
  'fontSize': _number(config.fontSize),
  'fontWeightIndex': FontWeight.values.indexOf(config.fontWeight),
  if (config.background != null)
    'background': {
      'color': config.background!.color.toARGB32(),
      if (config.background!.cornerRadius != null)
        'cornerRadius': _number(config.background!.cornerRadius!),
      'padding': _encodeInsets(config.background!.padding),
      if (config.background!.borderColor != null)
        'borderColor': config.background!.borderColor!.toARGB32(),
      'borderWidth': _number(config.background!.borderWidth),
    },
};

SeriesInlineLabelConfig? _decodeInlineLabel(Map<String, Object?>? value) {
  if (value == null) return null;
  final background = _optionalMap(value, 'background');
  return SeriesInlineLabelConfig(
    text: _string(value, 'text'),
    position: _enum(value, 'position', SeriesLabelPosition.values),
    offsetY: _double(value, 'offsetY'),
    color: _optionalColor(value['color'], r'$.style.inlineLabel.color'),
    fontSize: _double(value, 'fontSize'),
    fontWeight: _fontWeight(value, 'fontWeightIndex'),
    background: background == null
        ? null
        : SeriesLabelBackground(
            color: _color(background, 'color'),
            cornerRadius: _optionalDouble(background['cornerRadius']),
            padding: _decodeInsets(_map(background, 'padding')),
            borderColor: _optionalColor(
              background['borderColor'],
              r'$.style.inlineLabel.background.borderColor',
            ),
            borderWidth: _double(background, 'borderWidth'),
          ),
  );
}

JsonObjectValue? _encodeAxis(YAxisConfig? axis, {JsonObjectValue? formatter}) {
  if (axis == null) return null;
  return _jsonObject({
    'id': axis.id,
    'position': axis.position.name,
    if (axis.color != null) 'color': axis.color!.toARGB32(),
    if (axis.label != null) 'label': axis.label,
    if (axis.unit != null) 'unit': axis.unit,
    if (axis.min != null) 'min': _number(axis.min!),
    if (axis.max != null) 'max': _number(axis.max!),
    if (axis.renderMin != null) 'renderMin': _number(axis.renderMin!),
    if (axis.renderMax != null) 'renderMax': _number(axis.renderMax!),
    'visible': axis.visible,
    'showAxisLine': axis.showAxisLine,
    'showTicks': axis.showTicks,
    'showTickLabels': axis.showTickLabels,
    'showCrosshairLabel': axis.showCrosshairLabel,
    'crosshairLabelPosition': axis.crosshairLabelPosition.name,
    'labelDisplay': axis.labelDisplay.name,
    'minWidth': _number(axis.minWidth),
    'maxWidth': _number(axis.maxWidth),
    'tickLabelPadding': _number(axis.tickLabelPadding),
    'axisLabelPadding': _number(axis.axisLabelPadding),
    'axisMargin': _number(axis.axisMargin),
    if (axis.tickCount != null) 'tickCount': axis.tickCount,
    'showMinorTicks': axis.showMinorTicks,
    'minorTickCount': axis.minorTickCount,
    'minorTickLength': _number(axis.minorTickLength),
    if (formatter != null) 'formatter': formatter.toJson(),
  }, path: r'$.inlineAxis');
}

YAxisConfig? _decodeAxis(
  JsonObjectValue? value, {
  YAxisLabelFormatter? formatter,
}) {
  if (value == null) return null;
  final map = _objectMap(value);
  final id = _string(map, 'id');
  final position = _enum(map, 'position', YAxisPosition.values);
  final arguments = (
    color: _optionalColor(map['color'], r'$.inlineAxis.color'),
    label: _optionalString(map['label']),
    unit: _optionalString(map['unit']),
    min: _optionalDouble(map['min']),
    max: _optionalDouble(map['max']),
    renderMin: _optionalDouble(map['renderMin']),
    renderMax: _optionalDouble(map['renderMax']),
    visible: _bool(map, 'visible'),
    showAxisLine: _bool(map, 'showAxisLine'),
    showTicks: _bool(map, 'showTicks'),
    showTickLabels: _bool(map, 'showTickLabels'),
    showCrosshairLabel: _bool(map, 'showCrosshairLabel'),
    crosshairLabelPosition: _enum(
      map,
      'crosshairLabelPosition',
      CrosshairLabelPosition.values,
    ),
    labelDisplay: _enum(map, 'labelDisplay', AxisLabelDisplay.values),
    minWidth: _double(map, 'minWidth'),
    maxWidth: _double(map, 'maxWidth'),
    tickLabelPadding: _double(map, 'tickLabelPadding'),
    axisLabelPadding: _double(map, 'axisLabelPadding'),
    axisMargin: _double(map, 'axisMargin'),
    tickCount: _optionalInt(map['tickCount']),
    showMinorTicks: _bool(map, 'showMinorTicks'),
    minorTickCount: _int(map, 'minorTickCount'),
    minorTickLength: _double(map, 'minorTickLength'),
  );
  final axis = YAxisConfig(
    position: position,
    color: arguments.color,
    label: arguments.label,
    unit: arguments.unit,
    min: arguments.min,
    max: arguments.max,
    renderMin: arguments.renderMin,
    renderMax: arguments.renderMax,
    visible: arguments.visible,
    showAxisLine: arguments.showAxisLine,
    showTicks: arguments.showTicks,
    showTickLabels: arguments.showTickLabels,
    showCrosshairLabel: arguments.showCrosshairLabel,
    crosshairLabelPosition: arguments.crosshairLabelPosition,
    labelDisplay: arguments.labelDisplay,
    minWidth: arguments.minWidth,
    maxWidth: arguments.maxWidth,
    tickLabelPadding: arguments.tickLabelPadding,
    axisLabelPadding: arguments.axisLabelPadding,
    axisMargin: arguments.axisMargin,
    tickCount: arguments.tickCount,
    showMinorTicks: arguments.showMinorTicks,
    minorTickCount: arguments.minorTickCount,
    minorTickLength: arguments.minorTickLength,
    labelFormatter: formatter,
  );
  return id.isEmpty ? axis : axis.copyWith(id: id);
}

Object _number(double value) => ChartNumberDocument.fromDouble(value).toJson();

JsonObjectValue _jsonObject(
  Map<String, Object?> value, {
  required String path,
}) => JsonValue.fromJson(value, path: path) as JsonObjectValue;

JsonObjectValue? _jsonObjectOrNull(
  Map<String, dynamic>? value, {
  required String path,
}) => value == null ? null : _jsonObject(value, path: path);

Map<String, Object?> _objectMap(JsonObjectValue? value) => value == null
    ? <String, Object?>{}
    : (value.toJson() as Map<String, Object?>);

Map<String, dynamic>? _dynamicMap(JsonObjectValue? value) =>
    value == null ? null : Map<String, dynamic>.from(_objectMap(value));

Map<String, Object?> _map(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is Map<String, Object?>) return value;
  if (value is Map) return Map<String, Object?>.from(value);
  throw FormatException('Expected object at $key.');
}

Map<String, Object?>? _optionalMap(Map<String, Object?> map, String key) =>
    map[key] == null ? null : _map(map, key);

String _string(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is String) return value;
  throw FormatException('Expected string at $key.');
}

String? _optionalString(Object? value) {
  if (value == null || value is String) return value as String?;
  throw const FormatException('Expected optional string.');
}

bool _bool(Map<String, Object?> map, String key, {bool? fallback}) {
  final value = map[key];
  if (value == null && fallback != null) return fallback;
  if (value is bool) return value;
  throw FormatException('Expected bool at $key.');
}

int _int(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is int) return value;
  throw FormatException('Expected integer at $key.');
}

int? _optionalInt(Object? value) {
  if (value == null || value is int) return value as int?;
  throw const FormatException('Expected optional integer.');
}

bool? _optionalBool(Object? value) {
  if (value == null || value is bool) return value as bool?;
  throw const FormatException('Expected optional boolean.');
}

double _double(Map<String, Object?> map, String key) =>
    _optionalDouble(map[key]) ??
    (throw FormatException('Expected chart number at $key.'));

double? _optionalDouble(Object? value) =>
    value == null ? null : ChartNumberDocument.fromJson(value).asDouble;

List<double?> _decodeOptionalDoubleList(Object? value, String path) {
  if (value == null) return const [];
  if (value is! List) {
    throw FormatException('Expected number list at $path.');
  }
  return [
    for (var index = 0; index < value.length; index++)
      switch (value[index]) {
        null => null,
        final item => ChartNumberDocument.fromJson(item).asDouble,
      },
  ];
}

List<double> _decodeDashPattern(Object? value) {
  if (value == null) return const [];
  if (value is! List || value.length.isOdd) {
    throw const FormatException(
      'Expected an even-length path dash pattern list.',
    );
  }
  final result = <double>[];
  for (var index = 0; index < value.length; index++) {
    final interval = ChartNumberDocument.fromJson(value[index]).asDouble;
    if (!interval.isFinite || interval <= 0) {
      throw FormatException(
        'Expected a positive finite path dash interval at index $index.',
      );
    }
    result.add(interval);
  }
  return result;
}

Set<int> _decodeIntSet(Object? value, String path) {
  if (value == null) return const {};
  if (value is! List) throw FormatException('Expected integer list at $path.');
  return {
    for (var index = 0; index < value.length; index++)
      value[index] is int
          ? value[index] as int
          : throw FormatException('Expected integer at $path[$index].'),
  };
}

Color _color(Map<String, Object?> map, String key) =>
    _optionalColor(map[key], r'$.style.' + key) ??
    (throw FormatException('Expected color at $key.'));

Color? _optionalColor(Object? value, String path) {
  if (value == null) return null;
  if (value is int) return Color(value);
  throw FormatException('Expected ARGB color integer at $path.');
}

T _enum<T extends Enum>(Map<String, Object?> map, String key, List<T> values) =>
    _optionalEnum(map[key], values, r'$.style.' + key) ??
    (throw FormatException('Expected enum at $key.'));

T? _optionalEnum<T extends Enum>(Object? value, List<T> values, String path) {
  if (value == null) return null;
  if (value is! String) throw FormatException('Expected enum name at $path.');
  for (final candidate in values) {
    if (candidate.name == value) return candidate;
  }
  throw FormatException('Unknown enum value "$value" at $path.');
}

FontWeight _fontWeight(Map<String, Object?> map, String key) {
  final index = _int(map, key);
  if (index < 0 || index >= FontWeight.values.length) {
    throw FormatException('Invalid font weight index at $key.');
  }
  return FontWeight.values[index];
}

Map<String, Object?> _encodeInsets(EdgeInsets insets) => {
  'left': _number(insets.left),
  'top': _number(insets.top),
  'right': _number(insets.right),
  'bottom': _number(insets.bottom),
};

EdgeInsets _decodeInsets(Map<String, Object?> value) => EdgeInsets.fromLTRB(
  _double(value, 'left'),
  _double(value, 'top'),
  _double(value, 'right'),
  _double(value, 'bottom'),
);

ChartAnnotationDocument _encodeAnnotationOrThrow(
  ChartAnnotation annotation,
  ChartModelCodecContext context,
) {
  final result = ChartAnnotationDocumentCodec.encodeWithContext(
    annotation,
    context,
  );
  return switch (result) {
    ChartArtifactSuccess<ChartAnnotationDocument>() => result.value,
    ChartArtifactFailure<ChartAnnotationDocument>() =>
      throw _NestedCodecException(result.error),
  };
}

ChartAnnotation _decodeAnnotationOrThrow(ChartAnnotationDocument document) {
  final result = ChartAnnotationDocumentCodec.decode(document);
  return switch (result) {
    ChartArtifactSuccess<ChartAnnotation>() => result.value,
    ChartArtifactFailure<ChartAnnotation>() => throw _NestedCodecException(
      result.error,
    ),
  };
}

class _RuntimeBindingException implements Exception {
  const _RuntimeBindingException(this.message, this.path);

  final String message;
  final String path;
}

class _UnsupportedModelException implements Exception {
  const _UnsupportedModelException(this.message, this.path);

  final String message;
  final String path;
}

class _NestedCodecException implements Exception {
  const _NestedCodecException(this.error);

  final ChartArtifactError error;
}
