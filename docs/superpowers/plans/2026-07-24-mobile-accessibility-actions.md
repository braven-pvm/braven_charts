# Mobile accessibility command surface

## Status

Implementation contract for BC-0001 and GitHub issue #110.

## Outcome

Screen-reader and switch-control users can operate the essential chart
viewport and durable selection state without reproducing pointer gestures or
desktop modifier-key chords.

## Architecture

`BravenChartPlus` owns the renderer, interaction gates, selection resolver, and
streaming state, so it remains the authority for whether an action is
available. The widget exposes two dedicated semantic control nodes:

- **Chart viewport actions** for zoom, pan, fit, and return-to-live commands.
- **Chart selection actions** for a bounded select-all command and clearing all
  durable selection.

These nodes are separate from the existing family-specific point/slice
semantics. Point inspection keeps its current increase/decrease/tap behavior;
the new nodes do not replace it or duplicate renderer-owned data descriptions.

Every semantic command delegates to the same internal handler attached to
`BravenChartController`. The controller gains renderer-aware commands for
pixel pan, bounded select-all, clearing all selection, and return-to-live.
Existing `zoomViewport` and `fitData` remain the zoom/reset authority.

## Capability rules

- Actions are absent when the complete interaction system is disabled.
- Zoom and pan follow `enableZoom` and `enablePan`.
- Pan distance follows `KeyboardConfig.panStep`.
- Zoom magnitude follows `keyboardZoomPercent`.
- Select all is exposed only when selection is enabled and the result is
  bounded by the package's existing keyboard-selection limits. Whole-series
  scope stays compact and does not materialize every point.
- Clear selection appears only while durable point, series, expression, or
  brush selection exists.
- Return to live appears only for a managed streaming viewport that is
  currently paused or exploring history.
- Cartesian viewport actions are not advertised on radial layouts.

## Feedback

Each successful command updates the value of its dedicated live-region node
with a short state result such as `Zoomed in. Visible X 2.00 to 8.00.` or
`Selection cleared.` This announces the command result without restating chart
marks, tooltips, or renderer-owned semantic summaries.

## Verification

- Focused widget tests inspect action availability and execute custom semantic
  actions through Flutter's semantics owner.
- Controller tests prove that host controls and semantic actions share the
  same command path.
- Existing keyboard, touch, selection, streaming, and family semantics suites
  remain green.
- The showcase receives a mobile accessibility validation surface before
  physical TalkBack/VoiceOver review.

Physical Android/iOS evidence, 200% text, reduced-motion, and switch-control
review remain required before BC-0001 can be closed.
