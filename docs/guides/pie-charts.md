# Pie charts

The release-facing Pie guide is maintained in
[`doc/pie_charts.md`](../../doc/pie_charts.md) so the same documentation ships
inside the pub.dev package archive.

It covers:

- the `PieChartSeries` data and validation contract;
- optional variable slice radii through a labeled second metric, perceptual or
  linear scaling, and a configurable minimum radius;
- physical gap geometry, dual inside/outside labels, signed inside radial
  offsets, compact outside lanes, collision handling, and palettes;
- theme/per-series opacity, all-corner, outer-only, or circular-center corner
  treatment, shadows, selected glow, callouts, tooltip styles, legend
  placement, and reduced-motion-aware animation;
- pointer, keyboard, legend, and controller-driven selection;
- separate shared `RadialSelectionEffect.explode` and centroid-scaled
  `RadialSelectionEffect.lift` presentation, with configurable scale, backdrop
  blur, independent radial offset, and selected elevation;
- the native `Category | Value | Radius | Share` table when applicable;
- canonical JSON, `series.pie`, `series.pie.style.v2`,
  `series.pie.corner-treatment.v1`, optional
  `series.pie.variable-radius.v1`, previews, and hydration;
- AI/tool configuration; and
- accessibility and responsive behavior.

For all series types and mixed Cartesian composition, see
[Chart types](chart-types.md).
