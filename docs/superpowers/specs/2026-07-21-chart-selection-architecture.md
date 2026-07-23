# Chart Selection Architecture

**Status:** Implemented; release hardening complete

**Lane:** `feature/selection-architecture`

**Base:** `origin/master` at `6892ee42`

## Goal

Make selection a renderer-neutral, first-class chart capability that can
identify marks, series, categories, stacks, and data-domain sections without
coupling those meanings to one chart family's painted geometry. A committed
selection must drive rendering, callbacks, Workbench tables, programmatic
control, and selection-scoped artifact extraction through one state model.

## Product principles

- Acquisition, semantic resolution, and downstream actions are separate.
- One pointer sequence has one interaction owner.
- Focus, hover, selection, axis promotion, and viewport navigation are distinct
  states even when one user action updates more than one of them.
- Existing selection behavior remains compatible unless a new policy is
  explicitly enabled.
- A visual mark resolves to every source datum it represents.
- Touch selection uses visible tools and usable hit targets rather than hidden
  modifier requirements.
- Selection meaning never relies on colour alone.
- Extracting a selection extends the existing `extractArtifact()` lifecycle;
  it does not introduce a second persistence or chart-construction system.

## Architecture

```text
pointer / keyboard / controller
              |
              v
acquisition geometry
tap | x interval | y interval | rectangle | lasso
              |
              v
semantic resolver
mark | category | stack | series
              |
              v
selection expression + revision-bound snapshot
              |
              +--> rendering and semantics
              +--> callbacks and Workbench tables
              +--> statistics, copy, CSV, zoom
              `--> ChartDocument selection projection
```

### Acquisition

Acquisition describes how a user identifies candidates. It does not decide
what a hit means. Point, interval, rectangle, and lasso tools all commit
through the same reducer and operation policy.

The public code contract names each layer independently:

- `ChartSelectionAcquisitionMode` describes candidate geometry: `point`,
  `xInterval`, `yInterval`, `rectangle`, or `lasso`;
- `ChartSelectionScope` describes semantic expansion: `mark`, `category`,
  `categoryStack`, `wholeSeries`, or `markOrWholeSeries`;
- `ChartSelectionOperation` describes set mutation: `replace`, `add`,
  `subtract`, or `toggle`.
- `ChartSelectionDragActivation` describes the pointer chord reserved by a
  drag-capable tool: `primaryButton` or `shiftPrimaryButton`.

The longer `categoryStack`, `wholeSeries`, `primaryButton`, and
`shiftPrimaryButton` identifiers are deliberate: they prevent terse words such
as “stack”, “series”, or “primary” from being mistaken for acquisition
geometry, viewport state, or a keyboard-only modifier.

### Semantic scope

- **Mark:** every source row represented by one rendered mark.
- **Category:** compatible marks at the same native category or X identity.
- **Stack:** contributors sharing a category and stack/group identity.
- **Series:** a complete Cartesian series, radial ring, or polar series.
- **Mark or series:** the directly acquired mark wins inside its marker radius;
  otherwise the complete series can win inside its path corridor. One
  activation never creates mixed mark-and-series state.

Scopes become public only when their family-neutral resolver is implemented.
Unsupported combinations return a structured result instead of falling back
to a different meaning.

The first semantic resolver checkpoint defines compatibility precisely:

- Cartesian category identity is the exact finite native X value already used
  by the Workbench shared-X row model; radial/polar category identity is its
  native non-empty category label so ring ordering remains irrelevant;
- a Bar stack additionally requires equal orientation, layout, resolved value
  axis, baseline, and explicit/default group identity;
- a Polar Column stack requires stacked composition plus the same native
  category label and signed stack side;
- grouped and waterfall Bars have no multi-series stack, so stack scope stays
  within the acquired source series;
- modifiers alter the selection operation only; they never alter semantic
  scope.

### Selection state

The durable state has two representations:

- `ChartSelectionExpression` stores compact intent such as series IDs, domain
  intervals, index spans, or explicit point references.
- `ChartSelectionSnapshot` resolves that intent against one effective document
  revision and supplies source identities, extents, counts, and statistics.

The public clause names remain explicit about identity and inclusivity:

- `ChartSelectionWholeSeriesClause`;
- `ChartSelectionPointIndexSpanClause`, with inclusive start and end indexes;
- `ChartSelectionPointKeysClause`, with stable point keys scoped by series ID;
- `ChartSelectionXIntervalClause` and `ChartSelectionYIntervalClause`, with
  inclusive numeric bounds and an optional target-series set;
- `ChartSelectionExplicitPointRefsClause` for identities that cannot be
  represented more compactly.

This avoids materializing huge sets for whole-series or dense interval
selection. `ChartPointRef` remains the revision-bound point identity.
`ChartDataPoint.pointKey` is the optional portable identity for observations
that must survive reorder, insertion, or bounded-stream eviction. Keys must be
non-empty and unique within their series. `ChartPointKeyRef` carries that
identity across revisions, while `ChartPointKeyIndex` resolves it lazily and
rejects ambiguous duplicate keys. Keyed points remap before family-specific
index/category fallbacks; unkeyed points retain the existing revision-bound
behavior.

### Axis promotion

Y-axis slot promotion is not selection. The existing singular selected-series
state becomes an explicit promoted/active-axis series internally. Durable chart
selection uses an independent set of series IDs. Existing controller methods
remain compatible while new multi-series state is added.

## Interaction ownership

Highest priority wins:

1. modal editor, context menu, or range-annotation creation;
2. annotation resize and drag;
3. navigator and scrollbar handles;
4. active selection tool;
5. data mark or series activation;
6. pan;
7. passive hover, tracking, crosshair, and tooltip.

The interaction coordinator and element hit priorities must produce the same
winner. Preview geometry is transient and a selection commits atomically on
pointer-up. Escape cancels an active preview before it clears committed state.

Desktop modifiers use the existing portable operation policy: Ctrl/Command
toggles, Shift adds, and Alt/Option subtracts. Touch exposes the same operations
through visible selection controls. Selection handles use compact visuals with
at least 44 logical-pixel hit regions, targeting 48 where layout permits.

## Family semantics

### Line and Area

- A direct marker/nearest-point action selects a datum.
- A stroke or fill action selects the series.
- Complete-series mode uses a configurable screen-space corridor around the
  rendered path, resolves overlapping corridors to the nearest path, and
  visibly expands the hovered stroke before activation. Marker-only mode
  highlights only its marker; the dual-target scope chooses the marker inside
  its point radius and otherwise permits the complete path corridor to win.
  It never highlights or selects both target types at once. Series enter and
  exit feedback is immediate. The independent marker and
  series hit radii default to 20 and 22 logical pixels. The series corridor
  must not claim interval, rectangle, or lasso drags.
- Acquisition geometry and visual emphasis are independent. Marker hover and
  selection scales, and complete-series hover and selection stroke scales, are
  separately configurable without changing the forgiving hit corridors.
- The floating tracking information panel can be disabled independently of
  crosshair lines, axis-value labels, and intersection markers.
- The standard single-point hover popup is controlled by the existing
  `TooltipConfig.enabled` policy and can be disabled independently of both the
  tracking information panel and the remaining crosshair presentation.
- Modifiers allow multi-point and multi-series selection.
- X-interval is the default section tool; rectangle is available for genuine
  two-dimensional filtering.
- Selected point decoration is available even when normal markers are hidden.

### Bar

- Default scope remains one segment/bar.
- Opt-in category scope selects compatible bars at the same category.
- Opt-in stack scope selects contributors in the same category and stack.
- Series scope selects the complete series in any orientation.
- Workbench shared-X row semantics are the canonical category resolver.

### Scatter

- Existing point, rectangle, and lasso tools remain.
- Aggregate marks expand through `effectiveSourcePointIndices`.
- Dense selections use compressed expressions rather than one stored object per
  selected observation.

### Candlestick

- A mark is one complete OHLC session.
- X-interval selects aligned sessions across price, volume, and indicator panes.
- Extraction retains complete OHLC tuples and recomputes compatible overlays.

### Radial and Polar

- A mark is one visible slice or column and expands grouped categories.
- Category scope spans compatible concentric rings or polar series.
- Series scope selects one complete ring/series.
- Stack scope selects polar contributors sharing stack identity.
- Extracted part-to-whole charts recalculate shares from retained raw values.

### Range Area

Low/high endpoints are one semantic datum. Selection and extraction never
retain only half of a range tuple.

## Selection-scoped chart creation

`ChartDataScope.selection` and a selection projection policy extend the current
document/artifact extractor. A pure projector receives a stable effective
document plus selection snapshot and returns a detached `ChartDocument`.

Projection policies cover:

- selected-only versus participating series;
- source-only versus interpolated interval boundaries;
- fitted, document, or viewport axis bounds;
- annotation omission, containment, or clipping;
- X preservation versus rebasing;
- derived-series recalculation or structured omission warnings.

Line and Area interval extraction keeps source observations by default, while
an explicit interpolation projection uses the same implementation as
rendering for exact interval boundaries. Point-index annotations and chords
are rebased. The resulting view starts fitted with selection cleared and
carries source-document and selection provenance.

Annotation projection is explicit. The default clips compatible data-space
ranges to the retained selection bounds, rebases point/chord/error-bar indices,
and emits structured warnings for stale or derived annotations that cannot be
projected faithfully. Series-bound Y annotations resolve containment on that
series' axis domain rather than a combined multi-axis range.

## Accessibility and visible actions

- Focus and selection are announced and painted independently.
- Arrow keys move focus; Space toggles; Shift+Space extends where ordered;
  Ctrl/Command+A is provided only when the scope is bounded and meaningful.
- A visible summary reports count, series, and domain, for example
  `18 points - 3 series - Jun 4-12`.
- Visible actions include Create chart, Zoom to selection, Copy, Export CSV,
  Invert, and Clear. Context-menu and keyboard commands remain accelerators.

## Performance contract

- Sorted X intervals resolve by binary search plus output size.
- Rectangle/lasso reuse the spatial index and visible geometry indexes.
- Selection preview is overlay-only and does not regenerate series.
- Committed selection invalidates only layers whose appearance changes.
- Large results remain compact and are materialized only when a consumer asks.
- Benchmarks cover 100k and 1m source observations plus multi-chart linking.

## Acceptance criteria

- Line and Area support real point, series, and modifier-aware multi-selection.
- Axis promotion and semantic series selection have independent state.
- Aggregate marks select all represented source identities.
- Radial input honours the configured selection operation.
- Bar/radial group scopes are opt-in, renderer-neutral, and orientation-safe.
- Interval selection cannot conflict with pan, navigator, scrollbar, or
  annotation manipulation.
- Controller commands, callbacks, view state, tables, and rendering agree.
- A committed selection can be projected through `extractArtifact()` into a
  correct detached chart document.
- Keyboard and touch paths have equivalent selection meaning.
- Analysis, focused tests, package tests, example tests, release web build, and
  `git diff --check` pass before release.

## Deliberate deferrals

- Arbitrary persisted selections across unrelated replacement datasets.
- Free-form angular lasso for radial charts; category/series/table interaction
  covers the initial radial requirement with less interaction ambiguity.
- Selection history/undo beyond normal host state restoration.

## Linked brushing contract

Cross-chart selection synchronization uses the existing
`ChartInteractionGroupController`; it is not a second selection or event bus.
It is disabled by default and requires
`ChartInteractionGroupOptions.synchronizeSelection` on every participating
chart.

Only durable `ChartPointKeyRef` values cross chart boundaries. A participant
must therefore provide a unique `pointKey` for every selected observation. The
group does not transport point indices, because indices change under sorting,
filtering, insertion, streaming eviction, and heterogeneous chart projections.
If a non-empty local selection cannot be mapped completely to stable keys, the
participant publishes nothing rather than creating a partial linked selection.
