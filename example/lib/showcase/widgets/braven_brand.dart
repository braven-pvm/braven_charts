// Copyright 2025 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

/// Compact Braven Charts identity used by the showcase shell and hero areas.
class BravenBrand extends StatelessWidget {
  const BravenBrand({super.key, this.compact = false, this.markSize = 38});

  final bool compact;
  final double markSize;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BravenMark(size: markSize),
        if (!compact) ...[
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Braven Charts',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.25,
                  ),
                ),
                Text(
                  'Flutter charts that keep up.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Code-native chart mark so the brand stays crisp at every display density.
class BravenMark extends StatelessWidget {
  const BravenMark({super.key, this.size = 38});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Braven Charts',
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              colors: [scheme.primary, scheme.tertiary],
            ),
            borderRadius: BorderRadius.circular(size * 0.28),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.22),
                blurRadius: size * 0.35,
                offset: Offset(0, size * 0.12),
              ),
            ],
          ),
          child: const CustomPaint(painter: _BravenMarkPainter()),
        ),
      ),
    );
  }
}

class _BravenMarkPainter extends CustomPainter {
  const _BravenMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = size.width * 0.075
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final pointPaint = Paint()..color = Colors.white;
    final path = Path()
      ..moveTo(size.width * 0.19, size.height * 0.67)
      ..lineTo(size.width * 0.39, size.height * 0.48)
      ..lineTo(size.width * 0.57, size.height * 0.59)
      ..lineTo(size.width * 0.81, size.height * 0.29);

    canvas.drawPath(path, linePaint);
    for (final point in [
      Offset(size.width * 0.19, size.height * 0.67),
      Offset(size.width * 0.39, size.height * 0.48),
      Offset(size.width * 0.57, size.height * 0.59),
      Offset(size.width * 0.81, size.height * 0.29),
    ]) {
      canvas.drawCircle(point, size.width * 0.045, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BravenMarkPainter oldDelegate) => false;
}
