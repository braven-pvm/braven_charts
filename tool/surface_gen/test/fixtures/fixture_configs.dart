/// Fixture config family for the surface reader tests.
///
/// This library is never imported by test code. The reader test loads this
/// file's CONTENT into `resolveSources` as an in-memory asset, so everything
/// the reader must resolve — including the `ChartSurface` annotation
/// contract — is mirrored here verbatim. `surface_gen` cannot depend on the
/// Flutter package, so the reader matches annotations and framework-shaped
/// types (`ChartSurface`, `ChartStyleValue`, `Listenable`) BY NAME + shape,
/// library-agnostically; these mirrors exercise exactly that contract.
///
/// The family exercises every classification rule from the plan:
/// - enum param, nested-config param, tri-state param
/// - function-typed params (inline function type + typedef alias)
/// - controller params (Listenable-implementing and `*Controller`-named)
/// - clear-flag copyWith booleans (scatter shape)
/// - assert-coupled pair with `CombinedSetter` metadata
/// - sealed hierarchy with `sealedVariants` metadata
/// - preset factories
/// - a YAxisConfig-shaped class (non-const public ctor + private const
///   `_internal`) and a non-const class without an `_internal` pathway
/// - super-parameter forwarding (LineChartSeries shape)
library;

// ---------------------------------------------------------------------------
// Mirrored annotation contract — verbatim shape of lib/src/meta/chart_surface.dart
// ---------------------------------------------------------------------------

/// Marks a public config/style/series class for surface generation.
class ChartSurface {
  const ChartSurface({
    this.presetFactories = const <String>[],
    this.sealedVariants = const <String>[],
    this.combinedSetters = const <CombinedSetter>[],
    this.excluded = const <String>[],
    this.clearFlags = const <String, String>{},
  });

  final List<String> presetFactories;
  final List<String> sealedVariants;
  final List<CombinedSetter> combinedSetters;
  final List<String> excluded;
  final Map<String, String> clearFlags;
}

/// Couples assert-linked constructor parameters into a single setter.
class CombinedSetter {
  const CombinedSetter(this.name, this.params);

  final String name;
  final List<String> params;
}

/// Exempts a barrel-reachable config-shaped class from enforcement.
class ChartSurfaceExempt {
  const ChartSurfaceExempt(this.reason);

  final String reason;
}

const chartSurface = ChartSurface();

// ---------------------------------------------------------------------------
// Mirrored framework-shaped types (matched by the reader BY NAME)
// ---------------------------------------------------------------------------

/// Mirror of Flutter's `Listenable` — matched by name in the supertype walk.
class Listenable {
  const Listenable();
}

/// Mirror of the package's tri-state `ChartStyleValue` — matched by name.
class ChartStyleValue<T> {
  const ChartStyleValue.value(T this.raw) : state = 'value';
  const ChartStyleValue.none() : raw = null, state = 'none';
  const ChartStyleValue.inherit() : raw = null, state = 'inherit';

  final T? raw;
  final String state;
}

// ---------------------------------------------------------------------------
// Supporting fixture types
// ---------------------------------------------------------------------------

enum FixtureMode { off, auto, on }

typedef FixtureLabelFormatter = String Function(double value);

/// Listenable-implementing type whose name does NOT end in `Controller`:
/// exercises the supertype-walk controller rule in isolation.
class FixtureSyncNotifier extends Listenable {
  const FixtureSyncNotifier();
}

/// `*Controller`-named type that is NOT a Listenable: exercises the
/// name-suffix controller rule in isolation.
class FixturePanController {
  const FixturePanController();
}

// ---------------------------------------------------------------------------
// Nested config
// ---------------------------------------------------------------------------

@chartSurface
class FixtureNestedStyle {
  const FixtureNestedStyle({this.opacity = 1.0});

  final double opacity;

  FixtureNestedStyle copyWith({double? opacity}) =>
      FixtureNestedStyle(opacity: opacity ?? this.opacity);
}

// ---------------------------------------------------------------------------
// Sealed hierarchy (owner annotated with sealedVariants metadata)
// ---------------------------------------------------------------------------

@ChartSurface(
  sealedVariants: ['FixtureOverlayPresentation', 'FixtureAnnotationPresentation'],
)
sealed class FixturePresentation {
  const FixturePresentation();
}

final class FixtureOverlayPresentation extends FixturePresentation {
  const FixtureOverlayPresentation({this.pinned = true});

  final bool pinned;
}

final class FixtureAnnotationPresentation extends FixturePresentation {
  const FixtureAnnotationPresentation({this.draggable = false});

  final bool draggable;
}

// ---------------------------------------------------------------------------
// Main const config: every classification rule in one class
// (CrosshairConfig shape: const ctor + defaults + asserts + factories)
// ---------------------------------------------------------------------------

@ChartSurface(
  presetFactories: ['tracking', 'defaultConfig'],
  combinedSetters: [
    CombinedSetter('withVisibleRange', ['min', 'max']),
  ],
  excluded: ['debugTag'],
  clearFlags: {
    'overlayStyle': 'clearOverlayStyle',
    'highlightText': 'clearHighlightText',
  },
)
class FixtureCrosshairConfig {
  const FixtureCrosshairConfig({
    required this.id,
    this.enabled = true,
    this.mode = FixtureMode.auto,
    this.snapRadius = 20.0,
    this.min,
    this.max,
    this.label,
    this.nested = const FixtureNestedStyle(),
    this.presentation = const FixtureOverlayPresentation(),
    this.accentColor = const ChartStyleValue<double>.inherit(),
    this.panelText = const ChartStyleValue<String>.inherit(),
    this.onTap,
    this.formatter,
    this.syncNotifier,
    this.panController,
    this.overlayStyle,
    this.highlightText,
    this.dashPattern = const <double>[2, 6],
    this.metadata = const <String, int>{},
    this.debugTag,
  })  : assert(snapRadius >= 0, 'snapRadius must be non-negative'),
        assert(
          min == null || max == null || min < max,
          'min must be less than max',
        );

  factory FixtureCrosshairConfig.tracking({bool interpolate = true}) =>
      FixtureCrosshairConfig(id: 'tracking', enabled: interpolate);

  factory FixtureCrosshairConfig.defaultConfig() =>
      const FixtureCrosshairConfig(id: 'default');

  final String id;
  final bool enabled;
  final FixtureMode mode;
  final double snapRadius;
  final double? min;
  final double? max;
  final String? label;
  final FixtureNestedStyle nested;
  final FixturePresentation presentation;
  final ChartStyleValue<double> accentColor;
  final ChartStyleValue<String> panelText;
  final void Function()? onTap;
  final FixtureLabelFormatter? formatter;
  final FixtureSyncNotifier? syncNotifier;
  final FixturePanController? panController;
  final FixtureNestedStyle? overlayStyle;
  final String? highlightText;
  final List<double> dashPattern;
  final Map<String, int> metadata;
  final String? debugTag;

  FixtureCrosshairConfig copyWith({
    String? id,
    bool? enabled,
    FixtureMode? mode,
    double? snapRadius,
    double? min,
    double? max,
    String? label,
    FixtureNestedStyle? nested,
    FixturePresentation? presentation,
    ChartStyleValue<double>? accentColor,
    ChartStyleValue<String>? panelText,
    void Function()? onTap,
    FixtureLabelFormatter? formatter,
    FixtureSyncNotifier? syncNotifier,
    FixturePanController? panController,
    FixtureNestedStyle? overlayStyle,
    bool clearOverlayStyle = false,
    String? highlightText,
    bool clearHighlightText = false,
    List<double>? dashPattern,
    Map<String, int>? metadata,
    String? debugTag,
  }) {
    return FixtureCrosshairConfig(
      id: id ?? this.id,
      enabled: enabled ?? this.enabled,
      mode: mode ?? this.mode,
      snapRadius: snapRadius ?? this.snapRadius,
      min: min ?? this.min,
      max: max ?? this.max,
      label: label ?? this.label,
      nested: nested ?? this.nested,
      presentation: presentation ?? this.presentation,
      accentColor: accentColor ?? this.accentColor,
      panelText: panelText ?? this.panelText,
      onTap: onTap ?? this.onTap,
      formatter: formatter ?? this.formatter,
      syncNotifier: syncNotifier ?? this.syncNotifier,
      panController: panController ?? this.panController,
      overlayStyle: clearOverlayStyle ? null : (overlayStyle ?? this.overlayStyle),
      highlightText:
          clearHighlightText ? null : (highlightText ?? this.highlightText),
      dashPattern: dashPattern ?? this.dashPattern,
      metadata: metadata ?? this.metadata,
      debugTag: debugTag ?? this.debugTag,
    );
  }
}

// ---------------------------------------------------------------------------
// YAxisConfig-shaped class: NON-const public unnamed ctor with initializer
// normalization + asserts, private const `_internal` with explicit `id`,
// and a `withId` preset factory. The reader must select `_internal` and the
// internal-only `id` param must be force-excluded via annotation metadata.
// ---------------------------------------------------------------------------

@ChartSurface(
  presetFactories: ['withId'],
  combinedSetters: [
    CombinedSetter('withVisibleRange', ['min', 'max']),
  ],
  excluded: ['id'],
)
class FixtureAxisConfig {
  FixtureAxisConfig({
    required FixtureMode mode,
    this.label,
    this.min,
    this.max,
    bool visible = true,
    this.minWidth = 0.0,
  })  : id = '',
        mode = mode == FixtureMode.off ? FixtureMode.auto : mode,
        visible = mode == FixtureMode.off ? false : visible,
        assert(minWidth >= 0, 'minWidth must be non-negative'),
        assert(
          min == null || max == null || min < max,
          'min must be less than max',
        );

  const FixtureAxisConfig._internal({
    required this.id,
    required this.mode,
    this.label,
    this.min,
    this.max,
    bool visible = true,
    this.minWidth = 0.0,
  }) : visible = mode == FixtureMode.off ? false : visible;

  factory FixtureAxisConfig.withId({
    required String id,
    required FixtureMode mode,
    String? label,
    double? min,
    double? max,
    bool visible = true,
    double minWidth = 0.0,
  }) {
    return FixtureAxisConfig._internal(
      id: id,
      mode: mode,
      label: label,
      min: min,
      max: max,
      visible: visible,
      minWidth: minWidth,
    );
  }

  final String id;
  final FixtureMode mode;
  final String? label;
  final double? min;
  final double? max;
  final bool visible;
  final double minWidth;

  FixtureAxisConfig copyWith({
    FixtureMode? mode,
    String? label,
    double? min,
    double? max,
    bool? visible,
    double? minWidth,
  }) {
    return FixtureAxisConfig._internal(
      id: id,
      mode: mode ?? this.mode,
      label: label ?? this.label,
      min: min ?? this.min,
      max: max ?? this.max,
      visible: visible ?? this.visible,
      minWidth: minWidth ?? this.minWidth,
    );
  }
}

// ---------------------------------------------------------------------------
// Non-const unnamed ctor WITHOUT an `_internal` pathway: the reader falls
// back to reading the unnamed constructor and reports it non-const.
// ---------------------------------------------------------------------------

@chartSurface
class FixtureMutableConfig {
  FixtureMutableConfig({this.scale = 1.0});

  final double scale;

  FixtureMutableConfig copyWith({double? scale}) =>
      FixtureMutableConfig(scale: scale ?? this.scale);
}

// ---------------------------------------------------------------------------
// Super-parameter forwarding (ChartSeries/LineChartSeries shape)
// ---------------------------------------------------------------------------

@chartSurface
class FixtureSeriesBase {
  const FixtureSeriesBase({
    required this.id,
    this.name,
    this.unit,
    this.ordered = false,
  });

  final String id;
  final String? name;
  final String? unit;
  final bool ordered;

  FixtureSeriesBase copyWith({
    String? id,
    String? name,
    String? unit,
    bool? ordered,
  }) {
    return FixtureSeriesBase(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      ordered: ordered ?? this.ordered,
    );
  }
}

@chartSurface
class FixtureLineSeries extends FixtureSeriesBase {
  const FixtureLineSeries({
    required super.id,
    super.name,
    super.unit,
    super.ordered = false,
    this.strokeWidth = 2.0,
    this.interpolation = FixtureMode.auto,
    this.dashPattern = const <double>[],
  });

  final double strokeWidth;
  final FixtureMode interpolation;
  final List<double> dashPattern;

  @override
  FixtureLineSeries copyWith({
    String? id,
    String? name,
    String? unit,
    bool? ordered,
    double? strokeWidth,
    FixtureMode? interpolation,
    List<double>? dashPattern,
  }) {
    return FixtureLineSeries(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      ordered: ordered ?? this.ordered,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      interpolation: interpolation ?? this.interpolation,
      dashPattern: dashPattern ?? this.dashPattern,
    );
  }
}
