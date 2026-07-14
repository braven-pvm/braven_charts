import 'package:flutter/material.dart' hide TooltipTriggerMode;

import '../models/interaction_config.dart';
import 'chart_artifact_diagnostics.dart';
import 'chart_data_payload.dart';
import 'chart_document.dart';
import 'chart_style_document_codec.dart';
import 'json_value.dart';

/// Complete portable codec for [InteractionConfig].
///
/// Executable callbacks are represented only by explicit host binding
/// descriptors. Decoding a document that requires bindings is deferred to the
/// hydration layer, where a runtime registry can safely resolve them.
abstract final class ChartInteractionDocumentCodec {
  static const tooltipBuilderBinding = 'tooltip.customBuilder';
  static const dataPointTapBinding = 'onDataPointTap';
  static const dataPointHoverBinding = 'onDataPointHover';
  static const dataPointLongPressBinding = 'onDataPointLongPress';
  static const selectionChangedBinding = 'onSelectionChanged';
  static const zoomChangedBinding = 'onZoomChanged';
  static const panChangedBinding = 'onPanChanged';
  static const viewportChangedBinding = 'onViewportChanged';
  static const crosshairChangedBinding = 'onCrosshairChanged';
  static const tooltipChangedBinding = 'onTooltipChanged';
  static const keyboardActionBinding = 'onKeyboardAction';

  static ChartArtifactResult<ChartInteractionDocument> encode(
    InteractionConfig config, {
    Map<String, JsonObjectValue> runtimeBindingDescriptors = const {},
  }) {
    try {
      final callbacks = <String, Object?>{};
      final requiredBindings = <String>{};
      void capture(String field, bool present) {
        if (!present) return;
        final descriptor = runtimeBindingDescriptors[field];
        if (descriptor == null) {
          throw _BindingException(
            'Interaction callback $field requires a runtime binding descriptor.',
            r'$.interaction.configuration.callbacks.' + field,
          );
        }
        final descriptorMap = _map(descriptor);
        final id = _string(descriptorMap, 'id');
        callbacks[field] = descriptor.toJson();
        requiredBindings.add(id);
      }

      capture(tooltipBuilderBinding, config.tooltip.customBuilder != null);
      capture(dataPointTapBinding, config.onDataPointTap != null);
      capture(dataPointHoverBinding, config.onDataPointHover != null);
      capture(dataPointLongPressBinding, config.onDataPointLongPress != null);
      capture(selectionChangedBinding, config.onSelectionChanged != null);
      capture(zoomChangedBinding, config.onZoomChanged != null);
      capture(panChangedBinding, config.onPanChanged != null);
      capture(viewportChangedBinding, config.onViewportChanged != null);
      capture(crosshairChangedBinding, config.onCrosshairChanged != null);
      capture(tooltipChangedBinding, config.onTooltipChanged != null);
      capture(keyboardActionBinding, config.onKeyboardAction != null);

      return ChartArtifactSuccess(
        value: ChartInteractionDocument(
          configuration: _object({
            'enabled': config.enabled,
            'crosshair': _encodeCrosshair(config.crosshair),
            'tooltip': _encodeTooltip(config.tooltip),
            'gesture': _encodeGesture(config.gesture),
            'keyboard': _encodeKeyboard(config.keyboard),
            'enableZoom': config.enableZoom,
            'enablePan': config.enablePan,
            'enableSelection': config.enableSelection,
            'showFocusBorder': config.showFocusBorder,
            'enableFocusOnHover': config.enableFocusOnHover,
            'showXScrollbar': config.showXScrollbar,
            'showYScrollbar': config.showYScrollbar,
            'keyboardZoomPercent': config.keyboardZoomPercent,
            if (callbacks.isNotEmpty) 'callbacks': callbacks,
          }),
          requiredBindings: requiredBindings,
        ),
      );
    } on _BindingException catch (error) {
      return ChartArtifactFailure(
        error: ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.runtimeBindingRequired,
          message: error.message,
          path: error.path,
        ),
      );
    } on UnsupportedError catch (error) {
      return ChartArtifactFailure(
        error: ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.unsupportedModelType,
          message:
              error.message?.toString() ?? 'Unsupported interaction style.',
          path: r'$.interaction.configuration',
        ),
      );
    } on Object catch (error) {
      return _invalidFailure(error);
    }
  }

  static ChartArtifactResult<InteractionConfig> decode(
    ChartInteractionDocument document,
  ) {
    if (document.requiredBindings.isNotEmpty) {
      return ChartArtifactFailure(
        error: ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.runtimeBindingRequired,
          message:
              'Interaction hydration requires bindings: ${document.requiredBindings.toList()..sort()}.',
          path: r'$.interaction.requiredBindings',
        ),
      );
    }
    try {
      final map = _map(document.configuration);
      if (map['callbacks'] != null) {
        throw const FormatException(
          'Callback descriptors must declare requiredBindings.',
        );
      }
      return ChartArtifactSuccess(
        value: InteractionConfig(
          enabled: _bool(map, 'enabled'),
          crosshair: _decodeCrosshair(_requiredMap(map, 'crosshair')),
          tooltip: _decodeTooltip(_requiredMap(map, 'tooltip')),
          gesture: _decodeGesture(_requiredMap(map, 'gesture')),
          keyboard: _decodeKeyboard(_requiredMap(map, 'keyboard')),
          enableZoom: _bool(map, 'enableZoom'),
          enablePan: _bool(map, 'enablePan'),
          enableSelection: _bool(map, 'enableSelection'),
          showFocusBorder: _bool(map, 'showFocusBorder'),
          enableFocusOnHover: _bool(map, 'enableFocusOnHover'),
          showXScrollbar: _bool(map, 'showXScrollbar'),
          showYScrollbar: _bool(map, 'showYScrollbar'),
          keyboardZoomPercent: _int(map, 'keyboardZoomPercent'),
        ),
      );
    } on Object catch (error) {
      return _invalidFailure(error);
    }
  }
}

Map<String, Object?> _encodeCrosshair(CrosshairConfig value) => {
  'enabled': value.enabled,
  'mode': value.mode.name,
  'snapToDataPoint': value.snapToDataPoint,
  'snapRadius': _n(value.snapRadius),
  'showCoordinateLabels': value.showCoordinateLabels,
  if (value.coordinateLabelStyle != null)
    'coordinateLabelStyle': ChartStyleDocumentCodec.encodeTextStyle(
      value.coordinateLabelStyle!,
    ).toJson(),
  'style': _encodeCrosshairStyle(value.style),
  'displayMode': value.displayMode.name,
  'trackingModeThreshold': value.trackingModeThreshold,
  'interpolateValues': value.interpolateValues,
  'showTrackingTooltip': value.showTrackingTooltip,
  'showIntersectionMarkers': value.showIntersectionMarkers,
  'intersectionMarkerRadius': _n(value.intersectionMarkerRadius),
};

CrosshairConfig _decodeCrosshair(Map<String, Object?> map) => CrosshairConfig(
  enabled: _bool(map, 'enabled'),
  mode: _enum(map, 'mode', CrosshairMode.values),
  snapToDataPoint: _bool(map, 'snapToDataPoint'),
  snapRadius: _double(map, 'snapRadius'),
  showCoordinateLabels: _bool(map, 'showCoordinateLabels'),
  coordinateLabelStyle: map['coordinateLabelStyle'] == null
      ? null
      : ChartStyleDocumentCodec.decodeTextStyle(
          _object(_requiredMap(map, 'coordinateLabelStyle')),
        ),
  style: _decodeCrosshairStyle(_requiredMap(map, 'style')),
  displayMode: _enum(map, 'displayMode', CrosshairDisplayMode.values),
  trackingModeThreshold: _int(map, 'trackingModeThreshold'),
  interpolateValues: _bool(map, 'interpolateValues'),
  showTrackingTooltip: _bool(map, 'showTrackingTooltip'),
  showIntersectionMarkers: _bool(map, 'showIntersectionMarkers'),
  intersectionMarkerRadius: _double(map, 'intersectionMarkerRadius'),
);

Map<String, Object?> _encodeCrosshairStyle(CrosshairStyle value) => {
  'lineColor': value.lineColor.toARGB32(),
  'lineWidth': _n(value.lineWidth),
  if (value.dashPattern != null)
    'dashPattern': value.dashPattern!.map(_n).toList(),
  'strokeCap': value.strokeCap.name,
  'labelBackgroundColor': value.labelBackgroundColor.toARGB32(),
  'labelTextColor': value.labelTextColor.toARGB32(),
  'labelPadding': _n(value.labelPadding),
};

CrosshairStyle _decodeCrosshairStyle(Map<String, Object?> map) =>
    CrosshairStyle(
      lineColor: _color(map, 'lineColor'),
      lineWidth: _double(map, 'lineWidth'),
      dashPattern: map['dashPattern'] == null
          ? null
          : _doubleList(map, 'dashPattern'),
      strokeCap: _enum(map, 'strokeCap', StrokeCap.values),
      labelBackgroundColor: _color(map, 'labelBackgroundColor'),
      labelTextColor: _color(map, 'labelTextColor'),
      labelPadding: _double(map, 'labelPadding'),
    );

Map<String, Object?> _encodeTooltip(TooltipConfig value) => {
  'enabled': value.enabled,
  'triggerMode': value.triggerMode.name,
  'preferredPosition': value.preferredPosition.name,
  'showDelayMicros': value.showDelay.inMicroseconds,
  'hideDelayMicros': value.hideDelay.inMicroseconds,
  'followCursor': value.followCursor,
  'offsetFromPoint': _n(value.offsetFromPoint),
  'style': _encodeTooltipStyle(value.style),
};

TooltipConfig _decodeTooltip(Map<String, Object?> map) => TooltipConfig(
  enabled: _bool(map, 'enabled'),
  triggerMode: _enum(map, 'triggerMode', TooltipTriggerMode.values),
  preferredPosition: _enum(map, 'preferredPosition', TooltipPosition.values),
  showDelay: Duration(microseconds: _int(map, 'showDelayMicros')),
  hideDelay: Duration(microseconds: _int(map, 'hideDelayMicros')),
  followCursor: _bool(map, 'followCursor'),
  offsetFromPoint: _double(map, 'offsetFromPoint'),
  style: _decodeTooltipStyle(_requiredMap(map, 'style')),
);

Map<String, Object?> _encodeTooltipStyle(TooltipStyle value) => {
  'backgroundColor': value.backgroundColor.toARGB32(),
  'borderColor': value.borderColor.toARGB32(),
  'borderWidth': _n(value.borderWidth),
  'borderRadius': _n(value.borderRadius),
  'shadowColor': value.shadowColor.toARGB32(),
  'shadowBlurRadius': _n(value.shadowBlurRadius),
  'padding': _n(value.padding),
  'textColor': value.textColor.toARGB32(),
  'fontSize': _n(value.fontSize),
};

TooltipStyle _decodeTooltipStyle(Map<String, Object?> map) => TooltipStyle(
  backgroundColor: _color(map, 'backgroundColor'),
  borderColor: _color(map, 'borderColor'),
  borderWidth: _double(map, 'borderWidth'),
  borderRadius: _double(map, 'borderRadius'),
  shadowColor: _color(map, 'shadowColor'),
  shadowBlurRadius: _double(map, 'shadowBlurRadius'),
  padding: _double(map, 'padding'),
  textColor: _color(map, 'textColor'),
  fontSize: _double(map, 'fontSize'),
);

Map<String, Object?> _encodeGesture(GestureConfig value) => {
  'tapTimeoutMicros': value.tapTimeout.inMicroseconds,
  'longPressTimeoutMicros': value.longPressTimeout.inMicroseconds,
  'panThreshold': _n(value.panThreshold),
  'pinchThreshold': _n(value.pinchThreshold),
};

GestureConfig _decodeGesture(Map<String, Object?> map) => GestureConfig(
  tapTimeout: Duration(microseconds: _int(map, 'tapTimeoutMicros')),
  longPressTimeout: Duration(microseconds: _int(map, 'longPressTimeoutMicros')),
  panThreshold: _double(map, 'panThreshold'),
  pinchThreshold: _double(map, 'pinchThreshold'),
);

Map<String, Object?> _encodeKeyboard(KeyboardConfig value) => {
  'enabled': value.enabled,
  'panStep': _n(value.panStep),
  'zoomStep': _n(value.zoomStep),
  'enableArrowKeys': value.enableArrowKeys,
  'enablePlusMinusKeys': value.enablePlusMinusKeys,
  'enableHomeEndKeys': value.enableHomeEndKeys,
};

KeyboardConfig _decodeKeyboard(Map<String, Object?> map) => KeyboardConfig(
  enabled: _bool(map, 'enabled'),
  panStep: _double(map, 'panStep'),
  zoomStep: _double(map, 'zoomStep'),
  enableArrowKeys: _bool(map, 'enableArrowKeys'),
  enablePlusMinusKeys: _bool(map, 'enablePlusMinusKeys'),
  enableHomeEndKeys: _bool(map, 'enableHomeEndKeys'),
);

Object _n(double value) => ChartNumberDocument.fromDouble(value).toJson();

JsonObjectValue _object(Map<String, Object?> value) =>
    JsonValue.fromJson(value) as JsonObjectValue;

Map<String, Object?> _map(JsonObjectValue value) =>
    Map<String, Object?>.from(value.toJson() as Map);

Map<String, Object?> _requiredMap(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is Map<String, Object?>) return value;
  if (value is Map) return Map<String, Object?>.from(value);
  throw FormatException('Expected object at $key.');
}

List<Object?> _list(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is List) return List<Object?>.from(value);
  throw FormatException('Expected list at $key.');
}

List<double> _doubleList(Map<String, Object?> map, String key) => _list(
  map,
  key,
).map((value) => ChartNumberDocument.fromJson(value).asDouble).toList();

String _string(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is String && value.isNotEmpty) return value;
  throw FormatException('Expected non-empty string at $key.');
}

bool _bool(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is bool) return value;
  throw FormatException('Expected boolean at $key.');
}

int _int(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is int) return value;
  throw FormatException('Expected integer at $key.');
}

double _double(Map<String, Object?> map, String key) =>
    ChartNumberDocument.fromJson(map[key]).asDouble;

Color _color(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is int) return Color(value);
  throw FormatException('Expected ARGB color integer at $key.');
}

T _enum<T extends Enum>(Map<String, Object?> map, String key, List<T> values) {
  final name = _string(map, key);
  for (final value in values) {
    if (value.name == name) return value;
  }
  throw FormatException('Unknown enum value "$name" at $key.');
}

ChartArtifactFailure<T> _invalidFailure<T>(Object error) =>
    ChartArtifactFailure(
      error: ChartArtifactError(
        code: ChartArtifactDiagnosticCodes.invalidArtifact,
        message: 'Invalid interaction configuration: $error',
        path: r'$.interaction.configuration',
      ),
    );

class _BindingException implements Exception {
  const _BindingException(this.message, this.path);

  final String message;
  final String path;
}
