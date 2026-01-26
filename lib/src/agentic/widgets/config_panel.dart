import 'package:flutter/material.dart';

import '../models/chart_configuration.dart';

/// Configuration panel widget for editing chart appearance settings.
///
/// Provides controls for theme, grid, legend, and scrollbar visibility.
/// Uses ValueNotifier pattern for <100ms update latency (SC-012).
class ConfigPanel extends StatefulWidget {
  const ConfigPanel({
    super.key,
    required this.configuration,
    required this.onConfigurationChanged,
  });

  /// Current chart configuration to display
  final ChartConfiguration configuration;

  /// Callback when configuration is updated
  final ValueChanged<ChartConfiguration> onConfigurationChanged;

  @override
  State<ConfigPanel> createState() => _ConfigPanelState();
}

class _ConfigPanelState extends State<ConfigPanel> {
  /// Get current theme setting (default to 'light' if not set)
  bool get isDarkTheme => widget.configuration.theme == 'dark';

  /// Get current grid visibility (default to true if not set - matches chart default)
  bool get isGridVisible =>
      widget.configuration.grid == null ||
      widget.configuration.grid['visible'] != false;

  /// Get current legend visibility (default to true if not set - matches chart default)
  bool get isLegendVisible =>
      widget.configuration.legend == null ||
      widget.configuration.legend['visible'] != false;

  /// Get current legend position (default to 'bottom' if not set)
  String get legendPosition => widget.configuration.legend != null &&
          widget.configuration.legend['position'] != null
      ? widget.configuration.legend['position'] as String
      : 'bottom';

  /// Get current scrollbar enabled state (default to false if not set)
  bool get isScrollbarEnabled =>
      widget.configuration.interactions != null &&
      widget.configuration.interactions['scrollbar'] != null &&
      widget.configuration.interactions['scrollbar']['enabled'] == true;

  /// Handle theme toggle
  void _onThemeChanged(bool isDark) {
    final updated = widget.configuration.copyWith(
      theme: isDark ? 'dark' : 'light',
    );
    widget.onConfigurationChanged(updated);
  }

  /// Handle grid visibility toggle
  void _onGridChanged(bool visible) {
    final updatedGrid = <String, dynamic>{
      ...?(widget.configuration.grid as Map<String, dynamic>?),
      'visible': visible,
    };
    final updated = widget.configuration.copyWith(
      grid: updatedGrid,
    );
    widget.onConfigurationChanged(updated);
  }

  /// Handle legend visibility toggle
  void _onLegendVisibilityChanged(bool visible) {
    final updatedLegend = <String, dynamic>{
      ...?(widget.configuration.legend as Map<String, dynamic>?),
      'visible': visible,
    };
    final updated = widget.configuration.copyWith(
      legend: updatedLegend,
    );
    widget.onConfigurationChanged(updated);
  }

  /// Handle legend position change
  void _onLegendPositionChanged(String? position) {
    if (position == null) return;
    final updatedLegend = <String, dynamic>{
      ...?(widget.configuration.legend as Map<String, dynamic>?),
      'position': position,
    };
    final updated = widget.configuration.copyWith(
      legend: updatedLegend,
    );
    widget.onConfigurationChanged(updated);
  }

  /// Handle scrollbar toggle
  void _onScrollbarChanged(bool enabled) {
    final updatedInteractions = <String, dynamic>{
      ...?(widget.configuration.interactions as Map<String, dynamic>?),
      'scrollbar': {'enabled': enabled},
    };
    final updated = widget.configuration.copyWith(
      interactions: updatedInteractions,
    );
    widget.onConfigurationChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Theme toggle
            SwitchListTile(
              title: const Text('Dark Theme'),
              value: isDarkTheme,
              onChanged: _onThemeChanged,
            ),
            // Grid visibility toggle
            SwitchListTile(
              title: const Text('Show Grid'),
              value: isGridVisible,
              onChanged: _onGridChanged,
            ),
            // Legend visibility toggle
            SwitchListTile(
              title: const Text('Show Legend'),
              value: isLegendVisible,
              onChanged: _onLegendVisibilityChanged,
            ),
            // Legend position dropdown
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Legend Position'),
                  DropdownButton<String>(
                    value: legendPosition,
                    items: const [
                      DropdownMenuItem(value: 'top', child: Text('Top')),
                      DropdownMenuItem(value: 'bottom', child: Text('Bottom')),
                      DropdownMenuItem(value: 'left', child: Text('Left')),
                      DropdownMenuItem(value: 'right', child: Text('Right')),
                    ],
                    onChanged: _onLegendPositionChanged,
                  ),
                ],
              ),
            ),
            // Scrollbar visibility toggle
            SwitchListTile(
              title: const Text('Show Scrollbar'),
              value: isScrollbarEnabled,
              onChanged: _onScrollbarChanged,
            ),
          ],
        ),
      ),
    );
  }
}
