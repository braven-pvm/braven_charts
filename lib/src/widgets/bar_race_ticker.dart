import 'package:flutter/material.dart';

import '../controllers/bar_race_controller.dart';

/// Advances a [BarRaceController] using Flutter's frame clock.
///
/// The widget is intentionally presentation-free so applications can compose
/// their own playback controls and chart surface.
class BarRaceTicker extends StatefulWidget {
  const BarRaceTicker({
    required this.controller,
    required this.child,
    super.key,
    this.disableMotion = false,
  });

  final BarRaceController controller;
  final Widget child;
  final bool disableMotion;

  @override
  State<BarRaceTicker> createState() => _BarRaceTickerState();
}

class _BarRaceTickerState extends State<BarRaceTicker>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _clock;
  bool _tickerEnabled = true;
  bool _updatingAxis = false;

  bool get _motionDisabled =>
      widget.disableMotion ||
      (MediaQuery.maybeOf(context)?.disableAnimations ?? false);

  @override
  void initState() {
    super.initState();
    _clock = AnimationController(vsync: this)
      ..addListener(_handleClockTick)
      ..addStatusListener(_handleClockStatus);
    WidgetsBinding.instance.addObserver(this);
    widget.controller.addListener(_syncClock);
    _syncClock();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tickerEnabled = TickerMode.of(context);
    if (!_tickerEnabled && widget.controller.isPlaying) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_tickerEnabled) widget.controller.pause();
      });
    }
    _syncClock();
  }

  @override
  void didUpdateWidget(BarRaceTicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_syncClock);
      widget.controller.addListener(_syncClock);
    }
    _syncClock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(_syncClock);
    _clock
      ..removeListener(_handleClockTick)
      ..removeStatusListener(_handleClockStatus)
      ..dispose();
    super.dispose();
  }

  void _syncClock() {
    if (!mounted) return;
    if (_updatingAxis) return;
    if (!widget.controller.isPlaying || !_tickerEnabled) {
      _clock.stop();
      widget.controller.completeAxisTransition();
      return;
    }
    if (_motionDisabled) {
      widget.controller.completeAxisTransition();
      final duration = widget.controller.effectiveDuration;
      if (_clock.duration != duration || !_clock.isAnimating) {
        _clock
          ..duration = duration
          ..forward(from: 0);
      }
      return;
    }
    final duration = widget.controller.effectiveDuration;
    if (_clock.duration != duration || !_clock.isAnimating) {
      _clock
        ..duration = duration
        ..forward(from: 0);
    }
  }

  void _handleClockTick() {
    if (_motionDisabled) return;
    _updatingAxis = true;
    try {
      widget.controller.updateAxisTransitionProgress(_clock.value);
    } finally {
      _updatingAxis = false;
    }
  }

  void _handleClockStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && widget.controller.isPlaying) {
      widget.controller.next();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) widget.controller.pause();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
