import 'package:flutter/foundation.dart';

import 'artifact_json_readers.dart';
import 'chart_data_payload.dart';
import 'json_value.dart';

/// Portable chart-level grid configuration.
@immutable
class ChartGridDocument {
  ChartGridDocument({
    this.horizontal = true,
    this.vertical = true,
    this.horizontalColor,
    this.verticalColor,
    ChartNumberDocument? horizontalStrokeWidth,
    ChartNumberDocument? verticalStrokeWidth,
    Map<String, JsonValue> extensions = const {},
  }) : horizontalStrokeWidth =
           horizontalStrokeWidth ?? ChartNumberDocument.fromDouble(0.5),
       verticalStrokeWidth =
           verticalStrokeWidth ?? ChartNumberDocument.fromDouble(0.5),
       extensions = Map.unmodifiable(extensions);

  final bool horizontal;
  final bool vertical;
  final int? horizontalColor;
  final int? verticalColor;
  final ChartNumberDocument horizontalStrokeWidth;
  final ChartNumberDocument verticalStrokeWidth;
  final Map<String, JsonValue> extensions;

  bool get isDefault =>
      horizontal &&
      vertical &&
      horizontalColor == null &&
      verticalColor == null &&
      horizontalStrokeWidth.asDouble == 0.5 &&
      verticalStrokeWidth.asDouble == 0.5 &&
      extensions.isEmpty;

  Map<String, Object?> toJson() => {
    'horizontal': horizontal,
    'vertical': vertical,
    if (horizontalColor != null) 'horizontalColor': horizontalColor,
    if (verticalColor != null) 'verticalColor': verticalColor,
    'horizontalStrokeWidth': horizontalStrokeWidth.toJson(),
    'verticalStrokeWidth': verticalStrokeWidth.toJson(),
    if (extensions.isNotEmpty) 'extensions': jsonValueMap(extensions),
  };

  factory ChartGridDocument.fromJson(Map<String, Object?> json) =>
      ChartGridDocument(
        horizontal: readRequiredBool(json, 'horizontal'),
        vertical: readRequiredBool(json, 'vertical'),
        horizontalColor: readOptionalInt(json, 'horizontalColor'),
        verticalColor: readOptionalInt(json, 'verticalColor'),
        horizontalStrokeWidth: ChartNumberDocument.fromJson(
          json['horizontalStrokeWidth'],
        ),
        verticalStrokeWidth: ChartNumberDocument.fromJson(
          json['verticalStrokeWidth'],
        ),
        extensions: readOptionalJsonValueMap(json, 'extensions'),
      );
}

/// Portable chart-level legend visibility and resolved styling.
@immutable
class ChartLegendDocument {
  ChartLegendDocument({
    this.visible = false,
    JsonObjectValue? style,
    Map<String, JsonValue> extensions = const {},
  }) : style = style ?? JsonObjectValue(const {}),
       extensions = Map.unmodifiable(extensions);

  final bool visible;
  final JsonObjectValue style;
  final Map<String, JsonValue> extensions;

  bool get isDefault => !visible && style.values.isEmpty && extensions.isEmpty;

  Map<String, Object?> toJson() => {
    'visible': visible,
    if (style.values.isNotEmpty) 'style': style.toJson(),
    if (extensions.isNotEmpty) 'extensions': jsonValueMap(extensions),
  };

  factory ChartLegendDocument.fromJson(Map<String, Object?> json) =>
      ChartLegendDocument(
        visible: readRequiredBool(json, 'visible'),
        style: readOptionalJsonObject(json, 'style'),
        extensions: readOptionalJsonValueMap(json, 'extensions'),
      );
}

/// Portable widget-level layout and chart chrome configuration.
@immutable
class ChartLayoutDocument {
  ChartLayoutDocument({
    this.width,
    this.height,
    this.backgroundColor,
    this.showToolbar,
    this.interactiveAnnotations,
    this.maxAxesPerSide,
    this.axisSwapMode,
    Map<String, JsonValue> extensions = const {},
  }) : extensions = Map.unmodifiable(extensions);

  final ChartNumberDocument? width;
  final ChartNumberDocument? height;
  final int? backgroundColor;
  final bool? showToolbar;
  final bool? interactiveAnnotations;
  final int? maxAxesPerSide;
  final String? axisSwapMode;
  final Map<String, JsonValue> extensions;

  bool get isEmpty =>
      width == null &&
      height == null &&
      backgroundColor == null &&
      showToolbar == null &&
      interactiveAnnotations == null &&
      maxAxesPerSide == null &&
      axisSwapMode == null &&
      extensions.isEmpty;

  Map<String, Object?> toJson() => {
    if (width != null) 'width': width!.toJson(),
    if (height != null) 'height': height!.toJson(),
    if (backgroundColor != null) 'backgroundColor': backgroundColor,
    if (showToolbar != null) 'showToolbar': showToolbar,
    if (interactiveAnnotations != null)
      'interactiveAnnotations': interactiveAnnotations,
    if (maxAxesPerSide != null) 'maxAxesPerSide': maxAxesPerSide,
    if (axisSwapMode != null) 'axisSwapMode': axisSwapMode,
    if (extensions.isNotEmpty) 'extensions': jsonValueMap(extensions),
  };

  factory ChartLayoutDocument.fromJson(Map<String, Object?> json) =>
      ChartLayoutDocument(
        width: json['width'] == null
            ? null
            : ChartNumberDocument.fromJson(json['width']),
        height: json['height'] == null
            ? null
            : ChartNumberDocument.fromJson(json['height']),
        backgroundColor: readOptionalInt(json, 'backgroundColor'),
        showToolbar: readOptionalBool(json, 'showToolbar'),
        interactiveAnnotations: readOptionalBool(
          json,
          'interactiveAnnotations',
        ),
        maxAxesPerSide: readOptionalInt(json, 'maxAxesPerSide'),
        axisSwapMode: readOptionalString(json, 'axisSwapMode'),
        extensions: readOptionalJsonValueMap(json, 'extensions'),
      );
}

/// Portable multi-axis normalization policy.
@immutable
class ChartNormalizationDocument {
  ChartNormalizationDocument({
    required this.mode,
    ChartNumberDocument? autoRangeRatioThreshold,
    Map<String, JsonValue> resolvedAxisBounds = const {},
    Map<String, JsonValue> extensions = const {},
  }) : autoRangeRatioThreshold =
           autoRangeRatioThreshold ?? ChartNumberDocument.fromDouble(10),
       resolvedAxisBounds = Map.unmodifiable(resolvedAxisBounds),
       extensions = Map.unmodifiable(extensions);

  final String mode;
  final ChartNumberDocument autoRangeRatioThreshold;
  final Map<String, JsonValue> resolvedAxisBounds;
  final Map<String, JsonValue> extensions;

  Map<String, Object?> toJson() => {
    'mode': mode,
    'autoRangeRatioThreshold': autoRangeRatioThreshold.toJson(),
    if (resolvedAxisBounds.isNotEmpty)
      'resolvedAxisBounds': jsonValueMap(resolvedAxisBounds),
    if (extensions.isNotEmpty) 'extensions': jsonValueMap(extensions),
  };

  factory ChartNormalizationDocument.fromJson(Map<String, Object?> json) =>
      ChartNormalizationDocument(
        mode: readRequiredString(json, 'mode'),
        autoRangeRatioThreshold: ChartNumberDocument.fromJson(
          json['autoRangeRatioThreshold'],
        ),
        resolvedAxisBounds: readOptionalJsonValueMap(
          json,
          'resolvedAxisBounds',
        ),
        extensions: readOptionalJsonValueMap(json, 'extensions'),
      );
}
