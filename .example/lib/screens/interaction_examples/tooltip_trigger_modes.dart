// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Example 11: Tooltip Trigger Modes
///
/// This example demonstrates the three different trigger modes for showing tooltips:
///
/// - **Hover Mode**: Tooltip appears when mouse hovers over data point
///   - Desktop: Smooth mouse movement triggers tooltip
///   - Mobile: Not applicable (no hover on touch)
///
/// - **Tap Mode**: Tooltip appears only when tapping/clicking data point
///   - Desktop: Click to show, click elsewhere to hide
///   - Mobile: Single tap to show
///
/// - **Both Mode**: Tooltip shows on both hover and tap
///   - Desktop: Hover to preview, click for persistent view
///   - Mobile: Tap to show
///
/// Additionally demonstrates:
/// - Show/hide delays (how long before tooltip appears/disappears)
/// - FollowCursor option (tooltip sticks to data point vs follows cursor)
/// - Snap radius (how close cursor needs to be to snap to data point)
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;

class TooltipTriggerModesExample extends StatefulWidget {
  const TooltipTriggerModesExample({super.key});

  @override
  State<TooltipTriggerModesExample> createState() => _TooltipTriggerModesExampleState();
}

class _TooltipTriggerModesExampleState extends State<TooltipTriggerModesExample> {
  int _selectedMode = 0;
  bool _showCrosshair = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Example 11: Tooltip Trigger Modes'),
      ),
      body: Column(
        children: [
          // Mode selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trigger Mode',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildModeButton(context, 'Hover', 0),
                    const SizedBox(width: 12),
                    _buildModeButton(context, 'Tap', 1),
                    const SizedBox(width: 12),
                    _buildModeButton(context, 'Both', 2),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: _showCrosshair,
                      onChanged: (value) => setState(() => _showCrosshair = value ?? true),
                    ),
                    const Text('Show Crosshair'),
                  ],
                ),
              ],
            ),
          ),
          // Chart
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: BravenChart(
                chartType: ChartType.line,
                series: [
                  ChartSeries(
                    id: 'daily_revenue',
                    name: 'Daily Revenue',
                    points: const [
                      ChartDataPoint(x: 1, y: 2400),
                      ChartDataPoint(x: 2, y: 1398),
                      ChartDataPoint(x: 3, y: 9800),
                      ChartDataPoint(x: 4, y: 3908),
                      ChartDataPoint(x: 5, y: 4800),
                      ChartDataPoint(x: 6, y: 3490),
                    ],
                    color: Colors.blue,
                  ),
                ],
                interactionConfig: InteractionConfig(
                  // Disable crosshair in tap mode to avoid hover interactions
                  crosshair: (_showCrosshair && _selectedMode != 1) ? CrosshairConfig.defaultConfig() : const CrosshairConfig(enabled: false),
                  tooltip: _getTriggerModeConfig(_selectedMode),
                ),
              ),
            ),
          ),
          // Description and instructions
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: _buildModeDescription(_selectedMode),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(BuildContext context, String label, int index) {
    final isSelected = _selectedMode == index;
    return Expanded(
      child: OutlinedButton(
        onPressed: () => setState(() => _selectedMode = index),
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? Colors.blue : Colors.transparent,
          foregroundColor: isSelected ? Colors.white : Colors.blue,
          side: BorderSide(
            color: Colors.blue,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _buildModeDescription(int mode) {
    final descriptions = {
      0: {
        'title': '🖱️ Hover Mode',
        'description': 'Tooltip appears when your mouse hovers over a data point. Perfect for desktop users.',
        'desktop': '✅ Hover your mouse over data points',
        'mobile': '❌ Not available on touch devices',
        'showDelay': '200ms delay before showing',
        'hideDelay': 'Hides immediately when mouse leaves',
      },
      1: {
        'title': '👆 Tap Mode',
        'description':
            'Tooltip appears only when you click/tap a data point. Clean and minimalist. Crosshair is disabled to prevent hover interference.',
        'desktop': '✅ Click on data points to show tooltip',
        'mobile': '✅ Tap on data points to show tooltip',
        'showDelay': 'No delay - shows immediately',
        'hideDelay': 'Hides after 200ms of no interaction',
      },
      2: {
        'title': '🔄 Both Mode',
        'description': 'Tooltip shows on both hover and tap. Most versatile for mixed mouse/touch environments.',
        'desktop': '✅ Hover to preview or click for persistent view',
        'mobile': '✅ Tap to show',
        'showDelay': '100ms delay before showing',
        'hideDelay': 'Hides after 200ms',
      },
    };

    final info = descriptions[mode]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          info['title']!,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          info['description']!,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Text(
          'Platform Support:',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(info['desktop']!, style: Theme.of(context).textTheme.labelSmall),
        Text(info['mobile']!, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 8),
        Text(
          'Timing:',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(info['showDelay']!, style: Theme.of(context).textTheme.labelSmall),
        Text(info['hideDelay']!, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }

  // ============================================================
  // Trigger Mode Configurations
  // ============================================================

  TooltipConfig _getTriggerModeConfig(int mode) {
    switch (mode) {
      case 0:
        return _createHoverModeConfig();
      case 1:
        return _createTapModeConfig();
      case 2:
        return _createBothModeConfig();
      default:
        return _createHoverModeConfig();
    }
  }

  TooltipConfig _createHoverModeConfig() {
    return const TooltipConfig(
      enabled: true,
      triggerMode: TooltipTriggerMode.hover,
      showDelay: Duration(milliseconds: 200),
      hideDelay: Duration(milliseconds: 0),
      preferredPosition: TooltipPosition.top,
      offsetFromPoint: 12.0,
      style: TooltipStyle(
        backgroundColor: Color(0xFFE3F2FD),
        borderColor: Color(0xFF2196F3),
        borderWidth: 1.5,
        borderRadius: 6.0,
        padding: 10.0,
        textColor: Color(0xFF1565C0),
        fontSize: 13.0,
      ),
      customBuilder: _buildTooltipContent,
    );
  }

  TooltipConfig _createTapModeConfig() {
    return const TooltipConfig(
      enabled: true,
      triggerMode: TooltipTriggerMode.tap,
      showDelay: Duration(milliseconds: 0),
      hideDelay: Duration(milliseconds: 200),
      preferredPosition: TooltipPosition.auto,
      offsetFromPoint: 12.0,
      style: TooltipStyle(
        backgroundColor: Color(0xFFFFF3E0),
        borderColor: Color(0xFFFF6F00),
        borderWidth: 2.0,
        borderRadius: 8.0,
        padding: 12.0,
        textColor: Color(0xFFE65100),
        fontSize: 13.0,
      ),
      customBuilder: _buildTooltipContent,
    );
  }

  TooltipConfig _createBothModeConfig() {
    return const TooltipConfig(
      enabled: true,
      triggerMode: TooltipTriggerMode.both,
      showDelay: Duration(milliseconds: 100),
      hideDelay: Duration(milliseconds: 200),
      preferredPosition: TooltipPosition.auto,
      offsetFromPoint: 12.0,
      style: TooltipStyle(
        backgroundColor: Color(0xFFF3E5F5),
        borderColor: Color(0xFF7B1FA2),
        borderWidth: 1.5,
        borderRadius: 6.0,
        padding: 10.0,
        textColor: Color(0xFF7B1FA2),
        fontSize: 13.0,
      ),
      customBuilder: _buildTooltipContent,
    );
  }

  // ============================================================
  // Tooltip Content Builder
  // ============================================================

  static Widget _buildTooltipContent(BuildContext context, Map<String, dynamic> dataPoint) {
    final x = dataPoint['x'] as num;
    final y = dataPoint['y'] as num;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Day ${x.toInt()}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Revenue: \$${y.toStringAsFixed(0)}',
          style: const TextStyle(
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

