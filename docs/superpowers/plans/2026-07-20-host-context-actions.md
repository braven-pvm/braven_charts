# Host context actions implementation plan

**Date:** 2026-07-20
**Status:** Complete
**Branch:** `feature/host-context-actions`
**Primary surfaces:** `BravenChartPlus`, `BravenChartWorkbench`

## Objective

Allow a host application to add family-neutral commands to the native chart
context menu while retaining a visible Workbench action as the primary,
accessible entry point. The package owns interaction and menu lifecycle; the
host owns product semantics, persistence, permissions, feedback, and
navigation.

## Public contract

- Add immutable `ChartContextAction`, `ChartContextInvocation`, and
  `ChartContextHit` models.
- Add deterministic action sections so hosts never insert raw divider widgets.
- Add an optional low-level `BravenChartPlus.contextActionsBuilder`.
- Add an optional `BravenChartWorkbench.contextActionsBuilder` whose callback
  receives the same mounted `ChartWorkbenchHandle` as `actionsBuilder`.
- Keep all additions nullable and source compatible.
- Do not expose renderer elements or introduce comparison-specific concepts.

## Interaction contract

- Secondary click, keyboard Context Menu / Shift+F10, and opt-in touch
  long-press use one invocation and command path.
- Empty effective menus are never shown.
- One gesture creates at most one menu.
- The interaction coordinator is released before a callback runs.
- Async success, failure, and thrown callbacks cannot leave the chart in a
  modal interaction state.
- Menu dismissal restores chart focus when appropriate.
- Long-press cancels on movement and does not replace the visible action.

## Menu and accessibility contract

- Order: target-specific actions, host actions, annotation creation, then
  destructive target actions.
- Use package theme colors, 48px action rows, semantic labels, visible keyboard
  focus, Escape dismissal, arrow-key traversal, and viewport-clamped placement.
- Manage browser context-menu suppression safely across multiple charts.

## Delivery slices

1. Typed public models, host-only mouse menu, deterministic composition, and
   lifecycle tests.
2. Workbench propagation, shared handle, extraction, and multi-chart isolation
   tests.
3. Keyboard, long-press, focus, theme, and browser lifecycle behavior.
4. Showcase, documentation, package/example verification, release web build,
   direct-route verification, and publish dry run.

## Non-goals

- Comparison repositories, persistence, limits, product copy, permissions, or
  navigation.
- Artifact schema changes.
- Public renderer-element APIs.
- Enabling long-press by default.
