// Copyright (c) 2025 braven_charts. All rights reserved.
// BravenChartPlus - Integration of Prototype Interaction System
// NO REFERENCES TO lib/src - COMPLETELY ISOLATED

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../src/foundation/data_models/chart_data_point.dart' as src_point;
import '../../src/interaction/models/interaction_config.dart';
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
import '../theming/components/scrollbar_config.dart';
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
    this.showXScrollbar = false,
    this.showYScrollbar = false,
    this.scrollbarTheme,
    this.dataStream,
    this.streamingConfig,
    this.streamingController,
    this.controller,
    this.interactionConfig,
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

  /// Whether to show horizontal scrollbar at the bottom of the chart.
  ///
  /// When enabled, displays a dual-purpose scrollbar for panning (drag handle)
  /// and zooming (drag edges). Defaults to false.
  final bool showXScrollbar;

  /// Whether to show vertical scrollbar on the right side of the chart.
  ///
  /// When enabled, displays a dual-purpose scrollbar for panning (drag handle)
  /// and zooming (drag edges). Defaults to false.
  final bool showYScrollbar;

  /// Theme configuration for scrollbars.
  ///
  /// Controls visual appearance (colors, thickness, border radius) and
  /// interaction behavior (auto-hide, zoom limits, edge grip width).
  /// If null, defaults to [ScrollbarConfig.defaultLight()].
  ///
  /// **Property Implementation Status:**
  ///
  /// ✅ **Working:** All visual properties (thickness, colors, borderRadius,
  /// edgeGripWidth, showGripIndicator, padding, minHandleSize)
  ///
  /// ❌ **Not Yet Implemented:** Animation properties (autoHide, autoHideDelay,
  /// fadeDuration), behavior flags (enableResizeHandles), accessibility
  /// (forcedColorsMode, prefersReducedMotion), zoom limits (minZoomRatio,
  /// maxZoomRatio)
  ///
  /// See [ScrollbarConfig] documentation for full property list.
  final ScrollbarConfig? scrollbarTheme;

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

  /// Configuration for interactive features (crosshair, tooltip, gestures, keyboard navigation).
  ///
  /// Controls tooltip visibility via [InteractionConfig.tooltip.enabled].
  /// If null, defaults to enabled tooltips with standard behavior.
  final InteractionConfig? interactionConfig;

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

  // Locked viewport bounds when paused - THE FUNDAMENTAL FIX
  DataBounds? _lockedPausedBounds;

  // Cached full dataset bounds for pan constraints when paused (Option 4)
  // Updated incrementally in O(1) time as new data arrives
  double? _cachedDataXMin;
  double? _cachedDataXMax;
  double? _cachedDataYMin;
  double? _cachedDataYMax;

  @override
  void initState() {
    super.initState();

    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChanged);
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

    // Initialize cached bounds from existing series data for pan constraints
    _initializeCachedDataBounds();

    // Register streaming controller callbacks (needed even without dataStream)
    widget.streamingController?.registerResumeCallback(_resumeStreaming);
    widget.streamingController?.registerPauseCallback(_pauseStreaming);
    widget.streamingController?.registerClearCallback(_clearStreamingData);

    // Set up streaming if dataStream is provided
    if (widget.dataStream != null) {
      _setupStreamSubscription();
    }
  }

  @override
  void didUpdateWidget(BravenChartPlus oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Removed excessive debugPrints (didUpdateWidget details)

    // Handle controller changes (matches BravenChart pattern)
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_onControllerUpdate);
      widget.controller?.addListener(_onControllerUpdate);
    }

    if (widget.series != oldWidget.series || widget.theme != oldWidget.theme) {
      // Removed excessive debugPrint (theme/series changed)
      _rebuildElements();
      // Request focus after rebuild to ensure keyboard events still work
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
          // Removed excessive debugPrint (focus requested)
        }
      });
    }
  }

  /// Called when focus state changes.
  void _onFocusChanged() {
    // Trigger rebuild to show/hide focus border
    setState(() {});
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
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
    debugPrint('🔔 _onControllerUpdate called, mounted=$mounted, controller=${widget.controller != null}');
    if (!mounted) return;

    // Update cached bounds even when paused - needed for pan constraints
    if (widget.controller != null) {
      final controllerData = widget.controller!.getAllSeries();
      debugPrint('🔔 Controller has ${controllerData.length} series');
      int totalPoints = 0;
      for (final points in controllerData.values) {
        totalPoints += points.length;
        for (final point in points) {
          // Initialize cached bounds if this is the first point
          if (_cachedDataXMin == null) {
            _cachedDataXMin = point.x;
            _cachedDataXMax = point.x;
            _cachedDataYMin = point.y;
            _cachedDataYMax = point.y;
            debugPrint('📊 Controller: Initialized cached bounds with first point: '
                'X=[$_cachedDataXMin, $_cachedDataXMax], Y=[$_cachedDataYMin, $_cachedDataYMax]');
          } else {
            _updateCachedDataBounds(point.x, point.y);
          }
        }
      }
      // Only log occasionally to avoid spam
      if (totalPoints % 50 == 0 || totalPoints < 10) {
        debugPrint('📊 Controller: Updated cached bounds from $totalPoints points: '
            'X=[$_cachedDataXMin, $_cachedDataXMax], Y=[$_cachedDataYMin, $_cachedDataYMax]');
      }
    }

    // When paused, don't rebuild - let data accumulate silently
    // This prevents visual jumps when exploring the viewport
    if (!_isStreaming) {
      debugPrint('⏸️  Controller updated while paused - data accumulating, no rebuild');
      return;
    }

    // Controller data changed - rebuild with merged data
    // This ensures controller.addPoint() updates appear immediately
    setState(() {
      _rebuildElements();
    });
  }

  void _rebuildElements() {
    // Removed excessive debugPrints - was firing on every frame during streaming

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

      // Removed excessive debugPrint

      // First, update existing series with controller data
      for (final series in widget.series) {
        final controllerPoints = controllerData[series.id];
        if (controllerPoints != null && controllerPoints.isNotEmpty) {
          // Removed excessive debugPrints - was firing on every frame

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

          // Removed excessive debugPrint (last point details)

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
    // FUNDAMENTAL FIX: Use locked bounds when paused to prevent visual jump
    // Otherwise calculate bounds based on viewport mode
    DataBounds dataBounds; // Made mutable for validation safety checks

    if (_lockedPausedBounds != null) {
      // PAUSED: Use locked bounds captured at pause time
      // Removed excessive debugPrint (locked bounds details)
      dataBounds = _lockedPausedBounds!;
    } else {
      // NOT PAUSED: Calculate bounds based on viewport mode
      final shouldUseWindowBounds = widget.streamingConfig?.autoScroll == true &&
          widget.streamingController?.viewportMode == ViewportMode.followLatest &&
          effectiveSeries.isNotEmpty;

      if (shouldUseWindowBounds) {
        // Calculate sliding window bounds using CONFIGURABLE NUMBER of recent points
        final allPoints = effectiveSeries.expand((s) => s.points).toList();
        final windowSize = widget.streamingConfig?.autoScrollWindowSize ?? 150;
        // Removed excessive debugPrint (sliding window calculation)

        if (allPoints.isNotEmpty) {
          // Use last N points only (or all if less than N)
          final windowPoints = allPoints.length <= windowSize ? allPoints : allPoints.sublist(allPoints.length - windowSize);

          // Removed excessive debugPrint (window points count)

          if (windowPoints.isNotEmpty) {
            final minX = windowPoints.map((p) => p.x).reduce((a, b) => a < b ? a : b);
            final maxX = windowPoints.map((p) => p.x).reduce((a, b) => a > b ? a : b);
            final minY = windowPoints.map((p) => p.y).reduce((a, b) => a < b ? a : b);
            final maxY = windowPoints.map((p) => p.y).reduce((a, b) => a > b ? a : b);

            // Removed excessive print (window bounds)

            dataBounds = DataBounds(xMin: minX, xMax: maxX, yMin: minY, yMax: maxY);
          } else {
            // Removed excessive print (no points in window)
            dataBounds = DataConverter.computeDataBounds(effectiveSeries);
          }
        } else {
          // Removed excessive print (no points at all)
          dataBounds = const DataBounds(xMin: 0, xMax: 1, yMin: 0, yMax: 1);
        }
      } else {
        // Non-streaming, no auto-scroll, or explore mode: use all data
        // Removed excessive print (full data bounds)
        dataBounds = DataConverter.computeDataBounds(effectiveSeries);
      }
    }

    // CRITICAL: Ensure valid bounds before creating axes (prevent dataMax <= dataMin assertion)
    if (dataBounds.xMax <= dataBounds.xMin) {
      print('⚠️ INVALID X BOUNDS: xMin=${dataBounds.xMin}, xMax=${dataBounds.xMax}, forcing default [0,1]');
      dataBounds = DataBounds(
        xMin: 0,
        xMax: 1,
        yMin: dataBounds.yMin,
        yMax: dataBounds.yMax,
      );
    }
    if (dataBounds.yMax <= dataBounds.yMin) {
      print('⚠️ INVALID Y BOUNDS: yMin=${dataBounds.yMin}, yMax=${dataBounds.yMax}, forcing default [0,1]');
      dataBounds = DataBounds(
        xMin: dataBounds.xMin,
        xMax: dataBounds.xMax,
        yMin: 0,
        yMax: 1,
      );
    }

    // Create axes from data bounds with theme colors
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

    // Create element generator that renders series
    // This will be called by ChartRenderBox during zoom/pan to regenerate elements
    _elementGenerator = (ChartTransform transform) {
      // Removed excessive debugPrint (element generator executing)

      // Generate series elements from effective series (with streaming data)
      final elements = DataConverter.seriesToElements(
        series: effectiveSeries,
        transform: transform,
        theme: widget.theme,
        strokeWidth: 2.0,
        coordinator: _coordinator,
      ).cast<ChartElement>().toList();

      // Convert annotations to elements
      // Removed excessive debugPrints (annotation conversion details)
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
            // Removed excessive debugPrint (resize handles added)
          }
        } catch (e) {
          debugPrint('⚠️ Warning: Failed to create annotation element for ${annotation.id}: $e');
        }
      }

      return elements;
    };

    // Increment version to signal that regeneration is needed
    _elementGeneratorVersion++;

    // Removed excessive debugPrint (_rebuildElements complete)
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
      // Removed excessive debugPrint (focus requested via pan start)
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
      // Removed excessive debugPrint (focus requested via tap)
    }
  }

  void _handleTapUp(TapUpDetails details) {}

  void _handleCursorChange(MouseCursor cursor) {
    if (_currentCursor != cursor) {
      setState(() => _currentCursor = cursor);
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    // Removed excessive debugPrint (key event)

    if (event is KeyDownEvent) {
      final renderBox = _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
      // Removed excessive debugPrint (renderbox found)

      if (renderBox == null) return;

      // Reset view
      if (event.logicalKey == LogicalKeyboardKey.home || event.logicalKey == LogicalKeyboardKey.keyR) {
        // Removed excessive debugPrint (calling resetView)
        renderBox.resetView();
      }
      // Shift modifier for zoom
      else if (event.logicalKey == LogicalKeyboardKey.shiftLeft || event.logicalKey == LogicalKeyboardKey.shiftRight) {
        // Removed excessive debugPrint (adding shift modifier)
        _coordinator.addModifierKey(LogicalKeyboardKey.shift);
      }
      // Arrow keys for panning
      else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        // Removed excessive debugPrint (arrow left)
        renderBox.panChart(-20.0, 0.0);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        // Removed excessive debugPrint (arrow right)
        renderBox.panChart(20.0, 0.0);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        // Removed excessive debugPrint (arrow up)
        renderBox.panChart(0.0, -20.0);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        // Removed excessive debugPrint (arrow down)
        renderBox.panChart(0.0, 20.0);
      }
      // Zoom in with + or = or numpad +
      else if (event.logicalKey == LogicalKeyboardKey.equal ||
          event.logicalKey == LogicalKeyboardKey.add ||
          event.logicalKey == LogicalKeyboardKey.numpadAdd) {
        // Removed excessive debugPrint (zoom in)
        renderBox.zoomChart(1.1);
      }
      // Zoom out with - or numpad -
      else if (event.logicalKey == LogicalKeyboardKey.minus || event.logicalKey == LogicalKeyboardKey.numpadSubtract) {
        // Removed excessive debugPrint (zoom out)
        renderBox.zoomChart(0.9);
      }
    } else if (event is KeyUpEvent) {
      if (event.logicalKey == LogicalKeyboardKey.shiftLeft || event.logicalKey == LogicalKeyboardKey.shiftRight) {
        // Removed excessive debugPrint (removing shift modifier)
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

    // Removed excessive print - was flooding console 10-50 times per second

    // Update cached bounds for full dataset pan constraints (O(1) per point)
    _updateCachedDataBounds(point.x, point.y);

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
  /// FUNDAMENTAL FIX: Lock the current viewport bounds to prevent visual jump.
  /// PERFORMANCE FIX: No expensive point iteration - instant pause response.
  void _pauseStreaming() {
    if (!_isStreaming) return; // Already paused

    print('⏸️  ===== PAUSE STREAMING STARTED =====');

    // STEP 1: Capture current viewport bounds from axes
    // This is what the user sees RIGHT NOW - we must preserve it exactly
    if (_xAxis != null && _yAxis != null) {
      _lockedPausedBounds = DataBounds(
        xMin: _xAxis!.dataMin,
        xMax: _xAxis!.dataMax,
        yMin: _yAxis!.dataMin,
        yMax: _yAxis!.dataMax,
      );
      print(
          '🔒 LOCKED viewport bounds: X=[${_lockedPausedBounds!.xMin}, ${_lockedPausedBounds!.xMax}], Y=[${_lockedPausedBounds!.yMin}, ${_lockedPausedBounds!.yMax}]');
    }

    // STEP 2: Set pan constraints to full dataset bounds (Option 4)
    final renderBox = _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
    if (renderBox != null && _cachedDataXMin != null) {
      renderBox.setPanConstraintBounds(
        _cachedDataXMin!,
        _cachedDataXMax!,
        _cachedDataYMin!,
        _cachedDataYMax!,
      );
    }

    // STEP 3: Update streaming state
    _isStreaming = false;

    print('⏸️  ===== PAUSE COMPLETE - Viewport LOCKED =====');

    // STEP 4: Force rebuild with locked bounds to prevent race condition
    // This ensures _lockedPausedBounds is used IMMEDIATELY, before any other rebuild
    setState(() {
      // Locked bounds are already set, this just triggers rebuild
      print('⏸️  Forcing rebuild with locked bounds to prevent race condition');
    });
  }

  /// Resumes streaming and applies buffered data.
  /// FUNDAMENTAL FIX: Unlock the viewport bounds to resume dynamic calculation.
  void _resumeStreaming() {
    if (_isStreaming) return; // Already streaming

    print('▶️  ===== RESUME STREAMING STARTED =====');

    // STEP 1: Clear pan constraint bounds to restore sliding window constraints (Option 4)
    final renderBox = _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
    renderBox?.clearPanConstraintBounds();

    // STEP 2: Unlock the viewport bounds AND update streaming state FIRST
    // CRITICAL: Must set _isStreaming = true BEFORE applying buffered data
    // to prevent "Controller updated while paused" spam when controller.addPoint() is called
    _lockedPausedBounds = null;
    _isStreaming = true;

    // STEP 3: Apply buffered data (controller.addPoint will now trigger rebuilds)
    _applyBufferedData();

    // DON'T call updateState() - the controller already updated its state
    // and called notifyListeners() before calling this callback
    // widget.streamingController?.updateState(true);  // REMOVED - redundant

    // STEP 3: Jump viewport to latest data after resume
    _jumpToLatestData();

    // Removed excessive debugPrint (streaming resumed)
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

    // Removed excessive debugPrint (applied buffered points)
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
      setState(() {
        _streamingDataPoints.clear();
        _rebuildElements();
      });
      // Removed excessive debugPrint (cleared streaming points)
    }

    // Clear buffer regardless of path
    _buffer?.clear();
  }

  /// Updates the cached full dataset bounds incrementally (O(1) per point).
  ///
  /// This tracks the absolute min/max of all data that has ever been added,
  /// enabling pan constraints to cover the full dataset when paused.
  void _updateCachedDataBounds(double x, double y) {
    _cachedDataXMin = _cachedDataXMin == null ? x : (_cachedDataXMin! < x ? _cachedDataXMin! : x);
    _cachedDataXMax = _cachedDataXMax == null ? x : (_cachedDataXMax! > x ? _cachedDataXMax! : x);
    _cachedDataYMin = _cachedDataYMin == null ? y : (_cachedDataYMin! < y ? _cachedDataYMin! : y);
    _cachedDataYMax = _cachedDataYMax == null ? y : (_cachedDataYMax! > y ? _cachedDataYMax! : y);
  }

  /// Initializes cached bounds from existing series data.
  ///
  /// Called once during setup to establish baseline bounds before streaming starts.
  void _initializeCachedDataBounds() {
    if (_cachedDataXMin != null) return; // Already initialized

    // Get all points from widget.series OR widget.controller
    final List<dynamic> allPoints;
    if (widget.controller != null) {
      // ChartController Direct mode: get points from controller
      final controllerData = widget.controller!.getAllSeries();
      allPoints = controllerData.values.expand((points) => points).toList();
    } else {
      // Normal mode: get points from widget.series
      allPoints = widget.series.expand((s) => s.points).toList();
    }

    if (allPoints.isEmpty) {
      // No initial data - will be initialized when first point arrives
      return;
    }

    // Initialize with first point, then update with rest
    final firstPoint = allPoints.first;
    _cachedDataXMin = firstPoint.x;
    _cachedDataXMax = firstPoint.x;
    _cachedDataYMin = firstPoint.y;
    _cachedDataYMax = firstPoint.y;

    // Update with remaining points
    for (final point in allPoints.skip(1)) {
      _updateCachedDataBounds(point.x, point.y);
    }

    debugPrint('📊 Initialized cached bounds from ${allPoints.length} points: '
        'X=[$_cachedDataXMin, $_cachedDataXMax], Y=[$_cachedDataYMin, $_cachedDataYMax]');
  }

  /// Auto-scrolls the viewport to show the latest data.
  void _autoScrollToLatest() {
    final renderBox = _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
    if (renderBox == null) return;

    // NOTE: We don't call updateDataBounds() here anymore because:
    // 1. The sliding window in _rebuildElements() already calculated correct bounds
    // 2. Calling updateDataBounds() with all historical data causes bounds explosion
    // 3. The pan operation below is sufficient to follow latest data

    // Removed excessive debugPrint (auto-scrolling viewport)

    // Pan right every time to follow the data
    final panAmount = renderBox.size.width * 0.02; // 2% per update
    renderBox.panChart(panAmount, 0.0);
  }

  /// Jumps the viewport to show the latest data after resume.
  ///
  /// This is called when streaming resumes to ensure the user sees the
  /// most recent data immediately. The viewport smoothly animates back
  /// to the "tip" of the data stream.
  void _jumpToLatestData() {
    // Schedule for next frame to ensure data is applied
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final renderBox = _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
      if (renderBox == null) {
        // Keep this warning - it's important
        debugPrint('⚠️  Cannot jump to latest: renderBox not found');
        return;
      }

      // Reset the viewport transform to original (identity transform)
      // This effectively "jumps" back to showing the sliding window bounds
      // Removed excessive debugPrint (resetting viewport)

      // Reset view to show original bounds (which are now the sliding window)
      renderBox.resetView();

      // Trigger rebuild with sliding window bounds (viewportMode changed to followLatest)
      setState(() {
        _rebuildElements();
      });

      // Removed excessive debugPrint (viewport reset)
    });
  }

  @override
  Widget build(BuildContext context) {
    // Removed excessive debugPrint (build called)
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
                // Removed excessive debugPrint (focus requested via mouse enter)
              }
            },
            // Unfocus when mouse exits this chart
            onExit: (_) {
              if (_focusNode.hasFocus) {
                _focusNode.unfocus();
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
                        tooltipsEnabled: widget.interactionConfig?.tooltip.enabled ?? true,
                        showXScrollbar: widget.showXScrollbar,
                        showYScrollbar: widget.showYScrollbar,
                        scrollbarTheme: widget.scrollbarTheme,
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
    required this.tooltipsEnabled,
    required this.showXScrollbar,
    required this.showYScrollbar,
    this.scrollbarTheme,
    this.onCursorChange,
  });

  final ChartInteractionCoordinator coordinator;
  final QuadTree spatialIndex;
  final List<ChartElement> Function(ChartTransform)? elementGenerator;
  final int elementGeneratorVersion;
  final chart_axis.Axis? xAxis;
  final chart_axis.Axis? yAxis;
  final ChartTheme? theme;
  final bool tooltipsEnabled;
  final bool showXScrollbar;
  final bool showYScrollbar;
  final ScrollbarConfig? scrollbarTheme;
  final void Function(MouseCursor cursor)? onCursorChange;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return ChartRenderBox(
      coordinator: coordinator,
      elementGenerator: elementGenerator,
      theme: theme,
      tooltipsEnabled: tooltipsEnabled,
      showXScrollbar: showXScrollbar,
      showYScrollbar: showYScrollbar,
      scrollbarTheme: scrollbarTheme,
      onCursorChange: onCursorChange,
    )
      ..setXAxis(xAxis)
      ..setYAxis(yAxis);
  }

  @override
  void updateRenderObject(BuildContext context, ChartRenderBox renderObject) {
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
