# Quick Start: Running the Example App

## Prerequisites

- Flutter SDK 3.10.0 or higher
- Dart 3.0.0 or higher
- A connected device or emulator (Android/iOS) or web browser

## Installation & Running

### 1. Navigate to Example Directory
```bash
cd example
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run the App

**For Android:**
```bash
flutter run -d android
```

**For iOS:**
```bash
flutter run -d ios
```

**For Web:**
```bash
flutter run -d chrome
```

**For Desktop:**
```bash
# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux
```

### 4. Explore the Charts

The app opens with a home screen showing 4 chart type cards:
1. **Line Charts** - Tap to see 4 different line chart demonstrations
2. **Area Charts** - Tap to see 4 different area chart demonstrations
3. **Bar Charts** - Tap to see 4 different bar chart demonstrations
4. **Scatter Plots** - Tap to see 4 different scatter plot demonstrations

Each chart screen has:
- Info card explaining the chart type features
- Multiple chart examples with descriptions
- Refresh button to regenerate sample data

## What You'll See

Currently, the charts show **placeholder widgets** with descriptions because:
- Layer 2 (Coordinate System) is not yet integrated
- Layer 3 (Theming System) is not yet integrated
- The full rendering pipeline requires all layers connected

The placeholders demonstrate:
- Complete UI structure and navigation
- Sample data generation for all chart types
- Material 3 design with theme support
- Responsive layout

## Next Integration Steps

To see actual rendered charts:
1. Integrate Layer 2 (Coordinate System)
2. Integrate Layer 3 (Theming System)
3. Replace `DemoChartWidget` with `CustomPaint` implementations
4. Wire up chart layers to sample data
5. Add interactivity (tap, zoom, pan)

See `integration_testing.md` for detailed integration guide.

## Troubleshooting

### "Target of URI doesn't exist" errors
Run `flutter clean` then `flutter pub get`

### "Unable to determine engine version" errors
This is a known Flutter hash.txt file lock issue. Close other Flutter processes and try again.

### Build errors
Make sure you're in the `example/` directory and have run `flutter pub get`

## Code Quality

Run these commands to verify code quality:

```bash
# Analyze code
flutter analyze

# Format code
flutter format lib/

# Run tests (when tests are added)
flutter test
```

## Platform-Specific Notes

### Android
- Minimum SDK: 21 (Android 5.0)
- Target SDK: 34 (Android 14)
- Requires Android Studio or SDK command-line tools

### iOS
- Minimum iOS: 12.0
- Requires Xcode 13 or higher
- Requires macOS to build

### Web
- Supports all modern browsers
- Best experience in Chrome
- Enable CORS for local development if needed

### Desktop
- Windows: Requires Visual Studio 2022 with C++ workload
- macOS: Requires Xcode 13 or higher
- Linux: Requires GTK 3.0 development libraries

## Questions?

See the main project README or open an issue on GitHub.
