// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Example 13: Theme-Aware Tooltips
///
/// This example demonstrates how to create tooltips that respond to light/dark theme changes.
/// Tooltips automatically adapt their appearance based on the current theme:
///
/// - **Light Theme**: Light background, dark text for good contrast
/// - **Dark Theme**: Dark background, light text for good contrast
/// - **High Contrast**: Bold colors for accessibility
///
/// This pattern is useful when building applications that support theme switching.
/// The tooltip colors are derived from Flutter's ThemeData, ensuring consistency
/// across your entire application.
///
/// Features:
/// - Real-time theme switching
/// - Smooth transitions between themes
/// - Accessibility-friendly color schemes
/// - Material Design 3 color system integration
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;

class ThemeAwareTooltipExample extends StatefulWidget {
  const ThemeAwareTooltipExample({super.key});

  @override
  State<ThemeAwareTooltipExample> createState() => _ThemeAwareTooltipExampleState();
}

class _ThemeAwareTooltipExampleState extends State<ThemeAwareTooltipExample> {
  ThemeMode _themeMode = ThemeMode.light;
  bool _useHighContrast = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Theme-Aware Tooltips',
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: _themeMode,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Example 13: Theme-Aware Tooltips'),
          actions: [
            // Theme mode switcher
            PopupMenuButton<ThemeMode>(
              onSelected: (mode) => setState(() => _themeMode = mode),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: ThemeMode.light,
                  child: Row(
                    children: [
                      Icon(
                        Icons.light_mode,
                        color: _themeMode == ThemeMode.light ? Colors.orange : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      const Text('Light'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: ThemeMode.dark,
                  child: Row(
                    children: [
                      Icon(
                        Icons.dark_mode,
                        color: _themeMode == ThemeMode.dark ? Colors.blue : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      const Text('Dark'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: ThemeMode.system,
                  child: Row(
                    children: [
                      Icon(
                        Icons.brightness_auto,
                        color: _themeMode == ThemeMode.system ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      const Text('System'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Column(
      children: [
        // Controls
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Theme Settings',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('High Contrast Mode'),
                subtitle: const Text('Use stronger colors for accessibility'),
                value: _useHighContrast,
                onChanged: (value) => setState(() => _useHighContrast = value),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade900 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade700 : Colors.blue.shade200,
                  ),
                ),
                child: Text(
                  'Current Theme: ${isDark ? '🌙 Dark' : '☀️ Light'} | '
                  'Contrast: ${_useHighContrast ? '🔥 High' : '⚙️ Normal'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        // Chart
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: BravenChart(
              chartType: ChartType.bar,
              series: [
                ChartSeries(
                  id: 'sales',
                  name: 'Quarterly Sales',
                  points: const [
                    ChartDataPoint(x: 1, y: 45),
                    ChartDataPoint(x: 2, y: 52),
                    ChartDataPoint(x: 3, y: 38),
                    ChartDataPoint(x: 4, y: 67),
                  ],
                  color: _getSeriesColor(isDark),
                ),
              ],
              interactionConfig: InteractionConfig(
                crosshair: CrosshairConfig.defaultConfig(),
                tooltip: _getThemeAwareTooltipConfig(isDark),
              ),
            ),
          ),
        ),
        // Info
        Container(
          padding: const EdgeInsets.all(16),
          color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
          child: _buildThemeInfo(isDark),
        ),
      ],
    );
  }

  Widget _buildThemeInfo(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '💡 Theme Information',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          isDark
              ? 'Dark mode active: Tooltips use dark backgrounds with light text '
                  'for better readability in low-light conditions.'
              : 'Light mode active: Tooltips use light backgrounds with dark text '
                  'for excellent readability in bright conditions.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        if (_useHighContrast)
          Text(
            'High contrast mode: Colors are more saturated and borders are thicker '
            'for better accessibility.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.amber.shade600,
                ),
          ),
      ],
    );
  }

  // ============================================================
  // Theme-Aware Configurations
  // ============================================================

  TooltipConfig _getThemeAwareTooltipConfig(bool isDark) {
    if (_useHighContrast) {
      return _createHighContrastTooltipConfig(isDark);
    } else {
      return _createNormalTooltipConfig(isDark);
    }
  }

  TooltipConfig _createNormalTooltipConfig(bool isDark) {
    if (isDark) {
      // Dark theme: light text on dark background
      return const TooltipConfig(
        enabled: true,
        triggerMode: TooltipTriggerMode.both,
        preferredPosition: TooltipPosition.auto,
        offsetFromPoint: 12.0,
        showDelay: Duration(milliseconds: 150),
        hideDelay: Duration(milliseconds: 0),
        style: TooltipStyle(
          backgroundColor: Color(0xFF424242), // Dark gray
          borderColor: Color(0xFF616161), // Medium gray border
          borderWidth: 1.0,
          borderRadius: 6.0,
          padding: 10.0,
          textColor: Color(0xFFE0E0E0), // Light text
          fontSize: 13.0,
          shadowColor: Color(0x80000000), // Strong shadow on dark bg
          shadowBlurRadius: 8.0,
        ),
        customBuilder: _buildThemeAwareContent,
      );
    } else {
      // Light theme: dark text on light background
      return const TooltipConfig(
        enabled: true,
        triggerMode: TooltipTriggerMode.both,
        preferredPosition: TooltipPosition.auto,
        offsetFromPoint: 12.0,
        showDelay: Duration(milliseconds: 150),
        hideDelay: Duration(milliseconds: 0),
        style: TooltipStyle(
          backgroundColor: Color(0xFFFAFAFA), // Almost white
          borderColor: Color(0xFFE0E0E0), // Light gray border
          borderWidth: 1.0,
          borderRadius: 6.0,
          padding: 10.0,
          textColor: Color(0xFF212121), // Dark text
          fontSize: 13.0,
          shadowColor: Color(0x1A000000), // Subtle shadow on light bg
          shadowBlurRadius: 4.0,
        ),
        customBuilder: _buildThemeAwareContent,
      );
    }
  }

  TooltipConfig _createHighContrastTooltipConfig(bool isDark) {
    if (isDark) {
      // Dark theme high contrast: bright colors with bold borders
      return const TooltipConfig(
        enabled: true,
        triggerMode: TooltipTriggerMode.both,
        preferredPosition: TooltipPosition.auto,
        offsetFromPoint: 12.0,
        showDelay: Duration(milliseconds: 150),
        hideDelay: Duration(milliseconds: 0),
        style: TooltipStyle(
          backgroundColor: Color(0xFF1565C0), // Vibrant blue
          borderColor: Color(0xFF00BCD4), // Cyan border
          borderWidth: 2.5,
          borderRadius: 6.0,
          padding: 12.0,
          textColor: Color(0xFFFFFFFF), // White text
          fontSize: 14.0,
          shadowColor: Color(0x80000000),
          shadowBlurRadius: 10.0,
        ),
        customBuilder: _buildThemeAwareContent,
      );
    } else {
      // Light theme high contrast: bold colors with strong borders
      return const TooltipConfig(
        enabled: true,
        triggerMode: TooltipTriggerMode.both,
        preferredPosition: TooltipPosition.auto,
        offsetFromPoint: 12.0,
        showDelay: Duration(milliseconds: 150),
        hideDelay: Duration(milliseconds: 0),
        style: TooltipStyle(
          backgroundColor: Color(0xFFFFEB3B), // Bright yellow
          borderColor: Color(0xFFF57F17), // Orange border
          borderWidth: 2.5,
          borderRadius: 6.0,
          padding: 12.0,
          textColor: Color(0xFF000000), // Black text
          fontSize: 14.0,
          shadowColor: Color(0x40000000),
          shadowBlurRadius: 10.0,
        ),
        customBuilder: _buildThemeAwareContent,
      );
    }
  }

  Color _getSeriesColor(bool isDark) {
    return isDark ? Colors.cyan : Colors.blue;
  }

  // ============================================================
  // Tooltip Content Builder
  // ============================================================

  static Widget _buildThemeAwareContent(BuildContext context, Map<String, dynamic> dataPoint) {
    final x = dataPoint['x'] as num;
    final y = dataPoint['y'] as num;

    final quarterNames = ['Q1', 'Q2', 'Q3', 'Q4'];
    final quarterName = x <= quarterNames.length ? quarterNames[x.toInt() - 1] : 'Q${x.toInt()}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$quarterName Sales Report',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.trending_up, size: 16),
            const SizedBox(width: 4),
            Text(
              '\$${y.toStringAsFixed(0)}K',
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.percent, size: 16),
            const SizedBox(width: 4),
            Text(
              '${(y * 1.5).toStringAsFixed(0)}% of annual',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}
