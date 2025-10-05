# Manual Testing Guide: Core Rendering Engine

**Feature**: 002-core-rendering  
**Purpose**: Visual validation and performance verification checklist  
**Last Updated**: 2025-10-05

---

## Overview

This guide provides manual testing procedures to complement automated tests. Use this checklist to visually validate rendering correctness and verify performance targets are met.

## Prerequisites

- Flutter SDK 3.37.0-1.0.pre-216 or later
- Dart 3.0+ (3.10.0-227.0.dev)
- Project dependencies installed (`flutter pub get`)
- All automated tests passing (`flutter test`)

---

## Part 1: Visual Validation

### Test 1.1: Z-Order Rendering ✅

**Purpose**: Verify layers render in correct z-order (background → primary → overlay)

**Steps**:
1. Create test widget with 3 overlapping layers:
   ```dart
   pipeline.addLayer(GridLayer(zIndex: -1));      // Background
   pipeline.addLayer(DataSeriesLayer(zIndex: 0));  // Primary
   pipeline.addLayer(AnnotationLayer(zIndex: 1));  // Foreground
   ```
2. Render widget in debug mode
3. Verify visual stacking order

**Expected Result**:
- Grid appears behind data series
- Data series appears behind annotations
- No z-fighting or flickering

**Pass Criteria**: ✅ Layers render in correct order without artifacts

---

### Test 1.2: Text Rendering ✅

**Purpose**: Verify text labels render correctly without clipping or overflow artifacts

**Steps**:
1. Create AnnotationLayer with various text sizes (10px - 48px)
2. Add labels at different positions (edges, center, corners)
3. Include labels with varying lengths (short, medium, long)
4. Render with different viewport sizes

**Expected Result**:
- Text is sharp and legible at all sizes
- No clipping artifacts at viewport edges
- Long text handled gracefully (clip or truncate, no crash)
- Text maintains correct positioning during pan/zoom

**Pass Criteria**: ✅ All text renders clearly without artifacts

---

### Test 1.3: Viewport Clipping ✅

**Purpose**: Verify rendering respects viewport bounds

**Steps**:
1. Create DataSeriesLayer with 10,000 points spanning x=[0, 10000]
2. Set viewport to show small region (e.g., x=[100, 200])
3. Pan viewport rapidly across entire range
4. Zoom in/out repeatedly

**Expected Result**:
- Only points within viewport are rendered
- No rendering outside canvas bounds
- Smooth transitions during pan/zoom
- No visual artifacts at viewport edges

**Pass Criteria**: ✅ Rendering respects viewport bounds, no overflow artifacts

---

### Test 1.4: Alpha Blending ✅

**Purpose**: Verify semi-transparent layers blend correctly

**Steps**:
1. Create 3 layers with semi-transparent colors:
   ```dart
   Color(0x80FF0000)  // Red, 50% alpha
   Color(0x8000FF00)  // Green, 50% alpha  
   Color(0x800000FF)  // Blue, 50% alpha
   ```
2. Stack layers with overlapping geometry
3. Verify color mixing matches expectations

**Expected Result**:
- Overlapping regions show correct color blending
- Transparency is uniform across layer
- No banding or artifacts

**Pass Criteria**: ✅ Alpha blending works correctly

---

## Part 2: Performance Validation

### Test 2.1: Frame Time Benchmarks ⚡

**Purpose**: Verify average frame time meets <8ms target

**Steps**:
1. Run benchmark: `flutter test test/benchmarks/rendering/render_pipeline_benchmark.dart`
2. Check console output for frame time metrics
3. Record average and p99 frame times

**Expected Results**:
```
Scenario: 500 visible points
Average frame time: <8ms ✅
P99 frame time: <16ms ✅

Scenario: 5000 visible points  
Average frame time: <8ms ✅
P99 frame time: <16ms ✅

Scenario: 100-frame stability
Jank frames (>16ms): 0 ✅
```

**Pass Criteria**: ✅ All scenarios meet performance targets

---

### Test 2.2: Object Pool Hit Rate ⚡

**Purpose**: Verify object pool hit rate meets >90% target

**Steps**:
1. Run benchmark: `flutter test test/benchmarks/rendering/object_pool_benchmark.dart`
2. Check console output for hit rate statistics
3. Record hit rates for Paint, Path, TextPainter pools

**Expected Results**:
```
Paint pool:
- Hit rate: >90% ✅
- Average latency: <10μs ✅

Path pool:
- Hit rate: >90% ✅
- Average latency: <10μs ✅

TextPainter pool:
- Hit rate: >90% ✅
- Average latency: <10μs ✅
```

**Pass Criteria**: ✅ All pools exceed 90% hit rate

---

### Test 2.3: Text Cache Hit Rate ⚡

**Purpose**: Verify text layout cache hit rate meets >70% target

**Steps**:
1. Run benchmark: `flutter test test/benchmarks/rendering/text_cache_benchmark.dart`
2. Check console output for cache statistics
3. Record hit rate after 1000 renders

**Expected Results**:
```
Text cache after 1000 renders:
- Hit rate: >70% ✅
- Cache hit latency: <<< cache miss latency ✅
- LRU eviction working correctly ✅
```

**Pass Criteria**: ✅ Cache exceeds 70% hit rate

---

### Test 2.4: Viewport Culling Performance ⚡

**Purpose**: Verify viewport culling completes in <3ms for 10K points

**Steps**:
1. Run benchmark: `flutter test test/benchmarks/rendering/viewport_culling_benchmark.dart`
2. Check console output for culling latency
3. Verify O(n) scaling behavior

**Expected Results**:
```
Culling 10,000 points:
- 5% visible: <3ms ✅
- 50% visible: <3ms ✅
- 95% visible: <3ms ✅

Scaling: O(n) confirmed ✅
```

**Pass Criteria**: ✅ All scenarios complete in <3ms

---

## Part 3: Edge Case Testing

### Test 3.1: Rapid Pan Handling 🔄

**Purpose**: Verify stability during rapid viewport changes

**Steps**:
1. Create widget with 10,000 data points
2. Programmatically pan viewport 100 times in 1 second:
   ```dart
   for (int i = 0; i < 100; i++) {
     pipeline.updateViewport(Rect.fromLTWH(i * 10.0, 0, 800, 600));
     pipeline.renderFrame(canvas, size);
   }
   ```
3. Monitor for crashes, frame drops, memory leaks

**Expected Result**:
- No crashes or exceptions
- Frame drops: 0 ✅
- Average frame time: <8ms ✅
- Pool sizes remain stable (no memory leaks)
- Performance degradation: <20%

**Pass Criteria**: ✅ No crashes, minimal performance impact

---

### Test 3.2: Extreme Zoom Handling 🔍

**Purpose**: Verify graceful degradation when showing all data

**Steps**:
1. Create widget with 10,000 data points
2. Set viewport to show all points simultaneously
3. Render frame and measure performance

**Expected Result**:
- No crashes or rendering artifacts
- Frame time degrades gracefully (may exceed 16ms, but <50ms)
- Slowdown proportional to visible points (<20x)

**Pass Criteria**: ✅ Graceful degradation, no crash

---

### Test 3.3: Overlapping Layers 📚

**Purpose**: Verify correct rendering with many overlapping layers

**Steps**:
1. Create 10 layers with identical screen coverage
2. Assign different z-indices and colors
3. Verify render order matches z-order

**Expected Result**:
- Layers render in correct z-order
- No flickering or z-fighting
- Performance acceptable (<5ms for 10 layers)

**Pass Criteria**: ✅ Correct z-order, good performance

---

### Test 3.4: Text Overflow Handling 📝

**Purpose**: Verify text rendering when labels exceed viewport

**Steps**:
1. Create annotations with very long text (1000+ characters)
2. Position text at viewport edges (top, right, bottom, left)
3. Include empty strings and whitespace-only labels

**Expected Result**:
- No crashes with overflowing text
- Large text renders in reasonable time (<20ms)
- Empty/whitespace text handled gracefully

**Pass Criteria**: ✅ Robust text handling, no crashes

---

### Test 3.5: Pool Exhaustion Handling 🔋

**Purpose**: Verify system handles requests exceeding pool capacity

**Steps**:
1. Create layer that acquires 200 Paint objects (pool capacity ~100)
2. Render frame
3. Verify no crashes, check statistics

**Expected Result**:
- No crashes (allocate beyond capacity)
- Performance degrades but not catastrophically
- Pool recovers after exhaustion (subsequent frames normal)

**Pass Criteria**: ✅ Graceful degradation, no crash

---

### Test 3.6: Cache Overflow Handling 💾

**Purpose**: Verify LRU eviction when cache exceeds capacity

**Steps**:
1. Create layer rendering 1000 unique text labels (cache maxSize=500)
2. Render multiple frames
3. Verify cache size bounded, hit rate stabilizes

**Expected Result**:
- Cache size never exceeds maxSize (≤500)
- Hit rate stabilizes around 50% (500/1000 cached)
- No unbounded memory growth

**Pass Criteria**: ✅ LRU eviction working, memory bounded

---

## Part 4: Performance Profiling

### Test 4.1: Frame Time Analysis 📊

**Purpose**: Identify rendering bottlenecks

**Steps**:
1. Run app in profile mode: `flutter run --profile`
2. Open DevTools Performance tab
3. Record rendering timeline for 60 frames
4. Analyze frame breakdown

**Expected Breakdown**:
- Layer sorting: <0.1ms per layer
- isEmpty checks: <0.01ms per empty layer
- Pool acquire/release: <0.01ms per operation
- Viewport culling: <3ms for large datasets
- Canvas drawing: Variable (depends on complexity)

**Pass Criteria**: ✅ No unexpected bottlenecks

---

### Test 4.2: Memory Profiling 🧠

**Purpose**: Verify no memory leaks or unbounded growth

**Steps**:
1. Run app in profile mode: `flutter run --profile`
2. Open DevTools Memory tab
3. Render 1000 frames with varying viewport
4. Force GC and check memory snapshot

**Expected Result**:
- Heap size stable after initial allocation
- No retained objects from previous frames
- Pool sizes bounded (not growing unbounded)
- Cache sizes bounded by maxSize

**Pass Criteria**: ✅ Memory usage stable, no leaks

---

## Part 5: Integration Validation

### Test 5.1: Full Pipeline Integration ✨

**Purpose**: Verify all components work together end-to-end

**Steps**:
1. Create complete chart widget with:
   - GridLayer (background)
   - DataSeriesLayer with 5000 points (primary)
   - AnnotationLayer with 50 labels (overlay)
2. Pan viewport across entire dataset
3. Zoom in/out 10x
4. Monitor performance metrics

**Expected Result**:
- All layers render correctly
- No visual artifacts during interaction
- Performance targets met throughout
- Object pools and cache effective

**Pass Criteria**: ✅ Complete pipeline works seamlessly

---

## Troubleshooting

### Issue: Frame time exceeds 8ms

**Diagnosis**:
1. Run benchmarks to identify bottleneck
2. Check pool hit rates (should be >90%)
3. Check text cache hit rate (should be >70%)
4. Verify viewport culling enabled

**Solutions**:
- Increase pool sizes if hit rate low
- Increase cache size if hit rate low
- Reduce visible data points (zoom in)
- Optimize layer isEmpty checks

### Issue: Visual artifacts or flickering

**Diagnosis**:
1. Check layer z-indices (ensure unique per visual priority)
2. Verify viewport bounds (must intersect canvas)
3. Check for floating-point precision issues

**Solutions**:
- Assign explicit z-indices to all layers
- Clamp viewport to valid bounds
- Use stable coordinate transformations

### Issue: Memory leaks

**Diagnosis**:
1. Run memory profiler (DevTools)
2. Check pool statistics (should have equal acquire/release)
3. Verify cache bounded by maxSize

**Solutions**:
- Ensure all acquired objects released in finally blocks
- Verify cache eviction working (check length)
- Look for retained references to RenderContext

---

## Acceptance Criteria

All manual tests must pass before considering feature complete:

- ✅ Visual validation (4/4 tests)
- ✅ Performance validation (4/4 tests)
- ✅ Edge case testing (6/6 tests)
- ✅ Performance profiling (2/2 tests)
- ✅ Integration validation (1/1 test)

**Total**: 17/17 manual tests passing

---

## Sign-Off

**Tester**: ________________  
**Date**: ________________  
**Result**: PASS ☐ / FAIL ☐  
**Notes**: ________________________________
