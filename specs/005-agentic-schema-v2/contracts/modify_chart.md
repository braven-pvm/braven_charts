# Tool Contract: modify_chart

**Version**: 2.0 (MAJOR REWRITE)  
**Feature**: 005-agentic-schema-v2

## Description

Modifies an existing chart using explicit update, add, and remove operations. Execution order is: remove → add → update. Returns the modified chart configuration including any newly generated IDs.

## Input Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "description": "Modify an existing chart. Use 'update' for changes, 'add' for new items, 'remove' for deletions. Execution order: remove → add → update.",
  "properties": {
    "chartId": {
      "type": "string",
      "description": "Optional chart identifier. If omitted, modifies the current/active chart."
    },
    "update": {
      "type": "object",
      "description": "Partial chart configuration to merge. Nested objects are deep-merged, scalars and arrays are replaced.",
      "properties": {
        "title": { "type": "string" },
        "xAxis": { "$ref": "#/definitions/XAxisConfig" },
        "yAxis": { "$ref": "#/definitions/YAxisConfig" },
        "normalizationMode": {
          "type": "string",
          "enum": ["none", "auto", "perSeries"]
        },
        "series": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "id": {
                "type": "string",
                "description": "REQUIRED. ID of series to update."
              },
              "name": { "type": "string" },
              "type": { "type": "string" },
              "data": { "type": "array" },
              "color": { "type": "string" },
              "yAxis": {
                "$ref": "#/definitions/YAxisConfig",
                "description": "Partial yAxis update - will be deep-merged with existing"
              }
            },
            "required": ["id"]
          },
          "description": "Series updates. Each entry MUST have 'id' of existing series."
        },
        "annotations": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "id": {
                "type": "string",
                "description": "REQUIRED. ID of annotation to update."
              }
            },
            "required": ["id"]
          },
          "description": "Annotation updates. Each entry MUST have 'id' of existing annotation."
        }
      }
    },
    "add": {
      "type": "object",
      "description": "New items to add to the chart.",
      "properties": {
        "series": {
          "type": "array",
          "items": { "$ref": "#/definitions/SeriesConfig" },
          "description": "New series to add. Must have unique IDs."
        },
        "annotations": {
          "type": "array",
          "items": { "$ref": "#/definitions/AnnotationConfig" },
          "description": "New annotations to add. IDs will be generated."
        }
      }
    },
    "remove": {
      "type": "object",
      "description": "Items to remove from the chart by ID.",
      "properties": {
        "series": {
          "type": "array",
          "items": { "type": "string" },
          "description": "Array of series IDs to remove"
        },
        "annotations": {
          "type": "array",
          "items": { "type": "string" },
          "description": "Array of annotation IDs to remove"
        }
      }
    }
  },
  "definitions": {
    "YAxisConfig": {
      "type": "object",
      "properties": {
        "label": { "type": "string" },
        "unit": { "type": "string" },
        "position": {
          "type": "string",
          "enum": ["left", "right", "leftOuter", "rightOuter"]
        },
        "color": { "type": "string" },
        "min": { "type": "number" },
        "max": { "type": "number" },
        "autoRange": { "type": "boolean" },
        "includeZero": { "type": "boolean" },
        "showTicks": { "type": "boolean" },
        "showAxisLine": { "type": "boolean" },
        "showGridLines": { "type": "boolean" }
      }
    },
    "XAxisConfig": {
      "type": "object",
      "properties": {
        "label": { "type": "string" },
        "type": {
          "type": "string",
          "enum": ["numeric", "datetime", "category"]
        },
        "format": { "type": "string" },
        "showTicks": { "type": "boolean" },
        "showAxisLine": { "type": "boolean" },
        "showGridLines": { "type": "boolean" }
      }
    },
    "SeriesConfig": {
      "type": "object",
      "properties": {
        "id": { "type": "string" },
        "name": { "type": "string" },
        "type": {
          "type": "string",
          "enum": ["line", "area", "bar", "scatter", "step"]
        },
        "data": { "type": "array" },
        "color": { "type": "string" },
        "yAxis": { "$ref": "#/definitions/YAxisConfig" }
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
        "seriesId": { "type": "string" },
        "orientation": { "type": "string", "enum": ["horizontal", "vertical"] },
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
    "chart": {
      "type": "object",
      "description": "Complete chart configuration after modifications (data as count)"
    },
    "added": {
      "type": "object",
      "description": "Newly added items with generated IDs",
      "properties": {
        "annotations": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "id": { "type": "string" }
            }
          }
        }
      }
    },
    "warnings": {
      "type": "array",
      "items": { "type": "string" }
    },
    "error": {
      "type": "string"
    }
  }
}
```

## Merge Semantics

| Field Type                       | Behavior   | Example                                                  |
| -------------------------------- | ---------- | -------------------------------------------------------- |
| Scalar (string, number, boolean) | Replace    | `"title": "New"` replaces old title                      |
| Nested Object                    | Deep merge | `"yAxis": { "label": "New" }` merges into existing yAxis |
| Array                            | Replace    | `"data": [...]` replaces entire data array               |

### Deep Merge Example

Existing series:

```json
{
  "id": "heart-rate",
  "yAxis": { "label": "BPM", "color": "#ff0000", "min": 0, "max": 200 }
}
```

Update:

```json
{
  "update": {
    "series": [{ "id": "heart-rate", "yAxis": { "min": 50, "max": 180 } }]
  }
}
```

Result:

```json
{
  "id": "heart-rate",
  "yAxis": { "label": "BPM", "color": "#ff0000", "min": 50, "max": 180 }
}
```

## Execution Order

1. **REMOVE**: Delete items by ID first
2. **ADD**: Add new items (generates annotation IDs)
3. **UPDATE**: Apply updates to remaining/new items

This order ensures:

- Removed IDs don't conflict with add
- Updates can reference newly added series

## Validation Rules

| Rule      | Type    | Condition                                        |
| --------- | ------- | ------------------------------------------------ |
| V010      | Error   | `update.series[].id` not found in chart          |
| V011      | Error   | `remove.series` contains non-existent ID         |
| V012      | Error   | `add.series[].id` already exists                 |
| V020      | Error   | `update.annotations[].id` not found in chart     |
| V021      | Error   | `remove.annotations` contains non-existent ID    |
| V022      | Warning | Agent supplies `id` on add.annotations (ignored) |
| V030-V044 | Error   | Type-specific annotation validation              |

## Examples

### Update Series Y-Axis

```json
{
  "update": {
    "series": [
      {
        "id": "heart-rate",
        "yAxis": { "min": 50, "max": 180 }
      }
    ]
  }
}
```

### Add Annotation

```json
{
  "add": {
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
}
```

Response includes generated ID:

```json
{
  "success": true,
  "added": {
    "annotations": [{ "id": "ann-uuid-003" }]
  }
}
```

### Remove Annotation

```json
{
  "remove": {
    "annotations": ["ann-uuid-001"]
  }
}
```

### Combined Operations

```json
{
  "remove": {
    "annotations": ["ann-uuid-001"]
  },
  "add": {
    "annotations": [
      {
        "type": "zone",
        "orientation": "horizontal",
        "minValue": 150,
        "maxValue": 170,
        "seriesId": "heart-rate"
      }
    ]
  },
  "update": {
    "title": "Updated Chart Title",
    "series": [
      {
        "id": "heart-rate",
        "yAxis": { "label": "Heart Rate (BPM)" }
      }
    ]
  }
}
```

## Error Cases

| Condition                          | Response                                                                    |
| ---------------------------------- | --------------------------------------------------------------------------- |
| No chart exists                    | `{ "success": false, "error": "No chart exists. Use create_chart first." }` |
| Series ID not found for update     | `{ "success": false, "error": "Series not found: {id}" }`                   |
| Annotation ID not found for update | `{ "success": false, "error": "Annotation not found: {id}" }`               |
| Duplicate series ID on add         | `{ "success": false, "error": "Series ID already exists: {id}" }`           |

## Migration from V1

V1 patterns no longer supported:

| V1 Pattern                             | V2 Replacement                             |
| -------------------------------------- | ------------------------------------------ |
| `modifications.series[].yAxisPosition` | `update.series[].yAxis.position`           |
| `modifications.series[].yAxisLabel`    | `update.series[].yAxis.label`              |
| `addSeries: [...]`                     | `add.series: [...]`                        |
| `removeSeries: ["id"]`                 | `remove.series: ["id"]`                    |
| `addAnnotations: [...]`                | `add.annotations: [...]`                   |
| No annotation update                   | `update.annotations: [{ id: "...", ... }]` |
| No annotation remove                   | `remove.annotations: ["id"]`               |
