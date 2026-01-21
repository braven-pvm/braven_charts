# Contributing to Braven Charts

Thank you for your interest in contributing to Braven Charts! We welcome contributions from the community.

## 🤝 How to Contribute

### Reporting Issues

Found a bug or have a feature request?

1. Check [existing issues](https://github.com/yourusername/braven_charts/issues)
2. If it doesn't exist, [create a new issue](https://github.com/yourusername/braven_charts/issues/new)
3. Use the appropriate template (Bug Report or Feature Request)
4. Provide as much detail as possible

### Pull Requests

1. **Fork** the repository
2. **Create a branch** for your feature (`git checkout -b feature/amazing-feature`)
3. **Write tests first** (TDD approach)
4. **Implement** your feature
5. **Ensure all tests pass** (`flutter test`)
6. **Commit** your changes (`git commit -m 'feat: Add amazing feature'`)
7. **Push** to your branch (`git push origin feature/amazing-feature`)
8. **Open a Pull Request**

## 🧪 Test-Driven Development

Braven Charts follows strict TDD. **All code contributions must include tests.**

### Writing Tests

1. **Write the test first**

   ```dart
   // test/unit/my_feature_test.dart
   test('should do something amazing', () {
     final result = myFeature.doSomething();
     expect(result, equals('amazing'));
   });
   ```

2. **See it fail**

   ```bash
   flutter test test/unit/my_feature_test.dart
   ```

3. **Write minimum code** to pass

   ```dart
   // lib/src/my_feature.dart
   String doSomething() => 'amazing';
   ```

4. **Refactor** while keeping tests green

### Test Requirements

- ✅ **Unit tests** for all business logic
- ✅ **Widget tests** for all UI components
- ✅ **Integration tests** for user workflows
- ✅ **Web tests** for web-specific functionality
- ✅ **Golden tests** for visual regression
- ✅ **Performance tests** for critical paths

## 📝 Code Style

### Dart Guidelines

Follow [Effective Dart](https://dart.dev/guides/language/effective-dart):

```dart
// ✅ Good
class ChartComponent extends StatelessWidget {
  const ChartComponent({
    super.key,
    required this.data,
  });

  final ChartData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: CustomPaint(
        painter: ChartPainter(data),
      ),
    );
  }
}

// ❌ Bad
class chart_component extends StatelessWidget {
  chart_component(this.data);
  var data;
  build(ctx) => Container(child: CustomPaint(painter: ChartPainter(data)));
}
```

### Documentation

All public APIs must be documented:

````dart
/// A reusable chart component for displaying time-series data.
///
/// The [TimeSeriesChart] accepts [ChartData] and renders it as a
/// line or area chart based on the [chartType] parameter.
///
/// Example:
/// ```dart
/// TimeSeriesChart(
///   data: myData,
///   chartType: ChartType.line,
/// )
/// ```
///
/// See also:
/// * [ChartData] for data structure requirements
/// * [ChartType] for available chart types
class TimeSeriesChart extends StatelessWidget {
  // Implementation
}
````

#### Documentation File Naming (Mandatory)

- Documentation filenames must be **lowercase** only (no uppercase letters).
- Use `snake_case` for multi-word filenames.
- If a document is renamed, **update every internal link** that references it.

### Naming Conventions

- **Classes:** `PascalCase` (e.g., `LineChart`)
- **Methods/Variables:** `camelCase` (e.g., `renderChart`)
- **Constants:** `camelCase` (e.g., `maxDataPoints`)
- **Private:** `_leadingUnderscore` (e.g., `_internalMethod`)
- **Files:** `snake_case` (e.g., `line_chart.dart`)

## 🎯 Commit Messages

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `perf`: Performance improvements
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

### Examples

```
feat(charts): Add pie chart component

Implements basic pie chart with:
- Data visualization
- Legend support
- Interactive tooltips

Closes #42
```

```
fix(annotations): Correct positioning on rotated charts

Fixed calculation error in coordinate transformer
when chart rotation is applied.

Fixes #123
```

```
test(web): Add mouse interaction tests

Added tests for:
- Hover behavior
- Click handling
- Drag gestures
```

## 🏗️ Architecture Guidelines

### Web-First Philosophy

All features must work optimally on web:

```dart
// ✅ Good - Web-optimized
class ChartInteraction {
  void handlePointer(PointerEvent event) {
    if (event is PointerHoverEvent) {
      // Web mouse hover
    } else if (event is PointerDownEvent) {
      // Touch or click
    }
  }
}

// ❌ Bad - Mobile-only thinking
class ChartInteraction {
  void handleTap(TapDetails details) {
    // Doesn't support mouse hover
  }
}
```

### Performance Standards

- **Render time:** ≤ 50ms (web target)
- **Interaction response:** ≤ 16ms (60fps)
- **Memory:** Efficient data structures
- **Bundle size:** Minimize dependencies

### Accessibility

All components must support:

- ✅ Keyboard navigation
- ✅ Screen readers (ARIA labels)
- ✅ High contrast mode
- ✅ Configurable text sizes
- ✅ WCAG 2.1 AA compliance

## 📦 Pull Request Checklist

Before submitting your PR, ensure:

- [ ] Tests are written and passing
- [ ] Code follows style guidelines
- [ ] Documentation is updated
- [ ] Commit messages follow conventions
- [ ] No breaking changes (or documented)
- [ ] All CI checks pass
- [ ] Code is reviewed (self-review first)

### PR Template

```markdown
## Description

Brief description of changes

## Type of Change

- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing

- [ ] Unit tests added/updated
- [ ] Widget tests added/updated
- [ ] Integration tests added/updated
- [ ] Web tests added/updated
- [ ] All tests passing

## Checklist

- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No console errors/warnings
```

## 🔍 Code Review Process

### What Reviewers Look For

1. **Tests First**
   - Are tests comprehensive?
   - Do they test the right things?
   - Do they follow TDD principles?

2. **Code Quality**
   - Clean, readable code
   - Proper error handling
   - Performance considerations
   - No code smells

3. **Documentation**
   - Public APIs documented
   - Complex logic explained
   - Examples provided

4. **Web Compatibility**
   - Works on all browsers
   - Responsive design
   - Mouse/keyboard support

### Review Timeline

- **Initial response:** Within 2 business days
- **Full review:** Within 1 week
- **Revisions:** Iterate as needed

## 🐛 Debugging Contributions

### Running Tests Locally

```bash
# All tests
flutter test

# Specific file
flutter test test/unit/my_test.dart

# Watch mode
flutter test --watch

# With coverage
flutter test --coverage
```

### Web Testing

```bash
# Unit tests
flutter test test/web/

# Integration tests
./scripts/testing/run_chromedriver_tests.ps1
```

## 📊 Performance Testing

Add performance tests for new features:

```dart
test('renders large dataset efficiently', () {
  final data = generateLargeDataset(10000);
  final stopwatch = Stopwatch()..start();

  final chart = LineChart(data: data);
  // Render chart

  stopwatch.stop();
  expect(stopwatch.elapsedMilliseconds, lessThan(50));
});
```

## 🎨 Visual Changes

For UI changes, include:

1. **Before/After screenshots**
2. **Golden test updates** (if applicable)
3. **Browser compatibility** testing results
4. **Accessibility** verification

## 📚 Documentation Contributions

Documentation is as important as code!

- Improve existing docs
- Add examples
- Fix typos
- Create tutorials
- Update architecture docs

See [docs/readme.md](docs/readme.md) for structure.

## 🆘 Getting Help

- **Questions?** Open a [Discussion](https://github.com/yourusername/braven_charts/discussions)
- **Stuck?** Ask in your PR or issue
- **Chat:** Join our community (link TBD)

## 📜 License

By contributing, you agree that your contributions will be licensed under the MIT License.

## 🙏 Recognition

Contributors are recognized in:

- Release notes
- changelog.md
- Project documentation

Thank you for making Braven Charts better! 🎉
