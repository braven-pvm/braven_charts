import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';

import 'emitter.dart';
import 'enforcement.dart';
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
/// 2. resolve the PUBLIC BARREL and hand its export namespace to the emitter,
///    which refuses to generate for a class the barrel does not export
///    (generated files import only the barrel, so such a class would emit an
///    extension full of `undefined_class`);
/// 3. emit the fluent extensions through the [SurfaceEmitter] seam
///    ([SurfaceEmitter.emitLibrary], which formats with dart_style);
/// 4. write the output ONLY when at least one annotated class yields
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
    final barrel = await _barrel(buildStep);
    final model = await const AnalyzerSurfaceReader().read(
      library,
      reachable: barrel == null ? const [] : reachableClasses([barrel]),
    );
    if (model.classes.isEmpty) return;

    final SurfaceEmitter emitter = FluentEmitter(
      exportedNames: barrel?.exportNamespace.definedNames2.keys.toSet(),
    );
    final source = emitter.emitLibrary(model);
    if (source == null) return;

    final gap = countParamsWithoutClearVerb(model);
    if (gap > 0) {
      log.info(
        'surface_gen: ${inputId.path}: $gap nullable parameter(s) have no '
        'clear verb — this class\'s copyWith cannot unset them; construct a '
        'new instance to reset.',
      );
    }

    await buildStep.writeAsString(buildStep.allowedOutputs.single, source);
  }

  /// The public barrel library, or `null` when there is none.
  ///
  /// It supplies BOTH halves of "reachable": the name set the emitter's
  /// export guard needs, and the class set the reader's slicing diagnostic
  /// scans. The generated fluent barrel re-exports this one and defines no
  /// classes of its own, so the core barrel is the whole reachable surface.
  Future<LibraryElement?> _barrel(BuildStep buildStep) async {
    final barrelId = AssetId(
      buildStep.inputId.package,
      'lib/${buildStep.inputId.package}.dart',
    );
    if (!await buildStep.canRead(barrelId)) return null;
    return buildStep.resolver.libraryFor(barrelId);
  }
}

/// Generates the opt-in fluent barrel from the set of generated files.
///
/// A hand-written barrel does not survive ~40 generated files: a file nobody
/// exports is invisible dead code and nothing guards it. Generating it means
/// the existing CI regenerate-and-diff gate covers barrel drift too.
///
/// Runs in a later build phase than [SurfaceGenBuilder] via
/// `required_inputs: ['_fluent.dart']`, so `findAssets` sees the freshly
/// written extensions.
class FluentBarrelBuilder implements Builder {
  const FluentBarrelBuilder();

  static const String _output = 'braven_charts_fluent.dart';

  @override
  Map<String, List<String>> get buildExtensions => const {
        r'$lib$': [_output],
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    final package = buildStep.inputId.package;
    final assets = await buildStep
        .findAssets(Glob('lib/src/fluent/generated/**_fluent.dart'))
        .toList();
    if (assets.isEmpty) return;

    final exports = [
      for (final asset in assets) asset.path.substring('lib/'.length),
    ]..sort();

    final buffer = StringBuffer()
      ..writeln('/// Opt-in fluent modifier surface for braven_charts.')
      ..writeln('///')
      ..writeln('/// GENERATED by surface_gen — do not edit. This barrel is '
          'derived from the')
      ..writeln('/// set of generated `*_fluent.dart` files, so a generated '
          'extension can never')
      ..writeln('/// go unexported. Regenerate: dart run build_runner build')
      ..writeln('///')
      ..writeln('/// Exports the full core barrel plus the generated fluent '
          'extensions, so a')
      ..writeln('/// single import unlocks chained modifiers on the config '
          'surface:')
      ..writeln('///')
      ..writeln('/// ```dart')
      ..writeln("/// import 'package:$package/$_output';")
      ..writeln('///')
      ..writeln('/// final crosshair = const CrosshairConfig()')
      ..writeln('///     .withMode(CrosshairMode.vertical)')
      ..writeln('///     .withSnapRadius(24);')
      ..writeln('/// ```')
      ..writeln('///')
      ..writeln('/// Every chain step is an ordinary `copyWith` call '
          'returning an ordinary')
      ..writeln('/// config instance; importing this barrel changes no '
          'behavior of the core')
      ..writeln('/// API. Consumers who don\'t want the extensions keep '
          'importing')
      ..writeln('/// `package:$package/$package.dart` and never see them.')
      ..writeln('library;')
      ..writeln()
      ..writeln("export '$package.dart';");
    for (final export in exports) {
      buffer.writeln("export '$export';");
    }

    await buildStep.writeAsString(
      buildStep.allowedOutputs.single,
      buffer.toString(),
    );
  }
}
