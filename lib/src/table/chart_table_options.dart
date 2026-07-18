import 'package:flutter/foundation.dart';

import '../artifacts/chart_runtime_bindings.dart';

/// Which series contribute rows to a table projection.
enum ChartTableDataScope {
  allSeries,
  visibleSeries,
  selectedSeries,
  specifiedSeries,
}

/// Physical row shape rendered or exported by [ChartTableModel].
enum ChartTableRowLayout { long, wide }

/// Alignment rule for a wide table's shared X column.
enum ChartTableAlignmentPolicy { exactX }

/// Whether a host shows the chart, its data table, both, or generated source.
enum ChartDisplayMode { chart, data, split, source }

/// Immutable rules for deriving a table from a chart document.
@immutable
class ChartTableOptions {
  const ChartTableOptions({
    this.dataScope = ChartTableDataScope.allSeries,
    this.rowLayout = ChartTableRowLayout.wide,
    this.alignmentPolicy = ChartTableAlignmentPolicy.exactX,
    this.seriesIds = const {},
    this.viewportOnly = false,
    this.includeMetadata = false,
    this.formatters = const ChartFormatterRegistry(),
  });

  final ChartTableDataScope dataScope;
  final ChartTableRowLayout rowLayout;
  final ChartTableAlignmentPolicy alignmentPolicy;
  final Set<String> seriesIds;
  final bool viewportOnly;
  final bool includeMetadata;
  final ChartFormatterRegistry formatters;
}
