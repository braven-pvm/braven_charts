// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

import '../controllers/heatmap_viewport_controller.dart';
import '../models/heatmap_chart_series.dart';
import '../models/heatmap_viewport_source.dart';
import 'json_value.dart';

/// Portable description of a host-owned viewport-backed Heatmap provider.
///
/// The descriptor is deliberately limited to stable identity, JSON-safe
/// arguments, and an initial viewport. Sources, callbacks, credentials,
/// clients, caches, subscriptions, and mutation history remain host-owned.
@immutable
class HeatmapViewportProviderDescriptor {
  HeatmapViewportProviderDescriptor({
    required this.providerId,
    required this.seriesId,
    required this.initialViewport,
    Map<String, JsonValue> arguments = const {},
  }) : assert(providerId != ''),
       assert(seriesId != ''),
       arguments = Map.unmodifiable(arguments) {
    initialViewport.validate(parameterName: 'initialViewport');
  }

  /// Capability declared by documents containing provider descriptors.
  static const capabilityId = 'series.heatmap.viewport-provider.v1';

  /// Stable allowlisted provider identity resolved by the host.
  final String providerId;

  /// ID of the resident [HeatmapChartSeries] this provider refreshes.
  final String seriesId;

  /// First finite viewport loaded by a freshly hydrated runtime.
  final HeatmapViewportRequest initialViewport;

  /// Provider-specific JSON-safe arguments interpreted only by the host.
  final Map<String, JsonValue> arguments;

  JsonObjectValue toDocument() => JsonObjectValue({
    'providerId': JsonStringValue(providerId),
    'seriesId': JsonStringValue(seriesId),
    'initialViewport': JsonObjectValue({
      'minimumX': JsonNumberValue(initialViewport.minimumX),
      'maximumX': JsonNumberValue(initialViewport.maximumX),
      'minimumY': JsonNumberValue(initialViewport.minimumY),
      'maximumY': JsonNumberValue(initialViewport.maximumY),
    }),
    if (arguments.isNotEmpty) 'arguments': JsonObjectValue(arguments),
  });

  factory HeatmapViewportProviderDescriptor.fromDocument(
    JsonObjectValue document,
  ) {
    final map = document.toJson() as Map<String, Object?>;
    final providerId = map['providerId'];
    final seriesId = map['seriesId'];
    if (providerId is! String || providerId.isEmpty) {
      throw const FormatException('Heatmap providerId is required.');
    }
    if (seriesId is! String || seriesId.isEmpty) {
      throw const FormatException('Heatmap provider seriesId is required.');
    }
    final rawViewport = map['initialViewport'];
    if (rawViewport is! Map) {
      throw const FormatException(
        'Heatmap provider initialViewport must be an object.',
      );
    }
    double coordinate(String key) {
      final value = rawViewport[key];
      if (value is! num || !value.toDouble().isFinite) {
        throw FormatException(
          'Heatmap provider initialViewport.$key must be finite.',
        );
      }
      return value.toDouble();
    }

    final rawArguments = map['arguments'];
    final arguments = <String, JsonValue>{};
    if (rawArguments != null) {
      if (rawArguments is! Map) {
        throw const FormatException(
          'Heatmap provider arguments must be an object.',
        );
      }
      for (final entry in rawArguments.entries) {
        if (entry.key is! String) {
          throw const FormatException(
            'Heatmap provider argument keys must be strings.',
          );
        }
        arguments[entry.key as String] = JsonValue.fromJson(entry.value);
      }
    }
    try {
      return HeatmapViewportProviderDescriptor(
        providerId: providerId,
        seriesId: seriesId,
        initialViewport: HeatmapViewportRequest(
          minimumX: coordinate('minimumX'),
          maximumX: coordinate('maximumX'),
          minimumY: coordinate('minimumY'),
          maximumY: coordinate('maximumY'),
        ),
        arguments: arguments,
      );
    } on ArgumentError catch (error) {
      throw FormatException('Invalid Heatmap provider viewport: $error');
    }
  }
}

/// Fresh host runtime returned for one hydrated Heatmap provider descriptor.
@immutable
class HeatmapViewportProviderRuntime {
  const HeatmapViewportProviderRuntime({
    required this.controller,
    this.disposeController = true,
  });

  /// Host-created source/cache/residency controller.
  final HeatmapViewportController controller;

  /// Whether the hydrated chart owns and disposes [controller].
  final bool disposeController;
}

/// Creates a fresh provider runtime for one mounted hydrated chart.
typedef HeatmapViewportProviderFactory =
    HeatmapViewportProviderRuntime Function(
      HeatmapViewportProviderDescriptor descriptor,
      HeatmapChartSeries residentTemplate,
    );

/// Allowlisted host factories keyed by portable provider ID.
@immutable
class HeatmapViewportProviderRegistry {
  const HeatmapViewportProviderRegistry({this.factories = const {}});

  final Map<String, HeatmapViewportProviderFactory> factories;

  bool contains(String providerId) => factories.containsKey(providerId);

  HeatmapViewportProviderFactory? resolve(String providerId) =>
      factories[providerId];
}
