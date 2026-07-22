/// Builder factories for the braven_charts surface generator.
///
/// Referenced from `tool/surface_gen/build.yaml`; the root package's
/// `build.yaml` enables the builder scoped to `lib/src/**`.
library;

import 'package:build/build.dart';

import 'src/builder.dart';

/// Entry point declared in `build.yaml` (`builder_factories`).
Builder surfaceGenBuilder(BuilderOptions options) => const SurfaceGenBuilder();

/// Aggregating barrel builder, declared in `build.yaml` as `fluent_barrel`.
///
/// Runs after [surfaceGenBuilder] (`required_inputs: ['_fluent.dart']`) and
/// regenerates `lib/braven_charts_fluent.dart` from the generated file set.
Builder fluentBarrelBuilder(BuilderOptions options) =>
    const FluentBarrelBuilder();

/// Aggregating smoke-test builder, declared in `build.yaml` as `smoke_test`.
///
/// Runs after [surfaceGenBuilder] (`required_inputs: ['_fluent.dart']`) and
/// regenerates `test/fluent/fluent_smoke_generated_test.dart`, which invokes
/// every generated verb once so that compilation is the assertion.
Builder smokeTestBuilder(BuilderOptions options) => const SmokeTestBuilder();

/// Aggregating AI-schema builder, declared in `build.yaml` as
/// `surface_definitions`.
///
/// Runs after [surfaceGenBuilder] (`required_inputs: ['_fluent.dart']`) and
/// regenerates `lib/src/ai/generated/surface_definitions.dart`: the structural
/// JSON-Schema `$defs` that `ChartToolSchema.surfaceDefinitions` exposes
/// ALONGSIDE the hand-written tool literals.
Builder surfaceDefinitionsBuilder(BuilderOptions options) =>
    const SurfaceDefinitionsBuilder();
