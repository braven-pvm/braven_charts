// Copyright (c) 2025 braven_charts. All rights reserved.
// BravenChartPlus - Integration of Prototype Interaction System
// NO REFERENCES TO lib/src - COMPLETELY ISOLATED

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../src/foundation/data_models/chart_data_point.dart' as src_point;
import '../../src/widgets/controller/chart_controller.dart';
import '../axis/axis.dart' as chart_axis;
import '../axis/axis_config.dart';
import '../coordinates/chart_transform.dart';
import '../elements/annotation_elements.dart';
import '../interaction/core/chart_element.dart';
import '../interaction/core/coordinator.dart';
import '../interaction/recognizers/priority_pan_recognizer.dart';
import '../interaction/recognizers/priority_tap_recognizer.dart';
import '../models/chart_annotation.dart';
import '../models/chart_data_point.dart';
import '../models/chart_series.dart';
import '../models/chart_theme.dart';
import '../models/chart_type.dart';
import '../models/streaming_config.dart';
import '../rendering/chart_render_box.dart';
import '../rendering/spatial_index.dart';
import '../streaming/buffer_manager.dart';
import '../streaming/streaming_controller.dart';
import '../utils/data_converter.dart';

/// Next-generation BravenChart with prototype interaction system.
///
/// **⚠️ COMPLETELY ISOLATED** - No references to lib/src!
///
/// **Architecture** (from PrototypeChart):
/// - RenderBox with handleEvent() for direct pointer events
/// - ChartInteractionCoordinator for unified state management
/// - QuadTree spatial indexing for O(log n) hit testing
///
/// **Current Phase**: Foundation - Widget skeleton created
/// Next: Create example app to test empty widget
class BravenChartPlus extends StatefulWidget {
  const BravenChartPlus({
    super.key,
    required this.chartType,
    required this.series,
    this.annotations = const [],
    this.theme,
    this.xAxis,
    this.yAxis,
    this.width,
    this.height,
    this.backgroundColor = Colors.white,
    this.showDebugInfo = false,
    this.dataStream,
    this.streamingConfig,
    this.streamingController,
    this.controller,
  });

  final ChartType chartType;
  final List<ChartSeries> series;
  final List<ChartAnnotation> annotations;
  final ChartTheme? theme;
  final AxisConfig? xAxis;
  final AxisConfig? yAxis;
  final double? width;
  final double? height;
  final Color backgroundColor;
  final bool showDebugInfo;

  /// Optional controller for programmatic data updates.
  ///
  /// Matches BravenChart API. When provided, the chart will listen to
  /// controller changes and merge controller data with [series] data.
  /// Use [ChartController.addPoint] for real-time data updates.
  final ChartController? controller;

  /// Optional stream of real-time data points.
  ///
  /// When provided, the chart will subscribe to this stream and add incoming
  /// data points to the first series. For multiple series streaming, use
  /// [StreamingController] to manage data programmatically.
  final Stream<ChartDataPoint>? dataStream;

  /// Configuration for streaming behavior.
  ///
  /// Controls buffer size, auto-scroll, and callbacks. Only used when
  /// [dataStream] is provided. Defaults to [StreamingConfig()] if null.
  final StreamingConfig? streamingConfig;

  /// Controller for programmatic streaming control.
  ///
  /// Allows pausing/resuming streaming and provides state notifications.
  /// Optional - streaming works without it, but useful for custom UI controls.
  final StreamingController? streamingController;

  @override
  State<BravenChartPlus> createState() => _BravenChartPlusState();
}

class _BravenChartPlusState extends State<BravenChartPlus> {
  late ChartInteractionCoordinator _coordinator;
  late QuadTree _spatialIndex;
  late PriorityPanGestureRecognizer _panRecognizer;
  late PriorityTapGestureRecognizer _tapRecognizer;
  late FocusNode _focusNode;

  MouseCursor _currentCursor = SystemMouseCursors.basic;
  final GlobalKey _renderBoxKey = GlobalKey();

  // Element generator function for pan/zoom regeneration
  List<ChartElement> Function(ChartTransform)? _elementGenerator;

  // Generation counter to track when elements actually need regeneration
  // Only incremented in _rebuildElements when series/theme change
  int _elementGeneratorVersion = 0;

  chart_axis.Axis? _xAxis;
  chart_axis.Axis? _yAxis;

  // Streaming state
  StreamSubscription<ChartDataPoint>? _streamSubscription;
  BufferManager<ChartDataPoint>? _buffer;
  bool _isStreaming = true;
  final List<ChartDataPoint> _streamingDataPoints = [];

  @override
  void initState() {
    super.initState();

    _focusNode = FocusNode();
    _coordinator = ChartInteractionCoordinator();
    _coordinator.addListener(_onCoordinatorChanged);

    _spatialIndex = QuadTree(bounds: const Rect.fromLTWH(0, 0, 800, 600), maxElementsPerNode: 4);

    _panRecognizer = PriorityPanGestureRecognizer(
      coordinator: _coordinator,
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
    );

    _tapRecognizer = PriorityTapGestureRecognizer(coordinator: _coordinator, onTapDown: _handleTapDown, onTapUp: _handleTapUp);

    // Listen to controller updates (matches BravenChart pattern)
    widget.controller?.addListener(_onControllerUpdate);

    _rebuildElements();

    // Set up streaming if dataStream is provided
    if (widget.dataStream != null) {
      _setupStreamSubscription();
    }
  }

  @override
  void didUpdateWidget(BravenChartPlus oldWidget) {
    super.didUpdateWidget(oldWidget);
    debugPrint('🔄 didUpdateWidget: seriesChanged=${widget.series != oldWidget.series}, themeChanged=${widget.theme != oldWidget.theme}');
    debugPrint('   oldTheme seriesColors: ${oldWidget.theme?.seriesColors}');
    debugPrint('   newTheme seriesColors: ${widget.theme?.seriesColors}');

    // Handle controller changes (matches BravenChart pattern)
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_onControllerUpdate);
      widget.controller?.addListener(_onControllerUpdate);
    }

    if (widget.series != oldWidget.series || widget.theme != oldWidget.theme) {
      debugPrint('🎨 Theme/Series changed! Calling _rebuildElements()');
      _rebuildElements();
      // Request focus after rebuild to ensure keyboard events still work
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
          debugPrint('🎯 Focus requested after theme/series change');
        }
      });
    } else {
      debugPrint('⚠️ NO CHANGE DETECTED - not rebuilding');
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _streamSubscription?.cancel();
    widget.controller?.removeListener(_onControllerUpdate);
    _coordinator.removeListener(_onCoordinatorChanged);
    _coordinator.dispose();
    _panRecognizer.dispose();
    _tapRecognizer.dispose();
    super.dispose();
  }

  /// Called when controller notifies of changes (matches BravenChart pattern).
  void _onControllerUpdate() {
    if (!mounted) return;

    // Controller data changed - rebuild with merged data
    // This ensures controller.addPoint() updates appear immediately
    setState(() {
      _rebuildElements();
    });
  }

  void _rebuildElements() {
    debugPrint('📋 _rebuildElements called');
    debugPrint('   Current theme: ${widget.theme}');
    debugPrint('   Theme seriesColors: ${widget.theme?.seriesColors}');

    _spatialIndex.clear();

    // Start with widget.series as base
    List<ChartSeries> effectiveSeries = widget.series;

    // Merge controller data if controller is provided (matches BravenChart pattern)
    if (widget.controller != null) {
      final controllerData = widget.controller!.getAllSeries();

      // Create map of existing series for efficient lookup
      final seriesMap = <String, ChartSeries>{};
      for (final series in widget.series) {
        seriesMap[series.id] = series;
      }

      // Merge controller data into series
      final mergedSeriesList = <ChartSeries>[];
      final processedIds = <String>{};

      debugPrint('🔄 Controller has ${controllerData.length} series');

      // First, update existing series with controller data
      for (final series in widget.series) {
        final controllerPoints = controllerData[series.id];
        if (controllerPoints != null && controllerPoints.isNotEmpty) {
          debugPrint('   Series ${series.id}: ${controllerPoints.length} points from controller');

          // Convert src ChartDataPoint to src_plus ChartDataPoint
          final convertedPoints = controllerPoints
              .map((p) => ChartDataPoint(
                    x: p.x,
                    y: p.y,
                    timestamp: p.timestamp,
                    label: p.label,
                    metadata: p.metadata,
                  ))
              .toList();

          if (convertedPoints.isNotEmpty) {
            final lastPoint = convertedPoints.last;
            debugPrint('      Last point: x=${lastPoint.x.toStringAsFixed(3)}, y=${lastPoint.y.toStringAsFixed(6)}');
          }

          // Merge series points with controller points
          final mergedPoints = [...series.points, ...convertedPoints];

          final updatedSeries = switch (series) {
            LineChartSeries() => LineChartSeries(
                id: series.id,
                name: series.name,
                points: mergedPoints,
                color: series.color,
                isXOrdered: series.isXOrdered,
                metadata: series.metadata,
                interpolation: series.interpolation,
                strokeWidth: series.strokeWidth,
                tension: series.tension,
                showDataPointMarkers: series.showDataPointMarkers,
                dataPointMarkerRadius: series.dataPointMarkerRadius,
              ),
            _ => series, // Keep original if not LineChartSeries
          };

          mergedSeriesList.add(updatedSeries);
        } else {
          mergedSeriesList.add(series);
        }
        processedIds.add(series.id);
      }

      // Then, add any controller series that don't exist in widget.series
      for (final entry in controllerData.entries) {
        if (!processedIds.contains(entry.key)) {
          // Convert src ChartDataPoint to src_plus ChartDataPoint
          final convertedPoints = entry.value
              .map((p) => ChartDataPoint(
                    x: p.x,
                    y: p.y,
                    timestamp: p.timestamp,
                    label: p.label,
                    metadata: p.metadata,
                  ))
              .toList();

          // Create new series from controller data
          mergedSeriesList.add(LineChartSeries(
            id: entry.key,
            name: entry.key,
            points: convertedPoints,
            color: widget.theme?.seriesColors.isNotEmpty == true
                ? widget.theme!.seriesColors[mergedSeriesList.length % widget.theme!.seriesColors.length]
                : Colors.blue,
          ));
        }
      }

      effectiveSeries = mergedSeriesList;
    }
    // Legacy: Also merge _streamingDataPoints if present (for backward compatibility)
    else if (_streamingDataPoints.isNotEmpty && widget.series.isNotEmpty) {
      final firstSeries = widget.series.first;
      final mergedPoints = [...firstSeries.points, ..._streamingDataPoints];

      // Create updated series with streaming data
      final updatedFirstSeries = switch (firstSeries) {
        LineChartSeries() => LineChartSeries(
            id: firstSeries.id,
            name: firstSeries.name,
            points: mergedPoints,
            color: firstSeries.color,
            isXOrdered: firstSeries.isXOrdered,
            metadata: firstSeries.metadata,
            interpolation: firstSeries.interpolation,
            strokeWidth: firstSeries.strokeWidth,
            tension: firstSeries.tension,
            showDataPointMarkers: firstSeries.showDataPointMarkers,
            dataPointMarkerRadius: firstSeries.dataPointMarkerRadius,
          ),
        _ => firstSeries, // Keep original if not LineChartSeries
      };

      effectiveSeries = [updatedFirstSeries, ...widget.series.skip(1)];
    }

    // Compute data bounds from effective series
    // For streaming with auto-scroll, use a sliding window instead of all data
    final DataBounds dataBounds;
    if (widget.streamingConfig?.autoScroll == true && effectiveSeries.isNotEmpty) {
      // Calculate sliding window bounds using FIXED NUMBER of recent points
      final allPoints = effectiveSeries.expand((s) => s.points).toList();
      debugPrint('📊 Sliding window calculation: total points=${allPoints.length}');

      if (allPoints.isNotEmpty) {
        // Use last 100 points only (or all if less than 100)
        const maxWindowPoints = 100;
        final windowPoints = allPoints.length <= maxWindowPoints ? allPoints : allPoints.sublist(allPoints.length - maxWindowPoints);

        debugPrint('   Using last ${windowPoints.length} points for bounds (of ${allPoints.length} total)');

        if (windowPoints.isNotEmpty) {
          final minX = windowPoints.map((p) => p.x).reduce((a, b) => a < b ? a : b);
          final maxX = windowPoints.map((p) => p.x).reduce((a, b) => a > b ? a : b);
          final minY = windowPoints.map((p) => p.y).reduce((a, b) => a < b ? a : b);
          final maxY = windowPoints.map((p) => p.y).reduce((a, b) => a > b ? a : b);

          debugPrint('   window bounds: X=[$minX, $maxX], Y=[$minY, $maxY]');

          dataBounds = DataBounds(xMin: minX, xMax: maxX, yMin: minY, yMax: maxY);
        } else {
          debugPrint('   ⚠️ No points in window, falling back to full bounds');
          dataBounds = DataConverter.computeDataBounds(effectiveSeries);
        }
      } else {
        debugPrint('   ⚠️ No points at all, using default [0,1]');
        dataBounds = const DataBounds(xMin: 0, xMax: 1, yMin: 0, yMax: 1);
      }
    } else {
      // Non-streaming or no auto-scroll: use all data
      debugPrint('📊 Using full data bounds (not streaming or autoScroll=false)');
      dataBounds = DataConverter.computeDataBounds(effectiveSeries);
    } // Create axes from data bounds with theme colors
    _xAxis = chart_axis.Axis(
      config: AxisConfig(
        label: widget.xAxis?.label ?? 'X',
        orientation: AxisOrientation.horizontal,
        position: AxisPosition.bottom,
        axisColor: widget.theme?.axisColor ?? Colors.black87,
        gridColor: widget.theme?.gridColor ?? const Color(0xFFE0E0E0),
        labelStyle: TextStyle(fontSize: 12, color: widget.theme?.textColor ?? Colors.black87),
        tickLabelStyle: TextStyle(fontSize: 10, color: widget.theme?.textColor ?? Colors.black54),
      ),
      dataMin: dataBounds.xMin,
      dataMax: dataBounds.xMax,
    );

    _yAxis = chart_axis.Axis(
      config: AxisConfig(
        label: widget.yAxis?.label ?? 'Y',
        orientation: AxisOrientation.vertical,
        position: AxisPosition.left,
        axisColor: widget.theme?.axisColor ?? Colors.black87,
        gridColor: widget.theme?.gridColor ?? const Color(0xFFE0E0E0),
        labelStyle: TextStyle(fontSize: 12, color: widget.theme?.textColor ?? Colors.black87),
        tickLabelStyle: TextStyle(fontSize: 10, color: widget.theme?.textColor ?? Colors.black54),
      ),
      dataMin: dataBounds.yMin,
      dataMax: dataBounds.yMax,
    );

    // Create element generator function
    // This will be called by ChartRenderBox during zoom/pan to regenerate elements
    _elementGenerator = (ChartTransform transform) {
      final seriesIds = effectiveSeries.map((s) => s.id).join(', ');
      debugPrint('🔧 Element generator executing for series: [$seriesIds]');

      // Generate series elements from effective series (with streaming data)
      final elements = DataConverter.seriesToElements(
        series: effectiveSeries,
        transform: transform,
        theme: widget.theme,
        strokeWidth: 2.0,
      ).cast<ChartElement>().toList();

      // Convert annotations to elements
      debugPrint('📍 Converting ${widget.annotations.length} annotations to elements');
      debugPrint('   Transform: plotWidth=${transform.plotWidth}, plotHeight=${transform.plotHeight}');
      debugPrint('   Transform: dataX=${transform.dataXMin}..${transform.dataXMax}, dataY=${transform.dataYMin}..${transform.dataYMax}');
      for (final annotation in widget.annotations) {
        try {
          final ChartElement element = switch (annotation) {
            PointAnnotation() => PointAnnotationElement(
                annotation: annotation,
                series: widget.series.firstWhere(
                  (s) => s.id == annotation.seriesId,
                  orElse: () => throw StateError('Series ${annotation.seriesId} not found'),
                ),
                transform: transform,
              ),
            RangeAnnotation() => RangeAnnotationElement(
                annotation: annotation,
                transform: transform,
                chartSize: Size(transform.plotWidth, transform.plotHeight),
              ),
            TextAnnotation() => TextAnnotationElement(
                annotation: annotation,
              ),
            ThresholdAnnotation() => ThresholdAnnotationElement(
                annotation: annotation,
                transform: transform,
              ),
            TrendAnnotation() => TrendAnnotationElement(
                annotation: annotation,
                series: widget.series.firstWhere(
                  (s) => s.id == annotation.seriesId,
                  orElse: () => throw StateError('Series ${annotation.seriesId} not found'),
                ),
                transform: transform,
              ),
          };
          elements.add(element);
          debugPrint('  ✅ Created ${annotation.runtimeType} element: ${annotation.id}');

          // For resizable elements, also insert their resize handle elements
          if (element is ResizableElement && element.isResizable) {
            final handleElements = element.createResizeHandleElements().cast<ChartElement>();
            elements.addAll(handleElements);
            debugPrint('  🎯 Added ${handleElements.length} resize handles for ${annotation.id}');
          }
        } catch (e) {
          debugPrint('⚠️ Warning: Failed to create annotation element for ${annotation.id}: $e');
        }
      }

      return elements;
    };

    // Increment version to signal that regeneration is needed
    _elementGeneratorVersion++;

    debugPrint('✅ _rebuildElements complete, new generator created (version $_elementGeneratorVersion)');
  }

  void _onCoordinatorChanged() {
    // CRITICAL FIX: Only call setState() if debug overlay is visible!
    // Crosshair rendering happens in RenderBox.paint() via markNeedsPaint(),
    // so we don't need setState() for cursor movement.
    // setState() triggers expensive widget tree rebuilds.
    if (widget.showDebugInfo) {
      setState(() {});
    }
  }

  void _handlePanStart(DragStartDetails details) {
    // Request focus on pan start to enable keyboard controls
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
      debugPrint('🎯 Focus requested via pan start');
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final renderBox = _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
    renderBox?.panChart(details.delta.dx, details.delta.dy);
  }

  void _handlePanEnd(DragEndDetails details) {}

  void _handleTapDown(TapDownDetails details) {
    // Request focus on tap to enable keyboard controls
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
      debugPrint('🎯 Focus requested via tap');
    }
  }

  void _handleTapUp(TapUpDetails details) {}

  void _handleCursorChange(MouseCursor cursor) {
    if (_currentCursor != cursor) {
      setState(() => _currentCursor = cursor);
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    debugPrint('⌨️ _handleKeyEvent: ${event.runtimeType}, key=${event.logicalKey}');

    if (event is KeyDownEvent) {
      final renderBox = _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
      debugPrint('   RenderBox found: ${renderBox != null}');

      if (renderBox == null) return;

      // Reset view
      if (event.logicalKey == LogicalKeyboardKey.home || event.logicalKey == LogicalKeyboardKey.keyR) {
        debugPrint('   Calling resetView()');
        renderBox.resetView();
      }
      // Shift modifier for zoom
      else if (event.logicalKey == LogicalKeyboardKey.shiftLeft || event.logicalKey == LogicalKeyboardKey.shiftRight) {
        debugPrint('   Adding Shift modifier');
        _coordinator.addModifierKey(LogicalKeyboardKey.shift);
      }
      // Arrow keys for panning
      else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        debugPrint('   Arrow Left - calling panChart(-20, 0)');
        renderBox.panChart(-20.0, 0.0);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        debugPrint('   Arrow Right - calling panChart(20, 0)');
        renderBox.panChart(20.0, 0.0);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        debugPrint('   Arrow Up - calling panChart(0, -20)');
        renderBox.panChart(0.0, -20.0);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        debugPrint('   Arrow Down - calling panChart(0, 20)');
        renderBox.panChart(0.0, 20.0);
      }
      // Zoom in with + or = or numpad +
      else if (event.logicalKey == LogicalKeyboardKey.equal ||
          event.logicalKey == LogicalKeyboardKey.add ||
          event.logicalKey == LogicalKeyboardKey.numpadAdd) {
        debugPrint('   Zoom In key - calling zoomChart(1.1)');
        renderBox.zoomChart(1.1);
      }
      // Zoom out with - or numpad -
      else if (event.logicalKey == LogicalKeyboardKey.minus || event.logicalKey == LogicalKeyboardKey.numpadSubtract) {
        debugPrint('   Zoom Out key - calling zoomChart(0.9)');
        renderBox.zoomChart(0.9);
      }
    } else if (event is KeyUpEvent) {
      if (event.logicalKey == LogicalKeyboardKey.shiftLeft || event.logicalKey == LogicalKeyboardKey.shiftRight) {
        debugPrint('   Removing Shift modifier');
        _coordinator.removeModifierKey(LogicalKeyboardKey.shift);
      }
    }
  }

  // Streaming methods

  /// Sets up the stream subscription for real-time data ingestion.
  void _setupStreamSubscription() {
    final config = widget.streamingConfig ?? const StreamingConfig();

    // Initialize buffer if not already created
    _buffer ??= BufferManager<ChartDataPoint>(maxSize: config.maxBufferSize);

    // Register callbacks with controller if provided
    widget.streamingController?.registerResumeCallback(_resumeStreaming);
    widget.streamingController?.registerPauseCallback(_pauseStreaming);
    widget.streamingController?.registerClearCallback(_clearStreamingData);

    // Subscribe to the data stream
    _streamSubscription = widget.dataStream?.listen(
      _onStreamData,
      onError: (error) {
        config.onStreamError?.call(error);
        debugPrint('❌ Stream error: $error');
      },
    );
  }

  /// Handles incoming stream data points.
  void _onStreamData(ChartDataPoint point) {
    if (!mounted) return;

    final config = widget.streamingConfig ?? const StreamingConfig();

    debugPrint('🔵 Stream data received: x=${point.x.toStringAsFixed(3)}, y=${point.y.toStringAsFixed(6)}');

    if (_isStreaming) {
      // Use controller if available (matches BravenChart pattern)
      if (widget.controller != null) {
        // Determine series ID - use first series ID or default to 'stream'
        final seriesId = widget.series.isNotEmpty ? widget.series.first.id : 'stream';

        // Convert src_plus ChartDataPoint to src ChartDataPoint for controller
        final srcPoint = src_point.ChartDataPoint(
          x: point.x,
          y: point.y,
          timestamp: point.timestamp,
          label: point.label,
          metadata: point.metadata,
        );

        // Add to controller - this will trigger _onControllerUpdate -> setState -> rebuild
        widget.controller!.addPoint(seriesId, srcPoint);

        // Auto-scroll if enabled
        if (config.autoScroll) {
          setState(() {
            _autoScrollToLatest();
          });
        }
      } else {
        // Legacy path: Add point to streaming data list
        setState(() {
          _streamingDataPoints.add(point);
          _rebuildElements();

          // Auto-scroll if enabled
          if (config.autoScroll) {
            _autoScrollToLatest();
          }
        });
      }
    } else {
      // Buffer the point for later
      _buffer?.add(point);
      config.onBufferUpdated?.call(_buffer?.length ?? 0);
    }
  }

  /// Pauses streaming and starts buffering incoming data.
  void _pauseStreaming() {
    if (!_isStreaming) return; // Already paused

    setState(() {
      _isStreaming = false;
    });

    widget.streamingController?.updateState(false);
    debugPrint('⏸️  Streaming paused');
  }

  /// Resumes streaming and applies buffered data.
  void _resumeStreaming() {
    if (_isStreaming) return; // Already streaming

    // Apply buffered data
    _applyBufferedData();

    setState(() {
      _isStreaming = true;
    });

    widget.streamingController?.updateState(true);
    debugPrint('▶️  Streaming resumed');
  }

  /// Applies all buffered data points to the series.
  void _applyBufferedData() {
    final bufferedPoints = _buffer?.removeAll() ?? [];

    if (bufferedPoints.isEmpty) return;

    // Use controller if available
    if (widget.controller != null) {
      final seriesId = widget.series.isNotEmpty ? widget.series.first.id : 'stream';

      for (final point in bufferedPoints) {
        final srcPoint = src_point.ChartDataPoint(
          x: point.x,
          y: point.y,
          timestamp: point.timestamp,
          label: point.label,
          metadata: point.metadata,
        );
        widget.controller!.addPoint(seriesId, srcPoint);
      }
      // Controller will trigger _onControllerUpdate -> setState -> rebuild
    } else {
      // Legacy path
      setState(() {
        _streamingDataPoints.addAll(bufferedPoints);
        _rebuildElements();
      });
    }

    // Auto-scroll and notify regardless of path
    final config = widget.streamingConfig ?? const StreamingConfig();
    if (config.autoScroll) {
      setState(() {
        _autoScrollToLatest();
      });
    }

    // Notify about buffer clear
    config.onBufferUpdated?.call(0);

    debugPrint('📊 Applied ${bufferedPoints.length} buffered points');
  }

  /// Clears all accumulated streaming data.
  void _clearStreamingData() {
    if (!mounted) return;

    // Clear controller data if available
    if (widget.controller != null) {
      final seriesId = widget.series.isNotEmpty ? widget.series.first.id : 'stream';
      widget.controller!.clearSeries(seriesId);
      // Controller will trigger _onControllerUpdate -> setState -> rebuild
    } else {
      // Legacy path
      final pointCount = _streamingDataPoints.length;
      setState(() {
        _streamingDataPoints.clear();
        _rebuildElements();
      });
      debugPrint('🗑️  Cleared $pointCount streaming points');
    }

    // Clear buffer regardless of path
    _buffer?.clear();
  }

  /// Auto-scrolls the viewport to show the latest data.
  void _autoScrollToLatest() {
    final renderBox = _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
    if (renderBox == null) return;

    // NOTE: We don't call updateDataBounds() here anymore because:
    // 1. The sliding window in _rebuildElements() already calculated correct bounds
    // 2. Calling updateDataBounds() with all historical data causes bounds explosion
    // 3. The pan operation below is sufficient to follow latest data

    debugPrint('↩️  Auto-scrolling viewport to follow latest data');

    // Pan right every time to follow the data
    final panAmount = renderBox.size.width * 0.02; // 2% per update
    renderBox.panChart(panAmount, 0.0);
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🏗️  BravenChartPlus.build() called');
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        _handleKeyEvent(event);
        return KeyEventResult.handled;
      },
      child: Builder(
        builder: (context) {
          final hasFocus = _focusNode.hasFocus;
          return MouseRegion(
            // Request focus when mouse enters this chart (for keyboard controls)
            onEnter: (_) {
              if (!_focusNode.hasFocus) {
                _focusNode.requestFocus();
                debugPrint('🎯 Focus requested via mouse enter');
              }
            },
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                border: hasFocus ? Border.all(color: Colors.blue, width: 2) : null,
              ),
              child: Stack(
                children: [
                  MouseRegion(
                    cursor: _currentCursor,
                    child: RawGestureDetector(
                      gestures: {
                        PriorityPanGestureRecognizer: GestureRecognizerFactoryWithHandlers<PriorityPanGestureRecognizer>(
                          () => _panRecognizer,
                          (recognizer) {},
                        ),
                        PriorityTapGestureRecognizer: GestureRecognizerFactoryWithHandlers<PriorityTapGestureRecognizer>(
                          () => _tapRecognizer,
                          (recognizer) {},
                        ),
                      },
                      child: _ChartRenderWidget(
                        key: _renderBoxKey,
                        coordinator: _coordinator,
                        spatialIndex: _spatialIndex,
                        elementGenerator: _elementGenerator,
                        elementGeneratorVersion: _elementGeneratorVersion,
                        xAxis: _xAxis,
                        yAxis: _yAxis,
                        theme: widget.theme,
                        onCursorChange: _handleCursorChange,
                      ),
                    ),
                  ),
                  if (widget.showDebugInfo) Positioned(top: 8, left: 8, child: _DebugOverlay(coordinator: _coordinator)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ChartRenderWidget extends LeafRenderObjectWidget {
  const _ChartRenderWidget({
    super.key,
    required this.coordinator,
    required this.spatialIndex,
    this.elementGenerator,
    required this.elementGeneratorVersion,
    this.xAxis,
    this.yAxis,
    this.theme,
    this.onCursorChange,
  });

  final ChartInteractionCoordinator coordinator;
  final QuadTree spatialIndex;
  final List<ChartElement> Function(ChartTransform)? elementGenerator;
  final int elementGeneratorVersion;
  final chart_axis.Axis? xAxis;
  final chart_axis.Axis? yAxis;
  final ChartTheme? theme;
  final void Function(MouseCursor cursor)? onCursorChange;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return ChartRenderBox(coordinator: coordinator, elementGenerator: elementGenerator, theme: theme, onCursorChange: onCursorChange)
      ..setXAxis(xAxis)
      ..setYAxis(yAxis);
  }

  @override
  void updateRenderObject(BuildContext context, ChartRenderBox renderObject) {
    debugPrint('🔧 _ChartRenderWidget.updateRenderObject called (version $elementGeneratorVersion)');
    renderObject
      ..setElementGenerator(elementGenerator, elementGeneratorVersion)
      ..setXAxis(xAxis)
      ..setYAxis(yAxis)
      ..setTheme(theme);
  }
}

class _DebugOverlay extends StatelessWidget {
  const _DebugOverlay({required this.coordinator});

  final ChartInteractionCoordinator coordinator;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(4)),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Mode: ${coordinator.currentMode.name}'),
            Text('Selected: ${coordinator.selectedElements.length}'),
            if (coordinator.activeElement != null) Text('Active: ${coordinator.activeElement!.id}'),
          ],
        ),
      ),
    );
  }
}
