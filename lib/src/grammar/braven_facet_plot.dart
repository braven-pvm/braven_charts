// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:flutter/widgets.dart';

import '../controllers/chart_interaction_group_controller.dart';
import '../models/chart_state_config.dart';
import '../models/chart_theme.dart';
import '../models/x_axis_config.dart';
import '../models/y_axis_config.dart';
import '../models/y_axis_position.dart';
import 'braven_plot.dart';
import 'facet_partition.dart';
import 'facet_spec.dart';
import 'grammar_diagnostics.dart';
import 'mark.dart';
import 'plot_spec.dart';

/// Default maximum number of facet panels. Exceeding it is a grammar
/// diagnostic, not a silent large render.
const int facetPanelCap = 50;

/// One resolved facet panel: a strip label over a facet-cleared, range-injected
/// [PlotSpec] ready to be lowered by a [BravenPlot].
class BravenFacetPanel<T> {
  /// Creates a resolved panel.
  const BravenFacetPanel({
    required this.value,
    required this.label,
    required this.spec,
  });

  /// The distinct facet value this panel is for (may be null).
  final Object? value;

  /// The strip label shown above the panel.
  final String label;

  /// The single-panel spec (facet cleared, ranges injected, subset data).
  final PlotSpec<T> spec;
}

/// Placeholder shown for a null facet value, so a strip never reads `null`.
const String facetNullValuePlaceholder = '—'; // em dash

/// The strip label for a facet [value] under an optional [prefix].
///
/// A null [value] renders as [facetNullValuePlaceholder] (an em dash) rather
/// than the literal string `'null'` — a null value is a valid panel per the
/// spec, so it gets a defined label. Non-null values stringify as before.
String facetStripLabel(Object? value, String? prefix) {
  final valuePart = value == null ? facetNullValuePlaceholder : '$value';
  return prefix == null ? valuePart : '$prefix: $valuePart';
}

/// Partitions [spec] into one [BravenFacetPanel] per distinct facet value.
///
/// Validates the faceting up front: [GrammarDiagnosticCode.notFaceted] when the
/// spec is not faceted, [GrammarDiagnosticCode.emptyMarks] when it has no marks,
/// [GrammarDiagnosticCode.emptyFacetValues] when the partition is empty, and
/// [GrammarDiagnosticCode.facetPanelCapExceeded] over [facetPanelCap]. Then, for
/// each value (first-seen order), builds a facet-cleared copy over the row
/// subset with the shared axis ranges injected per [FacetScales].
List<BravenFacetPanel<T>> resolveFacetPanels<T>(PlotSpec<T> spec) {
  final facet = spec.facet;
  if (facet == null) throw GrammarSpecException.notFaceted();
  if (facet.columns != null && facet.columns! <= 0) {
    throw GrammarSpecException.facetColumnsNotPositive(facet.columns!);
  }
  if (spec.yAxes.length > 1 && facet.scales.sharesY) {
    throw GrammarSpecException.facetMultiAxisSharedY(
      spec.yAxes.length,
      facet.scales.name,
    );
  }
  if (spec.marks.isEmpty) throw GrammarSpecException.emptyMarks();
  for (final mark in spec.marks) {
    if (mark is RadialMark<T>) {
      // Radial faceting is out of scope for this slice: a radial geom on a
      // faceted spec fails loud rather than rendering N radial panels.
      throw GrammarSpecException.facetedRadialUnsupported(mark.id ?? 'radial');
    }
  }

  final values = distinctFacetValues(spec.data, facet.by);
  if (values.isEmpty) throw GrammarSpecException.emptyFacetValues();
  if (values.length > facetPanelCap) {
    throw GrammarSpecException.facetPanelCapExceeded(
      values.length,
      facetPanelCap,
    );
  }

  final xRange = facet.scales.sharesX
      ? globalRange(spec, spec.data, FacetAxis.x)
      : null;
  final yRange = facet.scales.sharesY
      ? globalRange(spec, spec.data, FacetAxis.y)
      : null;

  final base = spec.facetCleared();
  return <BravenFacetPanel<T>>[
    for (final value in values)
      BravenFacetPanel<T>(
        value: value,
        label: facetStripLabel(value, facet.label),
        spec: _injectPanel<T>(
          base,
          <T>[for (final row in spec.data) if (facet.by(row) == value) row],
          xRange,
          yRange,
        ),
      ),
  ];
}

/// Builds one panel spec from [base]: subset [data] plus any shared axis range.
///
/// A range is injected only when it is a real interval (`min < max`); a
/// degenerate range (all-equal values) is left to auto-scale rather than trip
/// the axis config's `min < max` assert. For a shared Y axis with no declared
/// axes, a single default left axis carrying the range is synthesized (it
/// lowers to `axis-0` exactly as the empty-yAxes default does).
PlotSpec<T> _injectPanel<T>(
  PlotSpec<T> base,
  List<T> data,
  FacetRange? xRange,
  FacetRange? yRange,
) {
  final injectX = xRange != null && xRange.min < xRange.max;
  final injectY = yRange != null && yRange.min < yRange.max;
  final xAxis = injectX
      ? (base.xAxis ?? const XAxisConfig()).copyWith(
          min: xRange.min,
          max: xRange.max,
        )
      : base.xAxis;
  final yAxes = injectY
      ? (base.yAxes.isEmpty
            ? <YAxisConfig>[
                YAxisConfig(
                  position: YAxisPosition.left,
                  min: yRange.min,
                  max: yRange.max,
                ),
              ]
            : <YAxisConfig>[
                for (final axis in base.yAxes)
                  axis.copyWith(min: yRange.min, max: yRange.max),
              ])
      : base.yAxes;
  return PlotSpec<T>(
    data: data,
    marks: base.marks,
    transposed: base.transposed,
    theme: base.theme,
    interaction: base.interaction,
    xAxis: xAxis,
    yAxes: yAxes,
    grid: base.grid,
    title: base.title,
    subtitle: base.subtitle,
    showLegend: base.showLegend,
  );
}

/// Renders a faceted [PlotSpec] as a grid of synchronized small-multiple
/// panels — one [BravenPlot] per distinct facet value.
///
/// Each panel is a strip label (the facet value, prefixed by
/// [FacetSpec.label]) above a [BravenPlot] over the panel's facet-cleared,
/// range-injected spec. Synchronized interaction is active only when x is
/// shared ([FacetScales.fixed]/[FacetScales.freeY]): every panel is handed the
/// SAME [ChartInteractionGroupController]; under [FacetScales.freeX]/
/// [FacetScales.free] the panels get no shared controller and interact
/// independently.
class BravenFacetPlot<T> extends StatefulWidget {
  /// Renders [spec], which must be faceted (`spec.facet != null`).
  const BravenFacetPlot(
    this.spec, {
    super.key,
    this.emptyStateConfig = const ChartEmptyStateConfig(),
  });

  /// The faceted specification this widget renders.
  final PlotSpec<T> spec;

  /// Presentation used when a panel's row subset is empty.
  final ChartEmptyStateConfig emptyStateConfig;

  @override
  State<BravenFacetPlot<T>> createState() => _BravenFacetPlotState<T>();
}

class _BravenFacetPlotState<T> extends State<BravenFacetPlot<T>> {
  ChartInteractionGroupController? _syncController;

  bool get _syncs => widget.spec.facet?.scales.syncsInteraction ?? false;

  @override
  void initState() {
    super.initState();
    if (_syncs) _syncController = ChartInteractionGroupController();
  }

  @override
  void didUpdateWidget(covariant BravenFacetPlot<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wantsSync = _syncs;
    final hasSync = _syncController != null;
    if (wantsSync && !hasSync) {
      _syncController = ChartInteractionGroupController();
    } else if (!wantsSync && hasSync) {
      _syncController!.dispose();
      _syncController = null;
    }
  }

  @override
  void dispose() {
    _syncController?.dispose();
    super.dispose();
  }

  TextStyle _stripStyle() {
    final typography = (widget.spec.theme ?? ChartTheme.light).typographyTheme;
    return TextStyle(
      fontFamily: typography.fontFamily,
      fontSize: typography.baseFontSize * typography.labelMultiplier,
      fontWeight: FontWeight.w600,
    );
  }

  Widget _panelCell(BravenFacetPanel<T> panel, TextStyle stripStyle) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          panel.label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: stripStyle,
        ),
      ),
      Expanded(
        child: BravenPlot<T>(
          panel.spec,
          interactionGroupController: _syncController,
          emptyStateConfig: widget.emptyStateConfig,
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final panels = resolveFacetPanels<T>(widget.spec);
    final columns = widget.spec.facet!.columns ?? autoColumns(panels.length);
    final stripStyle = _stripStyle();

    final gridRows = <Widget>[];
    for (var start = 0; start < panels.length; start += columns) {
      final cells = <Widget>[
        for (var column = 0; column < columns; column++)
          Expanded(
            child: (start + column) < panels.length
                ? _panelCell(panels[start + column], stripStyle)
                : const SizedBox.shrink(),
          ),
      ];
      gridRows.add(
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: cells,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: gridRows,
    );
  }
}
