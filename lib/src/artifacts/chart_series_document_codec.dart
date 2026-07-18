import 'package:flutter/foundation.dart' show internal;
import 'package:flutter/material.dart';

import '../models/chart_annotation.dart';
import '../models/bar_chart_style.dart';
import '../models/chart_data_point.dart';
import '../models/chart_series.dart';
import '../models/data_point_label_config.dart';
import '../models/donut_chart_config.dart';
import '../models/donut_chart_series.dart';
import '../models/pie_chart_config.dart';
import '../models/pie_chart_series.dart';
import '../models/path_animation_style.dart';
import '../models/radial_category_series.dart';
import '../models/segment_style.dart';
import '../models/series_inline_label_config.dart';
import '../models/y_axis_config.dart';
import '../models/y_axis_position.dart';
import 'chart_annotation_document.dart';
import 'chart_annotation_document_codec.dart';
import 'chart_artifact_diagnostics.dart';
import 'chart_data_payload.dart';
import 'chart_data_storage.dart';
import 'chart_model_codec_context.dart';
import 'chart_style_document_codec.dart';
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
            if (series is BarChartSeries && series.barStyle.pattern != null)
              'series.bar.pattern.v1',
            if (series is BarChartSeries && series.bulletStyle != null)
              'series.bar.bullet.v1',
            if (series is BarChartSeries && series.lollipopStyle != null)
              'series.bar.lollipop.v1',
            if (series is BarChartSeries &&
                series.layoutMode == BarLayoutMode.divergingStacked)
              'series.bar.diverging.v1',
            if (series is PieChartSeries) 'series.pie.style.v2',
            if (series is PieChartSeries) 'series.pie.corner-treatment.v1',
            if (series is PieChartSeries && series.hasVariableSliceRadius)
              'series.pie.variable-radius.v1',
            if (series is DonutChartSeries) 'series.donut.style.v1',
            if (series is DonutChartSeries && series.centerContent.isVisible)
              'series.donut.center-content.v1',
            if (series is DonutChartSeries && series.hasVariableSliceRadius)
              'series.donut.variable-radius.v1',
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
            if ((series is LineChartSeries || series is AreaChartSeries) &&
                _pathAnimationFor(series) != const PathAnimationStyle())
              'series.path-motion.v1',
            if ((series is LineChartSeries || series is AreaChartSeries) &&
                _hasNonDefaultPathTiming(_pathAnimationFor(series)!))
              'series.path-motion-timing.v1',
            if (series is AreaChartSeries && series.fillGradient != null)
              'series.area.gradient.v1',
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
      final points = payload.points.map(_decodePoint).toList(growable: false);
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
          markerRadius: _double(style, 'markerRadius'),
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
        'pie' => PieChartSeries(
          id: document.id,
          name: document.name,
          points: points,
          color: _optionalColor(style['color'], r'$.style.color'),
          metadata: metadata,
          unit: document.unit,
          pieStyle: _decodePieStyle(_map(style, 'pieStyle')),
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
          donutStyle: _decodeDonutStyle(_map(style, 'donutStyle')),
          centerContent: _optionalMap(style, 'centerContent') == null
              ? DonutCenterContent.hidden
              : _decodeDonutCenterContent(
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
  BarChartSeries() => 'bar',
  PieChartSeries() => 'pie',
  DonutChartSeries() => 'donut',
  ChartSeries() => 'base',
};

ChartPointDocument _encodePoint(ChartDataPoint point, int index) =>
    ChartPointDocument(
      x: ChartNumberDocument.fromDouble(point.x),
      y: ChartNumberDocument.fromDouble(point.y),
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
            }, path: r'$.data.points[$index].segmentStyle'),
      pointStyle: point.pointStyle == null
          ? null
          : _jsonObject({
              if (point.pointStyle!.color != null)
                'color': point.pointStyle!.color!.toARGB32(),
              if (point.pointStyle!.size != null)
                'size': _number(point.pointStyle!.size!),
            }, path: r'$.data.points[$index].pointStyle'),
    );

ChartDataPoint _decodePoint(ChartPointDocument point) {
  final segmentStyle = _objectMap(point.segmentStyle);
  final pointStyle = _objectMap(point.pointStyle);
  return ChartDataPoint(
    x: point.x.asDouble,
    y: point.y.asDouble,
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
          ),
    pointStyle: point.pointStyle == null
        ? null
        : PointStyle(
            color: _optionalColor(
              pointStyle['color'],
              r'$.data.point.pointStyle.color',
            ),
            size: _optionalDouble(pointStyle['size']),
          ),
  );
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
        ),
      );
      result['pathAnimation'] = _encodePathAnimation(series.pathAnimation);
    case ScatterChartSeries():
      result['markerRadius'] = _number(series.markerRadius);
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
    case PieChartSeries():
      result
        ..['pieStyle'] = _encodePieStyle(series.pieStyle)
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
        ..['centerContent'] = _encodeDonutCenterContent(
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
    case ChartSeries():
      break;
  }
  result.removeWhere((_, value) => value == null);
  return result;
}

PathAnimationStyle? _pathAnimationFor(ChartSeries series) => switch (series) {
  LineChartSeries() => series.pathAnimation,
  AreaChartSeries() => series.pathAnimation,
  _ => null,
};

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

Map<String, Object?> _encodeDonutCenterContent(
  DonutCenterContent content, {
  JsonObjectValue? valueFormatter,
}) => {
  'isVisible': content.isVisible,
  if (content.label != null) 'label': content.label,
  'valueMode': content.valueMode.name,
  if (content.customValue != null) 'customValue': content.customValue,
  if (content.labelStyle != null)
    'labelStyle': ChartStyleDocumentCodec.encodeLabelStyle(
      content.labelStyle!,
    ).toJson(),
  if (content.valueStyle != null)
    'valueStyle': ChartStyleDocumentCodec.encodeLabelStyle(
      content.valueStyle!,
    ).toJson(),
  if (valueFormatter != null) 'valueFormatter': valueFormatter.toJson(),
};

DonutCenterContent _decodeDonutCenterContent(
  Map<String, Object?> value, {
  RadialValueFormatter? valueFormatter,
}) => DonutCenterContent(
  isVisible: _bool(value, 'isVisible'),
  label: _optionalString(value['label']),
  valueMode: _enum(value, 'valueMode', DonutCenterValueMode.values),
  customValue: _optionalString(value['customValue']),
  labelStyle: _optionalMap(value, 'labelStyle') == null
      ? null
      : ChartStyleDocumentCodec.decodeLabelStyle(
          _jsonObject(
            _map(value, 'labelStyle'),
            path: r'$.style.centerContent.labelStyle',
          ),
        ),
  valueStyle: _optionalMap(value, 'valueStyle') == null
      ? null
      : ChartStyleDocumentCodec.decodeLabelStyle(
          _jsonObject(
            _map(value, 'valueStyle'),
            path: r'$.style.centerContent.valueStyle',
          ),
        ),
  valueFormatter: valueFormatter,
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
  'minimumShare': _number(config.minimumShare),
  'minimumSweepDegrees': _number(config.minimumSweepDegrees),
  'padding': _number(config.padding),
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
  minimumShare: _double(value, 'minimumShare'),
  minimumSweepDegrees: _double(value, 'minimumSweepDegrees'),
  padding: _double(value, 'padding'),
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
};

Map<String, Object?> _encodeDataPointLabels(DataPointLabelConfig config) => {
  'show': config.show,
  'position': config.position.name,
  'offsetX': _number(config.offsetX),
  'offsetY': _number(config.offsetY),
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
    offsetX: _double(value, 'offsetX'),
    offsetY: _double(value, 'offsetY'),
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
