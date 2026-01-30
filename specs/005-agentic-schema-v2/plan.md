# Implementation Plan: Agentic Schema V2

**Branch**: `005-agentic-schema-v2` | **Date**: 2025-01-20 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/005-agentic-schema-v2/spec.md`
**Base Spec**: Technical schema from `/specs/_base/005-agentic-schema-v2/schema_spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Complete redesign of the agentic chart schema to fix structural issues with Y-axis configuration (nested vs flat fields), add annotation IDs for lifecycle management, and restructure modify_chart to use explicit update/add/remove operations. This is a breaking change with no backward compatibility - all V1 patterns (`yAxisId`, `yAxes[]`, flat y-axis fields) will be removed immediately.

**Technical Approach**:

- Nested `series[].yAxis` instead of flat fields or `yAxisId` references
- System-generated annotation IDs (like SeriesConfig.id pattern)
- New `get_chart` tool for querying chart state with IDs
- Restructured `modify_chart` with explicit `update`/`add`/`remove` sections
- Deep merge semantics for nested objects, replace for scalars and arrays
- 44 validation rules (V001-V044) for schema correctness

## Technical Context

**Language/Version**: Dart 3.0+ (3.10.0-227.0.dev)  
**Framework**: Flutter SDK 3.37.0-1.0.pre-216  
**Primary Dependencies**: `braven_chart_plus` (parent), `anthropic_sdk_dart: ^0.2.0`, `uuid: ^4.0.0`, `equatable: ^2.0.5`, `meta: ^1.11.0`  
**Storage**: N/A (session-local only, no persistence in V1)  
**Testing**: `flutter test` (widget tests, unit tests, integration tests)  
**Target Platform**: Flutter (Web, Windows, macOS, Linux, iOS, Android)  
**Project Type**: Flutter package (monorepo with braven_agent sub-package)  
**Performance Goals**: 60 fps rendering, <16ms frame budget for chart updates  
**Constraints**: Pure Flutter (no external packages for core rendering), ValueNotifier for high-frequency updates  
**Scale/Scope**: LLM agentic chart creation/modification via tool calls

## Constitution Check

_GATE: Must pass before Phase 0 research. Re-check after Phase 1 design._

| Principle                                   | Status      | Notes                                                                                                                                                    |
| ------------------------------------------- | ----------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| I. Test-First Development                   | ✅ PASS     | TDD required - spec includes Phase 6 test tasks. Red-green-refactor cycle will be enforced.                                                              |
| II. Performance First (60fps)               | ✅ PASS     | Schema changes don't affect rendering performance. No setState in tool handlers. Deep merge operates on config objects, not render loop.                 |
| III. Architectural Integrity (Pure Flutter) | ✅ PASS     | No external packages for core. Schema uses standard Dart patterns (UUID via `uuid` package which is already a dependency).                               |
| IV. Requirements Compliance                 | ✅ PASS     | Full spec exists in `spec.md` + `schema_spec.md`. 32 functional requirements tracked.                                                                    |
| V. API Consistency & Stability              | ⚠️ BREAKING | V2 is intentionally breaking. No backward compatibility per design decision. Will require major version bump.                                            |
| VI. Documentation Discipline                | ✅ PASS     | Phase 7 includes documentation updates. All tool schemas include LLM-facing descriptions.                                                                |
| VII. Simplicity & Pragmatism (KISS)         | ✅ PASS     | Nested yAxis is simpler than flat fields + references. Deep merge follows standard semantics. Validation rules are exhaustive but simple if/then checks. |
| Code Quality (SOLID/Analyzer)               | ✅ PASS     | Zero warnings required. All changed files must pass `flutter analyze`.                                                                                   |

**Constitution Compliance**: APPROVED with noted breaking change (version bump required).

## Project Structure

### Documentation (this feature)

```
specs/005-agentic-schema-v2/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)

specs/_base/005-agentic-schema-v2/
└── schema_spec.md       # Technical specification (source of truth for schema)
```

### Source Code (repository root)

```
# Flutter Package (monorepo structure)

lib/
└── src/
    └── models/
        ├── chart_annotation.dart     # MODIFY - add id field
        ├── chart_series.dart         # MODIFY - nested yAxis
        ├── y_axis_config.dart         # VERIFY - position enum
        └── ...

packages/braven_agent/
├── lib/
│   └── src/
│       ├── models/
│       │   ├── annotation_config.dart     # MODIFY - add id field
│       │   ├── series_config.dart         # MODIFY - nested yAxis
│       │   ├── chart_configuration.dart   # MODIFY - remove yAxes[]
│       │   └── y_axis_config.dart         # VERIFY - position field
│       ├── renderer/
│       │   └── chart_renderer.dart        # MODIFY - remove yAxisId lookup
│       ├── tools/
│       │   ├── get_chart_tool.dart        # NEW
│       │   ├── create_chart_tool.dart     # MODIFY - schema v2
│       │   └── modify_chart_tool.dart     # MAJOR REWRITE
│       └── validation/
│           └── schema_validator.dart      # NEW
└── test/
    ├── tools/
    │   ├── get_chart_tool_test.dart       # NEW
    │   ├── create_chart_tool_test.dart    # MODIFY
    │   └── modify_chart_tool_test.dart    # MODIFY
    └── validation/
        └── schema_validator_test.dart     # NEW

test/
├── unit/
│   ├── models/
│   │   ├── annotation_config_test.dart    # MODIFY - id field tests
│   │   ├── series_config_test.dart        # MODIFY - nested yAxis tests
│   │   └── chart_configuration_test.dart  # MODIFY - remove yAxes[] tests
│   └── rendering/
│       └── y_axis_resolution_test.dart    # MODIFY - new resolution logic
└── integration/
    └── agentic_flow_test.dart             # NEW - full lifecycle test
```

**Structure Decision**: Monorepo with `braven_agent` as sub-package under `packages/`. Changes span both the core `lib/` models and the `packages/braven_agent/` tool implementation. Test files mirror source structure.

## Complexity Tracking

_Violations requiring justification:_

| Violation                                | Why Needed                                                                                                                               | Simpler Alternative Rejected Because                                                                                                                      |
| ---------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Breaking API change (no backward compat) | V1 schema has fundamental design flaws: flat y-axis fields, yAxisId references, no annotation IDs. Shim layer would propagate confusion. | Backward compat layer rejected: adds maintenance burden, confuses LLM with dual patterns, doesn't fix the core problem. Clean break is simpler long-term. |
| 44 validation rules (V001-V044)          | Schema complexity requires strict validation. LLM tool calls are error-prone. Early validation prevents confusing runtime errors.        | Lazy validation rejected: errors during rendering are harder to debug than upfront schema errors. Full validation is investment in developer experience.  |

## Implementation Phases

_Reference: schema_spec.md "Implementation Tasks" section for detailed file-level breakdown._

| Phase | Description               | Key Deliverables                                                      |
| ----- | ------------------------- | --------------------------------------------------------------------- |
| 1     | Model Updates             | Annotation id field, nested yAxis in series, remove yAxes[]           |
| 2     | BravenChartPlus Rendering | Y-axis resolution from series[].yAxis, annotation rendering           |
| 3     | Braven Agent Tools        | get_chart_tool (NEW), create_chart_tool v2, modify_chart_tool rewrite |
| 4     | Braven Agent Renderer     | Remove yAxisId lookup, update config parsing                          |
| 5     | Validation Module         | schema_validator.dart with V001-V044 rules                            |
| 6     | Test Updates              | Model tests, tool tests, validation tests, integration tests          |
| 7     | Documentation             | API docs, example updates                                             |
| 8     | Cleanup                   | Remove deprecated code, final audit                                   |

## Open Questions

_None - all questions resolved in schema_spec.md "Resolved Decisions" section._

## Next Steps

1. Create `research.md` (Phase 0 - no NEEDS CLARIFICATION items)
2. Create `data-model.md` (Phase 1 - entity definitions)
3. Create `contracts/` (Phase 1 - tool schemas)
4. Create `quickstart.md` (Phase 1 - getting started guide)
5. Run `update-agent-context.ps1` to sync agent context
6. Execute `/speckit.tasks` to generate tasks.md (Phase 2)
