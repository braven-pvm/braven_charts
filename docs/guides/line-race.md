# Line race charts

A line race progressively reveals a shared ordered timeline while keeping the
complete X domain fixed. Use it when the story is *how several stable
participants accumulated values over time*. It is not a ranked bar race:
series do not swap layout slots, and the chart never contracts to the current
frontier.

The feature deliberately composes existing chart architecture:

- `LineRaceConfig` is the portable authored timeline.
- `LineRaceController` owns playback, seeking, interpolation, and looping.
- `LineRaceTicker` connects that controller to Flutter's frame clock and
  respects lifecycle, `TickerMode`, and reduced-motion state.
- each snapshot becomes ordinary `LineChartSeries` data;
- `SeriesCalloutConfig` supplies collision-aware moving endpoint labels. Set
  its lane placement to `SeriesCalloutLanePlacement.anchorFrontier` with a
  `lastVisible` anchor so the label lane advances beside the live frame rather
  than remaining pinned to the plot edge. Transparent backgrounds, zero
  borders, and zero label padding produce direct labels; backing panels remain
  available when the host needs more separation from the chart.

This means axes, legends, themes, interactions, Workbench inspection, and
series callouts continue to use their normal implementations.

## Author a timeline

Series IDs must be unique and remain stable. Frame IDs must also be unique, and
frame X values must be finite and strictly increasing. A missing value is an
authored absence: after a series has appeared, it becomes a real path gap rather
than an invented zero or interpolated observation.

```dart
const race = LineRaceConfig(
  series: [
    LineRaceSeries(id: 'north', name: 'North', color: Colors.blue),
    LineRaceSeries(id: 'south', name: 'South', color: Colors.orange),
  ],
  frames: [
    LineRaceFrame(
      id: 'q1',
      label: 'Quarter 1',
      x: 1,
      values: {'north': 18, 'south': 14},
    ),
    LineRaceFrame(
      id: 'q2',
      label: 'Quarter 2',
      x: 2,
      values: {'north': 31, 'south': 35},
    ),
  ],
  durationPerFrame: Duration(milliseconds: 800),
);
```

`LineRaceConfigCodec.encode` and `decode` provide a versioned JSON-safe
document for the authored data, cadence, and loop setting.

## Render from one clock

Create one controller, place the chart under `LineRaceTicker`, and rebuild the
line-series data from `controller.snapshot`. Disable ordinary line data-update
motion so the race controller remains the sole animation clock.

```dart
final controller = LineRaceController(config: race);

LineRaceTicker(
  controller: controller,
  child: AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final snapshot = controller.snapshot;
      final xSpan = controller.xMaximum - controller.xMinimum;
      return BravenChartPlus(
        series: [
          for (final participant in controller.config.series)
            LineChartSeries(
              id: 'race-${participant.id}',
              name: participant.name,
              color: participant.color,
              points: snapshot.pointsFor(participant.id),
              isXOrdered: true,
              pathAnimation: const PathAnimationStyle(
                entranceMode: PathEntranceAnimationMode.none,
                dataUpdateMode: PathDataUpdateAnimationMode.none,
              ),
            ),
        ],
        xAxisConfig: XAxisConfig(
          min: controller.xMinimum,
          max: controller.xMaximum + xSpan * 0.12,
          // Preserve the final authored round as the last visible tick.
          renderMax: controller.xMaximum,
        ),
        seriesCallouts: const SeriesCalloutConfig(
          enabled: true,
          lanePlacement: SeriesCalloutLanePlacement.anchorFrontier,
          anchor: SeriesCalloutAnchor.lastVisible,
          packing: SeriesCalloutPacking.hideCollisions,
          inset: 8,
          minimumGap: 5,
          collisionFadeDuration: Duration(milliseconds: 180),
          labelPadding: EdgeInsets.zero,
          backgroundOpacity: 0,
          borderWidth: 0,
        ),
      );
    },
  ),
);
```

Use `play`, `pause`, `toggle`, `next`, `previous`, `seek`, and `setSpeed` to
build application controls. Seeking settles immediately and pauses playback.
Looping returns to the first settled frame without drawing a false line from
the last frame back to the first.

The example above reserves 12% of the authored X span as responsive right-side
headroom. This keeps frontier labels inside the plot at the final frame without
inventing later rounds: `max` controls scaling, while `renderMax` keeps ticks
bounded to the real timeline. The showcase exposes the same setting as
**Right axis padding**.

## Maintained showcase

Open `?page=line-charts&preset=race` in the example application. The F1 season
preset exercises ten stable identities, twenty rounds, lead changes, a fixed
season domain, moving endpoint labels, transport controls, responsive layout,
speed and cadence controls, looping, and callout geometry options. The live
label inspector defaults to exact endpoint alignment and hides lower-priority
collisions rather than moving labels away from their values. It also exposes
an adjustable collision fade, packed-lane alternatives, frontier distance,
side, maximum visible labels,
right-axis padding, optional values, connectors, anchors, text styling, and
optional background and border decoration.
