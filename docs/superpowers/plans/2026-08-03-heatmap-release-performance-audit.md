# Heatmap release performance audit

**Register:** BC-0052
**Status:** Review needed
**Baseline revision:** `b60ec846a68e00b2045387fb48ecc1f8e9031c0b`

## Purpose

Heatmap V1 is not release-ready merely because its focused tests pass. This
audit measures the complete shipped family: ordinary matrices, analytical
transforms and overlays, clustered compositions, viewport-backed resident
snapshots, raster tiles, and live mutations. It separates deterministic CI
gates from browser/device evidence so a fast workstation cannot conceal a
regression on a representative target.

The renderer continues to receive immutable resident snapshots. Tile fetching,
cache policy, decoded-resource ownership, and mutation coalescing remain host
controller responsibilities; this audit does not move those concerns into the
render loop.

## Performance budgets

| Surface | Release budget | Gate type |
| --- | ---: | --- |
| Full cached chart paint | p95 < 16.67 ms | Deterministic host benchmark and profile review |
| Heatmap hover/selection overlay | p95 < 1 ms | Deterministic host benchmark |
| Indexed cell hit lookup | p95 < 1 ms | Deterministic host benchmark |
| Chart layout | p95 < 5 ms | Profile review |
| Browser presentation | p95 frame gap <= 20 ms, <= 1% frames over 16.67 ms | Chrome profile/release review |
| Resident regular matrix | <= 12,288 cells, <= 12 cached tiles | Deterministic controller gate |
| Resident raster matrix | <= 16 mounted tiles, <= 48 cached tiles, <= 8 MiB decoded cache | Deterministic controller gate |
| Hot-path materialization | No full conceptual-matrix materialization during pan, zoom, hover, selection, or mutation publication | Code/test evidence |

Device-sensitive results fail review when they exceed a budget consistently in
three runs. One isolated wall-clock spike is retained as evidence and rerun; a
budget is never loosened merely to make CI green.

## Required environments

| Environment | Mode | Purpose | State |
| --- | --- | --- | --- |
| Windows x64 host test | Flutter test, serial process per benchmark | Deterministic model, controller, paint, and hit-test gates | Three-pass audit passed |
| Chrome desktop | Profile web run and release/profile web builds | CanvasKit presentation, pan/zoom, selection, mutation, and cache cadence | Builds and representative interaction scenarios passed |
| Edge desktop | Release web build | Secondary Chromium presentation check | Not captured; Chrome is the audited Chromium target |
| Windows desktop | `flutter run --profile -d windows` | Native raster/build timing and memory | Blocked: Visual Studio toolchain unavailable on audit host |
| Representative Android device | Profile build and run | Touch selection and dense-view degradation check | Build blocked: showcase uses unsupported legacy Gradle project |

The first host baseline was captured on 2026-08-03 with:

- AMD Ryzen 7 7800X3D, 8 cores / 16 logical processors;
- 31.1 GiB RAM and AMD Radeon integrated graphics;
- Windows 11 Pro build 26200;
- Flutter 3.44.0, Dart 3.12.0;
- Chrome 150.0.7871.187 and Edge 151.0.4129.59.

## Scenario matrix

| Family | Scenario | Current automated evidence | Remaining evidence |
| --- | --- | --- | --- |
| Static renderer | 1K labelled, 10K dense, filtered 10K | Repeated paint median/p95 and one-frame gate; transform-rebuild tail gate | Device allocation sampling deferred |
| Static renderer | 250K source culled to about 1.1K visible | Visited/materialized count and paint p95 | Device allocation sampling deferred |
| Interaction | Indexed hit, cached hover, durable Heatmap selection, persistent brush, selection-expression summaries | Repeated sub-millisecond overlay/brush gates plus million-cell summary gates | Native touch presentation blocked by Android shell |
| Histogram | 50K observations into 8,192 bins | Repeated transform median/p95 gate | Device allocation sampling deferred |
| Density and contours | 2K observations, 768 raster cells, five contour levels | Repeated transform/paint gates and four Chrome interaction samples | Device allocation sampling deferred |
| Clustering | 1,536 and 6,144 cells; 512-leaf hierarchy | Repeated transform/layout gates and qualitative Chrome interaction review | Device allocation sampling deferred |
| Dendrogram | 512 leaves, 120 retained repaints | Bounded repaint gate plus hover/select/collapse browser review | None on audited Chrome target |
| Regular viewport | 24M conceptual cells, initial/moving/same-tile windows | Residency, reuse, load count, repeated request tails, Chrome baseline/zoom/pan | Native presentation blocked by toolchains |
| Live regular viewport | 2,400 cell upserts | Coalescing, residency, publication count, and repeated batch tails | Native presentation blocked by toolchains |
| Raster viewport | 512M conceptual cells, moving and same-residency windows | Mounted/cache/decoded bytes, hits, eviction, disposal, and repeated request tails | Native presentation blocked by toolchains |
| Compositions | Shared-domain small multiples and irregular rectangles | Functional tests and current release/profile web builds | Device allocation sampling deferred |

## Baseline 1: merged master

Command:

```powershell
& .\tool\run_heatmap_performance_audit.ps1 -Repeat 1
```

All eight initial Heatmap benchmark files passed. First-run measurements (including
normal host-test variance) were:

| Scenario | Result |
| --- | ---: |
| 1K labelled paint | 1.858 ms p95 |
| 10K dense paint | 12.171 ms p95 |
| 12,288 resident / 7,248 visible paint | 8.781 ms p95 |
| Filtered 10K paint | 3.975 ms p95 |
| 250K source / 1,134 visible paint | 1.119 ms p95 |
| Cached 250K hit lookup | 0.008 ms p95 |
| Cached 10K hover overlay | 0.005 ms p95 |
| 512-leaf dendrogram, 120 repaints | 260.549 ms total |
| 50K to 8,192-bin histogram | 51.317 ms |
| 2K to 768-cell density | 31.826 ms |
| Five contours over 768 cells | 44.268 ms |
| 6,144-cell clustering | 73.140 ms |
| 512-leaf hierarchy layout | 6.698 ms |
| 24M regular source, 100 moving windows | 335.487 ms total / 78 loads |
| Regular same-tile reuse, 100 pans | 1.157 ms total / 100 reuses |
| 2,400 live upserts | 75.451 ms enqueue total / one publication |
| 512M raster source, 100 moving windows | 96.923 ms total / 212 loads |
| Raster same-residency reuse, 100 pans | 35.440 ms total / 1,200 hits |

These numbers establish the audit starting point, not a universal performance
claim. Model/controller totals still need repeated median/tail reporting, and
the browser/native rows above remain mandatory before BC-0052 can close.

## Baseline 2: repeated host audit and renderer correction

The first three-pass audit exposed a real tail regression that one successful
run had hidden: the 10K regular matrix missed the 16.67 ms cached-paint budget
in three of four isolated processes, with p95 values from 17.9 to 18.9 ms. The
budget was not relaxed.

The renderer now caches the resolved visible Heatmap paint geometry for an
unchanged series/transform and batches regular-cell border geometry by paint
style. Explicit irregular cells retain source-ordered per-cell painting, and
active entrance/update reveals retain their progressive per-cell path. The
cache is invalidated by transform, series, and full-geometry invalidation.

After the correction, the complete eight-suite audit passed three consecutive
serial processes. Representative result ranges were:

| Scenario | Three-pass result |
| --- | ---: |
| 1K labelled cached paint | 1.46-2.27 ms p95 |
| 10K dense cached paint | 5.90-7.69 ms p95 |
| 10K transform invalidation plus paint | 12.89-17.84 ms p95 in a separate three-pass gate |
| 12,288 resident / 7,248 visible cached paint | 4.59-6.46 ms p95 |
| Filtered 10K cached paint | 1.02-1.98 ms p95 |
| 250K source / 1,134 visible cached paint | 0.53-0.95 ms p95 |
| Cached hit and hover overlay | <= 0.011 ms p95 |
| Density raster plus five contour levels, 12 connected paths | 0.70 ms p95 |
| 50K to 8,192-bin histogram | 33.96-43.15 ms p95 |
| 2K to 768-cell density | 35.71-43.35 ms p95 |
| Five contours over 768 cells | 10.53-15.21 ms p95 |
| 6,144-cell clustering | 50.86-68.00 ms p95 |
| 512-leaf hierarchy layout | 1.02-3.25 ms p95 |
| Regular moving-window load | 5.42-7.67 ms p95 |
| Regular same-tile pan | 0.012-0.047 ms p95 |
| 24-cell mutation batch | 1.50-2.03 ms p95 |
| Raster moving-window load | 1.20-1.67 ms p95 |
| Raster same-residency pan | 0.47-0.70 ms p95 |

The rendering correction also passed the Heatmap viewport invalidation,
functional rendering, entrance/update animation, and all three existing golden
tests without visual changes. Browser, native, and representative mobile rows
remain release evidence still to capture; the host result alone does not close
BC-0052.

The analytical paint gate now measures the mounted composition rather than
stopping at model transformation: a 768-cell density raster plus five contour
levels (12 connected Line paths in the benchmark fixture) paints at 0.70 ms
p95. The separate density and contour transform distributions remain in the
model benchmark files, so computation and presentation regressions are visible
independently.

## Browser profile instrumentation

The Heatmap showcase now exposes a controlled `Performance audit` diagnostics
section in the options panel. A four-second sampling action drives continuous
frame scheduling while the user exercises the chart, so deliberate idle gaps
in Flutter's demand-driven pipeline are not misreported as dropped frames. It
listens to Flutter frame timings in a small, isolated stateful subtree and
throttles its own display refresh to 500 ms; the chart, Workbench, and page are
not rebuilt for every timing sample. The latest 180 rendered frames report
frame p95, presentation-gap p95 and inferred FPS, build/raster p95, and the
percentage of frames exceeding 16.67 ms.

The profile routes used for the next manual review gates are:

```text
http://127.0.0.1:8144/?page=heatmap-charts&preset=density-contours
http://127.0.0.1:8144/?page=heatmap-charts&preset=clustered-matrix
http://127.0.0.1:8144/?page=heatmap-charts&preset=massive-matrix
```

These human-facing slugs are part of the showcase route contract and are
covered by widget tests; a mistyped or unsupported slug must not be treated as
valid audit evidence merely because the page fell back to Activity Matrix.

Use the options search to reveal `Performance audit`, start the controlled
sample, then exercise one scenario without mixing presets: hover and persistent
selection, pan/zoom/reset, entrance/update motion, dendrogram
selection/collapse, Massive matrix tile-boundary movement, raster invalidation,
or live cell publication. Wait for the four-second run to complete before
recording the result.
Browser numbers are host- and build-specific release evidence, not universal
package claims.

On 2026-08-03 the current showcase produced clean web artifacts:

| Artifact | Command | Result |
| --- | --- | ---: |
| Release web | `flutter build web --release --base-href /braven_charts/` | Final audit build passed in 46.2 s |
| Profile web | `flutter build web --profile` | Passed in 53.8 s; refreshed after direct-route hardening |

The complete Heatmap showcase test file now passes all 20 tests, including
direct-route contracts for density contours, clustered matrix, and Massive
matrix. Native runtime evidence is still unproven: the audit
host cannot build Windows without a Visual Studio toolchain, and
`flutter build apk --profile` rejects the showcase's legacy Android Gradle
project. These are recorded environment/project-shell blockers, not target
passes and not evidence of a Heatmap rendering failure.

### Chrome profile scenario results

Each result below is a completed controlled four-second sample from the
profile build on the audit workstation. The presentation gate is frame p95
below 16.67 ms, frame-gap p95 at or below 20 ms, and no more than 1% frames
over 16.67 ms.

| Scenario | Interaction during sample | Frame p95 | Gap p95 | Presented FPS | Jank | Build p95 | Raster p95 | Result |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| Dense signal viewport, 30K sparse source positions | Hover and viewport interaction | 9.6 ms | 17.4 ms | 57.5 | 0% | 6.1 ms | 3.1 ms | Pass |
| Customer density contours, 480 weighted observations / five contour levels | Baseline controlled sample with no interaction | 5.3 ms | 16.8 ms | 59.5 | 0% | 3.5 ms | 1.5 ms | Pass |
| Customer density contours, 480 weighted observations / five contour levels | Hover tracking across cells and contour paths | 6.7 ms | 17.4 ms | 57.5 | 0% | 5.2 ms | 1.5 ms | Pass |
| Customer density contours, 480 weighted observations / five contour levels | Pan throughout the sample | 8.9 ms | 17.3 ms | 57.8 | 0% | 6.3 ms | 2.2 ms | Pass |
| Customer density contours, 480 weighted observations / five contour levels | Zoom in and out throughout the sample | 9.0 ms | 16.8 ms | 59.5 | 0% | 6.1 ms | 2.1 ms | Pass |
| Viewport-backed massive matrix, 24M conceptual / 12,288 resident cells | Baseline controlled sample with no interaction | 3.3 ms | 16.8 ms | 59.5 | 0% | 0.9 ms | 1.1 ms | Pass |
| Viewport-backed massive matrix, 24M conceptual / 12,288 resident cells | Zoom in and out throughout the sample | 8.6 ms | 17.0 ms | 58.8 | 1% | 7.2 ms | 1.2 ms | Pass |
| Viewport-backed massive matrix, 24M conceptual / 12,288 resident cells | Pan throughout the sample | 4.3 ms | 17.1 ms | 58.5 | 0% | 3.4 ms | 0.7 ms | Pass |

The first passive probe incorrectly reported Flutter's deliberate idle periods
as slow presentation gaps. That diagnostic was rejected. The controlled probe
now requests frames continuously only during the four-second sample; the row
above is the first valid browser result.

The massive-matrix results are intentionally reported against the conceptual
and resident sizes separately. Only the bounded 12,288-cell immutable resident
snapshot enters rendering; the 24-million-cell source remains host-owned and
is not materialized by the chart during viewport interaction. Before these
three samples, the same browser path visibly missed the gate: the baseline
reported 20.5 ms frame p95 and 23% jank, zoom reported 20.3 ms and 11% jank,
and pan reported 26.1 ms and 97% jank, with raster p95 between 13.1 and
22.2 ms. The renderer now uploads indexed quad chunks (four vertices and six
indices per cell, bounded to 16,384 cells per chunk) rather than independent
triangle vertices, while the gap-only showcase avoids thousands of redundant
rounded border draws. Raster p95 is now 0.7-1.2 ms and all three controlled
scenarios pass without relaxing the browser budget.

The density-contour composition also passes as four isolated scenarios. Its
five connected contour paths, 480 weighted observations, cell raster,
tracking overlay, pan, and zoom remain below 9.0 ms frame p95 and 2.2 ms
raster p95, with zero sampled jank. This is the browser counterpart to the
separate deterministic analytical-composition benchmark; it verifies the
mounted host and overlay path without conflating the four interactions.

The clustered-matrix composition was then manually reviewed as four isolated
controlled samples: baseline, dendrogram hover, branch selection, and branch
collapse/expand. The reviewer confirmed all four diagnostics passed. Exact
metric values were not retained with that checkpoint, so this is qualitative
interaction-path evidence rather than a numeric row in the table above; no
values are inferred or fabricated.

## Automated interaction, mutation, and cache closure

The final audit runner contains ten isolated target files. It adds the durable
Heatmap selection overlay, persistent rectangle-brush movement/resizing, and
selection-expression aggregation to the earlier renderer, analytical model,
regular viewport, raster viewport, and mutation suites. Three serial passes
therefore execute 30 fresh Flutter test processes rather than sharing warmed
state between benchmark families.

The final three-pass run completed successfully in 93 seconds. Representative
tail ranges were:

| Scenario | Three-pass result |
| --- | ---: |
| Durable selection overlay over 10K cells / 200 selected | 0.303-0.367 ms p95 |
| Persistent rectangle brush | 0.342-0.437 ms p95 |
| Million-cell selection summary | 30.137-38.571 ms |
| Million-cell rectangle summary | 51.538-59.309 ms |
| Regular moving-window load | 4.669-7.126 ms p95 |
| Regular same-tile pan | 0.011-0.014 ms p95 |
| 2,400 live upserts | 72.378-88.906 ms enqueue total / one publication |
| 24-cell mutation batch | 1.086-1.317 ms p95 |
| Raster moving-window load | 1.281-1.329 ms p95 |
| Raster same-residency pan | 0.408-0.479 ms p95 |

This closes the deterministic selection, mutation, invalidation, eviction, and
resident-reuse portions of the matrix. It does not substitute for native
device allocation data; those unavailable environment rows remain explicit
release decisions below.

## Reproduction

Run only the Heatmap release benchmark set, one Flutter process at a time. The
current runner covers ten files and a three-pass invocation launches 30 fresh
Flutter processes:

```powershell
& .\tool\run_heatmap_performance_audit.ps1 -Repeat 3
```

Run package analysis and the non-benchmark suite independently so benchmark
wall clocks are not affected by concurrent tests:

```powershell
flutter analyze lib
flutter test
```

The repository quality workflow likewise isolates every benchmark file in its
own serial Flutter process.

## Final adversarial review and public-surface polish

The final pre-PR review was rebased onto `origin/master` at `87d4c667` and
repeated every automated Heatmap benchmark three times in isolated Flutter
processes. All 30 processes passed. The current tail ranges include a
0.312-0.364 ms p95 durable selection overlay, 0.325-0.443 ms p95 persistent
brush, 4.820-5.156 ms p95 regular moving-window load, 0.011 ms p95 regular
same-tile pan, 1.113-1.299 ms p95 raster moving-window load, and
0.435-0.517 ms p95 raster same-residency pan. The 48 x 32 clustering transform
remained at 8.448-8.693 ms p95; the larger 96 x 64 scale fixture remained
bounded at 52.776-57.797 ms p95.

One earlier combined-process pass produced a single 3.515 ms durable-selection
tail against its 1 ms gate after the 250K-cell renderer fixture. The threshold
was not weakened. Five fresh isolated reruns passed at 0.307-0.391 ms p95, and
the subsequent complete three-pass audit passed at 0.312-0.364 ms p95. This is
recorded as process-tail contamination evidence rather than hidden or promoted
as a product regression.

The adversarial repository pass also covered the full package tests, all 540
showcase tests, package and affected-showcase analysis, generated-surface
checks, public documentation and guide generation, and a release web build.
The surface generator's full 251-test suite passed with serial execution;
default Windows concurrency exposed two transient fixture races that passed
when rerun directly and are not in the Heatmap runtime path. Broad Flutter
test processes were likewise kept sequential after concurrent tool processes
raced over one shared native-assets build artifact.

The public discovery surfaces now present Heatmap as a complete chart family,
not one generic blue matrix. Chart Types calls out sequential/diverging scales,
missing-cell identity, and viewport-backed data. The Gallery contains four
focused native Heatmaps: sequential activity, diverging temperature,
correlation, and threshold service health with a missing cell. Gallery tests
assert the four-card contract and the presence of a diverging example.

## Release decision record

- **Green now:** the expanded 30-process deterministic audit; cached and
  invalidated paint; analytical transforms and mounted contour composition;
  dendrogram layout/repaint; culling; hit, hover, durable selection, persistent
  brush, and selection summaries; regular/raster residency and reuse;
  eviction/disposal; live mutation coalescing; representative Chrome
  baseline/hover/pan/zoom interaction; release/profile web builds; package
  analysis; the full package suite; and the complete Heatmap showcase test
  file.
- **Blocked/unproven:** Windows-native profile evidence because the audit host
  lacks the Visual Studio toolchain; Android profile/touch evidence because the
  showcase retains an unsupported legacy Gradle shell; native allocation and
  memory samples; and a separate Edge capture. These are environment/project
  blockers, not inferred target passes and not observed Heatmap regressions.
- **Promotion rule:** the audited Windows-host/Chrome surface is green. Package
  promotion requires a maintainer decision to accept the explicit native and
  device-memory deferrals, or a follow-up environment lane that supplies those
  results. No deterministic or measured Chrome budget is being waived.
