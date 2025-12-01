# Orchestrator Pre-Flight Checklist: Task 15

**Task**: Expose Multi-Axis API on BravenChartPlus  
**Date**: 2025-11-30  
**Orchestrator**: Agent (Orchestrator Mode)

## Pre-Flight Verification

- [x] I have READ `.orchestra/readme.md` (not from memory!)
- [x] I have READ `.orchestra/manifest.yaml` for this task's details
- [x] I have READ the SpecKit `tasks.md` for detailed requirements
- [x] I have VERIFIED manifest.yaml has `category: integration` for this task
- [x] I have identified task type: [ ] Logic [ ] Visual/Rendering [x] Integration
- [x] If VISUAL/INTEGRATION: I have included Section 7 (flutter_agent.py workflow)
- [x] If INTEGRATION: I have listed files that MUST be modified (not just created)
- [x] I have CREATED `.orchestra/verification/task-015.yaml` with hidden criteria
- [x] I have filled ALL sections below (content or [N/A] with reason)
- [x] No [TODO] markers remain in this document
- [x] I have saved this checklist to `.orchestra/verification/orchestrator-preflight-015.md`

## Task Summary

| Field | Value |
|-------|-------|
| Task ID | 15 |
| Title | Expose Multi-Axis API on BravenChartPlus |
| Phase | Integration |
| Category | INTEGRATION |
| SpecKit Tasks | T006, T047, T048, T049 |
| Screenshot Required | Yes |
| Test Baseline | 270 tests |

## Key Deliverables

1. **ChartSeries Model Updates**
   - Add `yAxisId` field (optional String?) to base class
   - Add `unit` field (optional String?) to base class
   - Update all subclasses: LineChartSeries, AreaChartSeries, BarChartSeries, ScatterChartSeries
   - Update copyWith, equality, hashCode, toString

2. **BravenChartPlus Validation**
   - Max 4 axes assertion
   - Unique axis positions assertion

3. **Tests**
   - Unit tests for new ChartSeries fields
   - Widget tests for validation errors

4. **Demo**
   - example/lib/demos/task_015_api_demo.dart showing yAxisId usage

## Verification Criteria Created

File: `.orchestra/verification/task-015.yaml`

| Severity | Count | Focus |
|----------|-------|-------|
| BLOCKING | 8 | yAxisId/unit fields, validation, tests |
| MAJOR | 3 | API docs, copyWith, demo |
| MINOR | 2 | hashCode/==, toString |

## Notes

- This is an INTEGRATION task - modifies public API
- The yAxisId field provides simpler alternative to SeriesAxisBinding
- When yAxisId is set on series, it should work with existing SeriesAxisResolver
