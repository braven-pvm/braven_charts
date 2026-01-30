# Technical Debt: US7 Workout Comparison Feature Blocked

**Created**: 2026-01-28  
**Status**: BLOCKED  
**Priority**: P3 (tied to US7 priority)  
**Blocking Tasks**: T079, T080, T081, T082, T083

## Problem Statement

User Story 7 (Workout Comparison) cannot be implemented because the underlying file import and context handling infrastructure is not functional.

## Functional Requirement

**FR-010**: System MUST support comparing up to 5 workouts with overlay and metrics table.

## User Story 7 Goals

- Compare multiple workouts side-by-side or overlaid to track progress over time
- Upload 2-5 FIT/CSV files → prompt "Compare these rides" → get overlay chart + metrics table
- Each workout has distinct colors for visual differentiation
- Metrics table shows NP, TSS, IF, duration, avg power for each workout

## Blocked Tasks

| Task | Description                                           | Status  |
| ---- | ----------------------------------------------------- | ------- |
| T079 | Integration test for multi-workout comparison         | BLOCKED |
| T080 | Add multi-file handling to data store (up to 5 files) | BLOCKED |
| T081 | Implement comparison overlay logic in CreateChartTool | BLOCKED |
| T082 | Create comparison metrics table widget                | BLOCKED |
| T083 | Add distinct colors/styles for overlaid workouts      | BLOCKED |

## Root Cause: Missing Infrastructure

This feature depends on the FIT file data pipeline (see `fit_file_data_pipeline.md`), which is currently not functional:

1. **File Upload to Agent Context**: No mechanism to pass uploaded file contents to LLM agent
2. **Multi-File Handling**: DataStore cannot manage multiple workout files simultaneously
3. **FIT File Parsing**: No integration with FIT file parser in agent workflow
4. **Data Alignment**: No time-series alignment logic for workouts of different durations

## Dependencies

- `fit_file_data_pipeline.md` - Core file import infrastructure
- Working DataStore with multi-file support
- Time-series alignment utilities
- Chart renderer support for multiple series with distinct styling

## Impact

**User Story 7 is completely blocked**. Cannot write meaningful tests or implementations without:

- File upload → agent context pipeline
- Multi-workout data storage
- Time alignment logic

## Resolution Path

1. ✅ Complete `fit_file_data_pipeline.md` technical debt item first
2. ✅ Implement multi-file DataStore support
3. ✅ Create time-series alignment utilities
4. Then return to US7 tasks in order (T079 → T080 → T081 → T082 → T083)

## Acceptance Criteria for Resolution

- [ ] File upload pipeline functional (per `fit_file_data_pipeline.md`)
- [ ] DataStore can store and retrieve up to 5 workout files
- [ ] Time-series data can be aligned on common time axis
- [ ] Chart renderer supports multiple series with distinct colors
- [ ] All 5 tasks (T079-T083) can be completed

## Notes

- Priority remains P3 (same as US7)
- This is a **foundational infrastructure gap**, not a minor bug
- Attempting to implement without infrastructure would produce non-functional stubs
- Better to acknowledge the blocker and defer than create technical debt in implementation

---

**Decision**: Skip all US7 tasks until infrastructure is ready. Move to next feasible user story.
