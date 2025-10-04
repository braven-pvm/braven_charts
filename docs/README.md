# Braven Charts Documentation

Welcome to the Braven Charts documentation! This directory contains all documentation for using and contributing to the Braven Charts library.

## 📚 Documentation Structure

### For Users

#### Getting Started
- **Quick Start** - See main [README.md](../README.md)
- **Installation** - Add braven_charts to your project
- **Basic Usage** - Coming soon with first chart implementation

#### Features
- [Annotation System](architecture/features/ANNOTATION_SYSTEM.md) - Interactive chart annotations
- [Theming System](architecture/features/THEMING_SYSTEM.md) - Customization and styling

### For Developers

#### Testing
- [Testing Guide](testing/TESTING.md) - Comprehensive testing framework (614 lines)
- [Web Testing Guide](testing/TESTING_WEB.md) - Web-specific testing (614 lines)
- [ChromeDriver Setup](testing/CHROMEDRIVER_SETUP.md) - Web integration testing setup
- [Quick Start](testing/WEB_TESTING_QUICK_START.md) - Quick testing reference

#### Architecture
- [Architecture Overview](architecture/README.md) - System design overview
- [Vision](architecture/vision/) - Project goals and philosophy
- [Requirements](architecture/requirements/) - Functional and technical requirements
- [Specifications](architecture/specs/) - Detailed architecture specs
  - [Annotation System Architecture](architecture/specs/ANNOTATION_SYSTEM_ARCHITECTURE.md)
  - [Performance Architecture](architecture/specs/PERFORMANCE_ARCHITECTURE.md)
  - [Universal Coordinate Transformer](architecture/specs/UNIVERSAL_COORDINATE_TRANSFORMER.md)
  - [Universal Marker System](architecture/specs/UNIVERSAL_MARKER_SYSTEM.md)
- [Lessons Learned](architecture/lessons-learned/) - Critical implementation insights

## 🧪 Testing Philosophy

Braven Charts is built using **Test-Driven Development (TDD)**. We have 6 layers of testing:

1. **Unit Tests** - Individual component testing
2. **Widget Tests** - UI component testing
3. **Integration Tests** - Component interaction testing
4. **Golden Tests** - Visual regression testing
5. **Performance Tests** - Benchmarking and optimization
6. **Web Integration Tests** - Browser-based E2E testing

**Current Status:** ✅ 26/26 tests passing

## 🏗️ Architecture Highlights

### Web-First Design
- Optimized for web performance (50ms render target)
- Mouse and keyboard interaction support
- 8 responsive viewport sizes (375x667 to 3440x1440)
- Touch and gesture support for mobile web

### Key Systems
- **Universal Coordinate Transformer** - Consistent coordinate system across chart types
- **Universal Marker System** - Flexible annotation framework
- **Theming System** - Comprehensive customization
- **Performance Monitoring** - Built-in performance metrics

## 🚀 Quick Links

### Development
- [Development Setup](DEVELOPMENT.md) - Environment configuration
- [Contributing Guide](../CONTRIBUTING.md) - How to contribute
- [Testing Scripts](../scripts/testing/) - Automated test runners

### Testing
```bash
# Run all tests
flutter test

# Web tests only
flutter test test/web/

# Integration tests on Chrome
./scripts/testing/run_chromedriver_tests.ps1
```

### Architecture Decisions
- **Web-First** - Optimized for web, mobile-compatible
- **TDD Approach** - Tests written before implementation
- **Modular Design** - Independent, reusable components
- **Performance Focus** - 50ms render, 16ms interaction targets

## 📖 Reading Guide

### New Users
1. Start with main [README.md](../README.md)
2. Review [Architecture Overview](architecture/README.md)
3. Check [Features](architecture/features/) for capabilities
4. Explore examples (coming soon)

### Contributors
1. Read [Development Setup](DEVELOPMENT.md)
2. Study [Testing Guide](testing/TESTING.md)
3. Review [Architecture Specs](architecture/specs/)
4. Check [Lessons Learned](architecture/lessons-learned/)
5. Follow TDD workflow in [README.md](../README.md)

### Package Maintainers
1. Review [Architecture](architecture/)
2. Check [Requirements](architecture/requirements/)
3. Monitor [Lessons Learned](architecture/lessons-learned/)
4. Update documentation as features evolve

## 🎯 Documentation Standards

All documentation in this project follows these principles:

- **Clear Examples** - Code samples for all features
- **Current** - Updated with each major change
- **Searchable** - Organized for easy navigation
- **Comprehensive** - Covers all use cases
- **Tested** - All code examples are tested

## 🔄 Documentation Updates

This documentation is a living resource. As the project evolves:

- New features get documented before release
- Examples are tested and verified
- Architecture docs reflect current implementation
- Lessons learned are added continuously

---

**Last Updated:** October 4, 2025  
**Documentation Version:** 0.1.0  
**Project Status:** Ready for development
