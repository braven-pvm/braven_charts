# Native Cartesian Value Summary — Architecture, Feature, and Lane Handoff

**Date:** 2026-07-20  
**Status:** Architecture ready; both presentations proven in the Candlestick showcase; native package implementation not started  
**Recommended lane:** `feature/cartesian-value-summary`  
**Depends on:** the Candlestick family and its typed interaction payload landing on `master`  
**Prototype:** `example/lib/showcase/pages/candlestick_charts_page.dart`  
**Owning surface:** every built-in Cartesian family rendered by `BravenChartPlus`

## Executive decision

Promote the Candlestick showcase's pinned OHLC summary into a native,
family-neutral Cartesian value-summary feature.

The native feature must provide two presentations from one configuration and
one resolved data snapshot:

1. a fixed overlay anchored inside the plot; and
2. an in-plot, optionally draggable summary that behaves like a chart
   annotation.

This must not be implemented as a reusable showcase `Stack`, as a second
tooltip, or as application code that rewrites `TextAnnotation.rich` whenever
the pointer moves. Those approaches reproduce the current visuals but do not
create a portable Cartesian contract.

The implementation should expose the renderer's already-resolved tracking
state, adapt it into typed summary rows, and paint the selected presentation
without rebuilding chart geometry. Configuration must survive chart artifacts,
hydration, and generated Dart Source. Transient hover state must not.

## Product outcome

A chart author can keep the current Cartesian value visible without relying on
a floating pointer tooltip:

```dart
BravenChartPlus(
  series: series,
  interactionConfig: InteractionConfig(
    valueSummary: CartesianValueSummaryConfig(
      enabled: true,
      presentation: CartesianValueSummaryPresentation.overlay(
        placement: ChartOverlayPlacement.topLeft,
      ),
      valuePolicy: CartesianValueSummaryValuePolicy.trackingThenLatest,
      content: CartesianValueSummaryContent.automatic(),
    ),
  ),
)
```

The same content can be embedded and moved inside the plot:

```dart
valueSummary: CartesianValueSummaryConfig(
  enabled: true,
  presentation: CartesianValueSummaryPresentation.annotation(
    placement: ChartOverlayPlacement(
      anchor: Alignment.topLeft,
      offset: Offset(12, 12),
    ),
    draggable: true,
  ),
  valuePolicy: CartesianValueSummaryValuePolicy.trackingThenLatest,
)
```

The feature is successful only when Line, Area, Bar, Scatter, and Candlestick
all receive correct typed rows; multi-series and multi-axis charts reuse the
same resolved X sample; theme and accessibility behavior are first-class; and
the full behavior is represented in Workbench Data, artifacts, hydration, and
Source.

## What the prototype proved

The Candlestick showcase proves the product shape, not the final architecture.

| Capability | Proven implementation | Native implication |
|---|---|---|
| Fixed presentation | Flutter `Stack` + `Positioned` + `IgnorePointer` | Native overlay needs plot-aware placement and pass-through hit testing |
| Embedded presentation | `TextAnnotation.rich` with screen-space position | Native summary needs annotation-like placement and drag behavior |
| Active value | `onPointHover` / `onPointTap` into a `ValueNotifier` | Resolved interaction state must become an internal shared output |
| Empty-state fallback | Latest visible candle | Value-source policy must be explicit and family-neutral |
| OHLC content | Typed `CandlestickDataPoint` rows | Row adapters must consume typed renderer payloads |
| Styling | Shared background, border, text, accent, radius, padding, and font controls | One public style model must drive both presentations |
| Clear colors | Explicit visibility flags produce true transparency | Nullable/cleared values must not silently restore theme fallbacks |
| Movement | `onAnnotationDragged` stores a new screen position | Placement state needs resize-safe anchor + offset semantics |
| Accessibility | Overlay card has a grouped semantic label | Native semantics must be shared between presentations |

The prototype also established a good default visual density: 168 logical
pixels wide, 8 pixels of padding, 11-pixel detail text, an 8-pixel accent mark,
and two-decimal financial values. These are Candlestick showcase defaults, not
hard-coded package constraints.

## Why the current composition is not the final feature

### The overlay is outside the chart contract

The overlay is a showcase widget layered above `BravenChartPlus`. The renderer
does not know it exists, so it cannot resolve collisions, include it in
artifacts or Source, coordinate semantics, or prevent redundant work across
synchronized charts.

### The `TextAnnotation` contains a snapshot, not a binding

`TextAnnotation.rich` is portable and draggable, but its Delta contains the
currently rendered strings. It does not encode "follow tracking, otherwise
show the latest datum". Serializing the prototype preserves one card's text,
not the behavior that keeps it current.

### Public callbacks are being used as an internal state bus

The prototype listens to `onPointHover` and `onPointTap`. A native feature must
not consume, replace, or chain application callbacks to learn what the renderer
already resolved. User callbacks remain notifications; they are not internal
state transport.

### Crosshair resolution is trapped in paint

`CrosshairTracker.calculateTrackingState` already produces
`CrosshairTrackingState` with per-series `CrosshairSeriesValue` entries and a
typed Candlestick payload. `CrosshairRenderer` enriches that state for Scatter
and trend annotations, then immediately paints it. The new lane must extract a
single resolved snapshot that both crosshair feedback and the summary consume.

## Scope boundaries

### In scope for native v1

- All built-in Cartesian series: Line, Area, Bar, Scatter, and Candlestick.
- Single- and multi-series charts, including multi-axis values.
- Fixed plot overlay and draggable in-plot annotation-style presentations.
- Tracking, focused/selected point, explicitly pinned point, and deterministic
  fallback policies.
- Automatic family-specific rows plus a constrained custom-content escape
  hatch.
- Shared styling, adaptive theme defaults, clear/no-surface semantics, RTL,
  keyboard, and accessibility.
- Controller support for pin, unpin, and placement reset.
- Artifact encoding, hydration, generated Dart Source, and Workbench support.
- Synchronized charts consuming a shared X while resolving local series rows.
- Performance coverage for high-density and multi-chart tracking.

### Explicitly out of scope for native v1

- Arbitrary application widgets inside the renderer's canvas.
- HTML/Markdown or a general document editor inside the summary.
- Automatic technical indicators or financial analytics.
- Persisting the last hovered value in an artifact.
- Cross-chart aggregation into one global dashboard card.
- Collision-free automatic layout among every annotation and tooltip.
- Polar, Pie, Donut, Concentric Donut, or other non-Cartesian families.

## Terminology and separation from existing feedback

The public name is **Cartesian value summary**. “Pinned OHLC summary” remains a
Candlestick showcase label only.

| Layer | Lifetime | Position | Content |
|---|---|---|---|
| Crosshair tracking panel | Pointer/focus tracking | Near cursor | Values for the active X |
| Point tooltip | Direct mark hover or selection | Near mark/cursor | One directly hit datum |
| Axis value labels | Pointer/focus tracking | Axis edges | Compact X/Y coordinates |
| Intersection marker | Pointer/focus tracking | Series intersection | Visual mark only |
| Cartesian value summary | Persistent while enabled | Fixed overlay or movable plot panel | Current policy-resolved datum/series values |

Enabling the summary must not implicitly enable any of the other four layers.
Each remains independently configurable.

## Native target architecture

### Component boundary

Add `CartesianValueSummaryConfig` to `InteractionConfig`. The feature is
interaction-derived, but persistent in presentation. Keeping it beside
crosshair and tooltip configuration makes the independence of all feedback
layers explicit while allowing them to share resolved tracking state.

The minimum internal decomposition is:

```text
pointer / keyboard / synchronized X / controller pin
                    |
                    v
       CartesianTrackingSnapshotResolver
                    |
          immutable resolved snapshot
                    |
          CartesianValueSummaryAdapter
                    |
             typed display rows
                    |
       +------------+-------------+
       |                          |
       v                          v
overlay summary element     annotation summary element
```

One resolver owns nearest-point/interpolation work. Renderers consume the same
immutable result; they do not independently scan series.

### Proposed public models

Names may be refined before implementation, but the responsibilities and
separation below are the contract to preserve.

```dart
enum CartesianValueSummaryValuePolicy {
  trackingThenLatest,
  trackingThenFirst,
  selectionThenTrackingThenLatest,
  pinnedThenTrackingThenLatest,
  explicitOnly,
}

sealed class CartesianValueSummaryPresentation {
  const factory CartesianValueSummaryPresentation.overlay({
    ChartOverlayPlacement placement,
  }) = CartesianValueSummaryOverlay;

  const factory CartesianValueSummaryPresentation.annotation({
    ChartOverlayPlacement placement,
    bool draggable,
    bool clampToPlot,
  }) = CartesianValueSummaryAnnotation;
}

class ChartOverlayPlacement {
  const ChartOverlayPlacement({
    required this.anchor,
    this.offset = Offset.zero,
  });

  final Alignment anchor;
  final Offset offset;
}

class CartesianValueSummaryConfig {
  const CartesianValueSummaryConfig({
    this.enabled = false,
    this.presentation = const CartesianValueSummaryPresentation.overlay(),
    this.valuePolicy =
        CartesianValueSummaryValuePolicy.trackingThenLatest,
    this.content = const CartesianValueSummaryContent.automatic(),
    this.style,
    this.showSeriesAccent = true,
    this.announceChanges = false,
  });
}

class CartesianValueSummaryStyle {
  const CartesianValueSummaryStyle({
    this.backgroundColor,
    this.backgroundOpacity,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.padding,
    this.textStyle,
    this.labelStyle,
    this.accentColor,
    this.shadow,
    this.minWidth,
    this.maxWidth,
    this.rowGap,
  });
}
```

`ChartOverlayPlacement` is anchor-relative, not a raw absolute canvas offset.
It keeps a moved panel stable across plot resize, axis-width changes, RTL, and
responsive layouts. Dragging updates the offset relative to the selected
anchor. The renderer clamps the final rectangle when `clampToPlot` is true.

### Resolved snapshot model

Do not expose the mutable `CrosshairTrackingState.seriesValues` list as the new
public contract. Introduce an immutable snapshot:

```dart
class CartesianTrackingSnapshot {
  final double dataX;
  final double plotX;
  final List<CartesianTrackedSeriesValue> values;
  final CartesianTrackingOrigin origin;
  final ChartPointRef? primaryPoint;
}
```

`CartesianTrackedSeriesValue` should retain stable series and point identity,
raw X/Y, formatted X/Y, colour, interpolation state, source indices, and typed
family details such as `CandlestickInteractionDetails`. Trend values may be
included only when the content policy asks for annotation-derived values.

The existing `CrosshairSeriesValue` can be evolved into this immutable model
or adapted into it. Do not maintain two competing nearest-X algorithms.

### Content model

The renderer consumes semantic rows rather than a preformatted block of text:

```dart
class CartesianValueSummaryContentModel {
  final String? title;
  final String? subtitle;
  final Color? accentColor;
  final List<CartesianValueSummaryRow> rows;
}

class CartesianValueSummaryRow {
  final String label;
  final String value;
  final Color? color;
  final String? semanticValue;
}
```

Built-in automatic adapters:

- Line and Area: series name, X label, formatted Y and unit.
- Bar: category/X label, formatted value, grouped/stacked context where
  available.
- Scatter: X/Y plus optional size, colour, opacity, and category encodings.
- Candlestick: label/timestamp, Open, High, Low, Close, absolute/percentage
  change, and direction according to configured field selection.
- Mixed/multi-series: one grouped section per visible series at the resolved X.

Formatting must use the existing axis/series formatter registry. Financial
defaults may use two decimals, but the package feature must not impose two
decimals on non-financial series.

A runtime row-builder may be offered, but it is deliberately non-portable.
Artifacts and Source must either use a registered formatter/content descriptor
or emit an explicit diagnostic. They must never silently serialize whatever
text happened to be visible.

## State ownership and precedence

### State categories

| State | Owner | Portable? |
|---|---|---|
| Enabled, presentation, policy, fields, style | Chart configuration | Yes |
| Placement anchor and configured offset | Chart configuration / artifact | Yes |
| User-committed dragged offset | Host via callback/controller, then configuration | Yes when committed |
| Current tracking X | Interaction/render state | No |
| Hover/focus/selection candidate | Interaction coordinator | No |
| Explicit pinned `ChartPointRef` | Summary controller | Optional application state; not serialized by default |
| Derived rows | Summary adapter cache | No |

### Resolution precedence

For `pinnedThenTrackingThenLatest`:

1. valid explicit pin;
2. active keyboard focus or selected point, if the policy includes selection;
3. active local or synchronized tracking snapshot;
4. deterministic fallback among visible data;
5. hidden summary when no valid datum exists.

If a point disappears after a data replacement, clear the invalid pin and
continue through the policy. Never retain values from a removed series.

Pointer exit clears tracking state but does not clear an explicit pin.
Panning/zooming suspends transient tracking updates; a pinned or fallback
summary may remain visible and re-resolve after the transform settles.

### Controller boundary

If a controller is added, keep it small:

```dart
abstract interface class CartesianValueSummaryController {
  ChartPointRef? get pinnedPoint;
  void pin(ChartPointRef point);
  void clearPin();
  void resetPlacement();
}
```

It must not accept formatted strings, paint the panel, or become a second chart
controller. Placement changes should also emit a typed callback so immutable
widget configuration remains authoritative.

## Presentation and coordinate contract

### Overlay presentation

- Anchored to the plot interior, not the entire widget or page card.
- Default `topLeft` with a 12-pixel inset.
- Uses renderer/theme layout metrics and responds to axis/legend changes.
- Passes pointer input through by default.
- Does not move with pan or zoom.
- Does not draw a crosshair or select a point merely by being visible.

### Annotation presentation

- Uses the same content and style renderer as overlay presentation.
- Position is plot-screen space expressed as anchor + offset; it is not tied to
  a data X/Y coordinate.
- Optional drag begins only from the summary bounds and claims annotation-drag
  priority from `ChartInteractionCoordinator`.
- While dragging, crosshair/hover updates are suspended and the cursor becomes
  the platform move cursor.
- Drag emits continuous visual updates and one committed placement callback.
- The panel stays clamped to the plot after resize unless explicitly allowed
  to overflow.
- Keyboard movement uses arrow keys, with Shift for a larger step, whenever
  the summary has focus and dragging is enabled.

Do not synthesize a public `TextAnnotation` for this mode. A dedicated
`CartesianValueSummaryAnnotationElement`, or a shared summary element with an
annotation-placement strategy, preserves the live data binding. It may reuse
text annotation layout and drag utilities internally.

## Styling and theming contract

Add a `CartesianValueSummaryDefaults` component to the Cartesian interaction
theme, with light, dark, high-contrast, and colour-blind-safe presets.

Required properties:

- background colour and opacity;
- border colour and width;
- border radius;
- inner padding and row spacing;
- primary, secondary, label, and value text styles;
- accent/series indicator colour and size;
- optional shadow;
- min/max width and overflow policy.

Explicit clear semantics are mandatory:

- clearing background means a truly transparent background;
- clearing border means no visible stroke;
- a selected palette swatch may be toggled off;
- cleared values must not be confused with “inherit theme”.

Use an explicit override model (`ChartStyleValue.inherit`, `.value`, `.none`) or
equivalent sentinel semantics where nullable values otherwise conflate inherit
and clear. Both presentations must resolve the exact same effective style.

The summary must remain legible in high contrast, at 200% text scaling, and on
dark plot backgrounds. A transparent surface does not waive text-contrast
requirements; authors are responsible for explicit text colour in that mode.

## Interaction and synchronization contract

The summary consumes the same final snapshot as the crosshair renderer. The
pipeline must resolve Candlestick snapping, Scatter two-dimensional nearest
point replacement, trend values, and per-axis transforms before publishing the
snapshot.

For synchronized Cartesian charts:

- the synchronization group shares only the active data X and viewport;
- each chart resolves its own local series values and formatting;
- each chart may show or hide its own summary independently;
- an explicit pin is local unless a later group-level pin API is designed;
- no summary implementation may trigger another cursor broadcast.

The summary must coexist with point selection, point tooltip, crosshair panel,
axis labels, annotations, navigator, pan, and zoom. Its visibility has no side
effects on those features.

## Artifacts, hydration, Workbench, and Source

First-class means the behavior is portable, not only the pixels.

### Artifact schema

Encode the following under the interaction configuration:

- enabled;
- value policy;
- presentation kind;
- anchor, offset, draggable, and clamp behavior;
- automatic content field selection and formatter descriptors;
- complete style overrides including explicit `none` values.

Do not encode transient tracking X, current hover, derived rows, or animation
state. Define a schema version and reject unknown enum values with the normal
artifact diagnostic path.

### Hydration

Hydration reconstructs the live binding from configuration. Registered custom
formatters/content adapters come from runtime bindings. A missing binding uses
an explicit safe fallback and diagnostic consistent with other formatter
registries.

### Workbench

- Chart mode renders and interacts with both presentations.
- Data mode remains the source of raw values and current formatting.
- Split mode must not produce duplicate summary state or callbacks.
- Source mode emits a self-contained `CartesianValueSummaryConfig` for all
  portable properties.
- Runtime-only builders are called out as omitted dependencies, never emitted
  as stale text.

### Backward compatibility

Artifacts without the field hydrate with `enabled: false`. No existing chart
changes visually. `InteractionConfig.none()` must disable the summary even if a
nested config is accidentally enabled.

## Accessibility and keyboard contract

- Expose one grouped semantic region: title, context/X, and labelled values.
- Preserve meaningful source order and announce units.
- Do not announce every pointer pixel. Default `announceChanges` is false; when
  enabled, debounce by resolved datum identity rather than pointer movement.
- Annotation presentation is focusable only when interactive.
- Provide semantic actions for move, reset position, pin, and clear pin when
  those capabilities are enabled.
- Ensure screen-reader traversal does not duplicate the same values through
  the crosshair panel and summary without distinct labels.
- Honour reduced motion and platform high-contrast settings.

## Performance architecture

### Hot-path rules

- Resolve series values once per interaction frame.
- Publish an immutable snapshot only when datum identity or formatted values
  change; raw pointer movement within the same snapped candle must not rebuild
  the panel.
- Do not call `setState` on the page or rebuild `BravenChartPlus` per pointer
  move.
- Keep summary layout cached until content, style, text scale, or plot bounds
  change.
- Repaint only the feedback layer; do not invalidate series pictures, geometry,
  spatial indices, bounds, or axis layout.
- Reuse Scatter's final two-dimensional hit and Candlestick's snapped session
  payload rather than scanning those series again.
- Synchronized participants resolve locally without allocating broadcast row
  models for other charts.

### Required benchmark matrix

| Scenario | Requirement |
|---|---|
| 5,000-point Line + Area, two series | No regression against crosshair-only p95 raster/build |
| 50,000-point Line, fixed overlay | Summary update stays within one 16.7 ms frame at p95 |
| 2,000 Candlesticks + moving average | No geometry/cache invalidation while tracking |
| Dense Scatter | No second O(N) nearest-point scan for summary |
| Three synchronized charts | One group broadcast; one local resolution per participant |
| Draggable annotation summary | Continuous paint during drag; one commit/rebuild on release |

Add counters or debug hooks proving resolver executions, feedback repaints, and
series-cache invalidations. “Looks smooth” is not sufficient evidence.

## Failure and lifecycle behavior

- Empty series: hide the summary and expose no stale semantics.
- All-invalid series: hide and emit the existing data diagnostic path.
- Hidden series: exclude from automatic rows unless explicitly configured.
- Removed pinned point: clear pin and apply fallback policy.
- Reordered/replaced data: resolve by stable `ChartPointRef`; never retain an
  old object instance.
- Resize or axis-width change: recompute anchor placement and clamp.
- Theme change: recompute inherited style without altering explicit clears.
- Pointer exit: clear tracking origin; keep pin/fallback according to policy.
- Pan/zoom/annotation drag: suspend transient tracking and avoid spurious hover
  callbacks.
- Dispose: detach listeners/controllers and release cached text layouts.

## Implementation slices

### Slice 0 — Dependency landing and contract freeze

- Branch from updated `master` after the Candlestick lane lands.
- Re-run package/showcase baselines.
- Freeze public names, style override semantics, and artifact version.
- Keep the showcase prototype unchanged as the visual and behavior oracle.

**Gate:** API review covers family neutrality, persistence, and callback
compatibility before renderer work starts.

### Slice 1 — Immutable tracking snapshot

- Extract the final crosshair resolution result from paint.
- Include Scatter replacement, Candlestick details, trend values, source
  identity, and formatting.
- Add equality/change suppression and internal publication.
- Make crosshair rendering consume the same snapshot.

**Gate:** existing tracking tests remain green and prove only one resolution
per frame.

### Slice 2 — Content adapters and policy reducer

- Implement deterministic value-source precedence.
- Add automatic adapters for every Cartesian family and mixed series.
- Add pin invalidation and empty/hidden-series behavior.
- Define portable formatter/content descriptors.

**Gate:** pure unit matrix covers family, policy, fallback, and formatting.

### Slice 3 — Native overlay presentation

- Add plot-aware placement and shared summary layout/paint.
- Add theme defaults, true clear semantics, semantics, and responsive sizing.
- Keep hit testing pass-through.

**Gate:** widget/golden tests cover four corners, themes, text scale, RTL, and
multi-axis content.

### Slice 4 — Native annotation presentation

- Reuse the summary layout with annotation placement.
- Integrate drag priority, continuous paint, commit callback, clamping,
  keyboard movement, and focus semantics.
- Confirm dragging never updates tracking/cursor state.

**Gate:** pointer and keyboard E2E cover move, resize, pan/zoom coexistence, and
reset.

### Slice 5 — Portability and Workbench

- Add artifact schema/codec/hydration.
- Add Source generation and runtime binding diagnostics.
- Wire all Workbench views and round-trip tests.
- Replace the showcase prototype with the native configuration while retaining
  both demos and all appearance controls.

**Gate:** artifact -> hydrate -> Source -> compile preserves behavior and style.

### Slice 6 — Performance, docs, and release readiness

- Run the benchmark matrix and compare against recorded baselines.
- Add public docs and examples for ordinary, multi-series, Candlestick, and
  synchronized charts.
- Run full package/showcase tests, analyze, release Web build, Wasm dry run,
  direct-route browser check, and pub.dev dry run.

**Gate:** no performance regression, no accessibility blocker, no source or
artifact warning for portable configurations, and pixel review approved.

## Verification matrix

### Unit

- Value-policy precedence and pin invalidation.
- Adapter rows for Line, Area, Bar, Scatter, Candlestick, mixed, and multi-axis.
- Formatter/unit propagation and financial precision.
- Anchor + offset placement and clamping.
- Explicit inherit/value/none style semantics.
- Artifact encode/decode and old-artifact defaults.

### Render and widget

- Overlay at every supported anchor.
- Annotation placement, drag, focus, keyboard move, and reset.
- Pointer pass-through for fixed overlay.
- No tracking updates during annotation drag.
- Tooltip, crosshair panel, axis labels, and summary remain independent.
- Resize, RTL, theme, high contrast, and 200% text scale.
- Empty/invalid data and removed pinned point.

### Source and Workbench

- Portable automatic content emits compilable Dart.
- Explicit clear colours survive Source and artifact round trips.
- Runtime-only builders emit a precise diagnostic.
- Chart/Data/Split/Source do not duplicate controllers or summaries.

### Performance

- Resolver invocation count.
- Feedback-only repaint count.
- Series cache invalidation remains zero during tracking/drag.
- p50/p95 build and raster timing for the benchmark matrix.

## Migration from the Candlestick prototype

1. Land the native feature without removing the showcase implementation.
2. Recreate the existing fixed and annotation screenshots using only
   `CartesianValueSummaryConfig`.
3. Port every summary appearance control to the native models.
4. Compare hover, tap, latest fallback, dragging, clear colours, dark theme,
   semantics, Data, Split, and Source.
5. Delete `_PinnedOhlcSummaryCard`, `_buildPinnedSummaryLayer`,
   `_buildPinnedSummaryAnnotations`, and page-owned active-summary state only
   after parity tests pass.
6. Retain the Candlestick sample as the richest showcase, then add compact Line
   and synchronized examples to prove family neutrality.

The visual defaults may remain the same. The page must stop owning value
resolution and live binding.

## Known gaps inherited from the prototype

- Overlay is currently limited to four corners.
- Annotation position is an absolute `Offset`, so resize resilience is weak.
- Hover callbacks, rather than final tracking state, drive the active value.
- Annotation Source serializes current rich text, not the live binding policy.
- Overlay is absent from artifacts and Source.
- Candlestick-only row formatting is embedded in the page.
- Annotation updates rebuild the page; overlay updates a separate notifier.
- No explicit pin/unpin controller exists.
- Collision handling with legends and transient tooltips is manual.
- The prototype proves widget semantics only for the fixed card.

## Decisions the receiving lane must confirm in Slice 0

1. Whether `CartesianTrackingSnapshot` replaces or wraps
   `CrosshairTrackingState` publicly. Recommendation: one immutable model,
   retaining a compatibility typedef only if needed.
2. Whether value-summary style lives in `InteractionTheme` or a dedicated
   Cartesian component. Recommendation: a dedicated component referenced by
   the interaction theme.
3. The exact explicit-clear representation. Recommendation: a tri-state style
   override rather than nullable ambiguity.
4. Whether runtime custom row builders are supported in v1. Recommendation:
   allow them only with explicit non-portable diagnostics.
5. Whether dragged placement is automatically written to a controller or only
   emitted. Recommendation: emit and let immutable host configuration remain
   authoritative.
6. Whether trend annotation values appear automatically. Recommendation: off
   by default; opt in through content selection.

These are contract refinements, not permission to fall back to a showcase
`Stack` or static `TextAnnotation` snapshot.

## Required reading for the receiving lane

- `example/lib/showcase/pages/candlestick_charts_page.dart`
  - `_buildPinnedSummaryLayer`
  - `_buildPinnedSummaryAnnotations`
  - `_summaryCandleFor`
  - `_handlePinnedPointHover`
  - `_handlePinnedSummaryAnnotationDragged`
  - `_PinnedOhlcSummaryCard`
- `example/test/showcase/candlestick_charts_page_test.dart`
  - pinned summary independence, active-value, styling, clear, and drag tests
- `lib/src/interaction/core/crosshair_tracker.dart`
- `lib/src/models/interaction_config.dart`
- `lib/src/interaction/core/data_hit.dart`
- `lib/src/interaction/core/coordinator.dart`
- `lib/src/rendering/modules/crosshair_renderer.dart`
- `lib/src/rendering/modules/annotation_drag_handler.dart`
- `lib/src/models/chart_annotation.dart`
- `lib/src/elements/annotation_elements.dart`
- `lib/src/artifacts/chart_annotation_document_codec.dart`
- `lib/src/artifacts/chart_document_hydrator.dart`
- `lib/src/source/chart_dart_source_generator.dart`
- `doc/candlestick_charts.md`
- `docs/superpowers/specs/2026-07-20-cartesian-navigator-architecture-handoff.md`

## Do-not-break rules

- Do not change existing charts visually; summary defaults to disabled.
- Do not merge point tooltip, crosshair panel, axis labels, or summary toggles.
- Do not calculate the same tracking snapshot twice in one chart frame.
- Do not use application callbacks as internal renderer state.
- Do not persist current hover/tracking values.
- Do not serialize dynamic summary content as static annotation text.
- Do not make the summary Candlestick-specific.
- Do not make the fixed overlay intercept chart gestures.
- Do not let annotation dragging update crosshair or selection.
- Do not conflate clear with inherit for background or border.
- Do not bypass artifacts, hydration, Source, Workbench, semantics, or theme.
- Do not remove the prototype until native parity is proven.

## Definition of done

The handoff lane is complete when:

- one public native configuration enables the summary on every Cartesian
  family;
- fixed overlay and draggable annotation presentations share content, state,
  style, semantics, and formatting;
- the summary consumes the final shared tracking snapshot without redundant
  scans or chart rebuilds;
- pin, selection, tracking, fallback, data replacement, and empty-state rules
  are deterministic;
- synchronized charts resolve correct local values at the shared X;
- placement survives resize and annotation drag does not disturb tracking;
- explicit clear colours remain genuinely clear in render, artifacts, and
  Source;
- automatic configurations round-trip through artifacts, hydration, and
  generated compilable Dart;
- Workbench Chart, Data, Split, and Source are correct;
- accessibility, keyboard, theme, RTL, and high-density performance gates pass;
- the Candlestick showcase uses the native API and retains both approved visual
  presentations; and
- full package and showcase release verification is green.

