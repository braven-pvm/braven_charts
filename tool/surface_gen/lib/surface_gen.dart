/// Builder factories for the braven_charts surface generator.
///
/// Referenced from `tool/surface_gen/build.yaml`; the root package's
/// `build.yaml` enables the builder scoped to `lib/src/**`.
library;

import 'package:build/build.dart';

import 'src/builder.dart';

/// Entry point declared in `build.yaml` (`builder_factories`).
Builder surfaceGenBuilder(BuilderOptions options) => const SurfaceGenBuilder();
