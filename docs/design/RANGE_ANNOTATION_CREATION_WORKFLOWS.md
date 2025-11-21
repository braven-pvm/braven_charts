# RangeAnnotation Creation Workflows - Design Discussion

**Date**: November 21, 2025  
**Status**: Design Phase - Not Implemented  
**Related**: Context Menu Implementation (commit fad07c7)

---

## Overview

This document captures the design discussion for RangeAnnotation creation workflows. RangeAnnotations allow users to highlight regions on the chart (e.g., time periods, value ranges, areas of interest).

**Decision**: Start with **Option 4** (Right-click empty → Menu → Interactive drag) for first implementation.

---

## Proposed Options

### Option 1: Drag Random Box (Box Selection)

**Workflow**:
1. User drags a box anywhere on chart
2. If box includes ≥1 series AND ≥2 points on at least one series
3. Show popup menu with "Add Range Annotation"

**Analysis**:
- ✅ **Pros**: Natural for defining arbitrary regions, immediate visual feedback during drag
- ⚠️ **Cons**: Conflicts with existing box-select for multi-selection (scenario 5 in interaction architecture), requires disambiguation logic
- 💡 **Refinement**: Could use modifier key (e.g., Alt+drag) to distinguish from box-select mode
- 🎯 **Best for**: Freeform region definition without constraints

---

### Option 2: Right-click Marker → Menu → Interactive Creation

**Workflow**:
1. Right-click on data point marker
2. Select "Add Range Annotation" from context menu
3. Choose creation method:
   - Drag to define end point, or
   - Specify end point in dialog, or
   - Drag edge of newly created region

**Analysis**:
- ✅ **Pros**: Discoverable via context menu, clear starting point anchored to data
- ⚠️ **Cons**: Two-step process, requires mode switch after menu selection
- 💡 **Use Case**: Best for precise range definition starting from known data point
- 🎯 **Best for**: Data-driven ranges (e.g., "from measurement A to measurement B")

---

### Option 3: Ctrl+Click Start/End Points

**Workflow**:
1. Hold Ctrl key
2. Click first data point marker (start)
3. Click second data point marker (end)
4. Release Ctrl → creation dialog appears

**Analysis**:
- ✅ **Pros**: Fast for power users, precise point-to-point definition, minimal UI
- ⚠️ **Cons**: Not discoverable, requires documentation/tooltips, hidden feature
- 💡 **Refinement**: Visual feedback showing "first point selected, click second point" with preview line
- 🎯 **Best for**: Expert users, keyboard-driven workflows, rapid annotation

---

### Option 4: Right-click Empty Area → "Add Range Annotation" → Interactive Drag ⭐

**Workflow**:
1. Right-click empty chart area
2. Select "Add Range Annotation" from context menu
3. Cursor changes to crosshair with range icon
4. Click-drag to define rectangular region (with live preview)
5. Release mouse button → properties dialog opens
6. Confirm or cancel in dialog

**Analysis**:
- ✅ **Pros**: No modifier keys needed, discoverable via menu, visual mode indication, clear entry/exit
- ✅ **Aligns with web-first design philosophy** (menu-driven, progressive disclosure)
- ⚠️ **Cons**: Three-step process (click menu → drag → dialog)
- 💡 **Implementation Notes**:
  - Enter `InteractionMode.rangeAnnotationCreation` after menu selection
  - Show rubber-band rectangle during drag
  - ESC key cancels mode
  - Right-click cancels mode
- 🎯 **Best for**: New users, discoverable workflows, tutorial-friendly

**DECISION**: **This is the recommended starting point for first implementation.**

---

### Option 5: Toolbar Button → Interactive Mode

**Workflow**:
1. Click "Range Annotation" button in toolbar
2. Chart enters "range creation mode" (cursor changes, status indicator)
3. Click-drag on chart to define region
4. Release to create with default properties OR open dialog
5. Mode stays active for multiple ranges OR automatically exits

**Analysis**:
- ✅ **Pros**: Streamlined for creating multiple ranges, clear mode indication, efficient batch operation
- ⚠️ **Cons**: Requires toolbar UI, modal mode blocks other interactions, less discoverable than context menu
- 💡 **Variants**:
  - Sticky mode (stays active until ESC/button clicked again)
  - One-shot mode (auto-exits after first range)
- 🎯 **Best for**: Power users doing annotation-heavy work (e.g., marking multiple analysis regions)

---

### Option 6: Double-Click-Drag (Gesture-based)

**Workflow**:
1. Double-click empty area (enters range creation mode instantly)
2. Without releasing, immediately drag to define region
3. Release mouse button → range created or dialog opens

**Analysis**:
- ✅ **Pros**: Single fluid gesture, fastest for power users, no menu navigation
- ⚠️ **Cons**: Not discoverable, can conflict with zoom-to-fit double-click gestures, hidden feature
- 💡 **Refinement**: Could use different gesture (e.g., triple-click, double-right-click)
- 🎯 **Best for**: Expert users with muscle memory, CAD-style interaction patterns

---

### Option 7: Right-click Series Line → "Add Range Along Series"

**Workflow**:
1. Right-click on series line (not on marker)
2. Select "Add Range Along Series" from context menu
3. Drag horizontally to define X-axis range
4. Y-bounds auto-calculated from series min/max in X-range
5. Range "hugs" the series data

**Analysis**:
- ✅ **Pros**: Automatic Y-bounds calculation, intuitive for time-series ranges, series-aware
- ⚠️ **Cons**: Limited to single-series ranges, different UX from other range types
- 💡 **Use Cases**:
  - Time periods: "Q1 2024", "Outage Period"
  - Event spans: "Testing Phase", "Peak Hours"
  - Threshold violations: "Above Limit Period"
- 🎯 **Best for**: Time-series analysis, event annotation, period marking

---

### Option 8: Snap-to-Grid Range Selection

**Workflow**:
1. Right-click data point marker → "Start Range Annotation"
2. Chart enters "range selection mode" (visual indicator, status text)
3. Hover over other markers → highlights valid end points
4. Click second marker → range defined between points
5. Properties dialog opens
6. Confirm or cancel

**Analysis**:
- ✅ **Pros**: Precise point-to-point selection, visual feedback on valid targets, no modifier keys
- ⚠️ **Cons**: Requires mode management, limited to data point boundaries, can't select arbitrary regions
- 💡 **Enhancements**:
  - Show preview range during hover
  - Display distance/point count in tooltip
  - Allow clicking same series or cross-series
- 🎯 **Best for**: Ranges that align with data points (measurement intervals, sample spans, event-to-event periods)

---

## Additional Suggestions from AI Analysis

### Option 9: Contextual Smart Ranges (AI-Enhanced)

**Workflow**:
1. Right-click anywhere on chart
2. Menu shows "Add Smart Range" with sub-options:
   - "Peak Period" (auto-detects local maxima region)
   - "Anomaly Region" (highlights outlier cluster)
   - "Custom Range" (falls back to Option 4)

**Analysis**:
- ✅ **Pros**: Leverages data analysis, reduces manual work
- ⚠️ **Cons**: Complex implementation, requires heuristics, may not match user intent
- 🎯 **Best for**: Future enhancement after basic workflows proven

---

### Option 10: Template-Based Ranges

**Workflow**:
1. Right-click → "Add Range from Template"
2. Select template: "Business Hours", "Weekend", "Monthly", "Quarterly"
3. Template defines pattern, user specifies start point
4. Range auto-calculated based on template rules

**Analysis**:
- ✅ **Pros**: Efficient for recurring patterns, standardized annotations
- ⚠️ **Cons**: Requires template system, not flexible for ad-hoc ranges
- 🎯 **Best for**: Business dashboards, scheduled reports, compliance marking

---

## Implementation Tiers (Progressive Disclosure)

### Tier 1: Most Discoverable (Start Here) ⭐

**Priority 1a**: 
- **Option 4**: Right-click empty → "Add Range Annotation" → Interactive drag
- **Why**: Most discoverable, no modifier keys, menu-driven

**Priority 1b**:
- **Option 2**: Right-click marker → "Add Range Annotation" → Choose creation method
- **Why**: Anchored to data, complementary to Option 4

### Tier 2: Power User Features (Phase 2)

**Priority 2a**:
- **Option 3**: Ctrl+Click start/end points
- **Why**: Fast keyboard-driven workflow, doesn't interfere with Tier 1

**Priority 2b**:
- **Option 8**: Click-click snap-to-datapoints mode
- **Why**: Precise point-to-point without modifier keys

### Tier 3: Advanced Features (Phase 3)

**Priority 3a**:
- **Option 7**: Series-specific range creation
- **Why**: Specialized use case, powerful for time-series

**Priority 3b**:
- **Option 1**: Alt+Drag box (with disambiguation)
- **Why**: Freeform selection, requires conflict resolution

**Priority 3c**:
- **Option 5**: Toolbar button mode
- **Why**: Batch operations, requires toolbar UI

---

## Key Design Decisions (To Be Resolved)

Before implementing any option, these questions must be answered:

### 1. Range Types Supported

**Question**: What shapes can RangeAnnotations take?

**Options**:
- ✅ **Rectangular** (X-range × Y-range) - Most flexible
- ✅ **Horizontal bands** (X-range, full Y-height) - Time periods, events
- ✅ **Vertical bands** (full X-width, Y-range) - Threshold zones, target ranges
- ⚠️ **Irregular shapes** following series contours - Complex, future enhancement

**Decision Needed**: Support all three basic shapes? Different creation flows for each?

---

### 2. Coordinate Anchor Behavior

**Question**: How do ranges respond to pan/zoom?

**Options**:
- ✅ **Data-space anchored**: Range fixed to data coordinates (zooms with chart)
  - Use case: "Sales between Jan-Mar 2024"
- ⚠️ **Plot-space anchored**: Range fixed to pixel coordinates (stays in place during zoom)
  - Use case: "Important region always visible"
- 💡 **Hybrid**: X-axis data-anchored, Y-axis plot-anchored
  - Use case: Time period with floating Y-range

**Recommendation**: Start with data-space anchored (matches other annotations).

---

### 3. Multi-Series Handling

**Question**: Can a single range span multiple series?

**Options**:
- ✅ **Cross-series ranges**: Single range covers all series in region
  - Use case: "All metrics during outage period"
- ✅ **Per-series ranges**: Range associates with specific series
  - Use case: "Temperature spike on Sensor-A"
- 💡 **Linked ranges**: Multiple ranges with shared properties
  - Use case: "Compare periods across different metrics"

**Recommendation**: Support cross-series (simpler), add per-series as option.

---

### 4. Visual Preview During Creation

**Question**: What feedback during drag operation?

**Options**:
- ✅ **Live rubber-band rectangle**: Semi-transparent box follows cursor
  - Simple, clear, immediate feedback
- ✅ **Ghost annotation preview**: Shows actual styled range during drag
  - Realistic preview, "what you see is what you get"
- ⚠️ **Just cursor change**: Minimal feedback, fast rendering
  - Not recommended - insufficient feedback

**Recommendation**: Rubber-band rectangle with series data preview (point count, X/Y ranges shown in tooltip).

---

### 5. Cancellation Mechanisms

**Question**: How can user cancel range creation?

**Options**:
- ✅ **ESC key**: Standard cancellation, works in all modes
- ✅ **Right-click**: Context menu cancellation (web-native pattern)
- ✅ **Click outside dialog**: Cancel after dialog opens
- ✅ **Release without drag**: Cancel if drag distance < threshold (e.g., 5px)

**Recommendation**: Support all four for maximum flexibility.

---

### 6. Dialog vs Direct Creation

**Question**: Always show properties dialog, or allow direct creation?

**Options**:
- **Always dialog**: Consistent, allows property customization
- **Direct creation with defaults**: Faster, dialog optional (double-click to edit)
- **User preference**: Setting to choose behavior

**Recommendation**: Always dialog initially (consistent with TextAnnotation flow), add quick-create later.

---

## Range Type Specifications

### Rectangular Range (Full 2D Region)

**Properties**:
```dart
class RangeAnnotation {
  String id;
  String label;
  String? description;
  
  // Bounds
  double xMin;
  double xMax;
  double yMin;
  double yMax;
  
  // Optional: Series association
  String? seriesId; // null = all series
  
  // Styling
  Color fillColor;
  double fillOpacity;
  Color borderColor;
  double borderWidth;
  
  // Interaction
  bool allowDragging;
  bool allowResizing;
  bool showLabel;
  
  // Metadata
  DateTime createdAt;
  String? category;
  Map<String, dynamic>? metadata;
}
```

**Use Cases**:
- Analysis regions: "High volatility period"
- Comparison zones: "Before/After intervention"
- Data quality markers: "Unreliable data region"

---

### Horizontal Band Range (Time Period)

**Properties** (subset of Rectangular):
```dart
// yMin/yMax not specified (full Y-height)
// Primarily used for time-series marking
```

**Use Cases**:
- Time periods: "Q1 2024", "Maintenance Window"
- Events: "Product Launch", "Market Crash"
- Schedules: "Business Hours", "Peak Season"

---

### Vertical Band Range (Value Range)

**Properties** (subset of Rectangular):
```dart
// xMin/xMax not specified (full X-width)
// Primarily used for threshold/target zones
```

**Use Cases**:
- Target zones: "Optimal Temperature Range"
- Threshold bands: "Warning Level", "Critical Zone"
- Specification limits: "Tolerance Band"

---

## Integration with Existing Systems

### Interaction Coordinator

**New Mode Required**:
```dart
enum InteractionMode {
  // ... existing modes
  rangeAnnotationCreation, // priority: 10 (modal)
}
```

**State Management**:
- Enter mode when "Add Range Annotation" menu selected
- Store creation start point in coordinator
- Exit mode on ESC, right-click, or creation completion

---

### Context Menu Updates

**Empty Area Menu** (Option 4):
```dart
if (isEmptyArea) {
  WebContextMenuAction(
    value: 'add_range',
    icon: Icons.width_full,
    label: 'Add Range Annotation',
  ),
}
```

**Marker Menu** (Option 2):
```dart
if (isDataPointClick) {
  WebContextMenuAction(
    value: 'add_range_from_point',
    icon: Icons.width_full,
    label: 'Add Range Annotation',
  ),
}
```

---

### RenderBox Integration

**Hit Testing**:
- RangeAnnotationElement must participate in spatial indexing
- Bounds based on transformed X/Y ranges
- Hit test considers both body and resize handles

**Rendering**:
- Paint filled rectangle with border
- Optional: Paint series data points within range with highlight
- Label positioning (corner or center)

---

## Open Questions for Future Discussion

1. **Range Stacking**: How to handle overlapping ranges? Z-order? Transparency blending?

2. **Range Grouping**: Can ranges be grouped (e.g., "All Q1 ranges")? Hierarchical organization?

3. **Range Templates**: Pre-defined styles for common use cases (success/warning/error zones)?

4. **Range Statistics**: Auto-calculate stats for data within range (min/max/avg)? Show in tooltip?

5. **Range Export**: Export range definitions to JSON/CSV? Import from external sources?

6. **Range Alerts**: Trigger notifications when data enters/exits range? Real-time monitoring?

7. **Range Animation**: Animate range creation? Highlight new ranges temporarily?

8. **Range Search**: Search/filter ranges by label, category, or metadata?

---

## Implementation Roadmap

### Phase 1: Basic Implementation (Option 4)

**Milestone 1**: Core Creation Flow
- [ ] Add "Add Range Annotation" to context menu (empty area)
- [ ] Implement `rangeAnnotationCreation` interaction mode
- [ ] Rubber-band rectangle rendering during drag
- [ ] Calculate X/Y bounds from drag start/end
- [ ] Create RangeAnnotationElement from bounds

**Milestone 2**: Properties Dialog
- [ ] Design RangeAnnotationDialog UI
- [ ] Form fields: label, description, colors, opacity
- [ ] Preview pane showing styled range
- [ ] Validation: ensure valid bounds
- [ ] Create/Cancel actions

**Milestone 3**: Rendering & Interaction
- [ ] RangeAnnotationElement paint implementation
- [ ] Resize handles (8 points: corners + edges)
- [ ] Drag-to-move entire range
- [ ] Edit dialog on double-click
- [ ] Delete via context menu

---

### Phase 2: Enhanced Workflows (Options 2, 3, 8)

**Milestone 4**: Point-to-Point Creation
- [ ] Option 2: Right-click marker menu
- [ ] Option 3: Ctrl+Click two points
- [ ] Option 8: Click-click snap mode
- [ ] Visual feedback for point selection

**Milestone 5**: Polish & Refinement
- [ ] Keyboard shortcuts documentation
- [ ] Tooltip help during creation
- [ ] Undo/redo support
- [ ] Range duplication

---

### Phase 3: Advanced Features (Options 1, 5, 7)

**Milestone 6**: Alternative Creation Methods
- [ ] Option 1: Alt+Drag box selection
- [ ] Option 5: Toolbar button mode
- [ ] Option 7: Series-specific ranges

**Milestone 7**: Advanced Capabilities
- [ ] Range templates system
- [ ] Multi-range batch operations
- [ ] Range statistics overlay
- [ ] Export/import functionality

---

## Testing Scenarios

### Creation Testing

1. **Happy Path**: Right-click → Drag → Dialog → Create
2. **Cancellation**: ESC during drag, right-click during drag
3. **Invalid Range**: Zero-width or zero-height ranges
4. **Boundary Cases**: Range extends beyond chart bounds
5. **Multi-Series**: Range spans multiple series correctly

### Interaction Testing

6. **Resize**: Drag handles to resize range
7. **Move**: Drag body to reposition range
8. **Select**: Click to select, shift-click for multi-select
9. **Edit**: Double-click opens properties dialog
10. **Delete**: Right-click → Delete confirmation

### Edge Cases

11. **Zoom/Pan**: Range maintains data-space anchoring
12. **Series Changes**: Range updates when series added/removed
13. **Overlapping**: Multiple ranges stack correctly
14. **Performance**: Many ranges render efficiently
15. **Persistence**: Ranges saved/loaded correctly

---

## References

- **Interaction Architecture**: `docs/architecture/INTERACTION_ARCHITECTURE_DESIGN.md`
- **Conflict Resolution**: Scenario 5 (box selection vs element drag)
- **Context Menu**: Commit fad07c7 (context-aware menus)
- **Related Annotations**: PointAnnotation, TrendAnnotation, TextAnnotation, ThresholdAnnotation

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-21 | 1.0 | Initial design discussion documented | AI Assistant |

---

**Next Steps**:
1. ✅ Document complete (this file)
2. ⏳ Implement TextAnnotation creation dialog (foundation)
3. ⏳ Implement Option 4 RangeAnnotation creation workflow
4. ⏳ User testing and feedback
5. ⏳ Iterate based on usage patterns
