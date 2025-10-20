// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Example 10: Tooltip Styling Variants
///
/// This example showcases different tooltip style configurations to demonstrate
/// the full range of visual customization options available:
///
/// - **Light Style**: Light gray background with subtle shadow
/// - **Dark Style**: Dark background with light text (modern appearance)
/// - **Accent Style**: Color-accented tooltip with bold styling
/// - **Minimal Style**: No border, no shadow, just content
/// - **Material Style**: Material Design themed with elevation shadow
///
/// Each variant is shown with a different data series. Hover or tap to see
/// how the tooltip styling changes based on configuration.
///
/// Key TooltipStyle Properties:
/// - backgroundColor: Color of the tooltip background
/// - borderColor & borderWidth: Border appearance
/// - borderRadius: Corner rounding (0 = sharp, 8+ = rounded)
/// - shadowColor & shadowBlurRadius: Drop shadow effect
/// - padding: Interior spacing around content
/// - textColor & fontSize: Text styling
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;

class TooltipStylingVariantsExample extends StatefulWidget {
  const TooltipStylingVariantsExample({super.key});

  @override
  State<TooltipStylingVariantsExample> createState() => _TooltipStylingVariantsExampleState();
}

class _TooltipStylingVariantsExampleState extends State<TooltipStylingVariantsExample> {
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
        title: const Text('Example 10: Tooltip Styling Variants'),
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
                  'Style ${_currentPage + 1} of 5',
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
                _buildStyleVariantChart(
                  'Light Style',
                  _createLightStyleConfig(),
                  Colors.blue,
                ),
                _buildStyleVariantChart(
                  'Dark Style',
                  _createDarkStyleConfig(),
                  Colors.green,
                ),
                _buildStyleVariantChart(
                  'Accent Style',
                  _createAccentStyleConfig(),
                  Colors.orange,
                ),
                _buildStyleVariantChart(
                  'Minimal Style',
                  _createMinimalStyleConfig(),
                  Colors.purple,
                ),
                _buildStyleVariantChart(
                  'Material Style',
                  _createMaterialStyleConfig(),
                  Colors.indigo,
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
                const SizedBox(height: 16),
                // Style descriptions
                _buildStyleDescription(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleVariantChart(String title, TooltipConfig config, Color seriesColor) {
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
              'Hover or tap to see ${title.toLowerCase()}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BravenChart(
                chartType: ChartType.line,
                series: [
                  ChartSeries(
                    id: 'variant',
                    name: title,
                    points: const [
                      ChartDataPoint(x: 1, y: 30),
                      ChartDataPoint(x: 2, y: 45),
                      ChartDataPoint(x: 3, y: 35),
                      ChartDataPoint(x: 4, y: 60),
                      ChartDataPoint(x: 5, y: 50),
                      ChartDataPoint(x: 6, y: 70),
                    ],
                    color: seriesColor,
                  ),
                ],
                interactionConfig: InteractionConfig(
                  crosshair: CrosshairConfig.defaultConfig(),
                  tooltip: config,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleDescription() {
    final descriptions = [
      'Light background with subtle gray border and soft shadow. Classic, professional appearance.',
      'Dark background with light text. Modern dark-mode style with bold borders and pronounced shadow.',
      'Bright accent background with vibrant colors. Bold borders and strong shadows for emphasis.',
      'No border, no shadow, just content. Clean, minimalist approach for unobtrusive tooltips.',
      'Material Design elevation-style shadow. Rounded corners with layered depth effect.',
    ];

    return Text(
      descriptions[_currentPage],
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade700,
          ),
    );
  }

  // ============================================================
  // Tooltip Style Configurations
  // ============================================================

  TooltipConfig _createLightStyleConfig() {
    return const TooltipConfig(
      enabled: true,
      triggerMode: TooltipTriggerMode.both,
      preferredPosition: TooltipPosition.auto,
      offsetFromPoint: 10.0,
      showDelay: Duration(milliseconds: 200),
      hideDelay: Duration.zero,
      style: TooltipStyle(
        backgroundColor: Color(0xFFFAFAFA), // Near white
        borderColor: Color(0xFFD0D0D0), // Light gray
        borderWidth: 1.0,
        borderRadius: 4.0,
        padding: 8.0,
        textColor: Color(0xFF424242), // Dark gray text
        fontSize: 13.0,
        shadowColor: Color(0x1A000000), // Subtle shadow
        shadowBlurRadius: 3.0,
      ),
    );
  }

  TooltipConfig _createDarkStyleConfig() {
    return const TooltipConfig(
      enabled: true,
      triggerMode: TooltipTriggerMode.both,
      preferredPosition: TooltipPosition.auto,
      offsetFromPoint: 10.0,
      showDelay: Duration(milliseconds: 200),
      hideDelay: Duration.zero,
      style: TooltipStyle(
        backgroundColor: Color(0xFF212121), // Dark gray/charcoal
        borderColor: Color(0xFF424242), // Medium gray border
        borderWidth: 2.0,
        borderRadius: 6.0,
        padding: 10.0,
        textColor: Color(0xFFE0E0E0), // Light text
        fontSize: 13.0,
        shadowColor: Color(0x40000000), // Stronger shadow
        shadowBlurRadius: 8.0,
      ),
    );
  }

  TooltipConfig _createAccentStyleConfig() {
    return const TooltipConfig(
      enabled: true,
      triggerMode: TooltipTriggerMode.both,
      preferredPosition: TooltipPosition.auto,
      offsetFromPoint: 10.0,
      showDelay: Duration(milliseconds: 200),
      hideDelay: Duration.zero,
      style: TooltipStyle(
        backgroundColor: Color(0xFFFF6F00), // Deep orange
        borderColor: Color(0xFFE65100), // Orange red border
        borderWidth: 2.5,
        borderRadius: 8.0,
        padding: 12.0,
        textColor: Color(0xFFFFFFFF), // White text
        fontSize: 14.0,
        shadowColor: Color(0x80FF6F00), // Orange-tinted shadow
        shadowBlurRadius: 10.0,
      ),
    );
  }

  TooltipConfig _createMinimalStyleConfig() {
    return const TooltipConfig(
      enabled: true,
      triggerMode: TooltipTriggerMode.both,
      preferredPosition: TooltipPosition.auto,
      offsetFromPoint: 10.0,
      showDelay: Duration(milliseconds: 200),
      hideDelay: Duration.zero,
      style: TooltipStyle(
        backgroundColor: Color(0xFFEEEEEE), // Light background
        borderColor: Color(0xFFEEEEEE), // No visible border
        borderWidth: 0.0,
        borderRadius: 0.0, // Sharp corners
        padding: 6.0, // Minimal padding
        textColor: Color(0xFF616161),
        fontSize: 12.0,
        shadowColor: Color(0x00000000), // No shadow
        shadowBlurRadius: 0.0,
      ),
    );
  }

  TooltipConfig _createMaterialStyleConfig() {
    return const TooltipConfig(
      enabled: true,
      triggerMode: TooltipTriggerMode.both,
      preferredPosition: TooltipPosition.auto,
      offsetFromPoint: 10.0,
      showDelay: Duration(milliseconds: 200),
      hideDelay: Duration.zero,
      style: TooltipStyle(
        backgroundColor: Color(0xFF3F51B5), // Material indigo
        borderColor: Color(0xFF3F51B5), // No visible border
        borderWidth: 0.0,
        borderRadius: 12.0, // Rounded Material style
        padding: 14.0,
        textColor: Color(0xFFFFFFFF), // White text
        fontSize: 14.0,
        shadowColor: Color(0x60000000), // Material elevation shadow
        shadowBlurRadius: 12.0,
      ),
    );
  }
}
