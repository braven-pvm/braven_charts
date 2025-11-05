# Interaction Conflict Resolution Table

**Document Purpose**: Define explicit behavior for all possible interaction conflicts  
**Status**: 🔴 **BLOCKED** - Requires team decisions before prototype implementation  
**Priority**: **CRITICAL** - Cannot proceed with Phase 0 prototype without these decisions

---

## Instructions

For each conflict scenario below:
1. **Review the scenario description**
2. **Decide which element should "win"** (receive the interaction)
3. **Define the exact behavior** (what happens to both elements)
4. **Specify any special conditions** (distance thresholds, modifier keys, etc.)

Mark decisions with ✅ when complete.

---

## Priority Levels Reference

Use these priority levels for conflict resolution:

1. **CRITICAL** (10): Modal overlays, context menus (blocks everything)
2. **HIGH** (7-9): Resize handles, dragging operations in progress
3. **MEDIUM** (4-6): Selection, datapoints, annotations
4. **LOW** (1-3): Background pan/zoom, series highlight
5. **PASSIVE** (0): Crosshair, hover effects (never claims interactions)

---

## Conflict Scenarios

### 1. Annotation Resize Handle Under Datapoint

## Mouse Event Responsibilities (Decided)

These mappings reflect the team's decisions about which mouse events affect which components. They are authoritative for conflict resolution logic.

- Middle-click (click-and-hold): EXCLUSIVELY used for panning. No other element may claim middle-button drag events.
- Right-click: EXCLUSIVELY used for context menus. Behavior:
  - Right-click on empty chart area -> open "Add Annotation / Chart Actions" menu.
  - Right-click on an annotation -> open annotation-specific menu (Edit / Delete / Properties).
  - Context menu is modal and blocks other interactions until closed.
- Mouse hover:
  - Series line: hover highlights the series and shows clickable affordance (cursor change). Hover does NOT claim drag gestures.
  - Datapoint marker: hover shows tooltip and hover visual; tooltip is passive and does not block clicks.
  - Annotations:
    - Text annotation: hover shows a translucent text box and tooltip (passive)
    - Range annotation: hover over body shows highlight; hover over edges shows resize affordance (cursor change)
    - Point annotation: same location as datapoint markers; resolution rules below determine winner
    - Trend annotation: hover shows full annotation and should be selectable via left-click
- Left-click behaviors (summary):
  - Left-click on datapoint: select, and left-drag (if initiated on datapoint within radius) = datapoint drag
  - Left-click on series (not on datapoint): select series (no drag). Series drag requires modifier (Alt) if supported.
  - Left-click on annotation: generally does NOT claim selection except for Trend annotations; annotation edits and moves occur via drag handles or explicit edit mode (double-click).
  - Left-click + drag (box-select): ONLY selects datapoints. Box selection is constrained to datapoints of the series(es) intersecting the box; annotations are NOT selected by box-select.

These rules supersede default GestureDetector ordering; implement them in the coordinator and recognizers.



## Conflict Scenarios

### 1. Annotation Resize Handle Under Datapoint

**Scenario**: User clicks on an annotation resize handle, but there's a datapoint at the same location.

**Elements**:
- **Element A**: Annotation resize handle (8px × 8px hit target)
- **Element B**: Datapoint (typically 16px × 16px hit target)

**Decision (applied)**:
- **Winner**: Resize handle
- **Behavior**: Clicks/taps inside the resize handle region always route to the annotation resize handle. Datapoint hit-testing ignores pointer events that fall inside an active annotation handle geometry.
- **Conditions**: Only the visible handle region takes priority. If the handle is not visible (hidden by style/state), normal datapoint hit rules apply.
- **Priority**: Resize handle = 9, Datapoint = 6

**Rationale**: Handles are small and denote precise edit intent; logical for edit affordances to win over general datapoint selection.

----

### 2. Datapoint on Series Line

**Scenario**: User clicks on a location where a datapoint sits on its series line.

**Decision (applied)**:
- **Winner**: Datapoint
- **Behavior**: Datapoint claims the click if the pointer is within the datapoint marker radius. Clicks outside that radius but on the path hit the series line.
- **Priority**: Datapoint = 6, Series = 4

**Rationale**: Datapoint is more specific; users expect point-level interactions to be favored.

----

### 3. Annotation Body Over Datapoint

**Scenario**: User clicks where an annotation box/area overlaps a datapoint underneath.

**Decision (applied)**:
- **Winner**: Annotation for Trend annotations; otherwise Datapoint
- **Behavior**: If the annotation is a Trend-type or explicitly marked selectable, the annotation wins clicks in its body region. For general text/range annotations that are not intended to occlude datapoint selection, datapoints win.
- **Priority**: Annotation (trend/selectable)=7, Datapoint=6

**Rationale**: Trend annotations often represent an independent interactive object. For non-interactive or passive annotations, datapoint interaction is preferred to avoid blocking data exploration.

----

### 4. Multiple Overlapping Datapoints

**Scenario**: Several datapoints are very close together (dense data region). User clicks in the cluster.

**Decision (applied)**:
- **Winner**: Closest datapoint by Euclidean distance to pointer
- **Behavior**: Compute euclidean distance to centers of candidate points. Select the nearest. If multiple points lie within a small epsilon (3px) of the same distance, open a small picker UI with the nearby candidates.
- **Multi-select**: Ctrl+Click toggles selection on the nearest point; Shift/drag selection follows box rules.

**Rationale**: Deterministic nearest-point selection is intuitive; the picker handles ambiguous clicks gracefully.

----

### 5. Box Selection Drag vs Datapoint Click

**Scenario**: User clicks on a datapoint, but starts dragging slightly. Is this a datapoint drag or box selection start?

**Decision (applied)**:
- **Winner**: Datapoint drag if the drag is initiated within datapoint radius; otherwise Box selection
- **Threshold**: If initial pointer-down is within datapoint radius (10px), treat initial gesture as datapoint drag even if dragged. If initial down is on empty area and user drags >5px, treat as box selection.
- **Behavior**: Box-selection selects only datapoints inside the box and does NOT select annotations.

**Rationale**: Matches user expectation—clicking points edits/moves points; box-select is for bulk datapoint selection only.

----

### 6. Pan Gesture vs Series Click

**Scenario**: User clicks on a series line, then starts dragging. Is this a pan (chart navigation) or series selection?

**Decision (applied)**:
- **Winner**: Middle-click drag = Pan (exclusive). Left-click = Series select only (no drag). If series drag is needed, require explicit modifier (e.g., Alt + left-drag).
- **Behavior**: Implement separate recognizers: middle-button drag routes to pan; left-button click selects series (no drag unless with modifier).

**Rationale**: This removes ambiguity and relies on mouse-button semantics.

----

### 7. Crosshair Active vs Any Click

**Scenario**: Crosshair is following mouse. User clicks to select a datapoint. Should crosshair stay, hide, or move?

**Decision (applied)**:
- **Behavior**: Crosshair is PASSIVE. It stays visible during clicks and does not block or claim events. If snapping to a datapoint is enabled and a click/select occurs, the crosshair may snap to the selected datapoint.

**Rationale**: Crosshair is display-only; it must not interfere with interactions.

----

### 8. Context Menu Open

**Scenario**: User has right-clicked and context menu is visible. User performs another action.

**Decision (applied)**:
- **Behavior**: Context menu is modal and blocks chart interactions while open.
- **Context menu specifics**:
  - Right-click on empty chart -> show Add Annotation / Chart Actions menu.
  - Right-click on annotation -> show annotation-specific menu (Edit / Delete / Properties).
  - After choosing "Add" from empty-area menu, the add flow begins; after right-click on annotation, menu shows Edit/Delete (per user rule).
- **Close triggers**: Click outside, select item, Escape key.

**Rationale**: Matches the user's explicit mapping and standard OS behavior.

----

### 9. Ctrl+Click Toggle vs Normal Click

**Scenario**: User Ctrl+Clicks on datapoints to toggle multi-selection.

**Decision (applied)**:
- **Behavior**: Ctrl+Click toggles selection state of the nearest datapoint. No conflicts—modifier-based actions win deterministically.

----

### 10. Annotation Drag vs Resize vs Chart Pan

**Scenario**: User initiates pointer down on an annotation; move occurs. Is this annotation drag/resize or chart pan?

**Decision (applied)**:
- **Behavior**: If pointer-down is on an annotation resize handle -> resize. If pointer-down on annotation body and drag begins on handle or in edit mode -> annotation drag. Otherwise, middle-button drag -> pan. Left-button drag outside annotation -> box select or nothing depending on threshold.

----

### 11. Click to edit annotation (single vs double click)

**Decision (applied)**:
- **Behavior**: Double-click on annotation body enters edit mode. Single-click selects only if annotation is Trend or explicitly selectable. Otherwise single-click passes through per rules above.

----

### 12. Simultaneous Pan + Hover Tooltips

**Scenario**: User pans with middle-button while hover tooltips try to show.

**Decision (applied)**:
- **Behavior**: While panning (middle-button down), hover/tooltips are suspended. Tooltip providers must check the ChartInteractionCoordinator for active pan state and defer updates.

----

### 13. Datapoint Drag vs Series Reflow

**Decision (applied)**:
- **Behavior**: Dragging a datapoint (left-drag started on datapoint) modifies the datapoint. Series-level reflow operations require explicit edit mode or modifier. Datapoint drag wins over series-level gestures.

----

### 14. Box Select Overlapping Annotations

**Decision (applied)**:
- **Behavior**: Box select ignores annotations entirely and only adds datapoints (from any visible series) inside the box. Per user's instruction, box-select may be limited to datapoints of selected series if the UI has a "restrict to selected series" option; default: all series.

----

### 15. Long-press vs Click

**Decision (applied)**:
- **Behavior**: Long-press (touch/press-and-hold) enters context-sensitive mode (e.g., show touch context menu). For mouse, long-press is not used; right-click is explicit.

----

## Decision Summary Table

| Scenario | Winner | Key Behaviors | Priority (winner / loser) | Notes |
|---|---:|---|---:|---|
| 1. Resize handle vs datapoint | Resize handle | Handle always wins; datapoint ignores events in handle region | 9 / 6 | Small handle higher specificity |
| 2. Datapoint vs series line | Datapoint | Point hit radius wins; series path otherwise | 6 / 4 | |
| 3. Annotation body vs datapoint | Annotation (trend) / Datapoint otherwise | Trend annotations claim clicks; otherwise point wins | 7 / 6 | |
| 4. Overlapping datapoints | Nearest point (picker if ambiguous) | Euclidean nearest; picker if within 3px tie | 6 / 6 | Ctrl toggles |
| 5. Box-select vs datapoint drag | Datapoint drag (if started on point) / Box-select otherwise | Start-on-point radius=10px -> drag; empty area drag=box-select (>5px) | 6 / 5 | Box-select excludes annotations |
| 6. Pan vs series click | Pan = middle-button; Left-click select | Middle-button drag -> pan; left-click selects only | 3 / 4 | Clear button separation |
| 7. Crosshair | Passive | Never blocks events; may snap on select | 0 / - | Display-only |
| 8. Context menu | Context menu (modal) | Right-click empty=Add; right-click annotation=Edit/Delete | modal / blocked | Follows user rule |
| 9. Ctrl+Click multi-select | Ctrl+Click toggles nearest datapoint | Modifier-based toggle | - | Deterministic |
| 10. Annotation drag/resize vs pan | Annotation drag/resize (based on region) | Resize handle -> resize; body->drag in edit mode; mid-button pan unaffected | 8 / 3 | |
| 11. Annotation edit (dblclick) | Double-click -> edit | Single-click selects only if trend/selectable | - | |
| 12. Pan + hover | Pan suspends hover/tooltips | Tooltips suppressed during pan | - | Coordinator enforces |
| 13. Datapoint drag vs series reflow | Datapoint drag | Point-edit wins; series reflow requires explicit mode | 7 / 4 | |
| 14. Box-select over annotations | Box-select ignores annotations | Only datapoints are selected; annotations untouched | - | May be toggled to restrict to selected series |
| 15. Long-press vs click | Long-press = touch context mode | Mouse uses right-click; long-press for touch only | - | |

----

## Implementation notes

- Enforce these rules in the ChartInteractionCoordinator: route pointer events by button, by hit-target geometry and by explicit element types before falling back to nearest-object heuristics.
- Implement spatial index (quadtree) to efficiently find nearest candidate objects at pointer location.
- Tooltip and hover providers must check coordinator state (e.g., isPanning) and defer updates appropriately.
- Context menu actions for annotations must include Edit / Delete when right-clicking an annotation (per user rule).

---

### 9. Ctrl+Click (Multi-Select) vs Normal Click

**Scenario**: User clicks with Ctrl held. Should this add to selection or perform different action?

**Elements**:
- **Element A**: Multi-select mode (Ctrl modifier)
- **Element B**: Single selection mode (no modifier)

**Current Behavior**: ❌ Not implemented

**Decision Required**:
- [ ] **Behavior**:
  - [ ] Ctrl+Click = Add/remove from selection (toggle)
  - [ ] Ctrl+Click = Add only (no toggle)
  - [ ] Ctrl+Click = Different action: _______________
- [ ] **Multi-Select Limit**: Maximum selected elements = ⬜ Unlimited  ⬜ Limit: ___
- [ ] **Visual Feedback**: How are multiple selected elements shown? _______________
- [ ] **Deselect**: Click empty space to ⬜ Clear all  ⬜ Keep selection  ⬜ Other: ___

**Recommendation**: Ctrl+Click toggles selection (add if not selected, remove if selected). No limit. Click empty space clears all.

---

### 10. Resize Drag Leaves Element Bounds

**Scenario**: User is dragging an annotation resize handle, but mouse cursor leaves the annotation area (or screen).

**Elements**:
- **Element A**: Resize operation in progress
- **Element B**: Mouse exit event / pointer leaves bounds

**Current Behavior**: ❌ Not implemented

**Decision Required**:
- [ ] **Behavior**: If mouse leaves during resize:
  - [ ] Continue resize (track mouse outside bounds)
  - [ ] Cancel resize (restore original size)
  - [ ] Pause resize (resume when mouse returns)
  - [ ] Other: ___________________________________________
- [ ] **Mouse Release Outside**: If user releases mouse button outside chart:
  - [ ] Apply resize
  - [ ] Cancel resize
  - [ ] Other: ___________________________________________

**Recommendation**: Continue tracking mouse outside bounds (standard desktop behavior). Apply resize on mouse up regardless of position.

---

### 11. Annotation Edit Mode Active

**Scenario**: User double-clicks annotation to enter edit mode (editing text). User clicks elsewhere.

**Elements**:
- **Element A**: Annotation in edit mode
- **Element B**: Any other clickable element

**Current Behavior**: ❌ Not implemented

**Decision Required**:
- [ ] **Behavior**: Click outside annotation while editing:
  - [ ] Commit changes, exit edit mode, perform clicked action
  - [ ] Commit changes, exit edit mode, ignore clicked action
  - [ ] Discard changes, exit edit mode
  - [ ] Stay in edit mode (ignore click)
  - [ ] Show confirmation dialog
- [ ] **Priority**: Annotation in edit mode = ___ (should be HIGH - blocks most interactions)

**Recommendation**: Commit changes, exit edit mode, then perform clicked action. Priority=9 (blocks background pan/zoom but allows selecting other elements to switch context).

---

### 12. Simultaneous Pan and Zoom (Wheel During Drag)

**Scenario**: User is panning the chart (middle-mouse drag), then scrolls mouse wheel without releasing.

**Elements**:
- **Element A**: Pan operation in progress
- **Element B**: Zoom operation (mouse wheel)

**Current Behavior**: ✅ Partial - Pan and zoom implemented separately

**Decision Required**:
- [ ] **Behavior**: Mouse wheel during active pan:
  - [ ] Allow zoom (simultaneous pan + zoom)
  - [ ] Ignore wheel (finish pan first)
  - [ ] Cancel pan, start zoom
  - [ ] Other: ___________________________________________

**Recommendation**: Allow simultaneous pan + zoom (standard behavior in design tools). Pan continues, zoom applies to current view center or mouse position.

---

### 13. Datapoint Drag vs Series Drag

**Scenario**: If we allow dragging individual datapoints AND entire series, which takes priority?

**Elements**:
- **Element A**: Individual datapoint drag (move one point)
- **Element B**: Series drag (move entire line)

**Current Behavior**: ❌ Neither implemented

**Decision Required**:
- [ ] **Behavior**:
  - [ ] Click datapoint = Drag individual point only
  - [ ] Click series line (not on point) = Drag entire series
  - [ ] Modifier key to switch: ___ + click = Drag series
  - [ ] Never allow series drag (only datapoints)
  - [ ] Other: ___________________________________________
- [ ] **Priority**: Datapoint drag = ___, Series drag = ___

**Recommendation**: Click datapoint = Drag point (priority=7). Click series line between points = Select series (priority=4). Alt+Drag series = Move entire series (priority=5).

---

### 14. Box Selection Over Annotations

**Scenario**: User drags box selection rectangle. Should it select annotations inside the box, or only datapoints?

**Elements**:
- **Element A**: Box selection area
- **Element B**: Annotations inside box
- **Element C**: Datapoints inside box

**Current Behavior**: ❌ Not implemented

**Decision Required**:
- [ ] **What Gets Selected**:
  - [ ] Only datapoints
  - [ ] Only annotations
  - [ ] Both datapoints and annotations
  - [ ] Configurable (user preference)
- [ ] **Selection Criteria**:
  - [ ] Element fully inside box
  - [ ] Element partially overlaps box
  - [ ] Element center inside box

**Recommendation**: Box select captures both datapoints AND annotations. Selection criteria: Element center inside box OR element boundary intersects box (configurable per use case).

---

### 15. Long Press vs Click-and-Hold (for Drag)

**Scenario**: User presses and holds mouse button on an element. Is this starting a drag, or waiting for long press context menu?

**Elements**:
- **Element A**: Drag operation (click and hold, then move)
- **Element B**: Long press gesture (hold without moving)

**Current Behavior**: ❌ Not implemented

**Decision Required**:
- [ ] **Behavior**:
  - [ ] Movement detection: Move >___px = Drag, Stay still ___ms = Long press
  - [ ] Time threshold: Hold >___ms without moving = Long press, Move before = Drag
  - [ ] Separate triggers: Long press on ⬜ Right-click  ⬜ Hold ___ms  ⬜ Never
- [ ] **Long Press Action**: ___________________________________________

**Recommendation**: 
- Move >5px within first 200ms = Drag wins
- Hold still >500ms = Long press (show context menu)
- No long press needed if right-click provides context menu

---

## Decision Summary Table

| # | Scenario | Winner | Priority A | Priority B | Special Conditions |
|---|----------|--------|------------|------------|-------------------|
| 1 | Resize handle vs Datapoint | ❓ | ___ | ___ | ___ |
| 2 | Datapoint vs Series line | ❓ | ___ | ___ | ___ |
| 3 | Annotation vs Datapoint | ❓ | ___ | ___ | ___ |
| 4 | Multiple overlapping points | ❓ | ___ | ___ | ___ |
| 5 | Datapoint drag vs Box select | ❓ | ___ | ___ | ___ |
| 6 | Pan vs Series click | ❓ | ___ | ___ | ___ |
| 7 | Crosshair vs Click | ❓ | ___ | ___ | ___ |
| 8 | Context menu (blocks all) | ✅ Context menu | 10 | N/A | Modal blocking |
| 9 | Ctrl+Click multi-select | ❓ | ___ | ___ | ___ |
| 10 | Resize drag leaves bounds | ❓ | ___ | ___ | ___ |
| 11 | Edit mode vs Click elsewhere | ❓ | ___ | ___ | ___ |
| 12 | Pan + Wheel zoom | ❓ | ___ | ___ | ___ |
| 13 | Point drag vs Series drag | ❓ | ___ | ___ | ___ |
| 14 | Box select scope | ❓ | ___ | ___ | ___ |
| 15 | Drag vs Long press | ❓ | ___ | ___ | ___ |

---

## Sign-Off

Once all decisions are made, sign off here:

- [ ] **Product Owner**: _______________ Date: ___________
- [ ] **Lead Developer**: _______________ Date: ___________
- [ ] **UX Designer**: _______________ Date: ___________

---

## Next Steps After Completion

1. ✅ Update `INTERACTION_ARCHITECTURE_DESIGN.md` with final priority hierarchy
2. ✅ Update `InteractionMode` enum with all required modes
3. ✅ Implement conflict resolution logic in `ChartInteractionCoordinator`
4. ✅ Create test cases for each conflict scenario
5. ✅ Begin Phase 0 prototype implementation

**BLOCKER**: Phase 0 prototype cannot proceed without these decisions.

---

**Document Status**: 🔴 INCOMPLETE - 13 of 15 scenarios need decisions  
**Last Updated**: 2025-11-05  
**Next Review**: Schedule conflict resolution meeting ASAP
