import 'package:flutter/foundation.dart';

import 'artifact_json_readers.dart';
import 'chart_annotation_document.dart';
import 'chart_data_payload.dart';
import 'json_value.dart';

@immutable
class ChartAxisDocument {
  ChartAxisDocument({
    required this.id,
    required this.position,
    this.label,
    this.unit,
    this.minimum,
    this.maximum,
    this.formatter,
    Map<String, JsonValue> extensions = const {},
  }) : extensions = Map.unmodifiable(extensions);

  final String id;
  final String position;
  final String? label;
  final String? unit;
  final ChartNumberDocument? minimum;
  final ChartNumberDocument? maximum;
  final JsonObjectValue? formatter;
  final Map<String, JsonValue> extensions;

  Map<String, Object?> toJson() => {
    'id': id,
    'position': position,
    if (label != null) 'label': label,
    if (unit != null) 'unit': unit,
    if (minimum != null) 'minimum': minimum!.toJson(),
    if (maximum != null) 'maximum': maximum!.toJson(),
    if (formatter != null) 'formatter': formatter!.toJson(),
    if (extensions.isNotEmpty) 'extensions': jsonValueMap(extensions),
  };

  factory ChartAxisDocument.fromJson(Map<String, Object?> json) =>
      ChartAxisDocument(
        id: readRequiredString(json, 'id'),
        position: readRequiredString(json, 'position'),
        label: readOptionalString(json, 'label'),
        unit: readOptionalString(json, 'unit'),
        minimum: json['minimum'] == null
            ? null
            : ChartNumberDocument.fromJson(json['minimum']),
        maximum: json['maximum'] == null
            ? null
            : ChartNumberDocument.fromJson(json['maximum']),
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

/// Extensible JSON-safe component used until built-in codecs provide their
/// audited typed fields in the next implementation slice.
@immutable
class ChartDocumentComponent {
  ChartDocumentComponent({
    JsonObjectValue? properties,
    Map<String, JsonValue> extensions = const {},
  }) : properties = properties ?? JsonObjectValue(const {}),
       extensions = Map.unmodifiable(extensions);

  final JsonObjectValue properties;
  final Map<String, JsonValue> extensions;

  bool get isEmpty => properties.values.isEmpty && extensions.isEmpty;

  Map<String, Object?> toJson() => {
    ...properties.toJson() as Map<String, Object?>,
    if (extensions.isNotEmpty) 'extensions': jsonValueMap(extensions),
  };

  factory ChartDocumentComponent.fromJson(Map<String, Object?> json) {
    final properties = Map<String, Object?>.from(json)..remove('extensions');
    return ChartDocumentComponent(
      properties: JsonValue.fromJson(properties) as JsonObjectValue,
      extensions: readOptionalJsonValueMap(json, 'extensions'),
    );
  }
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
    ChartDocumentComponent? legend,
    ChartDocumentComponent? grid,
    ChartDocumentComponent? layout,
    this.normalization,
    Set<String> requiredCapabilities = const {},
    Map<String, JsonValue> extensions = const {},
  }) : series = List.unmodifiable(series),
       axes = List.unmodifiable(axes),
       annotations = List.unmodifiable(annotations),
       legend = legend ?? ChartDocumentComponent(),
       grid = grid ?? ChartDocumentComponent(),
       layout = layout ?? ChartDocumentComponent(),
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
  final ChartDocumentComponent legend;
  final ChartDocumentComponent grid;
  final ChartDocumentComponent layout;
  final ChartDocumentComponent? normalization;
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
    if (!legend.isEmpty) 'legend': legend.toJson(),
    if (!grid.isEmpty) 'grid': grid.toJson(),
    if (!layout.isEmpty) 'layout': layout.toJson(),
    if (normalization != null) 'normalization': normalization!.toJson(),
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
    legend: _readOptionalComponent(json, 'legend'),
    grid: _readOptionalComponent(json, 'grid'),
    layout: _readOptionalComponent(json, 'layout'),
    normalization: json['normalization'] == null
        ? null
        : ChartDocumentComponent.fromJson(
            readRequiredMap(json, 'normalization'),
          ),
    requiredCapabilities: readOptionalStringSet(json, 'requiredCapabilities'),
    extensions: readOptionalJsonValueMap(json, 'extensions'),
  );
}

ChartDocumentComponent? _readOptionalComponent(
  Map<String, Object?> json,
  String key,
) => json[key] == null
    ? null
    : ChartDocumentComponent.fromJson(readRequiredMap(json, key));
