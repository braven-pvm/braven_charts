# Research: Agentic Schema V2

**Feature**: 005-agentic-schema-v2  
**Date**: 2025-01-20  
**Status**: COMPLETE (No NEEDS CLARIFICATION items)

## Research Summary

This document captures the research findings that informed the schema v2 design. All open questions have been resolved and documented in `schema_spec.md`.

## Problem Statement

The v1 agentic schema has several structural issues that cause confusion and bugs:

1. **Y-Axis Confusion**: Multiple patterns exist (flat fields, `yAxisId` references, `yAxes[]` array) with unclear precedence
2. **No Annotation IDs**: Cannot update or remove specific annotations after creation
3. **Ambiguous Modify**: `modify_chart` mixes update/add/remove semantics in unclear ways
4. **Missing Query**: No way to inspect current chart state with all IDs

## Research Findings

### RF-001: Nested Y-Axis Pattern

**Question**: How should y-axis configuration be structured?

**Finding**: Nested `series[].yAxis` is the cleanest pattern. Matches `BravenChartPlus` widget API where each series owns its axis config. Eliminates:

- Flat fields (`yAxisPosition`, `yAxisLabel`, etc.) - scattered, incomplete
- Reference pattern (`yAxisId` → `yAxes[]`) - indirection complexity
- Chart-level `yAxes[]` array - orphan configs, unclear ownership

**Decision**: Nested yAxis. Each series contains its own `YAxisConfig` object.

### RF-002: Annotation ID Lifecycle

**Question**: How should annotation IDs be managed?

**Finding**: System-generated IDs follow the `SeriesConfig.id` pattern already in use:

- ID is a settable field on the object (not a wrapper)
- Agent can optionally provide ID on create (will be used if valid)
- System generates UUID if not provided
- ID appears in tool output and `get_chart` response
- Agent uses ID for update/remove operations

**Decision**: System-generated, settable field pattern.

### RF-003: Modify Operation Structure

**Question**: How should modify_chart express intent?

**Finding**: Explicit sections are clearer than overloaded semantics:

```json
{
  "update": { ... },      // Deep merge into existing
  "add": { ... },         // New items
  "remove": { ... }       // By ID
}
```

Execution order: remove → add → update (prevents ID conflicts)

**Decision**: Explicit update/add/remove structure with defined execution order.

### RF-004: Merge Semantics

**Question**: How should nested updates work?

**Finding**: Standard deep merge semantics:
| Field Type | Behavior | Rationale |
|------------|----------|-----------|
| Scalar | Replace | Simple override |
| Nested Object | Deep merge | Partial updates |
| Array | Replace | Append/splice too complex for LLM |

**Decision**: Deep merge for objects, replace for arrays and scalars.

### RF-005: Backward Compatibility

**Question**: Should v2 maintain v1 compatibility?

**Finding**: Shim layers add complexity without solving the problem:

- LLM sees both patterns → confusion
- Maintenance burden for deprecated code
- Core design flaws remain

**Decision**: Breaking change. No backward compatibility. Major version bump required.

### RF-006: get_chart Data Handling

**Question**: Should `get_chart` return full data arrays?

**Finding**: Data arrays can be large (1000s of points). LLM rarely needs raw data for modify operations. Options:

- Always include: Token waste
- Always exclude: Some use cases blocked
- Optional flag: Flexibility

**Decision**: Default `includeData: false` returns `{ "count": N }`. Optional `includeData: true` returns full array.

### RF-007: Y-Axis Position

**Question**: Can chart-level yAxis have configurable position?

**Finding**: No technical reason to restrict. Same `position` enum works at both levels:

- `left` (default)
- `right`
- `leftOuter`
- `rightOuter`

**Decision**: Fully configurable via `yAxis.position` at chart and series level.

## Technical Discoveries

### TD-001: Existing Model Structure

The `braven_agent` package already has separate model classes:

- `packages/braven_agent/lib/src/models/series_config.dart`
- `packages/braven_agent/lib/src/models/annotation_config.dart`
- `packages/braven_agent/lib/src/models/chart_configuration.dart`
- `packages/braven_agent/lib/src/models/y_axis_config.dart`

These mirror but don't duplicate the core `lib/src/models/` classes. Both need updates.

### TD-002: Tool Registration

Tools are registered in `packages/braven_agent/lib/src/tools/tools.dart`. New `get_chart_tool.dart` needs to be added here.

### TD-003: No Existing Validation

There's no `validation/` folder in braven_agent. Schema validation is ad-hoc in tool handlers. Creating dedicated `schema_validator.dart` is new infrastructure.

### TD-004: UUID Dependency

The `uuid` package is already a dependency of `braven_agent` per `pubspec.yaml`. No new dependency needed for ID generation.

## Risks & Mitigations

| Risk                           | Impact | Mitigation                                                   |
| ------------------------------ | ------ | ------------------------------------------------------------ |
| Breaking change disrupts users | High   | Major version bump, clear migration docs, example updates    |
| Deep merge edge cases          | Medium | Exhaustive validation rules (V001-V044), comprehensive tests |
| LLM schema confusion           | Medium | Clear JSON schema descriptions, examples in tool docs        |
| Performance of validation      | Low    | Validation runs once per tool call, not per frame            |

## Conclusion

All research questions resolved. Schema v2 design is finalized in `schema_spec.md`. Ready to proceed with Phase 1 (data model documentation) and implementation planning.
