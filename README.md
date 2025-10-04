# Braven Charts

[![Pub Version](https://img.shields.io/pub/v/braven_charts)](https://pub.dev/packages/braven_charts)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Flutter Version](https://img.shields.io/badge/Flutter-%3E%3D3.10.0-blue.svg)](https://flutter.dev)

**Web-first Flutter charting library** with advanced annotation system, responsive design, and comprehensive testing framework.

##  Overview

Braven Charts is a high-performance, web-optimized charting library for Flutter applications. Built with a **web-first philosophy**, it provides:

-  **Web-Optimized** - Designed specifically for web performance and interactions
-  **Rich Chart Types** - Line, Bar, Pie, Scatter, and more
-  **Advanced Annotations** - Interactive chart annotations and markers
-  **Flexible Theming** - Comprehensive theming system
-  **Responsive Design** - 8 viewport sizes from mobile to ultrawide
-  **Test-Driven** - Comprehensive testing framework included
-  **Accessible** - WCAG 2.1 AA compliant

##  Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  braven_charts: ^0.1.0
```

Then run:

```bash
flutter pub get
```

##  Quick Start

```dart
import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

// Coming soon - chart implementation in progress
```

##  Documentation

### For Users
- [Getting Started Guide](docs/README.md) - Basic usage and examples
- [Chart Types](docs/architecture/features/) - Available chart types
- [Theming Guide](docs/architecture/features/THEMING_SYSTEM.md) - Customization options
- [Annotation System](docs/architecture/features/ANNOTATION_SYSTEM.md) - Interactive annotations

### For Contributors
- [Testing Guide](docs/testing/TESTING.md) - Running tests
- [Web Testing](docs/testing/TESTING_WEB.md) - Web-specific testing
- [Architecture](docs/architecture/) - System design and specifications
- [Development Setup](docs/DEVELOPMENT.md) - Environment setup

##  Testing

This project uses **Test-Driven Development (TDD)** with comprehensive test coverage:

```bash
# Run all tests
flutter test

# Run web-specific tests
flutter test test/web/

# Run integration tests on Chrome
./scripts/testing/run_chromedriver_tests.ps1
```

**Current Test Status:**  26/26 tests passing

See [Testing Documentation](docs/testing/) for details.

##  Project Structure

```
```
braven_charts/
├── lib/                          # Library source code
│   ├── src/                      # Internal implementation
│   └── braven_charts.dart        # Public API
├── test/                         # All testing files
│   ├── web/                      # Web-specific tests
│   ├── unit/                     # Unit tests
│   ├── golden/                   # Golden file tests
│   ├── performance/              # Performance tests
│   ├── integration/              # Integration test utilities
│   ├── integration_test/         # End-to-end tests
│   ├── test_driver/              # Test drivers
│   └── chromedriver/             # ChromeDriver for web testing
├── docs/                         # Documentation
│   ├── testing/                  # Testing guides
│   └── architecture/             # Architecture specs
└── scripts/                      # Utility scripts
    ├── testing/                  # Test runners
    └── setup/                    # Setup scripts
```
```

##  Development Status

###  Completed
- [x] Project structure and build system
- [x] Comprehensive testing framework (6 layers)
- [x] Web testing with ChromeDriver
- [x] Documentation structure
- [x] CI/CD foundation

###  In Progress
- [ ] Core chart components
- [ ] Annotation system implementation
- [ ] Theming system implementation

###  Planned
- [ ] Advanced chart types
- [ ] Performance optimizations
- [ ] Accessibility enhancements
- [ ] Example gallery
- [ ] API documentation

##  Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Development Workflow

1. **Clone & Setup**
   ```bash
   git clone <repository-url>
   cd braven_charts_v2.0
   flutter pub get
   ```

2. **Write Tests First** (TDD)
   ```bash
   # Create test in test/ directory
   flutter test --watch
   ```

3. **Implement Feature**
   ```bash
   # Write implementation in lib/
   flutter test
   ```

4. **Test on Web**
   ```bash
   ./scripts/testing/run_chromedriver_tests.ps1
   ```

##  License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

##  Acknowledgments

- Built with [Flutter](https://flutter.dev)
- Testing powered by [integration_test](https://pub.dev/packages/integration_test)
- Web testing with [ChromeDriver](https://chromedriver.chromium.org/)

##  Contact

- **Issues**: [GitHub Issues](https://github.com/yourusername/braven_charts/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/braven_charts/discussions)

---

**Ready for web-first chart development!** 
