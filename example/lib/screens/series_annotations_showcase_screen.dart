// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Series-Level Annotations Showcase
///
/// Demonstrates the NEW ARCHITECTURE where annotations are attached directly
/// to ChartSeries, providing:
/// - Better encapsulation (data + annotations together)
/// - No redundant seriesId lookups
/// - Each series can have independent annotations
/// - Cleaner, more maintainable API
///
/// Features:
/// - 3 different data series (Temperature, Humidity, Pressure)
/// - Each series has its own set of annotations
/// - Different annotation types per series
/// - Visual comparison of old vs new pattern
/// - Interactive controls to show/hide series
library;

import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

class SeriesAnnotationsShowcaseScreen extends StatefulWidget {
  const SeriesAnnotationsShowcaseScreen({super.key});

  @override
  State<SeriesAnnotationsShowcaseScreen> createState() => _SeriesAnnotationsShowcaseScreenState();
}

class _SeriesAnnotationsShowcaseScreenState extends State<SeriesAnnotationsShowcaseScreen> {
  // Control which series are visible
  bool _showTemperature = true;
  bool _showHumidity = true;
  bool _showPressure = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎯 Series-Level Annotations Showcase'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Architecture Info',
            onPressed: () => _showArchitectureInfo(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildInfoBanner(),
          _buildSeriesControls(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: BravenChart(
                    chartType: ChartType.line,
                    series: _buildAllSeries(),
                    title: 'Multi-Series Weather Data with Series-Level Annotations',
                    theme: ChartTheme.defaultLight,
                    interactionConfig: const InteractionConfig(
                      enabled: true,
                      enableZoom: true,
                      enablePan: true,
                    ),
                  ),
                ),
              ),
            ),
          ),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.purple.shade50],
        ),
        border: Border(bottom: BorderSide(color: Colors.blue.shade200, width: 2)),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome, color: Colors.blue, size: 24),
              SizedBox(width: 8),
              Text(
                'NEW ARCHITECTURE: Annotations on ChartSeries',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade400),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '✅ Each series owns its annotations  |  ✅ No redundant seriesId  |  ✅ Better encapsulation  |  ✅ Independent per-series control',
                    style: TextStyle(fontSize: 12, color: Colors.green.shade900, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeriesControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Show Series: ', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
          _buildSeriesToggle('🌡️ Temperature', _showTemperature, Colors.red, (val) => setState(() => _showTemperature = val)),
          const SizedBox(width: 12),
          _buildSeriesToggle('💧 Humidity', _showHumidity, Colors.blue, (val) => setState(() => _showHumidity = val)),
          const SizedBox(width: 12),
          _buildSeriesToggle('⚖️ Pressure', _showPressure, Colors.green, (val) => setState(() => _showPressure = val)),
        ],
      ),
    );
  }

  Widget _buildSeriesToggle(String label, bool value, Color color, ValueChanged<bool> onChanged) {
    return FilterChip(
      label: Text(label),
      selected: value,
      onSelected: onChanged,
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
      side: BorderSide(color: value ? color : Colors.grey.shade400),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📊 Annotation Legend:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 24,
            runSpacing: 8,
            children: [
              _buildLegendItem(
                  '🌡️ Temperature',
                  [
                    'Threshold: Target temp (28°C)',
                    'Linear trend line',
                    'Range: Hot zone (26-32°C)',
                    'Point: Peak temperature marker',
                  ],
                  Colors.red),
              _buildLegendItem(
                  '💧 Humidity',
                  [
                    'Threshold: Comfort level (60%)',
                    'Moving average trend (5-period)',
                    'Range: Comfort zone (55-65%)',
                    'Text: Low humidity annotation',
                  ],
                  Colors.blue),
              _buildLegendItem(
                  '⚖️ Pressure',
                  [
                    'Threshold: Standard pressure (1013 hPa)',
                    'Polynomial trend (degree 3)',
                    'Range: High pressure zone (1016-1021 hPa)',
                    'Point: Pressure spike marker',
                  ],
                  Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String title, List<String> items, Color color) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(color: color, fontSize: 12)),
                    Expanded(child: Text(item, style: const TextStyle(fontSize: 11))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  List<ChartSeries> _buildAllSeries() {
    final series = <ChartSeries>[];

    if (_showTemperature) {
      series.add(_buildTemperatureSeries());
    }
    if (_showHumidity) {
      series.add(_buildHumiditySeries());
    }
    if (_showPressure) {
      series.add(_buildPressureSeries());
    }

    return series;
  }

  /// Temperature Series with its own annotations
  ChartSeries _buildTemperatureSeries() {
    return ChartSeries(
      id: 'temperature',
      name: 'Temperature (°C)',
      points: _generateTemperatureData(),
      color: Colors.red,
      annotations: [
        // Threshold annotation for target temperature
        ThresholdAnnotation(
          id: 'temp_threshold',
          label: 'Target: 28°C',
          axis: AnnotationAxis.y,
          value: 28,
          lineColor: Colors.red,
          lineWidth: 2,
          dashPattern: const [8, 4],
          labelPosition: AnnotationLabelPosition.topRight,
          style: AnnotationStyle(
            textStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            backgroundColor: Colors.red,
            borderRadius: BorderRadius.circular(4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
        ),

        // Linear trend line
        TrendAnnotation(
          id: 'temp_trend',
          label: 'Temperature Trend',
          trendType: TrendType.linear,
          lineColor: Colors.red.withAlpha(150),
          lineWidth: 2.5,
          dashPattern: const [6, 3],
        ),

        // Range annotation for above-average zone (more visible)
        RangeAnnotation(
          id: 'temp_range',
          label: 'Hot Zone',
          startY: 26,
          endY: 32,
          fillColor: Colors.red.withAlpha(40),
          borderColor: Colors.red.withAlpha(150),
          labelPosition: AnnotationLabelPosition.topLeft,
          style: const AnnotationStyle(
            textStyle: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
            backgroundColor: Colors.white,
            borderColor: Colors.red,
            borderWidth: 1,
            borderRadius: BorderRadius.all(Radius.circular(4)),
            padding: EdgeInsets.all(4),
          ),
        ),

        // Point annotation for peak temperature
        PointAnnotation(
          id: 'temp_peak',
          label: 'Peak 🔥',
          seriesId: 'temperature', // Still required for PointAnnotation
          dataPointIndex: 15, // Approximate peak
          markerShape: MarkerShape.circle,
          markerSize: 12,
          markerColor: Colors.orange,
          style: const AnnotationStyle(
            textStyle: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
            backgroundColor: Colors.white,
            borderColor: Colors.orange,
            borderWidth: 1,
            borderRadius: BorderRadius.all(Radius.circular(4)),
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          ),
        ),
      ],
    );
  }

  /// Humidity Series with its own annotations
  ChartSeries _buildHumiditySeries() {
    return ChartSeries(
      id: 'humidity',
      name: 'Humidity (%)',
      points: _generateHumidityData(),
      color: Colors.blue,
      annotations: [
        // Threshold annotation for comfort level
        ThresholdAnnotation(
          id: 'humidity_threshold',
          label: 'Comfort: 60%',
          axis: AnnotationAxis.y,
          value: 60,
          lineColor: Colors.blue,
          lineWidth: 2,
          dashPattern: const [5, 5],
          labelPosition: AnnotationLabelPosition.bottomLeft,
          style: AnnotationStyle(
            textStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            backgroundColor: Colors.blue,
            borderRadius: BorderRadius.circular(4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
        ),

        // Moving average trend
        TrendAnnotation(
          id: 'humidity_trend',
          label: 'Humidity MA(5)',
          trendType: TrendType.movingAverage,
          windowSize: 5,
          lineColor: Colors.blue.withAlpha(150),
          lineWidth: 2,
        ),

        // Range annotation for optimal humidity (more visible)
        RangeAnnotation(
          id: 'humidity_range',
          label: 'Comfort Zone',
          startY: 55,
          endY: 65,
          fillColor: Colors.blue.withAlpha(40),
          borderColor: Colors.blue.withAlpha(150),
          labelPosition: AnnotationLabelPosition.bottomRight,
          style: const AnnotationStyle(
            textStyle: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.blue,
            ),
            backgroundColor: Colors.white,
            borderColor: Colors.blue,
            borderWidth: 1,
            borderRadius: BorderRadius.all(Radius.circular(4)),
            padding: EdgeInsets.all(4),
          ),
        ),

        // Text annotation for specific data point
        TextAnnotation(
          id: 'humidity_note',
          text: 'Low\nHumidity',
          dataX: 8.0,
          dataY: 52.0,
          seriesId: 'humidity',
          style: const AnnotationStyle(
            textStyle: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
            backgroundColor: Colors.white,
            borderColor: Colors.blue,
            borderWidth: 1,
            borderRadius: BorderRadius.all(Radius.circular(4)),
            padding: EdgeInsets.all(4),
          ),
        ),
      ],
    );
  }

  /// Pressure Series with its own annotations
  ChartSeries _buildPressureSeries() {
    return ChartSeries(
      id: 'pressure',
      name: 'Pressure (hPa)',
      points: _generatePressureData(),
      color: Colors.green,
      annotations: [
        // Threshold annotation for standard pressure
        ThresholdAnnotation(
          id: 'pressure_threshold',
          label: 'Standard: 1013 hPa',
          axis: AnnotationAxis.y,
          value: 1013,
          lineColor: Colors.green,
          lineWidth: 2,
          dashPattern: const [10, 5],
          labelPosition: AnnotationLabelPosition.topLeft,
          style: AnnotationStyle(
            textStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            backgroundColor: Colors.green,
            borderRadius: BorderRadius.circular(4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
        ),

        // Polynomial trend
        TrendAnnotation(
          id: 'pressure_trend',
          label: 'Pressure Polynomial',
          trendType: TrendType.polynomial,
          degree: 3,
          lineColor: Colors.green.withAlpha(150),
          lineWidth: 2.5,
          dashPattern: const [4, 4],
        ),

        // Range annotation for high pressure (more visible)
        RangeAnnotation(
          id: 'pressure_range',
          label: 'High Pressure',
          startY: 1016,
          endY: 1021,
          fillColor: Colors.green.withAlpha(40),
          borderColor: Colors.green.withAlpha(150),
          labelPosition: AnnotationLabelPosition.topRight,
          style: const AnnotationStyle(
            textStyle: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
            backgroundColor: Colors.white,
            borderColor: Colors.green,
            borderWidth: 1,
            borderRadius: BorderRadius.all(Radius.circular(4)),
            padding: EdgeInsets.all(4),
          ),
        ),

        // Point annotation for pressure spike
        PointAnnotation(
          id: 'pressure_spike',
          label: 'Spike ⚡',
          seriesId: 'pressure', // Still required for PointAnnotation
          dataPointIndex: 20, // Approximate spike
          markerShape: MarkerShape.triangle,
          markerSize: 12,
          markerColor: Colors.amber,
          style: const AnnotationStyle(
            textStyle: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
            backgroundColor: Colors.white,
            borderColor: Colors.amber,
            borderWidth: 1,
            borderRadius: BorderRadius.all(Radius.circular(4)),
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          ),
        ),
      ],
    );
  }

  void _showArchitectureInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.architecture, color: Colors.blue),
            SizedBox(width: 8),
            Text('Series-Level Annotations Architecture'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🎯 NEW PATTERN (Preferred):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: const Text(
                  'ChartSeries(\n'
                  '  id: \'temperature\',\n'
                  '  points: [...],\n'
                  '  annotations: [  // ✅ Annotations WITH data!\n'
                  '    TrendAnnotation(\n'
                  '      // No seriesId needed - inferred!\n'
                  '      trendType: TrendType.linear,\n'
                  '    ),\n'
                  '  ],\n'
                  ')',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '❌ OLD PATTERN (Still works):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Text(
                  'BravenChart(\n'
                  '  series: [temperatureSeries],\n'
                  '  annotations: [  // ❌ Chart-level\n'
                  '    TrendAnnotation(\n'
                  '      seriesId: \'temperature\',  // ❌ Required lookup\n'
                  '      trendType: TrendType.linear,\n'
                  '    ),\n'
                  '  ],\n'
                  ')',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '✅ Benefits:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text('• Data Locality: Annotations live with their data'),
              const Text('• Encapsulation: Series owns data + annotations'),
              const Text('• No Redundancy: seriesId inferred from parent'),
              const Text('• Scalability: Each series has independent annotations'),
              const Text('• Dataset Scope: Trends use parent series automatically'),
              const Text('• Backwards Compatible: Chart-level still works'),
              const SizedBox(height: 16),
              const Text(
                '📊 This Demo:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text('• 3 series: Temperature, Humidity, Pressure'),
              const Text('• Each has 4 unique annotations'),
              const Text('• Total: 12 series-level annotations'),
              const Text('• Toggle series on/off to see effect'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got It!'),
          ),
        ],
      ),
    );
  }

  // Data generation methods - Realistic weather data with trends, noise, and variation
  static List<ChartDataPoint> _generateTemperatureData() {
    final points = <ChartDataPoint>[];
    final random = math.Random(42);
    
    for (int i = 0; i < 30; i++) {
      final x = i.toDouble();
      
      // Base temperature with daily cycle
      final dailyCycle = 22 + math.sin(i * 0.5) * 6;
      
      // Upward trend (warming)
      final trend = i * 0.15;
      
      // Multi-frequency variations (weather systems)
      final weather = math.sin(i * 0.3) * 3 + math.cos(i * 0.7) * 2;
      
      // Random noise (micro-variations)
      final noise = (random.nextDouble() - 0.5) * 4;
      
      // Occasional spikes (hot days)
      final spike = (i == 12 || i == 25) ? random.nextDouble() * 5 : 0;
      
      final y = dailyCycle + trend + weather + noise + spike;
      points.add(ChartDataPoint(x: x, y: y));
    }
    return points;
  }

  static List<ChartDataPoint> _generateHumidityData() {
    final points = <ChartDataPoint>[];
    final random = math.Random(123);
    
    for (int i = 0; i < 30; i++) {
      final x = i.toDouble();
      
      // Base humidity
      final base = 58;
      
      // Inverse correlation with temperature pattern
      final tempInfluence = -math.sin(i * 0.5) * 4;
      
      // Weather system influence
      final weather = math.cos(i * 0.4) * 6 + math.sin(i * 0.8) * 3;
      
      // Random variations
      final noise = (random.nextDouble() - 0.5) * 5;
      
      // Occasional dry periods
      final dryPeriod = (i >= 7 && i <= 10) ? -8 : 0;
      
      // Occasional humid periods
      final humidPeriod = (i >= 18 && i <= 22) ? 6 : 0;
      
      final y = base + tempInfluence + weather + noise + dryPeriod + humidPeriod;
      points.add(ChartDataPoint(x: x, y: y.clamp(40, 80)));
    }
    return points;
  }

  static List<ChartDataPoint> _generatePressureData() {
    final points = <ChartDataPoint>[];
    final random = math.Random(456);
    
    for (int i = 0; i < 30; i++) {
      final x = i.toDouble();
      
      // Base pressure (standard atmospheric)
      final base = 1013;
      
      // Pressure systems (high and low)
      final systems = math.sin(i * 0.25) * 5 + math.cos(i * 0.15) * 4;
      
      // Fronts passing through
      final fronts = math.sin(i * 0.6) * 3;
      
      // Random micro-variations
      final noise = (random.nextDouble() - 0.5) * 2;
      
      // High pressure period
      final highPressure = (i >= 15 && i <= 23) ? 4 : 0;
      
      // Pressure spike
      final spike = (i == 20) ? 3 : 0;
      
      final y = base + systems + fronts + noise + highPressure + spike;
      points.add(ChartDataPoint(x: x, y: y));
    }
    return points;
  }
}
