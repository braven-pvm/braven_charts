import 'package:flutter/foundation.dart' show internal;
import 'package:flutter/material.dart';

import '../models/annotation_style.dart';
import '../models/chart_annotation.dart';
import '../models/chart_series.dart';
import '../models/enums.dart';
import 'chart_annotation_document.dart';
import 'chart_artifact_diagnostics.dart';
import 'chart_data_payload.dart';
import 'chart_data_storage.dart';
import 'chart_model_codec_context.dart';
import 'chart_series_document_codec.dart';
import 'chart_style_document_codec.dart';
import 'json_value.dart';

/// Audited adapter for all built-in [ChartAnnotation] subtypes.
abstract final class ChartAnnotationDocumentCodec {
  static ChartArtifactResult<ChartAnnotationDocument> encode(
    ChartAnnotation annotation, {
    ChartDataStorage dataStorage = ChartDataStorage.inlinePoints,
  }) => encodeWithContext(
    annotation,
    ChartModelCodecContext(dataStorage: dataStorage),
  );

  @internal
  static ChartArtifactResult<ChartAnnotationDocument> encodeWithContext(
    ChartAnnotation annotation,
    ChartModelCodecContext context,
  ) {
    var entered = false;
    try {
      context.enter(annotation);
      entered = true;
      if (annotation case LegendAnnotation(onSeriesToggle: != null)) {
        throw const _CodecException(
          ChartArtifactDiagnosticCodes.runtimeBindingRequired,
          'Legend toggle callbacks belong in runtime bindings.',
          r'$.payload.onSeriesToggle',
        );
      }
      final type = _typeOf(annotation);
      return ChartArtifactSuccess(
        value: ChartAnnotationDocument(
          type: type,
          id: annotation.id,
          payload: _object(_encodePayload(annotation, context)),
          requiredCapabilities: _requiredCapabilities(annotation),
        ),
      );
    } on _CodecException catch (error) {
      return ChartArtifactFailure(error: error.error);
    } on ChartModelGraphException catch (error) {
      return ChartArtifactFailure(
        error: ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.validationLimitExceeded,
          message: error.message,
          path: r'$.payload',
        ),
      );
    } on UnsupportedError catch (error) {
      return ChartArtifactFailure(
        error: ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.unsupportedModelType,
          message: error.message?.toString() ?? 'Unsupported annotation style.',
          path: r'$.payload.style.textStyle',
        ),
      );
    } on FormatException catch (error) {
      return ChartArtifactFailure(
        error: ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.metadataValueNotJsonSafe,
          message: error.message,
          path: r'$.payload',
        ),
      );
    } finally {
      if (entered) context.exit(annotation);
    }
  }

  static ChartArtifactResult<ChartAnnotation> decode(
    ChartAnnotationDocument document,
  ) {
    try {
      final payload = _map(document.payload.toJson());
      final common = _decodeCommon(payload);
      final annotation = switch (document.type) {
        'point' => _decodePoint(document.id, payload, common),
        'range' => RangeAnnotation(
          id: document.id,
          label: common.label,
          style: common.style,
          allowDragging: common.allowDragging,
          allowEditing: common.allowEditing,
          zIndex: common.zIndex,
          snapToValue: common.snapToValue,
          snapIncrement: common.snapIncrement,
          snapTolerance: _double(payload, 'snapTolerance'),
          startX: _optionalDouble(payload['startX']),
          endX: _optionalDouble(payload['endX']),
          startY: _optionalDouble(payload['startY']),
          endY: _optionalDouble(payload['endY']),
          seriesId: _optionalString(payload['seriesId']),
          fillColor: _optionalColor(payload['fillColor']),
          borderColor: _optionalColor(payload['borderColor']),
          labelPosition: _enum(
            payload,
            'labelPosition',
            AnnotationLabelPosition.values,
          ),
          labelMargin: _double(payload, 'labelMargin'),
        ),
        'text' => _decodeText(document.id, payload, common),
        'threshold' => _decodeThreshold(document.id, payload, common),
        'pin' => _decodePin(document.id, payload, common),
        'trend' => _decodeTrend(document.id, payload, common),
        'chord' => _decodeChord(document.id, payload, common),
        'legend' => _decodeLegend(document.id, payload, common),
        final type => throw _CodecException(
          ChartArtifactDiagnosticCodes.unsupportedModelType,
          'Unsupported built-in annotation type: $type.',
          r'$.type',
        ),
      };
      return ChartArtifactSuccess(value: annotation);
    } on _CodecException catch (error) {
      return ChartArtifactFailure(error: error.error);
    } on Object catch (error) {
      return ChartArtifactFailure(
        error: ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.invalidArtifact,
          message: 'Invalid built-in annotation document: $error',
          path: r'$.payload',
        ),
      );
    }
  }
}

String _typeOf(ChartAnnotation annotation) => switch (annotation) {
  PointAnnotation() => 'point',
  RangeAnnotation() => 'range',
  TextAnnotation() => 'text',
  ThresholdAnnotation() => 'threshold',
  PinAnnotation() => 'pin',
  TrendAnnotation() => 'trend',
  ChordAnnotation() => 'chord',
  LegendAnnotation() => 'legend',
};

Set<String> _requiredCapabilities(ChartAnnotation annotation) {
  final result = <String>{'annotation.${_typeOf(annotation)}'};
  if (annotation case LegendAnnotation()) {
    if (annotation.sizeScale != null) {
      result.add('annotation.legend.size-scale.v1');
    }
    if (annotation.colorScale != null) {
      result.add('annotation.legend.color-scale.v1');
    }
    if (annotation.opacityScale != null) {
      result.add('annotation.legend.opacity-scale.v1');
    }
    for (final series in annotation.series) {
      result.add('series.${_seriesTypeOf(series)}');
      for (final nested in series.annotations) {
        result.addAll(_requiredCapabilities(nested));
      }
    }
    for (final trend in annotation.trendAnnotations) {
      result.addAll(_requiredCapabilities(trend));
    }
  }
  return result;
}

String _seriesTypeOf(ChartSeries series) => switch (series) {
  LineChartSeries() => 'line',
  ScatterChartSeries() => 'scatter',
  AreaChartSeries() => 'area',
  BarChartSeries() => 'bar',
  ChartSeries() => 'base',
};

Map<String, Object?> _encodePayload(
  ChartAnnotation annotation,
  ChartModelCodecContext context,
) {
  final payload = <String, Object?>{
    if (annotation.label != null) 'label': annotation.label,
    'style': ChartStyleDocumentCodec.encodeAnnotationStyle(
      annotation.style,
    ).toJson(),
    'allowDragging': annotation.allowDragging,
    'allowEditing': annotation.allowEditing,
    'zIndex': annotation.zIndex,
    'snapToValue': annotation.snapToValue,
    'snapIncrement': _number(annotation.snapIncrement),
  };
  switch (annotation) {
    case PointAnnotation():
      payload.addAll({
        'coordinateSpace': 'data',
        'seriesId': annotation.seriesId,
        'dataPointIndex': annotation.dataPointIndex,
        'offset': _encodeOffset(annotation.offset),
        'markerShape': annotation.markerShape.name,
        'markerSize': _number(annotation.markerSize),
        'markerColor': annotation.markerColor.toARGB32(),
        'labelMargin': _number(annotation.labelMargin),
      });
    case RangeAnnotation():
      payload.addAll({
        'coordinateSpace': 'data',
        if (annotation.startX != null) 'startX': _number(annotation.startX!),
        if (annotation.endX != null) 'endX': _number(annotation.endX!),
        if (annotation.startY != null) 'startY': _number(annotation.startY!),
        if (annotation.endY != null) 'endY': _number(annotation.endY!),
        'snapTolerance': _number(annotation.snapTolerance),
        if (annotation.seriesId != null) 'seriesId': annotation.seriesId,
        if (annotation.fillColor != null)
          'fillColor': annotation.fillColor!.toARGB32(),
        if (annotation.borderColor != null)
          'borderColor': annotation.borderColor!.toARGB32(),
        'labelPosition': annotation.labelPosition.name,
        'labelMargin': _number(annotation.labelMargin),
      });
    case TextAnnotation():
      payload.addAll({
        'coordinateSpace': 'widgetLogicalPixels',
        if (annotation.text != null) 'text': annotation.text,
        if (annotation.richTextDelta != null)
          'richTextDelta': annotation.richTextDelta,
        'position': _encodeOffset(annotation.position),
        'anchor': annotation.anchor.name,
        if (annotation.backgroundColor != null)
          'backgroundColor': annotation.backgroundColor!.toARGB32(),
        if (annotation.borderColor != null)
          'borderColor': annotation.borderColor!.toARGB32(),
      });
    case ThresholdAnnotation():
      payload.addAll({
        'coordinateSpace': 'data',
        'axis': annotation.axis.name,
        'value': _number(annotation.value),
        if (annotation.seriesId != null) 'seriesId': annotation.seriesId,
        'lineColor': annotation.lineColor.toARGB32(),
        'lineWidth': _number(annotation.lineWidth),
        if (annotation.dashPattern != null)
          'dashPattern': annotation.dashPattern!.map(_number).toList(),
        'labelPosition': annotation.labelPosition.name,
        'labelMargin': _number(annotation.labelMargin),
        'elevation': _number(annotation.elevation),
      });
    case PinAnnotation():
      payload.addAll({
        'coordinateSpace': 'data',
        'x': _number(annotation.x),
        'y': _number(annotation.y),
        'markerShape': annotation.markerShape.name,
        'markerSize': _number(annotation.markerSize),
        'markerColor': annotation.markerColor.toARGB32(),
        'labelMargin': _number(annotation.labelMargin),
      });
    case TrendAnnotation():
      payload.addAll({
        'coordinateSpace': 'data',
        'seriesId': annotation.seriesId,
        'trendType': annotation.trendType.name,
        if (annotation.windowSize != null) 'windowSize': annotation.windowSize,
        'degree': annotation.degree,
        'lineColor': annotation.lineColor.toARGB32(),
        'lineWidth': _number(annotation.lineWidth),
        if (annotation.dashPattern != null)
          'dashPattern': annotation.dashPattern!.map(_number).toList(),
        'elevation': _number(annotation.elevation),
      });
    case ChordAnnotation():
      payload.addAll({
        'coordinateSpace': 'data',
        'seriesId': annotation.seriesId,
        'startIndex': annotation.startIndex,
        'endIndex': annotation.endIndex,
        'lineColor': annotation.lineColor.toARGB32(),
        'lineWidth': _number(annotation.lineWidth),
        if (annotation.dashPattern != null)
          'dashPattern': annotation.dashPattern!.map(_number).toList(),
        'elevation': _number(annotation.elevation),
        if (annotation.perpendicularIndex != null)
          'perpendicularIndex': annotation.perpendicularIndex,
        if (annotation.perpendicularLabel != null)
          'perpendicularLabel': annotation.perpendicularLabel,
        'perpendicularLabelOffset': _encodeOffset(
          annotation.perpendicularLabelOffset,
        ),
        if (annotation.perpendicularLabelStyle != null)
          'perpendicularLabelStyle':
              ChartStyleDocumentCodec.encodeAnnotationStyle(
                annotation.perpendicularLabelStyle!,
              ).toJson(),
        if (annotation.perpendicularLineColor != null)
          'perpendicularLineColor': annotation.perpendicularLineColor!
              .toARGB32(),
        if (annotation.perpendicularLineWidth != null)
          'perpendicularLineWidth': _number(annotation.perpendicularLineWidth!),
        if (annotation.perpendicularDashPattern != null)
          'perpendicularDashPattern': annotation.perpendicularDashPattern!
              .map(_number)
              .toList(),
        if (annotation.perpendicularElevation != null)
          'perpendicularElevation': _number(annotation.perpendicularElevation!),
      });
    case LegendAnnotation():
      payload.addAll({
        'coordinateSpace': 'widgetLogicalPixels',
        'series': [
          for (final series in annotation.series)
            _encodeSeriesOrThrow(series, context).toJson(),
        ],
        'trendAnnotations': [
          for (final trend in annotation.trendAnnotations)
            _encodeAnnotationOrThrow(trend, context).toJson(),
        ],
        if (annotation.sizeScale != null)
          'sizeScale': _encodeLegendSizeScale(annotation.sizeScale!),
        if (annotation.colorScale != null)
          'colorScale': _encodeLegendColorScale(annotation.colorScale!),
        if (annotation.opacityScale != null)
          'opacityScale': _encodeLegendOpacityScale(annotation.opacityScale!),
        'legendStyle': ChartStyleDocumentCodec.encodeLegendStyle(
          annotation.legendStyle,
        ).toJson(),
        'hiddenSeriesIds': annotation.hiddenSeriesIds.toList()..sort(),
        if (annotation.customPosition != null)
          'customPosition': _encodeOffset(annotation.customPosition!),
      });
  }
  return payload;
}

typedef _CommonAnnotationFields = ({
  String? label,
  AnnotationStyle style,
  bool allowDragging,
  bool allowEditing,
  int zIndex,
  bool snapToValue,
  double snapIncrement,
});

_CommonAnnotationFields _decodeCommon(Map<String, Object?> payload) => (
  label: _optionalString(payload['label']),
  style: ChartStyleDocumentCodec.decodeAnnotationStyle(
    JsonValue.fromJson(_requiredMap(payload, 'style')) as JsonObjectValue,
  ),
  allowDragging: _bool(payload, 'allowDragging'),
  allowEditing: _bool(payload, 'allowEditing'),
  zIndex: _int(payload, 'zIndex'),
  snapToValue: _bool(payload, 'snapToValue'),
  snapIncrement: _double(payload, 'snapIncrement'),
);

PointAnnotation _decodePoint(
  String id,
  Map<String, Object?> payload,
  _CommonAnnotationFields common,
) {
  _requireDefaultSnap(common, 'point');
  return PointAnnotation(
    id: id,
    label: common.label,
    style: common.style,
    allowDragging: common.allowDragging,
    allowEditing: common.allowEditing,
    zIndex: common.zIndex,
    seriesId: _string(payload, 'seriesId'),
    dataPointIndex: _int(payload, 'dataPointIndex'),
    offset: _decodeOffset(_requiredMap(payload, 'offset')),
    markerShape: _enum(payload, 'markerShape', MarkerShape.values),
    markerSize: _double(payload, 'markerSize'),
    markerColor: _color(payload, 'markerColor'),
    labelMargin: _double(payload, 'labelMargin'),
  );
}

TextAnnotation _decodeText(
  String id,
  Map<String, Object?> payload,
  _CommonAnnotationFields common,
) {
  _requireDefaultSnap(common, 'text');
  final position = _decodeOffset(_requiredMap(payload, 'position'));
  final anchor = _enum(payload, 'anchor', AnnotationAnchor.values);
  final background = _optionalColor(payload['backgroundColor']);
  final border = _optionalColor(payload['borderColor']);
  final rich = payload['richTextDelta'];
  if (rich != null) {
    if (rich is! List) throw const FormatException('Expected rich-text list.');
    return TextAnnotation.rich(
      id: id,
      label: common.label,
      style: common.style,
      allowDragging: common.allowDragging,
      allowEditing: common.allowEditing,
      zIndex: common.zIndex,
      richTextDelta: List<dynamic>.from(rich),
      position: position,
      anchor: anchor,
      backgroundColor: background,
      borderColor: border,
    );
  }
  return TextAnnotation(
    id: id,
    label: common.label,
    style: common.style,
    allowDragging: common.allowDragging,
    allowEditing: common.allowEditing,
    zIndex: common.zIndex,
    text: _string(payload, 'text'),
    position: position,
    anchor: anchor,
    backgroundColor: background,
    borderColor: border,
  );
}

ThresholdAnnotation _decodeThreshold(
  String id,
  Map<String, Object?> payload,
  _CommonAnnotationFields common,
) {
  _requireDefaultSnap(common, 'threshold');
  return ThresholdAnnotation(
    id: id,
    label: common.label,
    style: common.style,
    allowDragging: common.allowDragging,
    allowEditing: common.allowEditing,
    zIndex: common.zIndex,
    axis: _enum(payload, 'axis', AnnotationAxis.values),
    value: _double(payload, 'value'),
    seriesId: _optionalString(payload['seriesId']),
    lineColor: _color(payload, 'lineColor'),
    lineWidth: _double(payload, 'lineWidth'),
    dashPattern: _optionalDoubleList(payload['dashPattern']),
    labelPosition: _enum(
      payload,
      'labelPosition',
      AnnotationLabelPosition.values,
    ),
    labelMargin: _double(payload, 'labelMargin'),
    elevation: _double(payload, 'elevation'),
  );
}

PinAnnotation _decodePin(
  String id,
  Map<String, Object?> payload,
  _CommonAnnotationFields common,
) {
  _requireDefaultSnap(common, 'pin');
  return PinAnnotation(
    id: id,
    label: common.label,
    style: common.style,
    allowDragging: common.allowDragging,
    allowEditing: common.allowEditing,
    zIndex: common.zIndex,
    x: _double(payload, 'x'),
    y: _double(payload, 'y'),
    markerShape: _enum(payload, 'markerShape', MarkerShape.values),
    markerSize: _double(payload, 'markerSize'),
    markerColor: _color(payload, 'markerColor'),
    labelMargin: _double(payload, 'labelMargin'),
  );
}

TrendAnnotation _decodeTrend(
  String id,
  Map<String, Object?> payload,
  _CommonAnnotationFields common,
) {
  _requireDefaultSnap(common, 'trend');
  return TrendAnnotation(
    id: id,
    label: common.label,
    style: common.style,
    allowDragging: common.allowDragging,
    allowEditing: common.allowEditing,
    zIndex: common.zIndex,
    seriesId: _string(payload, 'seriesId'),
    trendType: _enum(payload, 'trendType', TrendType.values),
    windowSize: _optionalInt(payload['windowSize']),
    degree: _int(payload, 'degree'),
    lineColor: _color(payload, 'lineColor'),
    lineWidth: _double(payload, 'lineWidth'),
    dashPattern: _optionalDoubleList(payload['dashPattern']),
    elevation: _double(payload, 'elevation'),
  );
}

ChordAnnotation _decodeChord(
  String id,
  Map<String, Object?> payload,
  _CommonAnnotationFields common,
) {
  _requireDefaultSnap(common, 'chord');
  return ChordAnnotation(
    id: id,
    label: common.label,
    style: common.style,
    allowDragging: common.allowDragging,
    allowEditing: common.allowEditing,
    zIndex: common.zIndex,
    seriesId: _string(payload, 'seriesId'),
    startIndex: _int(payload, 'startIndex'),
    endIndex: _int(payload, 'endIndex'),
    lineColor: _color(payload, 'lineColor'),
    lineWidth: _double(payload, 'lineWidth'),
    dashPattern: _optionalDoubleList(payload['dashPattern']),
    elevation: _double(payload, 'elevation'),
    perpendicularIndex: _optionalInt(payload['perpendicularIndex']),
    perpendicularLabel: _optionalString(payload['perpendicularLabel']),
    perpendicularLabelOffset: _decodeOffset(
      _requiredMap(payload, 'perpendicularLabelOffset'),
    ),
    perpendicularLabelStyle: payload['perpendicularLabelStyle'] == null
        ? null
        : ChartStyleDocumentCodec.decodeAnnotationStyle(
            JsonValue.fromJson(_requiredMap(payload, 'perpendicularLabelStyle'))
                as JsonObjectValue,
          ),
    perpendicularLineColor: _optionalColor(payload['perpendicularLineColor']),
    perpendicularLineWidth: _optionalDouble(payload['perpendicularLineWidth']),
    perpendicularDashPattern: _optionalDoubleList(
      payload['perpendicularDashPattern'],
    ),
    perpendicularElevation: _optionalDouble(payload['perpendicularElevation']),
  );
}

LegendAnnotation _decodeLegend(
  String id,
  Map<String, Object?> payload,
  _CommonAnnotationFields common,
) {
  _requireDefaultSnap(common, 'legend');
  final style = ChartStyleDocumentCodec.decodeLegendStyle(
    JsonValue.fromJson(_requiredMap(payload, 'legendStyle')) as JsonObjectValue,
  );
  if (common.style != const AnnotationStyle() ||
      common.allowEditing ||
      common.allowDragging != style.allowDragging) {
    throw const _CodecException(
      ChartArtifactDiagnosticCodes.invalidArtifact,
      'Legend base behavior must agree with its legend style.',
      r'$.payload',
    );
  }
  if ([
        payload['sizeScale'],
        payload['colorScale'],
        payload['opacityScale'],
      ].where((value) => value != null).length >
      1) {
    throw const _CodecException(
      ChartArtifactDiagnosticCodes.invalidArtifact,
      'Quantitative scales require separate legend annotations.',
      r'$.payload',
    );
  }
  return LegendAnnotation(
    id: id,
    label: common.label,
    zIndex: common.zIndex,
    series: [
      for (final item in _list(payload, 'series'))
        _decodeSeriesOrThrow(ChartSeriesDocument.fromJson(_map(item))),
    ],
    trendAnnotations: [
      for (final item in _list(payload, 'trendAnnotations'))
        _decodeTrendOrThrow(ChartAnnotationDocument.fromJson(_map(item))),
    ],
    sizeScale: payload['sizeScale'] == null
        ? null
        : _decodeLegendSizeScale(_requiredMap(payload, 'sizeScale')),
    colorScale: payload['colorScale'] == null
        ? null
        : _decodeLegendColorScale(_requiredMap(payload, 'colorScale')),
    opacityScale: payload['opacityScale'] == null
        ? null
        : _decodeLegendOpacityScale(_requiredMap(payload, 'opacityScale')),
    legendStyle: style,
    hiddenSeriesIds: _stringSet(payload, 'hiddenSeriesIds'),
    customPosition: payload['customPosition'] == null
        ? null
        : _decodeOffset(_requiredMap(payload, 'customPosition')),
  );
}

Map<String, Object?> _encodeLegendSizeScale(LegendSizeScale scale) => {
  'label': scale.label,
  'color': scale.color.toARGB32(),
  'samples': [
    for (final sample in scale.samples)
      {'radius': _number(sample.radius), 'label': sample.label},
  ],
};

LegendSizeScale _decodeLegendSizeScale(Map<String, Object?> payload) {
  final samples = <LegendSizeSample>[
    for (final item in _list(payload, 'samples'))
      LegendSizeSample(
        radius: _double(_map(item), 'radius'),
        label: _string(_map(item), 'label'),
      ),
  ];
  if (samples.isEmpty) {
    throw const _CodecException(
      ChartArtifactDiagnosticCodes.invalidArtifact,
      'Legend size scales require at least one sample.',
      r'$.payload.sizeScale.samples',
    );
  }
  return LegendSizeScale(
    label: _string(payload, 'label'),
    samples: samples,
    color: _color(payload, 'color'),
  );
}

Map<String, Object?> _encodeLegendColorScale(LegendColorScale scale) => {
  'label': scale.label,
  'colors': [for (final color in scale.colors) color.toARGB32()],
  'type': scale.type.name,
  if (scale.segmentLabels.isNotEmpty) 'segmentLabels': scale.segmentLabels,
  'minimumLabel': scale.minimumLabel,
  if (scale.midpointLabel != null) 'midpointLabel': scale.midpointLabel,
  'maximumLabel': scale.maximumLabel,
};

LegendColorScale _decodeLegendColorScale(Map<String, Object?> payload) {
  final rawColors = _list(payload, 'colors');
  if (rawColors.length < 2) {
    throw const _CodecException(
      ChartArtifactDiagnosticCodes.invalidArtifact,
      'Legend color scales require at least two colors.',
      r'$.payload.colorScale.colors',
    );
  }
  final type = payload['type'] == null
      ? LegendColorScaleType.continuous
      : _enum(payload, 'type', LegendColorScaleType.values);
  final segmentLabels = payload['segmentLabels'] == null
      ? const <String>[]
      : [
          for (final item in _list(payload, 'segmentLabels'))
            if (item is String)
              item
            else
              throw const FormatException(
                'Legend color scale segment labels must be strings.',
              ),
        ];
  if (type == LegendColorScaleType.piecewise &&
      segmentLabels.length != rawColors.length) {
    throw const _CodecException(
      ChartArtifactDiagnosticCodes.invalidArtifact,
      'Piecewise legend color scales require one label per color.',
      r'$.payload.colorScale.segmentLabels',
    );
  }
  return LegendColorScale(
    label: _string(payload, 'label'),
    colors: [
      for (var index = 0; index < rawColors.length; index++)
        _color({'value': rawColors[index]}, 'value'),
    ],
    minimumLabel: _string(payload, 'minimumLabel'),
    midpointLabel: _optionalString(payload['midpointLabel']),
    maximumLabel: _string(payload, 'maximumLabel'),
    type: type,
    segmentLabels: segmentLabels,
  );
}

Map<String, Object?> _encodeLegendOpacityScale(LegendOpacityScale scale) => {
  'label': scale.label,
  'color': scale.color.toARGB32(),
  'minimumOpacity': _number(scale.minimumOpacity),
  'maximumOpacity': _number(scale.maximumOpacity),
  'minimumLabel': scale.minimumLabel,
  if (scale.midpointLabel != null) 'midpointLabel': scale.midpointLabel,
  'maximumLabel': scale.maximumLabel,
};

LegendOpacityScale _decodeLegendOpacityScale(Map<String, Object?> payload) {
  final minimumOpacity = _double(payload, 'minimumOpacity');
  final maximumOpacity = _double(payload, 'maximumOpacity');
  if (!minimumOpacity.isFinite ||
      minimumOpacity < 0 ||
      minimumOpacity > 1 ||
      !maximumOpacity.isFinite ||
      maximumOpacity < minimumOpacity ||
      maximumOpacity > 1) {
    throw const _CodecException(
      ChartArtifactDiagnosticCodes.invalidArtifact,
      'Legend opacity scale range must be finite, ordered, and within zero to one.',
      r'$.payload.opacityScale',
    );
  }
  return LegendOpacityScale(
    label: _string(payload, 'label'),
    color: _color(payload, 'color'),
    minimumOpacity: minimumOpacity,
    maximumOpacity: maximumOpacity,
    minimumLabel: _string(payload, 'minimumLabel'),
    midpointLabel: _optionalString(payload['midpointLabel']),
    maximumLabel: _string(payload, 'maximumLabel'),
  );
}

void _requireDefaultSnap(_CommonAnnotationFields common, String type) {
  if (common.snapToValue || common.snapIncrement != 0.5) {
    throw _CodecException(
      ChartArtifactDiagnosticCodes.invalidArtifact,
      '$type annotations do not expose custom snap settings.',
      r'$.payload.snapToValue',
    );
  }
}

ChartSeriesDocument _encodeSeriesOrThrow(
  ChartSeries series,
  ChartModelCodecContext context,
) {
  final result = ChartSeriesDocumentCodec.encodeWithContext(series, context);
  return switch (result) {
    ChartArtifactSuccess<ChartSeriesDocument>() => result.value,
    ChartArtifactFailure<ChartSeriesDocument>() =>
      throw _CodecException.fromError(result.error),
  };
}

ChartSeries _decodeSeriesOrThrow(ChartSeriesDocument document) {
  final result = ChartSeriesDocumentCodec.decode(document);
  return switch (result) {
    ChartArtifactSuccess<ChartSeries>() => result.value,
    ChartArtifactFailure<ChartSeries>() => throw _CodecException.fromError(
      result.error,
    ),
  };
}

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
      throw _CodecException.fromError(result.error),
  };
}

TrendAnnotation _decodeTrendOrThrow(ChartAnnotationDocument document) {
  final result = ChartAnnotationDocumentCodec.decode(document);
  return switch (result) {
    ChartArtifactSuccess<ChartAnnotation>(value: final TrendAnnotation value) =>
      value,
    ChartArtifactSuccess<ChartAnnotation>() => throw const _CodecException(
      ChartArtifactDiagnosticCodes.invalidArtifact,
      'Legend trendAnnotations must contain trend annotations.',
      r'$.payload.trendAnnotations',
    ),
    ChartArtifactFailure<ChartAnnotation>() => throw _CodecException.fromError(
      result.error,
    ),
  };
}

JsonObjectValue _object(Map<String, Object?> value) =>
    JsonValue.fromJson(value) as JsonObjectValue;

Object _number(double value) => ChartNumberDocument.fromDouble(value).toJson();

Map<String, Object?> _encodeOffset(Offset offset) => {
  'dx': _number(offset.dx),
  'dy': _number(offset.dy),
};

Offset _decodeOffset(Map<String, Object?> value) =>
    Offset(_double(value, 'dx'), _double(value, 'dy'));

Map<String, Object?> _map(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) return Map<String, Object?>.from(value);
  throw const FormatException('Expected JSON object.');
}

Map<String, Object?> _requiredMap(Map<String, Object?> map, String key) =>
    _map(map[key]);

List<Object?> _list(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is List<Object?>) return value;
  if (value is List) return List<Object?>.from(value);
  throw FormatException('Expected list at $key.');
}

String _string(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is String) return value;
  throw FormatException('Expected string at $key.');
}

String? _optionalString(Object? value) {
  if (value == null || value is String) return value as String?;
  throw const FormatException('Expected optional string.');
}

bool _bool(Map<String, Object?> map, String key) {
  final value = map[key];
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

List<double>? _optionalDoubleList(Object? value) {
  if (value == null) return null;
  if (value is! List) throw const FormatException('Expected number list.');
  return [
    for (final item in value) ChartNumberDocument.fromJson(item).asDouble,
  ];
}

Color _color(Map<String, Object?> map, String key) =>
    _optionalColor(map[key]) ??
    (throw FormatException('Expected ARGB color at $key.'));

Color? _optionalColor(Object? value) {
  if (value == null) return null;
  if (value is int) return Color(value);
  throw const FormatException('Expected ARGB color integer.');
}

Set<String> _stringSet(Map<String, Object?> map, String key) => {
  for (final item in _list(map, key))
    if (item is String)
      item
    else
      throw FormatException('Expected string in $key.'),
};

T _enum<T extends Enum>(Map<String, Object?> map, String key, List<T> values) {
  final value = _string(map, key);
  for (final candidate in values) {
    if (candidate.name == value) return candidate;
  }
  throw FormatException('Unknown enum value "$value" at $key.');
}

class _CodecException implements Exception {
  const _CodecException(this.code, this.message, this.path);

  factory _CodecException.fromError(ChartArtifactError error) =>
      _CodecException(error.code, error.message, error.path);

  final String code;
  final String message;
  final String? path;

  ChartArtifactError get error =>
      ChartArtifactError(code: code, message: message, path: path);
}
