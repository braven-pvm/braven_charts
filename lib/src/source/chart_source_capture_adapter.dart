import '../artifacts/chart_artifact_diagnostics.dart';
import '../artifacts/chart_document_extractor.dart';
import '../artifacts/chart_interaction_document_codec.dart';
import '../artifacts/chart_runtime_bindings.dart';
import '../artifacts/json_value.dart';
import '../artifacts/radial_formatter_document_descriptors.dart';
import '../models/chart_series.dart';
import '../models/chart_annotation.dart';
import '../models/bar_chart_style.dart';
import '../models/data_point_label_config.dart';
import '../models/donut_chart_series.dart';
import '../models/pie_chart_config.dart';
import '../models/pie_chart_series.dart';
import '../models/polar_column_chart_series.dart';

/// Builds source-only extraction options for runtime-owned chart values.
///
/// Portable artifact extraction remains fail-closed. This adapter is used only
/// by the generated-source path, where callbacks and formatters are represented
/// by stable placeholder descriptors and explicit generator diagnostics.
abstract final class ChartSourceCaptureAdapter {
  static ChartSourceCaptureRequest adapt({
    required ChartDocumentExtractionSource source,
    required ChartDocumentExtractOptions options,
  }) {
    final interactionDescriptors = <String, JsonObjectValue>{
      ...options.interactionBindingDescriptors,
    };
    final interaction = source.interaction;

    void describeInteraction(String field, bool isPresent) {
      if (isPresent) {
        interactionDescriptors.putIfAbsent(
          field,
          () => _placeholder('interaction.$field'),
        );
      }
    }

    describeInteraction(
      ChartInteractionDocumentCodec.tooltipBuilderBinding,
      interaction.tooltip.customBuilder != null,
    );
    describeInteraction(
      ChartInteractionDocumentCodec.dataPointTapBinding,
      interaction.onDataPointTap != null,
    );
    describeInteraction(
      ChartInteractionDocumentCodec.dataPointHoverBinding,
      interaction.onDataPointHover != null,
    );
    describeInteraction(
      ChartInteractionDocumentCodec.dataPointLongPressBinding,
      interaction.onDataPointLongPress != null,
    );
    describeInteraction(
      ChartInteractionDocumentCodec.selectionChangedBinding,
      interaction.onSelectionChanged != null,
    );
    describeInteraction(
      ChartInteractionDocumentCodec.zoomChangedBinding,
      interaction.onZoomChanged != null,
    );
    describeInteraction(
      ChartInteractionDocumentCodec.panChangedBinding,
      interaction.onPanChanged != null,
    );
    describeInteraction(
      ChartInteractionDocumentCodec.viewportChangedBinding,
      interaction.onViewportChanged != null,
    );
    describeInteraction(
      ChartInteractionDocumentCodec.crosshairChangedBinding,
      interaction.onCrosshairChanged != null,
    );
    describeInteraction(
      ChartInteractionDocumentCodec.tooltipChangedBinding,
      interaction.onTooltipChanged != null,
    );
    describeInteraction(
      ChartInteractionDocumentCodec.keyboardActionBinding,
      interaction.onKeyboardAction != null,
    );

    final yAxisDescriptors = <String, JsonObjectValue>{
      ...options.yAxisFormatterDescriptors,
    };
    for (final axis in source.axes) {
      if (axis.labelFormatter != null) {
        yAxisDescriptors.putIfAbsent(
          axis.id,
          () => _formatterPlaceholder('axis.${axis.id}.labelFormatter'),
        );
      }
    }

    final radialDescriptors = <String, RadialFormatterDocumentDescriptors>{
      ...options.radialFormatterDescriptors,
    };
    for (final series in source.allSeries) {
      final generated = _radialDescriptors(series);
      if (generated == null) continue;
      final supplied = radialDescriptors[series.id];
      radialDescriptors[series.id] = RadialFormatterDocumentDescriptors(
        value: supplied?.value ?? generated.value,
        percentage: supplied?.percentage ?? generated.percentage,
        radius: supplied?.radius ?? generated.radius,
        center: supplied?.center ?? generated.center,
      );
    }

    final adaptedOptions = ChartDocumentExtractOptions(
      documentId: options.documentId,
      dataScope: options.dataScope,
      selectionProjection: options.selectionProjection,
      includeViewState: options.includeViewState,
      dataStorage: options.dataStorage,
      themeMode: options.themeMode,
      themeReference: options.themeReference,
      xAxisFormatterDescriptor:
          options.xAxisFormatterDescriptor ??
          (source.xAxis.labelFormatter == null
              ? null
              : _formatterPlaceholder('axis.x.labelFormatter')),
      yAxisFormatterDescriptors: yAxisDescriptors,
      interactionBindingDescriptors: interactionDescriptors,
      radialFormatterDescriptors: radialDescriptors,
      concentricCenterFormatterDescriptor:
          options.concentricCenterFormatterDescriptor ??
          (source.concentricDonutConfig?.centerContent.valueFormatter == null
              ? null
              : _formatterPlaceholder('concentric.center.value')),
      maxSnapshotAttempts: options.maxSnapshotAttempts,
    );
    final warnings = <ChartArtifactWarning>[];
    return ChartSourceCaptureRequest(
      source: _withoutUnsupportedCallbacks(source, warnings),
      options: adaptedOptions,
      warnings: warnings,
    );
  }

  static ChartDocumentExtractionSource _withoutUnsupportedCallbacks(
    ChartDocumentExtractionSource source,
    List<ChartArtifactWarning> warnings,
  ) {
    final warnedPaths = <String>{};
    late ChartSeries Function(ChartSeries series) sanitize;
    late ChartAnnotation Function(ChartAnnotation annotation)
    sanitizeAnnotation;
    sanitizeAnnotation = (ChartAnnotation annotation) {
      if (annotation is! LegendAnnotation) return annotation;
      if (annotation.onSeriesToggle != null) {
        const path = r'$.annotations.legend.onSeriesToggle';
        if (warnedPaths.add(path)) {
          warnings.add(
            const ChartArtifactWarning(
              code: ChartArtifactDiagnosticCodes.runtimeBindingRequired,
              message:
                  'The canvas legend toggle callback is runtime-owned and is represented by a source placeholder.',
              path: path,
            ),
          );
        }
      }
      return LegendAnnotation(
        id: annotation.id,
        label: annotation.label,
        zIndex: annotation.zIndex,
        series: annotation.series.map(sanitize).toList(growable: false),
        trendAnnotations: annotation.trendAnnotations,
        sizeScale: annotation.sizeScale,
        colorScale: annotation.colorScale,
        opacityScale: annotation.opacityScale,
        categoryScale: annotation.categoryScale,
        legendStyle: annotation.legendStyle,
        hiddenSeriesIds: annotation.hiddenSeriesIds,
        customPosition: annotation.customPosition,
      );
    };

    sanitize = (ChartSeries series) {
      final withoutCallbacks = _withoutUnsupportedSeriesCallbacks(
        series,
        warnings,
        warnedPaths,
      );
      final annotations = withoutCallbacks.annotations
          .map(sanitizeAnnotation)
          .toList(growable: false);
      return switch (withoutCallbacks) {
        LineChartSeries() => withoutCallbacks.copyWith(
          annotations: annotations,
        ),
        ScatterChartSeries() => withoutCallbacks.copyWith(
          annotations: annotations,
        ),
        AreaChartSeries() => withoutCallbacks.copyWith(
          annotations: annotations,
        ),
        BarChartSeries() => withoutCallbacks.copyWith(annotations: annotations),
        DonutChartSeries() => withoutCallbacks,
        PieChartSeries() => withoutCallbacks,
        PolarColumnChartSeries() => withoutCallbacks,
        ChartSeries() => withoutCallbacks.copyWith(annotations: annotations),
      };
    };

    return ChartDocumentExtractionSource(
      allSeries: source.allSeries.map(sanitize),
      visibleSeries: source.visibleSeries.map(sanitize),
      declaredSeries: source.declaredSeries.map(sanitize),
      annotations: source.annotations.map(sanitizeAnnotation),
      xAxis: source.xAxis,
      axes: source.axes,
      theme: source.theme,
      themeReference: source.themeReference,
      interaction: source.interaction,
      legendVisible: source.legendVisible,
      legendStyle: source.legendStyle,
      grid: source.grid,
      normalizationMode: source.normalizationMode,
      title: source.title,
      subtitle: source.subtitle,
      width: source.width,
      height: source.height,
      concentricDonutConfig: source.concentricDonutConfig,
      polarChartConfig: source.polarChartConfig,
      selectionSnapshot: source.selectionSnapshot,
      backgroundColor: source.backgroundColor,
      showToolbar: source.showToolbar,
      interactiveAnnotations: source.interactiveAnnotations,
      maxAxesPerSide: source.maxAxesPerSide,
      axisSwapMode: source.axisSwapMode,
      viewState: source.viewState,
    );
  }

  static ChartSeries _withoutUnsupportedSeriesCallbacks(
    ChartSeries series,
    List<ChartArtifactWarning> warnings,
    Set<String> warnedPaths,
  ) {
    void warn(String path, String label) {
      if (!warnedPaths.add(path)) return;
      warnings.add(
        ChartArtifactWarning(
          code: ChartArtifactDiagnosticCodes.runtimeBindingRequired,
          message:
              '$label is runtime-owned and is represented by a source placeholder.',
          path: path,
        ),
      );
    }

    switch (series) {
      case LineChartSeries(dataPointLabels: final labels?)
          when labels.formatter != null:
        warn(
          '\$.series.${series.id}.dataPointLabels.formatter',
          'The data-point label formatter',
        );
        return series.copyWith(dataPointLabels: _withoutLabelFormatter(labels));
      case AreaChartSeries(dataPointLabels: final labels?)
          when labels.formatter != null:
        warn(
          '\$.series.${series.id}.dataPointLabels.formatter',
          'The data-point label formatter',
        );
        return series.copyWith(dataPointLabels: _withoutLabelFormatter(labels));
      case ScatterChartSeries(dataPointLabels: final labels?)
          when labels.formatter != null:
        warn(
          '\$.series.${series.id}.dataPointLabels.formatter',
          'The data-point label formatter',
        );
        return series.copyWith(dataPointLabels: _withoutLabelFormatter(labels));
      case BarChartSeries(labelStyle: final labels)
          when labels.formatter != null:
        warn(
          '\$.series.${series.id}.barLabels.formatter',
          'The Bar label formatter',
        );
        return series.copyWith(
          labelStyle: BarLabelStyle(
            show: labels.show,
            position: labels.position,
            valueMode: labels.valueMode,
            color: labels.color,
            fontSize: labels.fontSize,
            fontWeight: labels.fontWeight,
            showUnit: labels.showUnit,
            padding: labels.padding,
          ),
        );
      default:
        return series;
    }
  }

  static DataPointLabelConfig _withoutLabelFormatter(
    DataPointLabelConfig labels,
  ) => DataPointLabelConfig(
    show: labels.show,
    position: labels.position,
    content: labels.content,
    offsetX: labels.offsetX,
    offsetY: labels.offsetY,
    markerGap: labels.markerGap,
    collisionPolicy: labels.collisionPolicy,
    collisionPadding: labels.collisionPadding,
    plotEdgeAware: labels.plotEdgeAware,
    labelColor: labels.labelColor,
    fontSize: labels.fontSize,
    fontWeight: labels.fontWeight,
    showUnit: labels.showUnit,
    background: labels.background,
    backgroundOpacity: labels.backgroundOpacity,
  );

  static RadialFormatterDocumentDescriptors? _radialDescriptors(
    ChartSeries series,
  ) {
    late PieDataLabelConfig labels;
    PieSliceRadiusConfig? radius;
    RadialValueFormatter? centerFormatter;
    switch (series) {
      case PieChartSeries():
        labels = series.dataLabels;
        radius = series.sliceRadiusConfig;
      case DonutChartSeries():
        labels = series.dataLabels;
        radius = series.sliceRadiusConfig;
        centerFormatter = series.centerContent.valueFormatter;
      default:
        return null;
    }
    final descriptors = RadialFormatterDocumentDescriptors(
      value: labels.valueFormatter == null
          ? null
          : _formatterPlaceholder('series.${series.id}.labels.value'),
      percentage: labels.percentageFormatter == null
          ? null
          : _formatterPlaceholder('series.${series.id}.labels.percentage'),
      radius: radius?.formatter == null
          ? null
          : _formatterPlaceholder('series.${series.id}.radius'),
      center: centerFormatter == null
          ? null
          : _formatterPlaceholder('series.${series.id}.center.value'),
    );
    return descriptors.isNotEmpty ? descriptors : null;
  }

  static JsonObjectValue _placeholder(String path) => JsonObjectValue({
    'id': JsonStringValue('braven.source.placeholder.$path'),
  });

  static JsonObjectValue _formatterPlaceholder(String path) =>
      ChartFormatterDescriptor(
        id: 'braven.source.placeholder.$path',
        fallbackPattern: '{value}',
      ).toDocument();
}

/// Source and options adapted without changing portable artifact semantics.
class ChartSourceCaptureRequest {
  const ChartSourceCaptureRequest({
    required this.source,
    required this.options,
    this.warnings = const [],
  });

  final ChartDocumentExtractionSource source;
  final ChartDocumentExtractOptions options;
  final List<ChartArtifactWarning> warnings;
}
