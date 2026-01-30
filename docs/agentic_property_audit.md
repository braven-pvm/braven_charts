# Agentic Charts Property Audit

**Date**: 2025-01-27  
**Purpose**: Comprehensive gap analysis between BravenChartPlus API and Agentic tooling

---

## Executive Summary

This audit compares:

1. **BravenChartPlus API** - What the chart library supports
2. **CreateChartTool Schema** - What the agent can specify
3. **ChartRenderer** - What actually gets wired through to rendering

**Legend**:

- ✅ = Fully supported and wired
- ⚠️ = In schema but NOT wired to renderer
- ❌ = NOT in schema (agent can't specify)
- 🔧 = Partially wired (needs fix)

---

## 1. SERIES PROPERTIES

### LineChartSeries (BravenChartPlus)

| Property                | BravenChartPlus            | Tool Schema         | Agentic Model             | Renderer Wiring                 | Status     |
| ----------------------- | -------------------------- | ------------------- | ------------------------- | ------------------------------- | ---------- |
| `id`                    | ✓ required                 | ✓ required          | ✓                         | ✓                               | ✅         |
| `name`                  | ✓ optional                 | ✓ optional          | ✓                         | ✓                               | ✅         |
| `points`                | ✓ required                 | ✓ `data` array      | ✓ `data`                  | ✓                               | ✅         |
| `color`                 | ✓ optional                 | ✓ hex string        | ✓                         | ✓ `_parseColor`                 | ✅         |
| `interpolation`         | ✓ `LineInterpolation` enum | ✓ enum              | ✓ `Interpolation` enum    | ✓ `_mapInterpolation`           | ✅         |
| `strokeWidth`           | ✓ default 2.0              | ✓                   | ✓                         | ✓                               | ✅         |
| `tension`               | ✓ default 0.25             | ✓                   | ✓                         | ✓                               | ✅         |
| `showDataPointMarkers`  | ✓ default false            | ✓ `showPoints`      | ✓ `showPoints`            | ✓                               | ✅         |
| `dataPointMarkerRadius` | ✓ default 3.0              | ❌ NOT IN SCHEMA    | ✓ `dataPointMarkerRadius` | ❌ NOT PASSED                   | ⚠️ MISSING |
| `yAxisConfig`           | ✓ inline YAxisConfig       | ✓ per-series fields | ✓                         | ✓ `_buildYAxisConfigFromSeries` | 🔧 PARTIAL |
| `yAxisId`               | ✓ optional                 | ✓                   | ✓                         | ❌ NOT PASSED                   | ⚠️ MISSING |
| `unit`                  | ✓ optional                 | ✓                   | ✓                         | ❌ NOT PASSED                   | ⚠️ MISSING |
| `isXOrdered`            | ✓ default false            | ❌                  | ❌                        | ❌                              | ❌ N/A     |
| `metadata`              | ✓ optional                 | ❌                  | ❌                        | ❌                              | ❌ N/A     |
| `annotations`           | ✓ per-series               | ❌                  | ❌                        | ❌                              | ❌ N/A     |

### AreaChartSeries (BravenChartPlus)

| Property                | BravenChartPlus | Tool Schema      | Agentic Model | Renderer Wiring | Status     |
| ----------------------- | --------------- | ---------------- | ------------- | --------------- | ---------- |
| `fillOpacity`           | ✓ default 0.3   | ✓                | ✓             | ✓               | ✅         |
| `interpolation`         | ✓               | ✓                | ✓             | ✓               | ✅         |
| `tension`               | ✓               | ✓                | ✓             | ✓               | ✅         |
| `showDataPointMarkers`  | ✓               | ✓                | ✓             | ✓               | ✅         |
| `dataPointMarkerRadius` | ✓ default 3.0   | ❌ NOT IN SCHEMA | ✓             | ❌ NOT PASSED   | ⚠️ MISSING |
| `strokeWidth`           | ✓               | ✓                | ✓             | ❌ NOT PASSED   | ⚠️ MISSING |

### BarChartSeries (BravenChartPlus)

| Property          | BravenChartPlus | Tool Schema      | Agentic Model | Renderer Wiring | Status       |
| ----------------- | --------------- | ---------------- | ------------- | --------------- | ------------ |
| `barWidthPercent` | ✓ 0.0-1.0       | ❌ NOT IN SCHEMA | ✓             | HARDCODED 0.7   | ⚠️ HARDCODED |
| `barWidthPixels`  | ✓ optional      | ❌ NOT IN SCHEMA | ✓             | ❌              | ⚠️ MISSING   |
| `minWidth`        | ✓ default 4.0   | ❌               | ❌            | ❌              | ❌ N/A       |
| `maxWidth`        | ✓ default 100.0 | ❌               | ❌            | ❌              | ❌ N/A       |

### ScatterChartSeries (BravenChartPlus)

| Property       | BravenChartPlus | Tool Schema      | Agentic Model | Renderer Wiring | Status |
| -------------- | --------------- | ---------------- | ------------- | --------------- | ------ |
| `markerRadius` | ✓ default 5.0   | ❌ NOT IN SCHEMA | ✓             | ✓ default 5.0   | ✅     |

---

## 2. Y-AXIS CONFIGURATION

### YAxisConfig (BravenChartPlus)

| Property                 | BravenChartPlus                                             | Tool Schema (series-level)          | Agentic Model       | Renderer Wiring    | Status                          |
| ------------------------ | ----------------------------------------------------------- | ----------------------------------- | ------------------- | ------------------ | ------------------------------- |
| `position`               | ✓ `YAxisPosition` enum (left, right, leftOuter, rightOuter) | ✓ `yAxisPosition` ("left", "right") | ✓ ("left", "right") | 🔧 ONLY left/right | 🔧 MISSING leftOuter/rightOuter |
| `label`                  | ✓ optional                                                  | ✓ `yAxisLabel`                      | ✓                   | ✓                  | ✅                              |
| `unit`                   | ✓ optional                                                  | ✓ `yAxisUnit`                       | ✓                   | ✓                  | ✅                              |
| `color`                  | ✓ optional                                                  | ✓ `yAxisColor`                      | ✓                   | ✓                  | ✅                              |
| `min`                    | ✓ optional                                                  | ❌ NOT IN SCHEMA                    | ❌                  | ❌                 | ❌ MISSING                      |
| `max`                    | ✓ optional                                                  | ❌ NOT IN SCHEMA                    | ❌                  | ❌                 | ❌ MISSING                      |
| `visible`                | ✓ default true                                              | ❌                                  | ❌                  | ❌                 | ❌ MISSING                      |
| `showAxisLine`           | ✓ default true                                              | ❌                                  | ❌                  | ❌                 | ❌ MISSING                      |
| `showTicks`              | ✓ default true                                              | ❌                                  | ❌                  | ❌                 | ❌ MISSING                      |
| `showCrosshairLabel`     | ✓ default true                                              | ❌                                  | ❌                  | ❌                 | ❌ MISSING                      |
| `crosshairLabelPosition` | ✓ `CrosshairLabelPosition` enum                             | ❌                                  | ❌                  | ❌                 | ❌ MISSING                      |
| `labelDisplay`           | ✓ `AxisLabelDisplay` enum                                   | ❌                                  | ❌                  | ❌                 | ❌ MISSING                      |
| `minWidth`               | ✓ default 0.0                                               | ❌                                  | ❌                  | ❌                 | ❌ N/A                          |
| `maxWidth`               | ✓ default 80.0                                              | ❌                                  | ❌                  | ❌                 | ❌ N/A                          |
| `tickCount`              | ✓ optional                                                  | ❌                                  | ❌                  | ❌                 | ❌ MISSING                      |
| `labelFormatter`         | ✓ function                                                  | ❌                                  | ❌                  | ❌                 | ❌ N/A (runtime)                |

### YAxisPosition Enum Gap

```
BravenChartPlus supports: leftOuter, left, right, rightOuter
Agentic supports:         left, right ONLY

MISSING: leftOuter, rightOuter
```

---

## 3. X-AXIS CONFIGURATION

### XAxisConfig (BravenChartPlus)

| Property       | BravenChartPlus           | Tool Schema      | Agentic Model       | Renderer Wiring | Status       |
| -------------- | ------------------------- | ---------------- | ------------------- | --------------- | ------------ |
| `label`        | ✓ optional                | ❌ NOT IN SCHEMA | ✓ XAxisConfig.label | HARDCODED "X"   | ⚠️ HARDCODED |
| `unit`         | ✓ optional                | ❌               | ✓                   | ❌              | ❌ MISSING   |
| `min`          | ✓ optional                | ❌               | ✓                   | ❌              | ❌ MISSING   |
| `max`          | ✓ optional                | ❌               | ✓                   | ❌              | ❌ MISSING   |
| `color`        | ✓ optional                | ❌               | ❌                  | ❌              | ❌ MISSING   |
| `visible`      | ✓ default true            | ❌               | ❌                  | ❌              | ❌ MISSING   |
| `showAxisLine` | ✓ default true            | ❌               | ❌                  | ❌              | ❌ MISSING   |
| `showTicks`    | ✓ default true            | ❌               | ❌                  | ❌              | ❌ MISSING   |
| `tickCount`    | ✓ optional                | ❌               | ❌                  | ❌              | ❌ MISSING   |
| `labelDisplay` | ✓ `AxisLabelDisplay` enum | ❌               | ❌                  | ❌              | ❌ MISSING   |

---

## 4. INTERACTION CONFIGURATION

### InteractionConfig (BravenChartPlus)

| Property     | BravenChartPlus     | Tool Schema                               | Agentic Model | Renderer Wiring | Status     |
| ------------ | ------------------- | ----------------------------------------- | ------------- | --------------- | ---------- |
| `enablePan`  | ✓                   | ✓ `interactions.pan`                      | ✓ dynamic     | ✓               | ✅         |
| `enableZoom` | ✓                   | ✓ `interactions.zoom`                     | ✓             | ✓               | ✅         |
| `crosshair`  | ✓ `CrosshairConfig` | ✓ `interactions.crosshair` (boolean only) | ✓             | 🔧 enabled only | ⚠️ PARTIAL |
| `tooltip`    | ✓ `TooltipConfig`   | ✓ `interactions.tooltip` (boolean only)   | ✓             | 🔧 enabled only | ⚠️ PARTIAL |
| `gesture`    | ✓ `GestureConfig`   | ❌                                        | ❌            | ❌              | ❌ MISSING |
| `keyboard`   | ✓ `KeyboardConfig`  | ❌                                        | ❌            | ❌              | ❌ MISSING |

### CrosshairConfig (BravenChartPlus)

| Property                  | BravenChartPlus                                      | Tool Schema | Status     |
| ------------------------- | ---------------------------------------------------- | ----------- | ---------- |
| `enabled`                 | ✓                                                    | ✓ boolean   | ✅         |
| `mode`                    | ✓ `CrosshairMode` (vertical, horizontal, both, none) | ❌          | ❌ MISSING |
| `snapToDataPoint`         | ✓                                                    | ❌          | ❌ MISSING |
| `snapRadius`              | ✓                                                    | ❌          | ❌ MISSING |
| `showCoordinateLabels`    | ✓                                                    | ❌          | ❌ MISSING |
| `style`                   | ✓ `CrosshairStyle`                                   | ❌          | ❌ MISSING |
| `displayMode`             | ✓ `CrosshairDisplayMode`                             | ❌          | ❌ MISSING |
| `interpolateValues`       | ✓                                                    | ❌          | ❌ MISSING |
| `showIntersectionMarkers` | ✓                                                    | ❌          | ❌ MISSING |

### TooltipConfig (BravenChartPlus)

| Property            | BravenChartPlus                                      | Tool Schema | Status     |
| ------------------- | ---------------------------------------------------- | ----------- | ---------- |
| `enabled`           | ✓                                                    | ✓ boolean   | ✅         |
| `triggerMode`       | ✓ `TooltipTriggerMode` (hover, tap, both)            | ❌          | ❌ MISSING |
| `preferredPosition` | ✓ `TooltipPosition` (auto, top, bottom, left, right) | ❌          | ❌ MISSING |
| `showDelay`         | ✓ Duration                                           | ❌          | ❌ MISSING |
| `hideDelay`         | ✓ Duration                                           | ❌          | ❌ MISSING |
| `followCursor`      | ✓ boolean                                            | ❌          | ❌ MISSING |
| `offsetFromPoint`   | ✓ double                                             | ❌          | ❌ MISSING |
| `style`             | ✓ `TooltipStyle`                                     | ❌          | ❌ MISSING |

---

## 5. GRID CONFIGURATION

### GridConfig (BravenChartPlus)

| Property                | BravenChartPlus | Tool Schema         | Agentic Model | Renderer Wiring | Status       |
| ----------------------- | --------------- | ------------------- | ------------- | --------------- | ------------ |
| `horizontal`            | ✓ default true  | ❌                  | ❌            | ❌              | ❌ MISSING   |
| `vertical`              | ✓ default true  | ❌                  | ❌            | ❌              | ❌ MISSING   |
| `horizontalColor`       | ✓ optional      | ✓ `style.gridColor` | ✓             | ❌ NOT PASSED   | ⚠️ NOT WIRED |
| `verticalColor`         | ✓ optional      | ❌                  | ❌            | ❌              | ❌ MISSING   |
| `horizontalStrokeWidth` | ✓ default 0.5   | ❌                  | ❌            | ❌              | ❌ MISSING   |
| `verticalStrokeWidth`   | ✓ default 0.5   | ❌                  | ❌            | ❌              | ❌ MISSING   |

**Note**: `showGrid` (boolean) IS supported and wired via theme.gridStyle manipulation.

---

## 6. LEGEND CONFIGURATION

### LegendStyle (BravenChartPlus)

| Property          | BravenChartPlus                | Tool Schema                      | Renderer Wiring | Status     |
| ----------------- | ------------------------------ | -------------------------------- | --------------- | ---------- |
| `position`        | ✓ `LegendPosition` (9 options) | ✓ top/bottom/left/right (4 only) | ✓ mapped        | 🔧 PARTIAL |
| `orientation`     | ✓ `LegendOrientation`          | ❌                               | ❌              | ❌ MISSING |
| `textStyle`       | ✓ TextStyle                    | ❌                               | ❌              | ❌ MISSING |
| `backgroundColor` | ✓ optional                     | ❌                               | ❌              | ❌ MISSING |
| `borderColor`     | ✓ optional                     | ❌                               | ❌              | ❌ MISSING |
| `borderWidth`     | ✓ default 1.0                  | ❌                               | ❌              | ❌ MISSING |
| `markerShape`     | ✓ `LegendMarkerShape`          | ❌                               | ❌              | ❌ MISSING |
| `markerSize`      | ✓ default 12.0                 | ❌                               | ❌              | ❌ MISSING |
| `itemSpacing`     | ✓ default 4.0                  | ❌                               | ❌              | ❌ MISSING |
| `opacity`         | ✓ default 1.0                  | ❌                               | ❌              | ❌ MISSING |
| `allowDragging`   | ✓ default true                 | ❌                               | ❌              | ❌ MISSING |

---

## 7. THEME CONFIGURATION

### ChartTheme (BravenChartPlus)

| Property           | BravenChartPlus | Tool Schema               | Renderer Wiring | Status     |
| ------------------ | --------------- | ------------------------- | --------------- | ---------- |
| dark/light presets | ✓               | ✓ `useDarkTheme`          | ✓               | ✅         |
| `backgroundColor`  | ✓               | ✓ `style.backgroundColor` | ❌ NOT WIRED    | ⚠️ MISSING |
| `plotAreaColor`    | ✓               | ❌                        | ❌              | ❌ MISSING |
| `axisStyle`        | ✓ AxisStyle     | ✓ `style.axisColor`       | ❌ NOT WIRED    | ⚠️ MISSING |
| `gridStyle`        | ✓ GridStyle     | ✓ `style.gridColor`       | ❌ NOT WIRED    | ⚠️ MISSING |
| `seriesStyle`      | ✓ SeriesTheme   | ❌                        | ❌              | ❌ MISSING |
| `legendStyle`      | ✓ LegendStyle   | ❌                        | ❌              | ❌ MISSING |

---

## 8. BRAVENCHARPLUS WIDGET PARAMETERS

### BravenChartPlus Constructor

| Parameter           | In Tool Schema   | Wired in Renderer    | Status          |
| ------------------- | ---------------- | -------------------- | --------------- | ---------- |
| `series`            | ✓                | ✓                    | ✅              |
| `annotations`       | ✓                | ✓                    | ✅              |
| `theme`             | ✓ dark/light     | ✓                    | ✅              |
| `xAxisConfig`       | ❌ partial       | 🔧 hardcoded label   | ⚠️ PARTIAL      |
| `yAxis`             | ✓ partial        | ✓                    | 🔧 PARTIAL      |
| `grid`              | ❌ (uses theme)  | via theme            | ✅ (workaround) |
| `width`             | ❌               | HARDCODED 350 height | ⚠️ HARDCODED    |
| `height`            | ❌               | HARDCODED 350        | ⚠️ HARDCODED    |
| `backgroundColor`   | ✓ in style       | ❌ NOT WIRED         | ⚠️ MISSING      |
| `showDebugInfo`     | ❌               | ❌                   | ❌ N/A          |
| `showXScrollbar`    | ✓                | ✓                    | ✅              |
| `showYScrollbar`    | ✓                | ✓                    | ✅              |
| `scrollbarTheme`    | ❌               | ❌                   | ❌ MISSING      |
| `interactionConfig` | ✓ partial        | ✓ partial            | 🔧 PARTIAL      |
| `title`             | ❌ NOT IN SCHEMA | ✓ in model           | ❌ NOT WIRED    | ⚠️ MISSING |
| `subtitle`          | ❌ NOT IN SCHEMA | ✓ in model           | ❌ NOT WIRED    | ⚠️ MISSING |
| `showLegend`        | ✓                | ✓                    | ✅              |
| `legendStyle`       | ✓ partial        | ✓ partial            | 🔧 PARTIAL      |
| `showToolbar`       | ❌               | ❌                   | ❌ MISSING      |
| `normalizationMode` | ✓                | ✓                    | ✅              |

---

## PRIORITY FIXES NEEDED

### P0 - CRITICAL (Agent can specify but it doesn't work)

1. **dataPointMarkerRadius** - In model, NOT in schema, NOT wired
2. **strokeWidth for AreaChartSeries** - NOT passed to constructor
3. **yAxisId** - In schema, in model, NOT passed to series
4. **unit** (series-level) - In schema, in model, NOT passed to series
5. **barWidthPercent/barWidthPixels** - In model, NOT in schema, HARDCODED

### P1 - HIGH (Commonly needed, missing from schema)

1. **leftOuter/rightOuter Y-axis positions** - BravenChartPlus supports, schema doesn't
2. **X-axis configuration** (label, min, max, unit) - NOT in schema
3. **Chart title/subtitle** - In model but NOT in schema or wired
4. **Chart width/height** - HARDCODED to 350
5. **Y-axis min/max bounds** - NOT in schema

### P2 - MEDIUM (Nice to have)

1. **CrosshairConfig details** (mode, snap, style)
2. **TooltipConfig details** (position, trigger, style)
3. **LegendStyle details** (orientation, marker shape, spacing)
4. **GridConfig details** (horizontal/vertical visibility, colors, widths)

### P3 - LOW (Advanced features)

1. **AxisLabelDisplay** enum for tick formatting
2. **Keyboard/Gesture configs**
3. **Theme customization beyond dark/light**
4. **labelFormatter functions** (runtime, can't be in schema)

---

## RENDERER FIX CHECKLIST

### Immediate Fixes in ChartRenderer.\_createSeriesForType:

```dart
// LineChartSeries - ADD:
dataPointMarkerRadius: dataPointMarkerRadius ?? 3.0,

// AreaChartSeries - ADD:
strokeWidth: strokeWidth,
dataPointMarkerRadius: dataPointMarkerRadius ?? 3.0,

// All series - ADD:
yAxisId: yAxisId,
unit: unit,
```

### Immediate Fixes in ChartRenderer.\_renderConfiguration:

```dart
// Wire chart dimensions:
SizedBox(
  width: config.layout?.width,  // Need to add to schema
  height: config.layout?.height ?? 350,
  ...
)

// Wire title/subtitle:
BravenChartPlus(
  title: config.title,
  subtitle: config.subtitle,
  ...
)
```

### Schema Additions Needed (CreateChartTool.inputSchema):

```dart
// Add to series properties:
'dataPointMarkerRadius': {'type': 'number', 'description': '...'},
'barWidthPercent': {'type': 'number', 'minimum': 0, 'maximum': 1},

// Add to yAxisPosition enum:
'yAxisPosition': {'enum': ['left', 'right', 'leftOuter', 'rightOuter']},

// Add top-level:
'title': {'type': 'string'},
'subtitle': {'type': 'string'},
'width': {'type': 'number'},
'height': {'type': 'number'},

// Add xAxis object:
'xAxis': {
  'type': 'object',
  'properties': {
    'label': {'type': 'string'},
    'unit': {'type': 'string'},
    'min': {'type': 'number'},
    'max': {'type': 'number'},
  }
}
```

---

## SUMMARY

| Category           | Total Props | Fully Wired | Partial | Missing | % Coverage |
| ------------------ | ----------- | ----------- | ------- | ------- | ---------- |
| LineChartSeries    | 14          | 9           | 1       | 4       | 64%        |
| AreaChartSeries    | 8           | 5           | 0       | 3       | 63%        |
| BarChartSeries     | 4           | 0           | 0       | 4       | 0%         |
| ScatterChartSeries | 1           | 1           | 0       | 0       | 100%       |
| YAxisConfig        | 16          | 4           | 1       | 11      | 25%        |
| XAxisConfig        | 10          | 0           | 1       | 9       | 0%         |
| InteractionConfig  | 6           | 2           | 2       | 2       | 33%        |
| CrosshairConfig    | 9           | 1           | 0       | 8       | 11%        |
| TooltipConfig      | 9           | 1           | 0       | 8       | 11%        |
| GridConfig         | 6           | 1           | 0       | 5       | 17%        |
| LegendStyle        | 11          | 0           | 1       | 10      | 0%         |
| **OVERALL**        | **94**      | **24**      | **6**   | **64**  | **26%**    |

**CONCLUSION**: Only ~26% of BravenChartPlus capabilities are exposed through the agentic tooling. Critical gaps exist in axis configuration, chart dimensions, and series-specific properties.
