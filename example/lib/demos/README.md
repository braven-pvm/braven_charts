# Task Demos

This folder contains **standalone demo files** for visual verification of specific tasks.

## Purpose

When a task requires visual verification, a minimal self-contained demo is created here
rather than modifying the main example app. This provides:

1. **Isolation** - Each demo tests ONE feature
2. **Independence** - Can be run directly without navigation
3. **Clarity** - Clear what's being tested visually
4. **History** - Past demos serve as documentation

## Naming Convention

```
task_NNN_feature_name_demo.dart
```

Examples:
- `task_012_dual_axis_integration_demo.dart`
- `task_014_synchronized_scrolling_demo.dart`

## How to Run

From the `example/` directory:

```powershell
# Using flutter_agent
python ..\tools\flutter_agent\flutter_agent.py run lib/demos/task_NNN_demo.dart -d chrome

# Or directly with flutter
flutter run -t lib/demos/task_NNN_demo.dart -d chrome
```

## Screenshot

After running, use flutter_agent to capture:

```powershell
python ..\tools\flutter_agent\flutter_agent.py screenshot
```

## Note

Not all tasks require demos. The three-category system determines this:

| Category       | Demo Required? |
|----------------|----------------|
| INFRASTRUCTURE | ❌ No (premature) |
| INTEGRATION    | ✅ Yes |
| VISUAL         | ✅ Yes |

Infrastructure tasks create classes that aren't yet wired into the main widget.
Visual verification happens in later integration tasks.
