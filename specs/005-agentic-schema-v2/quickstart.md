# Quickstart: Agentic Schema V2

**Feature**: 005-agentic-schema-v2  
**Audience**: LLM agents and developers using braven_agent tools

## Overview

Schema V2 provides three tools for chart management:

| Tool           | Purpose                                        |
| -------------- | ---------------------------------------------- |
| `create_chart` | Create a new chart with series and annotations |
| `get_chart`    | Query current chart state with all IDs         |
| `modify_chart` | Update, add, or remove chart elements          |

## Key Concepts

### 1. Nested Y-Axis

Each series can have its own Y-axis configuration:

```json
{
  "series": [{
    "id": "heart-rate",
    "data": [...],
    "yAxis": {
      "label": "BPM",
      "position": "left",
      "min": 0,
      "max": 200
    }
  }]
}
```

### 2. Normalization Modes

| Mode        | Description                      | Y-Axis Source       |
| ----------- | -------------------------------- | ------------------- |
| `none`      | Raw values, no scaling           | Chart-level `yAxis` |
| `auto`      | Auto-scale all series together   | Chart-level `yAxis` |
| `perSeries` | Each series scaled independently | `series[].yAxis`    |

### 3. Annotation IDs

Annotations get system-generated IDs that you can use for updates/removes:

```json
// Create returns:
{ "annotations": [{ "id": "ann-uuid-001", "type": "referenceLine", ... }] }

// Use ID to update:
{ "update": { "annotations": [{ "id": "ann-uuid-001", "color": "#00ff00" }] } }

// Use ID to remove:
{ "remove": { "annotations": ["ann-uuid-001"] } }
```

## Common Workflows

### Create a Multi-Axis Chart

```json
// create_chart input
{
  "title": "Cycling Performance",
  "normalizationMode": "perSeries",
  "series": [
    {
      "id": "heart-rate",
      "name": "Heart Rate",
      "data": [
        { "x": 0, "y": 120 },
        { "x": 60, "y": 145 }
      ],
      "yAxis": { "label": "BPM", "position": "left", "color": "#ff0000" }
    },
    {
      "id": "power",
      "name": "Power",
      "data": [
        { "x": 0, "y": 180 },
        { "x": 60, "y": 250 }
      ],
      "yAxis": { "label": "Watts", "position": "right", "color": "#0000ff" }
    }
  ]
}
```

### Query Chart State

```json
// get_chart input (default - excludes data arrays)
{}

// Response shows all IDs
{
  "chart": {
    "series": [
      {"id": "heart-rate", "data": {"count": 100}, ...},
      {"id": "power", "data": {"count": 100}, ...}
    ],
    "annotations": [
      {"id": "ann-uuid-001", "type": "referenceLine", ...}
    ]
  }
}
```

### Update Y-Axis Range

```json
// modify_chart input
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

### Add and Remove Annotations

```json
// modify_chart input
{
  "remove": {
    "annotations": ["ann-uuid-001"]
  },
  "add": {
    "annotations": [{
      "type": "zone",
      "orientation": "horizontal",
      "minValue": 150,
      "maxValue": 180,
      "seriesId": "heart-rate",
      "color": "rgba(255,0,0,0.2)"
    }]
  }
}

// Response includes new ID
{
  "added": {
    "annotations": [{"id": "ann-uuid-002"}]
  }
}
```

## Quick Reference

### Y-Axis Positions

| Position     | Description                            |
| ------------ | -------------------------------------- |
| `left`       | Primary left axis (default)            |
| `right`      | Primary right axis                     |
| `leftOuter`  | Secondary left axis (outside primary)  |
| `rightOuter` | Secondary right axis (outside primary) |

### Annotation Types

| Type            | Required Fields                       | seriesId Required?           |
| --------------- | ------------------------------------- | ---------------------------- |
| `referenceLine` | `value`, `orientation`                | Horizontal in perSeries mode |
| `zone`          | `minValue`, `maxValue`, `orientation` | Horizontal in perSeries mode |
| `textLabel`     | `text`, `x`, `y`                      | Never                        |
| `marker`        | `x`, `y`                              | Always                       |
| `point`         | `dataPointIndex`                      | Always                       |

### Merge Behavior

| Field Type    | Behavior   |
| ------------- | ---------- |
| Scalar        | Replace    |
| Nested Object | Deep merge |
| Array         | Replace    |

## Error Handling

Common validation errors:

| Code | Message                                 | Resolution                        |
| ---- | --------------------------------------- | --------------------------------- |
| V003 | Duplicate series ID                     | Use unique IDs for each series    |
| V010 | Series not found for update             | Use `get_chart` to find valid IDs |
| V011 | Series not found for remove             | Verify ID exists before removing  |
| V030 | seriesId references non-existent series | Check series IDs with `get_chart` |
| V031 | Point annotation requires seriesId      | Add `seriesId` field              |

## Migration from V1

If you're updating from V1 schema:

1. Replace flat y-axis fields with nested `yAxis` object
2. Remove `yAxisId` references
3. Use `update`/`add`/`remove` sections instead of `modifications`
4. Annotation updates now require ID (use `get_chart` to discover IDs)

See [contracts/modify_chart.md](contracts/modify_chart.md) for full migration table.
