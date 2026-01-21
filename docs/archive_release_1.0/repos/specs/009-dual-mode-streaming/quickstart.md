# Quickstart: Dual-Mode Streaming Charts

**Feature**: Real-time streaming with automatic pause-on-interaction  
**Complexity**: Intermediate  
**Time to integrate**: 15-30 minutes

## What You'll Build

A real-time line chart that:

- Streams data continuously at 60fps in **streaming mode**
- Automatically pauses and buffers data when user interacts (hover, zoom, pan)
- Auto-resumes after 10 seconds of inactivity
- Prevents all rendering errors during mode transitions

---

## Prerequisites

- Braven Charts v1.x.x or later (with dual-mode streaming support)
- Dart 3.0+ / Flutter SDK 3.10.0+
- Basic familiarity with Streams in Dart

---

## Basic Usage (Minimal Configuration)

### Step 1: Create a Stream Data Source

```dart
import 'dart:async';
import 'package:braven_charts/braven_charts.dart';

// Simulated real-time data stream (e.g., server metrics)
Stream<DataPoint> createServerMetricsStream() async* {
  while (true) {
    await Future.delayed(Duration(milliseconds: 100)); // 10 points/sec
    yield DataPoint(
      x: DateTime.now().millisecondsSinceEpoch.toDouble(),
      y: Random().nextDouble() * 100, // Random CPU usage 0-100%
    );
  }
}
```

### Step 2: Configure BravenChart with Streaming

```dart
class MyDashboard extends StatelessWidget {
  final stream = createServerMetricsStream();

  @override
  Widget build(BuildContext context) {
    return BravenChart(
      data: stream, // Pass Stream (not List)
      chartType: ChartType.line,

      // Enable dual-mode streaming with defaults
      streamingConfig: StreamingConfig(),

      // Optional: Customize appearance
      lineColor: Colors.blue,
      showGrid: true,
    );
  }
}
```

**That's it!** Chart now:

- ✅ Streams data in real-time (60fps)
- ✅ Pauses on first interaction (hover/click)
- ✅ Auto-resumes after 10 seconds
- ✅ Buffers up to 10,000 points
- ✅ Never loses data

---

## Advanced Configuration

### Custom Timeout and Buffer Size

```dart
StreamingConfig(
  // Auto-resume after 15 seconds (instead of 10)
  autoResumeTimeout: Duration(seconds: 15),

  // Buffer up to 5,000 points (instead of 10,000)
  maxBufferSize: 5000,

  // Disable auto-pause (chart stays in interactive mode)
  pauseOnFirstInteraction: false,
)
```

### Mode Change Notifications

```dart
StreamingConfig(
  onModeChanged: (ChartMode mode) {
    if (mode == ChartMode.streaming) {
      print('📊 Now streaming live data');
    } else {
      print('⏸️ Paused for interaction');
    }
  },
)
```

### Buffer Status Tracking

```dart
class MyDashboard extends StatefulWidget {
  @override
  _MyDashboardState createState() => _MyDashboardState();
}

class _MyDashboardState extends State<MyDashboard> {
  int _bufferedCount = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Show buffer status
        if (_bufferedCount > 0)
          Chip(
            label: Text('$_bufferedCount new points'),
            backgroundColor: Colors.orange,
          ),

        // Chart with buffer callback
        BravenChart(
          data: widget.stream,
          chartType: ChartType.line,
          streamingConfig: StreamingConfig(
            onBufferUpdated: (int count) {
              setState(() => _bufferedCount = count);
            },
          ),
        ),
      ],
    );
  }
}
```

### Manual "Return to Live" Button

```dart
class MyDashboard extends StatefulWidget {
  @override
  _MyDashboardState createState() => _MyDashboardState();
}

class _MyDashboardState extends State<MyDashboard> {
  final GlobalKey<BravenChartState> _chartKey = GlobalKey();
  bool _showResumeButton = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        BravenChart(
          key: _chartKey,
          data: widget.stream,
          chartType: ChartType.line,
          streamingConfig: StreamingConfig(
            onReturnToLive: () {
              setState(() => _showResumeButton = true);
            },
            onModeChanged: (mode) {
              if (mode == ChartMode.streaming) {
                setState(() => _showResumeButton = false);
              }
            },
          ),
        ),

        // Manual resume button (top-right corner)
        if (_showResumeButton)
          Positioned(
            top: 16,
            right: 16,
            child: ElevatedButton.icon(
              icon: Icon(Icons.play_arrow),
              label: Text('Return to Live'),
              onPressed: () {
                _chartKey.currentState?.resumeStreaming();
              },
            ),
          ),
      ],
    );
  }
}
```

### Error Handling

```dart
StreamingConfig(
  onStreamError: (Object error) {
    // Log error
    print('Stream error: $error');

    // Show error banner
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Connection lost. Attempting reconnection...'),
        backgroundColor: Colors.red,
      ),
    );

    // Developer is responsible for reconnection logic
    // Chart does NOT retry automatically
    _attemptReconnection();
  },
)
```

---

## Complete Example

```dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:braven_charts/braven_charts.dart';

class RealTimeDashboard extends StatefulWidget {
  @override
  _RealTimeDashboardState createState() => _RealTimeDashboardState();
}

class _RealTimeDashboardState extends State<RealTimeDashboard> {
  final GlobalKey<BravenChartState> _chartKey = GlobalKey();
  late StreamController<DataPoint> _controller;
  late Timer _dataGenerator;

  ChartMode _currentMode = ChartMode.streaming;
  int _bufferedCount = 0;

  @override
  void initState() {
    super.initState();

    // Create stream controller
    _controller = StreamController<DataPoint>.broadcast();

    // Generate data every 100ms (10 points/sec)
    _dataGenerator = Timer.periodic(Duration(milliseconds: 100), (_) {
      _controller.add(DataPoint(
        x: DateTime.now().millisecondsSinceEpoch.toDouble(),
        y: Random().nextDouble() * 100,
      ));
    });
  }

  @override
  void dispose() {
    _dataGenerator.cancel();
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Real-Time Metrics'),
        actions: [
          // Mode indicator
          Chip(
            avatar: Icon(
              _currentMode == ChartMode.streaming
                  ? Icons.circle
                  : Icons.pause_circle_filled,
              color: _currentMode == ChartMode.streaming
                  ? Colors.green
                  : Colors.orange,
            ),
            label: Text(
              _currentMode == ChartMode.streaming ? 'LIVE' : 'PAUSED',
            ),
          ),
          SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          // Chart
          BravenChart(
            key: _chartKey,
            data: _controller.stream,
            chartType: ChartType.line,
            lineColor: Colors.blue,
            showGrid: true,

            streamingConfig: StreamingConfig(
              // Custom timeout: 15 seconds
              autoResumeTimeout: Duration(seconds: 15),

              // Track mode changes
              onModeChanged: (ChartMode mode) {
                setState(() => _currentMode = mode);
              },

              // Track buffer count
              onBufferUpdated: (int count) {
                setState(() => _bufferedCount = count);
              },

              // Handle stream errors
              onStreamError: (error) {
                print('Stream error: $error');
              },
            ),
          ),

          // Buffer status badge
          if (_bufferedCount > 0)
            Positioned(
              top: 16,
              left: 16,
              child: Chip(
                avatar: Icon(Icons.update, color: Colors.white),
                label: Text(
                  '$_bufferedCount new points',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.orange,
              ),
            ),

          // Manual resume button
          if (_currentMode == ChartMode.interactive)
            Positioned(
              top: 16,
              right: 16,
              child: ElevatedButton.icon(
                icon: Icon(Icons.play_arrow),
                label: Text('Return to Live'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                onPressed: () {
                  _chartKey.currentState?.resumeStreaming();
                },
              ),
            ),
        ],
      ),
    );
  }
}
```

---

## Common Patterns

### Pattern 1: Monitoring Dashboard

**Use Case**: Server metrics, stock prices, IoT sensor data

```dart
StreamingConfig(
  autoResumeTimeout: Duration(seconds: 5),  // Quick return to live
  pauseOnFirstInteraction: true,            // Allow inspection
  maxBufferSize: 1000,                      // Short buffer window
)
```

### Pattern 2: Historical Analysis

**Use Case**: Log analysis, time-series investigation

```dart
StreamingConfig(
  autoResumeTimeout: Duration(minutes: 5),  // Long inspection time
  pauseOnFirstInteraction: true,
  maxBufferSize: 50000,                     // Large buffer
)
```

### Pattern 3: Always Interactive (No Auto-Pause)

**Use Case**: Static chart with occasional updates

```dart
StreamingConfig(
  pauseOnFirstInteraction: false,  // Never auto-pause
  // Auto-resume still works if manually paused
)
```

---

## Migration from Non-Streaming Charts

### Before (Static Chart)

```dart
BravenChart(
  data: myStaticData,  // List<DataPoint>
  chartType: ChartType.line,
)
```

### After (Streaming Chart)

```dart
BravenChart(
  data: myStreamController.stream,  // Stream<DataPoint>
  chartType: ChartType.line,
  streamingConfig: StreamingConfig(), // Required for streams
)
```

**Backward Compatibility**: Non-streaming charts work unchanged. No breaking changes for existing static charts.

---

## Performance Tips

### Tip 1: Limit Data Frequency

```dart
// Bad: 1000 points/sec (overkill, drops frames)
Timer.periodic(Duration(milliseconds: 1), ...);

// Good: 60 points/sec (smooth 60fps)
Timer.periodic(Duration(milliseconds: 16), ...);

// Best: 10-30 points/sec (sufficient for most monitoring)
Timer.periodic(Duration(milliseconds: 100), ...);
```

### Tip 2: Use Appropriate Buffer Size

```dart
// For 10 points/sec, 10K buffer = 16 minutes of data
// For 100 points/sec, 10K buffer = 1.6 minutes of data

// Adjust based on data frequency:
final bufferSize = dataPointsPerSecond * expectedInteractionSeconds;

StreamingConfig(
  maxBufferSize: bufferSize,
)
```

### Tip 3: Monitor Buffer Overflow

```dart
StreamingConfig(
  onBufferUpdated: (count) {
    // Warn when approaching limit (80% full)
    if (count > streamingConfig.maxBufferSize * 0.8) {
      print('⚠️ Buffer 80% full. Consider resuming or increasing limit.');
    }
  },
)
```

---

## Troubleshooting

### Issue: Chart never pauses on interaction

**Cause**: `pauseOnFirstInteraction: false`  
**Solution**: Use default or set to `true`

### Issue: Buffer fills too quickly

**Cause**: High data frequency + long interaction time  
**Solution**: Increase `maxBufferSize` or reduce data frequency

### Issue: Auto-resume too slow/fast

**Cause**: Default 10s timeout doesn't fit use case  
**Solution**: Adjust `autoResumeTimeout` duration

### Issue: Rendering errors (box.dart:3345)

**Cause**: Mixing setState with streaming (violates Constitution II)  
**Solution**: Use ValueNotifier pattern as shown in examples

---

## Next Steps

- **Testing**: See `/test/integration/dual_mode_streaming_test.dart` for test examples
- **API Reference**: See `/specs/009-dual-mode-streaming/contracts/streaming_api_contract.dart`
- **Architecture**: See `/docs/specs/streaming_interaction_architecture.md` for design details
- **Performance**: See `/test/performance/streaming_benchmark.dart` for benchmarks

---

**Need Help?** File an issue on GitHub with your StreamingConfig and error details.
