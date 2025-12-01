// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Task 016 Showcase Demo: Multi-Axis Normalization Complete Sprint Demo
///
/// This comprehensive showcase demonstrates all 4 user stories from
/// Sprint 011 - Multi-Axis Normalization:
///
/// - US1: Multi-Scale Visualization (Power W + Heart Rate bpm)
/// - US2: Auto-Detection Mode (automatic normalization when ranges differ >10x)
/// - US3: Color-Coded Axes (axis colors match their bound series)
/// - US4: Crosshair with Original Values (tooltip displays real values)
///
/// Run: flutter run -t lib/demos/task_016_showcase_demo.dart
library;

import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

void main() => runApp(const Task016ShowcaseDemo());

/// Root application widget for the showcase demo.
class Task016ShowcaseDemo extends StatefulWidget {
  const Task016ShowcaseDemo({super.key});

  @override
  State<Task016ShowcaseDemo> createState() => _Task016ShowcaseDemoState();
}

class _Task016ShowcaseDemoState extends State<Task016ShowcaseDemo> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Multi-Axis Showcase',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Sprint 011: Multi-Axis Normalization'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'US1: Multi-Scale'),
              Tab(text: 'US2: Auto-Detect'),
              Tab(text: 'US3: Color-Coded'),
              Tab(text: 'US4: Crosshair'),
            ],
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildMultiScaleDemo(),
            _buildAutoDetectDemo(),
            _buildColorCodedDemo(),
            _buildCrosshairDemo(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // US1: Multi-Scale Visualization
  // ============================================================

  /// Demonstrates displaying Power (0-300W) and Heart Rate (60-200bpm)
  /// on the same chart, each using full vertical space.
  Widget _buildMultiScaleDemo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDemoHeader(
            'US1: Multi-Scale Visualization',
            'Power (W) and Heart Rate (bpm) with vastly different ranges\n'
                'displayed on the same chart. Each series uses the full vertical space.',
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BravenChartPlus(
              chartType: ChartType.line,
              series: [
                LineChartSeries(
                  id: 'power',
                  name: 'Power Output',
                  points: _generatePowerData(),
                  color: Colors.blue,
                  yAxisId: 'power-axis',
                  unit: 'W',
                ),
                LineChartSeries(
                  id: 'hr',
                  name: 'Heart Rate',
                  points: _generateHRData(),
                  color: Colors.red,
                  yAxisId: 'hr-axis',
                  unit: 'bpm',
                ),
              ],
              yAxes: [
                YAxisConfig(
                  id: 'power-axis',
                  position: YAxisPosition.left,
                  label: 'Power',
                  unit: 'W',
                  color: Colors.blue,
                ),
                YAxisConfig(
                  id: 'hr-axis',
                  position: YAxisPosition.right,
                  label: 'Heart Rate',
                  unit: 'bpm',
                  color: Colors.red,
                ),
              ],
              axisBindings: const [
                SeriesAxisBinding(seriesId: 'power', yAxisId: 'power-axis'),
                SeriesAxisBinding(seriesId: 'hr', yAxisId: 'hr-axis'),
              ],
              normalizationMode: NormalizationMode.perSeries,
            ),
          ),
          const SizedBox(height: 16),
          _buildCodeSnippet('''
BravenChartPlus(
  series: [
    LineChartSeries(id: 'power', yAxisId: 'power-axis', unit: 'W', ...),
    LineChartSeries(id: 'hr', yAxisId: 'hr-axis', unit: 'bpm', ...),
  ],
  yAxes: [
    YAxisConfig(id: 'power-axis', position: YAxisPosition.left, ...),
    YAxisConfig(id: 'hr-axis', position: YAxisPosition.right, ...),
  ],
  normalizationMode: NormalizationMode.perSeries,
)'''),
        ],
      ),
    );
  }

  // ============================================================
  // US2: Auto-Detection Mode
  // ============================================================

  /// Demonstrates automatic normalization detection when series ranges
  /// differ by more than 10x.
  Widget _buildAutoDetectDemo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDemoHeader(
            'US2: Auto-Detection Mode',
            'No explicit normalizationMode needed! The system automatically\n'
                'detects when series ranges differ by >10x and enables multi-axis.',
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BravenChartPlus(
              chartType: ChartType.line,
              series: [
                // Temperature: 20-80°C range
                LineChartSeries(
                  id: 'temp',
                  name: 'Temperature',
                  points: _generateTemperatureData(),
                  color: Colors.orange,
                  yAxisId: 'temp-axis',
                  unit: '°C',
                ),
                // Pressure: 1000-9000 Pa range (~100x different scale)
                LineChartSeries(
                  id: 'pressure',
                  name: 'Pressure',
                  points: _generatePressureData(),
                  color: Colors.purple,
                  yAxisId: 'pressure-axis',
                  unit: 'Pa',
                ),
              ],
              yAxes: [
                YAxisConfig(
                  id: 'temp-axis',
                  position: YAxisPosition.left,
                  label: 'Temperature',
                  unit: '°C',
                  color: Colors.orange,
                ),
                YAxisConfig(
                  id: 'pressure-axis',
                  position: YAxisPosition.right,
                  label: 'Pressure',
                  unit: 'Pa',
                  color: Colors.purple,
                ),
              ],
              axisBindings: const [
                SeriesAxisBinding(seriesId: 'temp', yAxisId: 'temp-axis'),
                SeriesAxisBinding(seriesId: 'pressure', yAxisId: 'pressure-axis'),
              ],
              normalizationMode: NormalizationMode.auto, // Auto-detect!
            ),
          ),
          const SizedBox(height: 16),
          _buildCodeSnippet('''
BravenChartPlus(
  series: [
    LineChartSeries(id: 'temp', points: tempData, ...),  // 20-80 range
    LineChartSeries(id: 'pressure', points: pressureData, ...),  // 1000-9000 range
  ],
  yAxes: [...],
  normalizationMode: NormalizationMode.auto,  // System detects >10x difference!
)'''),
        ],
      ),
    );
  }

  // ============================================================
  // US3: Color-Coded Axes
  // ============================================================

  /// Demonstrates axes with colors that match their bound series.
  Widget _buildColorCodedDemo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDemoHeader(
            'US3: Color-Coded Axes',
            'Each Y-axis is colored to match its bound series.\n'
                'This visual link makes it easy to identify which axis belongs to which data.',
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BravenChartPlus(
              chartType: ChartType.line,
              series: [
                LineChartSeries(
                  id: 'revenue',
                  name: 'Revenue',
                  points: _generateRevenueData(),
                  color: const Color(0xFF1E88E5), // Blue
                  yAxisId: 'revenue-axis',
                  unit: '\$K',
                ),
                LineChartSeries(
                  id: 'users',
                  name: 'Active Users',
                  points: _generateUsersData(),
                  color: const Color(0xFFD81B60), // Pink
                  yAxisId: 'users-axis',
                  unit: '',
                ),
                LineChartSeries(
                  id: 'sessions',
                  name: 'Sessions',
                  points: _generateSessionsData(),
                  color: const Color(0xFF43A047), // Green
                  yAxisId: 'sessions-axis',
                ),
              ],
              yAxes: [
                YAxisConfig(
                  id: 'revenue-axis',
                  position: YAxisPosition.left,
                  label: 'Revenue',
                  unit: '\$K',
                  color: const Color(0xFF1E88E5), // Matches series!
                ),
                YAxisConfig(
                  id: 'users-axis',
                  position: YAxisPosition.right,
                  label: 'Users',
                  color: const Color(0xFFD81B60), // Matches series!
                ),
                YAxisConfig(
                  id: 'sessions-axis',
                  position: YAxisPosition.rightOuter,
                  label: 'Sessions',
                  color: const Color(0xFF43A047), // Matches series!
                ),
              ],
              axisBindings: const [
                SeriesAxisBinding(seriesId: 'revenue', yAxisId: 'revenue-axis'),
                SeriesAxisBinding(seriesId: 'users', yAxisId: 'users-axis'),
                SeriesAxisBinding(seriesId: 'sessions', yAxisId: 'sessions-axis'),
              ],
              normalizationMode: NormalizationMode.perSeries,
            ),
          ),
          const SizedBox(height: 16),
          _buildCodeSnippet('''
YAxisConfig(
  id: 'revenue-axis',
  position: YAxisPosition.left,
  label: 'Revenue',
  color: Color(0xFF1E88E5),  // Same color as series!
)'''),
        ],
      ),
    );
  }

  // ============================================================
  // US4: Crosshair with Original Values
  // ============================================================

  /// Demonstrates that tooltips and crosshair display original
  /// (non-normalized) values.
  Widget _buildCrosshairDemo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDemoHeader(
            'US4: Crosshair & Tooltips with Original Values',
            'Hover over the chart to see crosshair.\n'
                'Tooltips display original values (250 W, 145 bpm) not normalized 0-1 values.',
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BravenChartPlus(
              chartType: ChartType.line,
              series: [
                LineChartSeries(
                  id: 'power',
                  name: 'Power',
                  points: _generatePowerData(),
                  color: Colors.blue,
                  yAxisId: 'power-axis',
                  unit: 'W',
                ),
                LineChartSeries(
                  id: 'hr',
                  name: 'Heart Rate',
                  points: _generateHRData(),
                  color: Colors.red,
                  yAxisId: 'hr-axis',
                  unit: 'bpm',
                ),
              ],
              yAxes: [
                YAxisConfig(
                  id: 'power-axis',
                  position: YAxisPosition.left,
                  label: 'Power',
                  unit: 'W',
                  color: Colors.blue,
                ),
                YAxisConfig(
                  id: 'hr-axis',
                  position: YAxisPosition.right,
                  label: 'Heart Rate',
                  unit: 'bpm',
                  color: Colors.red,
                ),
              ],
              axisBindings: const [
                SeriesAxisBinding(seriesId: 'power', yAxisId: 'power-axis'),
                SeriesAxisBinding(seriesId: 'hr', yAxisId: 'hr-axis'),
              ],
              normalizationMode: NormalizationMode.perSeries,
              // Crosshair and tooltip enabled by default via interactionConfig
              interactionConfig: const InteractionConfig(
                crosshair: CrosshairConfig(enabled: true),
                tooltip: TooltipConfig(
                  enabled: true,
                  showDelay: Duration.zero,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoBox(
            Icons.mouse,
            'Try It!',
            'Move your mouse over the chart to see the crosshair.\n'
                'The tooltip shows the actual data values, not normalized values.',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Helper Widgets
  // ============================================================

  Widget _buildDemoHeader(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildCodeSnippet(String code) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text(
          code,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBox(IconData icon, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withAlpha(77)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Data Generators
  // ============================================================

  /// Power data: 100-300W range with wave pattern
  List<ChartDataPoint> _generatePowerData() {
    return List.generate(60, (i) {
      final wave = math.sin(i / 10 * math.pi);
      return ChartDataPoint(
        x: i.toDouble(),
        y: 200 + 100 * wave,
      );
    });
  }

  /// Heart rate data: 80-180bpm range with different phase
  List<ChartDataPoint> _generateHRData() {
    return List.generate(60, (i) {
      final wave = math.sin((i + 5) / 8 * math.pi);
      return ChartDataPoint(
        x: i.toDouble(),
        y: 130 + 50 * wave,
      );
    });
  }

  /// Temperature data: 20-80°C range
  List<ChartDataPoint> _generateTemperatureData() {
    return List.generate(40, (i) {
      return ChartDataPoint(
        x: i.toDouble(),
        y: 30 + 40 * (i / 40),
      );
    });
  }

  /// Pressure data: 1000-9000 Pa range (~100x different from temperature)
  List<ChartDataPoint> _generatePressureData() {
    return List.generate(40, (i) {
      final wave = math.sin(i / 6 * math.pi);
      return ChartDataPoint(
        x: i.toDouble(),
        y: 5000 + 3000 * wave,
      );
    });
  }

  /// Revenue data: 50-200K range
  List<ChartDataPoint> _generateRevenueData() {
    return List.generate(30, (i) {
      return ChartDataPoint(
        x: i.toDouble(),
        y: 80 + 100 * (i / 30) + (i.hashCode % 20),
      );
    });
  }

  /// Users data: 1000-5000 range
  List<ChartDataPoint> _generateUsersData() {
    return List.generate(30, (i) {
      final trend = 2000 + 2500 * (i / 30);
      final noise = (i.hashCode % 300).toDouble();
      return ChartDataPoint(
        x: i.toDouble(),
        y: trend + noise,
      );
    });
  }

  /// Sessions data: 5000-20000 range
  List<ChartDataPoint> _generateSessionsData() {
    return List.generate(30, (i) {
      final base = 8000 + 10000 * (i / 30);
      final wave = math.sin(i / 4 * math.pi) * 2000;
      return ChartDataPoint(
        x: i.toDouble(),
        y: base + wave,
      );
    });
  }
}
