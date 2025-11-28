# Flutter Integration Testing with Screenshots

This document explains how to run Flutter integration tests that interact with the app in a real web browser and capture screenshots.

## Verification Framework Integration

This document is part of the **Verification Framework**. For task-based screenshot verification:

- **Screenshot naming convention**: See [screenshot-verification.md](.specify/verification/screenshot-verification.md)
- **Integration test template**: See [integration-test-template.dart](.specify/verification/templates/integration-test-template.dart)
- **Verification framework entry**: See [.specify/verification/index.md](.specify/verification/index.md)

## Overview

Integration tests allow you to:
- **Run the app in a real browser** (Chrome)
- **Interact with UI elements** (tap, scroll, hover, keyboard input)
- **Capture screenshots** at any point during the test
- **Verify behavior** across the full application stack

## Prerequisites

### 1. Flutter Setup
Ensure Flutter is installed and configured:
```bash
flutter doctor
```

### 2. ChromeDriver Setup

ChromeDriver is required to automate Chrome browser interactions. **The ChromeDriver version MUST match your installed Chrome version.**

#### Check Your Chrome Version
```powershell
# Windows
$chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
(Get-Item $chromePath).VersionInfo.FileVersion
```

#### Download Matching ChromeDriver

1. **Find your Chrome version** (e.g., `142.0.7444.176` → major version is `142`)

2. **Download ChromeDriver** from: https://googlechromelabs.github.io/chrome-for-testing/
   - Select the matching major version (e.g., `142.x.x.x`)
   - Download the `chromedriver` for your platform (win64, mac-x64, linux64)

3. **Extract and place** ChromeDriver:
   ```bash
   # Extract the downloaded zip
   # Place chromedriver.exe in: test/chromedriver/win64-<version>/chromedriver-win64/
   ```

#### Current ChromeDriver Location
```
test/chromedriver/
├── .metadata
└── win64-142.0.7444.176/          # Version-specific folder
    └── chromedriver-win64/
        ├── chromedriver.exe
        ├── LICENSE.chromedriver
        └── THIRD_PARTY_NOTICES.chromedriver
```

## Running Integration Tests

### Step 1: Start ChromeDriver

Open a terminal and start ChromeDriver on port 4444:

```powershell
# Windows (adjust version number to match your Chrome)
cd test/chromedriver/win64-142.0.7444.176/chromedriver-win64
.\chromedriver.exe --port=4444
```

You should see:
```
ChromeDriver was started successfully on port 4444.
```

**Keep this terminal open** while running tests.

### Step 2: Run Integration Tests

Open a **new terminal**. You can choose between a fast, fully automated flow and a human-observable flow:

#### Option A: Fast web-server flow (recommended for CI/automation)

```bash
cd example
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/proof_test.dart \
  --dart-define=PROOF_PAUSES=false \
  -d web-server \
  --browser-name=chrome
```

- Requires ChromeDriver to keep running on port 4444 (from Step 1).
- Launches the `web-server` device but still drives a real Chrome session via WebDriver.
- Disables all “watch me” pauses so the run typically finishes in under a minute.

#### Option B: Direct Chrome flow (good for manual observation)

```bash
cd example
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/proof_test.dart \
  --dart-define=PROOF_PAUSES=true \
  -d chrome
```

- Flutter manages Chrome directly.
- Keeps the narrated pauses so you can visually verify every interaction in real time.

### Available Integration Tests

Located in `example/integration_test/`:

- **`proof_test.dart`** - Full interaction test with visible status overlays
  - Launches app, navigates, interacts with chart
  - Tests keyboard and mouse interactions
  - Captures screenshot of final state
  
- **`tooltip_positioning_integration_test.dart`** - Tooltip behavior tests
  - Verifies tooltips follow data points
  - Tests hover interactions
  - Validates tooltip positioning logic

- **`zoom_app_test.dart`** - Zoom functionality tests
  - Tests zoom controls
  - Keyboard zoom (+ / - keys)
  - Mouse wheel zoom

- **`keyboard_zoom_incremental_test.dart`** - Incremental zoom behavior

- **`line_continuity_test.dart`** - Line chart rendering continuity

- **`slow_visual_test.dart`** - Slow-motion visual verification

## Screenshot Capture

Screenshots are automatically captured and saved in the `screenshots/` folder.

- Successful runs print a line such as `📸 Screenshot saved: screenshots/proof_test_after_interactions.png`.
- Files are written under `example/screenshots/`. Share these PNGs as proof (e.g., `example/screenshots/proof_test_after_interactions.png` from the latest run).
- Multiple screenshots can be taken inside a test; all will accumulate in that folder.

### In Test Code

The test driver (`test_driver/integration_test.dart`) is configured to save screenshots:

```dart
await integrationDriver(
  onScreenshot: (String screenshotName, List<int> screenshotBytes, [Map<String, Object?>? args]) async {
    final File image = File('screenshots/$screenshotName.png');
    await image.parent.create(recursive: true);
    await image.writeAsBytes(screenshotBytes);
    print('📸 Screenshot saved: ${image.path}');
    return true;
  },
);
```

### Capturing Screenshots in Tests

Use the `IntegrationTestWidgetsFlutterBinding` to capture screenshots:

```dart
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  testWidgets('My test with screenshot', (WidgetTester tester) async {
    // ... test setup and interactions ...
    
    // Capture screenshot
    await binding.takeScreenshot('my_test_screenshot');
    
    // Screenshot saved to: screenshots/my_test_screenshot.png
  });
}
```

## Test Interaction Patterns

### Mouse Interactions

```dart
// Create mouse gesture
final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);

// Hover over a position
await gesture.moveTo(Offset(300, 300));
await tester.pumpAndSettle();

// Click
await gesture.down(Offset(300, 300));
await gesture.up();

// Clean up
await gesture.removePointer();
```

### Keyboard Interactions

```dart
// Single key press
await tester.sendKeyEvent(LogicalKeyboardKey.numpadAdd);

// Hold and release key
await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
// ... do something while shift is held ...
await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
```

### Navigation

```dart
// Find and tap a widget
final buttonFinder = find.text('My Button');
await tester.tap(buttonFinder);
await tester.pumpAndSettle();

// Scroll to make widget visible
await tester.scrollUntilVisible(
  buttonFinder,
  100.0,
  scrollable: find.byType(Scrollable).first,
);
```

### Verify State

```dart
// Verify widget exists
expect(find.byType(BravenChart), findsOneWidget);

// Verify text is present
expect(find.text('Expected Text'), findsOneWidget);

// Verify widget count
expect(find.byType(CustomPaint), findsWidgets);
```

## Troubleshooting

### Error: "session not created: This version of ChromeDriver only supports Chrome version X"

**Solution:** Your ChromeDriver version doesn't match your Chrome version.

1. Check Chrome version (see Prerequisites)
2. Download matching ChromeDriver
3. Update the path in your start command

### Error: "Unable to start a WebDriver session"

**Solution:** ChromeDriver is not running on port 4444.

1. Start ChromeDriver in a separate terminal
2. Verify it says "ChromeDriver was started successfully on port 4444"
3. Make sure no other process is using port 4444

### Browser Opens But Test Fails

**Solution:** Check the test logs in the terminal for specific errors.

Common issues:
- Widget not found: Use `tester.printToConsole()` to debug
- Timing issues: Add more `await tester.pumpAndSettle()` calls
- Navigation not completing: Increase wait times

### Screenshots Not Saving

**Solution:** Verify the test driver is configured correctly.

1. Check `test_driver/integration_test.dart` has `onScreenshot` callback
2. Ensure `screenshots/` folder is writable
3. Check test logs for screenshot save errors

## Best Practices

1. **Use descriptive screenshot names** - Include test name and step
2. **Toggle proof pauses appropriately** - Pass `--dart-define=PROOF_PAUSES=false` for automation; keep them `true` when you want on-screen narration.
3. **Pump between interactions** - Always call `await tester.pumpAndSettle()` after interactions
4. **Wait for animations** - Add delays for visual verification when pauses are enabled
5. **Clean up resources** - Remove pointer gestures when done
6. **Verify state explicitly** - Don't assume interactions worked; verify with `expect()`

## Example: Complete Integration Test

```dart
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:braven_charts_example/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  testWidgets('Chart interaction test', (WidgetTester tester) async {
    // 1. Launch app
    app.main();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('01_app_launched');
    
    // 2. Navigate to chart screen
    final chartButton = find.text('Line Chart');
    await tester.tap(chartButton);
    await tester.pumpAndSettle();
    await binding.takeScreenshot('02_chart_screen');
    
    // 3. Interact with chart
    final chartFinder = find.byType(BravenChart);
    final chartCenter = tester.getCenter(chartFinder);
    
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.moveTo(chartCenter);
    await tester.pumpAndSettle();
    await binding.takeScreenshot('03_hover_chart');
    
    // 4. Verify state
    expect(find.byType(BravenChart), findsOneWidget);
    
    // 5. Clean up
    await gesture.removePointer();
  });
}
```

## CI/CD Integration

To run integration tests in CI/CD pipelines:

1. **Install Chrome** in your CI environment
2. **Install matching ChromeDriver**
3. **Start ChromeDriver** as a background service
4. **Run tests** with `flutter drive`
5. **Archive screenshots** as build artifacts

Example GitHub Actions:
```yaml
- name: Install ChromeDriver
  run: |
    # Download and install matching ChromeDriver
    
- name: Start ChromeDriver
  run: chromedriver --port=4444 &
  
- name: Run Integration Tests
  run: |
    cd example
    flutter drive --driver=test_driver/integration_test.dart \
                  --target=integration_test/proof_test.dart \
                  -d chrome
                  
- name: Upload Screenshots
  uses: actions/upload-artifact@v3
  with:
    name: integration-test-screenshots
    path: example/screenshots/
```

## Resources

- [Flutter Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [Integration Testing on Web](https://flutter.dev/to/integration-test-on-web)
- [ChromeDriver Documentation](https://chromedriver.chromium.org/)
- [Chrome for Testing Downloads](https://googlechromelabs.github.io/chrome-for-testing/)

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review test logs carefully
3. Verify Chrome and ChromeDriver versions match
4. See example tests in `example/integration_test/` for working patterns
