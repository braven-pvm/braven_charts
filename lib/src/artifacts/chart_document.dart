import 'package:flutter/foundation.dart';

import 'artifact_json_readers.dart';
import 'chart_annotation_document.dart';
import 'chart_configuration_documents.dart';
import 'chart_data_payload.dart';
import 'json_value.dart';

@immutable
class ChartAxisDocument {
  ChartAxisDocument({
    required this.id,
    required this.position,
    this.axisType = 'value',
    this.label,
    this.unit,
    this.color,
    this.minimum,
    this.maximum,
    this.renderMinimum,
    this.renderMaximum,
    this.visible = true,
    this.showAxisLine = true,
    this.showTicks = true,
    this.showTickLabels = true,
    this.showCrosshairLabel = true,
    this.crosshairLabelPosition = 'overAxis',
    this.labelDisplay = 'labelWithUnit',
    this.layoutMinimum,
    this.layoutMaximum,
    this.tickLabelPadding,
    this.axisLabelPadding,
    this.axisMargin,
    this.tickLabelRotationDegrees,
    this.tickLabelCollisionPolicy,
    this.tickLabelCollisionPadding,
    this.tickCount,
    this.showMinorTicks = false,
    this.minorTickCount = 4,
    this.minorTickLength,
    List<String> categories = const [],
    this.categoryLabelDensity = 'auto',
    this.categoryLabelOverflow = 'wrap',
    this.categoryMinimumExtent,
    this.categoryMaximumLabelExtent,
    this.categoryMaxLabelLines = 2,
    this.categoryLabelRotationDegrees,
    this.categoryAutoViewport = true,
    this.formatter,
    Map<String, JsonValue> extensions = const {},
  }) : categories = List.unmodifiable(categories),
       extensions = Map.unmodifiable(extensions);

  final String id;
  final String position;
  final String axisType;
  final String? label;
  final String? unit;
  final int? color;
  final ChartNumberDocument? minimum;
  final ChartNumberDocument? maximum;
  final ChartNumberDocument? renderMinimum;
  final ChartNumberDocument? renderMaximum;
  final bool visible;
  final bool showAxisLine;
  final bool showTicks;
  final bool showTickLabels;
  final bool showCrosshairLabel;
  final String crosshairLabelPosition;
  final String labelDisplay;
  final ChartNumberDocument? layoutMinimum;
  final ChartNumberDocument? layoutMaximum;
  final ChartNumberDocument? tickLabelPadding;
  final ChartNumberDocument? axisLabelPadding;
  final ChartNumberDocument? axisMargin;
  final ChartNumberDocument? tickLabelRotationDegrees;
  final String? tickLabelCollisionPolicy;
  final ChartNumberDocument? tickLabelCollisionPadding;
  final int? tickCount;
  final bool showMinorTicks;
  final int minorTickCount;
  final ChartNumberDocument? minorTickLength;
  final List<String> categories;
  final String categoryLabelDensity;
  final String categoryLabelOverflow;
  final ChartNumberDocument? categoryMinimumExtent;
  final ChartNumberDocument? categoryMaximumLabelExtent;
  final int categoryMaxLabelLines;
  final ChartNumberDocument? categoryLabelRotationDegrees;
  final bool categoryAutoViewport;
  final JsonObjectValue? formatter;
  final Map<String, JsonValue> extensions;

  Map<String, Object?> toJson() => {
    'id': id,
    'position': position,
    if (axisType != 'value') 'axisType': axisType,
    if (label != null) 'label': label,
    if (unit != null) 'unit': unit,
    if (color != null) 'color': color,
    if (minimum != null) 'minimum': minimum!.toJson(),
    if (maximum != null) 'maximum': maximum!.toJson(),
    if (renderMinimum != null) 'renderMinimum': renderMinimum!.toJson(),
    if (renderMaximum != null) 'renderMaximum': renderMaximum!.toJson(),
    if (!visible) 'visible': false,
    if (!showAxisLine) 'showAxisLine': false,
    if (!showTicks) 'showTicks': false,
    if (!showTickLabels) 'showTickLabels': false,
    if (!showCrosshairLabel) 'showCrosshairLabel': false,
    if (crosshairLabelPosition != 'overAxis')
      'crosshairLabelPosition': crosshairLabelPosition,
    if (labelDisplay != 'labelWithUnit') 'labelDisplay': labelDisplay,
    if (layoutMinimum != null) 'layoutMinimum': layoutMinimum!.toJson(),
    if (layoutMaximum != null) 'layoutMaximum': layoutMaximum!.toJson(),
    if (tickLabelPadding != null)
      'tickLabelPadding': tickLabelPadding!.toJson(),
    if (axisLabelPadding != null)
      'axisLabelPadding': axisLabelPadding!.toJson(),
    if (axisMargin != null) 'axisMargin': axisMargin!.toJson(),
    if (tickLabelRotationDegrees != null)
      'tickLabelRotationDegrees': tickLabelRotationDegrees!.toJson(),
    if (tickLabelCollisionPolicy != null)
      'tickLabelCollisionPolicy': tickLabelCollisionPolicy,
    if (tickLabelCollisionPadding != null)
      'tickLabelCollisionPadding': tickLabelCollisionPadding!.toJson(),
    if (tickCount != null) 'tickCount': tickCount,
    if (showMinorTicks) 'showMinorTicks': true,
    if (minorTickCount != 4) 'minorTickCount': minorTickCount,
    if (minorTickLength != null) 'minorTickLength': minorTickLength!.toJson(),
    if (categories.isNotEmpty) 'categories': categories,
    if (categories.isNotEmpty && categoryLabelDensity != 'auto')
      'categoryLabelDensity': categoryLabelDensity,
    if (categories.isNotEmpty && categoryLabelOverflow != 'wrap')
      'categoryLabelOverflow': categoryLabelOverflow,
    if (categories.isNotEmpty && categoryMinimumExtent != null)
      'categoryMinimumExtent': categoryMinimumExtent!.toJson(),
    if (categories.isNotEmpty && categoryMaximumLabelExtent != null)
      'categoryMaximumLabelExtent': categoryMaximumLabelExtent!.toJson(),
    if (categories.isNotEmpty && categoryMaxLabelLines != 2)
      'categoryMaxLabelLines': categoryMaxLabelLines,
    if (categories.isNotEmpty && categoryLabelRotationDegrees != null)
      'categoryLabelRotationDegrees': categoryLabelRotationDegrees!.toJson(),
    if (categories.isNotEmpty && !categoryAutoViewport)
      'categoryAutoViewport': false,
    if (formatter != null) 'formatter': formatter!.toJson(),
    if (extensions.isNotEmpty) 'extensions': jsonValueMap(extensions),
  };

  factory ChartAxisDocument.fromJson(
    Map<String, Object?> json,
  ) => ChartAxisDocument(
    id: readRequiredString(json, 'id'),
    position: readRequiredString(json, 'position'),
    axisType: readOptionalString(json, 'axisType') ?? 'value',
    label: readOptionalString(json, 'label'),
    unit: readOptionalString(json, 'unit'),
    color: readOptionalInt(json, 'color'),
    minimum: json['minimum'] == null
        ? null
        : ChartNumberDocument.fromJson(json['minimum']),
    maximum: json['maximum'] == null
        ? null
        : ChartNumberDocument.fromJson(json['maximum']),
    renderMinimum: json['renderMinimum'] == null
        ? null
        : ChartNumberDocument.fromJson(json['renderMinimum']),
    renderMaximum: json['renderMaximum'] == null
        ? null
        : ChartNumberDocument.fromJson(json['renderMaximum']),
    visible: readOptionalBool(json, 'visible') ?? true,
    showAxisLine: readOptionalBool(json, 'showAxisLine') ?? true,
    showTicks: readOptionalBool(json, 'showTicks') ?? true,
    showTickLabels: readOptionalBool(json, 'showTickLabels') ?? true,
    showCrosshairLabel: readOptionalBool(json, 'showCrosshairLabel') ?? true,
    crosshairLabelPosition:
        readOptionalString(json, 'crosshairLabelPosition') ?? 'overAxis',
    labelDisplay: readOptionalString(json, 'labelDisplay') ?? 'labelWithUnit',
    layoutMinimum: json['layoutMinimum'] == null
        ? null
        : ChartNumberDocument.fromJson(json['layoutMinimum']),
    layoutMaximum: json['layoutMaximum'] == null
        ? null
        : ChartNumberDocument.fromJson(json['layoutMaximum']),
    tickLabelPadding: json['tickLabelPadding'] == null
        ? null
        : ChartNumberDocument.fromJson(json['tickLabelPadding']),
    axisLabelPadding: json['axisLabelPadding'] == null
        ? null
        : ChartNumberDocument.fromJson(json['axisLabelPadding']),
    axisMargin: json['axisMargin'] == null
        ? null
        : ChartNumberDocument.fromJson(json['axisMargin']),
    tickLabelRotationDegrees: json['tickLabelRotationDegrees'] == null
        ? null
        : ChartNumberDocument.fromJson(json['tickLabelRotationDegrees']),
    tickLabelCollisionPolicy: readOptionalString(
      json,
      'tickLabelCollisionPolicy',
    ),
    tickLabelCollisionPadding: json['tickLabelCollisionPadding'] == null
        ? null
        : ChartNumberDocument.fromJson(json['tickLabelCollisionPadding']),
    tickCount: readOptionalInt(json, 'tickCount'),
    showMinorTicks: readOptionalBool(json, 'showMinorTicks') ?? false,
    minorTickCount: readOptionalInt(json, 'minorTickCount') ?? 4,
    minorTickLength: json['minorTickLength'] == null
        ? null
        : ChartNumberDocument.fromJson(json['minorTickLength']),
    categories: readOptionalStringList(json, 'categories'),
    categoryLabelDensity:
        readOptionalString(json, 'categoryLabelDensity') ?? 'auto',
    categoryLabelOverflow:
        readOptionalString(json, 'categoryLabelOverflow') ?? 'wrap',
    categoryMinimumExtent: json['categoryMinimumExtent'] == null
        ? null
        : ChartNumberDocument.fromJson(json['categoryMinimumExtent']),
    categoryMaximumLabelExtent: json['categoryMaximumLabelExtent'] == null
        ? null
        : ChartNumberDocument.fromJson(json['categoryMaximumLabelExtent']),
    categoryMaxLabelLines: readOptionalInt(json, 'categoryMaxLabelLines') ?? 2,
    categoryLabelRotationDegrees: json['categoryLabelRotationDegrees'] == null
        ? null
        : ChartNumberDocument.fromJson(json['categoryLabelRotationDegrees']),
    categoryAutoViewport:
        readOptionalBool(json, 'categoryAutoViewport') ?? true,
    formatter: readOptionalJsonObject(json, 'formatter'),
    extensions: readOptionalJsonValueMap(json, 'extensions'),
  );
}

@immutable
class ChartThemeDocument {
  ChartThemeDocument({
    this.captureMode = 'referenceAndResolved',
    this.reference,
    JsonObjectValue? resolved,
  }) : resolved = resolved ?? JsonObjectValue(const {});

  final String captureMode;
  final String? reference;
  final JsonObjectValue resolved;

  Map<String, Object?> toJson() => {
    'captureMode': captureMode,
    if (reference != null) 'reference': reference,
    'resolved': resolved.toJson(),
  };

  factory ChartThemeDocument.fromJson(Map<String, Object?> json) =>
      ChartThemeDocument(
        captureMode: readRequiredString(json, 'captureMode'),
        reference: readOptionalString(json, 'reference'),
        resolved: readOptionalJsonObject(json, 'resolved'),
      );
}

@immutable
class ChartInteractionDocument {
  ChartInteractionDocument({
    JsonObjectValue? configuration,
    Set<String> requiredBindings = const {},
  }) : configuration = configuration ?? JsonObjectValue(const {}),
       requiredBindings = Set.unmodifiable(requiredBindings);

  final JsonObjectValue configuration;
  final Set<String> requiredBindings;

  Map<String, Object?> toJson() => {
    'configuration': configuration.toJson(),
    if (requiredBindings.isNotEmpty)
      'requiredBindings': requiredBindings.toList()..sort(),
  };

  factory ChartInteractionDocument.fromJson(Map<String, Object?> json) =>
      ChartInteractionDocument(
        configuration: readOptionalJsonObject(json, 'configuration'),
        requiredBindings: readOptionalStringSet(json, 'requiredBindings'),
      );
}

@immutable
class ChartDocument {
  ChartDocument({
    required this.documentId,
    required this.revision,
    required Iterable<ChartSeriesDocument> series,
    required this.xAxis,
    required Iterable<ChartAxisDocument> axes,
    required this.theme,
    required this.interaction,
    Iterable<ChartAnnotationDocument> annotations = const [],
    this.title,
    this.subtitle,
    ChartLegendDocument? legend,
    ChartGridDocument? grid,
    ChartLayoutDocument? layout,
    this.normalization,
    JsonObjectValue? configuration,
    Set<String> requiredCapabilities = const {},
    Map<String, JsonValue> extensions = const {},
  }) : series = List.unmodifiable(series),
       axes = List.unmodifiable(axes),
       annotations = List.unmodifiable(annotations),
       legend = legend ?? ChartLegendDocument(),
       grid = grid ?? ChartGridDocument(),
       layout = layout ?? ChartLayoutDocument(),
       configuration = configuration ?? JsonObjectValue(const {}),
       requiredCapabilities = Set.unmodifiable(requiredCapabilities),
       extensions = Map.unmodifiable(extensions);

  final String documentId;
  final int revision;
  final List<ChartSeriesDocument> series;
  final ChartAxisDocument xAxis;
  final List<ChartAxisDocument> axes;
  final ChartThemeDocument theme;
  final ChartInteractionDocument interaction;
  final List<ChartAnnotationDocument> annotations;
  final String? title;
  final String? subtitle;
  final ChartLegendDocument legend;
  final ChartGridDocument grid;
  final ChartLayoutDocument layout;
  final ChartNormalizationDocument? normalization;

  /// Portable chart-level composition configuration.
  ///
  /// Series-owned appearance remains in each [ChartSeriesDocument]. This
  /// object stores plot compositions, such as how independent Donut series
  /// share one concentric pane.
  final JsonObjectValue configuration;
  final Set<String> requiredCapabilities;
  final Map<String, JsonValue> extensions;

  int get pointCount =>
      series.fold(0, (count, item) => count + item.data.pointCount);

  Map<String, Object?> toJson() => {
    'documentId': documentId,
    'revision': revision,
    if (title != null) 'title': title,
    if (subtitle != null) 'subtitle': subtitle,
    'series': series.map((item) => item.toJson()).toList(),
    'xAxis': xAxis.toJson(),
    'axes': axes.map((axis) => axis.toJson()).toList(),
    'theme': theme.toJson(),
    'interaction': interaction.toJson(),
    if (annotations.isNotEmpty)
      'annotations': annotations.map((item) => item.toJson()).toList(),
    if (!legend.isDefault) 'legend': legend.toJson(),
    if (!grid.isDefault) 'grid': grid.toJson(),
    if (!layout.isEmpty) 'layout': layout.toJson(),
    if (normalization != null) 'normalization': normalization!.toJson(),
    if (configuration.values.isNotEmpty)
      'configuration': configuration.toJson(),
    if (requiredCapabilities.isNotEmpty)
      'requiredCapabilities': requiredCapabilities.toList()..sort(),
    if (extensions.isNotEmpty) 'extensions': jsonValueMap(extensions),
  };

  factory ChartDocument.fromJson(Map<String, Object?> json) => ChartDocument(
    documentId: readRequiredString(json, 'documentId'),
    revision: readRequiredInt(json, 'revision'),
    title: readOptionalString(json, 'title'),
    subtitle: readOptionalString(json, 'subtitle'),
    series: readRequiredList(json, 'series').map(
      (item) => ChartSeriesDocument.fromJson(readStringMap(item, 'series')),
    ),
    xAxis: ChartAxisDocument.fromJson(readRequiredMap(json, 'xAxis')),
    axes: readRequiredList(
      json,
      'axes',
    ).map((item) => ChartAxisDocument.fromJson(readStringMap(item, 'axis'))),
    theme: ChartThemeDocument.fromJson(readRequiredMap(json, 'theme')),
    interaction: ChartInteractionDocument.fromJson(
      readRequiredMap(json, 'interaction'),
    ),
    annotations: readOptionalList(json, 'annotations').map(
      (item) =>
          ChartAnnotationDocument.fromJson(readStringMap(item, 'annotation')),
    ),
    legend: json['legend'] == null
        ? null
        : ChartLegendDocument.fromJson(readRequiredMap(json, 'legend')),
    grid: json['grid'] == null
        ? null
        : ChartGridDocument.fromJson(readRequiredMap(json, 'grid')),
    layout: json['layout'] == null
        ? null
        : ChartLayoutDocument.fromJson(readRequiredMap(json, 'layout')),
    normalization: json['normalization'] == null
        ? null
        : ChartNormalizationDocument.fromJson(
            readRequiredMap(json, 'normalization'),
          ),
    configuration: readOptionalJsonObject(json, 'configuration'),
    requiredCapabilities: readOptionalStringSet(json, 'requiredCapabilities'),
    extensions: readOptionalJsonValueMap(json, 'extensions'),
  );
}
