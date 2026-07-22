import '../artifacts/chart_artifact_diagnostics.dart';
import '../artifacts/chart_document_hydrator.dart';
import '../artifacts/chart_document_extractor.dart';
import '../artifacts/chart_runtime_bindings.dart';
import 'chart_config_dart_emitter.dart';
import 'chart_source_models.dart';
import 'dart_source_writer.dart';

/// Generates direct, readable Dart configuration for a captured chart.
///
/// Generation is deterministic and uses only public `braven_charts` model
/// constructors. Runtime-owned values and intentionally omitted data are
/// reported explicitly rather than being silently discarded.
abstract final class ChartDartSourceGenerator {
  static ChartArtifactResult<ChartGeneratedSource> generate(
    ChartDocumentSnapshot snapshot, {
    ChartDartSourceOptions options = const ChartDartSourceOptions(),
  }) {
    if (!DartSourceWriter.isIdentifier(options.variableName)) {
      return ChartArtifactFailure(
        error: ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.invalidArtifact,
          message:
              'Source variable name "${options.variableName}" is not a valid Dart identifier.',
          path: r'$.sourceOptions.variableName',
        ),
      );
    }

    final hydrated = ChartDocumentHydrator.hydrateDocument(
      snapshot.document,
      viewState: snapshot.viewState,
      options: ChartHydrationOptions(
        restoreViewState: options.includeViewState,
      ),
      runtimeBindings: ChartRuntimeBindings(formatters: options.formatters),
    );
    if (hydrated case ChartArtifactFailure<HydratedChartConfiguration>()) {
      return ChartArtifactFailure(
        error: hydrated.error,
        warnings: hydrated.warnings,
      );
    }

    final success =
        hydrated as ChartArtifactSuccess<HydratedChartConfiguration>;
    final emitter = ChartConfigDartEmitter(
      snapshot: snapshot,
      configuration: success.value,
      options: options,
    );
    final generated = emitter.generate();
    return ChartArtifactSuccess(
      value: generated,
      warnings: success.warnings
          .where(
            (warning) =>
                !_isExpectedRuntimeInteractionOmission(snapshot, warning),
          )
          .toList(growable: false),
    );
  }

  static bool _isExpectedRuntimeInteractionOmission(
    ChartDocumentSnapshot snapshot,
    ChartArtifactWarning warning,
  ) {
    if (snapshot.document.interaction.requiredBindings.isEmpty ||
        warning.code != ChartArtifactDiagnosticCodes.runtimeBindingRequired) {
      return false;
    }
    return (warning.path?.startsWith(
              r'$.interaction.configuration.callbacks.',
            ) ??
            false) ||
        warning.path == r'$.interaction.configuration.valueSummary.content';
  }
}
