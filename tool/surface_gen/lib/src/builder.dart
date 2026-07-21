import 'package:build/build.dart';

/// Reads `@chartSurface` annotations from the braven_charts config surface
/// and emits the generated fluent extensions (and, later, the AI schema
/// mirror).
///
/// Task 1 scaffold: the builder is wired into the root `build.yaml` but is a
/// no-op until the `SurfaceReader` (Task 2) and emitters (Task 3) land.
class SurfaceGenBuilder implements Builder {
  const SurfaceGenBuilder();

  @override
  Map<String, List<String>> get buildExtensions => const {
        '^lib/src/{{}}.dart': ['lib/src/fluent/generated/{{}}_fluent.dart'],
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    // No-op until Task 3 wires the reader and fluent emitter together.
  }
}
