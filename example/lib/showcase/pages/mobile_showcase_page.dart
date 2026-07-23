// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;

import '../widgets/braven_brand.dart';
import '../widgets/chart_type_catalog.dart';

/// A phone-first introduction to every Braven Charts family.
///
/// The desktop showcase is intentionally dense and exploratory. This surface
/// instead mounts one focused chart at a time, uses touch-sized family
/// selectors, and keeps each example close to a typical mobile product use
/// case.
class MobileShowcasePage extends StatefulWidget {
  const MobileShowcasePage({
    super.key,
    this.initialChartSlug,
    this.onChartTypeSelected,
  });

  final String? initialChartSlug;
  final ValueChanged<String>? onChartTypeSelected;

  @override
  State<MobileShowcasePage> createState() => _MobileShowcasePageState();
}

class _MobileShowcasePageState extends State<MobileShowcasePage> {
  final ScrollController _chartTypeScrollController = ScrollController();
  late int _selectedIndex;
  _MobileVisualStyle _visualStyle = _MobileVisualStyle.vivid;
  _MobileChartChrome _chartChrome = _MobileChartChrome.clean;
  _MobileTouchMode _touchMode = _MobileTouchMode.detailsAndSelection;

  @override
  void initState() {
    super.initState();
    _selectedIndex = _indexForSlug(widget.initialChartSlug);
    _scheduleSelectedChartTypeVisibility(animate: false);
  }

  @override
  void didUpdateWidget(covariant MobileShowcasePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialChartSlug == widget.initialChartSlug) return;
    final nextIndex = _indexForSlug(widget.initialChartSlug);
    if (nextIndex != _selectedIndex) {
      _selectedIndex = nextIndex;
      _scheduleSelectedChartTypeVisibility(animate: true);
    }
  }

  int _indexForSlug(String? slug) {
    final index = showcaseChartTypes.indexWhere((entry) => entry.slug == slug);
    return index < 0 ? 0 : index;
  }

  void _selectChartType(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    _scheduleSelectedChartTypeVisibility(animate: true);
    widget.onChartTypeSelected?.call(showcaseChartTypes[index].slug);
  }

  void _selectVisualStyle(_MobileVisualStyle style) {
    if (style == _visualStyle) return;
    setState(() => _visualStyle = style);
  }

  void _selectChartChrome(_MobileChartChrome chrome) {
    if (chrome == _chartChrome) return;
    setState(() => _chartChrome = chrome);
  }

  void _selectTouchMode(_MobileTouchMode mode) {
    if (mode == _touchMode) return;
    setState(() => _touchMode = mode);
  }

  void _scheduleSelectedChartTypeVisibility({required bool animate}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_chartTypeScrollController.hasClients) return;
      final position = _chartTypeScrollController.position;
      final target = (_selectedIndex * 208.0).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      if (animate) {
        _chartTypeScrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      } else {
        _chartTypeScrollController.jumpTo(target);
      }
    });
  }

  @override
  void dispose() {
    _chartTypeScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chartType = showcaseChartTypes[_selectedIndex];
    final scheme = Theme.of(context).colorScheme;
    final examples = _mobileExamples(chartType.slug, _visualStyle);

    return Scaffold(
      key: const ValueKey('mobile-showcase'),
      appBar: AppBar(
        title: const BravenBrand(markSize: 34),
        scrolledUnderElevation: 1,
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Charts for Flutter',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Choose a chart type, pick a look, then scroll through purpose-built mobile examples.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Chart types',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                key: const ValueKey('mobile-chart-type-strip'),
                height: 148,
                child: ListView.separated(
                  controller: _chartTypeScrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: showcaseChartTypes.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final entry = showcaseChartTypes[index];
                    return _MobileChartTypeButton(
                      key: ValueKey('mobile-chart-type-${entry.slug}'),
                      chartType: entry,
                      selected: index == _selectedIndex,
                      onPressed: () => _selectChartType(index),
                    );
                  },
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Style',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _MobileStyleSelector(
                      selected: _visualStyle,
                      onSelected: _selectVisualStyle,
                    ),
                    const SizedBox(height: 16),
                    _MobileBehaviorSelector(
                      chartChrome: _chartChrome,
                      touchMode: _touchMode,
                      onChartChromeSelected: _selectChartChrome,
                      onTouchModeSelected: _selectTouchMode,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                chartType.label,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _touchMode.description,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${examples.length} examples',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              sliver: SliverList.separated(
                key: ValueKey('mobile-chart-list-${chartType.slug}'),
                itemCount: examples.length,
                separatorBuilder: (_, _) => const SizedBox(height: 16),
                itemBuilder: (context, index) => _MobileChartEntrance(
                  key: ValueKey(
                    'mobile-chart-entrance-${chartType.slug}-${_visualStyle.name}-$index',
                  ),
                  delay: Duration(milliseconds: index * 70),
                  child: _MobileChartCard(
                    key: ValueKey('mobile-chart-card-${chartType.slug}-$index'),
                    chartType: chartType,
                    example: examples[index],
                    visualStyle: _visualStyle,
                    chartChrome: _chartChrome,
                    touchMode: _touchMode,
                    index: index,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileChartTypeButton extends StatelessWidget {
  const _MobileChartTypeButton({
    super.key,
    required this.chartType,
    required this.selected,
    required this.onPressed,
  });

  final ShowcaseChartType chartType;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final surface = selected
        ? Color.alphaBlend(
            chartType.accent.withValues(alpha: 0.10),
            scheme.surface,
          )
        : scheme.surfaceContainerLow;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: selected ? chartType.accent : scheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: 196,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: selected ? 0.34 : 0.24,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 28),
                      child: _MobileChartBackdrop(chartType: chartType),
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        surface.withValues(alpha: 0.12),
                        surface.withValues(alpha: 0.88),
                        surface,
                      ],
                      stops: const [0, 0.38, 0.68, 0.82],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _mobileChartIcon(chartType),
                            size: 19,
                            color: chartType.accent,
                          ),
                          const Spacer(),
                          if (selected)
                            Icon(
                              Icons.check_circle,
                              size: 19,
                              color: chartType.accent,
                            ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        chartType.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: selected ? chartType.accent : scheme.onSurface,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _mobileChartTypeSummary(chartType),
                        maxLines: 2,
                        overflow: TextOverflow.fade,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _mobileChartTypeSummary(ShowcaseChartType chartType) =>
    switch (chartType.slug) {
      'line-charts' => 'Trends and forecasts',
      'area-charts' => 'Magnitude and composition',
      'range-area-charts' => 'Intervals and uncertainty',
      'bar-charts' => 'Categories and comparisons',
      'scatter-charts' => 'Relationships and density',
      'candlestick-charts' => 'Open, high, low, and close',
      'pie-charts' => 'Contribution to a whole',
      'donut-charts' => 'Contribution with center context',
      'concentric-donut' => 'Independent nested rings',
      'polar-column' => 'Radial category comparisons',
      _ => chartType.summary,
    };

class _MobileChartBackdrop extends StatelessWidget {
  const _MobileChartBackdrop({required this.chartType});

  final ShowcaseChartType chartType;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _MobileChartBackdropPainter(chartType),
    size: Size.infinite,
  );
}

class _MobileChartBackdropPainter extends CustomPainter {
  const _MobileChartBackdropPainter(this.chartType);

  final ShowcaseChartType chartType;

  @override
  void paint(Canvas canvas, Size size) {
    final color = chartType.accent;
    final plot = Rect.fromLTWH(4, 4, size.width - 8, size.height - 8);
    final grid = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var index = 1; index < 4; index++) {
      final x = plot.left + plot.width * index / 4;
      canvas.drawLine(Offset(x, plot.top), Offset(x, plot.bottom), grid);
    }
    for (var index = 1; index < 3; index++) {
      final y = plot.top + plot.height * index / 3;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
    }
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = color.withValues(alpha: 0.34)
      ..style = PaintingStyle.fill;

    if (chartType.slug == 'range-area-charts') {
      const upperValues = [0.35, 0.52, 0.44, 0.70, 0.62];
      const lowerValues = [0.64, 0.78, 0.66, 0.86, 0.76];
      final upper = _wavePath(size, upperValues);
      final lower = _wavePath(size, lowerValues);
      final band = Path();
      for (var index = 0; index < upperValues.length; index++) {
        final point = _normalizedPoint(size, upperValues, index);
        if (index == 0) {
          band.moveTo(point.dx, point.dy);
        } else {
          band.lineTo(point.dx, point.dy);
        }
      }
      for (var index = lowerValues.length - 1; index >= 0; index--) {
        final point = _normalizedPoint(size, lowerValues, index);
        band.lineTo(point.dx, point.dy);
      }
      band.close();
      canvas.drawPath(band, fill);
      canvas.drawPath(upper, stroke);
      canvas.drawPath(lower, stroke);
      return;
    }

    switch (chartType.type) {
      case ChartType.line:
        canvas.drawPath(
          _wavePath(size, const [0.58, 0.68, 0.42, 0.50, 0.28, 0.34]),
          stroke
            ..color = color.withValues(alpha: 0.46)
            ..strokeWidth = 2,
        );
        canvas.drawPath(
          _wavePath(size, const [0.72, 0.42, 0.58, 0.25, 0.38, 0.14]),
          stroke
            ..color = color
            ..strokeWidth = 2.8,
        );
        break;
      case ChartType.area:
        final path = _wavePath(size, const [0.74, 0.54, 0.60, 0.32, 0.40, 0.18])
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(
          _wavePath(size, const [0.74, 0.54, 0.60, 0.32, 0.40, 0.18]),
          stroke,
        );
        break;
      case ChartType.bar:
        const values = [0.70, 0.43, 0.62, 0.28, 0.51, 0.18];
        final barWidth = size.width / 15;
        for (var index = 0; index < values.length; index++) {
          final left = 6 + index * barWidth * 2.35;
          final top = size.height * values[index];
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTRB(left, top, left + barWidth, size.height),
              const Radius.circular(3),
            ),
            fill,
          );
        }
        break;
      case ChartType.scatter:
        const points = [
          Offset(0.12, 0.78),
          Offset(0.21, 0.66),
          Offset(0.30, 0.70),
          Offset(0.38, 0.52),
          Offset(0.48, 0.58),
          Offset(0.58, 0.38),
          Offset(0.68, 0.45),
          Offset(0.78, 0.24),
          Offset(0.88, 0.30),
        ];
        for (var index = 0; index < points.length; index++) {
          final point = points[index];
          canvas.drawCircle(
            Offset(size.width * point.dx, size.height * point.dy),
            index.isEven ? 5 : 3.5,
            fill..color = color.withValues(alpha: index.isEven ? 0.56 : 0.30),
          );
        }
        break;
      case ChartType.candlestick:
        const values = [0.62, 0.48, 0.55, 0.31, 0.39];
        final step = size.width / values.length;
        for (var index = 0; index < values.length; index++) {
          final x = step * (index + 0.5);
          final center = size.height * values[index];
          canvas.drawLine(
            Offset(x, center - 22),
            Offset(x, center + 24),
            stroke..strokeWidth = 2,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset(x, center),
                width: step * 0.45,
                height: 22,
              ),
              const Radius.circular(2),
            ),
            index.isEven ? fill : stroke,
          );
        }
        break;
      case ChartType.pie:
      case ChartType.donut:
      case ChartType.polarColumn:
        final center = Offset(size.width * 0.54, size.height * 0.50);
        final radius = size.shortestSide * 0.34;
        final radialStroke = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * 0.38
          ..strokeCap = StrokeCap.round;
        const sweeps = [0.28, 0.20, 0.32, 0.16];
        var start = -math.pi / 2;
        for (var index = 0; index < sweeps.length; index++) {
          final sweep = math.pi * 2 * sweeps[index];
          final arcColor = color.withValues(alpha: 0.46 + index * 0.12);
          if (chartType.type == ChartType.pie) {
            canvas.drawArc(
              Rect.fromCircle(center: center, radius: radius),
              start,
              sweep - 0.06,
              true,
              fill..color = arcColor,
            );
          } else {
            final effectiveRadius = chartType.type == ChartType.polarColumn
                ? radius * (0.62 + index * 0.13)
                : radius;
            canvas.drawArc(
              Rect.fromCircle(center: center, radius: effectiveRadius),
              start,
              sweep - 0.10,
              false,
              radialStroke
                ..strokeWidth = radius * 0.38
                ..color = arcColor,
            );
            if (chartType.slug == 'concentric-donut') {
              canvas.drawArc(
                Rect.fromCircle(center: center, radius: effectiveRadius * 0.64),
                start + 0.18,
                sweep - 0.20,
                false,
                radialStroke
                  ..strokeWidth = radius * 0.22
                  ..color = arcColor.withValues(alpha: 0.72),
              );
            }
          }
          start += sweep;
        }
        break;
    }
  }

  Path _wavePath(Size size, List<double> normalizedY) {
    final path = Path();
    for (var index = 0; index < normalizedY.length; index++) {
      final point = _normalizedPoint(size, normalizedY, index);
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path;
  }

  Offset _normalizedPoint(Size size, List<double> values, int index) => Offset(
    size.width * index / (values.length - 1),
    size.height * values[index],
  );

  @override
  bool shouldRepaint(covariant _MobileChartBackdropPainter oldDelegate) =>
      oldDelegate.chartType.slug != chartType.slug ||
      oldDelegate.chartType.accent != chartType.accent;
}

enum _MobileVisualStyle { vivid, midnight, calm, ocean, ember, graphite }

enum _MobileChartChrome { clean, axes }

enum _MobileTouchMode { details, selection, detailsAndSelection, static }

extension on _MobileVisualStyle {
  bool get isDark =>
      this == _MobileVisualStyle.midnight ||
      this == _MobileVisualStyle.graphite;

  String get label => switch (this) {
    _MobileVisualStyle.vivid => 'Vivid',
    _MobileVisualStyle.midnight => 'Midnight',
    _MobileVisualStyle.calm => 'Calm',
    _MobileVisualStyle.ocean => 'Ocean',
    _MobileVisualStyle.ember => 'Ember',
    _MobileVisualStyle.graphite => 'Graphite',
  };
}

extension on _MobileChartChrome {
  String get label => switch (this) {
    _MobileChartChrome.clean => 'Clean',
    _MobileChartChrome.axes => 'Axes',
  };
}

extension on _MobileTouchMode {
  String get label => switch (this) {
    _MobileTouchMode.details => 'Details',
    _MobileTouchMode.selection => 'Select',
    _MobileTouchMode.detailsAndSelection => 'Both',
    _MobileTouchMode.static => 'Static',
  };

  String get description => switch (this) {
    _MobileTouchMode.details => 'Tap any mark for its data-point details.',
    _MobileTouchMode.selection => 'Tap marks to create a durable selection.',
    _MobileTouchMode.detailsAndSelection =>
      'Tap marks for details and selection.',
    _MobileTouchMode.static => 'All chart interaction is disabled.',
  };

  String get cardHint => switch (this) {
    _MobileTouchMode.details => 'Tap a mark for details',
    _MobileTouchMode.selection => 'Tap a mark to select',
    _MobileTouchMode.detailsAndSelection => 'Tap for details and selection',
    _MobileTouchMode.static => 'Static presentation',
  };

  IconData get icon => switch (this) {
    _MobileTouchMode.details => Icons.info_outline,
    _MobileTouchMode.selection => Icons.touch_app_outlined,
    _MobileTouchMode.detailsAndSelection => Icons.ads_click_outlined,
    _MobileTouchMode.static => Icons.lock_outline,
  };

  InteractionConfig get interactionConfig => switch (this) {
    _MobileTouchMode.details => InteractionConfig.tap(enableSelection: false),
    _MobileTouchMode.selection => InteractionConfig.tap(enableTooltip: false),
    _MobileTouchMode.detailsAndSelection => InteractionConfig.tap(),
    _MobileTouchMode.static => InteractionConfig.none(),
  };
}

class _MobileStyleSelector extends StatelessWidget {
  const _MobileStyleSelector({
    required this.selected,
    required this.onSelected,
  });

  final _MobileVisualStyle selected;
  final ValueChanged<_MobileVisualStyle> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('mobile-style-selector'),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (index, style) in _MobileVisualStyle.values.indexed) ...[
            if (index > 0) const SizedBox(width: 8),
            SizedBox(
              width: 126,
              child: _MobileStyleTile(
                key: ValueKey('mobile-style-${style.name}'),
                style: style,
                selected: selected == style,
                onPressed: () => onSelected(style),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MobileStyleTile extends StatelessWidget {
  const _MobileStyleTile({
    super.key,
    required this.style,
    required this.selected,
    required this.onPressed,
  });

  final _MobileVisualStyle style;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final presentation = _MobileStylePresentation.resolve(style);
    final selectionColor = presentation.palette.first;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: presentation.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? selectionColor : presentation.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            height: 76,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      for (final color in presentation.palette.take(3))
                        Container(
                          width: 14,
                          height: 14,
                          margin: const EdgeInsets.only(right: 3),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: presentation.border,
                              width: 0.7,
                            ),
                          ),
                        ),
                      const Spacer(),
                      if (selected)
                        Icon(Icons.check, size: 16, color: selectionColor),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    style.label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: selected ? selectionColor : presentation.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileBehaviorSelector extends StatelessWidget {
  const _MobileBehaviorSelector({
    required this.chartChrome,
    required this.touchMode,
    required this.onChartChromeSelected,
    required this.onTouchModeSelected,
  });

  final _MobileChartChrome chartChrome;
  final _MobileTouchMode touchMode;
  final ValueChanged<_MobileChartChrome> onChartChromeSelected;
  final ValueChanged<_MobileTouchMode> onTouchModeSelected;

  Future<void> _showOptions(BuildContext context) {
    final theme = Theme.of(context);
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'View & touch',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose how much chart chrome and touch behavior the examples expose.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Chart chrome',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            _MobileOptionSelector<_MobileChartChrome>(
              key: const ValueKey('mobile-chart-chrome-selector'),
              optionKeyPrefix: 'mobile-chart-chrome',
              values: _MobileChartChrome.values,
              selected: chartChrome,
              labelFor: (value) => value.label,
              onSelected: (value) {
                onChartChromeSelected(value);
                Navigator.pop(sheetContext);
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Chart interaction',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            _MobileOptionSelector<_MobileTouchMode>(
              key: const ValueKey('mobile-touch-mode-selector'),
              optionKeyPrefix: 'mobile-touch-mode',
              values: _MobileTouchMode.values,
              selected: touchMode,
              labelFor: (value) => value.label,
              onSelected: (value) {
                onTouchModeSelected(value);
                Navigator.pop(sheetContext);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MobileSettingTile(
            key: const ValueKey('mobile-view-touch-button'),
            icon: chartChrome == _MobileChartChrome.clean
                ? Icons.crop_free_rounded
                : Icons.grid_4x4_rounded,
            label: 'Chart view',
            value: chartChrome.label,
            onPressed: () => _showOptions(context),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MobileSettingTile(
            key: const ValueKey('mobile-touch-settings-button'),
            icon: touchMode.icon,
            label: 'Touch',
            value: touchMode.label,
            onPressed: () => _showOptions(context),
          ),
        ),
      ],
    );
  }
}

class _MobileSettingTile extends StatelessWidget {
  const _MobileSettingTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          height: 72,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(icon, size: 18, color: scheme.primary),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        value,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileOptionSelector<T> extends StatelessWidget {
  const _MobileOptionSelector({
    super.key,
    required this.optionKeyPrefix,
    required this.values,
    required this.selected,
    required this.labelFor,
    required this.onSelected,
  });

  final String optionKeyPrefix;
  final List<T> values;
  final T selected;
  final String Function(T value) labelFor;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            for (final (index, value) in values.indexed) ...[
              if (index > 0)
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: scheme.outlineVariant,
                ),
              Expanded(
                child: Semantics(
                  selected: selected == value,
                  button: true,
                  child: Material(
                    color: selected == value
                        ? scheme.secondaryContainer
                        : Colors.transparent,
                    child: InkWell(
                      key: ValueKey(
                        '$optionKeyPrefix-${labelFor(value).toLowerCase()}',
                      ),
                      onTap: () => onSelected(value),
                      child: Center(
                        child: Text(
                          labelFor(value),
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: selected == value
                                    ? scheme.onSecondaryContainer
                                    : scheme.onSurfaceVariant,
                                fontWeight: selected == value
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MobileChartEntrance extends StatelessWidget {
  const _MobileChartEntrance({
    super.key,
    required this.delay,
    required this.child,
  });

  final Duration delay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      duration: reduceMotion
          ? Duration.zero
          : Duration(milliseconds: 480 + delay.inMilliseconds),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: 1),
      child: child,
      builder: (context, progress, child) => Opacity(
        opacity: progress,
        child: Transform.translate(
          offset: Offset(0, (1 - progress) * 14),
          child: child,
        ),
      ),
    );
  }
}

class _MobileChartExample {
  const _MobileChartExample({
    required this.title,
    required this.description,
    required this.series,
    this.annotations = const [],
    this.showLegend = false,
    this.grid,
    this.xAxisConfig,
    this.yAxis,
    this.concentricDonutConfig,
    this.polarChartConfig,
    this.chartHeight,
    this.badges = const [],
    this.legendStyle,
    this.radialLegendItemBuilder,
  });

  final String title;
  final String description;
  final List<ChartSeries> series;
  final List<ChartAnnotation> annotations;
  final bool showLegend;
  final GridConfig? grid;
  final XAxisConfig? xAxisConfig;
  final YAxisConfig? yAxis;
  final ConcentricDonutConfig? concentricDonutConfig;
  final PolarChartConfig? polarChartConfig;
  final double? chartHeight;
  final List<String> badges;
  final LegendStyle? legendStyle;
  final RadialLegendItemBuilder? radialLegendItemBuilder;
}

class _MobileStylePresentation {
  const _MobileStylePresentation({
    required this.chartTheme,
    required this.surface,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.border,
    required this.palette,
  });

  final ChartTheme chartTheme;
  final Color surface;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color border;
  final List<Color> palette;

  static _MobileStylePresentation resolve(_MobileVisualStyle style) =>
      switch (style) {
        _MobileVisualStyle.vivid => _MobileStylePresentation(
          chartTheme: ChartTheme.vibrant.copyWith(
            backgroundColor: const Color(0xFFFFFFFF),
          ),
          surface: const Color(0xFFFFFFFF),
          onSurface: const Color(0xFF172033),
          onSurfaceVariant: const Color(0xFF5E687B),
          border: const Color(0xFFD7DCE8),
          palette: const [
            Color(0xFF4F46E5),
            Color(0xFF06B6D4),
            Color(0xFFF97316),
            Color(0xFF8B5CF6),
            Color(0xFF10B981),
          ],
        ),
        _MobileVisualStyle.midnight => _MobileStylePresentation(
          chartTheme: ChartTheme.dark.copyWith(
            backgroundColor: const Color(0xFF0F172A),
          ),
          surface: const Color(0xFF0F172A),
          onSurface: const Color(0xFFF8FAFC),
          onSurfaceVariant: const Color(0xFFB7C3D4),
          border: const Color(0xFF334155),
          palette: const [
            Color(0xFF22D3EE),
            Color(0xFFA78BFA),
            Color(0xFFFBBF24),
            Color(0xFFFB7185),
            Color(0xFF34D399),
          ],
        ),
        _MobileVisualStyle.calm => _MobileStylePresentation(
          chartTheme: ChartTheme.minimal.copyWith(
            backgroundColor: const Color(0xFFFFFDF8),
          ),
          surface: const Color(0xFFFFFDF8),
          onSurface: const Color(0xFF24352F),
          onSurfaceVariant: const Color(0xFF65736D),
          border: const Color(0xFFDCE5DF),
          palette: const [
            Color(0xFF2A9D8F),
            Color(0xFF6574CD),
            Color(0xFFE76F51),
            Color(0xFFE9C46A),
            Color(0xFF4F9DA6),
          ],
        ),
        _MobileVisualStyle.ocean => _MobileStylePresentation(
          chartTheme: ChartTheme.minimal.copyWith(
            backgroundColor: const Color(0xFFF4FBFF),
          ),
          surface: const Color(0xFFF4FBFF),
          onSurface: const Color(0xFF102A43),
          onSurfaceVariant: const Color(0xFF526D82),
          border: const Color(0xFFC9E3F0),
          palette: const [
            Color(0xFF0077B6),
            Color(0xFF00B4D8),
            Color(0xFF48CAE4),
            Color(0xFF023E8A),
            Color(0xFF90E0EF),
          ],
        ),
        _MobileVisualStyle.ember => _MobileStylePresentation(
          chartTheme: ChartTheme.vibrant.copyWith(
            backgroundColor: const Color(0xFFFFF7ED),
          ),
          surface: const Color(0xFFFFF7ED),
          onSurface: const Color(0xFF431407),
          onSurfaceVariant: const Color(0xFF7C4A35),
          border: const Color(0xFFFED7AA),
          palette: const [
            Color(0xFFEA580C),
            Color(0xFFDC2626),
            Color(0xFFF59E0B),
            Color(0xFF9A3412),
            Color(0xFFFB7185),
          ],
        ),
        _MobileVisualStyle.graphite => _MobileStylePresentation(
          chartTheme: ChartTheme.dark.copyWith(
            backgroundColor: const Color(0xFF18181B),
          ),
          surface: const Color(0xFF18181B),
          onSurface: const Color(0xFFFAFAFA),
          onSurfaceVariant: const Color(0xFFD4D4D8),
          border: const Color(0xFF3F3F46),
          palette: const [
            Color(0xFFE4E4E7),
            Color(0xFF22C55E),
            Color(0xFFF59E0B),
            Color(0xFF38BDF8),
            Color(0xFFA1A1AA),
          ],
        ),
      };
}

class _MobileChartCard extends StatelessWidget {
  const _MobileChartCard({
    super.key,
    required this.chartType,
    required this.example,
    required this.visualStyle,
    required this.chartChrome,
    required this.touchMode,
    required this.index,
  });

  final ShowcaseChartType chartType;
  final _MobileChartExample example;
  final _MobileVisualStyle visualStyle;
  final _MobileChartChrome chartChrome;
  final _MobileTouchMode touchMode;
  final int index;

  @override
  Widget build(BuildContext context) {
    final presentation = _MobileStylePresentation.resolve(visualStyle);
    final theme = Theme.of(context);
    final isRadial =
        chartType.type == ChartType.pie ||
        chartType.type == ChartType.donut ||
        chartType.type == ChartType.polarColumn;
    final showAxes = chartChrome == _MobileChartChrome.axes;
    final axisLineColor = presentation.palette[index % 5];
    final axisLabelColor = presentation.palette[(index + 1) % 5];
    final axisTitleColor = presentation.palette[(index + 2) % 5];
    final tickColor = presentation.palette[(index + 3) % 5];
    final horizontalGridColor = presentation.palette[(index + 1) % 5]
        .withValues(alpha: visualStyle.isDark ? 0.24 : 0.16);
    final verticalGridColor = presentation.palette[(index + 3) % 5].withValues(
      alpha: visualStyle.isDark ? 0.20 : 0.12,
    );
    final chartTheme = presentation.chartTheme.copyWith(
      legendStyle: example.legendStyle ?? presentation.chartTheme.legendStyle,
      axisStyle: presentation.chartTheme.axisStyle.copyWith(
        lineColor: axisLineColor,
        lineWidth: index.isEven ? 1.25 : 0.85,
        labelStyle: presentation.chartTheme.axisStyle.labelStyle.copyWith(
          color: axisLabelColor,
          fontSize: 10,
          fontWeight: index.isEven ? FontWeight.w600 : FontWeight.w500,
        ),
        titleStyle: presentation.chartTheme.axisStyle.titleStyle.copyWith(
          color: axisTitleColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        tickColor: tickColor,
        tickLength: 4 + (index % 3).toDouble(),
        tickWidth: index.isEven ? 1.1 : 0.8,
      ),
      gridStyle: presentation.chartTheme.gridStyle.copyWith(
        majorColor: horizontalGridColor,
        majorWidth: index.isEven ? 0.8 : 0.6,
        majorDashPattern: switch (index % 3) {
          1 => const [4, 4],
          2 => const [1.5, 3],
          _ => const [],
        },
      ),
    );
    final xAxisConfig =
        example.xAxisConfig ??
        (isRadial
            ? const XAxisConfig(visible: false)
            : const XAxisConfig(tickCount: 5, showMinorTicks: false));
    final yAxis =
        example.yAxis ??
        (isRadial
            ? YAxisConfig(position: YAxisPosition.hidden)
            : YAxisConfig(
                position: YAxisPosition.left,
                tickCount: 5,
                maxWidth: 48,
                showMinorTicks: false,
              ));
    final styledXAxis = xAxisConfig.copyWith(
      clearColor: true,
      tickLabelPadding: 3 + (index % 3) * 2,
      axisLabelPadding: 4 + ((index + 1) % 3) * 2,
      axisMargin: 5 + (index % 2) * 3,
    );
    final styledYAxis = yAxis.copyWith(
      clearColor: true,
      tickLabelPadding: 3 + ((index + 1) % 3) * 2,
      axisLabelPadding: 4 + (index % 3) * 2,
      axisMargin: 5 + ((index + 1) % 2) * 3,
    );
    final polarConfig =
        example.polarChartConfig ??
        (chartType.type == ChartType.polarColumn
            ? const PolarChartConfig(
                pane: PolarPaneConfig(outerRadiusFactor: 0.98),
                angularAxis: PolarCategoryAxisConfig(
                  innerPadding: 0.14,
                  showLabels: true,
                  showGridLines: false,
                ),
                radialAxis: PolarNumericAxisConfig(
                  showLabels: false,
                  showGridLines: true,
                ),
              )
            : const PolarChartConfig());
    final expandedPolarConfig = polarConfig.copyWith(
      pane: polarConfig.pane.copyWith(outerRadiusFactor: 0.98),
    );
    final effectivePolarConfig = chartType.type != ChartType.polarColumn
        ? expandedPolarConfig
        : !showAxes
        ? expandedPolarConfig.copyWith(
            angularAxis: expandedPolarConfig.angularAxis.copyWith(
              showLabels: false,
              showGridLines: false,
            ),
            radialAxis: expandedPolarConfig.radialAxis.copyWith(
              showLabels: false,
              showGridLines: false,
            ),
          )
        : expandedPolarConfig.copyWith(
            angularAxis: expandedPolarConfig.angularAxis.copyWith(
              showLabels: true,
              showGridLines: index.isEven,
              labelOffset: switch (index % 4) {
                1 => 12,
                2 => 5,
                3 => 9,
                _ => 7,
              },
              labelStyle: PolarLabelStyle(
                color: axisLabelColor,
                fontSize: index.isEven ? 10 : 9,
                fontWeight: FontWeight.w600,
              ),
            ),
            radialAxis: expandedPolarConfig.radialAxis.copyWith(
              showLabels: true,
              showGridLines: true,
              tickCount: index.isEven ? 5 : 4,
              labelPosition: switch (index % 3) {
                1 => PolarRadialLabelPosition.middle,
                2 => PolarRadialLabelPosition.end,
                _ => PolarRadialLabelPosition.start,
              },
              labelAngleOffsetDegrees: switch (index % 4) {
                1 => 8,
                2 => -6,
                3 => 12,
                _ => 0,
              },
              labelOffset: switch (index % 4) {
                1 => 8,
                2 => 2,
                3 => 6,
                _ => 4,
              },
              labelStyle: PolarLabelStyle(
                color: axisTitleColor,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
    final axisGrid =
        example.grid ??
        (isRadial
            ? const GridConfig(horizontal: false, vertical: false)
            : GridConfig(
                horizontal: true,
                vertical: index.isOdd,
                horizontalColor: horizontalGridColor,
                verticalColor: verticalGridColor,
                horizontalStrokeWidth: index.isEven ? 0.8 : 0.6,
                verticalStrokeWidth: index.isEven ? 0.6 : 0.8,
              ));
    final effectiveGrid = !showAxes
        ? const GridConfig(horizontal: false, vertical: false)
        : axisGrid.copyWith(
            horizontalColor: horizontalGridColor,
            verticalColor: verticalGridColor,
            horizontalStrokeWidth: index.isEven ? 0.8 : 0.6,
            verticalStrokeWidth: index.isEven ? 0.6 : 0.8,
          );

    return Material(
      color: presentation.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: presentation.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: presentation.palette[index % 5].withValues(
                      alpha: 0.14,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      _mobileChartIcon(chartType),
                      size: 20,
                      color: presentation.palette[index % 5],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        example.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: presentation.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        example.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: presentation.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (example.badges.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final badge in example.badges)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: presentation.palette[index % 5].withValues(
                          alpha: 0.10,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badge,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: presentation.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              key: ValueKey('mobile-chart-${chartType.slug}-$index'),
              height: example.chartHeight ?? (isRadial ? 286 : 270),
              child: BravenChartPlus(
                series: example.series,
                annotations: example.annotations,
                theme: chartTheme,
                showLegend: example.showLegend,
                legendStyle: example.showLegend
                    ? example.legendStyle ??
                          const LegendStyle(
                            position: LegendPosition.topRight,
                            orientation: LegendOrientation.horizontal,
                            allowDragging: false,
                          )
                    : null,
                radialLegendItemBuilder: example.radialLegendItemBuilder,
                grid: effectiveGrid,
                xAxisConfig: showAxes
                    ? styledXAxis
                    : styledXAxis.copyWith(visible: false),
                yAxis: showAxes
                    ? styledYAxis
                    : styledYAxis.copyWith(visible: false),
                interactionConfig: touchMode.interactionConfig,
                concentricDonutConfig:
                    example.concentricDonutConfig ??
                    (chartType.slug == 'concentric-donut'
                        ? ConcentricDonutConfig(
                            innerRadiusFactor: 0.34,
                            ringGap: 5,
                            centerContent: DonutCenterContent(
                              label: index == 0 ? 'Weeks' : 'Rings',
                              valueMode: DonutCenterValueMode.custom,
                              customValue: index == 0 ? '2' : '${index + 1}',
                            ),
                          )
                        : const ConcentricDonutConfig()),
                polarChartConfig: effectivePolarConfig,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  touchMode.icon,
                  size: 17,
                  color: presentation.palette[index % 5],
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    touchMode.cardHint,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: presentation.onSurfaceVariant,
                    ),
                  ),
                ),
                Icon(
                  Icons.auto_awesome,
                  size: 15,
                  color: presentation.onSurfaceVariant,
                ),
                const SizedBox(width: 5),
                Text(
                  'Animated',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: presentation.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

IconData _mobileChartIcon(ShowcaseChartType chartType) =>
    chartType.slug == 'polar-column' ? Icons.explore_outlined : chartType.icon;

const _mobileExampleCopy = <String, List<(String, String)>>{
  'line-charts': [
    ('Weekly activity', 'One clear trend with friendly tap targets.'),
    ('Plan comparison', 'Current, previous, and target share one scale.'),
    ('Forecast', 'Observed values become a dotted future after now.'),
    (
      'VO₂ stage analysis',
      'Raw signal, stage average, target window, threshold, and glow.',
    ),
  ],
  'area-charts': [
    ('Screen time', 'Daily magnitude with a restrained fill and one scale.'),
    ('Target delta', 'Positive and negative deviation use distinct fills.'),
    ('Demand composition', 'Two filled layers and a plan line stay readable.'),
    (
      'User analytics',
      'Three layered areas and two line metrics form a compact dashboard.',
    ),
  ],
  'range-area-charts': [
    ('Temperature range', 'One low-high band for a compact forecast.'),
    ('Seasonal range', 'A changing weekly envelope preserves both bounds.'),
    ('Forecast fan', 'Nested 50% and 95% intervals frame one centre line.'),
    (
      'Service windows',
      'Stepped intervals preserve explicit missing monitoring windows.',
    ),
  ],
  'bar-charts': [
    ('Daily steps', 'A familiar category comparison for a weekly goal.'),
    ('Medal comparison', 'Overlaid reference and current bars save space.'),
    ('Product survey', 'Five response bands diverge around a neutral centre.'),
    ('Activation score', 'Two lollipop series keep exact values lightweight.'),
  ],
  'scatter-charts': [
    ('Walk pace', 'Individual observations without a connecting line.'),
    ('Market opportunity', 'Position, bubble area, and shape carry meaning.'),
    ('Generated cohorts', 'Three small populations reveal one relationship.'),
    (
      'Pickup density',
      'One concentrated population becomes a compact hexagonal density field.',
    ),
  ],
  'candlestick-charts': [
    ('Price movement', 'A concise open, high, low, and close history.'),
    ('Price and average', 'Candles share the pane with a moving average.'),
    ('Volatility study', 'A range envelope, candles, and trend work together.'),
    (
      'Market session',
      'Twenty sessions reveal swings, gaps, and a steadier close average.',
    ),
  ],
  'pie-charts': [
    ('Monthly spending', 'Four categories contributing to a single total.'),
    (
      'Revenue contribution',
      'Outside labels and connectors suit small slices.',
    ),
    ('Campaign reach', 'A second metric controls each slice radius.'),
    (
      'Support mix',
      'Small request channels group into Other without losing source rows.',
    ),
  ],
  'donut-charts': [
    ('Storage used', 'Part-to-whole values with useful center context.'),
    ('Delivery mix', 'A partial sweep creates a compact progress display.'),
    ('Channel reach', 'Angle shows share while radius shows reach.'),
    (
      'Release readiness',
      'A slim status ring keeps the overall readiness value at its centre.',
    ),
  ],
  'concentric-donut': [
    ('Week comparison', 'Weighted inner and outer rings compare two periods.'),
    (
      'Revenue by period',
      'Aligned categories retain their identity across three independent rings.',
    ),
    (
      'Service portfolio',
      'Unequal ring bands and a partial sweep separate three service domains.',
    ),
    (
      'Goal rings',
      'Four independent completion rings form a compact progress dashboard.',
    ),
  ],
  'polar-column': [
    (
      'Activity rhythm',
      'Category-coloured rose columns reveal a weekly cycle.',
    ),
    (
      'Demand vs capacity',
      'A quiet capacity track sits behind the observed radial values.',
    ),
    ('Regional mix', 'Three grouped series share each category sector.'),
    (
      'Supply balance',
      'Positive supply layers and negative shortfall share a stacked scale.',
    ),
  ],
};

List<_MobileChartExample> _mobileExamples(
  String slug,
  _MobileVisualStyle visualStyle,
) {
  final presentation = _MobileStylePresentation.resolve(visualStyle);
  final copy = _mobileExampleCopy[slug] ?? const [('Chart', 'Simple example')];
  return [
    for (var index = 0; index < copy.length; index++)
      _MobileChartExample(
        title: copy[index].$1,
        description: copy[index].$2,
        series: index == 0
            ? _mobileSeries(slug, presentation)
            : _mobileVariantSeries(slug, index, presentation),
        annotations: _mobileAnnotations(slug, index, presentation),
        showLegend:
            (slug == 'line-charts' && (index == 1 || index == 3)) ||
            (slug == 'area-charts' && index >= 2) ||
            (slug == 'range-area-charts' && index == 2) ||
            (slug == 'bar-charts' && index > 0) ||
            (slug == 'scatter-charts' && index > 0) ||
            (slug == 'candlestick-charts' && index > 0) ||
            (slug == 'concentric-donut' && index == 0) ||
            (slug == 'polar-column' && index > 0),
        xAxisConfig: _mobileXAxis(slug, index),
        yAxis: _mobileYAxis(slug, index),
        concentricDonutConfig: slug == 'concentric-donut'
            ? _mobileConcentricConfig(index)
            : null,
        polarChartConfig: slug == 'polar-column'
            ? _mobilePolarConfig(index)
            : null,
        grid: slug == 'bar-charts' && index == 2
            ? const GridConfig(horizontal: false, vertical: true)
            : null,
        chartHeight: switch ((slug, index)) {
          ('line-charts', 3) => 300,
          ('area-charts', 3) => 300,
          ('range-area-charts', 3) => 300,
          ('bar-charts', 2) => 330,
          ('bar-charts', 3) => 310,
          ('scatter-charts', 3) => 310,
          ('candlestick-charts', 3) => 330,
          ('pie-charts', 1) => 330,
          ('concentric-donut', _) => 310,
          ('polar-column', _) => 310,
          _ => null,
        },
        badges: _mobileBadges(slug, index),
        legendStyle: _mobileLegendStyle(slug, index, presentation),
        radialLegendItemBuilder: slug == 'concentric-donut' && index == 0
            ? _mobileCompactConcentricLegendItem
            : null,
      ),
  ];
}

XAxisConfig? _mobileXAxis(String slug, int index) => switch (slug) {
  'line-charts' when index == 2 => const XAxisConfig(
    label: 'Hour',
    tickCount: 5,
    showMinorTicks: false,
  ),
  'line-charts' when index == 3 => const XAxisConfig(
    label: 'Time (min)',
    tickCount: 5,
    showMinorTicks: false,
  ),
  'range-area-charts' when index == 3 => const XAxisConfig(
    label: 'Service window',
    tickCount: 5,
    showMinorTicks: false,
  ),
  'range-area-charts' when index == 2 => const XAxisConfig(
    label: 'Horizon',
    tickCount: 4,
    showMinorTicks: false,
  ),
  'scatter-charts' when index == 1 => const XAxisConfig(
    label: 'Growth %',
    tickCount: 4,
    showMinorTicks: false,
  ),
  'bar-charts' when index == 1 => XAxisConfig(
    label: 'Country',
    min: -0.6,
    max: 4.6,
    renderMin: 0,
    renderMax: 4,
    tickCount: 5,
    labelFormatter: (value) =>
        _mobileCategoryLabel(value, const ['CN', 'US', 'JP', 'AU', 'FR']),
  ),
  'bar-charts' when index == 2 => XAxisConfig(
    label: 'Statement',
    min: -1,
    max: 6,
    renderMin: 0,
    renderMax: 5,
    tickCount: 6,
    maxHeight: 88,
    labelFormatter: (value) => _mobileCategoryLabel(value, const [
      'Easy',
      'Fast',
      'Reports',
      'Workflow',
      'Support',
      'Recommend',
    ]),
  ),
  'bar-charts' when index == 3 => XAxisConfig(
    label: 'Day',
    min: -0.5,
    max: 6.5,
    renderMin: 0,
    renderMax: 6,
    tickCount: 7,
    labelFormatter: (value) => _mobileCategoryLabel(value, const [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ]),
  ),
  'candlestick-charts' when index == 3 => const XAxisConfig(
    label: 'Session',
    tickCount: 5,
    showMinorTicks: false,
  ),
  _ => null,
};

String _mobileCategoryLabel(double value, List<String> labels) {
  final index = value.round();
  if ((value - index).abs() > 0.05) return '';
  return index >= 0 && index < labels.length ? labels[index] : '';
}

YAxisConfig? _mobileYAxis(String slug, int index) => switch (slug) {
  'line-charts' when index == 2 => YAxisConfig(
    position: YAxisPosition.left,
    label: '°C',
    tickCount: 4,
    maxWidth: 48,
  ),
  'line-charts' when index == 3 => YAxisConfig(
    position: YAxisPosition.left,
    label: 'VO₂',
    min: 46,
    max: 55,
    tickCount: 4,
    maxWidth: 48,
  ),
  'scatter-charts' when index == 1 => YAxisConfig(
    position: YAxisPosition.left,
    label: 'Retention %',
    min: 68,
    max: 100,
    tickCount: 4,
    maxWidth: 48,
  ),
  _ => null,
};

List<ChartAnnotation> _mobileAnnotations(
  String slug,
  int index,
  _MobileStylePresentation presentation,
) => switch ((slug, index)) {
  ('line-charts', 2) => [
    ThresholdAnnotation(
      id: 'mobile-forecast-now',
      axis: AnnotationAxis.x,
      value: 4,
      label: 'Now',
      dashPattern: [5, 4],
      allowDragging: false,
      allowEditing: false,
    ),
  ],
  ('line-charts', 3) => [
    RangeAnnotation(
      id: 'mobile-vo2-target',
      startY: 49.8,
      endY: 51.7,
      label: 'Target window',
      fillColor: presentation.palette[0].withValues(alpha: 0.08),
      borderColor: presentation.palette[0].withValues(alpha: 0.34),
      allowDragging: false,
      allowEditing: false,
    ),
    ThresholdAnnotation(
      id: 'mobile-vo2-stage-change',
      axis: AnnotationAxis.x,
      value: 7,
      label: 'Stage change',
      dashPattern: [5, 4],
      allowDragging: false,
      allowEditing: false,
    ),
  ],
  _ => const [],
};

List<String> _mobileBadges(String slug, int index) => switch ((slug, index)) {
  ('line-charts', 3) => const [
    'Range band',
    'Threshold',
    'Glow',
    'Raw + summary',
  ],
  ('area-charts', 3) => const [
    '3 areas',
    '2 lines',
    'Layered',
    'Mixed metrics',
  ],
  ('range-area-charts', 3) => const [
    'Stepped',
    'Gaps',
    'Low + high',
    'Typed tracking',
  ],
  ('bar-charts', 2) => const [
    'Horizontal',
    'Diverging',
    '100% response',
    '5 bands',
  ],
  ('bar-charts', 3) => const [
    'Lollipop',
    '2 series',
    'Value labels',
    'Animated',
  ],
  ('scatter-charts', 3) => const [
    'Hexbin',
    '1 population',
    'Density',
    'Raw points retained',
  ],
  ('candlestick-charts', 3) => const [
    '20 sessions',
    'OHLC',
    'Close average',
    'Staggered motion',
  ],
  ('pie-charts', 3) => const ['7 sources', 'Grouped Other', 'Outside labels'],
  ('donut-charts', 3) => const [
    'Outside callouts',
    'Inside badges',
    'Status centre',
  ],
  ('concentric-donut', 0) => const [
    '2 rings',
    'Weighted bands',
    'Compact legend',
  ],
  ('concentric-donut', 1) => const [
    '3 rings',
    'Outer callouts',
    'Inside badges',
  ],
  ('concentric-donut', 2) => const [
    'Partial sweep',
    'Unequal bands',
    'Ring-specific data',
  ],
  ('concentric-donut', 3) => const [
    '4 rings',
    'Independent progress',
    'Shared centre',
  ],
  ('polar-column', 0) => const ['Rose', 'Category colour', '7 sectors'],
  ('polar-column', 1) => const ['Layered', 'Capacity track', 'Observed values'],
  ('polar-column', 2) => const ['Grouped', '3 series', 'Shared categories'],
  ('polar-column', 3) => const [
    'Stacked',
    'Signed values',
    'Shared radial scale',
  ],
  _ => const [],
};

LegendStyle? _mobileLegendStyle(
  String slug,
  int index,
  _MobileStylePresentation presentation,
) {
  if (slug == 'bar-charts' && index == 2) {
    return LegendStyle(
      position: LegendPosition.topLeft,
      orientation: LegendOrientation.vertical,
      textStyle: TextStyle(
        fontSize: 8,
        color: presentation.onSurfaceVariant,
        fontWeight: FontWeight.w500,
      ),
      backgroundColor: Colors.transparent,
      borderWidth: 0,
      padding: const EdgeInsets.all(4),
      itemSpacing: 3,
      markerSize: 10,
      markerLineWidth: 3,
      markerLabelSpacing: 4,
      allowDragging: false,
    );
  }
  if (slug == 'concentric-donut' && index == 0) {
    return LegendStyle(
      position: LegendPosition.bottomCenter,
      orientation: LegendOrientation.horizontal,
      textStyle: TextStyle(
        fontSize: 8,
        color: presentation.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: presentation.surface.withValues(alpha: 0.88),
      borderWidth: 0,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      itemSpacing: 2,
      markerSize: 8,
      markerLineWidth: 2,
      markerLabelSpacing: 3,
      allowDragging: false,
      offset: const Offset(0, 6),
    );
  }
  return null;
}

Widget _mobileCompactConcentricLegendItem(
  BuildContext context,
  RadialLegendItemData item,
) => Padding(
  padding: const EdgeInsets.symmetric(horizontal: 3),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: item.color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(
        '${item.seriesName == 'This week' ? 'Now' : 'Prior'} ${item.category}',
        style: item.defaultTextStyle.copyWith(
          fontSize: 8,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  ),
);

ConcentricDonutConfig _mobileConcentricConfig(int index) => switch (index) {
  0 => const ConcentricDonutConfig(
    innerRadiusFactor: 0.32,
    outerRadiusFactor: 0.98,
    ringGap: 5,
    ringWeights: {
      'mobile-concentric-current': 1.35,
      'mobile-concentric-previous': 0.72,
    },
    legendMode: ConcentricDonutLegendMode.flat,
    centerContent: DonutCenterContent(
      label: 'Weeks',
      valueMode: DonutCenterValueMode.custom,
      customValue: '2',
    ),
  ),
  1 => const ConcentricDonutConfig(
    innerRadiusFactor: 0.24,
    outerRadiusFactor: 0.98,
    ringGap: 3,
    ringWeights: {
      'mobile-concentric-1-0': 1.4,
      'mobile-concentric-1-1': 0.9,
      'mobile-concentric-1-2': 0.62,
    },
    legendMode: ConcentricDonutLegendMode.flat,
    centerContent: DonutCenterContent(
      label: 'Current',
      valueMode: DonutCenterValueMode.custom,
      customValue: '100',
    ),
  ),
  2 => const ConcentricDonutConfig(
    innerRadiusFactor: 0.31,
    outerRadiusFactor: 0.98,
    ringGap: 7,
    order: ConcentricRingOrder.innerToOuter,
    ringWeights: {
      'mobile-concentric-2-0': 0.68,
      'mobile-concentric-2-1': 1.0,
      'mobile-concentric-2-2': 1.48,
    },
    legendMode: ConcentricDonutLegendMode.flat,
    centerContent: DonutCenterContent(
      label: 'Domains',
      valueMode: DonutCenterValueMode.custom,
      customValue: '3',
    ),
  ),
  _ => const ConcentricDonutConfig(
    innerRadiusFactor: 0.18,
    outerRadiusFactor: 0.98,
    ringGap: 3,
    ringWeights: {
      'mobile-concentric-3-0': 1,
      'mobile-concentric-3-1': 1,
      'mobile-concentric-3-2': 1,
      'mobile-concentric-3-3': 1,
    },
    legendMode: ConcentricDonutLegendMode.flat,
    centerContent: DonutCenterContent(
      label: 'Goals',
      valueMode: DonutCenterValueMode.custom,
      customValue: '4',
    ),
  ),
};

PolarChartConfig _mobilePolarConfig(int index) => switch (index) {
  0 => const PolarChartConfig(
    pane: PolarPaneConfig(innerRadiusFactor: 0.08, outerRadiusFactor: 0.98),
    angularAxis: PolarCategoryAxisConfig(
      innerPadding: 0.18,
      showLabels: true,
      showGridLines: false,
    ),
    radialAxis: PolarNumericAxisConfig(showLabels: false, showGridLines: true),
  ),
  1 => const PolarChartConfig(
    pane: PolarPaneConfig(innerRadiusFactor: 0.16, outerRadiusFactor: 0.98),
    angularAxis: PolarCategoryAxisConfig(
      innerPadding: 0.16,
      showLabels: true,
      showGridLines: false,
    ),
    radialAxis: PolarNumericAxisConfig(
      minimum: 0,
      maximum: 100,
      showLabels: false,
      showGridLines: true,
    ),
  ),
  2 => const PolarChartConfig(
    pane: PolarPaneConfig(innerRadiusFactor: 0.12, outerRadiusFactor: 0.98),
    angularAxis: PolarCategoryAxisConfig(
      innerPadding: 0.10,
      showLabels: true,
      showGridLines: false,
    ),
    radialAxis: PolarNumericAxisConfig(
      minimum: 0,
      maximum: 100,
      showLabels: false,
      showGridLines: true,
    ),
    composition: PolarColumnCompositionConfig(
      mode: PolarColumnCompositionMode.grouped,
      groupInnerPadding: 0.18,
    ),
  ),
  _ => const PolarChartConfig(
    pane: PolarPaneConfig(innerRadiusFactor: 0.16, outerRadiusFactor: 0.98),
    angularAxis: PolarCategoryAxisConfig(
      innerPadding: 0.10,
      showLabels: true,
      showGridLines: false,
    ),
    radialAxis: PolarNumericAxisConfig(
      minimum: -30,
      maximum: 100,
      showLabels: false,
      showGridLines: true,
    ),
    composition: PolarColumnCompositionConfig(
      mode: PolarColumnCompositionMode.stacked,
    ),
  ),
};

const _pathEntrance = PathAnimationStyle(
  entranceMode: PathEntranceAnimationMode.reveal,
  dataUpdateMode: PathDataUpdateAnimationMode.interpolate,
  entranceTiming: PathAnimationTiming(duration: Duration(milliseconds: 720)),
  dataUpdateTiming: PathAnimationTiming(duration: Duration(milliseconds: 420)),
);

List<ChartSeries> _mobileSeries(
  String slug,
  _MobileStylePresentation presentation,
) => switch (slug) {
  'line-charts' => [
    LineChartSeries(
      id: 'mobile-line',
      name: 'Active minutes',
      unit: 'min',
      color: presentation.palette[0],
      interpolation: LineInterpolation.monotone,
      strokeWidth: 3,
      showDataPointMarkers: true,
      dataPointMarkerRadius: 4,
      pathAnimation: _pathEntrance,
      points: const [
        ChartDataPoint(x: 1, y: 28),
        ChartDataPoint(x: 2, y: 36),
        ChartDataPoint(x: 3, y: 32),
        ChartDataPoint(x: 4, y: 45),
        ChartDataPoint(x: 5, y: 51),
        ChartDataPoint(x: 6, y: 47),
        ChartDataPoint(x: 7, y: 60),
      ],
    ),
  ],
  'area-charts' => [
    AreaChartSeries(
      id: 'mobile-area',
      name: 'Screen time',
      unit: 'min',
      color: presentation.palette[1],
      interpolation: LineInterpolation.monotone,
      strokeWidth: 2.5,
      fillOpacity: 0.26,
      pathAnimation: _pathEntrance,
      points: const [
        ChartDataPoint(x: 1, y: 42),
        ChartDataPoint(x: 2, y: 55),
        ChartDataPoint(x: 3, y: 48),
        ChartDataPoint(x: 4, y: 66),
        ChartDataPoint(x: 5, y: 58),
        ChartDataPoint(x: 6, y: 72),
        ChartDataPoint(x: 7, y: 63),
      ],
    ),
  ],
  'range-area-charts' => [
    RangeAreaChartSeries(
      id: 'mobile-range-area',
      name: 'Forecast',
      unit: '°C',
      color: presentation.palette[0],
      interpolation: LineInterpolation.monotone,
      fillOpacity: 0.3,
      pathAnimation: _pathEntrance,
      points: [
        RangeAreaDataPoint(x: 1, low: 13, high: 22),
        RangeAreaDataPoint(x: 2, low: 15, high: 25),
        RangeAreaDataPoint(x: 3, low: 12, high: 20),
        RangeAreaDataPoint(x: 4, low: 14, high: 24),
        RangeAreaDataPoint(x: 5, low: 16, high: 27),
        RangeAreaDataPoint(x: 6, low: 17, high: 29),
        RangeAreaDataPoint(x: 7, low: 15, high: 26),
      ],
    ),
  ],
  'bar-charts' => [
    BarChartSeries(
      id: 'mobile-bar',
      name: 'Steps',
      color: presentation.palette[4],
      barWidthPercent: 0.68,
      barStyle: const BarChartStyle(
        cornerRadius: 6,
        motion: BarMotionStyle(
          order: BarAnimationOrder.forward,
          staggerFraction: 0.52,
        ),
      ),
      points: const [
        ChartDataPoint(x: 1, y: 6200),
        ChartDataPoint(x: 2, y: 8100),
        ChartDataPoint(x: 3, y: 7400),
        ChartDataPoint(x: 4, y: 9800),
        ChartDataPoint(x: 5, y: 10500),
        ChartDataPoint(x: 6, y: 8900),
        ChartDataPoint(x: 7, y: 11200),
      ],
    ),
  ],
  'scatter-charts' => [
    ScatterChartSeries(
      id: 'mobile-scatter',
      name: 'Walks',
      unit: 'min/km',
      color: presentation.palette[3],
      markerRadius: 6,
      points: const [
        ChartDataPoint(x: 2.1, y: 8.4),
        ChartDataPoint(x: 2.8, y: 7.9),
        ChartDataPoint(x: 3.4, y: 8.1),
        ChartDataPoint(x: 4.2, y: 7.4),
        ChartDataPoint(x: 5.1, y: 7.2),
        ChartDataPoint(x: 5.8, y: 6.9),
        ChartDataPoint(x: 6.4, y: 7.1),
      ],
    ),
  ],
  'candlestick-charts' => [
    CandlestickChartSeries(
      id: 'mobile-candlestick',
      name: 'Price',
      candlestickStyle: CandlestickChartStyle(
        risingBodyFillColor: presentation.palette[4],
        risingBorderColor: presentation.palette[4],
        risingWickColor: presentation.palette[4],
        fallingBodyFillColor: presentation.palette[3],
        fallingBorderColor: presentation.palette[3],
        fallingWickColor: presentation.palette[3],
        bodyFillMode: CandlestickBodyFillMode.filled,
        bodyCornerRadius: 2,
      ),
      animation: const CandlestickAnimationStyle(staggerFraction: 0.7),
      points: [
        CandlestickDataPoint(x: 1, open: 44, high: 49, low: 42, close: 47),
        CandlestickDataPoint(x: 2, open: 47, high: 51, low: 45, close: 49),
        CandlestickDataPoint(x: 3, open: 49, high: 50, low: 43, close: 45),
        CandlestickDataPoint(x: 4, open: 45, high: 52, low: 44, close: 50),
        CandlestickDataPoint(x: 5, open: 50, high: 55, low: 48, close: 53),
        CandlestickDataPoint(x: 6, open: 53, high: 54, low: 49, close: 51),
        CandlestickDataPoint(x: 7, open: 51, high: 57, low: 50, close: 56),
      ],
    ),
  ],
  'pie-charts' => [
    PieChartSeries.fromMap(
      id: 'mobile-pie',
      name: 'Spending',
      values: const {'Home': 42, 'Food': 27, 'Travel': 18, 'Other': 13},
      dataLabels: const PieDataLabelConfig(
        position: PieDataLabelPosition.inside,
        content: PieDataLabelContent.percentage,
        minimumShare: 0.12,
      ),
      pieStyle: const PieChartStyle(
        radiusFactor: 0.98,
        sliceGap: 3,
        cornerRadius: 3,
        gradient: PieGradientStyle(
          type: PieGradientType.radial,
          startLightnessShift: 0.22,
          endLightnessShift: -0.08,
        ),
        animationMode: PieAnimationMode.sweep,
      ),
    ),
  ],
  'donut-charts' => [
    DonutChartSeries.fromMap(
      id: 'mobile-donut',
      name: 'Storage',
      values: const {'Photos': 46, 'Apps': 31, 'Files': 23},
      donutStyle: const DonutChartStyle(
        innerRadiusFactor: 0.58,
        radiusFactor: 0.98,
        sliceGap: 3,
        cornerRadius: 6,
        gradient: PieGradientStyle(
          angleDegrees: -35,
          startLightnessShift: 0.2,
          endLightnessShift: -0.1,
        ),
        animationMode: PieAnimationMode.grow,
      ),
      centerContent: const DonutCenterContent(
        label: 'Used',
        valueMode: DonutCenterValueMode.custom,
        customValue: '78%',
      ),
      dataLabels: const PieDataLabelConfig(
        position: PieDataLabelPosition.inside,
        content: PieDataLabelContent.percentage,
        minimumShare: 0.14,
      ),
    ),
  ],
  'concentric-donut' => [
    DonutChartSeries.fromMap(
      id: 'mobile-concentric-current',
      name: 'This week',
      values: const {'Active': 68, 'Rest': 32},
      sliceColors: {
        'Active': presentation.palette[3],
        'Rest': presentation.palette[3].withValues(alpha: 0.2),
      },
      dataLabels: const PieDataLabelConfig(isVisible: false),
      donutStyle: const DonutChartStyle(
        radiusFactor: 0.98,
        sliceGap: 2,
        cornerRadius: 5,
        gradient: PieGradientStyle(
          type: PieGradientType.radial,
          startLightnessShift: 0.18,
          endLightnessShift: -0.08,
        ),
        selectionExplodeOffset: 0,
        animationMode: PieAnimationMode.sweep,
      ),
    ),
    DonutChartSeries.fromMap(
      id: 'mobile-concentric-previous',
      name: 'Last week',
      values: const {'Active': 54, 'Rest': 46},
      sliceColors: {
        'Active': presentation.palette[1],
        'Rest': presentation.palette[1].withValues(alpha: 0.2),
      },
      dataLabels: const PieDataLabelConfig(isVisible: false),
      donutStyle: const DonutChartStyle(
        radiusFactor: 0.98,
        sliceGap: 2,
        cornerRadius: 5,
        gradient: PieGradientStyle(
          angleDegrees: 45,
          startLightnessShift: 0.16,
          endLightnessShift: -0.1,
        ),
        selectionExplodeOffset: 0,
        animationMode: PieAnimationMode.sweep,
      ),
    ),
  ],
  'polar-column' => [
    PolarColumnChartSeries.rose(
      id: 'mobile-polar-column',
      name: 'Activity',
      values: const <String, num>{
        'Mon': 48,
        'Tue': 64,
        'Wed': 55,
        'Thu': 76,
        'Fri': 68,
        'Sat': 88,
        'Sun': 58,
      },
      columnColors: _sliceColors(const [
        'Mon',
        'Tue',
        'Wed',
        'Thu',
        'Fri',
        'Sat',
        'Sun',
      ], presentation.palette),
      polarStyle: const PolarColumnStyle(
        cornerRadius: 5,
        borderWidth: 1.2,
        showDataLabels: true,
        maximumVisibleDataLabels: 7,
        dataLabelRadialPosition: 0.62,
        dataLabelStyle: PolarLabelStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
        gradient: PolarColumnGradientStyle(
          startLightnessShift: 0.24,
          endLightnessShift: -0.08,
        ),
        animationMode: PolarColumnAnimationMode.sweep,
      ),
    ),
  ],
  _ => const <ChartSeries>[],
};

List<ChartSeries> _mobileVariantSeries(
  String slug,
  int variant,
  _MobileStylePresentation presentation,
) => switch (slug) {
  'line-charts' => [
    if (variant == 1) ...[
      _mobileLine(
        id: 'mobile-line-current',
        name: 'Current',
        color: presentation.palette[0],
        values: const [30, 38, 35, 48, 44, 55, 63, 58],
      ),
      _mobileLine(
        id: 'mobile-line-previous',
        name: 'Previous',
        color: presentation.palette[3],
        values: const [24, 32, 29, 42, 38, 49, 57, 52],
      ),
      _mobileLine(
        id: 'mobile-line-target',
        name: 'Target',
        color: presentation.palette[2],
        values: const [34, 36, 39, 43, 47, 51, 55, 59],
        interpolation: LineInterpolation.linear,
      ),
    ] else if (variant == 2)
      LineChartSeries(
        id: 'mobile-line-forecast',
        name: 'Observed + forecast',
        unit: '°C',
        color: presentation.palette[0],
        interpolation: LineInterpolation.monotone,
        strokeWidth: 3,
        showDataPointMarkers: true,
        dataPointMarkerRadius: 3.5,
        dataPointMarkerStyle: DataPointMarkerStyle.hollow,
        pathAnimation: _pathEntrance,
        inlineLabel: SeriesInlineLabelConfig(
          text: 'Forecast',
          position: SeriesLabelPosition.right,
          color: presentation.palette[0],
        ),
        points: const [
          ChartDataPoint(x: 0, y: 12.1),
          ChartDataPoint(x: 1, y: 11.9),
          ChartDataPoint(x: 2, y: 11.8),
          ChartDataPoint(x: 3, y: 11.7),
          ChartDataPoint(
            x: 4,
            y: 11.8,
            segmentStyle: SegmentStyle(dashPattern: [2, 6]),
          ),
          ChartDataPoint(
            x: 5,
            y: 11.4,
            segmentStyle: SegmentStyle(dashPattern: [2, 6]),
          ),
          ChartDataPoint(
            x: 6,
            y: 11.1,
            segmentStyle: SegmentStyle(dashPattern: [2, 6]),
          ),
          ChartDataPoint(
            x: 7,
            y: 10.4,
            segmentStyle: SegmentStyle(dashPattern: [2, 6]),
          ),
          ChartDataPoint(
            x: 8,
            y: 9.9,
            segmentStyle: SegmentStyle(dashPattern: [2, 6]),
          ),
        ],
      )
    else
      ..._mobileVo2StageSeries(presentation),
  ],
  'area-charts' => [
    if (variant == 1)
      AreaChartSeries(
        id: 'mobile-area-baseline',
        name: 'Delta from target',
        unit: '%',
        color: presentation.palette[3],
        interpolation: LineInterpolation.monotone,
        strokeWidth: 2.8,
        fillOpacity: 0.34,
        baselineValue: 0,
        aboveBaselineFillColor: presentation.palette[4].withValues(alpha: 0.3),
        belowBaselineFillColor: presentation.palette[3].withValues(alpha: 0.28),
        showDataPointMarkers: true,
        dataPointMarkerRadius: 3.5,
        pathAnimation: _pathEntrance,
        points: _points(const [14, 9, 5, -3, -9, -16, -8, 4]),
      )
    else if (variant == 2) ...[
      AreaChartSeries(
        id: 'mobile-area-total',
        name: 'Total',
        color: presentation.palette[0],
        interpolation: LineInterpolation.monotone,
        fillOpacity: 0.2,
        pathAnimation: _pathEntrance,
        points: _points(const [58, 65, 69, 66, 74, 81, 78]),
      ),
      AreaChartSeries(
        id: 'mobile-area-active',
        name: 'Active',
        color: presentation.palette[1],
        interpolation: LineInterpolation.monotone,
        fillOpacity: 0.3,
        pathAnimation: _pathEntrance,
        points: _points(const [32, 37, 41, 39, 46, 52, 49]),
      ),
      _mobileLine(
        id: 'mobile-area-plan',
        name: 'Plan',
        color: presentation.palette[2],
        values: const [35, 38, 41, 44, 47, 50, 53],
        interpolation: LineInterpolation.linear,
      ),
    ] else
      ..._mobileAnalyticsSeries(presentation),
  ],
  'range-area-charts' => [
    if (variant == 1)
      RangeAreaChartSeries(
        id: 'mobile-range-seasonal',
        name: 'Seasonal range',
        unit: '°C',
        color: presentation.palette[3],
        interpolation: LineInterpolation.monotone,
        fillOpacity: 0.3,
        fillGradient: AreaGradient(
          colors: [
            presentation.palette[3].withValues(alpha: 0.55),
            presentation.palette[3].withValues(alpha: 0.08),
          ],
        ),
        showBoundaryMarkers: true,
        markerRadius: 3,
        pathAnimation: _pathEntrance,
        points: _rangePoints(
          const [-8, -5, -2, 2, 7, 11, 9, 5, 0, -4, -7, -9],
          const [-1, 2, 6, 11, 16, 20, 18, 15, 10, 6, 2, 0],
        ),
      )
    else if (variant == 2)
      ..._mobileForecastFan(presentation),
    if (variant > 2) _mobileServiceWindows(presentation),
  ],
  'bar-charts' => [
    if (variant == 1)
      ..._mobileOverlayBars(presentation)
    else if (variant == 2)
      ..._mobileSurveyBars(presentation),
    if (variant > 2) ..._mobileLollipopBars(presentation),
  ],
  'scatter-charts' => [
    if (variant == 1)
      ..._mobileBubbleSeries(presentation)
    else if (variant == 3)
      _mobilePickupDensity(presentation)
    else
      ..._mobileCohortSeries(presentation),
  ],
  'candlestick-charts' => [
    if (variant == 1)
      ..._mobilePriceAndAverage(presentation)
    else if (variant == 2)
      ..._mobileVolatilityStudy(presentation),
    if (variant == 3) ..._mobileLongMarketSession(presentation),
  ],
  'pie-charts' => [
    PieChartSeries.fromMap(
      id: 'mobile-pie-$variant',
      name: switch (variant) {
        1 => 'Revenue',
        2 => 'Campaigns',
        _ => 'Support',
      },
      values: switch (variant) {
        1 => const {
          'Subscriptions': 46,
          'Services': 24,
          'Hardware': 15,
          'Training': 9,
          'Other': 6,
        },
        2 => const {
          'Search': 31,
          'Social': 24,
          'Partners': 19,
          'Events': 15,
          'Email': 11,
        },
        _ => const {
          'Portal': 52,
          'Phone': 18,
          'Partners': 11,
          'Email': 7,
          'Chat': 5,
          'Events': 4,
          'Other source': 3,
        },
      },
      radiusValues: variant == 2
          ? const {
              'Search': 92,
              'Social': 76,
              'Partners': 64,
              'Events': 51,
              'Email': 43,
            }
          : const {},
      sliceRadiusConfig: variant == 2
          ? const PieSliceRadiusConfig(
              minimumFactor: 0.48,
              scale: PieSliceRadiusScale.area,
              label: 'Audience reach',
            )
          : null,
      sliceGroupingConfig: variant == 3
          ? const RadialSliceGroupingConfig(minimumShare: 0.08, label: 'Other')
          : null,
      sliceColors: _sliceColors(switch (variant) {
        1 => const [
          'Subscriptions',
          'Services',
          'Hardware',
          'Training',
          'Other',
        ],
        2 => const ['Search', 'Social', 'Partners', 'Events', 'Email'],
        _ => const [
          'Portal',
          'Phone',
          'Partners',
          'Email',
          'Chat',
          'Events',
          'Other source',
        ],
      }, presentation.palette),
      dataLabels: PieDataLabelConfig(
        position: variant == 1 || variant == 3
            ? PieDataLabelPosition.outside
            : PieDataLabelPosition.inside,
        content: variant == 1 || variant == 3
            ? PieDataLabelContent.category
            : PieDataLabelContent.percentage,
        secondaryContent: variant == 1 || variant == 3
            ? PieDataLabelContent.percentage
            : null,
        secondaryPosition: PieDataLabelPosition.inside,
        minimumShare: variant == 3 ? 0.08 : 0.06,
        padding: 4,
        connectorLength: 10,
      ),
      pieStyle: PieChartStyle(
        radiusFactor: 0.98,
        startAngleDegrees: variant == 3 ? -120 : -90,
        clockwise: variant != 3,
        sliceGap: variant == 1 || variant == 3 ? 2 : 5,
        cornerRadius: variant == 1
            ? 3
            : variant == 3
            ? 5
            : 8,
        gradient: PieGradientStyle(
          type: variant == 1 || variant == 3
              ? PieGradientType.linear
              : PieGradientType.radial,
          angleDegrees: variant == 1
              ? -35
              : variant == 3
              ? 55
              : 20,
          startLightnessShift: variant == 1 ? 0.18 : 0.26,
          endLightnessShift: -0.1,
        ),
        animationMode: PieAnimationMode.sweep,
      ),
    ),
  ],
  'donut-charts' => [
    DonutChartSeries.fromMap(
      id: 'mobile-donut-$variant',
      name: switch (variant) {
        1 => 'Delivery',
        2 => 'Channels',
        _ => 'Readiness',
      },
      values: switch (variant) {
        1 => const {
          'Build': 46,
          'Discovery': 18,
          'Design': 14,
          'Testing': 12,
          'Launch': 7,
          'Support': 3,
        },
        2 => const {
          'Search': 31,
          'Social': 24,
          'Partners': 19,
          'Events': 15,
          'Email': 11,
        },
        _ => const {'Ready': 64, 'Review': 18, 'Blocked': 8, 'Remaining': 10},
      },
      radiusValues: variant == 2
          ? const {
              'Search': 92,
              'Social': 76,
              'Partners': 64,
              'Events': 51,
              'Email': 43,
            }
          : const {},
      sliceRadiusConfig: variant == 2
          ? const RadialSliceRadiusConfig(
              minimumFactor: 0.42,
              scale: PieSliceRadiusScale.area,
              label: 'Audience reach',
            )
          : null,
      sliceColors: _sliceColors(switch (variant) {
        1 => const [
          'Build',
          'Discovery',
          'Design',
          'Testing',
          'Launch',
          'Support',
        ],
        2 => const ['Search', 'Social', 'Partners', 'Events', 'Email'],
        _ => const ['Ready', 'Review', 'Blocked', 'Remaining'],
      }, presentation.palette),
      donutStyle: DonutChartStyle(
        innerRadiusFactor: variant == 1
            ? 0.68
            : variant == 3
            ? 0.58
            : 0.36,
        radiusFactor: 0.98,
        sweepAngleDegrees: variant == 1 ? 280 : 360,
        startAngleDegrees: variant == 1 ? 130 : -90,
        sliceGap: variant == 3 ? 2 : 3,
        cornerRadius: variant == 3 ? 6 : 10,
        gradient: PieGradientStyle(
          type: variant == 1 || variant == 3
              ? PieGradientType.linear
              : PieGradientType.radial,
          angleDegrees: variant == 1
              ? 40
              : variant == 3
              ? -55
              : -20,
          startLightnessShift: 0.22,
          endLightnessShift: -0.12,
        ),
        animationMode: PieAnimationMode.sweep,
      ),
      centerContent: DonutCenterContent(
        label: variant == 1
            ? 'Status'
            : variant == 3
            ? 'Ready'
            : 'Reach',
        valueMode: DonutCenterValueMode.custom,
        customValue: variant == 1
            ? 'On track'
            : variant == 3
            ? '82%'
            : '100',
      ),
      dataLabels: variant == 3
          ? _mobileRadialSplitCallouts(presentation, minimumShare: 0.06)
          : const PieDataLabelConfig(
              position: PieDataLabelPosition.inside,
              content: PieDataLabelContent.percentage,
              minimumShare: 0.1,
            ),
    ),
  ],
  'concentric-donut' => _concentricSeries(variant, presentation),
  'polar-column' => _mobilePolarSeries(variant, presentation),
  _ => const <ChartSeries>[],
};

LineChartSeries _mobileLine({
  required String id,
  required String name,
  required Color color,
  required List<double> values,
  LineInterpolation interpolation = LineInterpolation.monotone,
}) => LineChartSeries(
  id: id,
  name: name,
  color: color,
  interpolation: interpolation,
  strokeWidth: 2.7,
  showDataPointMarkers: true,
  dataPointMarkerRadius: 3,
  pathAnimation: _pathEntrance,
  points: _points(values),
);

List<ChartSeries> _mobileVo2StageSeries(_MobileStylePresentation presentation) {
  const raw = <double>[
    50.1,
    48.2,
    51.0,
    49.2,
    52.0,
    50.4,
    53.1,
    50.8,
    52.4,
    51.1,
    53.3,
    50.2,
    52.9,
    51.0,
    52.2,
  ];
  const stage = <double>[
    49.0,
    49.0,
    49.0,
    51.7,
    51.7,
    51.7,
    51.7,
    51.7,
    51.7,
    49.8,
    49.8,
    49.8,
    49.8,
    49.8,
    49.8,
  ];
  return [
    LineChartSeries(
      id: 'mobile-vo2-raw',
      name: 'Raw VO₂',
      unit: 'mL/kg/min',
      color: presentation.palette[1].withValues(alpha: 0.46),
      interpolation: LineInterpolation.linear,
      strokeWidth: 1.3,
      pathAnimation: _pathEntrance,
      points: _points(raw),
    ),
    LineChartSeries(
      id: 'mobile-vo2-stage',
      name: 'Stage avg VO₂',
      unit: 'mL/kg/min',
      color: presentation.palette[0],
      interpolation: LineInterpolation.stepped,
      strokeWidth: 3,
      lineGlow: 7,
      showDataPointMarkers: true,
      dataPointMarkerRadius: 3,
      dataPointMarkerStyle: DataPointMarkerStyle.hollow,
      pathAnimation: _pathEntrance,
      points: _points(stage),
    ),
  ];
}

List<ChartSeries> _mobileAnalyticsSeries(
  _MobileStylePresentation presentation,
) => [
  AreaChartSeries(
    id: 'mobile-analytics-sessions',
    name: 'Sessions',
    color: presentation.palette[0],
    interpolation: LineInterpolation.monotone,
    fillOpacity: 0.20,
    pathAnimation: _pathEntrance,
    points: _points(const [
      105,
      130,
      144,
      138,
      120,
      104,
      102,
      116,
      134,
      145,
      139,
      126,
    ]),
  ),
  AreaChartSeries(
    id: 'mobile-analytics-page-views',
    name: 'Page views',
    color: presentation.palette[3],
    interpolation: LineInterpolation.monotone,
    fillOpacity: 0.24,
    pathAnimation: _pathEntrance,
    points: _points(const [60, 74, 91, 88, 72, 60, 58, 67, 82, 93, 87, 70]),
  ),
  AreaChartSeries(
    id: 'mobile-analytics-active',
    name: 'Active users',
    color: presentation.palette[1],
    interpolation: LineInterpolation.monotone,
    fillOpacity: 0.28,
    pathAnimation: _pathEntrance,
    points: _points(const [35, 44, 58, 61, 52, 42, 39, 45, 53, 61, 56, 46]),
  ),
  _mobileLine(
    id: 'mobile-analytics-bounce',
    name: 'Bounce rate',
    color: presentation.palette[2],
    values: const [45, 50, 52, 48, 38, 30, 25, 27, 34, 38, 40, 35],
  ),
  _mobileLine(
    id: 'mobile-analytics-conversion',
    name: 'Conversion %',
    color: presentation.palette[4],
    values: const [20, 21, 20, 19, 18, 19, 23, 28, 33, 37, 40, 42],
  ),
];

RangeAreaChartSeries _mobileServiceWindows(
  _MobileStylePresentation presentation,
) => RangeAreaChartSeries(
  id: 'mobile-service-windows',
  name: 'Service-level range',
  unit: '%',
  color: presentation.palette[1],
  interpolation: LineInterpolation.stepped,
  fillOpacity: 0.30,
  showBoundaryMarkers: true,
  markerRadius: 3,
  connectGaps: false,
  pathAnimation: _pathEntrance,
  points: [
    RangeAreaDataPoint(x: 0, low: 91, high: 96),
    RangeAreaDataPoint(x: 1, low: 91, high: 96),
    RangeAreaDataPoint(x: 2, low: 92, high: 97),
    RangeAreaDataPoint(x: 3, low: 92, high: 97),
    RangeAreaDataPoint.gap(x: 4, label: 'Outage'),
    RangeAreaDataPoint.gap(x: 5, label: 'Outage'),
    RangeAreaDataPoint(x: 6, low: 94, high: 99),
    RangeAreaDataPoint(x: 7, low: 94, high: 99),
    RangeAreaDataPoint(x: 8, low: 93, high: 98),
    RangeAreaDataPoint(x: 9, low: 93, high: 98),
    RangeAreaDataPoint(x: 10, low: 95, high: 100),
    RangeAreaDataPoint(x: 11, low: 95, high: 100),
    RangeAreaDataPoint.gap(x: 12, label: 'Missing'),
    RangeAreaDataPoint(x: 13, low: 96, high: 101),
    RangeAreaDataPoint(x: 14, low: 96, high: 101),
    RangeAreaDataPoint(x: 15, low: 94, high: 99),
    RangeAreaDataPoint(x: 16, low: 94, high: 99),
    RangeAreaDataPoint(x: 17, low: 97, high: 102),
  ],
);

List<ChartSeries> _mobileForecastFan(_MobileStylePresentation presentation) {
  const centre = <double>[62, 65, 68, 69, 68, 67, 69, 74, 79];
  return [
    RangeAreaChartSeries(
      id: 'mobile-forecast-95',
      name: '95% interval',
      color: presentation.palette[0],
      interpolation: LineInterpolation.monotone,
      fillOpacity: 0.22,
      pathAnimation: _pathEntrance,
      points: _rangePoints(
        const [56, 58, 60, 60, 58, 56, 57, 60, 63],
        const [68, 72, 76, 78, 78, 78, 82, 88, 95],
      ),
    ),
    RangeAreaChartSeries(
      id: 'mobile-forecast-50',
      name: '50% interval',
      color: presentation.palette[3],
      interpolation: LineInterpolation.monotone,
      fillOpacity: 0.34,
      pathAnimation: _pathEntrance,
      points: _rangePoints(
        const [59, 62, 65, 66, 64, 63, 64, 68, 72],
        const [65, 68, 71, 72, 72, 71, 74, 80, 86],
      ),
    ),
    _mobileLine(
      id: 'mobile-forecast-centre',
      name: 'Centre',
      color: presentation.palette[2],
      values: centre,
    ),
  ];
}

List<ChartSeries> _mobileOverlayBars(_MobileStylePresentation presentation) => [
  BarChartSeries(
    id: 'mobile-medals-reference',
    name: 'Previous',
    color: presentation.onSurfaceVariant.withValues(alpha: 0.38),
    layoutMode: BarLayoutMode.overlaid,
    groupId: 'medals',
    overlayWidthFactor: 1,
    barWidthPercent: 0.72,
    barStyle: const BarChartStyle(
      cornerRadius: 4,
      motion: BarMotionStyle(staggerFraction: 0.5),
    ),
    points: _labelledPoints(
      const ['CN', 'US', 'JP', 'AU', 'FR'],
      const [38, 39, 27, 17, 10],
    ),
  ),
  BarChartSeries(
    id: 'mobile-medals-current',
    name: 'Current',
    color: presentation.palette[0],
    layoutMode: BarLayoutMode.overlaid,
    groupId: 'medals',
    overlayWidthFactor: 0.68,
    overlayOffsetFactor: 0.12,
    barWidthPercent: 0.72,
    barStyle: const BarChartStyle(
      cornerRadius: 4,
      motion: BarMotionStyle(
        order: BarAnimationOrder.centerOut,
        staggerFraction: 0.62,
      ),
    ),
    labelStyle: const BarLabelStyle(
      show: true,
      position: BarLabelPosition.insideCenter,
    ),
    points: _labelledPoints(
      const ['CN', 'US', 'JP', 'AU', 'FR'],
      const [40, 40, 20, 18, 16],
      colors: presentation.palette,
    ),
  ),
];

List<ChartSeries> _mobileSurveyBars(_MobileStylePresentation presentation) {
  const labels = [
    'Easy to learn',
    'Fast enough',
    'Reports are clear',
    'Fits our workflow',
    'Support is helpful',
    'Would recommend',
  ];
  const values = <List<double>>[
    [8, 12, 6, 15, 10, 7],
    [14, 18, 12, 20, 16, 11],
    [18, 16, 22, 17, 21, 14],
    [38, 34, 39, 31, 35, 40],
    [22, 20, 21, 17, 18, 28],
  ];
  const names = [
    'Strongly disagree',
    'Disagree',
    'Neutral',
    'Agree',
    'Strongly agree',
  ];
  const roles = [
    BarDivergingRole.negative,
    BarDivergingRole.negative,
    BarDivergingRole.neutral,
    BarDivergingRole.positive,
    BarDivergingRole.positive,
  ];
  return [
    for (var index = 0; index < values.length; index++)
      BarChartSeries(
        id: 'mobile-survey-$index',
        name: names[index],
        color: [
          const Color(0xFF315B78),
          const Color(0xFF6F93AA),
          const Color(0xFFAAB3BD),
          presentation.palette[2].withValues(alpha: 0.72),
          presentation.palette[2],
        ][index],
        unit: '%',
        orientation: BarOrientation.horizontal,
        layoutMode: BarLayoutMode.divergingStacked,
        divergingRole: roles[index],
        groupId: 'survey',
        barWidthPercent: 0.62,
        barStyle: const BarChartStyle(
          cornerRadius: 3,
          motion: BarMotionStyle(staggerFraction: 0.55),
        ),
        labelStyle: const BarLabelStyle(
          show: true,
          position: BarLabelPosition.insideCenter,
          valueMode: BarLabelValueMode.percentage,
          fontSize: 8,
          collisionPolicy: BarLabelCollisionPolicy.hide,
        ),
        points: _labelledPoints(labels, values[index]),
      ),
  ];
}

ScatterChartSeries _mobilePickupDensity(_MobileStylePresentation presentation) {
  final points = <ChartDataPoint>[];
  for (var index = 0; index < 900; index++) {
    final u = (((index * 37) % 997) + 1) / 998;
    final v = (((index * 61) % 991) + 1) / 992;
    final radius = math.sqrt(-2 * math.log(u)) * 8.4;
    final angle = 2 * math.pi * v;
    points.add(
      ChartDataPoint(
        x: 50 + math.cos(angle) * radius,
        y: 52 + math.sin(angle) * radius * 0.78,
      ),
    );
  }
  return ScatterChartSeries(
    id: 'mobile-pickup-density',
    name: 'Pickup requests',
    color: presentation.palette[1],
    points: points,
    markerRadius: 2,
    isXOrdered: false,
    renderMode: ScatterRenderMode.hexbin,
    binConfig: const ScatterBinConfig(
      cellSize: 26,
      gap: 1,
      minimumPointCount: 1,
      minimumOpacity: 0.14,
      maximumOpacity: 0.92,
      aggregate: ScatterBinAggregate.count,
      showLabels: false,
    ),
  );
}

List<ChartSeries> _mobileLollipopBars(_MobileStylePresentation presentation) {
  const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return [
    BarChartSeries(
      id: 'mobile-lollipop-current',
      name: 'Current',
      color: presentation.palette[1],
      layoutMode: BarLayoutMode.grouped,
      groupId: 'activation',
      barWidthPercent: 0.50,
      lollipopStyle: BarLollipopStyle(
        stemWidth: 2.5,
        headRadius: 6.5,
        stemColor: presentation.palette[1].withValues(alpha: 0.65),
        headColor: presentation.palette[1],
      ),
      barStyle: const BarChartStyle(
        motion: BarMotionStyle(
          order: BarAnimationOrder.forward,
          staggerFraction: 0.62,
        ),
      ),
      labelStyle: const BarLabelStyle(
        show: true,
        position: BarLabelPosition.outsideEnd,
      ),
      points: _labelledPoints(labels, const [54, 72, 61, 88, 69, 94, 76]),
    ),
    BarChartSeries(
      id: 'mobile-lollipop-previous',
      name: 'Previous',
      color: presentation.palette[2],
      layoutMode: BarLayoutMode.grouped,
      groupId: 'activation',
      barWidthPercent: 0.50,
      lollipopStyle: BarLollipopStyle(
        stemWidth: 2.5,
        headRadius: 6.5,
        stemColor: presentation.palette[2].withValues(alpha: 0.62),
        headColor: presentation.palette[2],
      ),
      barStyle: const BarChartStyle(
        motion: BarMotionStyle(
          order: BarAnimationOrder.reverse,
          staggerFraction: 0.62,
        ),
      ),
      labelStyle: const BarLabelStyle(
        show: true,
        position: BarLabelPosition.outsideEnd,
      ),
      points: _labelledPoints(labels, const [42, 64, 79, 58, 83, 71, 91]),
    ),
  ];
}

List<ChartSeries> _mobileBubbleSeries(_MobileStylePresentation presentation) =>
    [
      ScatterChartSeries(
        id: 'mobile-bubble-established',
        name: 'Established',
        color: presentation.palette[4],
        markerShape: SeriesMarkerShape.circle,
        sizeEncoding: const ScatterSizeEncoding(
          minimumRadius: 5,
          maximumRadius: 16,
          maximumValue: 18000,
          label: 'Active accounts',
        ),
        points: const [
          ChartDataPoint(x: 4, y: 94, magnitude: 16400),
          ChartDataPoint(x: 7, y: 89, magnitude: 9800),
          ChartDataPoint(x: 11, y: 84, magnitude: 7200),
          ChartDataPoint(x: 15, y: 79, magnitude: 4100),
        ],
      ),
      ScatterChartSeries(
        id: 'mobile-bubble-growth',
        name: 'Growth',
        color: presentation.palette[2],
        markerShape: SeriesMarkerShape.diamond,
        sizeEncoding: const ScatterSizeEncoding(
          minimumRadius: 5,
          maximumRadius: 16,
          maximumValue: 18000,
          label: 'Active accounts',
        ),
        points: const [
          ChartDataPoint(x: 8, y: 75, magnitude: 11300),
          ChartDataPoint(x: 12, y: 84, magnitude: 6900),
          ChartDataPoint(x: 16, y: 77, magnitude: 9800),
          ChartDataPoint(x: 20, y: 70, magnitude: 2600),
        ],
      ),
    ];

List<ChartSeries> _mobileCohortSeries(_MobileStylePresentation presentation) {
  const x = <double>[18, 25, 31, 36, 42, 47, 51, 56, 61, 67, 73, 82];
  const cohorts = <List<double>>[
    [30, 36, 40, 45, 47, 51, 49, 55, 59, 64, 68, 72],
    [24, 34, 38, 42, 52, 48, 55, 44, 61, 57, 66, 63],
    [32, 28, 41, 46, 43, 54, 50, 58, 53, 66, 61, 70],
  ];
  return [
    for (var index = 0; index < cohorts.length; index++)
      ScatterChartSeries(
        id: 'mobile-cohort-$index',
        name: 'Cohort ${index + 1}',
        color: presentation.palette[index],
        markerRadius: 4.5,
        points: _xyPoints(x, cohorts[index]),
      ),
  ];
}

List<ChartSeries> _mobilePriceAndAverage(
  _MobileStylePresentation presentation,
) => [
  _mobileCandles('mobile-price-average', presentation, _candles(1)),
  _mobileLine(
    id: 'mobile-price-average-line',
    name: 'Average',
    color: presentation.palette[0],
    values: const [40, 42, 42.7, 44.2, 46, 47.5, 49.5],
  ),
];

List<ChartSeries> _mobileVolatilityStudy(
  _MobileStylePresentation presentation,
) {
  final candles = _candles(2);
  return [
    RangeAreaChartSeries(
      id: 'mobile-volatility-band',
      name: 'Volatility',
      color: presentation.palette[4],
      interpolation: LineInterpolation.monotone,
      fillOpacity: 0.18,
      pathAnimation: _pathEntrance,
      points: _rangePoints(
        const [56, 57, 58, 61, 60, 62, 65],
        const [68, 70, 71, 74, 73, 76, 79],
      ),
    ),
    _mobileCandles('mobile-volatility-price', presentation, candles),
    _mobileLine(
      id: 'mobile-volatility-trend',
      name: 'Trend',
      color: presentation.palette[1],
      values: const [63, 62, 63.5, 65, 66, 68, 70],
    ),
  ];
}

List<ChartSeries> _mobileLongMarketSession(
  _MobileStylePresentation presentation,
) => [
  _mobileCandles('mobile-market-session', presentation, _candles(3)),
  _mobileLine(
    id: 'mobile-market-session-average',
    name: 'Close average',
    color: presentation.palette[0],
    values: const [
      75,
      76,
      75.7,
      75.3,
      76,
      77.4,
      78.2,
      78.4,
      78.2,
      77.4,
      77,
      76.8,
      77.6,
      79.8,
      81.8,
      82.4,
      83.4,
      84.4,
      84.6,
      85.6,
    ],
  ),
];

CandlestickChartSeries _mobileCandles(
  String id,
  _MobileStylePresentation presentation,
  List<CandlestickDataPoint> points,
) => CandlestickChartSeries(
  id: id,
  name: 'Price',
  points: points,
  candlestickStyle: CandlestickChartStyle(
    risingBodyFillColor: presentation.palette[4],
    risingBorderColor: presentation.palette[4],
    risingWickColor: presentation.palette[4],
    fallingBodyFillColor: presentation.palette[3],
    fallingBorderColor: presentation.palette[3],
    fallingWickColor: presentation.palette[3],
    bodyFillMode: CandlestickBodyFillMode.hollowRising,
    bodyCornerRadius: 2,
  ),
  animation: const CandlestickAnimationStyle(staggerFraction: 0.68),
);

List<PolarColumnChartSeries> _mobilePolarSeries(
  int variant,
  _MobileStylePresentation presentation,
) {
  const categories = ['Direct', 'Search', 'Social', 'Partners', 'Email'];
  const observed = <double>[83, 72, 48, 68, 39];
  const capacity = <double>[96, 88, 74, 82, 64];
  const south = <double>[55, 68, 61, 74, 52];
  const west = <double>[44, 57, 70, 63, 78];
  const style = PolarColumnStyle(
    cornerRadius: 5,
    showDataLabels: false,
    gradient: PolarColumnGradientStyle(
      startLightnessShift: 0.22,
      endLightnessShift: -0.1,
    ),
    animationMode: PolarColumnAnimationMode.sweep,
  );
  if (variant == 1) {
    return [
      PolarColumnChartSeries.fromMap(
        id: 'mobile-polar-capacity',
        name: 'Capacity',
        values: _categoryValues(categories, capacity),
        color: presentation.palette[3],
        polarStyle: style.copyWith(
          opacity: 0.22,
          borderWidth: 1.4,
          borderColor: presentation.palette[3],
        ),
      ),
      PolarColumnChartSeries.fromMap(
        id: 'mobile-polar-observed',
        name: 'Observed',
        values: _categoryValues(categories, observed),
        color: presentation.palette[0],
        polarStyle: style.copyWith(
          showDataLabels: true,
          maximumVisibleDataLabels: 5,
          dataLabelRadialPosition: 0.56,
          dataLabelStyle: const PolarLabelStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ];
  }
  if (variant == 3) {
    const balanceCategories = [
      'Direct',
      'Search',
      'Social',
      'Partners',
      'Email',
      'Events',
    ];
    const committed = <double>[37, 34, 26, 31, 19, 28];
    const flexible = <double>[20, 16, 12, 18, 11, 15];
    const shortfall = <double>[-15, -13, -21, -12, -17, -10];
    return [
      PolarColumnChartSeries.fromMap(
        id: 'mobile-polar-committed',
        name: 'Committed',
        values: _categoryValues(balanceCategories, committed),
        color: presentation.palette[0],
        polarStyle: style,
      ),
      PolarColumnChartSeries.fromMap(
        id: 'mobile-polar-flexible',
        name: 'Flexible',
        values: _categoryValues(balanceCategories, flexible),
        color: presentation.palette[2],
        polarStyle: style,
      ),
      PolarColumnChartSeries.fromMap(
        id: 'mobile-polar-shortfall',
        name: 'Shortfall',
        values: _categoryValues(balanceCategories, shortfall),
        color: presentation.palette[4],
        polarStyle: style,
      ),
    ];
  }
  return [
    for (final (index, values) in [observed, south, west].indexed)
      PolarColumnChartSeries.fromMap(
        id: 'mobile-polar-region-$index',
        name: ['North', 'South', 'West'][index],
        values: _categoryValues(categories, values),
        color: presentation.palette[index],
        polarStyle: style,
      ),
  ];
}

Map<String, num> _categoryValues(
  List<String> categories,
  List<double> values,
) => {
  for (var index = 0; index < categories.length; index++)
    categories[index]: values[index],
};

List<ChartDataPoint> _labelledPoints(
  List<String> labels,
  List<double> values, {
  List<Color>? colors,
}) => [
  for (var index = 0; index < values.length; index++)
    ChartDataPoint(
      x: index.toDouble(),
      y: values[index],
      label: labels[index],
      pointStyle: colors == null
          ? null
          : PointStyle.color(colors[index % colors.length]),
    ),
];

List<ChartDataPoint> _points(List<double> values) => [
  for (var index = 0; index < values.length; index++)
    ChartDataPoint(x: index + 1, y: values[index]),
];

List<ChartDataPoint> _xyPoints(List<double> x, List<double> y) => [
  for (var index = 0; index < x.length; index++)
    ChartDataPoint(x: x[index], y: y[index]),
];

List<RangeAreaDataPoint> _rangePoints(List<double> lows, List<double> highs) =>
    [
      for (var index = 0; index < lows.length; index++)
        RangeAreaDataPoint(x: index + 1, low: lows[index], high: highs[index]),
    ];

Map<String, Color> _sliceColors(
  Iterable<String> categories,
  List<Color> palette,
) => {
  for (final (index, category) in categories.indexed)
    category: palette[index % palette.length],
};

List<CandlestickDataPoint> _candles(int variant) {
  final source = switch (variant) {
    1 => const [
      (38.0, 44.0, 36.0, 42.0),
      (42.0, 47.0, 40.0, 45.0),
      (45.0, 46.0, 39.0, 41.0),
      (41.0, 48.0, 40.0, 47.0),
      (47.0, 52.0, 45.0, 50.0),
      (50.0, 53.0, 47.0, 49.0),
      (49.0, 56.0, 48.0, 54.0),
    ],
    3 => const [
      (72.0, 76.0, 70.0, 75.0),
      (75.0, 79.0, 73.0, 77.0),
      (77.0, 80.0, 74.0, 75.0),
      (75.0, 78.0, 72.0, 74.0),
      (74.0, 81.0, 73.0, 79.0),
      (79.0, 84.0, 77.0, 82.0),
      (82.0, 85.0, 78.0, 80.0),
      (80.0, 83.0, 76.0, 77.0),
      (77.0, 79.0, 71.0, 73.0),
      (73.0, 76.0, 69.0, 75.0),
      (75.0, 80.0, 72.0, 78.0),
      (78.0, 82.0, 76.0, 79.0),
      (79.0, 84.0, 77.0, 83.0),
      (83.0, 87.0, 80.0, 85.0),
      (85.0, 88.0, 82.0, 84.0),
      (84.0, 86.0, 79.0, 81.0),
      (81.0, 85.0, 78.0, 84.0),
      (84.0, 90.0, 82.0, 88.0),
      (88.0, 92.0, 85.0, 86.0),
      (86.0, 91.0, 83.0, 89.0),
    ],
    _ => const [
      (62.0, 66.0, 59.0, 64.0),
      (64.0, 65.0, 58.0, 60.0),
      (60.0, 67.0, 59.0, 66.0),
      (66.0, 71.0, 64.0, 69.0),
      (69.0, 70.0, 63.0, 65.0),
      (65.0, 72.0, 64.0, 70.0),
      (70.0, 75.0, 68.0, 73.0),
    ],
  };
  return [
    for (var index = 0; index < source.length; index++)
      CandlestickDataPoint(
        x: index + 1,
        open: source[index].$1,
        high: source[index].$2,
        low: source[index].$3,
        close: source[index].$4,
      ),
  ];
}

PieDataLabelConfig _mobileRadialSplitCallouts(
  _MobileStylePresentation presentation, {
  double minimumShare = 0.08,
}) => PieDataLabelConfig(
  position: PieDataLabelPosition.outside,
  content: PieDataLabelContent.category,
  secondaryContent: PieDataLabelContent.percentage,
  secondaryPosition: PieDataLabelPosition.inside,
  minimumShare: minimumShare,
  minimumSweepDegrees: 8,
  padding: 3,
  insideOffset: 2,
  connectorLength: 10,
  connectorWidth: 1,
  collisionStrategy: PieDataLabelCollisionStrategy.shiftAndHide,
  calloutStyle: LabelStyle(
    textStyle: TextStyle(
      color: presentation.onSurface,
      fontSize: 8.5,
      fontWeight: FontWeight.w500,
    ),
    backgroundColor: Colors.transparent,
    borderColor: Colors.transparent,
    borderWidth: 0,
    borderRadius: 0,
    padding: EdgeInsets.zero,
  ),
  secondaryCalloutStyle: LabelStyle(
    textStyle: TextStyle(
      color: presentation.surface,
      fontSize: 8,
      fontWeight: FontWeight.w700,
    ),
    backgroundColor: presentation.onSurface.withValues(alpha: 0.82),
    borderColor: presentation.surface.withValues(alpha: 0.5),
    borderWidth: 0.8,
    borderRadius: 4,
    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
  ),
);

List<ChartSeries> _concentricSeries(
  int variant,
  _MobileStylePresentation presentation,
) {
  if (variant == 3) {
    const ringValues = <(String, double)>[
      ('Movement', 92),
      ('Recovery', 76),
      ('Focus', 61),
      ('Hydration', 44),
    ];
    return [
      for (final (index, ring) in ringValues.indexed)
        DonutChartSeries.fromMap(
          id: 'mobile-concentric-3-$index',
          name: ring.$1,
          values: {'Complete': ring.$2, 'Remaining': 100 - ring.$2},
          sliceColors: {
            'Complete': presentation.palette[index],
            'Remaining': presentation.palette[index].withValues(alpha: 0.16),
          },
          dataLabels: const PieDataLabelConfig(isVisible: false),
          donutStyle: DonutChartStyle(
            radiusFactor: 0.98,
            sliceGap: 1.5,
            cornerRadius: 6,
            borderWidth: 1,
            borderColorMode: PieBorderColorMode.slice,
            borderLightnessShift: -0.14,
            gradient: PieGradientStyle(
              type: index.isEven
                  ? PieGradientType.linear
                  : PieGradientType.radial,
              angleDegrees: -45 + index * 30,
              startLightnessShift: 0.18,
              endLightnessShift: -0.08,
            ),
            selectionExplodeOffset: 0,
            animationMode: PieAnimationMode.sweep,
          ),
        ),
    ];
  }
  final seriesValues = switch (variant) {
    1 => const <Map<String, num>>[
      {'Subscriptions': 45, 'Services': 30, 'Enterprise': 15, 'Training': 10},
      {'Subscriptions': 30, 'Services': 35, 'Enterprise': 25, 'Training': 10},
      {'Subscriptions': 30, 'Services': 25, 'Enterprise': 28, 'Training': 17},
    ],
    _ => const <Map<String, num>>[
      {'Core': 52, 'Growth': 28, 'Other': 20},
      {'Consulting': 38, 'Support': 34, 'Training': 28},
      {'Email': 42, 'Chat': 36, 'Docs': 22},
    ],
  };
  final alignedColors = _sliceColors(seriesValues.first.keys, [
    presentation.palette[0],
    presentation.palette[1],
    presentation.palette[2],
    presentation.palette[3],
  ]);
  return [
    for (var index = 0; index < 3; index++)
      DonutChartSeries.fromMap(
        id: 'mobile-concentric-$variant-$index',
        name: variant == 1
            ? ['Current', 'Previous', 'Forecast'][index]
            : ['Platform', 'Services', 'Support'][index],
        values: seriesValues[index],
        sliceColors: variant == 1
            ? alignedColors
            : _sliceColors(seriesValues[index].keys, [
                presentation.palette[index],
                presentation.palette[(index + 2) % 5],
                presentation.palette[(index + 4) % 5],
              ]),
        dataLabels: variant == 1 && index == 0
            ? _mobileRadialSplitCallouts(presentation, minimumShare: 0.09)
            : const PieDataLabelConfig(isVisible: false),
        donutStyle: DonutChartStyle(
          radiusFactor: 0.98,
          sweepAngleDegrees: variant == 2 ? 280 : 360,
          startAngleDegrees: variant == 2 ? 130 : -90,
          sliceGap: variant == 2 ? 5 : 2,
          cornerRadius: variant == 2 ? 9 : 4,
          borderWidth: variant == 2 ? 1.4 : 1,
          borderColorMode: PieBorderColorMode.slice,
          borderLightnessShift: -0.18,
          gradient: PieGradientStyle(
            type: index.isEven
                ? PieGradientType.radial
                : PieGradientType.linear,
            angleDegrees: -45 + index * 35,
            startLightnessShift: 0.2,
            endLightnessShift: -0.1,
          ),
          selectionExplodeOffset: 0,
          animationMode: PieAnimationMode.sweep,
        ),
      ),
  ];
}
