# Tool Contract: get_chart

**Version**: 2.0 (NEW)  
**Feature**: 005-agentic-schema-v2

## Description

Retrieves the current chart configuration including all IDs. Use this to discover series IDs and annotation IDs for subsequent modify_chart operations.

## Input Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "description": "Query the current chart configuration. Returns all IDs for series and annotations.",
  "properties": {
    "chartId": {
      "type": "string",
      "description": "Optional chart identifier. If omitted, returns the current/active chart."
    },
    "includeData": {
      "type": "boolean",
      "default": false,
      "description": "Whether to include full data arrays. Default false returns data as { \"count\": N } to save tokens."
    }
  },
  "required": []
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
      "description": "Complete chart configuration with all IDs. Data arrays replaced with { \"count\": N } unless includeData is true."
    },
    "error": {
      "type": "string",
      "description": "Error message if success is false"
    }
  }
}
```

## Data Handling

When `includeData: false` (default):

```json
{
  "series": [
    {
      "id": "heart-rate",
      "name": "Heart Rate",
      "data": { "count": 1500 },
      "yAxis": { ... }
    }
  ]
}
```

When `includeData: true`:

```json
{
  "series": [
    {
      "id": "heart-rate",
      "name": "Heart Rate",
      "data": [{"x": 0, "y": 120}, {"x": 1, "y": 125}, ...],
      "yAxis": { ... }
    }
  ]
}
```

## Example

### Request (default, no data)

```json
{}
```

### Response

```json
{
  "success": true,
  "chart": {
    "title": "Performance Metrics",
    "normalizationMode": "perSeries",
    "series": [
      {
        "id": "heart-rate",
        "name": "Heart Rate",
        "data": { "count": 1500 },
        "yAxis": { "label": "BPM", "position": "left", "color": "#ff0000" }
      },
      {
        "id": "power",
        "name": "Power",
        "data": { "count": 1500 },
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
      },
      {
        "id": "ann-uuid-002",
        "type": "zone",
        "orientation": "horizontal",
        "minValue": 150,
        "maxValue": 170,
        "seriesId": "heart-rate",
        "color": "#ffcccc"
      }
    ]
  }
}
```

### Request (with full data)

```json
{
  "includeData": true
}
```

### Response

```json
{
  "success": true,
  "chart": {
    "title": "Performance Metrics",
    "series": [
      {
        "id": "heart-rate",
        "name": "Heart Rate",
        "data": [{"x": 0, "y": 120}, {"x": 1, "y": 125}, {"x": 2, "y": 130}, ...],
        "yAxis": { "label": "BPM", "position": "left", "color": "#ff0000" }
      }
    ],
    "annotations": [...]
  }
}
```

## Error Cases

| Condition       | Response                                                                    |
| --------------- | --------------------------------------------------------------------------- |
| No chart exists | `{ "success": false, "error": "No chart exists. Use create_chart first." }` |
| Invalid chartId | `{ "success": false, "error": "Chart not found: {chartId}" }`               |

## Use Cases

1. **Discover IDs before modify**: Call `get_chart` to see current series/annotation IDs, then use those IDs in `modify_chart`
2. **Verify changes**: Call `get_chart` after `modify_chart` to confirm changes applied correctly
3. **Debug state**: Inspect full chart configuration when troubleshooting
