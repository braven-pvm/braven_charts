// Copyright 2025 Braven Charts - Region Analysis Demo
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;

/// Demonstrates all three region-selection sources available in BravenChartPlus:
///
/// 1. **Range Annotation Tap** – Tap a highlighted range annotation to
///    fire [BravenChartPlus.onRegionSelected] with
///    [DataRegionSource.rangeAnnotation].
///
/// 2. **Styled Segment Tap** – Tap a segment whose data point carries a
///    [SegmentStyle] to fire [onRegionSelected] with
///    [DataRegionSource.segment].
///
/// 3. **Box-Select Drag** – Hold and drag across the chart to draw a
///    selection box, firing [onRegionSelected] with
///    [DataRegionSource.boxSelect].
///
/// The selected [DataRegion] metadata (series count, data-point count,
/// and source) is shown in the bottom info panel.
/// The built-in summary overlay card is also enabled via
/// [BravenChartPlus.showRegionSummary].
class RegionAnalysisDemo extends StatefulWidget {
  /// Creates a [RegionAnalysisDemo] page.
  const RegionAnalysisDemo({super.key});

  @override
  State<RegionAnalysisDemo> createState() => _RegionAnalysisDemoState();
}

class _RegionAnalysisDemoState extends State<RegionAnalysisDemo> {
  // ── Data ────────────────────────────────────────────────────────────────────

  late List<ChartDataPoint> _sineData;
  late List<ChartDataPoint> _styledSineData;

  // ── Annotation controller ───────────────────────────────────────────────────

  final AnnotationController _annotationController = AnnotationController();

  // ── Selected region state ───────────────────────────────────────────────────

  DataRegion? _selectedRegion;

  @override
  void initState() {
    super.initState();
    _generateData();
    _buildAnnotations();
  }

  @override
  void dispose() {
    _annotationController.dispose();
    super.dispose();
  }

  // ── Data generation ─────────────────────────────────────────────────────────

  /// Generates both chart series from scratch.
  void _generateData() {
    // Plain sine wave — used for the range annotation tap source.
    _sineData = List.generate(100, (i) {
      final x = i.toDouble();
      final y = 50.0 + 35.0 * math.sin(x * 0.12);
      return ChartDataPoint(x: x, y: y);
    });

    // Cosine wave with styled segments — demonstrates segment-tap source.
    final styledPoints = <ChartDataPoint>[];
    for (int i = 0; i < 100; i++) {
      final x = i.toDouble();
      final y = 50.0 + 35.0 * math.cos(x * 0.12);
      // Annotate a "peak" range with a SegmentStyle so users can tap it.
      final bool inHighZone = y > 70.0;
      styledPoints.add(
        ChartDataPoint(
          x: x,
          y: y,
          segmentStyle: inHighZone
              ? const SegmentStyle(color: Colors.deepPurpleAccent, strokeWidth: 3.5)
              : const SegmentStyle(color: Colors.orange, strokeWidth: 2.5),
        ),
      );
    }
    _styledSineData = styledPoints;
  }

  /// Adds a [RangeAnnotation] so the annotation-tap path can be demonstrated.
  void _buildAnnotations() {
    _annotationController.clearAnnotations();
    _annotationController.addAnnotation(
      RangeAnnotation(
        id: 'demo_range',
        startX: 20,
        endX: 45,
        label: 'Annotated Zone',
        fillColor: Colors.blue.withValues(alpha: 0.18),
        borderColor: Colors.blue.withValues(alpha: 0.5),
      ),
    );
  }

  // ── Callbacks ───────────────────────────────────────────────────────────────

  /// Stores the selected [DataRegion] and rebuilds the info panel.
  void _onRegionSelected(DataRegion? region) {
    setState(() => _selectedRegion = region);
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Region Analysis'), backgroundColor: theme.colorScheme.surface, elevation: 1),
      body: Column(
        children: [
          // ── Instructions ──────────────────────────────────────────────────
          // _buildInstructionBanner(theme),

          // ── Chart ─────────────────────────────────────────────────────────
          Expanded(child: _buildChart()),

          // ── Info panel ────────────────────────────────────────────────────
          // _buildInfoPanel(theme),
        ],
      ),
    );
  }

  /// Brief explanation of how to trigger each region source.
  Widget _buildInstructionBanner(ThemeData theme) {
    return Container(
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Three ways to select a region:', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _InstructionItem(
                  icon: Icons.edit_note,
                  color: Colors.blue,
                  label: '① Tap the blue shaded zone',
                  detail: 'source: rangeAnnotation',
                ),
              ),
              Expanded(
                child: _InstructionItem(
                  icon: Icons.format_color_fill,
                  color: Colors.orange,
                  label: '② Tap the orange cosine peaks',
                  detail: 'source: segment',
                ),
              ),
              Expanded(
                child: _InstructionItem(
                  icon: Icons.select_all,
                  color: Colors.green,
                  label: '③ Drag to box-select any area',
                  detail: 'source: boxSelect',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: BravenChartPlus(
        // ── Series ──────────────────────────────────────────────────────────
        series: [
          // Plain sine – supports range annotation tap
          LineChartSeries(
            id: 'sine',
            name: 'Sine Wave',
            points: _sineData,
            color: Colors.blue,
            interpolation: LineInterpolation.bezier,
            strokeWidth: 2.0,
            // showDataPointMarkers: true,
          ),
          // Cosine with styled segments – supports segment tap
          LineChartSeries(
            id: 'cosine_styled',
            name: 'Cosine (styled peaks)',
            points: _styledSineData,
            color: Colors.orange.withValues(alpha: 0.7),
            interpolation: LineInterpolation.bezier,
            strokeWidth: 2.0,
            // showDataPointMarkers: true,
            dataPointMarkerRadius: 5,
          ),
        ],

        // ── Annotation (range annotation tap source) ─────────────────────
        annotationController: _annotationController,

        // ── Region summary overlay ────────────────────────────────────────
        showRegionSummary: true,
        regionSummaryConfig: RegionSummaryConfig(
          metrics: {RegionMetric.min, RegionMetric.max, RegionMetric.average, RegionMetric.count, RegionMetric.range},
          position: RegionSummaryPosition.aboveRegion,
        ),

        // ── Box-select & interaction ──────────────────────────────────────
        interactionConfig: const InteractionConfig(
          enableZoom: true,
          enablePan: true,
          enableSelection: true,
          enableFocusOnHover: true,
          tooltip: TooltipConfig(enabled: false, triggerMode: TooltipTriggerMode.both),
        ),
        // ── Axis config ───────────────────────────────────────────────────
        xAxisConfig: const XAxisConfig(label: 'X'),
        yAxis: YAxisConfig(position: YAxisPosition.left, label: 'Y'),
        // ── Region selected callback ──────────────────────────────────────
        onRegionSelected: _onRegionSelected,

        // ── Additional styling ────────────────────────────────────────────
        showLegend: true,
        backgroundColor: Colors.white,
      ),
    );
  }

  /// Bottom panel that shows the current [DataRegion] metadata.
  Widget _buildInfoPanel(ThemeData theme) {
    final region = _selectedRegion;

    if (region == null) {
      return Container(
        height: 56,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: theme.colorScheme.surfaceContainerHighest,
        child: Text(
          'No region selected — try one of the three interactions above.',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor, fontStyle: FontStyle.italic),
        ),
      );
    }

    // Count total data points across all series in the region.
    final totalPoints = region.seriesData.values.fold<int>(0, (sum, pts) => sum + pts.length);
    final seriesCount = region.seriesData.length;

    final sourceLabel = switch (region.source) {
      DataRegionSource.rangeAnnotation => 'Range annotation tap',
      DataRegionSource.segment => 'Styled segment tap',
      DataRegionSource.boxSelect => 'Box-select drag',
    };

    final sourceColor = switch (region.source) {
      DataRegionSource.rangeAnnotation => Colors.blue,
      DataRegionSource.segment => Colors.orange,
      DataRegionSource.boxSelect => Colors.green,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _InfoChip(label: 'Source', value: sourceLabel, color: sourceColor),
          _InfoChip(label: 'Series', value: '$seriesCount', color: theme.colorScheme.primary),
          _InfoChip(label: 'Points', value: '$totalPoints', color: theme.colorScheme.primary),
          _InfoChip(
            label: 'X range',
            value:
                '${region.startX.toStringAsFixed(1)} – '
                '${region.endX.toStringAsFixed(1)}',
            color: theme.colorScheme.secondary,
          ),
        ],
      ),
    );
  }
}

// ── Small helper widgets ─────────────────────────────────────────────────────

/// A single labelled metric chip in the bottom info panel.
class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor)),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

/// A single instruction item in the banner.
class _InstructionItem extends StatelessWidget {
  const _InstructionItem({required this.icon, required this.color, required this.label, required this.detail});

  final IconData icon;
  final Color color;
  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodySmall),
              Text(
                detail,
                style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
