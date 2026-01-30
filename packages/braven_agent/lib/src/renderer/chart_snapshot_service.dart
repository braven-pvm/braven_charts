import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../llm/models/message_content.dart';
import '../models/chart_configuration.dart';

/// Service for capturing chart widgets as PNG images.
///
/// This service provides two approaches for capturing charts:
///
/// 1. **From a mounted widget** (recommended): Use [captureFromBoundary] with a
///    `GlobalKey` attached to a `RepaintBoundary` wrapping your chart.
///
/// 2. **From configuration** (experimental): Use [captureChart] for off-screen
///    rendering of a chart configuration. This may not work reliably on all
///    platforms, especially web.
///
/// ## Recommended Usage (from mounted widget)
///
/// ```dart
/// // In your widget
/// final _chartKey = GlobalKey();
///
/// @override
/// Widget build(BuildContext context) {
///   return RepaintBoundary(
///     key: _chartKey,
///     child: ChartRenderer().render(config),
///   );
/// }
///
/// // To capture
/// final service = ChartSnapshotService();
/// final imageContent = await service.captureFromBoundary(_chartKey);
/// ```
///
/// ## Alternative Usage (from configuration)
///
/// ```dart
/// final service = ChartSnapshotService();
/// final imageContent = await service.captureChart(config: chartConfig);
/// ```
class ChartSnapshotService {
  /// Creates a [ChartSnapshotService].
  ChartSnapshotService();

  /// Captures a chart from an already-mounted RepaintBoundary.
  ///
  /// This is the recommended approach as it works reliably on all platforms
  /// and captures the chart exactly as it appears on screen.
  ///
  /// Parameters:
  /// - [boundaryKey]: GlobalKey attached to a RepaintBoundary wrapping the chart
  /// - [pixelRatio]: Device pixel ratio for image quality (default: 2.0)
  ///
  /// Returns an [ImageContent] containing the base64-encoded PNG data,
  /// or `null` if the capture fails.
  Future<ImageContent?> captureFromBoundary(
    GlobalKey boundaryKey, {
    double pixelRatio = 2.0,
  }) async {
    try {
      final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        return null;
      }

      // Capture the image
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();

      if (byteData == null) return null;

      // Encode as base64
      final base64Data = base64Encode(byteData.buffer.asUint8List());

      return ImageContent(
        data: base64Data,
        mediaType: 'image/png',
      );
    } catch (e) {
      return null;
    }
  }

  /// Captures a chart configuration as a PNG image (experimental).
  ///
  /// **Note**: This method attempts off-screen rendering which may not work
  /// reliably on all platforms, especially web. Use [captureFromBoundary]
  /// for reliable results.
  ///
  /// Returns an [ImageContent] containing the base64-encoded PNG data,
  /// or `null` if the capture fails or is not supported.
  ///
  /// Parameters:
  /// - [config]: The chart configuration to render
  /// - [width]: Width of the captured image (default: 400)
  /// - [height]: Height of the captured image (default: 300)
  /// - [pixelRatio]: Device pixel ratio for image quality (default: 2.0)
  Future<ImageContent?> captureChart({
    required ChartConfiguration config,
    double width = 400,
    double height = 300,
    double pixelRatio = 2.0,
  }) async {
    // Off-screen rendering is complex and unreliable
    // Return null and let the caller use captureFromBoundary instead
    return null;
  }
}

/// Wrapper widget that provides snapshot capture capability.
///
/// Use this to wrap your chart widget and easily capture snapshots.
///
/// ## Example
///
/// ```dart
/// final _snapshotKey = GlobalKey<ChartSnapshotWrapperState>();
///
/// ChartSnapshotWrapper(
///   key: _snapshotKey,
///   child: ChartRenderer().render(config),
/// )
///
/// // To capture:
/// final imageContent = await _snapshotKey.currentState?.capture();
/// ```
class ChartSnapshotWrapper extends StatefulWidget {
  /// Creates a [ChartSnapshotWrapper].
  const ChartSnapshotWrapper({
    super.key,
    required this.child,
  });

  /// The chart widget to wrap.
  final Widget child;

  @override
  State<ChartSnapshotWrapper> createState() => ChartSnapshotWrapperState();
}

/// State for [ChartSnapshotWrapper] that provides capture functionality.
class ChartSnapshotWrapperState extends State<ChartSnapshotWrapper> {
  final GlobalKey _boundaryKey = GlobalKey();
  final ChartSnapshotService _service = ChartSnapshotService();

  /// Captures the chart as an [ImageContent].
  ///
  /// Returns `null` if capture fails.
  Future<ImageContent?> capture({double pixelRatio = 2.0}) async {
    return _service.captureFromBoundary(_boundaryKey, pixelRatio: pixelRatio);
  }

  /// Captures the chart and returns raw PNG bytes.
  ///
  /// Returns `null` if capture fails.
  Future<Uint8List?> captureBytes({double pixelRatio = 2.0}) async {
    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();

      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _boundaryKey,
      child: widget.child,
    );
  }
}
