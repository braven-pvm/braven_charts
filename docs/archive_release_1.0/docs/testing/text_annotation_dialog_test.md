# TextAnnotation Dialog Testing Guide

## Test Date: 2025-01-XX

## Feature: TextAnnotation Creation Dialog

## Status: ⏳ READY TO TEST

---

## Overview

This test validates the TextAnnotation creation dialog that was just implemented. The dialog follows the BravenChart design pattern with Material Design 3 styling and web-native UX.

---

## Prerequisites

✅ **Setup Complete:**

- [ ] Flutter app running on Chrome (`flutter run -d chrome -t lib/main.dart`)
- [ ] Example app showing charts with BravenChartPlus widgets
- [ ] Browser DevTools open (F12) for console logs

✅ **Implementation Complete:**

- [x] TextAnnotationDialog created (378 lines)
- [x] AnnotationStyleEditor created (612 lines)
- [x] Import added to braven_chart_plus.dart
- [x] Handler method `_showAddTextAnnotationDialog()` implemented
- [x] Menu action wired to handler (`_handleMenuAction()`)

---

## Test Scenarios

### Scenario 1: Basic Dialog Display

**Objective:** Verify dialog appears correctly on menu selection

**Steps:**

1. Find a BravenChartPlus chart in the example app
2. Right-click on an empty area of the chart (no data points)
3. Context menu should appear with "Add Text Annotation" option
4. Click "Add Text Annotation"

**Expected Results:**

- ✅ Dialog appears at screen center (not at click position)
- ✅ Dialog title: "Add Text Annotation"
- ✅ Dialog has rounded corners (16px radius)
- ✅ Dialog width: 400px
- ✅ Dialog has close button (X) in top right
- ✅ Form contains all sections:
  - Text field (empty, placeholder: "Enter annotation text")
  - Anchor selector (9 buttons, topLeft selected by default)
  - "Allow Dragging" checkbox (checked by default)
  - "Styling" section (collapsed by default)
  - Cancel and "Add" buttons at bottom

**Console Logs to Check:**

```
🎯 Handling menu action: add_text
```

---

### Scenario 2: Text Input Validation

**Objective:** Verify required field validation

**Steps:**

1. Open TextAnnotation dialog (right-click → Add Text Annotation)
2. Leave text field empty
3. Click "Add" button

**Expected Results:**

- ❌ Dialog should NOT close
- ✅ Validation error appears: "Please enter annotation text"
- ✅ Text field border turns red

**Steps (continued):** 4. Enter text: " " (only whitespace) 5. Click "Add" button

**Expected Results:**

- ❌ Dialog should NOT close
- ✅ Validation error still shows (whitespace trimmed)

**Steps (continued):** 6. Enter valid text: "Important Note" 7. Click "Add" button

**Expected Results:**

- ✅ Dialog closes
- ✅ Annotation appears on chart

---

### Scenario 3: Anchor Selector

**Objective:** Verify 9-position anchor selection

**Steps:**

1. Open TextAnnotation dialog
2. Enter text: "Test Anchor"
3. Observe anchor selector buttons (3x3 grid)
4. Click each button and observe visual feedback

**Expected Results:**

- ✅ 9 buttons arranged in 3x3 grid
- ✅ Labels: Top Left, Top Center, Top Right, Center Left, Center, Center Right, Bottom Left, Bottom Center, Bottom Right
- ✅ Default selection: Top Left (primary color background)
- ✅ Clicking a button changes selection (primary color, others gray)
- ✅ Only one button selected at a time

---

### Scenario 4: Collapsible Style Editor

**Objective:** Verify style editor expand/collapse

**Steps:**

1. Open TextAnnotation dialog
2. Enter text: "Styled Text"
3. Observe "Styling" section
4. Click on "Styling" header

**Expected Results:**

- ✅ Initial state: Collapsed (down chevron icon)
- ✅ After click: Expanded (up chevron icon)
- ✅ Style controls visible:
  - Text Color (12 swatches + custom button)
  - Font Size slider (8-32px, default: 14px)
  - Font Weight selector (5 options, default: Normal)
  - Background Color (12 swatches + custom button)
  - Border Color (12 swatches + custom button)
  - Border Width slider (0-8px, default: 1px)
  - Border Radius slider (0-24px, default: 4px)

---

### Scenario 5: Text Styling Controls

**Objective:** Verify text color, size, and weight controls

**Steps:**

1. Open TextAnnotation dialog
2. Enter text: "Styled Text"
3. Expand "Styling" section
4. Click red color swatch in Text Color
5. Drag Font Size slider to 24px
6. Click "Bold" in Font Weight selector

**Expected Results:**

- ✅ Red swatch shows check mark (white or black based on contrast)
- ✅ Previous selection (black) loses check mark
- ✅ Font Size label shows "Font Size (24px)"
- ✅ Slider thumb moves to 24px position
- ✅ Bold button shows primary color background
- ✅ Previous weight (Normal) returns to gray background
- ✅ Changes reflected in preview (if visible)

---

### Scenario 6: Custom Color Picker

**Objective:** Verify custom color selection dialog

**Steps:**

1. Open TextAnnotation dialog
2. Enter text: "Custom Color"
3. Expand "Styling" section
4. Click "Custom..." button in Text Color section

**Expected Results:**

- ✅ Color picker dialog appears (flex_color_picker)
- ✅ Shows color wheel, shades, opacity slider
- ✅ Shows material/color name (if applicable)
- ✅ Shows recent colors (if any previous selections)
- ✅ Has "Cancel" and "Select" buttons

**Steps (continued):** 5. Select a custom color (e.g., lime green) 6. Click "Select"

**Expected Results:**

- ✅ Color picker dialog closes
- ✅ Text color updated to selected color
- ✅ Selected color added to recent colors (max 5)

---

### Scenario 7: Background and Border Styling

**Objective:** Verify background color, border color, width, and radius

**Steps:**

1. Open TextAnnotation dialog
2. Enter text: "Styled Box"
3. Expand "Styling" section
4. Click white color swatch in Background Color
5. Click blue color swatch in Border Color
6. Drag Border Width slider to 3px
7. Drag Border Radius slider to 12px

**Expected Results:**

- ✅ Background Color shows white selected (check mark)
- ✅ Border Color shows blue selected (check mark)
- ✅ Border Width label shows "Border Width (3.0px)"
- ✅ Border Radius label shows "Border Radius (12px)"
- ✅ All changes tracked in internal state

---

### Scenario 8: Allow Dragging Checkbox

**Objective:** Verify dragging toggle functionality

**Steps:**

1. Open TextAnnotation dialog
2. Enter text: "Draggable"
3. Observe "Allow Dragging" checkbox (checked by default)
4. Click checkbox to uncheck
5. Click checkbox again to check

**Expected Results:**

- ✅ Default state: Checked
- ✅ Label: "Allow Dragging"
- ✅ Description: "Enable click-and-hold to reposition this annotation"
- ✅ Checkbox toggles on click
- ✅ State tracked internally (will affect created annotation)

---

### Scenario 9: Annotation Creation and Display

**Objective:** Verify annotation is created and appears on chart

**Steps:**

1. Right-click chart at position (x: 100, y: 50) approximately
2. Select "Add Text Annotation"
3. Enter text: "Important Event"
4. Select anchor: Top Center
5. Keep "Allow Dragging" checked
6. Expand styling, set:
   - Text Color: Blue
   - Font Size: 18px
   - Font Weight: Semi-Bold
   - Background Color: Light gray (Grey[300])
   - Border Color: Blue
   - Border Width: 2px
   - Border Radius: 8px
7. Click "Add"

**Expected Results:**

- ✅ Dialog closes immediately
- ✅ Console log: `✅ Created TextAnnotation: text_[timestamp] at Offset(100.0, 50.0)`
- ✅ Annotation appears on chart at click position
- ✅ Text reads "Important Event"
- ✅ Text is blue, 18px, semi-bold
- ✅ Background is light gray
- ✅ Border is blue, 2px wide
- ✅ Border has 8px radius (rounded corners)
- ✅ Text box aligns with top-center anchor (top edge at click y, horizontally centered on click x)

---

### Scenario 10: Annotation Dragging (Manual Test)

**Objective:** Verify dragging functionality works

**Steps:**

1. Create annotation as in Scenario 9 (with "Allow Dragging" checked)
2. Hover over annotation
3. Click and hold mouse button
4. Drag annotation to new position
5. Release mouse button

**Expected Results:**

- ✅ Cursor changes to move/grab cursor on hover
- ✅ Annotation follows mouse while dragging
- ✅ Annotation stays at new position after release
- ✅ Anchor point maintained (e.g., top-center still anchored)

**Note:** If dragging doesn't work yet, this is expected - dragging interaction may need additional implementation in the annotation rendering layer.

---

### Scenario 11: Cancel Dialog

**Objective:** Verify cancel action works correctly

**Steps:**

1. Open TextAnnotation dialog
2. Enter text: "Will be cancelled"
3. Make some style changes
4. Click "Cancel" button

**Expected Results:**

- ✅ Dialog closes immediately
- ✅ Console log: `❌ TextAnnotation creation cancelled`
- ✅ No annotation created
- ✅ Chart unchanged

**Steps (alternative):** 5. Open dialog again 6. Enter text and make changes 7. Click "X" close button in top right

**Expected Results:**

- ✅ Same behavior as "Cancel" button
- ✅ Dialog closes, no annotation created

**Steps (alternative):** 8. Open dialog again 9. Press Escape key (if supported)

**Expected Results:**

- ✅ Dialog closes
- ✅ No annotation created

---

### Scenario 12: Dialog Responsiveness

**Objective:** Verify dialog adapts to smaller screens

**Steps:**

1. Resize browser window to smaller size (e.g., 800x600)
2. Open TextAnnotation dialog
3. Expand styling section
4. Scroll within dialog

**Expected Results:**

- ✅ Dialog maintains 400px width (or adapts if screen < 400px)
- ✅ Dialog has max height constraint (650px)
- ✅ Content scrollable if height exceeds screen
- ✅ All controls remain accessible
- ✅ No horizontal scrolling needed

---

## Known Limitations / Future Work

**Not Yet Implemented:**

- ❌ Edit mode (right-click existing TextAnnotation → Edit)
- ❌ Delete confirmation dialog
- ❌ Annotation preview in dialog
- ❌ Drag handle visual indicator
- ❌ Annotation persistence (save/load)
- ❌ Undo/redo for annotation creation

**These are expected and documented for future implementation.**

---

## Test Results Summary

| Scenario                           | Status        | Notes |
| ---------------------------------- | ------------- | ----- |
| 1. Basic Dialog Display            | ⏳ Not Tested |       |
| 2. Text Input Validation           | ⏳ Not Tested |       |
| 3. Anchor Selector                 | ⏳ Not Tested |       |
| 4. Collapsible Style Editor        | ⏳ Not Tested |       |
| 5. Text Styling Controls           | ⏳ Not Tested |       |
| 6. Custom Color Picker             | ⏳ Not Tested |       |
| 7. Background and Border Styling   | ⏳ Not Tested |       |
| 8. Allow Dragging Checkbox         | ⏳ Not Tested |       |
| 9. Annotation Creation and Display | ⏳ Not Tested |       |
| 10. Annotation Dragging            | ⏳ Not Tested |       |
| 11. Cancel Dialog                  | ⏳ Not Tested |       |
| 12. Dialog Responsiveness          | ⏳ Not Tested |       |

**Overall Status:** ⏳ READY TO TEST

---

## Browser Console Debug Logs

**Look for these logs during testing:**

**Menu Interaction:**

```
🎯 _showContextMenu START...
🎯 Context Menu - Showing for element: null (empty area)
⏱️ [timestamp] 🎯 Menu action selected: add_text
🎯 Handling menu action: add_text
```

**Dialog Success:**

```
✅ Created TextAnnotation: text_1234567890 at Offset(100.0, 50.0)
```

**Dialog Cancel:**

```
❌ TextAnnotation creation cancelled
```

**Errors to Watch For:**

- ❌ `⚠️ Unknown menu action: add_text` (means handler not wired)
- ❌ `⏳ TODO: Show PointAnnotation dialog` (wrong case selected)
- ❌ Flutter framework errors (red text in console)
- ❌ Null reference exceptions

---

## Post-Testing Actions

After successful testing:

1. **Update this document** with test results (✅ Pass, ❌ Fail, ⚠️ Partial)
2. **Document any issues** in KNOWN_ISSUES section
3. **Create git commit**:

   ```bash
   git add -A
   git commit -m "feat: Implement TextAnnotation creation dialog

   Created web-native dialog following BravenChart patterns:

   NEW FILES:
   - lib/src_plus/widgets/dialogs/text_annotation_dialog.dart (378 lines)
   - lib/src_plus/widgets/dialogs/annotation_style_editor.dart (612 lines)

   FEATURES:
   - Text input with validation
   - 9-position anchor selector
   - Allow dragging checkbox
   - Collapsible style editor (8 controls)
   - Material Design 3 theme integration
   - Wired to context menu 'add_text' action

   TESTED:
   - All dialog controls functional
   - Annotation creation working
   - Style customization working
   - Cancel action working

   This establishes the dialog pattern for other annotation types."
   ```

4. **Push to remote**:
   ```bash
   git push origin core-interaction-refactor
   ```
5. **Update progress docs** (e.g., development.md)

---

## Next Steps After This Test

Once TextAnnotation is validated:

1. **PointAnnotation Dialog** (similar pattern, marker shapes)
2. **ThresholdAnnotation Dialog** (axis + value input)
3. **TrendAnnotation Dialog** (series selector + trend type)
4. **RangeAnnotation Creation** (Option 4: interactive drag mode)
5. **Edit Mode** (right-click existing annotation)
6. **Delete Confirmation** (delete selected annotation)

---

**Document Version:** 1.0  
**Last Updated:** 2025-01-XX  
**Author:** GitHub Copilot (Claude Sonnet 4.5)
