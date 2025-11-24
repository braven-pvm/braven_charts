# BravenChartPlus API Alignment & Migration Plan

## 1. Overview
This document outlines the plan to align the `BravenChartPlus` API with the existing `BravenChart` API, ensuring feature parity while adhering to the new `src_plus` architecture.

**Strict Rule**: No classes from `lib/src/` can be imported directly into `lib/src_plus/`. All configuration classes must be recreated or migrated to the `src_plus` structure.

## 2. Property Alignment Analysis

### 2.1. Core Configuration
| Property | BravenChart | BravenChartPlus | Action | Notes |
|----------|-------------|-----------------|--------|-------|
| `chartType` | ✅ | ✅ | **REMOVE** | Redundant. Series-level `style` or specific Series classes (e.g. `LineChartSeries`) should dictate rendering. |
| `lineStyle` | ✅ | ❌ | **ADD** | Add `LineStyle` enum to `src_plus/models/enums.dart`. |
| `series` | ✅ | ✅ | **KEEP** | Already aligned (using `src_plus` version). |

### 2.2. Dimensions & UI
| Property | BravenChart | BravenChartPlus | Action | Notes |
|----------|-------------|-----------------|--------|-------|
| `width` | ✅ | ✅ | **KEEP** | |
| `height` | ✅ | ✅ | **KEEP** | |
| `title` | ✅ | ❌ | **ADD** | Add `String? title`. |
| `subtitle` | ✅ | ❌ | **ADD** | Add `String? subtitle`. |
| `showLegend` | ✅ | ❌ | **ADD** | Add `bool showLegend`. |
| `showToolbar` | ✅ | ❌ | **ADD** | Add `bool showToolbar`. |
| `loadingWidget`| ✅ | ❌ | **ADD** | Add `Widget? loadingWidget`. |
| `errorWidget` | ✅ | ❌ | **ADD** | Add `Widget Function(Object)? errorWidget`. |
| `backgroundColor`| ❌ | ✅ | **KEEP** | Useful addition in Plus. |
| `showDebugInfo`| ❌ | ✅ | **KEEP** | Useful for dev. |

### 2.3. Theming & Axis
| Property | BravenChart | BravenChartPlus | Action | Notes |
|----------|-------------|-----------------|--------|-------|
| `theme` | ✅ | ✅ | **ALIGN** | Ensure `ChartTheme` in `src_plus` matches `src`. |
| `xAxis` | ✅ | ✅ | **ALIGN** | Ensure `AxisConfig` in `src_plus` matches `src`. |
| `yAxis` | ✅ | ✅ | **ALIGN** | Ensure `AxisConfig` in `src_plus` matches `src`. |

### 2.4. Interaction & Annotations
| Property | BravenChart | BravenChartPlus | Action | Notes |
|----------|-------------|-----------------|--------|-------|
| `annotations` | ✅ | ✅ | **KEEP** | |
| `interactiveAnnotations` | ✅ | ❌ | **ADD** | Add `bool interactiveAnnotations`. |
| `interactionConfig` | ✅ | ✅ | **MIGRATE** | **CRITICAL**: Current Plus implementation imports `src` version. Must recreate in `src_plus`. |
| `annotationController` | ❌ | ✅ | **KEEP** | Superior reactive model in Plus. |

### 2.5. Streaming & Scrolling
| Property | BravenChart | BravenChartPlus | Action | Notes |
|----------|-------------|-----------------|--------|-------|
| `dataStream` | ✅ | ✅ | **KEEP** | |
| `controller` | ✅ | ✅ | **MIGRATE** | **CRITICAL**: Current Plus imports `src` controller. Need `ChartController` in `src_plus`. |
| `streamingController`| ✅ | ✅ | **VERIFY** | `src_plus` has `StreamingController`. Verify API parity with `src`. |
| `streamingConfig` | ✅ | ✅ | **ALIGN** | Ensure parity. |
| `autoScrollConfig` | ✅ | ❌ | **ADD** | Recreate `AutoScrollConfig` in `src_plus`. |

### 2.6. Callbacks
| Property | BravenChart | BravenChartPlus | Action | Notes |
|----------|-------------|-----------------|--------|-------|
| `onPointTap` | ✅ | ❌ | **ADD** | |
| `onPointHover` | ✅ | ❌ | **ADD** | |
| `onBackgroundTap` | ✅ | ❌ | **ADD** | |
| `onSeriesSelected` | ✅ | ❌ | **ADD** | |
| `onAnnotationTap` | ✅ | ❌ | **ADD** | |
| `onAnnotationDragged`| ✅ | ❌ | **ADD** | |

## 3. Architecture Migration Tasks

### 3.1. Class Recreation (src -> src_plus)
The following classes are currently imported from `src` or missing and need to be defined in `src_plus`:

1.  **`InteractionConfig`**
    *   Source: `lib/src/interaction/models/interaction_config.dart`
    *   Target: `lib/src_plus/models/interaction_config.dart`
    *   Dependencies: `CrosshairConfig`, `TooltipConfig`, `SelectionConfig`, `ZoomConfig`, `PanConfig`, `KeyboardConfig`.

2.  **`AutoScrollConfig`**
    *   Source: `lib/src/widgets/auto_scroll_config.dart`
    *   Target: `lib/src_plus/models/auto_scroll_config.dart`

3.  **`LineStyle` (Enum)**
    *   Source: `lib/src/charts/line/line_chart_config.dart`
    *   Target: `lib/src_plus/models/enums.dart`

4.  **`ChartController`**
    *   Source: `lib/src/widgets/controller/chart_controller.dart`
    *   Target: `lib/src_plus/controllers/chart_controller.dart`
    *   *Note*: This is a heavy lift. We might need to duplicate it for now to break the dependency.

5.  **`StreamingController`**
    *   Source: `lib/src/widgets/controller/streaming_controller.dart`
    *   Target: `lib/src_plus/controllers/streaming_controller.dart`

### 3.2. Widget Implementation Steps
1.  **Remove `chartType`**: Remove the property and usage. Logic should derive from `ChartSeries` types.
2.  **Add Missing Properties**: Add all properties identified in Section 2.
3.  **Update Imports**: Switch all `src` imports to new `src_plus` classes.
4.  **Implement UI Shell**: Update `build` method to include Title, Subtitle, Legend, Toolbar (placeholder), Loading/Error states.
5.  **Wire Callbacks**: Connect `ChartInteractionCoordinator` events to the new callback properties.

## 4. Verification Plan
1.  **Compilation**: Ensure no `package:braven_charts/src/...` imports exist in `lib/src_plus/`.
2.  **Functionality**:
    *   Verify Title/Subtitle rendering.
    *   Verify Legend rendering (basic list).
    *   Verify Callbacks fire on interaction.
    *   Verify AutoScroll works with new config.
