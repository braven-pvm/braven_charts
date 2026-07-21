import 'package:build/build.dart';

import 'fluent_emitter.dart';
import 'surface_reader.dart';

/// Reads `@chartSurface` annotations from the braven_charts config surface
/// and emits the generated fluent extensions (and, later, the AI schema
/// mirror).
///
/// Pipeline per source library under `lib/src/**`:
///
/// 1. resolve the library and read every annotated class into a
///    `SurfaceModel` ([AnalyzerSurfaceReader]);
/// 2. emit the fluent extensions ([FluentEmitter.emitLibrary], which formats
///    with dart_style);
/// 3. write the output ONLY when at least one annotated class yields
///    members — un-annotated libraries produce no file.
///
/// The capture-group build extension preserves source subdirectories
/// (`lib/src/models/foo.dart` -> `lib/src/fluent/generated/models/
/// foo_fluent.dart`), which keeps the 1:1 input/output mapping
/// collision-proof for same-named files in different directories. One
/// generated file per SOURCE file; a source file with several annotated
/// classes yields several extensions in that one file.
///
/// Outputs are `build_to: source` and checked in; the root `build.yaml`
/// excludes `lib/src/fluent/generated/**` from inputs, and the guard below
/// keeps the builder inert on its own outputs even without that exclude.
class SurfaceGenBuilder implements Builder {
  const SurfaceGenBuilder();

  static const String _generatedPrefix = 'lib/src/fluent/generated/';

  @override
  Map<String, List<String>> get buildExtensions => const {
        '^lib/src/{{}}.dart': ['lib/src/fluent/generated/{{}}_fluent.dart'],
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    final inputId = buildStep.inputId;
    if (inputId.path.startsWith(_generatedPrefix)) return;
    if (!await buildStep.resolver.isLibrary(inputId)) return;

    final library = await buildStep.resolver.libraryFor(inputId);
    final model = await const AnalyzerSurfaceReader().read(library);
    final source = const FluentEmitter().emitLibrary(model);
    if (source == null) return;

    await buildStep.writeAsString(buildStep.allowedOutputs.single, source);
  }
}
