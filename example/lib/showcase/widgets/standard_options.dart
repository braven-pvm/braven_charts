// Copyright 2025 Braven Charts - Standard Chart Options Widget
// SPDX-License-Identifier: MIT

// ignore_for_file: deprecated_member_use

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import 'chart_options.dart';
import 'options_panel.dart';

/// Standard options section that can be added to any chart demo.
///
/// Provides consistent UI for common chart options like:
/// - Theme selection
/// - Grid visibility
/// - Axis visibility
/// - Data markers
/// - Scrollbars
/// - Legend
/// - Zoom/Pan
/// - Line style
class StandardChartOptions extends StatelessWidget {
  const StandardChartOptions({
    super.key,
    required this.controller,
    this.showThemeOption = true,
    this.showGridOption = true,
    this.showAxisOption = true,
    this.showMarkerOption = true,
    this.showScrollbarOptions = true,
    this.showLegendOption = true,
    this.showInteractionOptions = true,
    this.showLineStyleOption = true,
    this.additionalOptions,
  });

  final ChartOptionsController controller;
  final bool showThemeOption;
  final bool showGridOption;
  final bool showAxisOption;
  final bool showMarkerOption;
  final bool showScrollbarOptions;
  final bool showLegendOption;
  final bool showInteractionOptions;
  final bool showLineStyleOption;

  /// Additional widgets to include in the options panel.
  final List<Widget>? additionalOptions;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return OptionSection(
          title: 'Chart Options',
          icon: Icons.settings,
          children: [
            // Theme Selection
            if (showThemeOption)
              EnumOption<ThemePreset>(
                label: 'Theme',
                value: _currentThemePreset,
                values: ThemePreset.values,
                labelBuilder: (p) => p.displayName,
                onChanged: (preset) {
                  controller.theme = preset.theme;
                },
              ),

            // Grid Lines
            if (showGridOption)
              BoolOption(
                label: 'Show Grid Lines',
                value: controller.showGrid,
                onChanged: (v) => controller.showGrid = v,
              ),

            // Axis Lines
            if (showAxisOption)
              BoolOption(
                label: 'Show Axis Lines',
                value: controller.showAxisLines,
                onChanged: (v) => controller.showAxisLines = v,
              ),

            // Data Markers
            if (showMarkerOption)
              BoolOption(
                label: 'Show Data Markers',
                value: controller.showDataMarkers,
                onChanged: (v) => controller.showDataMarkers = v,
              ),

            // Scrollbars
            if (showScrollbarOptions) ...[
              BoolOption(
                label: 'Show X Scrollbar',
                value: controller.showXScrollbar,
                onChanged: (v) => controller.showXScrollbar = v,
              ),
              BoolOption(
                label: 'Show Y Scrollbar',
                value: controller.showYScrollbar,
                onChanged: (v) => controller.showYScrollbar = v,
              ),
            ],

            // Legend
            if (showLegendOption)
              BoolOption(
                label: 'Show Legend',
                value: controller.showLegend,
                onChanged: (v) => controller.showLegend = v,
              ),

            // Interactions
            if (showInteractionOptions) ...[
              BoolOption(
                label: 'Enable Zoom',
                value: controller.enableZoom,
                onChanged: (v) => controller.enableZoom = v,
              ),
              BoolOption(
                label: 'Enable Pan',
                value: controller.enablePan,
                onChanged: (v) => controller.enablePan = v,
              ),
            ],

            // Line Style
            if (showLineStyleOption)
              EnumOption<LineStyle>(
                label: 'Line Style',
                value: controller.lineStyle,
                values: LineStyle.values,
                onChanged: (v) => controller.lineStyle = v,
              ),

            // Additional custom options
            if (additionalOptions != null) ...additionalOptions!,
          ],
        );
      },
    );
  }

  /// Determines the current theme preset from the controller's theme.
  ThemePreset get _currentThemePreset {
    final theme = controller.theme;
    if (theme == null) return ThemePreset.light;

    // Match by comparing theme properties
    for (final preset in ThemePreset.values) {
      if (preset.theme.backgroundColor == theme.backgroundColor) {
        return preset;
      }
    }
    return ThemePreset.light;
  }
}

/// A card container for charts with title and optional description.
class ChartCard extends StatelessWidget {
  const ChartCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.actions,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final List<Widget>? actions;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null || actions != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  if (title != null)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title!,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.hintColor,
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (actions != null) ...actions!,
                ],
              ),
            ),
          Expanded(
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// A page layout with chart area and options panel.
class ChartPageLayout extends StatelessWidget {
  const ChartPageLayout({
    super.key,
    required this.title,
    this.subtitle,
    required this.chart,
    this.optionsPanelWidth = 320,
    this.optionsChildren = const [],
    this.bottomPanel,
    this.actions,
  });

  final String title;
  final String? subtitle;
  final Widget chart;
  final double optionsPanelWidth;
  final List<Widget> optionsChildren;
  final Widget? bottomPanel;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // Main chart area
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (subtitle != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                subtitle!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.hintColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (actions != null) ...actions!,
                  ],
                ),
                const SizedBox(height: 16),

                // Chart
                Expanded(child: chart),

                // Bottom panel
                if (bottomPanel != null) ...[
                  const SizedBox(height: 16),
                  bottomPanel!,
                ],
              ],
            ),
          ),
        ),

        // Options panel
        if (optionsChildren.isNotEmpty)
          OptionsPanel(
            width: optionsPanelWidth,
            children: optionsChildren,
          ),
      ],
    );
  }
}

/// Status indicator widget for showing metrics/feedback.
class StatusPanel extends StatelessWidget {
  const StatusPanel({
    super.key,
    required this.items,
    this.highlighted = false,
    this.color,
  });

  final List<StatusItem> items;
  final bool highlighted;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = color ?? (highlighted ? Colors.green.shade50 : Colors.grey.shade100);
    final borderColor = highlighted ? Colors.green.shade300 : theme.dividerColor;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) => _buildItem(context, item)).toList(),
      ),
    );
  }

  Widget _buildItem(BuildContext context, StatusItem item) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          item.value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: item.color ?? Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          item.label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).hintColor,
          ),
        ),
      ],
    );
  }
}

class StatusItem {
  const StatusItem({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;
}
