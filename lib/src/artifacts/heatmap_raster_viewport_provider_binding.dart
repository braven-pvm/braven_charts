// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

import '../controllers/heatmap_raster_viewport_controller.dart';
import '../models/heatmap_chart_series.dart';
import '../models/heatmap_viewport_source.dart';
import 'json_value.dart';

/// Portable behavior when a raster Heatmap provider is unavailable.
enum HeatmapRasterProviderFallback {
  /// Render the bounded canonical semantic series stored in the artifact.
  cell,

  /// Fail hydration because no truthful interactive fallback is available.
  hardFailure,
}

/// Portable sampling quality used when painting hydrated raster tiles.
enum HeatmapRasterProviderFilterQuality { none, low, medium, high }

/// Portable description of one host-owned image-backed Heatmap layer.
///
/// The descriptor contains no encoded image bytes, decoded handles, cache,
/// transport, credentials, callbacks, or mutable provider state. A host must
/// resolve [providerId] to a fresh runtime for every mounted hydrated chart.
@immutable
final class HeatmapRasterViewportProviderDescriptor {
  HeatmapRasterViewportProviderDescriptor({
    required this.providerId,
    required this.layerId,
    required this.initialViewport,
    this.semanticSeriesId,
    this.fallback = HeatmapRasterProviderFallback.hardFailure,
    this.opacity = 1,
    this.filterQuality = HeatmapRasterProviderFilterQuality.low,
    Map<String, JsonValue> arguments = const {},
  }) : arguments = Map.unmodifiable(arguments) {
    if (providerId.trim().isEmpty) {
      throw ArgumentError.value(providerId, 'providerId', 'must not be blank');
    }
    if (layerId.trim().isEmpty) {
      throw ArgumentError.value(layerId, 'layerId', 'must not be blank');
    }
    if (semanticSeriesId?.trim().isEmpty ?? false) {
      throw ArgumentError.value(
        semanticSeriesId,
        'semanticSeriesId',
        'must be null or non-blank',
      );
    }
    if (fallback == HeatmapRasterProviderFallback.cell &&
        semanticSeriesId == null) {
      throw ArgumentError(
        'Cell fallback requires a semanticSeriesId with canonical cells',
      );
    }
    if (!opacity.isFinite || opacity < 0 || opacity > 1) {
      throw ArgumentError.value(opacity, 'opacity', 'must be between 0 and 1');
    }
    initialViewport.validate(parameterName: 'initialViewport');
  }

  /// Capability declared by documents containing raster-provider metadata.
  static const capabilityId = 'series.heatmap.raster-provider.v1';

  /// Stable allowlisted provider identity resolved by the host.
  final String providerId;

  /// Stable identity for this non-series presentation layer.
  final String layerId;

  /// Optional canonical resident Heatmap series refreshed by the provider.
  final String? semanticSeriesId;

  /// First finite viewport loaded by a freshly hydrated runtime.
  final HeatmapViewportRequest initialViewport;

  /// Explicit behavior when [providerId] is not registered by the host.
  final HeatmapRasterProviderFallback fallback;

  /// Opacity applied to the borrowed raster layer only.
  final double opacity;

  /// Sampling quality applied to the borrowed raster layer only.
  final HeatmapRasterProviderFilterQuality filterQuality;

  /// Provider-specific JSON-safe arguments interpreted only by the host.
  final Map<String, JsonValue> arguments;

  JsonObjectValue toDocument() => JsonObjectValue({
    'providerId': JsonStringValue(providerId),
    'layerId': JsonStringValue(layerId),
    if (semanticSeriesId != null)
      'semanticSeriesId': JsonStringValue(semanticSeriesId!),
    'initialViewport': JsonObjectValue({
      'minimumX': JsonNumberValue(initialViewport.minimumX),
      'maximumX': JsonNumberValue(initialViewport.maximumX),
      'minimumY': JsonNumberValue(initialViewport.minimumY),
      'maximumY': JsonNumberValue(initialViewport.maximumY),
    }),
    'fallback': JsonStringValue(fallback.name),
    'opacity': JsonNumberValue(opacity),
    'filterQuality': JsonStringValue(filterQuality.name),
    if (arguments.isNotEmpty) 'arguments': JsonObjectValue(arguments),
  });

  factory HeatmapRasterViewportProviderDescriptor.fromDocument(
    JsonObjectValue document,
  ) {
    final map = document.toJson() as Map<String, Object?>;
    final providerId = _requiredString(map, 'providerId');
    final layerId = _requiredString(map, 'layerId');
    final semanticSeriesId = map['semanticSeriesId'];
    if (semanticSeriesId != null && semanticSeriesId is! String) {
      throw const FormatException(
        'Heatmap raster provider semanticSeriesId must be a string.',
      );
    }
    final rawViewport = map['initialViewport'];
    if (rawViewport is! Map) {
      throw const FormatException(
        'Heatmap raster provider initialViewport must be an object.',
      );
    }
    double coordinate(String key) {
      final value = rawViewport[key];
      if (value is! num || !value.toDouble().isFinite) {
        throw FormatException(
          'Heatmap raster provider initialViewport.$key must be finite.',
        );
      }
      return value.toDouble();
    }

    final fallback = _enumValue(
      HeatmapRasterProviderFallback.values,
      map['fallback'],
      'fallback',
    );
    final filterQuality = _enumValue(
      HeatmapRasterProviderFilterQuality.values,
      map['filterQuality'],
      'filterQuality',
    );
    final opacityValue = map['opacity'];
    if (opacityValue is! num || !opacityValue.toDouble().isFinite) {
      throw const FormatException(
        'Heatmap raster provider opacity must be finite.',
      );
    }
    final rawArguments = map['arguments'];
    final arguments = <String, JsonValue>{};
    if (rawArguments != null) {
      if (rawArguments is! Map) {
        throw const FormatException(
          'Heatmap raster provider arguments must be an object.',
        );
      }
      for (final entry in rawArguments.entries) {
        if (entry.key is! String) {
          throw const FormatException(
            'Heatmap raster provider argument keys must be strings.',
          );
        }
        arguments[entry.key as String] = JsonValue.fromJson(entry.value);
      }
    }

    try {
      return HeatmapRasterViewportProviderDescriptor(
        providerId: providerId,
        layerId: layerId,
        semanticSeriesId: semanticSeriesId as String?,
        initialViewport: HeatmapViewportRequest(
          minimumX: coordinate('minimumX'),
          maximumX: coordinate('maximumX'),
          minimumY: coordinate('minimumY'),
          maximumY: coordinate('maximumY'),
        ),
        fallback: fallback,
        opacity: opacityValue.toDouble(),
        filterQuality: filterQuality,
        arguments: arguments,
      );
    } on ArgumentError catch (error) {
      throw FormatException('Invalid Heatmap raster provider: $error');
    }
  }

  static String _requiredString(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Heatmap raster provider $key is required.');
    }
    return value;
  }

  static T _enumValue<T extends Enum>(List<T> values, Object? raw, String key) {
    if (raw is! String) {
      throw FormatException('Heatmap raster provider $key is required.');
    }
    for (final value in values) {
      if (value.name == raw) return value;
    }
    throw FormatException('Unsupported Heatmap raster provider $key "$raw".');
  }
}

/// Fresh host runtime returned for one hydrated raster-provider descriptor.
@immutable
final class HeatmapRasterViewportProviderRuntime {
  const HeatmapRasterViewportProviderRuntime({
    required this.controller,
    this.disposeController = true,
  });

  final HeatmapRasterViewportController controller;
  final bool disposeController;
}

typedef HeatmapRasterViewportProviderFactory =
    HeatmapRasterViewportProviderRuntime Function(
      HeatmapRasterViewportProviderDescriptor descriptor,
      HeatmapChartSeries? residentSemanticTemplate,
    );

/// Allowlisted host factories keyed by portable raster-provider ID.
@immutable
final class HeatmapRasterViewportProviderRegistry {
  const HeatmapRasterViewportProviderRegistry({this.factories = const {}});

  final Map<String, HeatmapRasterViewportProviderFactory> factories;

  bool contains(String providerId) => factories.containsKey(providerId);

  HeatmapRasterViewportProviderFactory? resolve(String providerId) =>
      factories[providerId];
}
