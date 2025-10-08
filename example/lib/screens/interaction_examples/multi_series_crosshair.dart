// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Example 9: Multi-Series Crosshair
///
/// This example demonstrates crosshair and tooltip interactions across multiple
/// series simultaneously:
/// - Vertical crosshair snaps to nearest X coordinate
/// - Tooltip shows all series values at the crosshair position
/// - Three series (temperature, humidity, pressure) on same chart
///
/// Reference: quickstart.md Example 9
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;

class MultiSeriesCrosshairExample extends StatelessWidget {
  const MultiSeriesCrosshairExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Example 9: Multi-Series Crosshair'),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text(
              'Hover over the chart to see crosshair snap to all series at the same X position',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: BravenChart(
              chartType: ChartType.line,
              series: [
                ChartSeries(
                  id: 'temperature',
                  name: 'Temperature (°F)',
                  points: _generateTemperatureData(),
                ),
                ChartSeries(
                  id: 'humidity',
                  name: 'Humidity (%)',
                  points: _generateHumidityData(),
                ),
                ChartSeries(
                  id: 'pressure',
                  name: 'Pressure (hPa)',
                  points: _generatePressureData(),
                ),
              ],
              interactionConfig: InteractionConfig(
                enabled: true,
                // Vertical crosshair only - shows snap points for ALL series
                crosshair: const CrosshairConfig(
                  enabled: true,
                  mode: CrosshairMode.vertical,
                  snapToDataPoint: true,
                  snapRadius: 30.0,
                  style: CrosshairStyle(
                    lineColor: Color(0xFF757575),
                    lineWidth: 1.5,
                    dashPattern: [8, 4],
                  ),
                ),
                // Tooltip shows all series values at X position
                tooltip: TooltipConfig(
                  enabled: true,
                  triggerMode: TooltipTriggerMode.hover,
                  showDelay: const Duration(milliseconds: 200),
                  preferredPosition: TooltipPosition.auto,
                  // Custom builder to show all series values
                  customBuilder: (context, dataPoint) {
                    final x = dataPoint['x'] as num;
                    return _buildMultiSeriesTooltip(context, x.toDouble());
                  },
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text(
              'Multi-series interaction: Crosshair snaps to nearest point on each series',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// Generate temperature data: ~70°F with slight variations
  List<ChartDataPoint> _generateTemperatureData() {
    return List.generate(
      24,
      (i) => ChartDataPoint(
        x: i * 1.0,
        y: 70 + (i * 0.5) + (i % 3) * 2,
      ),
    );
  }

  /// Generate humidity data: ~60% with variations
  List<ChartDataPoint> _generateHumidityData() {
    return List.generate(
      24,
      (i) => ChartDataPoint(
        x: i * 1.0,
        y: 60 - (i * 0.3) + (i % 4) * 3,
      ),
    );
  }

  /// Generate pressure data: ~1013 hPa with slight variations
  List<ChartDataPoint> _generatePressureData() {
    return List.generate(
      24,
      (i) => ChartDataPoint(
        x: i * 1.0,
        y: 1013 + (i * 0.2) - (i % 5) * 1,
      ),
    );
  }

  /// Build tooltip showing all series values at the given X coordinate
  ///
  /// In a real implementation, the chart would provide all series points at
  /// the X coordinate. For this example, we calculate the approximate values.
  Widget _buildMultiSeriesTooltip(BuildContext context, double xValue) {
    final hour = xValue.toInt();

    // Calculate approximate values for each series at this X
    final tempValue = 70 + (hour * 0.5) + (hour % 3) * 2;
    final humidValue = 60 - (hour * 0.3) + (hour % 4) * 3;
    final pressValue = 1013 + (hour * 0.2) - (hour % 5) * 1;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hour $hour:00',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const Divider(height: 12),
          _buildSeriesRow('Temperature', tempValue, const Color(0xFFFF5252)),
          const SizedBox(height: 4),
          _buildSeriesRow('Humidity', humidValue, const Color(0xFF2196F3)),
          const SizedBox(height: 4),
          _buildSeriesRow('Pressure', pressValue, const Color(0xFF4CAF50)),
        ],
      ),
    );
  }

  /// Build a row showing series name, value, and color indicator
  Widget _buildSeriesRow(String name, double value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$name: ${value.toStringAsFixed(1)}',
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }
}
