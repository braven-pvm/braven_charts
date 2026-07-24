import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;

/// Focused phone/tablet review surface for direct-touch viewport interaction.
class MobileInteractionPage extends StatefulWidget {
  const MobileInteractionPage({super.key});

  @override
  State<MobileInteractionPage> createState() => _MobileInteractionPageState();
}

class _MobileInteractionPageState extends State<MobileInteractionPage> {
  final BravenChartController _controller = BravenChartController();
  TouchInteractionProfile _profile = TouchInteractionProfile.browse;
  Map<String, double>? _visibleBounds;
  int _viewportUpdates = 0;
  bool _enableTrackingScrub = true;
  bool _enableHaptics = true;
  bool _enablePanInertia = true;
  double _panInertiaDeceleration = 6;
  double? _trackedDay;

  late final List<ChartDataPoint> _primary = _signal(phase: 0);
  late final List<ChartDataPoint> _comparison = _signal(phase: 0.8);

  static List<ChartDataPoint> _signal({required double phase}) {
    return List<ChartDataPoint>.generate(28, (index) {
      final x = index.toDouble();
      return ChartDataPoint(
        x: x,
        y:
            54 +
            math.sin(x * 0.48 + phase) * 12 +
            math.cos(x * 0.19 - phase) * 5 +
            x * 0.35,
      );
    }, growable: false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setProfile(TouchInteractionProfile profile) {
    if (_profile == profile) return;
    setState(() => _profile = profile);
  }

  void _onViewportChanged(Map<String, double> bounds) {
    if (!mounted) return;
    setState(() {
      _visibleBounds = bounds;
      _viewportUpdates++;
    });
  }

  void _onCrosshairChanged(Offset? position, List<ChartDataPoint> snapPoints) {
    final trackedDay = position == null || snapPoints.isEmpty
        ? null
        : snapPoints.first.x;
    if (!mounted || trackedDay == _trackedDay) return;
    setState(() => _trackedDay = trackedDay);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isBrowse = _profile == TouchInteractionProfile.browse;
    final isPhone = MediaQuery.sizeOf(context).width < 600;

    return ColoredBox(
      color: colors.surface,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 80),
        children: [
          Text(
            'Mobile interaction',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Test page scrolling, chart exploration, selection, and viewport controls with real touch input.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          _ProfileSelector(profile: _profile, onChanged: _setProfile),
          const SizedBox(height: 12),
          _InstructionCard(
            icon: isBrowse ? Icons.swipe_vertical : Icons.pan_tool_alt_outlined,
            title: isBrowse
                ? 'Browse: the page keeps one finger'
                : 'Explore: the chart keeps one finger',
            message: isBrowse
                ? 'Drag with one finger to scroll this page. Use two fingers together to pan and pinch the chart.'
                : 'Drag the chart with one finger to pan. Pinch with two fingers to zoom. Scroll the page outside the chart.',
          ),
          const SizedBox(height: 12),
          _TrackingControls(
            enabled: _enableTrackingScrub,
            hapticsEnabled: _enableHaptics,
            inertiaEnabled: _enablePanInertia,
            inertiaDeceleration: _panInertiaDeceleration,
            trackedDay: _trackedDay,
            onEnabledChanged: (value) {
              setState(() {
                _enableTrackingScrub = value;
                if (!value) _trackedDay = null;
              });
            },
            onHapticsChanged: (value) {
              setState(() => _enableHaptics = value);
            },
            onInertiaChanged: (value) {
              setState(() => _enablePanInertia = value);
            },
            onInertiaDecelerationChanged: (value) {
              setState(() => _panInertiaDeceleration = value);
            },
          ),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ChartHeader(
                    bounds: _visibleBounds,
                    updates: _viewportUpdates,
                  ),
                  const SizedBox(height: 10),
                  if (isPhone) ...[
                    _SeriesLegend(
                      recoveryColor: colors.primary,
                      capacityColor: colors.tertiary,
                    ),
                    const SizedBox(height: 4),
                  ],
                  SizedBox(
                    key: const ValueKey('mobile-interaction-chart'),
                    height: 330,
                    child: BravenChartPlus(
                      bravenChartController: _controller,
                      showLegend: !isPhone,
                      interactionConfig: InteractionConfig(
                        touch: TouchInteractionConfig(
                          profile: _profile,
                          enablePanInertia: _enablePanInertia,
                          panInertiaDeceleration: _panInertiaDeceleration,
                          enableLongPressTracking: _enableTrackingScrub,
                          enableHapticFeedback: _enableHaptics,
                        ),
                        tooltip: const TooltipConfig(
                          triggerMode: TooltipTriggerMode.tap,
                        ),
                        crosshair: const CrosshairConfig(
                          displayMode: CrosshairDisplayMode.tracking,
                        ),
                        enableFocusOnHover: false,
                        onViewportChanged: _onViewportChanged,
                        onCrosshairChanged: _onCrosshairChanged,
                      ),
                      xAxisConfig: const XAxisConfig(label: 'Day'),
                      yAxis: YAxisConfig(
                        label: 'Load',
                        position: YAxisPosition.left,
                      ),
                      series: [
                        LineChartSeries(
                          id: 'recovery',
                          name: 'Recovery',
                          color: colors.primary,
                          strokeWidth: 2.5,
                          showDataPointMarkers: true,
                          points: _primary,
                        ),
                        LineChartSeries(
                          id: 'capacity',
                          name: 'Capacity',
                          color: colors.tertiary,
                          strokeWidth: 2,
                          showDataPointMarkers: true,
                          points: _comparison,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ViewportControls(controller: _controller),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Scroll checkpoint',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'If you can reach this text by dragging directly over the chart in Browse mode, gesture arbitration is working. In Explore mode, start the page scroll beside or below the chart.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          _ContractSummary(profile: _profile),
        ],
      ),
    );
  }
}

class _TrackingControls extends StatelessWidget {
  const _TrackingControls({
    required this.enabled,
    required this.hapticsEnabled,
    required this.inertiaEnabled,
    required this.inertiaDeceleration,
    required this.trackedDay,
    required this.onEnabledChanged,
    required this.onHapticsChanged,
    required this.onInertiaChanged,
    required this.onInertiaDecelerationChanged,
  });

  final bool enabled;
  final bool hapticsEnabled;
  final bool inertiaEnabled;
  final double inertiaDeceleration;
  final double? trackedDay;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<bool> onHapticsChanged;
  final ValueChanged<bool> onInertiaChanged;
  final ValueChanged<double> onInertiaDecelerationChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
        child: Column(
          children: [
            SwitchListTile.adaptive(
              title: const Text('Long-press tracking'),
              subtitle: const Text(
                'Hold the plot, drag to scrub, then lift to clear.',
              ),
              secondary: const Icon(Icons.touch_app_outlined),
              value: enabled,
              onChanged: onEnabledChanged,
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            SwitchListTile.adaptive(
              title: const Text('Haptic steps'),
              subtitle: const Text(
                'Feedback on activation and each snapped day.',
              ),
              secondary: const Icon(Icons.vibration_outlined),
              value: hapticsEnabled,
              onChanged: enabled ? onHapticsChanged : null,
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            SwitchListTile.adaptive(
              title: const Text('Pan inertia'),
              subtitle: const Text(
                'Release a moving pan to let the viewport coast and settle.',
              ),
              secondary: const Icon(Icons.air_outlined),
              value: inertiaEnabled,
              onChanged: onInertiaChanged,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Row(
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    child: Slider(
                      value: inertiaDeceleration,
                      min: 3,
                      max: 12,
                      divisions: 9,
                      label: inertiaDeceleration.toStringAsFixed(0),
                      onChanged: inertiaEnabled
                          ? onInertiaDecelerationChanged
                          : null,
                    ),
                  ),
                  SizedBox(
                    width: 74,
                    child: Text(
                      '${inertiaDeceleration.toStringAsFixed(0)} / sec',
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
              child: Row(
                children: [
                  Icon(
                    trackedDay == null
                        ? Icons.radio_button_unchecked
                        : Icons.adjust,
                    size: 18,
                    color: trackedDay == null
                        ? colors.onSurfaceVariant
                        : colors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      trackedDay == null
                          ? 'Hold inside the plot to start'
                          : 'Tracking day ${trackedDay!.toStringAsFixed(0)}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: trackedDay == null
                            ? colors.onSurfaceVariant
                            : colors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSelector extends StatelessWidget {
  const _ProfileSelector({required this.profile, required this.onChanged});

  final TouchInteractionProfile profile;
  final ValueChanged<TouchInteractionProfile> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<TouchInteractionProfile>(
      segments: const [
        ButtonSegment(
          value: TouchInteractionProfile.browse,
          icon: Icon(Icons.chrome_reader_mode_outlined),
          label: Text('Browse'),
        ),
        ButtonSegment(
          value: TouchInteractionProfile.explore,
          icon: Icon(Icons.travel_explore_outlined),
          label: Text('Explore'),
        ),
      ],
      selected: {profile},
      expandedInsets: EdgeInsets.zero,
      showSelectedIcon: false,
      onSelectionChanged: (selection) => onChanged(selection.single),
      style: const ButtonStyle(
        minimumSize: WidgetStatePropertyAll(Size.fromHeight(48)),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
    );
  }
}

class _InstructionCard extends StatelessWidget {
  const _InstructionCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colors.onPrimaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewportControls extends StatelessWidget {
  const _ViewportControls({required this.controller});

  final BravenChartController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final zoomOut = OutlinedButton.icon(
          onPressed: () => controller.zoomViewport(0.8),
          icon: const Icon(Icons.zoom_out),
          label: const Text('Zoom out'),
          style: const ButtonStyle(
            minimumSize: WidgetStatePropertyAll(Size.fromHeight(48)),
          ),
        );
        final fitData = FilledButton.tonalIcon(
          onPressed: controller.fitData,
          icon: const Icon(Icons.fit_screen_outlined),
          label: const Text('Fit data'),
          style: const ButtonStyle(
            minimumSize: WidgetStatePropertyAll(Size.fromHeight(48)),
          ),
        );
        final zoomIn = OutlinedButton.icon(
          onPressed: () => controller.zoomViewport(1.25),
          icon: const Icon(Icons.zoom_in),
          label: const Text('Zoom in'),
          style: const ButtonStyle(
            minimumSize: WidgetStatePropertyAll(Size.fromHeight(48)),
          ),
        );
        if (constraints.maxWidth < 430) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: zoomOut),
                  const SizedBox(width: 8),
                  Expanded(child: zoomIn),
                ],
              ),
              const SizedBox(height: 8),
              fitData,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: zoomOut),
            const SizedBox(width: 8),
            Expanded(child: fitData),
            const SizedBox(width: 8),
            Expanded(child: zoomIn),
          ],
        );
      },
    );
  }
}

class _ChartHeader extends StatelessWidget {
  const _ChartHeader({required this.bounds, required this.updates});

  final Map<String, double>? bounds;
  final int updates;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recovery load',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Tap a point to inspect it. Transform the viewport using the active profile.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final badge = _ViewportBadge(bounds: bounds, updates: updates);
        if (constraints.maxWidth < 430) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              copy,
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerLeft, child: badge),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: copy),
            const SizedBox(width: 8),
            badge,
          ],
        );
      },
    );
  }
}

class _SeriesLegend extends StatelessWidget {
  const _SeriesLegend({
    required this.recoveryColor,
    required this.capacityColor,
  });

  final Color recoveryColor;
  final Color capacityColor;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 12,
      runSpacing: 4,
      children: [
        _SeriesLegendItem(color: recoveryColor, label: 'Recovery'),
        _SeriesLegendItem(color: capacityColor, label: 'Capacity'),
      ],
    );
  }
}

class _SeriesLegendItem extends StatelessWidget {
  const _SeriesLegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _ViewportBadge extends StatelessWidget {
  const _ViewportBadge({required this.bounds, required this.updates});

  final Map<String, double>? bounds;
  final int updates;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final label = bounds == null
        ? 'Full range'
        : 'X ${bounds!['minX']!.toStringAsFixed(1)}–${bounds!['maxX']!.toStringAsFixed(1)}';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            Text(
              '$updates updates',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContractSummary extends StatelessWidget {
  const _ContractSummary({required this.profile});

  final TouchInteractionProfile profile;

  @override
  Widget build(BuildContext context) {
    final isBrowse = profile == TouchInteractionProfile.browse;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active gesture contract',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            _ContractRow(
              gesture: 'One-finger drag',
              result: isBrowse ? 'Scroll page' : 'Pan chart',
            ),
            const _ContractRow(gesture: 'Two-finger drag', result: 'Pan chart'),
            const _ContractRow(gesture: 'Pinch', result: 'Zoom at fingers'),
            const _ContractRow(gesture: 'Tap point', result: 'Inspect/select'),
            const _ContractRow(
              gesture: 'Hold + drag',
              result: 'Scrub tracking',
            ),
          ],
        ),
      ),
    );
  }
}

class _ContractRow extends StatelessWidget {
  const _ContractRow({required this.gesture, required this.result});

  final String gesture;
  final String result;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(gesture)),
          const Icon(Icons.arrow_forward, size: 16),
          const SizedBox(width: 10),
          Expanded(child: Text(result)),
        ],
      ),
    );
  }
}
