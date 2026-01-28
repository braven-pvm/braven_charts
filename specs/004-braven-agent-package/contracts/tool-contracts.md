# Tool Contracts: Braven Agent Package

**Feature**: 004-braven-agent-package  
**Date**: 2026-01-28  
**Status**: Complete

## Overview

This document defines the JSON Schema contracts for all LLM tools in the `braven_agent` package. These schemas are provided to the LLM for structured tool invocation.

---

## 1. CreateChartTool

### 1.1 Metadata

| Property        | Value                                                                                                                                                               |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Name**        | `create_chart`                                                                                                                                                      |
| **Description** | Creates an interactive chart from provided data. Use this tool when the user wants to visualize data. ALWAYS include the data array with x,y values in each series. |

### 1.2 Input Schema

```json
{
  "type": "object",
  "properties": {
    "prompt": {
      "type": "string",
      "description": "Natural language description of the chart."
    },
    "type": {
      "type": "string",
      "enum": ["line", "area", "bar", "scatter"],
      "description": "Type of chart to render."
    },
    "title": {
      "type": "string",
      "description": "Chart title displayed at the top."
    },
    "subtitle": {
      "type": "string",
      "description": "Chart subtitle below the title."
    },
    "series": {
      "type": "array",
      "description": "Data series to plot. REQUIRED.",
      "items": {
        "type": "object",
        "properties": {
          "id": {
            "type": "string",
            "description": "Unique series identifier."
          },
          "name": {
            "type": "string",
            "description": "Display name for legend."
          },
          "color": {
            "type": "string",
            "description": "Hex color (#RRGGBB)."
          },
          "data": {
            "type": "array",
            "description": "Array of data points.",
            "items": {
              "type": "object",
              "properties": {
                "x": { "type": "number" },
                "y": { "type": "number" }
              },
              "required": ["x", "y"]
            }
          },
          "strokeWidth": {
            "type": "number",
            "description": "Line width in pixels. Default: 2.0"
          },
          "strokeDash": {
            "type": "array",
            "items": { "type": "number" },
            "description": "Dash pattern [5, 3]."
          },
          "fillOpacity": {
            "type": "number",
            "minimum": 0,
            "maximum": 1,
            "description": "Area fill opacity. Default: 0.0"
          },
          "markerStyle": {
            "type": "string",
            "enum": ["none", "circle", "square", "triangle", "diamond"]
          },
          "markerSize": {
            "type": "number",
            "description": "Marker radius. Default: 4.0"
          },
          "interpolation": {
            "type": "string",
            "enum": ["linear", "bezier", "stepped", "monotone"]
          },
          "showPoints": {
            "type": "boolean",
            "description": "Show data point markers."
          },
          "yAxisPosition": {
            "type": "string",
            "enum": ["left", "right", "leftOuter", "rightOuter"]
          },
          "yAxisLabel": { "type": "string" },
          "yAxisUnit": { "type": "string" },
          "yAxisColor": { "type": "string" },
          "yAxisMin": { "type": "number" },
          "yAxisMax": { "type": "number" }
        },
        "required": ["id", "data"]
      }
    },
    "xAxis": {
      "type": "object",
      "properties": {
        "label": { "type": "string" },
        "unit": { "type": "string" },
        "min": { "type": "number" },
        "max": { "type": "number" },
        "tickCount": { "type": "integer" },
        "showAxisLine": { "type": "boolean" },
        "showTicks": { "type": "boolean" },
        "showGridLines": { "type": "boolean" }
      }
    },
    "annotations": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "type": {
            "type": "string",
            "enum": ["referenceLine", "zone", "textLabel", "marker"]
          },
          "orientation": {
            "type": "string",
            "enum": ["horizontal", "vertical"]
          },
          "value": { "type": "number" },
          "minValue": { "type": "number" },
          "maxValue": { "type": "number" },
          "x": { "type": "number" },
          "y": { "type": "number" },
          "position": {
            "type": "string",
            "enum": [
              "topLeft",
              "topCenter",
              "topRight",
              "centerLeft",
              "center",
              "centerRight",
              "bottomLeft",
              "bottomCenter",
              "bottomRight"
            ]
          },
          "text": { "type": "string" },
          "label": { "type": "string" },
          "color": { "type": "string" },
          "opacity": { "type": "number" }
        },
        "required": ["type"]
      }
    },
    "style": {
      "type": "object",
      "properties": {
        "backgroundColor": { "type": "string" },
        "gridColor": { "type": "string" },
        "axisColor": { "type": "string" },
        "fontFamily": { "type": "string" },
        "fontSize": { "type": "number" },
        "paddingTop": { "type": "number" },
        "paddingBottom": { "type": "number" },
        "paddingLeft": { "type": "number" },
        "paddingRight": { "type": "number" }
      }
    },
    "showGrid": { "type": "boolean" },
    "showLegend": { "type": "boolean" },
    "legendPosition": {
      "type": "string",
      "enum": [
        "top",
        "bottom",
        "left",
        "right",
        "topLeft",
        "topRight",
        "bottomLeft",
        "bottomRight"
      ]
    },
    "useDarkTheme": { "type": "boolean" },
    "showScrollbar": { "type": "boolean" },
    "normalizationMode": {
      "type": "string",
      "enum": ["none", "auto", "perSeries"],
      "description": "Y-axis normalization. Use perSeries for multi-metric overlays."
    },
    "width": { "type": "number" },
    "height": { "type": "number" }
  },
  "required": ["prompt", "series"]
}
```

### 1.3 Output Format

**Success:**

```json
{
  "output": "Chart created successfully with 2 series.",
  "isError": false
}
```

**Error:**

```json
{
  "output": "Error: prompt is required",
  "isError": true
}
```

### 1.4 Structured Data

On success, `ToolResult.data` contains a `ChartConfiguration` object which is captured by `AgentSession` to update `state.activeChart`.

---

## 2. ModifyChartTool

### 2.1 Metadata

| Property        | Value                                                                                                                                                                                                           |
| --------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Name**        | `modify_chart`                                                                                                                                                                                                  |
| **Description** | Modifies the currently active chart. Use this when the user wants to change colors, add/remove series, adjust axes, or update any chart properties. Requires an active chart from a previous create_chart call. |

### 2.2 Input Schema

Same schema as `CreateChartTool`, but with no required fields:

```json
{
  "type": "object",
  "properties": {
    "title": { "type": "string" },
    "subtitle": { "type": "string" },
    "type": {
      "type": "string",
      "enum": ["line", "area", "bar", "scatter"]
    },
    "series": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "id": { "type": "string" },
          "name": { "type": "string" },
          "color": { "type": "string" },
          "data": {
            "type": "array",
            "items": {
              "type": "object",
              "properties": {
                "x": { "type": "number" },
                "y": { "type": "number" }
              }
            }
          },
          "strokeWidth": { "type": "number" },
          "fillOpacity": { "type": "number" },
          "markerStyle": {
            "type": "string",
            "enum": ["none", "circle", "square", "triangle", "diamond"]
          },
          "showPoints": { "type": "boolean" },
          "yAxisPosition": {
            "type": "string",
            "enum": ["left", "right", "leftOuter", "rightOuter"]
          }
        }
      }
    },
    "xAxis": {
      "type": "object",
      "properties": {
        "label": { "type": "string" },
        "unit": { "type": "string" },
        "min": { "type": "number" },
        "max": { "type": "number" }
      }
    },
    "annotations": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "type": {
            "type": "string",
            "enum": ["referenceLine", "zone", "textLabel", "marker"]
          },
          "orientation": { "type": "string" },
          "value": { "type": "number" },
          "text": { "type": "string" },
          "color": { "type": "string" }
        }
      }
    },
    "style": {
      "type": "object",
      "properties": {
        "backgroundColor": { "type": "string" },
        "gridColor": { "type": "string" }
      }
    },
    "showGrid": { "type": "boolean" },
    "showLegend": { "type": "boolean" },
    "useDarkTheme": { "type": "boolean" },
    "normalizationMode": {
      "type": "string",
      "enum": ["none", "auto", "perSeries"]
    }
  },
  "required": []
}
```

### 2.3 Output Format

**Success:**

```json
{
  "output": "Chart modified successfully.",
  "isError": false
}
```

**Error - No Active Chart:**

```json
{
  "output": "Error: No active chart to modify. Use create_chart first.",
  "isError": true
}
```

### 2.4 Merge Behavior

When modifying, the tool uses a merge strategy:

| Scenario                   | Behavior                       |
| -------------------------- | ------------------------------ |
| Property provided          | Use new value                  |
| Property omitted           | Keep existing value            |
| Series with same ID        | Merge properties onto existing |
| Series with new ID         | Add new series                 |
| `series: []` (empty array) | Clear all series (error)       |

---

## 3. Provider Contract

### 3.1 LLMProvider Interface

```dart
abstract class LLMProvider {
  String get id;

  Future<LLMResponse> generateResponse({
    required String systemPrompt,
    required List<AgentMessage> history,
    List<AgentTool>? tools,
    LLMConfig? config,
  });

  Stream<LLMChunk> streamResponse({
    required String systemPrompt,
    required List<AgentMessage> history,
    List<AgentTool>? tools,
    LLMConfig? config,
  });
}
```

### 3.2 Tool Definition Contract

Providers must convert `AgentTool` to their native format:

```dart
// Anthropic expects:
{
  "name": "create_chart",
  "description": "...",
  "input_schema": {
    "type": "object",
    "properties": { ... },
    "required": ["prompt", "series"]
  }
}
```

---

## 4. Event Contract

### 4.1 Event Types

| Event                      | Trigger                             | Data                            |
| -------------------------- | ----------------------------------- | ------------------------------- |
| `ChartCreatedEvent`        | `create_chart` success              | `ChartConfiguration`            |
| `ChartUpdatedEvent`        | `modify_chart` success OR user edit | `ChartConfiguration`            |
| `MessageReceivedEvent`     | LLM response received               | `AgentMessage`                  |
| `ErrorEvent`               | Any error                           | `String message, Object? error` |
| `CancelledEvent`           | User cancellation                   | None                            |
| `ProcessingStartedEvent`   | `transform()` called                | None                            |
| `ProcessingCompletedEvent` | `transform()` finished              | None                            |

### 4.2 Event Ordering

```
transform() called
    → ProcessingStartedEvent
    → [LLM processing]
    → ChartCreatedEvent (if tool executed)
    → MessageReceivedEvent
    → ProcessingCompletedEvent
```

---

## 5. State Contract

### 5.1 State Transitions

```
idle → processing (on transform)
processing → idle (on complete)
processing → error (on failure)
error → processing (on retry transform)
error → idle (on clearError)
```

### 5.2 State Invariants

1. `status == processing` ⇒ LLM request in flight
2. `status == error` ⇒ `errorMessage != null`
3. `activeChart != null` ⇒ at least one successful chart tool
4. `history.isNotEmpty` ⇒ at least one transform() call

---

## 6. Default Colors

When series `color` is not specified, assign from palette:

```dart
const defaultColors = [
  '#2196F3',  // Blue
  '#F44336',  // Red
  '#4CAF50',  // Green
  '#FF9800',  // Orange
  '#9C27B0',  // Purple
  '#00BCD4',  // Cyan
  '#795548',  // Brown
  '#607D8B',  // Blue Grey
];
```

Assignment: `color = defaultColors[seriesIndex % 8]`
