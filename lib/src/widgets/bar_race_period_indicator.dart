import 'package:flutter/material.dart';

import '../controllers/bar_race_controller.dart';
import '../models/bar_race.dart';

/// A prominent, theme-aware label for the active temporal frame of a bar race.
///
/// Compose this over the chart with a [Stack]. The widget ignores pointer
/// events so it never blocks chart tracking, selection, or drill-down.
class BarRacePeriodIndicator extends StatelessWidget {
  const BarRacePeriodIndicator({
    required this.controller,
    super.key,
    this.periodFormatter,
    this.totalFormatter,
  });

  final BarRaceController controller;

  /// Optional runtime override for the portable
  /// [BarRaceConfig.periodFormat] descriptor.
  final String Function(BarRaceFrame frame)? periodFormatter;

  /// Formats the optional frame total shown beneath the period.
  ///
  /// When omitted, totals use [BarRaceConfig.totalFormat].
  final String Function(double value)? totalFormatter;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final config = controller.config;
      if (!config.showPeriod) return const SizedBox.shrink();
      final frame = controller.currentFrame;
      final style = config.periodStyle;
      final alignment = switch (style.position) {
        BarRacePeriodPosition.topLeft => Alignment.topLeft,
        BarRacePeriodPosition.topRight => Alignment.topRight,
        BarRacePeriodPosition.bottomLeft => Alignment.bottomLeft,
        BarRacePeriodPosition.bottomRight => Alignment.bottomRight,
      };
      final textAlign = switch (style.position) {
        BarRacePeriodPosition.topLeft ||
        BarRacePeriodPosition.bottomLeft => TextAlign.left,
        BarRacePeriodPosition.topRight ||
        BarRacePeriodPosition.bottomRight => TextAlign.right,
      };
      final theme = Theme.of(context);
      final foreground = style.color ?? theme.colorScheme.onSurface;
      final period =
          periodFormatter?.call(frame) ?? config.periodFormat.format(frame);
      final effectiveTotal = controller.effectiveTotal;
      final total = config.showTotal && effectiveTotal != null
          ? (totalFormatter?.call(effectiveTotal) ??
                config.totalFormat.format(effectiveTotal))
          : null;

      return IgnorePointer(
        child: Semantics(
          container: true,
          excludeSemantics: true,
          liveRegion: true,
          label: total == null ? period : '$period, $total',
          child: Align(
            alignment: alignment,
            child: Padding(
              padding: EdgeInsets.all(style.inset),
              child: Opacity(
                opacity: style.opacity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: switch (textAlign) {
                    TextAlign.left => CrossAxisAlignment.start,
                    _ => CrossAxisAlignment.end,
                  },
                  children: [
                    Text(
                      period,
                      key: ValueKey(frame.id),
                      textAlign: textAlign,
                      style: theme.textTheme.displayLarge?.copyWith(
                        color: foreground,
                        fontSize: style.fontSize,
                        fontWeight: style.fontWeight,
                        height: 1,
                      ),
                    ),
                    if (total != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        total,
                        textAlign: textAlign,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: foreground,
                          fontSize: style.supportingTextSize,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
