import 'package:flutter/foundation.dart' show internal;
import 'package:flutter/material.dart';

import '../models/chart_annotation.dart';
import '../models/chart_data_point.dart';
import '../models/chart_series.dart';
import '../models/data_point_label_config.dart';
import '../models/segment_style.dart';
import '../models/series_inline_label_config.dart';
import '../models/y_axis_config.dart';
import '../models/y_axis_position.dart';
import 'chart_annotation_document.dart';
import 'chart_annotation_document_codec.dart';
import 'chart_artifact_diagnostics.dart';
import 'chart_data_payload.dart';
import 'chart_model_codec_context.dart';
import 'json_value.dart';

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
  }) => encodeWithContext(
    series,
    ChartModelCodecContext(),
    inlineAxisFormatter: inlineAxisFormatter,
  );

  @internal
  static ChartArtifactResult<ChartSeriesDocument> encodeWithContext(
    ChartSeries series,
    ChartModelCodecContext context, {
    JsonObjectValue? inlineAxisFormatter,
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
          style: _jsonObject(_encodeSeriesStyle(series), path: r'$.style'),
          metadata: _jsonObjectOrNull(series.metadata, path: r'$.metadata'),
          annotations: [
            for (final annotation in series.annotations)
              _encodeAnnotationOrThrow(annotation, context),
          ],
          data: InlinePointPayload([
            for (var index = 0; index < series.points.length; index++)
              _encodePoint(series.points[index], index),
          ]),
          requiredCapabilities: {'series.${_typeOf(series)}'},
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
  }) {
    try {
      final payload = document.data;
      if (payload is! InlinePointPayload) {
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
        ),
        final type => throw _UnsupportedModelException(
          'Unsupported built-in series type: $type.',
          r'$.type',
        ),
      };

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

String _typeOf(ChartSeries series) => switch (series) {
  LineChartSeries() => 'line',
  ScatterChartSeries() => 'scatter',
  AreaChartSeries() => 'area',
  BarChartSeries() => 'bar',
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

Map<String, Object?> _encodeSeriesStyle(ChartSeries series) {
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
        ..['baselineValue'] = series.baselineValue == null
            ? null
            : _number(series.baselineValue!)
        ..['aboveBaselineFillColor'] = series.aboveBaselineFillColor?.toARGB32()
        ..['belowBaselineFillColor'] = series.belowBaselineFillColor
            ?.toARGB32();
    case BarChartSeries():
      result
        ..['barWidthPercent'] = series.barWidthPercent == null
            ? null
            : _number(series.barWidthPercent!)
        ..['barWidthPixels'] = series.barWidthPixels == null
            ? null
            : _number(series.barWidthPixels!)
        ..['minWidth'] = _number(series.minWidth)
        ..['maxWidth'] = _number(series.maxWidth);
    case ChartSeries():
      break;
  }
  result.removeWhere((_, value) => value == null);
  return result;
}

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
