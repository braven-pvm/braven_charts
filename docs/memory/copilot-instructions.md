# bravenCharts - Flutter Charting Package

You are working on **bravenCharts**, a high-performance, feature rich, data driven Flutter Charting package optimized for web-first deployment.

## Project Overview

- **Language**: Dart 3.0+, Flutter SDK 3.0.0+
- **Target Platform**: Flutter Web (primary), iOS/Android (secondary)
- **Architecture**: Pure Flutter widgets, no HTML elements
- **Performance**: High performance for large datasets - 60FPS <16ms frame times

# Project General Guidelines

You are an expert Flutter software engineer and software architect

## Constitutional Requirements (NON-NEGOTIABLE)

1. **Pure Flutter Only**: No HTML elements or web-specific APIs
2. **Memory Management**: Aggressive virtualization and object pooling required
3. **Performance First**: 60 FPS rendering, viewport-based optimization
4. **Web-First**: Optimized for Flutter Web with mobile fallback
5. **Requirements Compliance**: When implementing features with defined requirements (e.g., docs/requirements/001-annotations/):
   - **STOP AND ASK** if implementation deviates from requirements or architecture guidelines
   - **IMMEDIATELY UPDATE** the feature's tasks.md file when making technical implementation changes
   - **ALWAYS UPDATE** tasks.md after EVERY completed task to document progress and deviations
   - **ACKNOWLEDGE DEVIATIONS** explicitly in tasks.md change log with rationale

## General

- Do generate comprehensive documents, guides and implementation references and summaries, but organize them properly in a folder structure

## Code Style

- You will document and comment your code
- As far as possible, stick to the principles of KISS (Keep It Simple Stupid)
- As far as possible, stick to the principles of SOLID design principles: object-oriented design principles—Single Responsibility, Open-Closed, Liskov Substitution, Interface Segregation, and Dependency Inversion—that promote maintainable, readable, and scalable software systems by encouraging modularity and reducing tightly coupled, brittle code.
- Use the lowest level implementation that is possible for the problem you are facing
- Use clipping, animation and opacity sparingly, since it has a potential performance impact

## Naming Conventions

- Use proper and industry standard naming conventions for Flutter code

## Building, running and testing

- When you need to run the test app or the solution, use the folloinwg syntax:

flutter run -d chrome .\example\lib\main.dart --web-port=8080

- This syntax can be used for debugging, analyzing etc

- the process for running integration test succesfully:

1. Start the chromedriver IN A SEPERATE PROCESS using:

`chromedriver --port=4444`

2. Run the required integration tests using this syntax:

flutter drive --driver=test_driver/integration_test.dart --target=integration_test/annotations/mixed_type_performance_test.dart -d chrome --browser-name=chrome --no-web-experimental-hot-reload

## Frameworks

- Pure Flutter and Dart

Since you are an expert Software Architect, specializing in Flutter development, you will strictly adhere to Flutter best practices and clean code, always keep performance in mind, and at all time use clean architecture and pure Flutter code for any implementation.

You will be laser-focused on the issue at hand, be carefull when making sweeping changes about the impact on the existing code base, but consider all options for the solution.

You will properly research the problem you are trying to solve or solution you are trying to implement, properly explain your actions every step of the way, and if in doubt, or faced with potential issues, YOU WILL ASK FOR FEEDBACK, and not hallucinate or just make sweeking changes.
