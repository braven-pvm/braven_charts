// Copyright (c) 2025 braven_charts. All rights reserved.
// BravenChartPlus - Integration of Prototype Interaction System
// NO REFERENCES TO lib/src - COMPLETELY ISOLATED

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../axis/axis.dart' as chart_axis;
import '../axis/axis_config.dart';
import '../coordinates/chart_transform.dart';
import '../elements/annotation_elements.dart';
import '../interaction/core/chart_element.dart';
import '../interaction/core/coordinator.dart';
import '../interaction/recognizers/priority_pan_recognizer.dart';
import '../interaction/recognizers/priority_tap_recognizer.dart';
import '../models/chart_annotation.dart';
import '../models/chart_series.dart';
import '../models/chart_theme.dart';
import '../models/chart_type.dart';
import '../rendering/chart_render_box.dart';
import '../rendering/spatial_index.dart';
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

    _rebuildElements();
  }

  @override
  void didUpdateWidget(BravenChartPlus oldWidget) {
    super.didUpdateWidget(oldWidget);
    debugPrint('🔄 didUpdateWidget: seriesChanged=${widget.series != oldWidget.series}, themeChanged=${widget.theme != oldWidget.theme}');
    debugPrint('   oldTheme seriesColors: ${oldWidget.theme?.seriesColors}');
    debugPrint('   newTheme seriesColors: ${widget.theme?.seriesColors}');
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
    _coordinator.removeListener(_onCoordinatorChanged);
    _coordinator.dispose();
    _panRecognizer.dispose();
    _tapRecognizer.dispose();
    super.dispose();
  }

  void _rebuildElements() {
    debugPrint('📋 _rebuildElements called');
    debugPrint('   Current theme: ${widget.theme}');
    debugPrint('   Theme seriesColors: ${widget.theme?.seriesColors}');

    _spatialIndex.clear();

    // Compute data bounds from all series
    final dataBounds = DataConverter.computeDataBounds(widget.series);

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

    // Create element generator function
    // This will be called by ChartRenderBox during zoom/pan to regenerate elements
    _elementGenerator = (ChartTransform transform) {
      final seriesIds = widget.series.map((s) => s.id).join(', ');
      debugPrint('🔧 Element generator executing for series: [$seriesIds]');
      
      // Generate series elements and convert to mutable list
      final elements = DataConverter.seriesToElements(
        series: widget.series, 
        transform: transform, 
        theme: widget.theme, 
        strokeWidth: 2.0,
      ).cast<ChartElement>().toList();
      
      // Convert annotations to elements
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
          };
          elements.add(element);
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
