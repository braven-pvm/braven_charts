// Copyright (c) 2025 braven_charts. All rights reserved.
// BravenChartPlus Feature Showcase - What's ACTUALLY Implemented

import 'dart:async';
import 'dart:math' as math;

import 'package:braven_charts/src_plus/axis/axis_config.dart';
import 'package:braven_charts/src_plus/controllers/annotation_controller.dart';
import 'package:braven_charts/src_plus/controllers/chart_controller.dart';
import 'package:braven_charts/src_plus/models/annotation_style.dart';
import 'package:braven_charts/src_plus/models/chart_annotation.dart';
import 'package:braven_charts/src_plus/models/chart_data_point.dart';
import 'package:braven_charts/src_plus/models/chart_series.dart';
import 'package:braven_charts/src_plus/models/chart_theme.dart';
import 'package:braven_charts/src_plus/models/chart_type.dart';
import 'package:braven_charts/src_plus/models/enums.dart';
import 'package:braven_charts/src_plus/models/interaction_config.dart' as chart show TooltipTriggerMode, TooltipPosition;
import 'package:braven_charts/src_plus/models/interaction_config.dart' hide TooltipTriggerMode;
import 'package:braven_charts/src_plus/models/streaming_config.dart';
import 'package:braven_charts/src_plus/streaming/streaming_controller.dart';
import 'package:braven_charts/src_plus/theming/components/scrollbar_config.dart';
import 'package:braven_charts/src_plus/widgets/braven_chart_plus.dart';
import 'package:braven_charts/src_plus/widgets/chart_legend.dart';
import 'package:flutter/material.dart';

/// Feature Showcase for BravenChartPlus (lib/src_plus/)
///
/// This example demonstrates ALL actually implemented features.
/// See docs/refactor/SPRINT_TASKS.md for features still in development.
///
/// ✅ IMPLEMENTED FEATURES:
/// - Sealed class series architecture (LineChartSeries, BarChartSeries, ScatterChartSeries, AreaChartSeries)
/// - 5 line interpolation types (linear, bezier, stepped, monotone, cardinal)
/// - Runtime theme switching (light/dark)
/// - Pan and zoom with constraints (10% max whitespace, 1x-10x zoom)
/// - Dynamic axes with just-in-time tick generation
/// - QuadTree spatial indexing (O(log n) hit testing)
/// - Multiple chart types (Line, Bar, Scatter, Area)
/// - Data point markers with configurable sizes
/// - Tooltips (100% feature parity: trigger modes, positioning, styling, animations, arrow pointers)
/// - Performance optimizations (Picture caching, hit test throttling)
/// - Focus management for keyboard interaction
/// - Legend widget (show/hide series with click interaction)
/// - Annotations (ALL 5 types: Point, Range, Text, Threshold, Trend)
/// - Real-time streaming data with pause/resume and auto-scroll
/// - Scrollbars (dual-purpose: pan via center, zoom via edges)
///
/// ❌ NOT YET IMPLEMENTED:
/// - Advanced markers (shapes beyond circles)
/// - Context menus
/// - Export functionality
void main() {
  runApp(const BravenChartPlusFeatureShowcaseApp());
}

class BravenChartPlusFeatureShowcaseApp extends StatelessWidget {
  const BravenChartPlusFeatureShowcaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BravenChartPlus - Feature Showcase',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const FeatureShowcasePage(),
    );
  }
}

class FeatureShowcasePage extends StatefulWidget {
  const FeatureShowcasePage({super.key});

  @override
  State<FeatureShowcasePage> createState() => _FeatureShowcasePageState();
}

class _FeatureShowcasePageState extends State<FeatureShowcasePage> {
  ChartTheme _selectedTheme = ChartTheme.light;
  bool _showDebugInfo = false;

  // Tooltips disabled for testing datapoint marker hover highlighting
  static const _interactionConfig = InteractionConfig(tooltip: TooltipConfig(enabled: false), showFocusBorder: false);

  // Legend example state
  final Set<String> _hiddenSeriesIds = {};
  late final List<ChartSeries> _legendExampleSeries;

  // Annotation example state
  late final List<ChartSeries> _annotationExampleSeries;
  late final AnnotationController _annotationController; // For main demo chart
  late final AnnotationController _pointAnnotationController;
  late final AnnotationController _rangeAnnotationController;
  late final AnnotationController _textAnnotationController;
  late final AnnotationController _thresholdAnnotationController;
  late final AnnotationController _trendAnnotationController;

  // Streaming Test 1: dataStream approach
  final StreamController<ChartDataPoint> _stream1Controller = StreamController<ChartDataPoint>.broadcast();
  final StreamingController _streaming1Controller = StreamingController();
  late final ChartController _chart1Controller;
  Timer? _streaming1Timer;
  int _streaming1DataCounter = 0;
  int _buffer1Count = 0;
  int _streaming1Rate = 10; // Hz
  String _data1Pattern = 'sine'; // 'sine', 'linear', 'random'
  bool _autoScroll1 = true;
  int _total1DataPoints = 0;

  // Streaming Test 2: ChartController direct approach
  final StreamingController _streaming2Controller = StreamingController();
  late final ChartController _chart2Controller;
  Timer? _streaming2Timer;
  int _streaming2DataCounter = 0;
  int _streaming2Rate = 10; // Hz
  String _data2Pattern = 'sine'; // 'sine', 'linear', 'random'
  bool _autoScroll2 = true;
  int _total2DataPoints = 0;

  // Tooltip showcase state
  final bool _tooltipEnabled = true;
  final chart.TooltipTriggerMode _tooltipTriggerMode = chart.TooltipTriggerMode.hover;
  final chart.TooltipPosition _tooltipPosition = chart.TooltipPosition.auto;
  final bool _tooltipFollowCursor = false;
  final double _tooltipShowDelay = 100.0; // milliseconds
  final double _tooltipHideDelay = 200.0; // milliseconds
  final double _tooltipOffsetFromPoint = 8.0;
  final Color _tooltipBackgroundColor = const Color(0xE6FFFFFF);
  final Color _tooltipBorderColor = const Color(0xFF999999);
  final double _tooltipBorderWidth = 1.0;
  final double _tooltipBorderRadius = 4.0;
  final Color _tooltipShadowColor = const Color(0x66000000);
  final double _tooltipShadowBlurRadius = 4.0;
  final double _tooltipPadding = 8.0;
  final Color _tooltipTextColor = const Color(0xFF333333);
  final double _tooltipFontSize = 12.0;

  @override
  void initState() {
    super.initState();
    _chart1Controller = ChartController(); // Initialize controller for test 1
    _chart2Controller = ChartController(); // Initialize controller for test 2

    // Initialize Legend example series
    _legendExampleSeries = [
      LineChartSeries(
        id: 'legend_line',
        name: 'Line Chart',
        interpolation: LineInterpolation.bezier,
        tension: 0.4,
        strokeWidth: 2.5,
        showDataPointMarkers: true,
        dataPointMarkerRadius: 4.0,
        color: Colors.blue,
        points: List.generate(15, (i) {
          final x = i / 2.0;
          final y = 50 + 25 * math.sin(x * 0.8);
          return ChartDataPoint(x: x, y: y);
        }),
        isXOrdered: true,
      ),
      BarChartSeries(
        id: 'legend_bar',
        name: 'Bar Chart',
        barWidthPercent: 0.6,
        color: Colors.orange,
        points: List.generate(10, (i) {
          final x = i / 2.0;
          final y = 40 + 20 * math.sin(i * 0.5);
          return ChartDataPoint(x: x, y: y);
        }),
        isXOrdered: true,
      ),
      ScatterChartSeries(
        id: 'legend_scatter',
        name: 'Scatter Plot',
        markerRadius: 6.0,
        color: Colors.green,
        points: List.generate(12, (i) {
          final x = i / 2.0;
          final y = 60 + 15 * math.cos(i * 0.6);
          return ChartDataPoint(x: x, y: y);
        }),
        isXOrdered: true,
      ),
      AreaChartSeries(
        id: 'legend_area',
        name: 'Area Chart',
        interpolation: LineInterpolation.bezier,
        tension: 0.5,
        strokeWidth: 2.0,
        fillOpacity: 0.3,
        color: Colors.purple,
        points: List.generate(15, (i) {
          final x = i / 2.0;
          final y = 30 + 20 * math.sin(x * 0.7 + 1.5);
          return ChartDataPoint(x: x, y: y);
        }),
        isXOrdered: true,
      ),
    ];

    // Initialize Annotation example series and annotations
    _annotationExampleSeries = [
      LineChartSeries(
        id: 'annotation_line',
        name: 'Temperature',
        interpolation: LineInterpolation.bezier,
        tension: 0.4,
        strokeWidth: 2.5,
        showDataPointMarkers: true,
        dataPointMarkerRadius: 4.0,
        color: Colors.blue,
        points: List.generate(12, (i) {
          final x = i.toDouble();
          final y = 60 + 15 * math.sin(i * 0.5) + (i > 6 ? (i - 6) * 3 : 0);
          return ChartDataPoint(x: x, y: y);
        }),
        isXOrdered: true,
      ),
    ];

    // Initialize AnnotationController with annotations (enables editing)
    _annotationController = AnnotationController(initialAnnotations: [
      // Point annotation marking the peak value
      PointAnnotation(
          id: 'peak',
          seriesId: 'annotation_line',
          dataPointIndex: 5,
          allowDragging: true, // Enable drag-to-move to different data point
          markerShape: MarkerShape.circle,
          markerSize: 14.0,
          markerColor: Colors.red.withAlpha(120),
          label: 'Peak',
          style: AnnotationStyle(
            borderColor: Colors.red.shade700,
            borderWidth: 0.5,
            backgroundColor: Colors.red.withAlpha(80),
            borderRadius: BorderRadius.circular(5),
            padding: const EdgeInsets.all(4),
          )),
      // Range annotation highlighting weekend period
      RangeAnnotation(
          id: 'weekend',
          startX: 5.0,
          endX: 7.0,
          snapToValue: true,
          snapTolerance: 0.05,
          fillColor: Colors.orange.withAlpha(50),
          borderColor: Colors.orange.withAlpha(150),
          label: 'Weekend',
          labelPosition: AnnotationLabelPosition.topRight,
          labelMargin: 15,
          style: AnnotationStyle(
            borderColor: Colors.orange.shade700,
            borderWidth: 0.5,
            backgroundColor: Colors.orange.withAlpha(80),
            borderRadius: BorderRadius.circular(5),
            padding: const EdgeInsets.all(5),
          )),
      // Text annotation for important note
      TextAnnotation(
          id: 'note',
          text: 'Trend Increasing',
          position: const Offset(320, 30),
          anchor: AnnotationAnchor.topRight,
          allowDragging: true, // Enable click-and-hold drag to reposition
          backgroundColor: Colors.green.withAlpha(50),
          borderColor: Colors.green,
          style: AnnotationStyle(
            borderRadius: BorderRadius.circular(5),
            borderWidth: 0.5,
            padding: const EdgeInsets.all(8),
          )),
      // Threshold annotation - horizontal target line
      // Threshold annotation - horizontal target line
      ThresholdAnnotation(
          id: 'target_line',
          axis: AnnotationAxis.y,
          value: 70.0,
          allowDragging: true, // Enable click-and-hold drag to move threshold
          lineColor: Colors.green,
          lineWidth: 2.0,
          dashPattern: const [8, 4],
          label: 'Target: 70°',
          labelPosition: AnnotationLabelPosition.topLeft,
          style: AnnotationStyle(
            borderColor: Colors.green.shade700,
            borderWidth: 0.5,
            backgroundColor: Colors.green.withAlpha(80),
            borderRadius: BorderRadius.circular(5),
            padding: const EdgeInsets.all(3),
          )),
      // Threshold annotation - horizontal minimum line
      ThresholdAnnotation(
        id: 'minimum_line',
        axis: AnnotationAxis.y,
        value: 55.0,
        allowDragging: true, // Enable click-and-hold drag to move threshold
        lineColor: Colors.red.withAlpha(50),
        lineWidth: 2.0,
        dashPattern: const [5, 3],
        label: 'Min: 55°',
        labelPosition: AnnotationLabelPosition.bottomRight,
      ),
      // Threshold annotation - vertical marker line
      ThresholdAnnotation(
        id: 'marker_line',
        axis: AnnotationAxis.x,
        value: 8.0,
        allowDragging: true, // Enable click-and-hold drag to move threshold
        lineColor: Colors.blue.withAlpha(150),
        lineWidth: 2.0,
        dashPattern: const [6, 3],
        label: 'Event',
        labelPosition: AnnotationLabelPosition.topRight,
        style: AnnotationStyle(
          borderColor: Colors.blue.shade700,
          borderWidth: 0.5,
          backgroundColor: Colors.blue.withAlpha(80),
          borderRadius: BorderRadius.circular(5),
          padding: const EdgeInsets.all(3),
        ),
      ),
      // Trend annotation - linear trend line
      TrendAnnotation(
          id: 'linear_trend',
          seriesId: 'annotation_line',
          trendType: TrendType.linear,
          lineColor: Colors.purple.withAlpha(200),
          lineWidth: 2.5,
          dashPattern: const [10, 5],
          label: 'Linear Trend',
          style: AnnotationStyle(
            borderColor: Colors.purple.shade700,
            borderWidth: 0.5,
            backgroundColor: Colors.purple.withAlpha(80),
            borderRadius: BorderRadius.circular(5),
            padding: const EdgeInsets.all(8),
          )),
      // Trend annotation - moving average
      TrendAnnotation(
          id: 'moving_avg',
          seriesId: 'annotation_line',
          trendType: TrendType.movingAverage,
          windowSize: 3,
          lineColor: Colors.teal.withAlpha(200),
          lineWidth: 2.0,
          label: '3-pt MA',
          style: AnnotationStyle(
            borderColor: Colors.teal.shade700,
            borderWidth: 0.5,
            backgroundColor: Colors.teal.withAlpha(80),
            borderRadius: BorderRadius.circular(2),
            padding: const EdgeInsets.all(2),
          )),
    ]); // REMOVED: Global listener that rebuilds entire page on pause/resume

    // Initialize separate controllers for each annotation type showcase
    // This prevents ALL showcases from rebuilding when ONE annotation is added
    _pointAnnotationController = AnnotationController(initialAnnotations: [
      PointAnnotation(
          id: 'peak',
          seriesId: 'annotation_line',
          dataPointIndex: 5,
          allowDragging: true,
          markerShape: MarkerShape.circle,
          markerSize: 14.0,
          markerColor: Colors.red.withAlpha(120),
          label: 'Peak',
          style: AnnotationStyle(
            borderColor: Colors.red.shade700,
            borderWidth: 0.5,
            backgroundColor: Colors.red.withAlpha(80),
            borderRadius: BorderRadius.circular(5),
            padding: const EdgeInsets.all(4),
          )),
    ]);

    _rangeAnnotationController = AnnotationController(initialAnnotations: [
      RangeAnnotation(
          id: 'weekend',
          startX: 5.0,
          endX: 7.0,
          snapToValue: true,
          snapTolerance: 0.05,
          fillColor: Colors.orange.withAlpha(50),
          borderColor: Colors.orange.withAlpha(150),
          label: 'Weekend',
          labelPosition: AnnotationLabelPosition.topRight,
          labelMargin: 15,
          style: AnnotationStyle(
            borderColor: Colors.orange.shade700,
            borderWidth: 0.5,
            backgroundColor: Colors.orange.withAlpha(80),
            borderRadius: BorderRadius.circular(5),
            padding: const EdgeInsets.all(5),
          )),
    ]);

    _textAnnotationController = AnnotationController(initialAnnotations: [
      TextAnnotation(
          id: 'note',
          text: 'Trend Increasing',
          position: const Offset(320, 30),
          anchor: AnnotationAnchor.topRight,
          allowDragging: true,
          backgroundColor: Colors.green.withAlpha(50),
          borderColor: Colors.green,
          style: AnnotationStyle(
            borderRadius: BorderRadius.circular(5),
            borderWidth: 0.5,
            padding: const EdgeInsets.all(8),
          )),
    ]);

    _thresholdAnnotationController = AnnotationController(initialAnnotations: [
      ThresholdAnnotation(
          id: 'target_line',
          axis: AnnotationAxis.y,
          value: 70.0,
          allowDragging: true,
          lineColor: Colors.green,
          lineWidth: 2.0,
          dashPattern: const [8, 4],
          label: 'Target: 70°',
          labelPosition: AnnotationLabelPosition.topLeft,
          style: AnnotationStyle(
            borderColor: Colors.green.shade700,
            borderWidth: 0.5,
            backgroundColor: Colors.green.withAlpha(80),
            borderRadius: BorderRadius.circular(5),
            padding: const EdgeInsets.all(3),
          )),
      ThresholdAnnotation(
        id: 'minimum_line',
        axis: AnnotationAxis.y,
        value: 55.0,
        allowDragging: true,
        lineColor: Colors.red.withAlpha(50),
        lineWidth: 2.0,
        dashPattern: const [5, 3],
        label: 'Min: 55°',
        labelPosition: AnnotationLabelPosition.bottomRight,
      ),
      ThresholdAnnotation(
        id: 'marker_line',
        axis: AnnotationAxis.x,
        value: 8.0,
        allowDragging: true,
        lineColor: Colors.blue.withAlpha(150),
        lineWidth: 2.0,
        dashPattern: const [6, 3],
        label: 'Event',
        labelPosition: AnnotationLabelPosition.topRight,
        style: AnnotationStyle(
          borderColor: Colors.blue.shade700,
          borderWidth: 0.5,
          backgroundColor: Colors.blue.withAlpha(80),
          borderRadius: BorderRadius.circular(5),
          padding: const EdgeInsets.all(3),
        ),
      ),
    ]);

    _trendAnnotationController = AnnotationController(initialAnnotations: [
      TrendAnnotation(
          id: 'linear_trend',
          seriesId: 'annotation_line',
          trendType: TrendType.linear,
          lineColor: Colors.purple.withAlpha(200),
          lineWidth: 2.5,
          dashPattern: const [10, 5],
          label: 'Linear Trend',
          style: AnnotationStyle(
            borderColor: Colors.purple.shade700,
            borderWidth: 0.5,
            backgroundColor: Colors.purple.withAlpha(80),
            borderRadius: BorderRadius.circular(5),
            padding: const EdgeInsets.all(8),
          )),
      TrendAnnotation(
          id: 'moving_avg',
          seriesId: 'annotation_line',
          trendType: TrendType.movingAverage,
          windowSize: 3,
          lineColor: Colors.teal.withAlpha(200),
          lineWidth: 2.0,
          label: '3-pt MA',
          style: AnnotationStyle(
            borderColor: Colors.teal.shade700,
            borderWidth: 0.5,
            backgroundColor: Colors.teal.withAlpha(80),
            borderRadius: BorderRadius.circular(2),
            padding: const EdgeInsets.all(2),
          )),
    ]);
    // Buttons now use ListenableBuilder to rebuild only themselves
  }

  // Chart 1 (dataStream) streaming methods
  void _startStreaming1() {
    _streaming1Timer?.cancel();
    // Also resume the chart to enable auto-scroll
    _streaming1Controller.resumeStreaming();
    _streaming1Timer = Timer.periodic(Duration(milliseconds: 1000 ~/ _streaming1Rate), (_) {
      _streaming1DataCounter++;
      _total1DataPoints++;

      final ChartDataPoint point;
      switch (_data1Pattern) {
        case 'sine':
          final x = _streaming1DataCounter * 0.01;
          final y = 0.5 + 0.4 * math.sin(x * 8.0);
          point = ChartDataPoint(x: x, y: y);
          break;
        case 'linear':
          final x = _streaming1DataCounter * 0.01;
          final y = 0.3 + (x * 0.3) % 0.6;
          point = ChartDataPoint(x: x, y: y);
          break;
        case 'random':
          final x = _streaming1DataCounter * 0.01;
          final y = 0.2 + math.Random().nextDouble() * 0.6;
          point = ChartDataPoint(x: x, y: y);
          break;
        default:
          final x = _streaming1DataCounter * 0.01;
          final y = 0.5;
          point = ChartDataPoint(x: x, y: y);
      }

      _stream1Controller.add(point);
      // Removed excessive print - was flooding console 10-50 times per second
    });
  }

  void _stopStreaming1() {
    _streaming1Timer?.cancel();
    _streaming1Timer = null;
    // Also pause the chart to freeze viewport
    _streaming1Controller.pauseStreaming();
  }

  void _resetStreaming1() {
    _stopStreaming1();
    _streaming1Controller.pauseStreaming();
    _streaming1Controller.clearStreamingData();
    _streaming1DataCounter = 0;
    _total1DataPoints = 0;
    setState(() {});
  }

  void _changeStreaming1Rate(int newRate) {
    setState(() {
      _streaming1Rate = newRate;
    });
    if (_streaming1Timer != null && _streaming1Timer!.isActive) {
      _startStreaming1();
    }
  }

  void _changeData1Pattern(String pattern) {
    setState(() {
      _data1Pattern = pattern;
      _streaming1DataCounter = 0;
    });
  }

  void _toggleAutoScroll1() {
    setState(() {
      _autoScroll1 = !_autoScroll1;
    });
  }

  void _toggleAutoScroll2() {
    setState(() {
      _autoScroll2 = !_autoScroll2;
    });
  }

  void _togglePauseResume1() {
    // CRITICAL: Read the state ONCE at method entry to avoid race conditions
    final isCurrentlyStreaming = _streaming1Controller.isStreaming;
    print('🔘🔘🔘 BUTTON CLICKED: isStreaming=$isCurrentlyStreaming');

    if (isCurrentlyStreaming) {
      print('🔘 Branch: Calling pauseStreaming()');
      _streaming1Controller.pauseStreaming();
      print('🔘 pauseStreaming() returned');
    } else {
      print('🔘 Branch: Calling resumeStreaming()');
      _streaming1Controller.resumeStreaming();
      print('🔘 resumeStreaming() returned');
    }
    print('🔘 Method complete');
  }

  // Chart 2 (ChartController) streaming methods
  void _startStreaming2() {
    _streaming2Timer?.cancel();
    _streaming2Timer = Timer.periodic(Duration(milliseconds: 1000 ~/ _streaming2Rate), (_) {
      _streaming2DataCounter++;
      _total2DataPoints++;

      final ChartDataPoint point;
      switch (_data2Pattern) {
        case 'sine':
          final x = _streaming2DataCounter * 0.01;
          final y = 0.5 + 0.4 * math.sin(x * 8.0);
          point = ChartDataPoint(x: x, y: y);
          break;
        case 'linear':
          final x = _streaming2DataCounter * 0.01;
          final y = 0.3 + (x * 0.3) % 0.6;
          point = ChartDataPoint(x: x, y: y);
          break;
        case 'random':
          final x = _streaming2DataCounter * 0.01;
          final y = 0.2 + math.Random().nextDouble() * 0.6;
          point = ChartDataPoint(x: x, y: y);
          break;
        default:
          final x = _streaming2DataCounter * 0.01;
          final y = 0.5;
          point = ChartDataPoint(x: x, y: y);
      }

      // Add directly to controller
      _chart2Controller.addPoint('controller_data', ChartDataPoint(x: point.x, y: point.y));
      // Removed excessive print - was flooding console 10-50 times per second
    });
    setState(() {}); // Rebuild UI to reflect timer state
  }

  void _stopStreaming2() {
    _streaming2Timer?.cancel();
    _streaming2Timer = null;
    setState(() {}); // Rebuild UI to reflect timer state
  }

  void _resetStreaming2() {
    _stopStreaming2();
    _chart2Controller.clearSeries('controller_data');
    _streaming2DataCounter = 0;
    _total2DataPoints = 0;
    setState(() {});
  }

  void _changeStreaming2Rate(int newRate) {
    setState(() {
      _streaming2Rate = newRate;
    });
    if (_streaming2Timer != null && _streaming2Timer!.isActive) {
      _startStreaming2();
    }
  }

  void _changeData2Pattern(String pattern) {
    setState(() {
      _data2Pattern = pattern;
      _streaming2DataCounter = 0;
    });
  }

  Widget _buildStatusChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _streaming1Timer?.cancel();
    _streaming2Timer?.cancel();
    _stream1Controller.close();
    _streaming1Controller.dispose();
    _chart1Controller.dispose();
    _chart2Controller.dispose();
    _annotationController.dispose();
    _pointAnnotationController.dispose();
    _rangeAnnotationController.dispose();
    _textAnnotationController.dispose();
    _thresholdAnnotationController.dispose();
    _trendAnnotationController.dispose();
    super.dispose();
  }

  // Generate sample data for demonstrations
  List<ChartDataPoint> _generateSineWave({
    required int pointCount,
    required double amplitude,
    required double frequency,
    required double phase,
  }) {
    return List.generate(pointCount, (i) {
      final x = i * 10.0 / pointCount;
      final y = amplitude * math.sin(frequency * x + phase) + 50;
      return ChartDataPoint(x: x, y: y);
    });
  }

  Widget _buildFeatureCard({
    required String title,
    required String description,
    required Widget child,
    required List<String> features,
    double height = 550,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  if (features.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: features.map((feature) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Text(
                            feature,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green.shade900,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            // Chart
            SizedBox(
              height: height,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('BravenChartPlus - Feature Showcase'),
          actions: [
            // Theme switcher
            DropdownButton<ChartTheme>(
              value: _selectedTheme,
              items: const [
                DropdownMenuItem(
                  value: ChartTheme.light,
                  child: Text('Light'),
                ),
                DropdownMenuItem(
                  value: ChartTheme.dark,
                  child: Text('Dark'),
                ),
              ],
              onChanged: (theme) {
                if (theme != null) {
                  setState(() {
                    _selectedTheme = theme;
                  });
                }
              },
            ),
            const SizedBox(width: 8),
            // Debug toggle
            IconButton(
              icon: Icon(_showDebugInfo ? Icons.bug_report : Icons.bug_report_outlined),
              onPressed: () {
                setState(() {
                  _showDebugInfo = !_showDebugInfo;
                });
              },
              tooltip: 'Toggle Debug Overlay',
            ),
          ],
          bottom: const TabBar(
            isScrollable: false,
            physics: NeverScrollableScrollPhysics(),
            tabs: [
              Tab(icon: Icon(Icons.dashboard), text: 'Features'),
              Tab(icon: Icon(Icons.label), text: 'Annotations'),
              Tab(icon: Icon(Icons.info_outline), text: 'Tooltips'),
              Tab(icon: Icon(Icons.stream), text: 'Streaming'),
            ],
          ),
        ),
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // Tab 1: Feature showcase
            _buildFeaturesTab(),
            // Tab 2: Annotations showcase
            _buildAnnotationsTab(),
            // Tab 3: Tooltips showcase
            _buildTooltipsTab(),
            // Tab 4: Streaming tests
            _buildStreamingTestsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),

          // Info banner
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade900),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '✅ Feature Showcase - What\'s Actually Working',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'This example demonstrates ONLY implemented features in lib/src_plus/.\n'
                        'See docs/refactor/SPRINT_TASKS.md for features in development.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Controls banner
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.keyboard, color: Colors.amber.shade900),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Pan: Arrow keys or middle mouse • Zoom: +/- keys or Shift+Wheel • Reset: R or Home',
                    style: TextStyle(fontSize: 13, color: Colors.amber.shade900),
                  ),
                ),
              ],
            ),
          ),

          // Feature 1: Line Interpolation Types
          _buildFeatureCard(
            title: '1. Line Interpolation Types',
            description: 'All 5 interpolation methods: linear, bezier (configurable tension), stepped, monotone, and cardinal',
            features: const [
              'Linear',
              'Bezier (tension)',
              'Stepped',
              'Monotone',
              'Cardinal',
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 0),
              child: BravenChartPlus(
                key: const ValueKey('chart_interpolation'),
                chartType: ChartType.line,
                showXScrollbar: true,

                showYScrollbar: true,
                // EXTREME SCROLLBAR THEME TEST - Verify all visual properties render
                scrollbarTheme: ScrollbarConfig(
                  // Sizing properties
                  thickness: 18.0, // 20px thick (vs default 11.5)
                  minHandleSize: 80.0, // 80px minimum HANDLE LENGTH (vs default 23) - prevents tiny handle when zoomed out
                  padding: 5.0, // No padding for max visibility
                  borderRadius: 6.0, // 10px radius (vs default 4)
                  edgeGripWidth: 40.0, // 40px edge zone WIDTH (default) - each end of handle for zoom

                  // Track colors (bright yellow background with GREEN hover for testing)
                  trackColor: Colors.grey.shade300.withAlpha(75),
                  trackHoverColor: Colors.grey.shade400.withAlpha(85),

                  // Handle colors (cyan/teal)R
                  handleColor: Colors.grey.shade300.withAlpha(100),
                  handleHoverColor: Colors.grey.shade400.withAlpha(120),
                  handleActiveColor: Colors.grey.shade400.withAlpha(200), // Dark cyan active
                  handleDisabledColor: const Color(0xFFB2EBF2), // Light cyan disabled

                  // Edge zone colors (magenta/pink - dramatic contrast)
                  edgeZoneColor: Colors.blue.shade300.withAlpha(100),
                  edgeHoverColor: Colors.blue.shade400.withAlpha(125),

                  // Grip indicator (white for contrast)
                  showGripIndicator: true,
                  gripIndicatorColor: Colors.black38,

                  // Behavior (note: some not implemented in chart_render_box yet)
                  autoHide: true, // Always visible for testing
                  autoHideDelay: const Duration(seconds: 2),
                  enableResizeHandles: true, // Edge zones enabled
                ),
                series: [
                  LineChartSeries(
                    id: 'linear',
                    name: 'Linear',
                    interpolation: LineInterpolation.linear,
                    strokeWidth: 2.5,
                    showDataPointMarkers: true,
                    dataPointMarkerRadius: 4.0,
                    points: _generateSineWave(
                      pointCount: 10,
                      amplitude: 20,
                      frequency: 0.8,
                      phase: 0,
                    ),
                    isXOrdered: true,
                  ),
                  LineChartSeries(
                    id: 'bezier',
                    name: 'Bezier (0.5)',
                    interpolation: LineInterpolation.bezier,
                    tension: 0.5,
                    strokeWidth: 2.5,
                    showDataPointMarkers: true,
                    dataPointMarkerRadius: 3.5,
                    points: _generateSineWave(
                      pointCount: 10,
                      amplitude: 20,
                      frequency: 0.8,
                      phase: 0.5,
                    ),
                    isXOrdered: true,
                  ),
                  LineChartSeries(
                    id: 'monotone',
                    name: 'Monotone',
                    interpolation: LineInterpolation.monotone,
                    strokeWidth: 2.5,
                    showDataPointMarkers: false,
                    points: _generateSineWave(
                      pointCount: 10,
                      amplitude: 20,
                      frequency: 0.8,
                      phase: 1.0,
                    ),
                    isXOrdered: true,
                  ),
                ],
                theme: _selectedTheme,
                backgroundColor: _selectedTheme == ChartTheme.dark ? Colors.grey.shade900 : Colors.white,
                showDebugInfo: _showDebugInfo,
                interactionConfig: _interactionConfig,
              ),
            ),
          ),

          // Feature 2: Chart Types
          _buildFeatureCard(
            title: '2. Multiple Chart Types',
            description: 'Line, Bar, Scatter, and Area charts with sealed class architecture',
            features: const [
              'LineChartSeries',
              'BarChartSeries',
              'ScatterChartSeries',
              'AreaChartSeries',
              'Type-safe sealed classes',
            ],
            child: BravenChartPlus(
              key: const ValueKey('chart_types'),
              chartType: ChartType.line,
              showXScrollbar: true,
              showYScrollbar: true,
              xAxis: const AxisConfig(
                orientation: AxisOrientation.horizontal,
                position: AxisPosition.bottom,
                label: "This is the X Label",
                axisColor: Colors.blue,
                gridColor: Colors.orange,
                tickLength: 50,
                showTickMarks: true,
                showGrid: true,
                showAxisLine: true,
              ),
              series: const [
                LineChartSeries(
                  id: 'line_1',
                  name: 'Line Series',
                  interpolation: LineInterpolation.bezier,
                  tension: 0.4,
                  strokeWidth: 2.5,
                  showDataPointMarkers: true,
                  dataPointMarkerRadius: 4.0,
                  points: [
                    ChartDataPoint(x: 0, y: 30),
                    ChartDataPoint(x: 2, y: 55),
                    ChartDataPoint(x: 4, y: 45),
                    ChartDataPoint(x: 6, y: 70),
                    ChartDataPoint(x: 8, y: 60),
                    ChartDataPoint(x: 10, y: 80),
                  ],
                  isXOrdered: true,
                ),
                BarChartSeries(
                  id: 'bar_1',
                  name: 'Bar Series',
                  barWidthPercent: 0.5,
                  points: [
                    ChartDataPoint(x: 1, y: 40),
                    ChartDataPoint(x: 3, y: 60),
                    ChartDataPoint(x: 5, y: 50),
                    ChartDataPoint(x: 7, y: 75),
                    ChartDataPoint(x: 9, y: 65),
                  ],
                  isXOrdered: true,
                ),
                AreaChartSeries(
                  id: 'area_1',
                  name: 'Area Series',
                  interpolation: LineInterpolation.bezier,
                  tension: 0.5,
                  fillOpacity: 0.2,
                  strokeWidth: 2.0,
                  points: [
                    ChartDataPoint(x: 0, y: 20),
                    ChartDataPoint(x: 2, y: 35),
                    ChartDataPoint(x: 4, y: 30),
                    ChartDataPoint(x: 6, y: 50),
                    ChartDataPoint(x: 8, y: 40),
                    ChartDataPoint(x: 10, y: 55),
                  ],
                  isXOrdered: true,
                ),
              ],
              theme: _selectedTheme,
              backgroundColor: _selectedTheme == ChartTheme.dark ? Colors.grey.shade900 : Colors.white,
              showDebugInfo: _showDebugInfo,
              interactionConfig: _interactionConfig,
            ),
          ),

          // Feature 3: Pan & Zoom Constraints
          _buildFeatureCard(
            title: '3. Pan & Zoom with Constraints',
            description: 'Constrained interaction: 10% max whitespace, 1x-10x zoom range, smooth gestures',
            features: const [
              '10% whitespace limit',
              '1x-10x zoom range',
              'Arrow key panning',
              '+/- zoom',
              'Shift+Wheel zoom',
              'R to reset',
            ],
            child: BravenChartPlus(
              key: const ValueKey('chart_constraints'),
              chartType: ChartType.line,
              showXScrollbar: true,
              showYScrollbar: true,
              series: [
                LineChartSeries(
                  id: 'data_1',
                  name: 'Large Dataset',
                  interpolation: LineInterpolation.linear,
                  strokeWidth: 2.0,
                  showDataPointMarkers: true,
                  dataPointMarkerRadius: 3.0,
                  points: List.generate(50, (i) {
                    final x = i / 5.0;
                    final y = 50 + 30 * math.sin(x * 0.5) + 10 * math.cos(x * 1.2);
                    return ChartDataPoint(x: x, y: y);
                  }),
                  isXOrdered: true,
                ),
              ],
              theme: _selectedTheme,
              backgroundColor: _selectedTheme == ChartTheme.dark ? Colors.grey.shade900 : Colors.white,
              showDebugInfo: _showDebugInfo,
              interactionConfig: _interactionConfig,
            ),
          ),

          // Feature 4: Dynamic Axes
          _buildFeatureCard(
            title: '4. Dynamic Axes with Just-In-Time Ticks',
            description: 'Axes update automatically based on viewport, with intelligent tick generation',
            features: const [
              'Auto-range calculation',
              'Just-in-time tick generation',
              'Smart tick spacing',
              'Responsive to zoom',
            ],
            child: BravenChartPlus(
              key: const ValueKey('chart_axes'),
              chartType: ChartType.line,
              showXScrollbar: true,
              showYScrollbar: true,
              series: const [
                LineChartSeries(
                  id: 'exponential',
                  name: 'Exponential Growth',
                  interpolation: LineInterpolation.bezier,
                  tension: 0.4,
                  strokeWidth: 2.5,
                  showDataPointMarkers: true,
                  dataPointMarkerRadius: 4.0,
                  points: [
                    ChartDataPoint(x: 0, y: 10),
                    ChartDataPoint(x: 1, y: 12),
                    ChartDataPoint(x: 2, y: 16),
                    ChartDataPoint(x: 3, y: 22),
                    ChartDataPoint(x: 4, y: 32),
                    ChartDataPoint(x: 5, y: 48),
                    ChartDataPoint(x: 6, y: 72),
                    ChartDataPoint(x: 7, y: 108),
                    ChartDataPoint(x: 8, y: 162),
                    ChartDataPoint(x: 9, y: 243),
                    ChartDataPoint(x: 10, y: 365),
                  ],
                  isXOrdered: true,
                ),
              ],
              theme: _selectedTheme,
              backgroundColor: _selectedTheme == ChartTheme.dark ? Colors.grey.shade900 : Colors.white,
              showDebugInfo: _showDebugInfo,
              interactionConfig: _interactionConfig,
            ),
          ),

          // Feature 5: Runtime Theme Switching
          _buildFeatureCard(
            title: '5. Runtime Theme Switching',
            description: 'Switch between light and dark themes without rebuilding chart state',
            features: const [
              'Light theme',
              'Dark theme',
              'Instant switching',
              'Preserved zoom/pan',
              'Focus management',
            ],
            child: BravenChartPlus(
              key: const ValueKey('chart_theming'),
              chartType: ChartType.line,
              showXScrollbar: true,
              showYScrollbar: true,
              series: const [
                LineChartSeries(
                  id: 'theme_demo_1',
                  name: 'Series 1',
                  interpolation: LineInterpolation.bezier,
                  tension: 0.5,
                  strokeWidth: 3.0,
                  showDataPointMarkers: true,
                  dataPointMarkerRadius: 5.0,
                  points: [
                    ChartDataPoint(x: 0, y: 45),
                    ChartDataPoint(x: 2, y: 65),
                    ChartDataPoint(x: 4, y: 55),
                    ChartDataPoint(x: 6, y: 80),
                    ChartDataPoint(x: 8, y: 70),
                    ChartDataPoint(x: 10, y: 90),
                  ],
                  isXOrdered: true,
                ),
                LineChartSeries(
                  id: 'theme_demo_2',
                  name: 'Series 2',
                  interpolation: LineInterpolation.monotone,
                  strokeWidth: 2.5,
                  showDataPointMarkers: true,
                  dataPointMarkerRadius: 4.0,
                  points: [
                    ChartDataPoint(x: 0, y: 30),
                    ChartDataPoint(x: 2, y: 50),
                    ChartDataPoint(x: 4, y: 40),
                    ChartDataPoint(x: 6, y: 65),
                    ChartDataPoint(x: 8, y: 55),
                    ChartDataPoint(x: 10, y: 75),
                  ],
                  isXOrdered: true,
                ),
              ],
              theme: _selectedTheme,
              backgroundColor: _selectedTheme == ChartTheme.dark ? Colors.grey.shade900 : Colors.white,
              showDebugInfo: _showDebugInfo,
              interactionConfig: _interactionConfig,
            ),
          ),

          // Feature 6: Performance Optimizations
          _buildFeatureCard(
            title: '6. Performance Optimizations',
            description: '60fps with 7 series, <100ms for 1000 points. Picture caching, QuadTree spatial indexing, hit test throttling.',
            features: const [
              'Picture caching (~17ms/frame)',
              'QuadTree O(log n) hit testing',
              'Hit test throttling (50ms)',
              '60fps with 7 series',
              '<100ms for 1000 points',
            ],
            child: BravenChartPlus(
              key: const ValueKey('chart_performance'),
              chartType: ChartType.line,
              showXScrollbar: true,
              showYScrollbar: true,
              series: [
                // 7 series to stress-test performance
                ...List.generate(7, (i) {
                  return LineChartSeries(
                    id: 'perf_series_$i',
                    name: 'Series ${i + 1}',
                    interpolation: LineInterpolation.bezier,
                    tension: 0.4 + (i * 0.05),
                    strokeWidth: 2.0,
                    showDataPointMarkers: i % 2 == 0,
                    dataPointMarkerRadius: 3.0,
                    points: List.generate(20, (j) {
                      final x = j / 2.0;
                      final y = 50 + 20 * math.sin(x * 0.5 + i * 0.3) + i * 5;
                      return ChartDataPoint(x: x, y: y);
                    }),
                    isXOrdered: true,
                  );
                }),
              ],
              theme: _selectedTheme,
              backgroundColor: _selectedTheme == ChartTheme.dark ? Colors.grey.shade900 : Colors.white,
              showDebugInfo: _showDebugInfo,
              interactionConfig: _interactionConfig,
            ),
          ),

          const SizedBox(height: 32),

          // Feature 7: Legend Widget (Show/Hide Series)
          _buildFeatureCard(
            title: '7. Legend Widget - Show/Hide Series',
            description: 'Interactive legend for controlling series visibility. Click legend items to show/hide series.',
            features: const [
              'Click to show/hide series',
              'Visual indicator for hidden series',
              'Supports all chart types',
              'Customizable styling',
              'Horizontal/vertical orientation',
            ],
            child: Column(
              children: [
                // Chart with visible series only
                SizedBox(
                  height: 240,
                  child: BravenChartPlus(
                    key: const ValueKey('chart_legend'),
                    chartType: ChartType.line,
                    series: _legendExampleSeries.where((s) => !_hiddenSeriesIds.contains(s.id)).toList(),
                    theme: _selectedTheme,
                    backgroundColor: _selectedTheme == ChartTheme.dark ? Colors.grey.shade900 : Colors.white,
                    showDebugInfo: _showDebugInfo,
                    interactionConfig: _interactionConfig,
                  ),
                ),
                const SizedBox(height: 16),
                // Legend widget
                ChartLegend(
                  series: _legendExampleSeries,
                  hiddenSeriesIds: _hiddenSeriesIds,
                  onSeriesToggle: (seriesId) {
                    setState(() {
                      if (_hiddenSeriesIds.contains(seriesId)) {
                        _hiddenSeriesIds.remove(seriesId);
                      } else {
                        _hiddenSeriesIds.add(seriesId);
                      }
                    });
                  },
                  orientation: Axis.horizontal,
                  spacing: 20.0,
                  runSpacing: 12.0,
                  padding: const EdgeInsets.all(16.0),
                  borderRadius: BorderRadius.circular(8),
                  showBorder: true,
                  borderColor: Colors.grey.shade300,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Feature 8: Chart Annotations
          _buildFeatureCard(
            title: '8. Chart Annotations - ALL 5 Types',
            description: 'Point, Range, Text, Threshold, and Trend annotations with interactive selection and visual feedback.',
            features: const [
              'Point annotations (custom markers)',
              'Range annotations (highlight regions)',
              'Text annotations (labels & notes)',
              'Threshold annotations (reference lines)',
              'Trend annotations (linear, MA)',
              'Selection and hover feedback',
            ],
            child: SizedBox(
              height: 280,
              child: BravenChartPlus(
                key: const ValueKey('chart_annotations'),
                chartType: ChartType.line,
                showXScrollbar: true,
                showYScrollbar: true,
                series: _annotationExampleSeries,
                annotationController: _annotationController,
                theme: _selectedTheme,
                backgroundColor: _selectedTheme == ChartTheme.dark ? Colors.grey.shade900 : Colors.white,
                showDebugInfo: _showDebugInfo,
                interactionConfig: _interactionConfig,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Feature 9: Real-Time Streaming Data
          _buildFeatureCard(
            title: '9. Real-Time Streaming Data',
            description: 'Live data ingestion with buffering, pause/resume controls, and auto-scroll viewport.',
            height: 900, // Larger height for streaming controls
            features: const [
              'Stream<ChartDataPoint> integration',
              'Configurable buffer (10,000 points default)',
              'Pause/resume streaming',
              'Auto-scroll to follow latest data',
              'Buffer count monitoring',
              'Variable data rates (1Hz-50Hz)',
            ],
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Streaming chart (uses Chart 1 state)
                Expanded(
                  child: Container(
                    child: BravenChartPlus(
                      key: const ValueKey('chart_streaming'),
                      chartType: ChartType.line,
                      controller: _chart1Controller,
                      series: const [
                        LineChartSeries(
                          id: 'streaming_data',
                          name: 'Live Data',
                          interpolation: LineInterpolation.linear,
                          strokeWidth: 2.0,
                          showDataPointMarkers: false,
                          color: Colors.blue,
                          points: [], // Start with empty data
                          isXOrdered: true,
                        ),
                      ],
                      dataStream: _stream1Controller.stream,
                      streamingConfig: StreamingConfig(
                        maxBufferSize: 500,
                        autoScroll: _autoScroll1,
                        onBufferUpdated: (count) {
                          if (mounted) {
                            setState(() {
                              _buffer1Count = count;
                            });
                          }
                        },
                      ),
                      streamingController: _streaming1Controller,
                      theme: _selectedTheme,
                      backgroundColor: _selectedTheme == ChartTheme.dark ? Colors.grey.shade900 : Colors.white,
                      showDebugInfo: _showDebugInfo,
                      interactionConfig: _interactionConfig,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Ultra-Compact Control Panel
                Container(
                  height: 150,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Row 1: Stream control buttons
                      Row(
                        children: [
                          Expanded(
                            // Wrap button in ListenableBuilder so only this button rebuilds
                            // when controller changes, not the entire page
                            child: ListenableBuilder(
                              listenable: _streaming1Controller,
                              builder: (context, child) {
                                return ElevatedButton.icon(
                                  onPressed: () {
                                    print('🔵🔵🔵 INLINE onPressed FIRED! Button widget received click event');
                                    _togglePauseResume1();
                                  },
                                  icon: Icon(_streaming1Controller.isStreaming ? Icons.pause : Icons.play_arrow, size: 14),
                                  label: Text(_streaming1Controller.isStreaming ? 'Pause' : 'Resume', style: const TextStyle(fontSize: 11)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _streaming1Controller.isStreaming ? Colors.orange : Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    minimumSize: const Size(0, 32),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _streaming1Timer != null && _streaming1Timer!.isActive ? _stopStreaming1 : _startStreaming1,
                              icon: Icon(_streaming1Timer != null && _streaming1Timer!.isActive ? Icons.stop : Icons.play_arrow, size: 14),
                              label: Text(_streaming1Timer != null && _streaming1Timer!.isActive ? 'Stop' : 'Start',
                                  style: const TextStyle(fontSize: 11)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _streaming1Timer != null && _streaming1Timer!.isActive ? Colors.red : Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                minimumSize: const Size(0, 32),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _resetStreaming1,
                              icon: const Icon(Icons.refresh, size: 14),
                              label: const Text('Reset', style: TextStyle(fontSize: 11)),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                minimumSize: const Size(0, 32),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Row 2: Dropdowns + Status
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Rate
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Rate:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 3),
                                Container(
                                  height: 32,
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: DropdownButton<int>(
                                    value: _streaming1Rate,
                                    isDense: true,
                                    isExpanded: true,
                                    underline: const SizedBox(),
                                    style: const TextStyle(fontSize: 10, color: Colors.black87),
                                    items: [1, 5, 10, 20, 50].map((rate) {
                                      return DropdownMenuItem(value: rate, child: Text('$rate Hz'));
                                    }).toList(),
                                    onChanged: (rate) => rate != null ? _changeStreaming1Rate(rate) : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Pattern
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Pattern:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 3),
                                Container(
                                  height: 32,
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: DropdownButton<String>(
                                    value: _data1Pattern,
                                    isDense: true,
                                    isExpanded: true,
                                    underline: const SizedBox(),
                                    style: const TextStyle(fontSize: 10, color: Colors.black87),
                                    items: const [
                                      DropdownMenuItem(value: 'sine', child: Text('Sine')),
                                      DropdownMenuItem(value: 'linear', child: Text('Linear')),
                                      DropdownMenuItem(value: 'random', child: Text('Random')),
                                    ],
                                    onChanged: (pattern) => pattern != null ? _changeData1Pattern(pattern) : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Auto-scroll
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Auto:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 3),
                                SizedBox(
                                  height: 32,
                                  child: ElevatedButton(
                                    onPressed: _toggleAutoScroll1,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _autoScroll1 ? Colors.green : Colors.grey,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 6),
                                    ),
                                    child: Text(_autoScroll1 ? 'ON' : 'OFF', style: const TextStyle(fontSize: 10)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Row 3: Compact status chips
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _buildStatusChip('Buf', '$_buffer1Count', Colors.orange),
                          _buildStatusChip('Pts', '$_total1DataPoints', Colors.purple),
                          _buildStatusChip('${_streaming1Rate}Hz', _streaming1Timer != null && _streaming1Timer!.isActive ? 'On' : 'Off',
                              _streaming1Timer != null && _streaming1Timer!.isActive ? Colors.green : Colors.red),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Footer with implementation status
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📊 Implementation Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '✅ COMPLETE (shown above):',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 4),
                Text(
                  '• Sealed class series architecture\n'
                  '• 5 line interpolation types\n'
                  '• Runtime theme switching\n'
                  '• Pan/zoom with constraints\n'
                  '• Dynamic axes\n'
                  '• QuadTree spatial indexing\n'
                  '• 4 chart types (Line, Bar, Scatter, Area)\n'
                  '• Data point markers\n'
                  '• Basic tooltips\n'
                  '• Performance optimizations\n'
                  '• Legend widget (show/hide series)\n'
                  '• Annotations (ALL 5 types: Point, Range, Text, Threshold, Trend)',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 16),
                const Text(
                  '⏳ IN DEVELOPMENT (not shown):',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                ),
                const SizedBox(height: 4),
                Text(
                  '• Real-time streaming data - ~9.5h\n'
                  '• Scrollbars - ~7h\n'
                  '• Advanced markers (shapes beyond circles) - ~1.5h\n'
                  '\n'
                  'See docs/refactor/SPRINT_TASKS.md for detailed roadmap.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildAnnotationsTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.label, color: Colors.purple.shade900, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chart Annotations',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'All 5 annotation types with interactive examples: Point, Range, Text, Threshold, and Trend annotations.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.purple.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Overview chart with all annotations
            _buildAnnotationCard(
              title: 'Complete Example - All Annotation Types',
              description: 'This chart demonstrates all 5 annotation types working together on a single chart.',
              icon: Icons.dashboard,
              child: BravenChartPlus(
                key: const ValueKey('annotations_overview'),
                chartType: ChartType.line,
                showXScrollbar: true,
                showYScrollbar: true,
                series: _annotationExampleSeries,
                annotationController: _annotationController,
                theme: _selectedTheme,
                backgroundColor: _selectedTheme == ChartTheme.dark ? Colors.grey.shade900 : Colors.white,
                showDebugInfo: _showDebugInfo,
                interactionConfig: _interactionConfig,
              ),
            ),

            const SizedBox(height: 24),

            // Point Annotations
            _buildAnnotationCard(
              title: '1. Point Annotations',
              description: 'Mark specific data points with custom markers (circle, star, triangle, etc.) and labels.',
              icon: Icons.place,
              features: const [
                'Multiple marker shapes (star, circle, triangle, square, diamond)',
                'Custom colors and sizes',
                'Optional labels',
                'Attached to specific data points by seriesId + index',
              ],
              child: BravenChartPlus(
                key: const ValueKey('point_annotations'),
                chartType: ChartType.line,
                showXScrollbar: true,
                showYScrollbar: true,
                series: _annotationExampleSeries,
                annotationController: _pointAnnotationController,
                theme: _selectedTheme,
                backgroundColor: _selectedTheme == ChartTheme.dark ? Colors.grey.shade900 : Colors.white,
                showDebugInfo: _showDebugInfo,
                interactionConfig: _interactionConfig,
              ),
            ),

            const SizedBox(height: 24),

            // Range Annotations
            _buildAnnotationCard(
              title: '2. Range Annotations',
              description: 'Highlight horizontal or vertical regions with colored fills and borders.',
              icon: Icons.width_full,
              features: const [
                'Vertical regions (startX to endX)',
                'Horizontal regions (startY to endY)',
                'Customizable fill color and opacity',
                'Optional borders and labels',
              ],
              child: BravenChartPlus(
                key: const ValueKey('range_annotations'),
                chartType: ChartType.line,
                showXScrollbar: true,
                showYScrollbar: true,
                series: _annotationExampleSeries,
                annotationController: _rangeAnnotationController,
                theme: _selectedTheme,
                backgroundColor: _selectedTheme == ChartTheme.dark ? Colors.grey.shade900 : Colors.white,
                showDebugInfo: _showDebugInfo,
                interactionConfig: _interactionConfig,
              ),
            ),

            const SizedBox(height: 24),

            // Text Annotations
            _buildAnnotationCard(
              title: '3. Text Annotations',
              description: 'Add freeform text labels at any position on the chart.',
              icon: Icons.text_fields,
              features: const [
                'Positioned via Offset (x, y in pixels)',
                'Multiple anchor points (topLeft, center, bottomRight, etc.)',
                'Custom text styling',
                'Optional background and border',
              ],
              child: BravenChartPlus(
                key: const ValueKey('text_annotations'),
                chartType: ChartType.line,
                showXScrollbar: true,
                showYScrollbar: true,
                series: _annotationExampleSeries,
                annotationController: _textAnnotationController,
                theme: _selectedTheme,
                backgroundColor: _selectedTheme == ChartTheme.dark ? Colors.grey.shade900 : Colors.white,
                showDebugInfo: _showDebugInfo,
                interactionConfig: _interactionConfig,
              ),
            ),

            const SizedBox(height: 24),

            // Threshold Annotations
            _buildAnnotationCard(
              title: '4. Threshold Annotations',
              description: 'Draw horizontal or vertical reference lines (e.g., targets, limits, averages).',
              icon: Icons.horizontal_rule,
              features: const [
                'Horizontal lines (Y-axis thresholds)',
                'Vertical lines (X-axis thresholds)',
                'Solid or dashed line styles',
                'Labels with flexible positioning',
              ],
              child: BravenChartPlus(
                key: const ValueKey('threshold_annotations'),
                chartType: ChartType.line,
                showXScrollbar: true,
                showYScrollbar: true,
                series: _annotationExampleSeries,
                annotationController: _thresholdAnnotationController,
                theme: _selectedTheme,
                backgroundColor: _selectedTheme == ChartTheme.dark ? Colors.grey.shade900 : Colors.white,
                showDebugInfo: _showDebugInfo,
                interactionConfig: _interactionConfig,
              ),
            ),

            const SizedBox(height: 24),

            // Trend Annotations
            _buildAnnotationCard(
              title: '5. Trend Annotations',
              description: 'Overlay trend lines calculated from series data (linear regression, moving averages).',
              icon: Icons.trending_up,
              features: const [
                'Linear trend (least squares regression)',
                'Moving average (configurable window size)',
                'Attached to specific series',
                'Customizable line style and color',
              ],
              child: BravenChartPlus(
                key: const ValueKey('trend_annotations'),
                chartType: ChartType.line,
                showXScrollbar: true,
                showYScrollbar: true,
                series: _annotationExampleSeries,
                annotationController: _trendAnnotationController,
                theme: _selectedTheme,
                backgroundColor: _selectedTheme == ChartTheme.dark ? Colors.grey.shade900 : Colors.white,
                showDebugInfo: _showDebugInfo,
                interactionConfig: _interactionConfig,
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnotationCard({
    required String title,
    required String description,
    required IconData icon,
    required Widget child,
    List<String> features = const [],
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(icon, color: Colors.purple.shade700, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
            if (features.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: features.map((feature) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.purple.shade200),
                    ),
                    child: Text(
                      feature,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.purple.shade800,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            // Chart
            SizedBox(
              height: 500,
              child: child,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamingTestsTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.stream, color: Colors.blue.shade900),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Streaming API Tests',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Compare dataStream vs ChartController streaming approaches',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Chart 1: dataStream approach
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Test 1: dataStream Property',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Uses BravenChartPlus.dataStream with Stream<ChartDataPoint>',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      height: 500,
                      child: BravenChartPlus(
                        key: const ValueKey('stream_test_datastream'),
                        chartType: ChartType.line,
                        controller: _chart1Controller,
                        showXScrollbar: true,
                        showYScrollbar: true,
                        series: const [
                          LineChartSeries(
                            id: 'streaming_data',
                            name: 'dataStream',
                            interpolation: LineInterpolation.linear,
                            strokeWidth: 2.0,
                            showDataPointMarkers: false,
                            color: Colors.blue,
                            points: [],
                            isXOrdered: true,
                          ),
                        ],
                        dataStream: _stream1Controller.stream,
                        streamingConfig: StreamingConfig(
                          maxBufferSize: 500,
                          autoScroll: _autoScroll1,
                          autoScrollWindowSize: 150, // Sliding window size
                          resumeAnimationDuration: const Duration(milliseconds: 300), // Smooth jump animation
                          onBufferUpdated: (count) {
                            if (mounted) {
                              setState(() {
                                _buffer1Count = count;
                              });
                            }
                          },
                        ),
                        streamingController: _streaming1Controller,
                        theme: _selectedTheme,
                        backgroundColor: _selectedTheme == ChartTheme.dark ? Colors.grey.shade900 : Colors.white,
                        showDebugInfo: _showDebugInfo,
                        interactionConfig: _interactionConfig,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Chart 1 controls
                    _buildStreaming1Controls(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Chart 2: ChartController approach
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Test 2: ChartController Direct',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Uses controller.addPoint() directly without dataStream',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 400,
                      child: BravenChartPlus(
                        key: const ValueKey('stream_test_controller'),
                        chartType: ChartType.line,
                        controller: _chart2Controller,
                        series: const [
                          LineChartSeries(
                            id: 'controller_data',
                            name: 'ChartController',
                            interpolation: LineInterpolation.linear,
                            strokeWidth: 2.0,
                            showDataPointMarkers: false,
                            color: Colors.green,
                            points: [],
                            isXOrdered: true,
                          ),
                        ],
                        streamingConfig: StreamingConfig(
                          maxBufferSize: 500,
                          autoScroll: _autoScroll2,
                          autoScrollWindowSize: 150, // Sliding window size
                          resumeAnimationDuration: const Duration(milliseconds: 300), // Smooth jump animation
                        ),
                        streamingController: _streaming2Controller,
                        theme: _selectedTheme,
                        backgroundColor: _selectedTheme == ChartTheme.dark ? Colors.grey.shade900 : Colors.white,
                        showDebugInfo: _showDebugInfo,
                        interactionConfig: _interactionConfig,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Chart 2 controls
                    _buildStreaming2Controls(),

                    const SizedBox(height: 8),

                    Text(
                      'This chart receives data through controller.addPoint() calls',
                      style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // Chart 1 (dataStream) controls
  Widget _buildStreaming1Controls() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Stream control buttons
          Row(
            children: [
              Expanded(
                // Wrap button in ListenableBuilder so only this button rebuilds
                // when controller changes, not the entire page
                child: ListenableBuilder(
                  listenable: _streaming1Controller,
                  builder: (context, child) {
                    return ElevatedButton.icon(
                      onPressed: () {
                        print('🔵🔵🔵 INLINE onPressed FIRED! Button widget received click event');
                        _togglePauseResume1();
                      },
                      icon: Icon(_streaming1Controller.isStreaming ? Icons.pause : Icons.play_arrow, size: 16),
                      label: Text(_streaming1Controller.isStreaming ? 'Pause' : 'Resume'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _streaming1Controller.isStreaming ? Colors.orange : Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _streaming1Timer != null && _streaming1Timer!.isActive ? _stopStreaming1 : _startStreaming1,
                  icon: Icon(_streaming1Timer != null && _streaming1Timer!.isActive ? Icons.stop : Icons.play_arrow, size: 16),
                  label: Text(_streaming1Timer != null && _streaming1Timer!.isActive ? 'Stop' : 'Start'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _streaming1Timer != null && _streaming1Timer!.isActive ? Colors.red : Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _resetStreaming1,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Reset'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Row 2: Configuration
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Rate:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    DropdownButton<int>(
                      value: _streaming1Rate,
                      isExpanded: true,
                      items: [1, 5, 10, 20, 50].map((rate) {
                        return DropdownMenuItem(value: rate, child: Text('$rate Hz'));
                      }).toList(),
                      onChanged: (rate) => rate != null ? _changeStreaming1Rate(rate) : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pattern:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    DropdownButton<String>(
                      value: _data1Pattern,
                      isExpanded: true,
                      items: ['sine', 'linear', 'random'].map((pattern) {
                        return DropdownMenuItem(value: pattern, child: Text(pattern));
                      }).toList(),
                      onChanged: (pattern) => pattern != null ? _changeData1Pattern(pattern) : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Auto-scroll:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    ElevatedButton(
                      onPressed: _toggleAutoScroll1,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _autoScroll1 ? Colors.green : Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_autoScroll1 ? 'ON' : 'OFF'),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Row 3: Status
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatusChip('Buffer', '$_buffer1Count', Colors.orange),
              _buildStatusChip('Total Points', '$_total1DataPoints', Colors.purple),
              _buildStatusChip('Rate', '${_streaming1Rate}Hz', Colors.blue),
              _buildStatusChip(
                'Status',
                _streaming1Timer != null && _streaming1Timer!.isActive ? 'Running' : 'Stopped',
                _streaming1Timer != null && _streaming1Timer!.isActive ? Colors.green : Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Chart 2 (ChartController) controls
  Widget _buildStreaming2Controls() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Stream control buttons
          Row(
            children: [
              Expanded(
                child: ListenableBuilder(
                  listenable: _streaming2Controller,
                  builder: (context, child) {
                    return ElevatedButton.icon(
                      onPressed: _streaming2Controller.isStreaming
                          ? () {
                              _streaming2Controller.pauseStreaming();
                              _stopStreaming2(); // Also stop the data generation timer
                            }
                          : () {
                              _streaming2Controller.resumeStreaming();
                              _startStreaming2(); // Also restart the data generation timer
                            },
                      icon: Icon(_streaming2Controller.isStreaming ? Icons.pause : Icons.play_arrow, size: 16),
                      label: Text(_streaming2Controller.isStreaming ? 'Pause' : 'Resume'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _streaming2Controller.isStreaming ? Colors.orange : Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _streaming2Timer != null && _streaming2Timer!.isActive ? _stopStreaming2 : _startStreaming2,
                  icon: Icon(_streaming2Timer != null && _streaming2Timer!.isActive ? Icons.stop : Icons.play_arrow, size: 16),
                  label: Text(_streaming2Timer != null && _streaming2Timer!.isActive ? 'Stop' : 'Start'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _streaming2Timer != null && _streaming2Timer!.isActive ? Colors.red : Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _resetStreaming2,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Reset'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Row 2: Configuration
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Rate:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    DropdownButton<int>(
                      value: _streaming2Rate,
                      isExpanded: true,
                      items: [1, 5, 10, 20, 50].map((rate) {
                        return DropdownMenuItem(value: rate, child: Text('$rate Hz'));
                      }).toList(),
                      onChanged: (rate) => rate != null ? _changeStreaming2Rate(rate) : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pattern:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    DropdownButton<String>(
                      value: _data2Pattern,
                      isExpanded: true,
                      items: ['sine', 'linear', 'random'].map((pattern) {
                        return DropdownMenuItem(value: pattern, child: Text(pattern));
                      }).toList(),
                      onChanged: (pattern) => pattern != null ? _changeData2Pattern(pattern) : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('AutoScroll:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    ElevatedButton(
                      onPressed: _toggleAutoScroll2,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _autoScroll2 ? Colors.green : Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_autoScroll2 ? 'ON' : 'OFF'),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Row 3: Status
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatusChip('Total Points', '$_total2DataPoints', Colors.purple),
              _buildStatusChip('Rate', '${_streaming2Rate}Hz', Colors.blue),
              _buildStatusChip(
                'Status',
                _streaming2Timer != null && _streaming2Timer!.isActive ? 'Running' : 'Stopped',
                _streaming2Timer != null && _streaming2Timer!.isActive ? Colors.green : Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTooltipsTab() {
    final tooltipConfig = TooltipConfig(
      enabled: _tooltipEnabled,
      triggerMode: _tooltipTriggerMode,
      preferredPosition: _tooltipPosition,
      showDelay: Duration(milliseconds: _tooltipShowDelay.toInt()),
      hideDelay: Duration(milliseconds: _tooltipHideDelay.toInt()),
      followCursor: _tooltipFollowCursor,
      offsetFromPoint: _tooltipOffsetFromPoint,
      style: TooltipStyle(
        backgroundColor: _tooltipBackgroundColor,
        borderColor: _tooltipBorderColor,
        borderWidth: _tooltipBorderWidth,
        borderRadius: _tooltipBorderRadius,
        shadowColor: _tooltipShadowColor,
        shadowBlurRadius: _tooltipShadowBlurRadius,
        padding: _tooltipPadding,
        textColor: _tooltipTextColor,
        fontSize: _tooltipFontSize,
      ),
    );

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.teal.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.teal.shade900, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tooltip Configuration Showcase',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Interactive tooltip configuration with live preview. Adjust settings below to see changes in real-time.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.teal.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Live Preview Chart
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.visibility, color: Colors.teal.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          'Live Preview',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hover over or tap data points to see tooltip behavior',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 400,
                      child: BravenChartPlus(
                        key: ValueKey('tooltip_preview_${_tooltipEnabled}_${_tooltipTriggerMode}_${_tooltipPosition}_$_tooltipFollowCursor'),
                        chartType: ChartType.line,
                        showXScrollbar: true,
                        showYScrollbar: true,
                        series: [
                          LineChartSeries(
                            id: 'tooltip_demo',
                            name: 'Temperature',
                            interpolation: LineInterpolation.bezier,
                            tension: 0.4,
                            strokeWidth: 2.5,
                            showDataPointMarkers: true,
                            dataPointMarkerRadius: 5.0,
                            color: Colors.blue,
                            points: List.generate(12, (i) {
                              final x = i.toDouble();
                              final y = 60 + 20 * math.sin(i * 0.5) + (i > 6 ? (i - 6) * 2 : 0);
                              return ChartDataPoint(x: x, y: y);
                            }),
                            isXOrdered: true,
                          ),
                          BarChartSeries(
                            id: 'tooltip_demo_bar',
                            name: 'Humidity',
                            barWidthPercent: 0.5,
                            color: Colors.green,
                            points: List.generate(8, (i) {
                              final x = i * 1.5;
                              final y = 50 + 15 * math.cos(i * 0.6);
                              return ChartDataPoint(x: x, y: y);
                            }),
                            isXOrdered: true,
                          ),
                        ],
                        theme: _selectedTheme,
                        backgroundColor: _selectedTheme == ChartTheme.dark ? Colors.grey.shade900 : Colors.white,
                        showDebugInfo: _showDebugInfo,
                        interactionConfig: InteractionConfig(
                          tooltip: tooltipConfig,
                          showFocusBorder: false,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Configuration Panel
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.settings, color: Colors.teal.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          'Tooltip Configuration',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Behavior Section
                    _buildTooltipConfigSection(
                      title: '⚙️ Behavior',
                      children: [
                        SwitchListTile(
                          title: const Text('Enabled'),
                          subtitle: const Text('Show/hide tooltips'),
                          value: _tooltipEnabled,
                          onChanged: (value) => setState(() => _tooltipEnabled = value),
                        ),
                        const Divider(),
                        ListTile(
                          title: const Text('Trigger Mode'),
                          subtitle: Text(_tooltipTriggerMode.name.toUpperCase()),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: SegmentedButton<chart.TooltipTriggerMode>(
                            segments: const [
                              ButtonSegment(
                                value: chart.TooltipTriggerMode.hover,
                                label: Text('Hover'),
                                icon: Icon(Icons.mouse, size: 16),
                              ),
                              ButtonSegment(
                                value: chart.TooltipTriggerMode.tap,
                                label: Text('Tap'),
                                icon: Icon(Icons.touch_app, size: 16),
                              ),
                              ButtonSegment(
                                value: chart.TooltipTriggerMode.both,
                                label: Text('Both'),
                                icon: Icon(Icons.touch_app, size: 16),
                              ),
                            ],
                            selected: {_tooltipTriggerMode},
                            onSelectionChanged: (Set<chart.TooltipTriggerMode> newSelection) {
                              setState(() => _tooltipTriggerMode = newSelection.first);
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        SwitchListTile(
                          title: const Text('Follow Cursor'),
                          subtitle: const Text('Tooltip moves with mouse/touch'),
                          value: _tooltipFollowCursor,
                          onChanged: (value) => setState(() => _tooltipFollowCursor = value),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Positioning Section
                    _buildTooltipConfigSection(
                      title: '📍 Positioning',
                      children: [
                        ListTile(
                          title: const Text('Preferred Position'),
                          subtitle: Text(_tooltipPosition.name.toUpperCase()),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: chart.TooltipPosition.values.map((position) {
                              final isSelected = _tooltipPosition == position;
                              return ChoiceChip(
                                label: Text(position.name.toUpperCase()),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => _tooltipPosition = position);
                                  }
                                },
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        ListTile(
                          title: const Text('Offset from Point'),
                          subtitle: Text('${_tooltipOffsetFromPoint.toStringAsFixed(1)} px'),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Slider(
                            value: _tooltipOffsetFromPoint,
                            min: 0,
                            max: 30,
                            divisions: 30,
                            label: _tooltipOffsetFromPoint.toStringAsFixed(0),
                            onChanged: (value) => setState(() => _tooltipOffsetFromPoint = value),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Animation Section
                    _buildTooltipConfigSection(
                      title: '✨ Animation',
                      children: [
                        ListTile(
                          title: const Text('Show Delay'),
                          subtitle: Text('${_tooltipShowDelay.toInt()} ms'),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Slider(
                            value: _tooltipShowDelay,
                            min: 0,
                            max: 1000,
                            divisions: 20,
                            label: '${_tooltipShowDelay.toInt()} ms',
                            onChanged: (value) => setState(() => _tooltipShowDelay = value),
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          title: const Text('Hide Delay'),
                          subtitle: Text('${_tooltipHideDelay.toInt()} ms'),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Slider(
                            value: _tooltipHideDelay,
                            min: 0,
                            max: 1000,
                            divisions: 20,
                            label: '${_tooltipHideDelay.toInt()} ms',
                            onChanged: (value) => setState(() => _tooltipHideDelay = value),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Styling Section
                    _buildTooltipConfigSection(
                      title: '🎨 Styling',
                      children: [
                        _buildTooltipColorPicker(
                          'Background Color',
                          _tooltipBackgroundColor,
                          (color) => setState(() => _tooltipBackgroundColor = color),
                        ),
                        const Divider(),
                        _buildTooltipColorPicker(
                          'Border Color',
                          _tooltipBorderColor,
                          (color) => setState(() => _tooltipBorderColor = color),
                        ),
                        const Divider(),
                        ListTile(
                          title: const Text('Border Width'),
                          subtitle: Text('${_tooltipBorderWidth.toStringAsFixed(1)} px'),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Slider(
                            value: _tooltipBorderWidth,
                            min: 0,
                            max: 5,
                            divisions: 50,
                            label: _tooltipBorderWidth.toStringAsFixed(1),
                            onChanged: (value) => setState(() => _tooltipBorderWidth = value),
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          title: const Text('Border Radius'),
                          subtitle: Text('${_tooltipBorderRadius.toStringAsFixed(1)} px'),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Slider(
                            value: _tooltipBorderRadius,
                            min: 0,
                            max: 20,
                            divisions: 40,
                            label: _tooltipBorderRadius.toStringAsFixed(0),
                            onChanged: (value) => setState(() => _tooltipBorderRadius = value),
                          ),
                        ),
                        const Divider(),
                        _buildTooltipColorPicker(
                          'Shadow Color',
                          _tooltipShadowColor,
                          (color) => setState(() => _tooltipShadowColor = color),
                        ),
                        const Divider(),
                        ListTile(
                          title: const Text('Shadow Blur Radius'),
                          subtitle: Text('${_tooltipShadowBlurRadius.toStringAsFixed(1)} px'),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Slider(
                            value: _tooltipShadowBlurRadius,
                            min: 0,
                            max: 20,
                            divisions: 40,
                            label: _tooltipShadowBlurRadius.toStringAsFixed(0),
                            onChanged: (value) => setState(() => _tooltipShadowBlurRadius = value),
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          title: const Text('Padding'),
                          subtitle: Text('${_tooltipPadding.toStringAsFixed(1)} px'),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Slider(
                            value: _tooltipPadding,
                            min: 0,
                            max: 24,
                            divisions: 24,
                            label: _tooltipPadding.toStringAsFixed(0),
                            onChanged: (value) => setState(() => _tooltipPadding = value),
                          ),
                        ),
                        const Divider(),
                        _buildTooltipColorPicker(
                          'Text Color',
                          _tooltipTextColor,
                          (color) => setState(() => _tooltipTextColor = color),
                        ),
                        const Divider(),
                        ListTile(
                          title: const Text('Font Size'),
                          subtitle: Text('${_tooltipFontSize.toStringAsFixed(1)} px'),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Slider(
                            value: _tooltipFontSize,
                            min: 8,
                            max: 24,
                            divisions: 32,
                            label: _tooltipFontSize.toStringAsFixed(0),
                            onChanged: (value) => setState(() => _tooltipFontSize = value),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Quick Presets
                    _buildTooltipConfigSection(
                      title: '🚀 Quick Presets',
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _applyDefaultPreset,
                              icon: const Icon(Icons.restore, size: 16),
                              label: const Text('Default'),
                            ),
                            ElevatedButton.icon(
                              onPressed: _applyMinimalPreset,
                              icon: const Icon(Icons.minimize, size: 16),
                              label: const Text('Minimal'),
                            ),
                            ElevatedButton.icon(
                              onPressed: _applyBoldPreset,
                              icon: const Icon(Icons.format_bold, size: 16),
                              label: const Text('Bold'),
                            ),
                            ElevatedButton.icon(
                              onPressed: _applyGlassPreset,
                              icon: const Icon(Icons.blur_on, size: 16),
                              label: const Text('Glass'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTooltipConfigSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildTooltipColorPicker(
    String label,
    Color currentColor,
    Function(Color) onColorChanged,
  ) {
    return ListTile(
      title: Text(label),
      subtitle: Text('#${currentColor.value.toRadixString(16).toUpperCase().padLeft(8, '0')}'),
      trailing: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: currentColor,
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onTap: () => _showTooltipColorPickerDialog(label, currentColor, onColorChanged),
    );
  }

  void _showTooltipColorPickerDialog(
    String label,
    Color currentColor,
    Function(Color) onColorChanged,
  ) {
    // Predefined colors for quick selection
    final colors = [
      Colors.white,
      const Color(0xE6FFFFFF), // Semi-transparent white
      Colors.black,
      const Color(0xE6000000), // Semi-transparent black
      Colors.grey.shade100,
      Colors.grey.shade300,
      Colors.grey.shade700,
      Colors.blue,
      Colors.blue.shade100,
      Colors.green,
      Colors.green.shade100,
      Colors.red,
      Colors.red.shade100,
      Colors.orange,
      Colors.orange.shade100,
      Colors.purple,
      Colors.purple.shade100,
      Colors.teal,
      Colors.teal.shade100,
      Colors.transparent,
      const Color(0x66000000), // Semi-transparent shadow
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select $label'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colors.map((color) {
            return GestureDetector(
              onTap: () {
                onColorChanged(color);
                Navigator.of(context).pop();
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  border: Border.all(
                    color: color == currentColor ? Colors.blue : Colors.grey.shade400,
                    width: color == currentColor ? 3 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Preset configurations
  void _applyDefaultPreset() {
    setState(() {
      _tooltipEnabled = true;
      _tooltipTriggerMode = chart.TooltipTriggerMode.hover;
      _tooltipPosition = chart.TooltipPosition.auto;
      _tooltipFollowCursor = false;
      _tooltipShowDelay = 100.0;
      _tooltipHideDelay = 200.0;
      _tooltipOffsetFromPoint = 8.0;
      _tooltipBackgroundColor = const Color(0xE6FFFFFF);
      _tooltipBorderColor = const Color(0xFF999999);
      _tooltipBorderWidth = 1.0;
      _tooltipBorderRadius = 4.0;
      _tooltipShadowColor = const Color(0x66000000);
      _tooltipShadowBlurRadius = 4.0;
      _tooltipPadding = 8.0;
      _tooltipTextColor = const Color(0xFF333333);
      _tooltipFontSize = 12.0;
    });
  }

  void _applyMinimalPreset() {
    setState(() {
      _tooltipEnabled = true;
      _tooltipTriggerMode = chart.TooltipTriggerMode.hover;
      _tooltipPosition = chart.TooltipPosition.top;
      _tooltipFollowCursor = false;
      _tooltipShowDelay = 50.0;
      _tooltipHideDelay = 100.0;
      _tooltipOffsetFromPoint = 4.0;
      _tooltipBackgroundColor = Colors.white;
      _tooltipBorderColor = Colors.grey.shade300;
      _tooltipBorderWidth = 0.5;
      _tooltipBorderRadius = 2.0;
      _tooltipShadowColor = Colors.transparent;
      _tooltipShadowBlurRadius = 0.0;
      _tooltipPadding = 4.0;
      _tooltipTextColor = Colors.black87;
      _tooltipFontSize = 11.0;
    });
  }

  void _applyBoldPreset() {
    setState(() {
      _tooltipEnabled = true;
      _tooltipTriggerMode = chart.TooltipTriggerMode.both;
      _tooltipPosition = chart.TooltipPosition.auto;
      _tooltipFollowCursor = true;
      _tooltipShowDelay = 0.0;
      _tooltipHideDelay = 300.0;
      _tooltipOffsetFromPoint = 12.0;
      _tooltipBackgroundColor = Colors.blue.shade700;
      _tooltipBorderColor = Colors.blue.shade900;
      _tooltipBorderWidth = 2.0;
      _tooltipBorderRadius = 8.0;
      _tooltipShadowColor = const Color(0x88000000);
      _tooltipShadowBlurRadius = 8.0;
      _tooltipPadding = 12.0;
      _tooltipTextColor = Colors.white;
      _tooltipFontSize = 14.0;
    });
  }

  void _applyGlassPreset() {
    setState(() {
      _tooltipEnabled = true;
      _tooltipTriggerMode = chart.TooltipTriggerMode.hover;
      _tooltipPosition = chart.TooltipPosition.auto;
      _tooltipFollowCursor = false;
      _tooltipShowDelay = 150.0;
      _tooltipHideDelay = 250.0;
      _tooltipOffsetFromPoint = 10.0;
      _tooltipBackgroundColor = const Color(0xCCFFFFFF); // 80% transparent white
      _tooltipBorderColor = const Color(0x44FFFFFF); // Very transparent white
      _tooltipBorderWidth = 1.5;
      _tooltipBorderRadius = 12.0;
      _tooltipShadowColor = const Color(0x44000000);
      _tooltipShadowBlurRadius = 12.0;
      _tooltipPadding = 10.0;
      _tooltipTextColor = Colors.black87;
      _tooltipFontSize = 12.0;
    });
  }
}
