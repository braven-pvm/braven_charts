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

## AI Chart Creation Demo (braven_agent_demo)

The Braven Agent Demo (braven_agent_demo) showcases AI-powered chart creation via a chat UI.
It connects to Anthropic Claude and turns natural language prompts into charts rendered by
BravenChartPlus.

### Prerequisites

- An Anthropic API key from https://console.anthropic.com
- Set the API key via environment variable `ANTHROPIC_API_KEY` or enter it in the app

### Run the demo

From the example directory:

```bash
flutter pub get
flutter run -d chrome -t lib/demos/braven_agent_demo.dart --dart-define=ANTHROPIC_API_KEY=sk-ant-...
```

### AI Chat features demonstrated

- API key gate for Anthropic credentials
- Chat history with user/assistant messages
- Live status indicators (thinking/tool execution)
- Chart rendering panel powered by `ChartRenderer`
- Follow-up prompts to modify the active chart

### Example prompts to try

- Create a line chart with 3 series showing monthly sales
- Create a bar chart comparing Q1 revenue by region
- Make the first series red and add markers
- Add a trend line and increase the line thickness
