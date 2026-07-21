/// Surface-generation marker annotations for the chart config surface.
///
/// Package-internal: NOT exported from any barrel. Classes annotated with
/// [chartSurface] are read by the dev-only `tool/surface_gen` generator into
/// a `SurfaceModel` that drives the generated fluent extensions and the AI
/// schema mirror. This library must stay pure Dart (no Flutter imports) so
/// the generator toolchain can load it.
library;

/// Marks a public config/style/series class for surface generation.
class ChartSurface {
  const ChartSurface({
    this.presetFactories = const <String>[], // e.g. ['tracking', 'defaultConfig']
    this.sealedVariants = const <String>[], // subclass names for sealed owners
    this.combinedSetters = const <CombinedSetter>[],
    this.excluded = const <String>[], // param names to force-exclude
    this.clearFlags = const <String, String>{}, // paramName -> copyWith clear flag name
  });

  final List<String> presetFactories;
  final List<String> sealedVariants;
  final List<CombinedSetter> combinedSetters;
  final List<String> excluded;
  final Map<String, String> clearFlags;
}

/// Couples assert-linked constructor parameters into a single generated
/// setter so no fluent chain step can construct an invalid intermediate
/// config.
class CombinedSetter {
  const CombinedSetter(this.name, this.params); // e.g. CombinedSetter('withVisibleRange', ['min', 'max'])

  final String name;
  final List<String> params;
}

/// Exempts a barrel-reachable config-shaped class from enforcement.
class ChartSurfaceExempt {
  const ChartSurfaceExempt(this.reason);

  final String reason;
}

const chartSurface = ChartSurface();
