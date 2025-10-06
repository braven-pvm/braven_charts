# Technical Debt: Chart Types (Layer 4)

**Feature**: 005-chart-types  
**Created**: 2025-10-06  
**Status**: Active Development

---

## Summary

**Layer 4 (Chart Types) has 10 tasks blocked on integration dependencies that don't exist yet.**

These tasks MUST be deferred to an integration phase after foundation layers (0-3) are complete. They cannot be implemented in isolation because they require full rendering pipeline, coordinate transformation, theming, and widget infrastructure.

---

## Blocked Tasks by Category

### Performance Benchmarks (T056-T061) - 6 Tasks ⏸️ BLOCKED

**Blocker**: Requires RenderPipeline, RenderContext, ObjectPool, ViewportCuller from Layers 0-1

**Tasks**:
- **T056**: LineChartLayer benchmark (10K points, <16ms)
- **T057**: AreaChartLayer benchmark (10K points, <16ms)
- **T058**: BarChartLayer benchmark (1K bars, <16ms)
- **T059**: ScatterChartLayer benchmark (10K points, <16ms)
- **T060**: Viewport culling benchmark (<1ms overhead)
- **T061**: Object pooling benchmark (>90% hit rate)

**Why Blocked**:
- Need actual RenderPipeline to render chart layers
- Need RenderContext with canvas, transformer, pools, culler
- Need to measure real frame time with Stopwatch
- Current chart layers can't render without full pipeline integration

**Defer To**: Integration Phase after Layers 0-3 complete

**Constitutional Impact**: ⚠️ **HIGH** - These are NON-NEGOTIABLE constitutional requirements. Performance benchmarks MUST pass before Layer 4 can be considered complete.

---

### Golden Tests (T062-T065) - 4 Tasks ⏸️ BLOCKED

**Blocker**: Requires Chart Widgets (don't exist), Theming (Layer 3), Full Rendering Pipeline

**Tasks**:
- **T062**: LineChart widget golden test (all styles, markers)
- **T063**: AreaChart widget golden test (all fills, stacking)
- **T064**: BarChart widget golden test (orientations, grouping)
- **T065**: ScatterChart widget golden test (markers, sizing)

**Why Blocked**:
- Chart Widgets don't exist (LineChart, AreaChart, BarChart, ScatterChart)
- Can't do visual regression without actual UI to render
- Need theming integration for consistent colors
- Need full rendering pipeline for widget output

**Defer To**: After Chart Widget layer created (Layer 5 or separate widget layer)

**Constitutional Impact**: 🔸 **MEDIUM** - Golden tests ensure UI consistency but aren't blocking Layer 4 completion

---

## What We CAN Do Now

### Already Complete ✅
- All chart layer implementations (T036-T041)
- All configuration models (T009-T015)
- All utility algorithms (T016-T035)
- Contract tests (T004-T008)
- Unit tests (T020-T026)
- Placeholder integration tests (T042-T055)

### Remaining Layer 4 Tasks
- **T067-T070**: Documentation (DartDoc, README, usage guide) - CAN DO NOW
- **T071-T072**: Code cleanup and final review - CAN DO NOW

---

## Integration Requirements

### What's Needed for T056-T061 (Performance Benchmarks)

**From Layer 0 (Foundation)**:
```dart
final objectPool = ObjectPool<Paint>(...);
final culler = ViewportCuller();
```

**From Layer 1 (Core Rendering)**:
```dart
final pipeline = RenderPipeline(
  paintPool: objectPool,
  pathPool: pathPool,
  textPainterPool: textPainterPool,
  culler: culler,
);

final context = RenderContext(
  canvas: canvas,
  viewport: viewport,
  transformer: transformer,
  // ... other properties
);
```

**From Layer 2 (Coordinate System)**:
```dart
final transformer = UniversalCoordinateTransformer(...);
```

**Then can benchmark**:
```dart
final stopwatch = Stopwatch()..start();
layer.render(context);
stopwatch.stop();
expect(stopwatch.elapsedMilliseconds, lessThan(16)); // <16ms requirement
```

---

### What's Needed for T062-T065 (Golden Tests)

**Chart Widgets** (don't exist yet):
```dart
// User-facing widgets that wrap RenderLayers
class LineChart extends StatelessWidget {
  final List<ChartSeries> series;
  final ChartTheme? theme;
  // ...
}
```

**Full Integration**:
- Layer 1: RenderPipeline
- Layer 2: UniversalCoordinateTransformer
- Layer 3: ChartTheme, SeriesTheme
- Widget Layer: LineChart, AreaChart, BarChart, ScatterChart widgets

**Then can test**:
```dart
testWidgets('LineChart renders correctly', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: LineChart(series: testData),
  ));
  
  await expectLater(
    find.byType(LineChart),
    matchesGoldenFile('goldens/line_chart_basic.png'),
  );
});
```

---

## Recommendation

### Short Term (Layer 4 Completion)
1. ✅ Mark T056-T065 as BLOCKED in tasks.md (DONE)
2. ✅ Create this TECHNICAL_DEBT.md (DONE)
3. 🔄 Complete remaining Layer 4 tasks (T067-T072)
4. 🔄 Document integration requirements in README
5. ✅ Merge Layer 4 with clear notes about deferred tasks

### Medium Term (Integration Phase)
1. ⏳ Complete Layer 3 (Theming) integration
2. ⏳ Create Chart Widgets layer (Layer 5 or separate)
3. ⏳ Integrate Layers 0-3 into chart layer rendering
4. ✅ Implement T056-T061 (Performance benchmarks)
5. ✅ Implement T062-T065 (Golden tests)
6. ✅ Verify constitutional compliance (all benchmarks pass)

### Long Term (Production Ready)
1. All performance benchmarks passing (<16ms frame time)
2. All golden tests passing (visual regression)
3. Full documentation complete
4. Example app showing real chart widgets
5. Ready for v1.0 release

---

## Impact Assessment

### Layer 4 Status Without Blocked Tasks
- **Core Implementation**: ✅ 100% Complete (all chart layers work)
- **Testing**: ⚠️ 75% Complete (unit/contract done, integration/performance blocked)
- **Documentation**: 🔄 50% Complete (awaiting T067-T070)
- **Constitutional Compliance**: ⚠️ INCOMPLETE (performance benchmarks required)

### Can Layer 4 Be Merged?
**YES, with caveats**:
- ✅ All core functionality implemented
- ✅ All unit and contract tests passing
- ✅ Integration test placeholders document future work
- ⚠️ Performance NOT validated (constitutional violation)
- ⚠️ Visual regression NOT validated

**Merge Strategy**:
1. Complete T067-T072 (documentation)
2. Merge to main with `[WIP]` or `[PARTIAL]` tag
3. Create follow-up issues for T056-T065
4. Track in project backlog for integration phase

---

## Follow-Up Actions

### Immediate (Before Merge)
- [ ] Complete T067: DartDoc comments
- [ ] Complete T068: Algorithm documentation
- [ ] Complete T069: README with integration notes
- [ ] Complete T070: Usage guide
- [ ] Complete T071: Code cleanup
- [ ] Complete T072: Final review
- [ ] Update PROJECT_STATUS.md with technical debt

### Integration Phase (After Layers 0-3)
- [ ] Create integration branch
- [ ] Implement T056-T061 performance benchmarks
- [ ] Implement T062-T065 golden tests
- [ ] Validate constitutional compliance
- [ ] Update this document when tasks complete

### Documentation
- [ ] Add "Integration Requirements" section to README
- [ ] Document deferred tasks in CHANGELOG
- [ ] Create GitHub issues for T056-T065
- [ ] Link issues to integration milestone

---

## Changelog

### 2025-10-06
- Created TECHNICAL_DEBT.md
- Identified 10 blocked tasks (T056-T065)
- Documented blockers: RenderPipeline, Chart Widgets, Full Integration
- Recommended merge strategy with follow-up tasks
- Marked tasks as BLOCKED in tasks.md

---

**Next Review**: After Layers 0-3 integration OR when Chart Widgets created
