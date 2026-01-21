# BravenChartPlus Showcase Example

A simple Flutter app demonstrating the basic features of BravenChartPlus.

## Features Demonstrated

- **Line Charts**: Smooth bezier interpolation with data point markers
- **Area Charts**: Filled area under curves with transparency
- **Bar Charts**: Vertical bar representations
- **Scatter Plots**: Individual data point visualization
- **Multiple Series**: Display multiple data series on a single chart

## Getting Started

1. Make sure you're in the example directory:
   ```bash
   cd example
   ```

2. Get dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run -d chrome
   ```

## Chart Types

### Line Chart
- Smooth bezier curve interpolation
- Data point markers at each value
- Interactive hover and zoom

### Area Chart
- Filled area with adjustable opacity
- Smooth curves following the data
- Visual emphasis on value ranges

### Bar Chart
- Vertical bars for each data point
- Adjustable bar width
- Clear categorical comparison

### Scatter Plot
- Individual point markers
- Ideal for correlation visualization
- Customizable point size

### Multiple Series
- Display multiple data sets
- Automatic legend generation
- Distinct colors for each series

## Interactive Features

All charts support:
- Pan and zoom with mouse/touch
- Keyboard navigation (arrow keys for pan, +/- for zoom)
- Reset view with 'R' or 'Home' key
- Focus management for keyboard controls

## Next Steps

This is a minimal showcase. For more advanced features, see the main documentation:
- Annotations (text, points, ranges, thresholds, trends)
- Streaming data with real-time updates
- Custom theming
- Advanced interaction modes
- Scrollbars and viewport controls
