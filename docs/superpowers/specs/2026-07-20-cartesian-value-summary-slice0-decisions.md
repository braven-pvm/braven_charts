# Cartesian Value Summary — Slice 0 Decision Record

**Date:** 2026-07-20
**Status:** Contract decisions for the receiving lane; supplements
[2026-07-20-cartesian-value-summary-architecture-handoff.md](2026-07-20-cartesian-value-summary-architecture-handoff.md)
**Lane:** `feature/cartesian-value-summary`, branched from `master` @ `b66c896d`
**Baseline:** master after PRs #63–#67 (scatter marginal composition, cluster
drill, `ChartDataHit.activationHint`) — additive drift only; the handoff
architecture stands.

## Corrections to the handoff spec, verified against master

1. **Three resolution call sites, not one.** Besides the paint path
   (`crosshair_renderer.dart:409` — re-resolves on every repaint, no change
   suppression), `_calculateSynchronizedTrackingState`
   (`chart_render_box.dart:641`) re-runs un-enriched resolution up to 4–5×
   per frame through the `_synchronizedCursorPosition` getter, and the
   `debugSynchronizedTrackingState` test hook recomputes again. Slice 1
   unifies all three behind one published snapshot.
2. **`annotation_drag_handler.dart` is dead code** — constructed then only
   disposed. Live annotation-drag logic (hit acquisition, coordinator mode
   claim, preview, commit) lives in `event_handler_manager.dart`. The
   summary's drag integration extends EventHandlerManager; no third copy of
   drag state is added, and the dead handler is not the pattern to follow.
3. **Artifact extension point** is `chart_interaction_document_codec.dart`
   (full `InteractionConfig` codec with runtime-binding descriptors), not
   `chart_annotation_document_codec.dart` as the handoff's reading list
   implies.
4. **`TextAnnotation` renders behind series** (`RenderOrder.textAnnotation
   = 1` < `series = 2`, contradicting its own doc comment). The summary
   elements must not inherit this; they render in the foreground feedback
   band.
5. **The prototype is not on master.** The pinned-OHLC oracle (~1,637
   uncommitted lines) exists only in the working tree of
   `F:\Repositories\braven_charts-candlestick-research`. See Decision 7.
6. **Formatting is paint-coupled.** Tracking-tooltip unit/label formatting
   depends on `MultiAxisInfo` assembled during paint
   (`chart_render_box.dart:2725`); the snapshot must carry resolved
   formatting so the summary never reaches back into paint state.

## Contract decisions

### D1. Snapshot model — one immutable model

`CartesianTrackingSnapshot` with an unmodifiable value list becomes the
single resolved-tracking product, published with identity-based change
suppression. `CrosshairRenderer` consumes it; the mutable
`CrosshairTrackingState` remains an internal detail during migration and is
not promoted into the new public contract.

### D2. Style lives in a flat `ChartTheme` component — deliberate divergence

The handoff recommends a component "referenced by the interaction theme".
Repo precedent (`CandlestickTheme`, `chart_theme.dart`) registers theme
components flat on `ChartTheme`, and `InteractionTheme` still carries a
legacy `fromJson`/`toJson` pair that the modern codec path bypasses —
nesting new state there would entangle two serialization systems.
`CartesianValueSummaryTheme` registers flat on `ChartTheme` with light,
dark, high-contrast, and colour-blind-safe presets.

### D3. Explicit clear = tri-state, scoped to the summary style

`ChartStyleValue<T>` (`inherit` / `value(T)` / `none`) is introduced for
`CartesianValueSummaryStyle` only — not a repo-wide refactor. Artifact
representation: absent = inherit, explicit `"none"` token = cleared;
Source emits the constructor form. The prototype's asymmetric nullable
semantics (null = hidden for background/border, null = auto for
text/accent) are mapped onto the tri-state during migration so ported
configurations keep their behavior.

### D4. Runtime row builders — allowed, explicitly non-portable

A runtime content builder is accepted in v1. Artifacts and Source reuse
the interaction codec's runtime-binding descriptor pattern: registered
descriptors round-trip; unregistered builders emit the standard omitted-
dependency diagnostic and never serialize rendered text.

### D5. Dragged placement — emitted, host-authoritative

Drag emits continuous visual updates internally and exactly one committed
`ChartOverlayPlacement` via callback. The widget configuration remains the
source of truth; the optional controller exposes `resetPlacement()` but
does not silently own placement.

### D6. Trend values — opt-in

Automatic rows exclude trend-annotation values unless content selection
explicitly includes them.

## Additional decisions from code analysis

### D7. Prototype is a read-only oracle; native-first showcase

The uncommitted prototype in the candlestick-research worktree is treated
as **read-only reference**. This lane does not commit, land, or modify
that worktree. Consequences for the handoff's migration plan: the
Candlestick showcase's native value-summary demo is built directly against
`CartesianValueSummaryConfig` in this lane (reproducing the prototype's
two presentations, 14 appearance controls, and defaults), and the
handoff's "delete the prototype after parity" steps become a no-op on
master. Behavioral parity is verified against the worktree copy by
reading, not by executing its tests in CI. (Securing that worktree's
contents is the owner's call and out of this lane's scope; this branch
lands the previously untracked handoff spec so the contract itself is in
git.)

### D8. Versioning — capability string, no schema bump

`chart.cartesian.value-summary.v1` is declared through the extractor and
built-in capability list, following `chart.polar.*.v1` precedent. The
global artifact `schemaVersion` is not bumped. Old artifacts hydrate with
the const disabled default (`enabled: false`) via the codec's
encode-only-when-non-default pattern.

### D9. Naming confirmed free

`ChartOverlayPlacement`, `CartesianValueSummary*`, and
`CartesianTrackingSnapshot` collide with nothing on master. The
`ChartOverlayAction*` (host context actions) namespace is unaffected;
`ChartOverlayPlacement` complements it.

### D10. Hot-path contract

The resolver runs on cursor/synchronized-X/transform/data change — not per
repaint. Snapshot publication is suppressed when datum identity and
formatted values are unchanged. Summary layout caches until content,
style, text scale, or plot bounds change; repaints touch only the feedback
layer. The synchronized-path getter dedup (correction 1) is part of
Slice 1's definition of done.

### D11. Slice-0 hygiene

Delete the stray tracked `lib/src/rendering/chart_render_box.dart.backup`
in this lane's first commit (it shadows old coordinator/annotation logic
and pollutes searches).

### D12. New machinery acknowledged as net-new

Keyboard annotation movement, move-cursor, plot clamping, continuous drag
preview callbacks for non-Range annotations, and the p95 frame-timing
benchmark harness have no existing implementation to reuse; slices 4 and 6
budget them as new work rather than integration.

## Working agreement

Work happens exclusively in the `braven_charts-value-summary` worktree on
`feature/cartesian-value-summary`; PR to master only on owner approval.
Slice gates from the handoff spec are preserved; each slice ends with
package analyze/test green before the next begins.
