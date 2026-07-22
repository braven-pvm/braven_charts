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
    this.bodyValidated = const <BodyValidated>[],
    this.paramNotes = const <String, String>{}, // paramName -> verb dartdoc caveat
  });

  final List<String> presetFactories;
  final List<String> sealedVariants;
  final List<CombinedSetter> combinedSetters;
  final List<String> excluded;
  final Map<String, String> clearFlags;

  /// Acknowledgements for constructor-BODY validation the surface model
  /// cannot express. See [BodyValidated].
  final List<BodyValidated> bodyValidated;

  /// Parameter name -> a caveat appended to that parameter's generated verb
  /// dartdoc.
  ///
  /// For a truth about a verb that the generator cannot derive and cannot
  /// fix. `TextAnnotation.withText` is the canonical case: the reader models
  /// the public plain-text constructor while `copyWith` rebuilds through
  /// `_internal`, so `withText` type-checks on every instance and is a no-op
  /// on a RICH one. Excluding `text` would delete the primary verb on a
  /// plain annotation, so the verb stays and states what it does not do.
  ///
  /// A note for an unknown or EXCLUDED parameter fails the build: it has no
  /// generated verb to carry it, and documentation nobody can read is worse
  /// than none. Document an exclusion in the class's own dartdoc instead.
  final Map<String, String> paramNotes;
}

/// Couples assert-linked constructor parameters into a single generated
/// setter so no fluent chain step can construct an invalid intermediate
/// config.
class CombinedSetter {
  const CombinedSetter(this.name, this.params); // e.g. CombinedSetter('withVisibleRange', ['min', 'max'])

  final String name;
  final List<String> params;
}

/// Acknowledges that a generative constructor validates parameters in its
/// BODY rather than in `assert` initializers.
///
/// A non-empty constructor body on an annotated class is an unmodelled-
/// validation signal: `surface_gen` can see the statements but cannot know
/// which invariant they enforce, so it cannot prove a generated `withX(...)`
/// produces a value the constructor accepts. Five classes shipped verbs that
/// throw at runtime exactly this way (`CandlestickDataPoint.withHigh(1)` on a
/// candle whose `low` is 99, `PieChartSeries.withPieStyle(...)` with a
/// `radiusFactor` the series — but not the style — rejects).
///
/// The reader therefore refuses to model such a class until every emitted
/// parameter the body could reach is discharged, by one of:
///
/// 1. a [CombinedSetter] over the coupled parameters, when they are genuinely
///    a unit (`CandlestickDataPoint`'s `open`/`high`/`low`/`close`);
/// 2. `excluded`, when no single verb could keep the invariant (a series'
///    `points` length-coupled to a sibling collection);
/// 3. this acknowledgement, when the coupling is real but inexpressible —
///    typically an opaque `validate()` call, or a nested config whose legal
///    range narrows inside its owner.
///
/// [reason] must explain what the body enforces and what a caller can still
/// trip; the assert rejects placeholders. [params] names the parameters the
/// acknowledgement covers, or is left empty to cover every parameter of the
/// class (the only honest option when the body's statements never name a
/// parameter, because the reader cannot then tell which ones are reachable).
class BodyValidated {
  const BodyValidated(this.reason, {this.params = const <String>[]})
    : assert(
        reason.length >= 12,
        'BodyValidated needs a real reason (>= 12 characters) explaining '
        'what the constructor body validates and what a fluent verb can '
        'still trip at runtime.',
      );

  final String reason;
  final List<String> params;
}

/// Exempts a barrel-reachable config-shaped class from enforcement.
///
/// An exemption is a permanent hole in the surface model, so [reason] must
/// explain WHY generation is wrong for this class — the assert rejects
/// placeholders like `''`, `'n/a'` or `'TODO'`. Every exemption is also
/// printed and count-pinned by `test/meta/surface_enforcement_test.dart`, so
/// adding one is a deliberate, reviewed act.
class ChartSurfaceExempt {
  const ChartSurfaceExempt(this.reason)
    : assert(
        reason.length >= 12,
        'ChartSurfaceExempt needs a real reason (>= 12 characters) '
        'explaining why this class must not be generated.',
      );

  final String reason;
}

const chartSurface = ChartSurface();
