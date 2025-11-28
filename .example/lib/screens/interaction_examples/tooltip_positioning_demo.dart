// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Example 12: Tooltip Positioning
///
/// This example demonstrates the different positioning options for tooltips:
///
/// - **Auto Position** (Smart): Automatically positions tooltip to avoid clipping
///   - Prefers top, but moves bottom/left/right as needed
///   - Best for most use cases
///
/// - **Top Position**: Always shows tooltip above the data point
///   - Good for bottom-aligned charts
///
/// - **Bottom Position**: Always shows tooltip below the data point
///   - Good for top-aligned charts
///
/// - **Left Position**: Always shows tooltip to the left of the data point
///   - Good for right-aligned charts
///
/// - **Right Position**: Always shows tooltip to the right of the data point
///   - Good for left-aligned charts
///
/// Try hovering near chart edges to see how different positioning strategies
/// handle edge cases and clipping prevention.
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;

class TooltipPositioningDemoExample extends StatefulWidget {
  const TooltipPositioningDemoExample({super.key});

  @override
  State<TooltipPositioningDemoExample> createState() => _TooltipPositioningDemoExampleState();
}

class _TooltipPositioningDemoExampleState extends State<TooltipPositioningDemoExample> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Example 12: Tooltip Positioning'),
      ),
      body: Column(
        children: [
          // Manual navigation buttons
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: Colors.grey.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _currentPage > 0
                      ? () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : null,
                  icon: const Icon(Icons.chevron_left),
                  label: const Text('Previous'),
                ),
                Text(
                  'Position ${_currentPage + 1} of 5',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                ElevatedButton.icon(
                  onPressed: _currentPage < 4
                      ? () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : null,
                  icon: const Icon(Icons.chevron_right),
                  label: const Text('Next'),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              physics: const BouncingScrollPhysics(),
              children: [
                _buildPositioningChart(
                  'Auto Position',
                  Colors.blue,
                  _createAutoPositionConfig(),
                  'Smart positioning - avoids edges',
                ),
                _buildPositioningChart(
                  'Top Position',
                  Colors.green,
                  _createTopPositionConfig(),
                  'Always above data point',
                ),
                _buildPositioningChart(
                  'Bottom Position',
                  Colors.orange,
                  _createBottomPositionConfig(),
                  'Always below data point',
                ),
                _buildPositioningChart(
                  'Left Position',
                  Colors.purple,
                  _createLeftPositionConfig(),
                  'Always left of data point',
                ),
                _buildPositioningChart(
                  'Right Position',
                  Colors.red,
                  _createRightPositionConfig(),
                  'Always right of data point',
                ),
              ],
            ),
          ),
          // Page indicator and description
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () {
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index ? Colors.blue : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Description
                _buildPositionDescription(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPositioningChart(
    String title,
    Color seriesColor,
    TooltipConfig config,
    String description,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Hover or tap data points, especially near edges',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BravenChart(
                chartType: ChartType.scatter,
                series: [
                  ChartSeries(
                    id: 'scatter',
                    name: title,
                    points: const [
                      ChartDataPoint(x: 2, y: 10),
                      ChartDataPoint(x: 4, y: 25),
                      ChartDataPoint(x: 6, y: 18),
                      ChartDataPoint(x: 8, y: 30),
                      ChartDataPoint(x: 10, y: 22),
                    ],
                    color: seriesColor,
                  ),
                ],
                interactionConfig: InteractionConfig(
                  crosshair: const CrosshairConfig(
                    enabled: true,
                    snapToDataPoint: true,
                  ),
                  tooltip: config,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionDescription() {
    final descriptions = [
      'Auto position uses intelligent algorithm to place tooltip where it fits best. '
          'Typically prefers top, but will move to bottom, left, or right if needed to avoid clipping.',
      'Top position always places tooltip above the data point. Works well when chart has space at top '
          'and data points are mostly in lower half.',
      'Bottom position always places tooltip below the data point. Good for charts with data concentrated '
          'in the upper half and plenty of space at bottom.',
      'Left position always places tooltip to the left. Useful when data points are on the right side '
          'of the chart or when you want to preserve space on the right.',
      'Right position always places tooltip to the right. Useful when data points are on the left side '
          'of the chart and you want to show details to the right.',
    ];

    return Text(
      descriptions[_currentPage],
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade700,
          ),
    );
  }

  // ============================================================
  // Positioning Configurations
  // ============================================================

  TooltipConfig _createAutoPositionConfig() {
    return const TooltipConfig(
      enabled: true,
      triggerMode: TooltipTriggerMode.both,
      preferredPosition: TooltipPosition.auto,
      offsetFromPoint: 30.0,
      showDelay: Duration(milliseconds: 100),
      hideDelay: Duration(milliseconds: 0),
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

  TooltipConfig _createTopPositionConfig() {
    return const TooltipConfig(
      enabled: true,
      triggerMode: TooltipTriggerMode.both,
      preferredPosition: TooltipPosition.top,
      offsetFromPoint: 30.0,
      showDelay: Duration(milliseconds: 100),
      hideDelay: Duration(milliseconds: 0),
      style: TooltipStyle(
        backgroundColor: Color(0xFFE8F5E9),
        borderColor: Color(0xFF4CAF50),
        borderWidth: 1.5,
        borderRadius: 6.0,
        padding: 10.0,
        textColor: Color(0xFF2E7D32),
        fontSize: 13.0,
      ),
      customBuilder: _buildTooltipContent,
    );
  }

  TooltipConfig _createBottomPositionConfig() {
    return const TooltipConfig(
      enabled: true,
      triggerMode: TooltipTriggerMode.both,
      preferredPosition: TooltipPosition.bottom,
      offsetFromPoint: 30.0,
      showDelay: Duration(milliseconds: 100),
      hideDelay: Duration(milliseconds: 0),
      style: TooltipStyle(
        backgroundColor: Color(0xFFFFF3E0),
        borderColor: Color(0xFFFF6F00),
        borderWidth: 1.5,
        borderRadius: 6.0,
        padding: 10.0,
        textColor: Color(0xFFE65100),
        fontSize: 13.0,
      ),
      customBuilder: _buildTooltipContent,
    );
  }

  TooltipConfig _createLeftPositionConfig() {
    return const TooltipConfig(
      enabled: true,
      triggerMode: TooltipTriggerMode.both,
      preferredPosition: TooltipPosition.left,
      offsetFromPoint: 30.0,
      showDelay: Duration(milliseconds: 100),
      hideDelay: Duration(milliseconds: 0),
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

  TooltipConfig _createRightPositionConfig() {
    return const TooltipConfig(
      enabled: true,
      triggerMode: TooltipTriggerMode.both,
      preferredPosition: TooltipPosition.right,
      offsetFromPoint: 30.0,
      showDelay: Duration(milliseconds: 100),
      hideDelay: Duration(milliseconds: 0),
      style: TooltipStyle(
        backgroundColor: Color(0xFFFFEBEE),
        borderColor: Color(0xFFC2185B),
        borderWidth: 1.5,
        borderRadius: 6.0,
        padding: 10.0,
        textColor: Color(0xFFC2185B),
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
        const Text(
          'Data Point',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'X: ${x.toStringAsFixed(1)}',
          style: const TextStyle(fontSize: 13),
        ),
        Text(
          'Y: ${y.toStringAsFixed(1)}',
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }
}

