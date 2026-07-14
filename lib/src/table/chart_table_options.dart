import 'package:flutter/foundation.dart';

import '../artifacts/chart_runtime_bindings.dart';

enum ChartTableDataScope {
  allSeries,
  visibleSeries,
  selectedSeries,
  specifiedSeries,
}

enum ChartTableRowLayout { long, wide }

/// Explicit alignment strategies supported by a wide table projection.
enum ChartTableAlignmentPolicy { exactX }

/// Immutable rules for deriving a table from a chart document.
@immutable
class ChartTableOptions {
  const ChartTableOptions({
    this.dataScope = ChartTableDataScope.allSeries,
    this.rowLayout = ChartTableRowLayout.long,
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
