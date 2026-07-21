# Cartesian Value Summary Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Native, family-neutral Cartesian value summary: one config, two presentations (fixed overlay + draggable annotation-style), fed by a single immutable tracking snapshot, fully portable through artifacts/hydration/Source, demonstrated by a first-class showcase page.

**Architecture:** Extract crosshair resolution out of paint into a `CartesianTrackingSnapshotResolver` publishing an immutable `CartesianTrackingSnapshot` (identity-suppressed) consumed by the crosshair renderer, the synchronized-cursor path, and the new summary pipeline (policy reducer → family adapters → shared summary layout painted by an overlay element or a draggable annotation-style element in the foreground band). Config lives on `InteractionConfig.valueSummary`; style resolves through a flat `ChartTheme` component with summary-scoped tri-state overrides.

**Tech Stack:** Flutter ≥3.35 / Dart ≥3.9, package-internal rendering pipeline (no new deps).

## Global Constraints

- Spec of record: `docs/superpowers/specs/2026-07-20-cartesian-value-summary-architecture-handoff.md` + `...-slice0-decisions.md` (this worktree). Do-not-break rules and D1–D12 bind every task.
- Summary defaults to disabled; zero visual change to existing charts. `InteractionConfig.none()` disables it.
- One tracking resolution per interaction frame; no `setState` per pointer move; feedback-layer-only repaints; series caches untouched while tracking.
- Public names frozen: `CartesianValueSummaryConfig`, `CartesianValueSummaryPresentation.overlay/.annotation`, `ChartOverlayPlacement`, `CartesianValueSummaryValuePolicy`, `CartesianValueSummaryContent`, `CartesianValueSummaryStyle`, `ChartStyleValue<T>`, `CartesianTrackingSnapshot`, `CartesianTrackedSeriesValue`, `CartesianTrackingOrigin`, `CartesianValueSummaryController`, `CartesianValueSummaryTheme`.
- Capability string: `chart.cartesian.value-summary.v1`. Global artifact schemaVersion is NOT bumped.
- Verification commands (run from the worktree root `F:\Repositories\braven_charts-value-summary`): `flutter analyze lib`, `flutter test <paths>`, full `flutter test` at slice gates. Showcase: `flutter analyze` + `flutter test` in `example/`, run via `flutter run -d chrome` from `example/`.
- Commit after every green step pair (test + impl). Conventional commits. Never touch `F:\Repositories\braven_charts-candlestick-research` (read-only oracle).
- Every showcase surface built here is a permanent first-class example: registered page, options panel via shared widgets (`SliderOption` uses `suffix`/`decimalPlaces`), widget tests in `example/test/showcase/`.

---

### Task 0: Lane hygiene + baseline

**Files:**
- Delete: `lib/src/rendering/chart_render_box.dart.backup`
- Test: none (baseline run)

- [ ] **Step 1:** `git rm lib/src/rendering/chart_render_box.dart.backup`
- [ ] **Step 2:** Run `flutter analyze lib` → 0 issues; `flutter test` → all pass (record count as baseline); `cd example; flutter test` → all pass.
- [ ] **Step 3:** Commit `chore: remove stale chart_render_box backup; record lane baseline`

---

## SLICE 1 — Immutable tracking snapshot

### Task 1: Snapshot models

**Files:**
- Create: `lib/src/interaction/core/cartesian_tracking_snapshot.dart`
- Modify: `lib/braven_charts.dart` (export)
- Test: `test/unit/interaction/cartesian_tracking_snapshot_test.dart`

**Interfaces:**
- Produces: `CartesianTrackingSnapshot{ double dataX; double plotX; List<CartesianTrackedSeriesValue> values (unmodifiable); CartesianTrackingOrigin origin; ChartPointRef? primaryPoint; bool sameIdentityAs(CartesianTrackingSnapshot other); }`
- Produces: `enum CartesianTrackingOrigin { pointer, keyboard, synchronized, pinned, fallback }`
- Produces: `CartesianTrackedSeriesValue` mirroring every `CrosshairSeriesValue` field (`lib/src/models/interaction_config.dart:46-130`): `seriesId, seriesName, seriesColor, x, y, dataPointIndex, sourcePointIndices, isInterpolated, linkedSeriesId, isTrend, pointLabel`, scatter encoding trios (`magnitudeValue/formattedMagnitudeValue/magnitudeLabel`, color/opacity trios, `categoryValue/categoryLabel`), `CandlestickInteractionDetails? candlestick`, plus resolved formatting fields `formattedX`, `formattedY`, `unitLabel` (new — see correction 6), and `factory CartesianTrackedSeriesValue.fromCrosshairValue(CrosshairSeriesValue v, {required String formattedX, required String formattedY, String? unitLabel})`.

- [ ] **Step 1:** Write failing tests: construction produces unmodifiable `values` (mutation throws), `sameIdentityAs` true for equal series/point identity + formatted values and false when `dataPointIndex` or `formattedY` differ, `fromCrosshairValue` copies every field (exhaustive field assertion), `origin` preserved.
- [ ] **Step 2:** `flutter test test/unit/interaction/cartesian_tracking_snapshot_test.dart` → FAIL (types missing).
- [ ] **Step 3:** Implement models (immutable, `const`-friendly, `List.unmodifiable` in ctor; `sameIdentityAs` compares length + per-entry `seriesId`,`dataPointIndex`,`isTrend`,`formattedY`,`candlestick?.identityKey`). Export from `lib/braven_charts.dart`.
- [ ] **Step 4:** Tests pass; `flutter analyze lib` clean.
- [ ] **Step 5:** Commit `feat(interaction): add immutable CartesianTrackingSnapshot models`

### Task 2: Snapshot resolver (single resolution point)

**Files:**
- Create: `lib/src/interaction/core/tracking_snapshot_resolver.dart`
- Modify: `lib/src/rendering/modules/crosshair_renderer.dart` (extract 409-524 enrichment)
- Test: `test/unit/interaction/tracking_snapshot_resolver_test.dart`

**Interfaces:**
- Produces (internal, `@internal`): `CartesianTrackingSnapshotResolver{ CartesianTrackingSnapshot? resolve({required Offset cursorPlotPosition, required CrosshairTracker tracker, required List<ChartElement> elements, required MultiAxisInfo axisInfo, required CartesianTrackingOrigin origin, required bool includeTrends}); CartesianTrackingSnapshot? get current; bool get publishedThisFrame; int get debugResolveCount; int get debugPublishCount; void invalidate(); }`
- Consumes: `CrosshairTracker.calculateTrackingState` (`lib/src/interaction/core/crosshair_tracker.dart:179-210`), scatter 2D replacement logic currently at `crosshair_renderer.dart:425-471`, trend merge at `:474-496`, unit resolution via `SeriesAxisResolver.resolveAxis` currently inside `_paintTrackingTooltip` (`crosshair_renderer.dart:1198-1230`).

- [ ] **Step 1:** Failing unit tests: (a) resolve twice with same cursor/data → second call returns identical instance and `debugResolveCount` increments but `debugPublishCount` doesn't (change suppression); (b) cursor move to a new snapped datum → new snapshot published; (c) `invalidate()` forces re-resolution; (d) scatter replacement and trend inclusion behaviors via lightweight fake elements implementing the same `dataHitAt`/`evaluateAt` contracts the renderer uses.
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3:** Implement: move the enrichment bodies out of `CrosshairRenderer._paintTrackingMode` verbatim into the resolver (scatter replace/remove/add, trend append), then build `CartesianTrackedSeriesValue`s with formatting resolved via the axis info (port label/unit logic from `_paintTrackingTooltip` without altering its output strings). Cache by `(cursorPosition, transformRevision, dataRevision)`.
- [ ] **Step 4:** Tests pass; analyze clean.
- [ ] **Step 5:** Commit `feat(interaction): add CartesianTrackingSnapshotResolver with change suppression`

### Task 3: Renderer + synchronized path consume the snapshot

**Files:**
- Modify: `lib/src/rendering/modules/crosshair_renderer.dart` (`paint`/`_paintTrackingMode`/`_paintIntersectionMarkers`/`_paintTrackingTooltip` consume snapshot)
- Modify: `lib/src/rendering/chart_render_box.dart` (`:583-671` sync getter dedup; `:2716-2746` paint guard wiring; own the resolver instance; `debugSynchronizedTrackingState` reads `resolver.current`)
- Test: existing `test/` tracking/crosshair suites stay green; add `test/widgets/tracking_single_resolution_test.dart`

**Interfaces:**
- Consumes: Task 2 resolver. `CrosshairRenderer.paint` gains a `CartesianTrackingSnapshot? trackingSnapshot` parameter; internal painters take the snapshot's values instead of the mutable list.

- [ ] **Step 1:** Failing widget test: pump a 2-series line chart, hover, pump 3 extra frames without moving → `debugResolveCount` == 1 for the stationary cursor across repaints, and `debugSynchronizedTrackingState` equals `resolver.current` without extra resolutions (assert count unchanged after getter access).
- [ ] **Step 2:** Run → FAIL (current code re-resolves per repaint/getter).
- [ ] **Step 3:** Wire: render box resolves once per frame before crosshair paint (honoring `shouldUseTrackingMode` `crosshair_renderer.dart:181-186` and the aggregate-hover rewrite at `chart_render_box.dart:2702-2715`); `_synchronizedCursorPosition` and the debug hook read `resolver.current`; painters consume the snapshot.
- [ ] **Step 4:** Full `flutter test` → baseline count green (crosshair goldens unchanged). New test passes.
- [ ] **Step 5:** Commit `refactor(rendering): single tracking resolution per frame via snapshot resolver`

**SLICE 1 GATE:** full package test suite green; no golden diffs; resolve-count proof committed.

---

## SLICE 2 — Config, adapters, policy

### Task 4: Public config + tri-state style

**Files:**
- Create: `lib/src/models/chart_overlay_placement.dart`, `lib/src/models/chart_style_value.dart`, `lib/src/models/cartesian_value_summary_config.dart`
- Modify: `lib/src/models/interaction_config.dart` (field + `none()` at `:1170-1184` + equality at `:1464-1500`), `lib/braven_charts.dart`
- Test: `test/unit/models/cartesian_value_summary_config_test.dart`, `test/unit/models/chart_style_value_test.dart`

**Interfaces (complete public contract):**

```dart
class ChartOverlayPlacement {
  const ChartOverlayPlacement({required this.anchor, this.offset = Offset.zero});
  final Alignment anchor; final Offset offset;
  static const topLeft = ChartOverlayPlacement(anchor: Alignment.topLeft, offset: Offset(12, 12));
  ChartOverlayPlacement copyWith({Alignment? anchor, Offset? offset});
  // + ==, hashCode, toString
}

sealed class ChartStyleValue<T> {
  const factory ChartStyleValue.inherit() = ChartStyleInherit<T>;
  const factory ChartStyleValue.value(T value) = ChartStyleExplicit<T>;
  const factory ChartStyleValue.none() = ChartStyleNone<T>;
  T? resolve(T? themeDefault); // inherit→themeDefault, value→value, none→null
  bool get isNone; bool get isInherit;
}

enum CartesianValueSummaryValuePolicy { trackingThenLatest, trackingThenFirst, selectionThenTrackingThenLatest, pinnedThenTrackingThenLatest, explicitOnly }

sealed class CartesianValueSummaryPresentation {
  const factory CartesianValueSummaryPresentation.overlay({ChartOverlayPlacement placement}) = CartesianValueSummaryOverlay;
  const factory CartesianValueSummaryPresentation.annotation({ChartOverlayPlacement placement, bool draggable, bool clampToPlot}) = CartesianValueSummaryAnnotation;
}

sealed class CartesianValueSummaryContent {
  const factory CartesianValueSummaryContent.automatic({bool includeTrends, bool includeHiddenSeries}) = CartesianValueSummaryAutomaticContent;
  const factory CartesianValueSummaryContent.builder(CartesianValueSummaryRowBuilder builder, {String? descriptorId}) = CartesianValueSummaryBuilderContent; // non-portable unless descriptorId registered
}
typedef CartesianValueSummaryRowBuilder = CartesianValueSummaryContentModel Function(CartesianTrackingSnapshot snapshot);

class CartesianValueSummaryContentModel { final String? title; final String? subtitle; final Color? accentColor; final List<CartesianValueSummaryRow> rows; }
class CartesianValueSummaryRow { final String label; final String value; final Color? color; final String? semanticValue; }

class CartesianValueSummaryStyle {
  // every field ChartStyleValue-wrapped where clear-vs-inherit matters:
  final ChartStyleValue<Color> backgroundColor; final ChartStyleValue<double> backgroundOpacity;
  final ChartStyleValue<Color> borderColor; final ChartStyleValue<double> borderWidth;
  final ChartStyleValue<BorderRadius> borderRadius; final ChartStyleValue<EdgeInsets> padding;
  final ChartStyleValue<TextStyle> textStyle; final ChartStyleValue<TextStyle> labelStyle;
  final ChartStyleValue<Color> accentColor; final ChartStyleValue<BoxShadow> shadow;
  final ChartStyleValue<double> minWidth; final ChartStyleValue<double> maxWidth; final ChartStyleValue<double> rowGap;
  const CartesianValueSummaryStyle({/* all default ChartStyleValue.inherit() */});
}

class CartesianValueSummaryConfig {
  const CartesianValueSummaryConfig({this.enabled = false, this.presentation = const CartesianValueSummaryPresentation.overlay(), this.valuePolicy = CartesianValueSummaryValuePolicy.trackingThenLatest, this.content = const CartesianValueSummaryContent.automatic(), this.style = const CartesianValueSummaryStyle(), this.showSeriesAccent = true, this.announceChanges = false, this.onPlacementChanged, this.controller});
  final ValueChanged<ChartOverlayPlacement>? onPlacementChanged; // EXCLUDED from == (callback rule, interaction_config.dart:1464-1500)
  final CartesianValueSummaryController? controller;             // EXCLUDED from ==
}

abstract interface class CartesianValueSummaryController {
  ChartPointRef? get pinnedPoint; void pin(ChartPointRef point); void clearPin(); void resetPlacement();
}
```

- [ ] **Step 1:** Failing tests: defaults disabled; `const CartesianValueSummaryConfig() == const CartesianValueSummaryConfig()`; callbacks/controller excluded from equality; `InteractionConfig.none().valueSummary.enabled == false`; `ChartStyleValue` resolve matrix (inherit/value/none × themeDefault present/null).
- [ ] **Step 2:** Run → FAIL. **Step 3:** Implement + wire `valueSummary` into `InteractionConfig` (ctor, `copyWith`, `none()`, `==`/`hashCode` with sub-config value semantics). **Step 4:** Green + analyze. **Step 5:** Commit `feat(models): CartesianValueSummaryConfig public contract with tri-state style`

### Task 5: Policy reducer + family adapters

**Files:**
- Create: `lib/src/interaction/summary/value_summary_reducer.dart`, `lib/src/interaction/summary/value_summary_adapters.dart`
- Test: `test/unit/interaction/value_summary_reducer_test.dart`, `test/unit/interaction/value_summary_adapters_test.dart`

**Interfaces:**
- Produces (internal): `ValueSummaryReducer.reduce({required CartesianValueSummaryValuePolicy policy, CartesianTrackingSnapshot? tracking, ChartPointRef? pinned, ChartPointRef? selection, required CartesianTrackingSnapshot? Function(ChartPointRef) resolvePoint, required CartesianTrackingSnapshot? Function() latestVisible, required CartesianTrackingSnapshot? Function() firstVisible}) → CartesianTrackingSnapshot?` implementing spec precedence (pin → selection → tracking → deterministic fallback → null) with invalid-pin clearing.
- Produces (internal): `ValueSummaryAdapter.build(CartesianTrackingSnapshot snapshot, {required CartesianValueSummaryContent content, required bool showSeriesAccent}) → CartesianValueSummaryContentModel` with per-family rows exactly per spec §Content model (Line/Area name+X+Y+unit; Bar category+value+group context; Scatter X/Y+encodings; Candlestick label/timestamp+OHLC+change+direction via `CandlestickInteractionDetails`; mixed = one grouped section per series). Formatting reuses the snapshot's `formattedX/formattedY/unitLabel` — adapters never re-format numbers, never impose 2-decimals on non-financial series.

- [ ] **Step 1:** Failing unit matrix: every policy × {pin valid, pin invalid, selection, tracking, empty data, hidden series} (≥20 cases); adapter tests per family with hand-built snapshots asserting exact row labels/values incl. candlestick change % and scatter encoding rows; trend rows appear only when `includeTrends: true`.
- [ ] **Step 2:** FAIL. **Step 3:** Implement. **Step 4:** Green. **Step 5:** Commit `feat(interaction): value summary policy reducer and family adapters`

**SLICE 2 GATE:** full unit suite green; adapters proven against all 5 families + mixed.

---

## SLICE 3 — Overlay presentation + showcase (CHECKPOINT A)

### Task 6: Theme component

**Files:**
- Create: `lib/src/theming/components/cartesian_value_summary_theme.dart`
- Modify: `lib/src/models/chart_theme.dart` (register flat, `CandlestickTheme` pattern at `chart_theme.dart:59,108`), `lib/braven_charts.dart`
- Test: `test/unit/theming/cartesian_value_summary_theme_test.dart`

**Interfaces:** `CartesianValueSummaryTheme{ background, backgroundOpacity, border, borderWidth, borderRadius, padding, titleStyle, labelStyle, valueStyle, accentSize, shadow, minWidth, maxWidth, rowGap; static light/dark/highContrast/colorBlindSafe; lerp; copyWith }` — defaults mirror the prototype visual density (168 min width, 8px padding, 11px detail text, 8px accent).

- [ ] Steps: failing tests (presets differ, lerp endpoints, ChartTheme resolution light/dark) → implement → green → commit `feat(theming): CartesianValueSummaryTheme component with presets`.

### Task 7: Shared summary layout + overlay element

**Files:**
- Create: `lib/src/elements/value_summary_layout.dart` (text layout cache + paint: background/border/radius/shadow/accent/rows, effective-style resolution `style × theme` via `ChartStyleValue.resolve`), `lib/src/elements/value_summary_overlay_element.dart`
- Modify: `lib/src/elements/element_types.dart` (foreground render order for summary — above series, with crosshair band)
- Test: `test/unit/elements/value_summary_layout_test.dart`, `test/golden/value_summary/value_summary_overlay_golden_test.dart` (4 anchors × light/dark, none-background, 2.0 text scale, RTL)

**Interfaces:**
- Produces: `ValueSummaryLayout.layout(CartesianValueSummaryContentModel, effectiveStyle, {maxWidth, textScale, textDirection}) → ValueSummaryLayoutResult{Size size; void paint(Canvas, Offset)}` with cache keyed on (content identity, style, scale, direction).
- Produces: `ValueSummaryOverlayElement` — screen-space anchored via `ChartOverlayPlacement` against plot rect (RTL-aware: `Alignment` resolved with text direction), `hitTest` always false (pass-through), renders in foreground band, repaints on snapshot publication only.

- [ ] Steps: failing layout unit tests (cache hit on identical inputs; none-background paints nothing; row gap/min-max width honored) + goldens → implement → green (record goldens) → commit `feat(elements): shared value summary layout and fixed overlay element`.

### Task 8: Pipeline wiring in the chart

**Files:**
- Modify: `lib/src/braven_chart_plus.dart` (config plumb-through), `lib/src/rendering/chart_render_box.dart` (own reducer+adapter, feed overlay element from resolver publication; suspend during pan/zoom per spec §lifecycle; pointer-exit keeps pin/fallback), `lib/src/interaction/core/coordinator.dart` only if a suspend hook is required
- Test: `test/widgets/value_summary_overlay_test.dart`

- [ ] **Step 1:** Failing widget tests: enabled summary shows latest-fallback rows with no pointer; hover updates rows once per datum change (count via `debugResolveCount`/publish count); pointer exit keeps fallback per policy; disabled/none() renders nothing; crosshair/tooltip/axis-labels unaffected (independence assertions); no series-picture invalidation during tracking (existing debug counters); `CartesianValueSummaryController.pin/clearPin` drive the reducer (pinned datum shown while hovering elsewhere under `pinnedThenTrackingThenLatest`) and a data replacement that removes the pinned point clears the pin and falls through the policy.
- [ ] **Step 2:** FAIL. **Step 3:** Wire. **Step 4:** Green + full package suite. **Step 5:** Commit `feat(chart): native cartesian value summary overlay pipeline`

### Task 9: Showcase page (first-class) — CHECKPOINT A

**Files:**
- Create: `example/lib/showcase/pages/value_summary_page.dart`
- Modify: `example/lib/showcase/showcase_app.dart` (NavDestination, slug `value-summary`), `example/lib/showcase/widgets/chart_type_catalog.dart` NOT touched (feature page, not family)
- Test: `example/test/showcase/value_summary_page_test.dart`

**Content (permanent example, prototype-parity controls):** presets `Line`, `Multi-series`, `Multi-axis`, `Candlestick OHLC`, `Synchronized pair`; options panel: enabled, presentation kind, anchor (4 corners), offset sliders, policy dropdown, accent toggle, background/border color + clear toggles (tri-state exercised), opacity, radius, padding, text scale hint, announceChanges. `ChartPageLayout` + `OptionsPanel` per repo pattern.

- [ ] Steps: failing widget test (page builds, preset switch, summary visible, clear-background truly transparent) → implement → green → `cd example; flutter analyze && flutter test` → commit `feat(showcase): first-class value summary page` → **CHECKPOINT A: launch `flutter run -d chrome` for user testing.**

**SLICE 3 GATE:** package + example suites green; goldens recorded; user has a running app.

---

## SLICE 4 — Annotation presentation (CHECKPOINT B)

### Task 10: Draggable annotation-style element

**Files:**
- Create: `lib/src/elements/value_summary_annotation_element.dart`
- Modify: `lib/src/rendering/modules/event_handler_manager.dart` (drag acquisition alongside existing annotation drag at the Text/Legend drag sites; continuous preview + single committed `onPlacementChanged`; move cursor; coordinator `draggingAnnotation` claim; tracking suspended while dragging), `lib/src/rendering/chart_render_box.dart` (keyboard arrows ±1px, Shift ±10px when focused; focus semantics)
- Test: `test/widgets/value_summary_annotation_test.dart`

**Interfaces:** same `ValueSummaryLayout`; position = `ChartOverlayPlacement` anchor+offset in plot-screen space; drag updates offset relative to anchor; `clampToPlot` clamps final rect on drag AND resize; hit test true only within bounds when `draggable`.

- [ ] **Step 1:** Failing widget tests: drag moves panel and emits exactly one `onPlacementChanged` on release with correct anchor-relative offset; tracking/crosshair state frozen during drag (no hover callbacks — spec do-not-break); clamp on resize; keyboard arrows move when focused, Shift ×10; `resetPlacement()` restores configured placement; drag never selects points beneath.
- [ ] **Step 2:** FAIL. **Step 3:** Implement (reuse EventHandlerManager's live drag pattern — NOT the dead `annotation_drag_handler.dart`). **Step 4:** Green + full suite. **Step 5:** Commit `feat(elements): draggable annotation-style value summary`

### Task 11: Showcase draggable preset — CHECKPOINT B

**Files:** Modify `example/lib/showcase/pages/value_summary_page.dart` (+`Draggable panel` preset, drag/reset/pin controls once controller lands), test additions.

- [ ] Steps: failing test → implement → green → commit `feat(showcase): draggable value summary preset` → **CHECKPOINT B: relaunch app for user.**

**SLICE 4 GATE:** package + example green; drag E2E proven.

---

## SLICE 5 — Portability

### Task 12: Artifact codec + hydration + capability

**Files:**
- Modify: `lib/src/artifacts/chart_interaction_document_codec.dart` (encode-only-when-non-default sub-config; tri-state encoding: absent=inherit, `"none"` token=cleared; runtime `descriptorId` binding via existing pattern), `lib/src/artifacts/chart_document_extractor.dart` + capability list (`chart.cartesian.value-summary.v1`), `lib/src/artifacts/chart_document_hydrator.dart` (rebuild config; unknown enum → diagnostic; missing descriptor → omitted-dependency diagnostic)
- Test: `test/unit/artifacts/cartesian_value_summary_codec_test.dart`

- [ ] Steps: failing round-trip matrix (default omitted; full config incl. `.none()` colors and annotation placement survives encode→decode; unknown policy string → diagnostic; old artifact without field → disabled) → implement → green → commit `feat(artifacts): value summary codec, capability, hydration`.

### Task 13: Source generation + Workbench

**Files:**
- Modify: `lib/src/source/chart_dart_source_generator.dart` + `chart_source_models.dart` (emit `CartesianValueSummaryConfig` constructor incl. tri-state forms; builder content → omitted-dependency comment diagnostic, never stale text), Workbench verification in `test/widgets/braven_chart_workbench_test.dart` additions
- Test: `test/unit/source/value_summary_source_test.dart` + extend `chart_generated_source_compile_test.dart`

- [ ] Steps: failing tests (generated Dart compiles and equals config; `.none()` survives; Split mode shows one summary, no duplicate callbacks) → implement → green → commit `feat(source): emit value summary config in generated Dart`.

**SLICE 5 GATE:** artifact→hydrate→Source→compile round-trip green.

---

## SLICE 6 — Performance, a11y proof, docs (CHECKPOINT C)

### Task 14: Perf counters + benchmarks

**Files:**
- Create: `test/benchmarks/interaction/value_summary_benchmark_test.dart`
- Modify: debug counters already added in Tasks 2/8 exposed via existing debug hooks
- Test: benchmark asserts + counter proofs

Matrix (spec §benchmarks): 5k line+area no-regression vs crosshair-only; 50k line overlay update < 16.7ms p95 (Stopwatch harness per repo pattern; note p95-raster harness gap per D12 — assert resolver/publish counts + build timing, document raster as manual); 2k candlestick zero cache invalidation while tracking; dense scatter no second O(N) scan (resolve-count proof); 3 synchronized charts = 1 broadcast + 1 local resolution each; drag = continuous paint, 1 commit.

- [ ] Steps: write benchmarks → run → record numbers in test comments → commit `perf(interaction): value summary benchmark matrix and counters`.

### Task 15: Semantics + docs + release gates — CHECKPOINT C

**Files:**
- Modify: summary elements (grouped semantic region: title, context, labelled values; `announceChanges` debounced by datum identity), `doc/` new `doc/value_summary.md`, `CHANGELOG.md` Unreleased entry, `doc/feature_matrix.md` row
- Test: `test/widgets/value_summary_semantics_test.dart`

- [ ] Steps: failing semantics tests (one grouped node, no crosshair duplication, debounced announcements) → implement → green → docs → full gates: `flutter analyze lib` + full `flutter test` + `cd example; flutter analyze && flutter test` + `dart pub publish --dry-run` → commit `feat(a11y+docs): value summary semantics, guide, changelog` → **CHECKPOINT C: final app run for user → PR on approval.**

**LANE DONE per spec Definition of Done.**
