# ORCHESTRATOR PRE-FLIGHT CHECKLIST - Task 13

Completed: 2025-11-30

- [x] I have READ `.orchestra/readme.md` (not from memory!)
- [x] I have READ `.orchestra/manifest.yaml` for this task's details
- [x] I have READ the SpecKit `tasks.md` for detailed requirements
- [x] I have VERIFIED manifest.yaml has `category:` field for this task (integration)
- [x] I have identified task type: [x] Integration
- [x] If VISUAL/INTEGRATION: I have included Section 7 (flutter_agent.py workflow)
- [x] If INTEGRATION: I have listed files that MUST be modified (chart_render_box.dart, crosshair_tracker.dart)
- [x] I have CREATED `.orchestra/verification/task-013.yaml` with hidden criteria
- [x] I have filled ALL sections below (content or [N/A] with reason)
- [x] No [TODO] markers remain in this document

## Task Details

- **Title**: Update Crosshair to Use Per-Axis Bounds
- **Category**: INTEGRATION (requires screenshot)
- **SpecKit Tasks**: T043, T044, T041

## Key Technical Insight

The current crosshair code at `chart_render_box.dart:4342` uses:
```dart
final screenY = CrosshairTracker.dataToScreenY(
  dataY: value.y,
  chartBounds: _plotArea,
  yMin: yMin,   // <-- Global bounds from _transform
  yMax: yMax,
);
```

This is WRONG for multi-axis because different series have different Y ranges.
The fix must:
1. Resolve which axis the series belongs to
2. Get the per-axis bounds (not global bounds)
3. Use axis-specific bounds for Y conversion

## Files to Modify

1. `lib/src/rendering/chart_render_box.dart` - Crosshair rendering (lines ~4340-4380)
2. `lib/src/interaction/core/crosshair_tracker.dart` - May need per-axis Y conversion method

## Verification Created

- Created: `.orchestra/verification/task-013.yaml`
- BLOCKING: Per-axis bounds used (not global yMin/yMax)
- BLOCKING: Widget tests exist and pass
- MAJOR: Uses SeriesAxisResolver or equivalent
- MAJOR: Demo file created
- Visual verification REQUIRED
