// Copyright 2025 Braven Charts - Showcase App
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

/// Internal Slice 1 review surface for the pure Candlestick geometry contract.
///
/// This intentionally does not mount [BravenChartPlus]. Native renderer,
/// interaction, and Workbench support begin in Slice 2.
class CandlestickGeometryLabPage extends StatefulWidget {
  const CandlestickGeometryLabPage({super.key});

  @override
  State<CandlestickGeometryLabPage> createState() =>
      _CandlestickGeometryLabPageState();
}

class _CandlestickGeometryLabPageState
    extends State<CandlestickGeometryLabPage> {
  late final CandlestickViewportIndex _irregularIndex;
  late final CandlestickViewportIndex _denseIndex;
  double _bodyWidthFactor = 0.7;
  double _maximumBodyWidth = 18;
  double _cornerRadius = 2;

  @override
  void initState() {
    super.initState();
    _irregularIndex = CandlestickViewportIndex(_irregularCandles());
    _denseIndex = CandlestickViewportIndex(_denseCandles());
  }

  CandlestickChartStyle get _style => CandlestickChartStyle(
    bodyWidthFactor: _bodyWidthFactor,
    maxBodyWidth: _maximumBodyWidth,
    bodyCornerRadius: _cornerRadius,
    minimumBodyHeight: 2,
  );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1320),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _LabHeader(),
                  const SizedBox(height: 24),
                  _GeometryControls(
                    bodyWidthFactor: _bodyWidthFactor,
                    maximumBodyWidth: _maximumBodyWidth,
                    cornerRadius: _cornerRadius,
                    onBodyWidthFactorChanged: (value) {
                      setState(() => _bodyWidthFactor = value);
                    },
                    onMaximumBodyWidthChanged: (value) {
                      setState(() => _maximumBodyWidth = value);
                    },
                    onCornerRadiusChanged: (value) {
                      setState(() => _cornerRadius = value);
                    },
                  ),
                  const SizedBox(height: 24),
                  _GeometryPanel(
                    title: 'Direction and irregular time',
                    description:
                        'Hollow rising bodies, filled falling bodies, doji marks, and a real X gap',
                    sourceLabel: '16 source · 16 visible',
                    index: _irregularIndex,
                    xMin: -0.8,
                    xMax: 23.8,
                    yMin: 88,
                    yMax: 126,
                    height: 360,
                    style: _style,
                  ),
                  const SizedBox(height: 24),
                  _GeometryPanel(
                    title: 'Viewport culling',
                    description:
                        'A binary-searched window from 5,000 ordered source candles',
                    sourceLabel: '5,000 source · 100 visible',
                    index: _denseIndex,
                    xMin: 2450,
                    xMax: 2549,
                    yMin: 86,
                    yMax: 126,
                    height: 240,
                    style: _style,
                  ),
                  const SizedBox(height: 24),
                  const _ContractSummary(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LabHeader extends StatelessWidget {
  const _LabHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.secondaryContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'Slice 1 · geometry lab',
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onSecondaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Candlestick geometry foundation',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Text(
            'Review OHLC shape, spacing, doji visibility, and viewport culling before native chart painting begins.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _GeometryControls extends StatelessWidget {
  const _GeometryControls({
    required this.bodyWidthFactor,
    required this.maximumBodyWidth,
    required this.cornerRadius,
    required this.onBodyWidthFactorChanged,
    required this.onMaximumBodyWidthChanged,
    required this.onCornerRadiusChanged,
  });

  final double bodyWidthFactor;
  final double maximumBodyWidth;
  final double cornerRadius;
  final ValueChanged<double> onBodyWidthFactorChanged;
  final ValueChanged<double> onMaximumBodyWidthChanged;
  final ValueChanged<double> onCornerRadiusChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 24,
          runSpacing: 16,
          children: [
            _LabSlider(
              label: 'Body width factor',
              valueLabel: bodyWidthFactor.toStringAsFixed(2),
              value: bodyWidthFactor,
              min: 0.25,
              max: 1,
              divisions: 15,
              onChanged: onBodyWidthFactorChanged,
            ),
            _LabSlider(
              label: 'Maximum body width',
              valueLabel: '${maximumBodyWidth.toStringAsFixed(0)} px',
              value: maximumBodyWidth,
              min: 8,
              max: 32,
              divisions: 12,
              onChanged: onMaximumBodyWidthChanged,
            ),
            _LabSlider(
              label: 'Corner radius',
              valueLabel: '${cornerRadius.toStringAsFixed(0)} px',
              value: cornerRadius,
              min: 0,
              max: 8,
              divisions: 8,
              onChanged: onCornerRadiusChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _LabSlider extends StatelessWidget {
  const _LabSlider({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(valueLabel, style: textTheme.labelMedium),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: valueLabel,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _GeometryPanel extends StatelessWidget {
  const _GeometryPanel({
    required this.title,
    required this.description,
    required this.sourceLabel,
    required this.index,
    required this.xMin,
    required this.xMax,
    required this.yMin,
    required this.yMax,
    required this.height,
    required this.style,
  });

  final String title;
  final String description;
  final String sourceLabel;
  final CandlestickViewportIndex index;
  final double xMin;
  final double xMax;
  final double yMin;
  final double yMax;
  final double height;
  final CandlestickChartStyle style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final descriptionBlock = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                );
                final sourceText = Text(
                  sourceLabel,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                );
                if (constraints.maxWidth < 720) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      descriptionBlock,
                      const SizedBox(height: 8),
                      sourceText,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: descriptionBlock),
                    const SizedBox(width: 24),
                    sourceText,
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            _DirectionLegend(scheme: scheme),
            const SizedBox(height: 8),
            SizedBox(
              height: height,
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _CandlestickGeometryLabPainter(
                    index: index,
                    style: style,
                    xMin: xMin,
                    xMax: xMax,
                    yMin: yMin,
                    yMax: yMax,
                    scheme: scheme,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectionLegend extends StatelessWidget {
  const _DirectionLegend({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 16,
    runSpacing: 8,
    children: [
      _LegendItem(
        label: 'Rising · hollow',
        icon: Icons.crop_square,
        color: scheme.primary,
      ),
      _LegendItem(
        label: 'Falling · filled',
        icon: Icons.square,
        color: scheme.error,
      ),
      _LegendItem(
        label: 'Doji · line',
        icon: Icons.horizontal_rule,
        color: scheme.tertiary,
      ),
    ],
  );
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 18, color: color),
      const SizedBox(width: 8),
      Text(label, style: Theme.of(context).textTheme.labelMedium),
    ],
  );
}

class _ContractSummary extends StatelessWidget {
  const _ContractSummary();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(label: Text('Close is canonical Y')),
            Chip(label: Text('Bounds use low and high')),
            Chip(label: Text('Strict ordered X')),
            Chip(label: Text('Median interval width')),
            Chip(label: Text('Binary-search culling')),
            Chip(label: Text('DPR-aligned centers')),
          ],
        ),
      ),
    );
  }
}

class _CandlestickGeometryLabPainter extends CustomPainter {
  _CandlestickGeometryLabPainter({
    required this.index,
    required this.style,
    required this.xMin,
    required this.xMax,
    required this.yMin,
    required this.yMax,
    required this.scheme,
  });

  final CandlestickViewportIndex index;
  final CandlestickChartStyle style;
  final double xMin;
  final double xMax;
  final double yMin;
  final double yMax;
  final ColorScheme scheme;

  @override
  void paint(Canvas canvas, Size size) {
    const leftInset = 48.0;
    const bottomInset = 28.0;
    const topInset = 8.0;
    const rightInset = 8.0;
    final plotSize = Size(
      math.max(1, size.width - leftInset - rightInset),
      math.max(1, size.height - topInset - bottomInset),
    );
    final transform = ChartTransform(
      dataXMin: xMin,
      dataXMax: xMax,
      dataYMin: yMin,
      dataYMax: yMax,
      plotWidth: plotSize.width,
      plotHeight: plotSize.height,
    );
    final geometry = CandlestickGeometryEngine.resolve(
      index: index,
      transform: transform,
      style: style,
      devicePixelRatio: 1,
    );

    canvas.save();
    canvas.translate(leftInset, topInset);
    _paintGrid(canvas, plotSize);
    canvas.clipRect(Offset.zero & plotSize);

    final wickPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.wickWidth;
    final bodyPaint = Paint();
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.bodyBorderWidth;

    for (final candle in geometry) {
      final color = switch (candle.direction) {
        CandlestickDirection.rising => scheme.primary,
        CandlestickDirection.falling => scheme.error,
        CandlestickDirection.doji => scheme.tertiary,
      };
      wickPaint.color = color;
      borderPaint.color = color;
      if (style.showWicks) {
        canvas.drawLine(candle.upperWickStart, candle.upperWickEnd, wickPaint);
        canvas.drawLine(candle.lowerWickStart, candle.lowerWickEnd, wickPaint);
      }
      if (candle.direction == CandlestickDirection.doji) {
        canvas.drawLine(
          candle.bodyRect.centerLeft,
          candle.bodyRect.centerRight,
          borderPaint,
        );
      } else {
        final isHollow = candle.direction == CandlestickDirection.rising;
        if (!isHollow) {
          bodyPaint
            ..style = PaintingStyle.fill
            ..color = color;
          canvas.drawRRect(candle.bodyRRect, bodyPaint);
        }
        if (style.showBodyBorder) {
          canvas.drawRRect(candle.bodyRRect, borderPaint);
        }
      }
    }
    canvas.restore();
  }

  void _paintGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = scheme.outlineVariant.withValues(alpha: 0.65)
      ..strokeWidth = 1;
    for (var line = 0; line <= 4; line++) {
      final y = size.height * line / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (var line = 0; line <= 6; line++) {
      final x = size.width * line / 6;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    final axisPaint = Paint()
      ..color = scheme.outline
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height),
      size.bottomRight(Offset.zero),
      axisPaint,
    );
    canvas.drawLine(Offset.zero, Offset(0, size.height), axisPaint);
  }

  @override
  bool shouldRepaint(covariant _CandlestickGeometryLabPainter oldDelegate) =>
      oldDelegate.index != index ||
      oldDelegate.style != style ||
      oldDelegate.xMin != xMin ||
      oldDelegate.xMax != xMax ||
      oldDelegate.yMin != yMin ||
      oldDelegate.yMax != yMax ||
      oldDelegate.scheme != scheme;
}

List<CandlestickDataPoint> _irregularCandles() {
  final closes = <double>[
    101,
    104,
    102,
    107,
    107,
    105,
    109,
    113,
    111,
    115,
    112,
    116,
    114,
    119,
    117,
    121,
  ];
  final xValues = <double>[
    0,
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    14,
    15,
    16,
    17,
    18,
    19,
    20,
    21,
  ];
  return [
    for (var index = 0; index < closes.length; index++)
      CandlestickDataPoint(
        x: xValues[index],
        open: index == 0 ? 99 : closes[index - 1],
        high: math.max(index == 0 ? 99 : closes[index - 1], closes[index]) + 3,
        low: math.min(index == 0 ? 99 : closes[index - 1], closes[index]) - 3,
        close: closes[index],
      ),
  ];
}

List<CandlestickDataPoint> _denseCandles() => [
  for (var index = 0; index < 5000; index++)
    CandlestickDataPoint(
      x: index.toDouble(),
      open: 104 + math.sin(index / 17) * 7,
      high:
          math.max(
            104 + math.sin(index / 17) * 7,
            104 + math.sin((index + 1) / 17) * 7,
          ) +
          2,
      low:
          math.min(
            104 + math.sin(index / 17) * 7,
            104 + math.sin((index + 1) / 17) * 7,
          ) -
          2,
      close: 104 + math.sin((index + 1) / 17) * 7,
    ),
];
