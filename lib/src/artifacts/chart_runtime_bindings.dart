import 'package:flutter/material.dart';

import '../models/chart_annotation.dart';
import '../models/chart_data_point.dart';
import '../models/chart_series.dart';
import '../models/interaction_config.dart';
import 'chart_artifact_diagnostics.dart';
import 'chart_annotation_document.dart';
import 'chart_data_payload.dart';
import 'json_value.dart';

typedef ChartValueFormatter =
    String Function(double value, Map<String, JsonValue> arguments);

/// Safe portable description of an executable numeric formatter.
@immutable
class ChartFormatterDescriptor {
  ChartFormatterDescriptor({
    required this.id,
    Map<String, JsonValue> arguments = const {},
    this.fallbackPattern,
  }) : assert(id != ''),
       arguments = Map.unmodifiable(arguments);

  final String id;
  final Map<String, JsonValue> arguments;
  final String? fallbackPattern;

  JsonObjectValue toDocument() => JsonObjectValue({
    'id': JsonStringValue(id),
    if (arguments.isNotEmpty) 'arguments': JsonObjectValue(arguments),
    if (fallbackPattern != null)
      'fallbackPattern': JsonStringValue(fallbackPattern!),
  });

  factory ChartFormatterDescriptor.fromDocument(JsonObjectValue document) {
    final map = document.toJson() as Map<String, Object?>;
    final id = map['id'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('Formatter descriptor id is required.');
    }
    final rawArguments = map['arguments'];
    final arguments = <String, JsonValue>{};
    if (rawArguments != null) {
      if (rawArguments is! Map) {
        throw const FormatException(
          'Formatter descriptor arguments must be an object.',
        );
      }
      for (final entry in rawArguments.entries) {
        if (entry.key is! String) {
          throw const FormatException(
            'Formatter descriptor argument keys must be strings.',
          );
        }
        arguments[entry.key as String] = JsonValue.fromJson(entry.value);
      }
    }
    final fallback = map['fallbackPattern'];
    if (fallback != null && fallback is! String) {
      throw const FormatException('fallbackPattern must be a string.');
    }
    return ChartFormatterDescriptor(
      id: id,
      arguments: arguments,
      fallbackPattern: fallback as String?,
    );
  }
}

@immutable
class ChartFormatterResolution {
  const ChartFormatterResolution({required this.formatter, this.warning});

  final String Function(double value) formatter;
  final ChartArtifactWarning? warning;
}

/// Registry for package-owned and host-provided numeric formatters.
@immutable
class ChartFormatterRegistry {
  const ChartFormatterRegistry({this.customFormatters = const {}});

  final Map<String, ChartValueFormatter> customFormatters;

  ChartFormatterResolution resolve(ChartFormatterDescriptor descriptor) {
    final implementation = customFormatters[descriptor.id];
    if (implementation != null) {
      return ChartFormatterResolution(
        formatter: (value) => implementation(value, descriptor.arguments),
      );
    }
    final builtIn = switch (descriptor.id) {
      'braven.number.fixed' => _formatFixed,
      'braven.number.percent' => _formatPercent,
      _ => null,
    };
    if (builtIn != null) {
      return ChartFormatterResolution(
        formatter: (value) => builtIn(value, descriptor.arguments),
      );
    }
    return ChartFormatterResolution(
      formatter: (value) =>
          descriptor.fallbackPattern?.replaceAll('{value}', value.toString()) ??
          value.toString(),
      warning: ChartArtifactWarning(
        code: ChartArtifactDiagnosticCodes.unregisteredFormatter,
        message:
            'Formatter "${descriptor.id}" is not registered; its safe fallback is active.',
      ),
    );
  }
}

/// Registry for custom tooltip builders referenced by stable IDs.
@immutable
class ChartTooltipRegistry {
  const ChartTooltipRegistry({this.builders = const {}});

  final Map<String, TooltipBuilder> builders;

  TooltipBuilder? resolve(String id) => builders[id];
}

/// Type-checked lookup for interaction callbacks referenced by stable IDs.
@immutable
class ChartCallbackRegistry {
  const ChartCallbackRegistry({this.callbacks = const {}});

  final Map<String, Object> callbacks;

  T? resolve<T extends Function>(String id) {
    final callback = callbacks[id];
    return callback is T ? callback : null;
  }
}

/// Constrained host extension codec; artifacts never instantiate class names.
abstract interface class ChartExtensionCodec<T> {
  String get typeId;
  int get codecVersion;
  Map<String, JsonValue> encode(T value);
  T decode(Map<String, JsonValue> value);
}

abstract interface class ChartSeriesExtensionCodec {
  String get typeId;
  String get capabilityId;
  int get codecVersion;
  ChartSeriesDocument encode(ChartSeries value);
  ChartSeries decode(ChartSeriesDocument document);
}

abstract interface class ChartAnnotationExtensionCodec {
  String get typeId;
  String get capabilityId;
  int get codecVersion;
  ChartAnnotationDocument encode(ChartAnnotation value);
  ChartAnnotation decode(ChartAnnotationDocument document);
}

@immutable
class ChartExtensionRegistry {
  const ChartExtensionRegistry({
    this.codecs = const {},
    this.seriesCodecs = const {},
    this.annotationCodecs = const {},
  });

  final Map<String, ChartExtensionCodec<Object?>> codecs;
  final Map<String, ChartSeriesExtensionCodec> seriesCodecs;
  final Map<String, ChartAnnotationExtensionCodec> annotationCodecs;

  Set<String> get supportedCapabilities => {
    ...codecs.keys,
    for (final codec in seriesCodecs.values) codec.capabilityId,
    for (final codec in annotationCodecs.values) codec.capabilityId,
  };
}

/// Executable host behavior supplied explicitly during hydration.
@immutable
class ChartRuntimeBindings {
  const ChartRuntimeBindings({
    this.formatters = const ChartFormatterRegistry(),
    this.tooltips = const ChartTooltipRegistry(),
    this.callbacks = const ChartCallbackRegistry(),
    this.extensions = const ChartExtensionRegistry(),
    this.onPointTap,
    this.onPointHover,
    this.onBackgroundTap,
    this.onSeriesSelected,
    this.onAnnotationTap,
    this.onAnnotationDragged,
    this.onSeriesDeselected,
  });

  final ChartFormatterRegistry formatters;
  final ChartTooltipRegistry tooltips;
  final ChartCallbackRegistry callbacks;
  final ChartExtensionRegistry extensions;
  final void Function(ChartDataPoint point, String seriesId)? onPointTap;
  final void Function(ChartDataPoint? point, String? seriesId)? onPointHover;
  final void Function(Offset position)? onBackgroundTap;
  final void Function(String seriesId)? onSeriesSelected;
  final void Function(ChartAnnotation annotation)? onAnnotationTap;
  final void Function(ChartAnnotation annotation, Offset newPosition)?
  onAnnotationDragged;
  final void Function(String seriesId)? onSeriesDeselected;
}

String _formatFixed(double value, Map<String, JsonValue> arguments) {
  final decimals = _integerArgument(arguments, 'decimals', fallback: 2);
  return value.toStringAsFixed(decimals.clamp(0, 20));
}

String _formatPercent(double value, Map<String, JsonValue> arguments) {
  final decimals = _integerArgument(arguments, 'decimals', fallback: 0);
  return '${(value * 100).toStringAsFixed(decimals.clamp(0, 20))}%';
}

int _integerArgument(
  Map<String, JsonValue> arguments,
  String key, {
  required int fallback,
}) {
  final raw = arguments[key]?.toJson();
  return raw is int ? raw : fallback;
}
