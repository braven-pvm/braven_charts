// Copyright 2025 Braven Charts - Standard Chart Options Widget
// SPDX-License-Identifier: MIT

// ignore_for_file: deprecated_member_use

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import 'chart_options.dart';
import 'options_panel.dart';
import 'showcase_randomizer.dart';

/// Separates stable authored examples from the exhaustive generated sandbox.
@immutable
class ChartPlaygroundConfig {
  const ChartPlaygroundConfig({
    required this.active,
    required this.optionsChildren,
    required this.randomizer,
  });

  final bool active;
  final List<Widget> optionsChildren;
  final ShowcaseRandomizerHandle randomizer;
}

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
class StandardChartOptions extends StatelessWidget
    implements ShowcaseInspectorEntry {
  const StandardChartOptions({
    super.key,
    required this.controller,
    this.showThemeOption = true,
    this.showGridOption = true,
    this.showAxisOption = true,
    this.showMarkerOption = true,
    this.showScrollbarOptions = true,
    this.showXScrollbarOption = true,
    this.showYScrollbarOption = true,
    this.showLegendOption = true,
    this.showCrosshairOption = true,
    this.showInteractionOptions = true,
    this.showLineStyleOption = true,
    this.sectionTitle = 'Chart Options',
    this.sectionIcon = Icons.settings,
    this.themeOptionKey,
    this.additionalOptions,
  });

  final ChartOptionsController controller;
  final bool showThemeOption;
  final bool showGridOption;
  final bool showAxisOption;
  final bool showMarkerOption;
  final bool showScrollbarOptions;
  final bool showXScrollbarOption;
  final bool showYScrollbarOption;
  final bool showLegendOption;
  final bool showCrosshairOption;
  final bool showInteractionOptions;
  final bool showLineStyleOption;
  final String sectionTitle;
  final IconData sectionIcon;
  final Key? themeOptionKey;

  /// Additional widgets to include in the options panel.
  final List<Widget>? additionalOptions;

  @override
  ShowcasePropertyMetadata get inspectorMetadata => ShowcasePropertyMetadata(
    label: sectionTitle,
    description:
        'Controls the common theme, plotting guides, markers, navigation, legend, and line appearance.',
    aliases: <String>[
      if (showThemeOption) 'theme preset appearance',
      if (showGridOption) 'grid lines guides',
      if (showAxisOption) 'axis lines axes',
      if (showMarkerOption) 'data markers points',
      if (showXScrollbarOption) 'x scrollbar horizontal navigation',
      if (showYScrollbarOption) 'y scrollbar vertical navigation',
      if (showLegendOption) 'legend series key',
      if (showCrosshairOption)
        'crosshair tracking cursor guide axis values intersection',
      if (showInteractionOptions) 'zoom pan interaction navigation',
      if (showLineStyleOption) 'line style stroke pattern',
    ],
  );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return OptionSection(
          title: sectionTitle,
          icon: sectionIcon,
          description: inspectorMetadata.description,
          aliases: inspectorMetadata.aliases,
          children: [
            // Theme Selection
            if (showThemeOption)
              EnumOption<ThemePreset>(
                key: themeOptionKey,
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
              if (showXScrollbarOption)
                BoolOption(
                  label: 'Show X Scrollbar',
                  value: controller.showXScrollbar,
                  onChanged: (v) => controller.showXScrollbar = v,
                ),
              if (showYScrollbarOption)
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

            // Crosshair and tracking
            if (showCrosshairOption)
              BoolOption(
                key: const ValueKey('standard-show-crosshair'),
                label: 'Show Crosshair / Tracking',
                subtitle:
                    'Hide crosshair guides, axis values, intersections, and the tracking panel together',
                value: controller.showCrosshair,
                onChanged: (v) => controller.showCrosshair = v,
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
            ...?additionalOptions,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  ...?actions,
                ],
              ),
            ),
          Expanded(
            child: Padding(padding: padding, child: child),
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
    this.playground,
    this.randomizerKeyPrefix = 'showcase-randomizer',
  });

  final String title;
  final String? subtitle;
  final Widget chart;
  final double optionsPanelWidth;
  final List<Widget> optionsChildren;
  final Widget? bottomPanel;
  final List<Widget>? actions;
  final ChartPlaygroundConfig? playground;
  final String randomizerKeyPrefix;

  bool get _playgroundActive => playground?.active ?? false;

  ShowcaseRandomizerHandle? get _activeRandomizer =>
      _playgroundActive ? playground!.randomizer : null;

  List<Widget> get _effectiveOptionsChildren =>
      _playgroundActive ? playground!.optionsChildren : optionsChildren;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveOptions = _effectiveOptionsChildren;
        final hasOptions =
            effectiveOptions.isNotEmpty || _activeRandomizer != null;
        final useOptionsSheet = hasOptions && constraints.maxWidth < 900;
        final mainContent = _buildMainContent(
          context,
          showOptionsButton: useOptionsSheet,
        );

        if (!hasOptions) return mainContent;

        return Row(
          children: [
            Expanded(child: mainContent),
            if (!useOptionsSheet)
              OptionsPanel(
                width: optionsPanelWidth,
                headerEditor: _randomizerEditor,
                headerEditorLabel: 'Property randomizer',
                headerEditorKey: '$randomizerKeyPrefix-editor',
                children: effectiveOptions,
              ),
          ],
        );
      },
    );
  }

  Widget _buildMainContent(
    BuildContext context, {
    required bool showOptionsButton,
  }) {
    final theme = Theme.of(context);
    final headerActions = <Widget>[
      ...?actions,
      // Compact pages expose the same action inside the options sheet. Keeping
      // it out of the already-constrained page header preserves chart height.
      if (_activeRandomizer != null && !showOptionsButton)
        ShowcaseRandomizerActions(
          controller: _activeRandomizer!,
          keyPrefix: randomizerKeyPrefix,
        ),
      if (showOptionsButton)
        OutlinedButton.icon(
          key: const ValueKey('chart-page-options-button'),
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
          onPressed: () => _showOptionsSheet(context),
          icon: const Icon(Icons.tune, size: 18),
          label: const Text('Options'),
        ),
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final titleBlock = Column(
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
              );
              final actionGroup = Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: headerActions,
              );

              final stackActions =
                  constraints.maxWidth < 760 && headerActions.isNotEmpty;
              if (stackActions) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    titleBlock,
                    if (headerActions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(
                          width: double.infinity,
                          child: actionGroup,
                        ),
                      ),
                    ],
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: titleBlock),
                  if (headerActions.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    Flexible(
                      flex: 2,
                      fit: FlexFit.loose,
                      child: Align(
                        alignment: Alignment.topRight,
                        child: actionGroup,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Expanded(child: chart),
          if (bottomPanel != null) ...[
            const SizedBox(height: 16),
            bottomPanel!,
          ],
        ],
      ),
    );
  }

  Future<void> _showOptionsSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => SizedBox(
        width: double.infinity,
        height: MediaQuery.sizeOf(sheetContext).height * 0.85,
        child: OptionsPanel(
          title: 'Chart options',
          headerEditor: _randomizerEditor,
          headerEditorLabel: 'Property randomizer',
          headerEditorKey: '$randomizerKeyPrefix-editor',
          children: _effectiveOptionsChildren,
        ),
      ),
    );
  }

  Widget? get _randomizerEditor => _activeRandomizer == null
      ? null
      : PropertyRandomizerSection(
          controller: _activeRandomizer!,
          keyPrefix: randomizerKeyPrefix,
          initiallyExpanded: true,
        );
}

/// The first, explicit sample in every chart-family selector.
///
/// Unlike authored samples this mounts generated data and the exhaustive
/// family inspector. It deliberately shares the host selector's visual
/// language instead of introducing a second page-level mode control.
class ShowcaseExampleChoiceChip extends StatelessWidget {
  const ShowcaseExampleChoiceChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onSelected,
    this.playground = false,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onSelected;
  final bool playground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final foreground = playground
        ? colors.onTertiaryContainer
        : selected
        ? colors.onSecondaryContainer
        : colors.onSurfaceVariant;
    return ChoiceChip(
      showCheckmark: false,
      selected: selected,
      onSelected: (_) => onSelected(),
      avatar: Icon(icon, size: 17, color: foreground),
      label: Text(label),
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        color: foreground,
        fontWeight: playground || selected ? FontWeight.w700 : FontWeight.w400,
      ),
      selectedColor: playground
          ? colors.tertiaryContainer
          : colors.secondaryContainer,
      backgroundColor: playground
          ? colors.tertiaryContainer.withValues(alpha: 0.52)
          : colors.surface,
      side: BorderSide(
        color: playground
            ? colors.tertiary
            : selected
            ? colors.primary
            : colors.outlineVariant,
        width: playground ? (selected ? 2 : 1.4) : (selected ? 1.5 : 1),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class PlaygroundChoiceChip extends StatelessWidget {
  const PlaygroundChoiceChip({
    super.key,
    required this.selected,
    required this.onSelected,
    this.label = 'Playground',
  });

  final bool selected;
  final VoidCallback onSelected;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ShowcaseExampleChoiceChip(
      label: label,
      icon: Icons.science_outlined,
      selected: selected,
      onSelected: onSelected,
      playground: true,
    );
  }
}

class ShowcaseExampleGrid extends StatelessWidget {
  const ShowcaseExampleGrid({
    super.key,
    required this.children,
    this.minimumCardWidth = 190,
    this.maximumColumns = 6,
    this.cardHeight = 92,
    this.spacing = 8,
  });

  final List<Widget> children;
  final double minimumCardWidth;
  final int maximumColumns;
  final double cardHeight;
  final double spacing;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final availableWidth = constraints.maxWidth;
      final fittingColumns =
          ((availableWidth + spacing) / (minimumCardWidth + spacing)).floor();
      final columns = fittingColumns.clamp(1, maximumColumns);
      final cardWidth = (availableWidth - spacing * (columns - 1)) / columns;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          for (final child in children)
            SizedBox(width: cardWidth, height: cardHeight, child: child),
        ],
      );
    },
  );
}

class ShowcaseExampleCard extends StatelessWidget {
  const ShowcaseExampleCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.playground = false,
    this.semanticsLabel,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool playground;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final background = playground
        ? selected
              ? colors.tertiaryContainer
              : colors.tertiaryContainer.withValues(alpha: 0.52)
        : selected
        ? colors.primaryContainer.withValues(alpha: 0.42)
        : colors.surface;
    final accent = playground ? colors.tertiary : colors.primary;
    final foreground = playground
        ? colors.onTertiaryContainer
        : selected
        ? colors.primary
        : colors.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: semanticsLabel ?? 'Open $title example',
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: playground
                ? accent
                : selected
                ? accent
                : colors.outlineVariant,
            width: playground ? (selected ? 2.4 : 1.4) : (selected ? 2 : 1),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: foreground),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: playground ? colors.onTertiaryContainer : null,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (selected)
                      Icon(Icons.check_circle, size: 17, color: accent),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: playground
                        ? colors.onTertiaryContainer.withValues(alpha: 0.82)
                        : colors.onSurfaceVariant,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PlaygroundExampleCard extends StatelessWidget {
  const PlaygroundExampleCard({
    super.key,
    required this.selected,
    required this.onTap,
    this.title = 'Playground',
    this.description = 'Generate data and every compatible property.',
  });

  final bool selected;
  final VoidCallback onTap;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return ShowcaseExampleCard(
      title: title,
      description: description,
      icon: Icons.science_outlined,
      selected: selected,
      onTap: onTap,
      playground: true,
      semanticsLabel: 'Open $title',
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
    final bgColor =
        color ?? (highlighted ? Colors.green.shade50 : Colors.grey.shade100);
    final borderColor = highlighted
        ? Colors.green.shade300
        : theme.dividerColor;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (items.isEmpty) return const SizedBox.shrink();

          final columnCount = constraints.maxWidth < 600
              ? 2
              : constraints.maxWidth < 900
              ? 3
              : (items.length > 6 ? 6 : items.length);
          final itemWidth = constraints.maxWidth / columnCount;

          return Wrap(
            alignment: WrapAlignment.center,
            runSpacing: 12,
            children: [
              for (final item in items)
                SizedBox(width: itemWidth, child: _buildItem(context, item)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildItem(BuildContext context, StatusItem item) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          item.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: item.color ?? Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          item.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor),
        ),
      ],
    );
  }
}

class StatusItem {
  const StatusItem({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;
}
