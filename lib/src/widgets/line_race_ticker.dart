import 'package:flutter/material.dart';

import '../controllers/line_race_controller.dart';

/// Advances a [LineRaceController] using Flutter's frame clock.
class LineRaceTicker extends StatefulWidget {
  const LineRaceTicker({
    required this.controller,
    required this.child,
    super.key,
    this.disableMotion = false,
  });

  final LineRaceController controller;
  final Widget child;
  final bool disableMotion;

  @override
  State<LineRaceTicker> createState() => _LineRaceTickerState();
}

class _LineRaceTickerState extends State<LineRaceTicker>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _clock;
  bool _tickerEnabled = true;
  bool _updatingController = false;

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
  void didUpdateWidget(LineRaceTicker oldWidget) {
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
    if (!mounted || _updatingController) return;
    if (!widget.controller.isPlaying || !_tickerEnabled) {
      _clock.stop();
      widget.controller.completeTransition();
      return;
    }
    if (_motionDisabled) {
      widget.controller.completeTransition();
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
    _updatingController = true;
    try {
      widget.controller.updateTransitionProgress(_clock.value);
    } finally {
      _updatingController = false;
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
