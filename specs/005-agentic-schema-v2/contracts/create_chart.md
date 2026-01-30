# Tool Contract: create_chart

**Version**: 2.0  
**Feature**: 005-agentic-schema-v2

## Description

Creates a new chart with the specified configuration. Returns the complete chart configuration including all system-generated IDs.

## Input Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "description": "Create a new chart with series and optional annotations. The input IS the chart configuration (no wrapper object).",
  "properties": {
    "title": {
      "type": "string",
      "description": "Chart title displayed above the chart"
    },
    "xAxis": {
      "$ref": "#/definitions/XAxisConfig"
    },
    "yAxis": {
      "$ref": "#/definitions/YAxisConfig",
      "description": "Chart-level Y-axis configuration. Used when normalizationMode is 'none' or 'auto'. Ignored when normalizationMode is 'perSeries'."
    },
    "normalizationMode": {
      "type": "string",
      "enum": ["none", "auto", "perSeries"],
      "default": "none",
      "description": "How to normalize Y-axis values. 'none': raw values, 'auto': auto-scale together, 'perSeries': each series scaled independently"
    },
    "series": {
      "type": "array",
      "minItems": 1,
      "items": {
        "$ref": "#/definitions/SeriesConfig"
      },
      "description": "Array of data series. At least one required."
    },
    "annotations": {
      "type": "array",
      "items": {
        "$ref": "#/definitions/AnnotationConfig"
      },
      "description": "Optional array of annotations. IDs will be generated and returned in output."
    },
    "style": {
      "$ref": "#/definitions/ChartStyleConfig"
    }
  },
  "required": ["series"],
  "definitions": {
    "YAxisConfig": {
      "type": "object",
      "properties": {
        "label": { "type": "string" },
        "unit": { "type": "string" },
        "position": {
          "type": "string",
          "enum": ["left", "right", "leftOuter", "rightOuter"],
          "default": "left"
        },
        "color": { "type": "string" },
        "min": { "type": "number" },
        "max": { "type": "number" },
        "autoRange": { "type": "boolean", "default": true },
        "includeZero": { "type": "boolean", "default": false },
        "showTicks": { "type": "boolean", "default": true },
        "showAxisLine": { "type": "boolean", "default": true },
        "showGridLines": { "type": "boolean", "default": false }
      }
    },
    "XAxisConfig": {
      "type": "object",
      "properties": {
        "label": { "type": "string" },
        "type": {
          "type": "string",
          "enum": ["numeric", "datetime", "category"],
          "default": "numeric"
        },
        "format": { "type": "string" },
        "showTicks": { "type": "boolean", "default": true },
        "showAxisLine": { "type": "boolean", "default": true },
        "showGridLines": { "type": "boolean", "default": false }
      }
    },
    "SeriesConfig": {
      "type": "object",
      "properties": {
        "id": {
          "type": "string",
          "description": "Unique identifier. Provide this to enable update/remove operations."
        },
        "name": { "type": "string" },
        "type": {
          "type": "string",
          "enum": ["line", "area", "bar", "scatter", "step"],
          "default": "line"
        },
        "data": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "x": { "type": "number" },
              "y": { "type": "number" }
            },
            "required": ["x", "y"]
          }
        },
        "color": { "type": "string" },
        "yAxis": {
          "$ref": "#/definitions/YAxisConfig",
          "description": "Per-series Y-axis configuration. Required when normalizationMode is 'perSeries'."
        }
      },
      "required": ["id", "data"]
    },
    "AnnotationConfig": {
      "type": "object",
      "properties": {
        "type": {
          "type": "string",
          "enum": ["referenceLine", "zone", "textLabel", "marker", "point"]
        },
        "seriesId": {
          "type": "string",
          "description": "Required for 'point' and 'marker' types. Required for horizontal 'referenceLine'/'zone' when normalizationMode is 'perSeries'."
        },
        "orientation": {
          "type": "string",
          "enum": ["horizontal", "vertical"]
        },
        "value": { "type": "number" },
        "minValue": { "type": "number" },
        "maxValue": { "type": "number" },
        "text": { "type": "string" },
        "dataPointIndex": { "type": "integer" },
        "x": { "type": "number" },
        "y": { "type": "number" },
        "color": { "type": "string" }
      },
      "required": ["type"]
    },
    "ChartStyleConfig": {
      "type": "object",
      "properties": {
        "backgroundColor": { "type": "string" },
        "padding": { "type": "object" }
      }
    }
  }
}
```

## Output Schema

```json
{
  "type": "object",
  "properties": {
    "success": { "type": "boolean" },
    "chartId": {
      "type": "string",
      "description": "Unique identifier for the created chart"
    },
    "chart": {
      "type": "object",
      "description": "Complete chart configuration with all generated IDs"
    },
    "warnings": {
      "type": "array",
      "items": { "type": "string" },
      "description": "Non-blocking validation warnings (e.g., V001, V002, V022)"
    },
    "error": {
      "type": "string",
      "description": "Error message if success is false"
    }
  }
}
```

## Validation Rules

| Rule      | Type    | Condition                                                         |
| --------- | ------- | ----------------------------------------------------------------- |
| V001      | Warning | `normalizationMode: "perSeries"` AND chart-level `yAxis` provided |
| V002      | Warning | `normalizationMode: "perSeries"` AND series lacks `yAxis`         |
| V003      | Error   | Duplicate series `id`                                             |
| V004      | Error   | Duplicate annotation `id`                                         |
| V022      | Warning | Agent supplies `id` on annotation (will be ignored)               |
| V030-V044 | Error   | Type-specific annotation validation (see schema_spec.md)          |

## Example

### Request

```json
{
  "title": "Performance Metrics",
  "normalizationMode": "perSeries",
  "series": [
    {
      "id": "heart-rate",
      "name": "Heart Rate",
      "data": [
        { "x": 0, "y": 120 },
        { "x": 1, "y": 125 }
      ],
      "yAxis": { "label": "BPM", "position": "left", "color": "#ff0000" }
    },
    {
      "id": "power",
      "name": "Power",
      "data": [
        { "x": 0, "y": 200 },
        { "x": 1, "y": 220 }
      ],
      "yAxis": { "label": "Watts", "position": "right", "color": "#0000ff" }
    }
  ],
  "annotations": [
    {
      "type": "referenceLine",
      "orientation": "horizontal",
      "value": 180,
      "seriesId": "heart-rate",
      "color": "#ff0000"
    }
  ]
}
```

### Response

```json
{
  "success": true,
  "chartId": "chart-abc123",
  "chart": {
    "title": "Performance Metrics",
    "normalizationMode": "perSeries",
    "series": [
      {
        "id": "heart-rate",
        "name": "Heart Rate",
        "data": [
          { "x": 0, "y": 120 },
          { "x": 1, "y": 125 }
        ],
        "yAxis": { "label": "BPM", "position": "left", "color": "#ff0000" }
      },
      {
        "id": "power",
        "name": "Power",
        "data": [
          { "x": 0, "y": 200 },
          { "x": 1, "y": 220 }
        ],
        "yAxis": { "label": "Watts", "position": "right", "color": "#0000ff" }
      }
    ],
    "annotations": [
      {
        "id": "ann-uuid-001",
        "type": "referenceLine",
        "orientation": "horizontal",
        "value": 180,
        "seriesId": "heart-rate",
        "color": "#ff0000"
      }
    ]
  },
  "warnings": []
}
```
