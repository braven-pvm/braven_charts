import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/chart_state_config.dart';
import '../models/chart_theme.dart';

/// Loading presentation used by [BravenChartPlus].
class ChartLoadingStateView extends StatelessWidget {
  const ChartLoadingStateView({
    super.key,
    required this.config,
    this.loadingWidget,
    this.chartTheme,
  });

  final ChartLoadingConfig config;
  final Widget? loadingWidget;
  final ChartTheme? chartTheme;

  @override
  Widget build(BuildContext context) {
    final replacement = loadingWidget ?? config.customBuilder?.call(context);
    final isBuiltInSkeleton =
        replacement == null &&
        config.indicator == ChartLoadingIndicator.skeleton;
    final content = replacement ?? _buildConfiguredIndicator(context);

    return Semantics(
      container: true,
      liveRegion: true,
      label: config.semanticLabel,
      child: isBuiltInSkeleton
          ? Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: _ChartSkeleton(
                      style: config.skeletonStyle,
                      chartTheme: chartTheme,
                    ),
                  ),
                  if (config.showMessage && config.message.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildMessage(context),
                  ],
                ],
              ),
            )
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: content,
              ),
            ),
    );
  }

  Widget _buildConfiguredIndicator(BuildContext context) {
    final indicator = switch (config.indicator) {
      ChartLoadingIndicator.skeleton => _ChartSkeleton(
        style: config.skeletonStyle,
        chartTheme: chartTheme,
      ),
      ChartLoadingIndicator.circular => CircularProgressIndicator(
        value: config.progress,
      ),
      ChartLoadingIndicator.linear => SizedBox(
        width: 240,
        child: LinearProgressIndicator(value: config.progress),
      ),
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        indicator,
        if (config.showMessage && config.message.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildMessage(context),
        ],
      ],
    );
  }

  Widget _buildMessage(BuildContext context) => Text(
    config.message,
    maxLines: 3,
    overflow: TextOverflow.ellipsis,
    textAlign: TextAlign.center,
    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      height: 1.5,
    ),
  );
}

/// Empty presentation used by [BravenChartPlus].
class ChartEmptyStateView extends StatelessWidget {
  const ChartEmptyStateView({super.key, required this.config});

  final ChartEmptyStateConfig config;

  @override
  Widget build(BuildContext context) {
    final custom = config.customBuilder?.call(context);
    final semanticLabel =
        config.semanticLabel ??
        [
          config.title,
          config.message,
        ].whereType<String>().where((value) => value.isNotEmpty).join('. ');

    return Semantics(
      container: true,
      label: semanticLabel,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child:
              custom ??
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (config.showIcon) ...[
                      ExcludeSemantics(
                        child: Icon(
                          config.icon,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      config.title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (config.message case final message?
                        when message.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        message,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
        ),
      ),
    );
  }
}

class _ChartSkeleton extends StatefulWidget {
  const _ChartSkeleton({required this.style, this.chartTheme});

  final ChartLoadingSkeletonStyle style;
  final ChartTheme? chartTheme;

  @override
  State<_ChartSkeleton> createState() => _ChartSkeletonState();
}

class _ChartSkeletonState extends State<_ChartSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  Duration get _animationDuration =>
      widget.style.animationDuration > Duration.zero
      ? widget.style.animationDuration
      : const Duration(milliseconds: 2400);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _animationDuration,
    );
  }

  @override
  void didUpdateWidget(_ChartSkeleton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.style.animationDuration != widget.style.animationDuration) {
      _controller.duration = _animationDuration;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animationsDisabled =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (animationsDisabled) {
      _controller
        ..stop()
        ..value = 0.28;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final chartColors = widget.chartTheme?.seriesTheme.colors;
    final seriesColor =
        widget.style.seriesColor ??
        chartColors?.firstOrNull ??
        colorScheme.primary;
    final secondarySeriesColor =
        widget.style.secondarySeriesColor ??
        (chartColors != null && chartColors.length > 1
            ? chartColors[1]
            : colorScheme.tertiary);
    final gridColor =
        widget.style.gridColor ??
        widget.chartTheme?.gridStyle.majorColor ??
        colorScheme.outlineVariant;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final responsiveWidth = availableWidth <= 600
            ? availableWidth
            : availableWidth * widget.style.widthFactor;
        final heightBoundWidth = constraints.maxHeight.isFinite
            ? constraints.maxHeight * widget.style.aspectRatio
            : double.infinity;
        final width = math.min(
          widget.style.maxWidth,
          math.min(responsiveWidth, heightBoundWidth),
        );

        return SizedBox(
          width: width,
          child: AspectRatio(
            aspectRatio: widget.style.aspectRatio,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(
                painter: _ChartSkeletonPainter(
                  phase: _controller.value,
                  gridColor: gridColor,
                  seriesColor: seriesColor,
                  secondarySeriesColor: secondarySeriesColor,
                  motionIntensity: widget.style.motionIntensity,
                  showSecondaryTrace: widget.style.showSecondaryTrace,
                  showGrid: widget.style.showGrid,
                  edgeFadeFraction: widget.style.edgeFadeFraction,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ChartSkeletonPainter extends CustomPainter {
  const _ChartSkeletonPainter({
    required this.phase,
    required this.gridColor,
    required this.seriesColor,
    required this.secondarySeriesColor,
    required this.motionIntensity,
    required this.showSecondaryTrace,
    required this.showGrid,
    required this.edgeFadeFraction,
  });

  final double phase;
  final Color gridColor;
  final Color seriesColor;
  final Color secondarySeriesColor;
  final double motionIntensity;
  final bool showSecondaryTrace;
  final bool showGrid;
  final double edgeFadeFraction;

  @override
  void paint(Canvas canvas, Size size) {
    final left = size.width * 0.08;
    final right = size.width * 0.96;
    final top = size.height * 0.08;
    final bottom = size.height * 0.88;
    final chartRect = Rect.fromLTRB(left, top, right, bottom);
    if (edgeFadeFraction > 0) {
      canvas.saveLayer(chartRect, Paint());
    }

    if (showGrid) {
      final gridPaint = Paint()
        ..color = gridColor.withValues(alpha: 0.75)
        ..strokeWidth = 1;

      for (var i = 0; i <= 4; i++) {
        final y = top + ((bottom - top) * i / 4);
        canvas.drawLine(Offset(left, y), Offset(right, y), gridPaint);
      }
      for (var i = 0; i <= 6; i++) {
        final x = left + ((right - left) * i / 6);
        canvas.drawLine(Offset(x, top), Offset(x, bottom), gridPaint);
      }

      final axisPaint = Paint()
        ..color = gridColor
        ..strokeWidth = 1.5;
      canvas.drawLine(Offset(left, top), Offset(left, bottom), axisPaint);
      canvas.drawLine(Offset(left, bottom), Offset(right, bottom), axisPaint);
    }

    if (showSecondaryTrace) {
      final secondaryLine = Path();
      const secondaryPointCount = 24;
      for (var i = 0; i < secondaryPointCount; i++) {
        final progress = i / (secondaryPointCount - 1);
        final movingProgress = progress + (phase * 0.72) + 0.18;
        final normalizedY =
            0.57 +
            (motionIntensity *
                0.10 *
                math.sin(movingProgress * math.pi * 2 * 1.6)) +
            (motionIntensity *
                0.045 *
                math.sin((movingProgress * math.pi * 2 * 2.7) + 1.4));
        final point = Offset(
          left + ((right - left) * progress),
          top + ((bottom - top) * normalizedY.clamp(0.18, 0.86)),
        );
        if (i == 0) {
          secondaryLine.moveTo(point.dx, point.dy);
        } else {
          secondaryLine.lineTo(point.dx, point.dy);
        }
      }
      final secondaryPaint = Paint()
        ..color = secondarySeriesColor.withValues(alpha: 0.20)
        ..strokeWidth = math.max(1.5, size.shortestSide * 0.008)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(secondaryLine, secondaryPaint);
    }

    final line = Path();
    const pointCount = 28;
    Offset? endpoint;
    for (var i = 0; i < pointCount; i++) {
      final progress = i / (pointCount - 1);
      final movingProgress = progress + phase;
      final normalizedY =
          0.5 +
          (motionIntensity *
              0.17 *
              math.sin(movingProgress * math.pi * 2 * 1.25)) +
          (motionIntensity *
              0.08 *
              math.sin((movingProgress * math.pi * 2 * 3.1) + 0.8));
      final point = Offset(
        left + ((right - left) * progress),
        top + ((bottom - top) * normalizedY.clamp(0.16, 0.84)),
      );
      if (i == 0) {
        line.moveTo(point.dx, point.dy);
      } else {
        line.lineTo(point.dx, point.dy);
      }
      endpoint = point;
    }

    final area = Path.from(line)
      ..lineTo(right, bottom)
      ..lineTo(left, bottom)
      ..close();
    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          seriesColor.withValues(alpha: 0.14),
          seriesColor.withValues(alpha: 0.015),
        ],
      ).createShader(chartRect)
      ..style = PaintingStyle.fill;
    canvas.drawPath(area, areaPaint);

    final seriesPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          seriesColor.withValues(alpha: 0.38),
          seriesColor.withValues(alpha: 0.82),
        ],
      ).createShader(chartRect)
      ..strokeWidth = math.max(2, size.shortestSide * 0.012)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(line, seriesPaint);

    final scanX = left + ((right - left) * phase);
    final scanWidth = math.max(28.0, size.width * 0.08);
    final scanRect = Rect.fromLTRB(
      scanX - scanWidth,
      top,
      scanX + scanWidth,
      bottom,
    );
    final scanPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          seriesColor.withValues(alpha: 0),
          seriesColor.withValues(alpha: 0.04 + (motionIntensity * 0.06)),
          seriesColor.withValues(alpha: 0),
        ],
      ).createShader(scanRect);
    canvas
      ..save()
      ..clipRect(chartRect)
      ..drawRect(scanRect, scanPaint)
      ..restore();

    final pathMetric = line.computeMetrics().first;
    final signalProgress = (phase * 1.35) % 1;
    final signal = pathMetric.getTangentForOffset(
      pathMetric.length * signalProgress,
    );
    if (signal != null) {
      final signalHalo = Paint()..color = seriesColor.withValues(alpha: 0.16);
      final signalDot = Paint()..color = seriesColor.withValues(alpha: 0.88);
      canvas.drawCircle(signal.position, 5 + (motionIntensity * 2), signalHalo);
      canvas.drawCircle(signal.position, 2.5, signalDot);
    }

    final pulse = (math.sin(phase * math.pi * 4) + 1) / 2;
    final haloPaint = Paint()
      ..color = seriesColor.withValues(alpha: 0.12 + (pulse * 0.10));
    final dotPaint = Paint()..color = seriesColor.withValues(alpha: 0.92);
    canvas.drawCircle(endpoint!, 6 + (pulse * 3), haloPaint);
    canvas.drawCircle(endpoint, 3, dotPaint);

    if (edgeFadeFraction > 0) {
      final edgeMask = Paint()
        ..shader = LinearGradient(
          colors: const [
            Colors.transparent,
            Colors.white,
            Colors.white,
            Colors.transparent,
          ],
          stops: [0, edgeFadeFraction, 1 - edgeFadeFraction, 1],
        ).createShader(chartRect)
        ..blendMode = BlendMode.dstIn;
      canvas
        ..drawRect(chartRect, edgeMask)
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_ChartSkeletonPainter oldDelegate) =>
      oldDelegate.phase != phase ||
      oldDelegate.gridColor != gridColor ||
      oldDelegate.seriesColor != seriesColor ||
      oldDelegate.secondarySeriesColor != secondarySeriesColor ||
      oldDelegate.motionIntensity != motionIntensity ||
      oldDelegate.showSecondaryTrace != showSecondaryTrace ||
      oldDelegate.showGrid != showGrid ||
      oldDelegate.edgeFadeFraction != edgeFadeFraction;
}
