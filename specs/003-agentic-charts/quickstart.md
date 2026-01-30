# Quickstart: Agentic Charts

**Feature**: 003-agentic-charts  
**Date**: 2026-01-25

## Prerequisites

- Flutter SDK 3.38.6+
- Dart 3.10+
- LLM API key (Anthropic Claude recommended)
- Chrome browser (for web development)

## Setup

### 1. Add Dependencies

```yaml
# pubspec.yaml
dependencies:
  braven_charts: ^1.x.x
  anthropic_sdk_dart: ^0.x.x # Or openai_dart, google_generative_ai
  http: ^1.x.x
  uuid: ^4.x.x
```

### 2. Configure API Key

```dart
// For development: environment variable
const apiKey = String.fromEnvironment('ANTHROPIC_API_KEY');

// For production: secure storage
final provider = AnthropicProvider(apiKey: secureStorage.get('llm_api_key'));
```

### 3. CORS Configuration (Web)

#### Development

```powershell
# Run with security disabled (development only!)
flutter run -d chrome --web-browser-flag "--disable-web-security"
```

#### Production

Deploy a Cloudflare Worker proxy:

```javascript
// worker.js - Cloudflare Worker
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const targetUrl = "https://api.anthropic.com" + url.pathname;

    const modifiedRequest = new Request(targetUrl, {
      method: request.method,
      headers: request.headers,
      body: request.body,
    });

    return fetch(modifiedRequest);
  },
};
```

## Basic Usage

### Initialize Agent Service

```dart
import 'package:braven_charts/agentic.dart';

void main() {
  final agentService = AgentService(
    provider: AnthropicProvider(
      apiKey: apiKey,
      model: 'claude-sonnet-4-20250514',
    ),
  );

  runApp(MyApp(agentService: agentService));
}
```

### Embed Chat Interface

```dart
import 'package:braven_charts/agentic.dart';

class ChartScreen extends StatelessWidget {
  final AgentService agentService;

  @override
  Widget build(BuildContext context) {
    return AgenticChatInterface(
      agentService: agentService,
      onChartCreated: (chartId, widget) {
        // Handle new chart
      },
      theme: AgenticTheme.light,
    );
  }
}
```

### Load Data Programmatically

```dart
// Load FIT file
final dataId = await agentService.loadData(
  source: FileSource(
    bytes: fitFileBytes,
    fileName: 'workout.fit',
    format: DataFormat.fit,
  ),
);

// Describe data
final description = await agentService.describeData(dataId);
print('Columns: ${description.columns.map((c) => c.name).join(", ")}');
```

### Create Chart Programmatically

```dart
final chartId = await agentService.createChart(
  ChartConfiguration(
    type: ChartType.line,
    title: 'Power Analysis',
    series: [
      SeriesConfig(
        id: 'power',
        name: 'Power',
        dataId: dataId,
        dataColumn: 'power',
        color: '#FF6B00',
        interpolation: Interpolation.bezier,
      ),
    ],
    xAxis: XAxisConfig(
      label: 'Time',
      type: AxisType.time,
    ),
    yAxes: [
      YAxisConfig(
        id: 'power-axis',
        label: 'Power',
        unit: 'W',
        position: AxisPosition.left,
      ),
    ],
  ),
);
```

### Calculate Metrics

```dart
final np = await agentService.calculateMetric(
  dataId: dataId,
  column: 'power',
  metric: MetricType.normalizedPower,
);

print('Normalized Power: ${np.formattedValue}'); // "256 W"
```

## Example Prompts

Once the chat interface is running, try these prompts:

### Basic Chart Creation

```
Show me a line chart of power over time
```

### With Styling

```
Create a blue area chart of heart rate with the grid hidden
```

### Data Analysis

```
Upload my FIT file and show 30-second rolling average of power
```

### Multi-Axis

```
Compare power and heart rate on the same chart with separate Y-axes
```

### Annotations

```
Add a horizontal reference line at 250W labeled "FTP"
```

### Metrics

```
Calculate Normalized Power for this ride
```

## File Support

| Format     | Extension | Notes                                     |
| ---------- | --------- | ----------------------------------------- |
| Garmin FIT | .fit      | Binary activity files from Garmin devices |
| CSV        | .csv      | Comma-separated values with headers       |
| JSON       | .json     | Array of objects or time-series format    |

## Configuration Options

### Theme

```dart
AgenticChatInterface(
  theme: AgenticTheme.dark, // or .light, .auto
)
```

### Keyboard Shortcuts

| Shortcut     | Action            |
| ------------ | ----------------- |
| Ctrl+Enter   | Send message      |
| Ctrl+U       | Upload file       |
| Ctrl+Z       | Undo chart change |
| Ctrl+Shift+Z | Redo              |
| Ctrl+S       | Save to favorites |
| Ctrl+E       | Export chart      |
| Escape       | Close panel       |

## Troubleshooting

### CORS Errors

- Development: Use `--disable-web-security` flag
- Production: Deploy proxy worker

### Large Files Slow

- Files >10 MB show warning
- Files >50 MB are rejected
- Consider downsampling in source

### Token Limit Warning

- Warning appears at 80% token usage
- Start new session to reset
- Export favorites before clearing

## Next Steps

- See [spec.md](spec.md) for full feature specification
- See [data-model.md](data-model.md) for entity definitions
- See [contracts/llm-tools.yaml](contracts/llm-tools.yaml) for tool schemas
