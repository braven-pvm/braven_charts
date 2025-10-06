# Braven Charts Example App

This example app demonstrates all chart types available in the Braven Charts library.

## Features Demonstrated

### Line Charts
- Basic line chart with straight interpolation
- Smooth line chart with Bezier curves
- Stepped line chart
- Multi-series line charts with markers
- Custom marker shapes

### Area Charts
- Solid fill area chart
- Gradient fill area chart
- Stacked area charts
- Area charts with custom baselines

### Bar Charts
- Vertical grouped bar chart
- Horizontal grouped bar chart
- Stacked bar chart
- Bars with rounded corners and gradients

### Scatter Plots
- Fixed-size scatter plot
- Data-driven sizing (bubble chart)
- Scatter plot with clustering
- Various marker shapes and styles

## Running the Example

```bash
cd example
flutter pub get
flutter run
```

## Chart Implementations

All charts are rendered using the chart types layer (Layer 4) with:
- Pure Flutter rendering (dart:ui)
- No external charting dependencies
- Performance-optimized algorithms
- Object pooling and shader caching

## Current Limitations

This example uses placeholder implementations for:
- Coordinate transformations (direct offset mapping)
- Theming (hardcoded color palettes)
- Animations (not yet integrated)

These will be replaced when Layer 2 (Coordinate System) and Layer 3 (Theming) are integrated.

## Code Structure

- `lib/main.dart` - Main app with navigation
- `lib/screens/` - Individual chart demo screens
- `lib/data/` - Sample data generators
- `lib/widgets/` - Reusable chart container widgets
