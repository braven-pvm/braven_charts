# Implementation Plan: Agentic Charts

**Branch**: `003-agentic-charts` | **Date**: 2026-01-25 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/003-agentic-charts/spec.md`

## Summary

Enable AI agents (LLMs) to have **full programmatic control** over BravenChartPlus chart creation, configuration, and data processing via natural language. Users describe data visualizations in plain language, attach workout files (FIT, CSV), and receive fully interactive, professionally styled charts. Primary use case: sport science laboratory workflows.

**Technical Approach**:

- Flutter web-first chat interface with pluggable LLM providers (Anthropic, OpenAI, Gemini)
- Tool-based agent architecture with typed schemas for chart creation, data loading, and metric calculation
- Integration with existing `braven_data` package for FIT/CSV parsing
- BravenChartPlus widget library for chart rendering with full property control

## Technical Context

**Language/Version**: Dart 3.10+, Flutter SDK 3.38.6  
**Primary Dependencies**: `anthropic_sdk_dart`, `braven_data`, `braven_charts`, `http`, `uuid`  
**Storage**: Session-local only (no persistence in V1)  
**Testing**: `flutter test` (unit, widget, integration), golden tests for UI  
**Target Platform**: Flutter Web (primary), iOS/Android (secondary)  
**Project Type**: Flutter library + example app  
**Performance Goals**: 60 FPS chart rendering, <30s first chart from prompt, <2s chart render  
**Constraints**: 50 MB max file size, 4 max Y-axes, 5 max workout comparison, 20 undo steps  
**Scale/Scope**: Single-user sessions, sport science workflows, ~10 core LLM tools

## Constitution Check

_GATE: Must pass before Phase 0 research. Re-check after Phase 1 design._

| Principle                                   | Status  | Notes                                                                                             |
| ------------------------------------------- | ------- | ------------------------------------------------------------------------------------------------- |
| I. Test-First Development                   | ✅ PASS | Tests required for all LLM tools, UI components, data transformations                             |
| II. Performance First (60fps)               | ✅ PASS | Chart rendering uses existing optimized BravenChartPlus; ValueNotifier for high-frequency updates |
| III. Architectural Integrity (Pure Flutter) | ✅ PASS | No HTML/web-specific APIs; pure Flutter widgets                                                   |
| IV. Requirements Compliance                 | ✅ PASS | All requirements traced to spec; tasks.md will track deviations                                   |
| V. API Consistency & Stability              | ✅ PASS | LLM tool schemas follow TypeScript interface patterns; stable contract                            |
| VI. Documentation Discipline                | ✅ PASS | All public APIs documented; tool schemas include descriptions                                     |
| VII. Simplicity & Pragmatism (KISS)         | ✅ PASS | Sequential tool execution for V1; parallel deferred                                               |

**Constitution Violations**: None

## Project Structure

### Documentation (this feature)

```
specs/003-agentic-charts/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (LLM tool schemas)
│   └── llm-tools.yaml   # OpenAPI-style tool definitions
├── checklists/          # Validation checklists
│   └── requirements.md
└── tasks.md             # Phase 2 output (NOT created by /speckit.plan)
```

### Source Code (repository root)

```
lib/src/
├── agentic/                     # NEW: Agentic charts module
│   ├── models/                  # Data models
│   │   ├── chart_config.dart    # Chart configuration model
│   │   ├── data_source.dart     # Data source abstraction
│   │   ├── tool_result.dart     # LLM tool execution result
│   │   └── conversation.dart    # Chat conversation model
│   ├── providers/               # LLM provider abstraction
│   │   ├── llm_provider.dart    # Abstract provider interface
│   │   ├── anthropic_provider.dart
│   │   ├── openai_provider.dart
│   │   └── gemini_provider.dart
│   ├── tools/                   # LLM tool implementations
│   │   ├── tool_registry.dart   # Tool registration and dispatch
│   │   ├── create_chart_tool.dart
│   │   ├── modify_chart_tool.dart
│   │   ├── describe_data_tool.dart
│   │   ├── load_data_tool.dart
│   │   ├── process_data_tool.dart
│   │   ├── calculate_metric_tool.dart
│   │   └── export_chart_tool.dart
│   ├── services/                # Business logic
│   │   ├── agent_service.dart   # Core agent orchestration
│   │   ├── data_store.dart      # UUID-based data reference store
│   │   ├── chart_history.dart   # Undo/redo state management
│   │   └── favorites_service.dart
│   └── widgets/                 # UI components
│       ├── chat_interface.dart  # Main chat widget
│       ├── message_bubble.dart
│       ├── chart_card.dart      # Chart with action bar
│       ├── config_panel.dart    # Quick config adjustments
│       ├── file_attachment_chip.dart
│       ├── data_preview.dart    # File column preview
│       ├── metric_card.dart     # NP, TSS display cards
│       └── inline_chat.dart     # Per-chart inline editing

example/lib/
├── demos/
│   └── agentic_chart_demo.dart  # Demo application
└── showcase/
    └── agentic_showcase.dart    # Feature showcase

test/
├── unit/
│   └── agentic/                 # Unit tests for agentic module
├── widget/
│   └── agentic/                 # Widget tests
├── integration/
│   └── agentic/                 # Integration tests
└── golden/
    └── agentic/                 # Visual regression tests
```

**Structure Decision**: Single Flutter library project with new `lib/src/agentic/` module. Follows existing BravenChartPlus patterns. Tests mirror source structure under `test/`.

## Phase 0 Output: Research

**File**: [research.md](research.md)

Research tasks completed:

- RT-1: LLM Tool Calling Patterns → Typed Dart classes
- RT-2: Multi-Provider Abstraction → LLMProvider interface
- RT-3: Data Reference System → UUID-based DataStore
- RT-4: CORS Handling → Cloudflare Worker proxy for production
- RT-5: State Management → ValueNotifier pattern (per constitution)
- RT-6: FIT File Integration → Wrap braven_data.FitLoader
- RT-7: Sport Science Formulas → TrainingPeaks standard (NP, TSS, IF)
- RT-8: Chart Serialization → json_serializable

**Status**: ✅ Complete - No NEEDS CLARIFICATION items

## Phase 1 Output: Design & Contracts

### Data Model

**File**: [data-model.md](data-model.md)

Core entities defined:

- Conversation, Message, ToolCall
- LoadedData, ColumnDescriptor
- ChartState, ChartConfiguration
- SeriesConfig, XAxisConfig, YAxisConfig
- AnnotationConfig, FileAttachment
- Metric, PromptTemplate

### API Contracts

**File**: [contracts/llm-tools.yaml](contracts/llm-tools.yaml)

LLM tools defined:
| Tool | Priority | Status |
|------|----------|--------|
| describe_data | P1 | Schema complete |
| load_data | P1 | Schema complete |
| create_chart | P1 | Schema complete |
| modify_chart | P1 | Schema complete |
| process_data | P2 | Schema complete |
| calculate_metric | P2 | Schema complete |
| add_annotation | P2 | Schema complete |
| export_chart | P3 | Schema complete |

### Quickstart Guide

**File**: [quickstart.md](quickstart.md)

Contents:

- Prerequisites and setup
- CORS configuration (dev/prod)
- Basic usage examples
- Example prompts
- Keyboard shortcuts
- Troubleshooting

### Agent Context Update

**Updated**: `.github/copilot-instructions.md`

Added technologies:

- Dart 3.10+, Flutter SDK 3.38.6
- `anthropic_sdk_dart`, `braven_data`, `braven_charts`, `http`, `uuid`
- Session-local storage (no persistence in V1)

## Constitution Re-Check (Post Phase 1)

| Principle                    | Status  | Notes                                         |
| ---------------------------- | ------- | --------------------------------------------- |
| I. Test-First Development    | ✅ PASS | Test structure defined in project layout      |
| II. Performance First        | ✅ PASS | ValueNotifier pattern for state; 60fps target |
| III. Architectural Integrity | ✅ PASS | Pure Flutter; modular structure               |
| IV. Requirements Compliance  | ✅ PASS | All FRs traceable to tools/entities           |
| V. API Consistency           | ✅ PASS | Tool schemas follow OpenAPI patterns          |
| VI. Documentation Discipline | ✅ PASS | All artifacts documented                      |
| VII. Simplicity & Pragmatism | ✅ PASS | Sequential tools for V1; no over-engineering  |

**Violations**: None

## Next Steps

Run `/speckit.tasks` to generate Phase 2 task breakdown in `tasks.md`.
