# Tooltip Styling & Theming Examples

## Overview

This document describes the comprehensive tooltip styling and theming examples added to the braven_charts example app. These examples showcase all the customization options available for tooltips in braven_charts.

## New Examples Added

### Example 10: Tooltip Styling Variants ✨
**File:** `lib/screens/interaction_examples/tooltip_styling_variants.dart`

Demonstrates 5 different tooltip style configurations with a PageView carousel:

1. **Light Style** - Classic professional appearance
   - Light gray background (#FAFAFA)
   - Subtle gray border (1px)
   - Minimal shadow for depth
   - Dark gray text for contrast

2. **Dark Style** - Modern dark-mode appearance
   - Dark charcoal background (#212121)
   - Medium gray border (2px)
   - Pronounced shadow effect
   - Light text for contrast

3. **Accent Style** - Bold and eye-catching
   - Vibrant orange background (#FF6F00)
   - Bold orange-red border (2.5px)
   - Orange-tinted shadow
   - White text for maximum contrast

4. **Minimal Style** - Clean and unobtrusive
   - Light background with no visible border
   - No shadow effect
   - Minimal padding
   - Perfect for minimalist UIs

5. **Material Style** - Material Design 3 approach
   - Material indigo background (#3F51B5)
   - Rounded corners (12px)
   - Elevation-style shadow
   - White text

**Key Features:**
- Swipe between 5 different style variants
- Page indicators showing current style
- Descriptions explaining each style
- Uses `TooltipStyle` class properties:
  - `backgroundColor` - Background color
  - `borderColor` - Border color
  - `borderWidth` - Border thickness
  - `borderRadius` - Corner rounding
  - `shadowColor` - Shadow tint
  - `shadowBlurRadius` - Shadow blur
  - `padding` - Interior spacing
  - `textColor` - Text color
  - `fontSize` - Font size

---

### Example 11: Tooltip Trigger Modes 👆
**File:** `lib/screens/interaction_examples/tooltip_trigger_modes.dart`

Demonstrates the 3 different trigger modes for showing tooltips:

1. **Hover Mode** - Desktop-centric
   - Tooltip appears on mouse hover
   - 200ms delay before showing
   - Hides immediately when mouse leaves
   - Not available on touch devices
   - Ideal for desktop applications

2. **Tap Mode** - Touch-friendly
   - Tooltip appears only on click/tap
   - Shows immediately (0ms delay)
   - Hides after 200ms of no interaction
   - Works on both desktop and mobile
   - Clean, minimalist interaction

3. **Both Mode** - Most versatile
   - Shows on both hover and tap
   - 100ms delay before showing
   - Works seamlessly across platforms
   - Best for mixed mouse/touch environments

**Key Features:**
- Toggle between 3 trigger modes with buttons
- Optional crosshair toggling
- Description panel explaining each mode
- Shows platform support information
- Displays timing configuration details
- Uses `TooltipTriggerMode` enum:
  - `TooltipTriggerMode.hover`
  - `TooltipTriggerMode.tap`
  - `TooltipTriggerMode.both`

---

### Example 12: Tooltip Positioning 📍
**File:** `lib/screens/interaction_examples/tooltip_positioning_demo.dart`

Demonstrates 5 different positioning strategies for tooltips:

1. **Auto Position** - Smart positioning (recommended)
   - Automatically avoids clipping
   - Prefers top, but moves as needed
   - Best for most use cases
   - Intelligent edge detection

2. **Top Position** - Always above
   - Positions tooltip above data point
   - Good for bottom-heavy data
   - Useful when space permits above

3. **Bottom Position** - Always below
   - Positions tooltip below data point
   - Good for top-heavy data
   - Useful when space permits below

4. **Left Position** - Always left
   - Positions tooltip left of data point
   - Good for right-side data
   - Preserves space on right

5. **Right Position** - Always right
   - Positions tooltip right of data point
   - Good for left-side data
   - Preserves space on right

**Key Features:**
- PageView carousel showing each position
- Page indicators with color themes
- Scatter chart to show edge cases
- Description panel explaining strategy
- Uses `TooltipPosition` enum:
  - `TooltipPosition.auto`
  - `TooltipPosition.top`
  - `TooltipPosition.bottom`
  - `TooltipPosition.left`
  - `TooltipPosition.right`

---

### Example 13: Theme-Aware Tooltips 🌓
**File:** `lib/screens/interaction_examples/theme_aware_tooltip.dart`

Demonstrates tooltips that respond to light/dark theme changes:

**Light Theme:**
- Light background with dark text
- Subtle shadows
- Good readability in bright conditions
- Professional appearance

**Dark Theme:**
- Dark background with light text
- Stronger shadows for depth
- Good readability in low-light conditions
- Modern appearance

**High Contrast Mode:**
- Bold, saturated colors
- Thicker borders (2.5px)
- Stronger shadows
- Enhanced accessibility

**Key Features:**
- Real-time theme switching (Light/Dark/System)
- High contrast accessibility mode toggle
- Material Design 3 color system integration
- Smooth theme transitions
- Theme information panel
- Uses `ThemeMode` for switching:
  - `ThemeMode.light` - Light theme
  - `ThemeMode.dark` - Dark theme
  - `ThemeMode.system` - System setting

---

## Code Examples

### Using Tooltip Styling

```dart
BravenChart(
  series: [/* ... */],
  interactionConfig: InteractionConfig(
    tooltip: TooltipConfig(
      enabled: true,
      style: TooltipStyle(
        backgroundColor: Colors.blue.shade50,
        borderColor: Colors.blue,
        borderWidth: 2.0,
        borderRadius: 8.0,
        padding: 12.0,
        textColor: Colors.blue.shade900,
        fontSize: 14.0,
        shadowColor: Colors.black26,
        shadowBlurRadius: 8.0,
      ),
    ),
  ),
)
```

### Using Trigger Modes

```dart
TooltipConfig(
  enabled: true,
  triggerMode: TooltipTriggerMode.both, // hover or tap
  showDelay: Duration(milliseconds: 100),
  hideDelay: Duration(milliseconds: 200),
)
```

### Using Positioning

```dart
TooltipConfig(
  enabled: true,
  preferredPosition: TooltipPosition.top, // auto, top, bottom, left, right
  offsetFromPoint: 15.0,
)
```

### Using Theme-Aware Styling

```dart
final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

TooltipConfig(
  style: TooltipStyle(
    backgroundColor: isDark ? Colors.grey.shade800 : Colors.white,
    textColor: isDark ? Colors.white : Colors.black,
    borderColor: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
  ),
)
```

---

## Navigation

All examples are accessible through the **Interaction Examples** screen:

1. Open the app
2. Navigate to **Interaction Examples**
3. Scroll to **Tooltip Examples** section
4. Choose from:
   - Example 10: Tooltip Styling Variants
   - Example 11: Tooltip Trigger Modes
   - Example 12: Tooltip Positioning
   - Example 13: Theme-Aware Tooltips

---

## TooltipStyle Properties Reference

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `backgroundColor` | `Color` | `#E6FFFFFF` | Background color |
| `borderColor` | `Color` | `#FF999999` | Border color |
| `borderWidth` | `double` | `1.0` | Border thickness (px) |
| `borderRadius` | `double` | `4.0` | Corner rounding (px) |
| `shadowColor` | `Color` | `#40000000` | Shadow tint |
| `shadowBlurRadius` | `double` | `4.0` | Shadow blur (px) |
| `padding` | `double` | `8.0` | Interior spacing (px) |
| `textColor` | `Color` | `#FF333333` | Text color |
| `fontSize` | `double` | `12.0` | Font size (px) |

---

## TooltipConfig Properties Reference

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `enabled` | `bool` | `true` | Enable/disable tooltip |
| `triggerMode` | `TooltipTriggerMode` | `hover` | hover, tap, or both |
| `preferredPosition` | `TooltipPosition` | `auto` | Positioning strategy |
| `showDelay` | `Duration` | `100ms` | Delay before showing |
| `hideDelay` | `Duration` | `200ms` | Delay before hiding |
| `followCursor` | `bool` | `false` | Follow cursor or stick to point |
| `offsetFromPoint` | `double` | `10.0` | Distance from data point (px) |
| `style` | `TooltipStyle` | - | Visual styling |
| `customBuilder` | `TooltipBuilder?` | - | Custom content builder |

---

## Best Practices

### 1. Choose Appropriate Styling
- Use **light style** for professional, clean apps
- Use **dark style** for modern, sleek apps
- Use **accent style** for important data highlights
- Use **minimal style** for unobtrusive UIs
- Use **material style** for Material Design 3 apps

### 2. Select Appropriate Trigger Mode
- Use **hover** for desktop-only applications
- Use **tap** for mobile-first applications
- Use **both** for responsive applications supporting all platforms

### 3. Pick Positioning Strategy
- Use **auto** (recommended) for most use cases
- Use **top** when chart data is bottom-heavy
- Use **bottom** when chart data is top-heavy
- Use **left/right** for edge cases where standard positioning clips

### 4. Support Dark Mode
- Use theme-aware tooltips for modern apps
- Adapt colors based on `MediaQuery.platformBrightness`
- Provide high contrast mode for accessibility
- Use Material Design 3 color system for consistency

### 5. Customize Content
- Use `customBuilder` for rich tooltip content
- Include icons, badges, or formatted data
- Keep tooltips compact and readable
- Use consistent styling with app theme

---

## Testing the Examples

Each example is a standalone, fully-functional demonstration:

```bash
# Run the example app
flutter run

# Navigate to Interaction Examples
# Browse through Tooltip Examples section
# Try each example interactively
```

---

## Related Documentation

- [Tooltip Configuration](../../docs/guides/interaction-system.md)
- [Styling System](../../docs/guides/theming-usage.md)
- [Interaction System](../../docs/guides/interaction-system.md)
- [API Reference](../../../doc/api/)

---

## Summary

These 4 new examples provide comprehensive coverage of tooltip customization:

| Feature | Example | Coverage |
|---------|---------|----------|
| **Styling** | Example 10 | 5 distinct styles |
| **Triggers** | Example 11 | 3 trigger modes |
| **Positioning** | Example 12 | 5 positioning strategies |
| **Theming** | Example 13 | Light/dark + contrast |

Together, they demonstrate how to create professional, accessible, themed tooltips that work seamlessly across desktop and mobile platforms.
