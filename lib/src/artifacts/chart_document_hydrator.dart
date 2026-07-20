import 'package:flutter/material.dart';

import '../braven_chart_plus.dart';
import '../controllers/annotation_controller.dart';
import '../layout/concentric_donut_layout.dart';
import '../layout/polar_column_composition.dart';
import '../models/axis_swap_mode.dart';
import '../models/braven_chart_controller.dart';
import '../models/chart_annotation.dart';
import '../models/chart_series.dart';
import '../models/chart_theme.dart';
import '../models/concentric_donut_config.dart';
import '../models/donut_center_builder.dart';
import '../models/donut_chart_series.dart';
import '../models/grid_config.dart';
import '../models/interaction_config.dart';
import '../models/legend_style.dart';
import '../models/normalization_mode.dart';
import '../models/polar_chart_config.dart';
import '../models/polar_column_chart_series.dart';
import '../models/x_axis_config.dart';
import '../models/y_axis_config.dart';
import 'chart_annotation_document_codec.dart';
import 'chart_annotation_document.dart';
import 'chart_artifact.dart';
import 'chart_artifact_diagnostics.dart';
import 'chart_artifact_json_codec.dart';
import 'chart_axis_document_codec.dart';
import 'chart_configuration_document_codec.dart';
import 'chart_data_payload.dart';
import 'chart_data_resolver.dart';
import 'chart_document.dart';
import 'chart_interaction_document_codec.dart';
import 'chart_runtime_bindings.dart';
import 'chart_series_document_codec.dart';
import 'chart_theme_document_codec.dart';
import 'chart_view_state.dart';
import 'json_value.dart';

/// Controls theme and durable-view-state behavior during hydration.
@immutable
class ChartHydrationOptions {
  const ChartHydrationOptions({
    this.themeMode = ChartThemeHydrationMode.asCaptured,
    this.restoreViewState = true,
    this.hostTheme,
  });

  final ChartThemeHydrationMode themeMode;
  final bool restoreViewState;
  final ChartTheme? hostTheme;
}

/// Fully decoded public model configuration for one chart artifact.
@immutable
class HydratedChartConfiguration {
  HydratedChartConfiguration({
    required Iterable<ChartSeries> series,
    required Iterable<ChartAnnotation> annotations,
    required this.xAxis,
    required Iterable<YAxisConfig> axes,
    required this.theme,
    required this.interaction,
    required this.grid,
    required this.legendStyle,
    required this.showLegend,
    required this.showToolbar,
    required this.interactiveAnnotations,
    required this.maxAxesPerSide,
    required this.axisSwapMode,
    required this.normalizationMode,
    required this.backgroundColor,
    required this.runtimeBindings,
    this.viewState,
    this.title,
    this.subtitle,
    this.width,
    this.height,
    this.concentricDonutConfig,
    this.polarChartConfig,
  }) : series = List.unmodifiable(series),
       annotations = List.unmodifiable(annotations),
       axes = List.unmodifiable(axes);

  /// Fresh immutable series models ready for [BravenChartPlus].
  final List<ChartSeries> series;

  /// Fresh immutable annotation models.
  final List<ChartAnnotation> annotations;
  final XAxisConfig xAxis;
  final List<YAxisConfig> axes;
  final ChartTheme theme;
  final InteractionConfig interaction;
  final GridConfig grid;
  final LegendStyle legendStyle;
  final bool showLegend;
  final bool showToolbar;
  final bool interactiveAnnotations;
  final int maxAxesPerSide;
  final AxisSwapMode axisSwapMode;
  final NormalizationMode normalizationMode;
  final Color backgroundColor;

  /// Explicit host behavior used by the restored chart.
  final ChartRuntimeBindings runtimeBindings;

  /// Captured view state, unless disabled by [ChartHydrationOptions].
  final ChartViewState? viewState;
  final String? title;
  final String? subtitle;
  final double? width;
  final double? height;

  /// Plot-level composition restored for two or more Donut series.
  final ConcentricDonutConfig? concentricDonutConfig;

  /// Plot-level pane and axes restored for an axis-based polar chart.
  final PolarChartConfig? polarChartConfig;

  YAxisConfig? get primaryYAxis {
    for (final axis in axes) {
      if (axis.id == 'y' || axis.id == 'primary_axis') return axis;
    }
    return axes.isEmpty ? null : axes.first;
  }

  /// Builds a fresh interactive runtime instance with independent controller
  /// and annotation identity.
  HydratedBravenChart build({
    Key? key,
    BravenChartController? bravenChartController,
    DonutCenterBuilder? donutCenterBuilder,
    DonutCenterTapCallback? onDonutCenterTap,
  }) => HydratedBravenChart(
    key: key,
    configuration: this,
    bravenChartController: bravenChartController,
    donutCenterBuilder: donutCenterBuilder,
    onDonutCenterTap: onDonutCenterTap,
  );
}

/// Stateful adapter that owns fresh annotation/controller identity per tile.
class HydratedBravenChart extends StatefulWidget {
  const HydratedBravenChart({
    super.key,
    required this.configuration,
    this.bravenChartController,
    this.donutCenterBuilder,
    this.onDonutCenterTap,
  });

  final HydratedChartConfiguration configuration;
  final BravenChartController? bravenChartController;
  final DonutCenterBuilder? donutCenterBuilder;
  final DonutCenterTapCallback? onDonutCenterTap;

  @override
  State<HydratedBravenChart> createState() => _HydratedBravenChartState();
}

class _HydratedBravenChartState extends State<HydratedBravenChart> {
  final Object _runtimeIdentity = Object();
  late AnnotationController _annotationController;
  late BravenChartController _bravenController;
  late bool _ownsBravenController;

  @override
  void initState() {
    super.initState();
    _annotationController = AnnotationController(
      initialAnnotations: widget.configuration.annotations,
    );
    _ownsBravenController = widget.bravenChartController == null;
    _bravenController = widget.bravenChartController ?? BravenChartController();
    _scheduleViewStateRestore();
  }

  @override
  void didUpdateWidget(HydratedBravenChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    var restoreState = false;
    if (widget.bravenChartController != oldWidget.bravenChartController) {
      if (_ownsBravenController) _bravenController.dispose();
      _ownsBravenController = widget.bravenChartController == null;
      _bravenController =
          widget.bravenChartController ?? BravenChartController();
      restoreState = true;
    }
    if (widget.configuration != oldWidget.configuration) {
      _annotationController.dispose();
      _annotationController = AnnotationController(
        initialAnnotations: widget.configuration.annotations,
      );
      restoreState = true;
    }
    if (restoreState) _scheduleViewStateRestore();
  }

  void _scheduleViewStateRestore() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.configuration.viewState == null) return;
      _bravenController.restoreViewState(widget.configuration.viewState!);
    });
  }

  @override
  void dispose() {
    _annotationController.dispose();
    if (_ownsBravenController) _bravenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.configuration;
    final bindings = config.runtimeBindings;
    return BravenChartPlus(
      key: ObjectKey(_runtimeIdentity),
      series: config.series,
      annotationController: _annotationController,
      bravenChartController: _bravenController,
      xAxisConfig: config.xAxis,
      yAxis: config.primaryYAxis,
      theme: config.theme,
      interactionConfig: config.interaction,
      grid: config.grid,
      legendStyle: config.legendStyle,
      showLegend: config.showLegend,
      concentricDonutConfig:
          config.concentricDonutConfig ?? const ConcentricDonutConfig(),
      polarChartConfig: config.polarChartConfig ?? const PolarChartConfig(),
      donutCenterBuilder: widget.donutCenterBuilder,
      onDonutCenterTap: widget.onDonutCenterTap,
      showToolbar: config.showToolbar,
      interactiveAnnotations: config.interactiveAnnotations,
      maxAxesPerSide: config.maxAxesPerSide,
      axisSwapMode: config.axisSwapMode,
      normalizationMode: config.normalizationMode,
      backgroundColor: config.backgroundColor,
      width: config.width,
      height: config.height,
      title: config.title,
      subtitle: config.subtitle,
      showXScrollbar: config.interaction.showXScrollbar,
      showYScrollbar: config.interaction.showYScrollbar,
      onPointTap: bindings.onPointTap,
      onPointHover: bindings.onPointHover,
      onBackgroundTap: bindings.onBackgroundTap,
      onSeriesSelected: bindings.onSeriesSelected,
      onAnnotationTap: bindings.onAnnotationTap,
      onAnnotationDragged: bindings.onAnnotationDragged,
      onSeriesDeselected: bindings.onSeriesDeselected,
    );
  }
}

/// Pure artifact/document hydration into supported public chart models.
abstract final class ChartDocumentHydrator {
  static const _builtInCapabilities = <String>{
    'series.base',
    'series.line',
    'series.scatter',
    'series.scatter.marker-style.v1',
    'series.scatter.interaction.v1',
    'series.scatter.size-encoding.v1',
    'series.scatter.color-encoding.v1',
    'series.scatter.opacity-encoding.v1',
    'series.scatter.category-encoding.v1',
    'series.scatter.jitter.v1',
    'series.scatter.clusters.v1',
    'series.scatter.bins.v1',
    'series.scatter.density.v1',
    'series.area',
    'series.area.gradient.v1',
    'series.candlestick',
    'series.candlestick.ohlc.v1',
    'series.candlestick.motion.v1',
    'series.candlestick.density-grouping.v1',
    'series.path-dash.v1',
    'series.bar',
    'series.path-motion.v1',
    'series.path-motion-timing.v1',
    'series.bar.pattern.v1',
    'series.bar.bullet.v1',
    'series.bar.lollipop.v1',
    'series.bar.diverging.v1',
    'series.pie',
    'series.pie.style.v2',
    'series.pie.corner-treatment.v1',
    'series.pie.variable-radius.v1',
    'series.donut',
    'series.donut.style.v1',
    'series.donut.center-content.v1',
    'series.donut.variable-radius.v1',
    'series.donut.concentric.v1',
    'series.polarColumn',
    'series.polar.column.v1',
    'series.polar.column.targets.v1',
    'series.polar.column.intervals.v1',
    'chart.polar.config.v1',
    'chart.polar.thresholds.v1',
    PolarColumnComposition.multipleSeriesCapability,
    PolarColumnComposition.groupedSeriesCapability,
    PolarColumnComposition.stackedSeriesCapability,
    'series.radial.grouping.v1',
    'series.radial.grouped-variable-radius.v1',
    'series.radial.formatters.v1',
    'series.radial.data-transitions.v1',
    'series.radial.selection-lift.v1',
    'series.radial.dual-labels.v1',
    'annotation.point',
    'annotation.range',
    'annotation.text',
    'annotation.threshold',
    'annotation.pin',
    'annotation.trend',
    'annotation.errorBar',
    'annotation.chord',
    'annotation.legend',
    'annotation.legend.size-scale.v1',
    'annotation.legend.color-scale.v1',
    'annotation.legend.opacity-scale.v1',
    'annotation.legend.category-scale.v1',
  };
  static const _builtInSeriesTypes = <String>{
    'base',
    'line',
    'scatter',
    'area',
    'bar',
    'candlestick',
    'pie',
    'donut',
    'polarColumn',
  };
  static const _builtInAnnotationTypes = <String>{
    'point',
    'range',
    'text',
    'threshold',
    'pin',
    'trend',
    'errorBar',
    'chord',
    'legend',
  };

  /// Validates, decodes, migrates, and hydrates an artifact JSON envelope.
  static ChartArtifactResult<HydratedChartConfiguration> hydrateJson(
    String encoded, {
    Iterable<ChartArtifactMigration> migrations = const [],
    ChartArtifactValidationLimits limits =
        const ChartArtifactValidationLimits(),
    ChartHydrationOptions options = const ChartHydrationOptions(),
    ChartRuntimeBindings runtimeBindings = const ChartRuntimeBindings(),
  }) {
    final decoded = ChartArtifactJsonCodec.decode(
      encoded,
      limits: limits,
      migrations: migrations,
      supportedCapabilities: {
        ..._builtInCapabilities,
        ...runtimeBindings.extensions.supportedCapabilities,
      },
    );
    return switch (decoded) {
      ChartArtifactFailure<ChartArtifactDecodeResult>() => ChartArtifactFailure(
        error: decoded.error,
        warnings: decoded.warnings,
      ),
      ChartArtifactSuccess<ChartArtifactDecodeResult>() =>
        _hydrateDecodedArtifact(
          decoded,
          options: options,
          runtimeBindings: runtimeBindings,
        ),
    };
  }

  /// Resolves host-owned data blobs before normal artifact hydration.
  static Future<ChartArtifactResult<HydratedChartConfiguration>>
  hydrateJsonWithDataResolver(
    String encoded, {
    required ChartDataResolver dataResolver,
    Iterable<ChartArtifactMigration> migrations = const [],
    ChartArtifactValidationLimits limits =
        const ChartArtifactValidationLimits(),
    ChartHydrationOptions options = const ChartHydrationOptions(),
    ChartRuntimeBindings runtimeBindings = const ChartRuntimeBindings(),
  }) async {
    final decoded = ChartArtifactJsonCodec.decode(
      encoded,
      limits: limits,
      migrations: migrations,
      supportedCapabilities: {
        ..._builtInCapabilities,
        ...runtimeBindings.extensions.supportedCapabilities,
      },
    );
    if (decoded case ChartArtifactFailure<ChartArtifactDecodeResult>()) {
      return ChartArtifactFailure(
        error: decoded.error,
        warnings: decoded.warnings,
      );
    }
    final success = decoded as ChartArtifactSuccess<ChartArtifactDecodeResult>;
    final hydrated = await hydrateArtifactWithDataResolver(
      success.value.artifact,
      dataResolver: dataResolver,
      limits: limits,
      options: options,
      runtimeBindings: runtimeBindings,
    );
    return switch (hydrated) {
      ChartArtifactSuccess<HydratedChartConfiguration>() =>
        ChartArtifactSuccess(
          value: hydrated.value,
          warnings: [...success.warnings, ...hydrated.warnings],
        ),
      ChartArtifactFailure<HydratedChartConfiguration>() =>
        ChartArtifactFailure(
          error: hydrated.error,
          warnings: [...success.warnings, ...hydrated.warnings],
        ),
    };
  }

  /// Resolves all referenced payloads, then uses the synchronous hydrator.
  static Future<ChartArtifactResult<HydratedChartConfiguration>>
  hydrateArtifactWithDataResolver(
    ChartArtifact artifact, {
    required ChartDataResolver dataResolver,
    ChartArtifactValidationLimits limits =
        const ChartArtifactValidationLimits(),
    ChartHydrationOptions options = const ChartHydrationOptions(),
    ChartRuntimeBindings runtimeBindings = const ChartRuntimeBindings(),
  }) async {
    final resolved = await ChartDataResolution.resolveArtifact(
      artifact,
      resolver: dataResolver,
      limits: limits,
    );
    if (resolved case ChartArtifactFailure<ChartArtifact>()) {
      return ChartArtifactFailure(
        error: resolved.error,
        warnings: resolved.warnings,
      );
    }
    final success = resolved as ChartArtifactSuccess<ChartArtifact>;
    final hydrated = hydrateArtifact(
      success.value,
      options: options,
      runtimeBindings: runtimeBindings,
    );
    return switch (hydrated) {
      ChartArtifactSuccess<HydratedChartConfiguration>() =>
        ChartArtifactSuccess(
          value: hydrated.value,
          warnings: [...success.warnings, ...hydrated.warnings],
        ),
      ChartArtifactFailure<HydratedChartConfiguration>() =>
        ChartArtifactFailure(
          error: hydrated.error,
          warnings: [...success.warnings, ...hydrated.warnings],
        ),
    };
  }

  static ChartArtifactResult<HydratedChartConfiguration>
  _hydrateDecodedArtifact(
    ChartArtifactSuccess<ChartArtifactDecodeResult> decoded, {
    required ChartHydrationOptions options,
    required ChartRuntimeBindings runtimeBindings,
  }) {
    final hydrated = hydrateArtifact(
      decoded.value.artifact,
      options: options,
      runtimeBindings: runtimeBindings,
    );
    return switch (hydrated) {
      ChartArtifactFailure<HydratedChartConfiguration>() =>
        ChartArtifactFailure(
          error: hydrated.error,
          warnings: [...decoded.warnings, ...hydrated.warnings],
        ),
      ChartArtifactSuccess<HydratedChartConfiguration>() =>
        ChartArtifactSuccess(
          value: hydrated.value,
          warnings: [...decoded.warnings, ...hydrated.warnings],
        ),
    };
  }

  static ChartArtifactResult<HydratedChartConfiguration> hydrateArtifact(
    ChartArtifact artifact, {
    ChartHydrationOptions options = const ChartHydrationOptions(),
    ChartRuntimeBindings runtimeBindings = const ChartRuntimeBindings(),
  }) {
    if (artifact.schemaVersion != ChartArtifact.currentSchemaVersion) {
      return ChartArtifactFailure(
        error: ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.unsupportedSchemaVersion,
          message:
              'Cannot hydrate schema ${artifact.schemaVersion}; supported schema is ${ChartArtifact.currentSchemaVersion}.',
          path: r'$.schemaVersion',
        ),
      );
    }
    return hydrateDocument(
      artifact.document,
      viewState: artifact.viewState,
      options: options,
      runtimeBindings: runtimeBindings,
    );
  }

  static ChartArtifactResult<HydratedChartConfiguration> hydrateDocument(
    ChartDocument document, {
    ChartViewState? viewState,
    ChartHydrationOptions options = const ChartHydrationOptions(),
    ChartRuntimeBindings runtimeBindings = const ChartRuntimeBindings(),
  }) {
    final warnings = <ChartArtifactWarning>[];
    try {
      final requiredCapabilities = <String>{
        ...document.requiredCapabilities,
        for (final series in document.series) ...series.requiredCapabilities,
        for (final annotation in document.annotations)
          ...annotation.requiredCapabilities,
      };
      final supportedCapabilities = {
        ..._builtInCapabilities,
        ...runtimeBindings.extensions.supportedCapabilities,
      };
      final unsupported = requiredCapabilities.difference(
        supportedCapabilities,
      );
      if (unsupported.isNotEmpty) {
        final sorted = unsupported.toList()..sort();
        return ChartArtifactFailure(
          error: ChartArtifactError(
            code: ChartArtifactDiagnosticCodes.missingRequiredCapability,
            message: 'Missing required capabilities: ${sorted.join(', ')}.',
            path: r'$.document.requiredCapabilities',
          ),
        );
      }

      final series = [
        for (var index = 0; index < document.series.length; index++)
          _decodeSeries(
            document.series[index],
            runtimeBindings.formatters,
            runtimeBindings.extensions,
            warnings,
            index,
          ),
      ];
      final annotations = [
        for (final item in document.annotations)
          _decodeAnnotation(item, runtimeBindings.extensions, warnings),
      ];
      final xAxisFormatter = _resolveFormatter(
        document.xAxis.formatter,
        runtimeBindings.formatters,
        warnings,
        r'$.document.xAxis.formatter',
      );
      final xAxis = _requireValue(
        ChartAxisDocumentCodec.decodeXAxis(
          document.xAxis,
          formatter: xAxisFormatter,
        ),
        warnings,
      );
      final axes = [
        for (var index = 0; index < document.axes.length; index++)
          _decodeAxis(
            document.axes[index],
            runtimeBindings.formatters,
            warnings,
            index,
          ),
      ];
      final ChartTheme theme;
      if (options.themeMode == ChartThemeHydrationMode.hostOverride) {
        theme = _requireHostTheme(options.hostTheme);
      } else if (options.themeMode == ChartThemeHydrationMode.adaptToHost &&
          options.hostTheme != null) {
        theme = options.hostTheme!;
      } else {
        theme = _requireValue(
          ChartThemeDocumentCodec.decode(document.theme),
          warnings,
        );
      }
      final interaction = _requireValue(
        ChartInteractionDocumentCodec.decode(
          document.interaction,
          bindings: runtimeBindings,
        ),
        warnings,
      );
      final legend = _requireValue(
        ChartConfigurationDocumentCodec.decodeLegend(document.legend),
        warnings,
      );
      final grid = _requireValue(
        ChartConfigurationDocumentCodec.decodeGrid(document.grid),
        warnings,
      );
      final normalization = document.normalization == null
          ? NormalizationMode.none
          : _requireValue(
              ChartConfigurationDocumentCodec.decodeNormalization(
                document.normalization!,
              ),
              warnings,
            );
      final concentricCenterFormatter = _resolveFormatter(
        _concentricCenterFormatterDescriptor(document.configuration),
        runtimeBindings.formatters,
        warnings,
        r'$.document.configuration.concentricDonut.centerContent.valueFormatter',
      );
      final concentricDonutConfig = _requireValue(
        ChartConfigurationDocumentCodec.decodeConcentricDonut(
          document.configuration,
          centerFormatter: concentricCenterFormatter,
        ),
        warnings,
      );
      _validateConcentricComposition(
        document: document,
        series: series,
        config: concentricDonutConfig,
      );
      final polarChartConfig = _requireValue(
        ChartConfigurationDocumentCodec.decodePolarChart(
          document.configuration,
        ),
        warnings,
      );
      _validatePolarComposition(
        document: document,
        series: series,
        config: polarChartConfig,
      );
      final layout = document.layout;

      return ChartArtifactSuccess(
        value: HydratedChartConfiguration(
          series: series,
          annotations: annotations,
          xAxis: xAxis,
          axes: axes,
          theme: theme,
          interaction: interaction,
          grid: grid,
          legendStyle: legend.style,
          showLegend: legend.visible,
          showToolbar: layout.showToolbar ?? false,
          interactiveAnnotations: layout.interactiveAnnotations ?? true,
          maxAxesPerSide: layout.maxAxesPerSide ?? 3,
          axisSwapMode: _axisSwapMode(layout.axisSwapMode),
          normalizationMode: normalization,
          backgroundColor: layout.backgroundColor == null
              ? theme.backgroundColor
              : Color(layout.backgroundColor!),
          runtimeBindings: runtimeBindings,
          viewState: options.restoreViewState ? viewState : null,
          title: document.title,
          subtitle: document.subtitle,
          width: layout.width?.asDouble,
          height: layout.height?.asDouble,
          concentricDonutConfig: concentricDonutConfig,
          polarChartConfig: polarChartConfig,
        ),
        warnings: warnings,
      );
    } on _HydrationFailure catch (failure) {
      return ChartArtifactFailure(
        error: failure.error,
        warnings: [...warnings, ...failure.warnings],
      );
    } on FormatException catch (error) {
      return ChartArtifactFailure(
        error: ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.invalidArtifact,
          message: error.message,
        ),
        warnings: warnings,
      );
    }
  }

  static YAxisConfig _decodeAxis(
    ChartAxisDocument document,
    ChartFormatterRegistry registry,
    List<ChartArtifactWarning> warnings,
    int index,
  ) {
    final formatter = _resolveFormatter(
      document.formatter,
      registry,
      warnings,
      '\$.document.axes[$index].formatter',
    );
    return _requireValue(
      ChartAxisDocumentCodec.decodeYAxis(document, formatter: formatter),
      warnings,
    );
  }

  static ChartSeries _decodeSeries(
    ChartSeriesDocument document,
    ChartFormatterRegistry registry,
    ChartExtensionRegistry extensions,
    List<ChartArtifactWarning> warnings,
    int index,
  ) {
    if (!_builtInSeriesTypes.contains(document.type)) {
      final codec = extensions.seriesCodecs[document.type];
      if (codec == null) {
        throw _HydrationFailure(
          ChartArtifactError(
            code: ChartArtifactDiagnosticCodes.unsupportedModelType,
            message: 'No series extension codec for "${document.type}".',
            path: '\$.document.series[$index].type',
          ),
          const [],
        );
      }
      try {
        return codec.decode(document);
      } on Object catch (error) {
        throw _HydrationFailure(
          ChartArtifactError(
            code: ChartArtifactDiagnosticCodes.invalidArtifact,
            message: 'Series extension codec "${codec.typeId}" failed: $error',
            path: '\$.document.series[$index]',
          ),
          const [],
        );
      }
    }
    final rawFormatter = document.inlineAxis?.values['formatter'];
    if (rawFormatter != null && rawFormatter is! JsonObjectValue) {
      throw FormatException(
        'Series inline-axis formatter at index $index must be an object.',
      );
    }
    final formatter = _resolveFormatter(
      rawFormatter as JsonObjectValue?,
      registry,
      warnings,
      '\$.document.series[$index].inlineAxis.formatter',
    );
    final radialValueFormatter = _resolveFormatter(
      _nestedFormatterDescriptor(document, 'dataLabels', 'valueFormatter'),
      registry,
      warnings,
      '\$.document.series[$index].style.dataLabels.valueFormatter',
    );
    final radialPercentageFormatter = _resolveFormatter(
      _nestedFormatterDescriptor(document, 'dataLabels', 'percentageFormatter'),
      registry,
      warnings,
      '\$.document.series[$index].style.dataLabels.percentageFormatter',
    );
    final radialRadiusFormatter = _resolveFormatter(
      _nestedFormatterDescriptor(document, 'sliceRadiusConfig', 'formatter'),
      registry,
      warnings,
      '\$.document.series[$index].style.sliceRadiusConfig.formatter',
    );
    final donutCenterFormatter = _resolveFormatter(
      _nestedFormatterDescriptor(document, 'centerContent', 'valueFormatter'),
      registry,
      warnings,
      '\$.document.series[$index].style.centerContent.valueFormatter',
    );
    return _requireValue(
      ChartSeriesDocumentCodec.decode(
        document,
        inlineAxisFormatter: formatter,
        radialValueFormatter: radialValueFormatter,
        radialPercentageFormatter: radialPercentageFormatter,
        radialRadiusFormatter: radialRadiusFormatter,
        donutCenterFormatter: donutCenterFormatter,
      ),
      warnings,
    );
  }

  static JsonObjectValue? _nestedFormatterDescriptor(
    ChartSeriesDocument document,
    String containerKey,
    String formatterKey,
  ) {
    final container = document.style?.values[containerKey];
    if (container == null) return null;
    if (container is! JsonObjectValue) {
      throw FormatException('Series style "$containerKey" must be an object.');
    }
    final formatter = container.values[formatterKey];
    if (formatter == null) return null;
    if (formatter is! JsonObjectValue) {
      throw FormatException(
        'Series formatter "$containerKey.$formatterKey" must be an object.',
      );
    }
    return formatter;
  }

  static JsonObjectValue? _concentricCenterFormatterDescriptor(
    JsonObjectValue configuration,
  ) {
    final composition = configuration.values['concentricDonut'];
    if (composition == null) return null;
    if (composition is! JsonObjectValue) {
      throw const FormatException(
        'Concentric Donut configuration must be an object.',
      );
    }
    final center = composition.values['centerContent'];
    if (center == null) return null;
    if (center is! JsonObjectValue) {
      throw const FormatException(
        'Concentric Donut center content must be an object.',
      );
    }
    final formatter = center.values['valueFormatter'];
    if (formatter == null) return null;
    if (formatter is! JsonObjectValue) {
      throw const FormatException(
        'Concentric Donut center formatter must be an object.',
      );
    }
    return formatter;
  }

  static void _validateConcentricComposition({
    required ChartDocument document,
    required List<ChartSeries> series,
    required ConcentricDonutConfig? config,
  }) {
    final rings = series.whereType<DonutChartSeries>().toList(growable: false);
    if (config == null) {
      if (rings.length > 1) {
        throw const _HydrationFailure(
          ChartArtifactError(
            code: ChartArtifactDiagnosticCodes.invalidArtifact,
            message:
                'Multiple Donut series require chart-level Concentric Donut configuration.',
            path: r'$.document.configuration.concentricDonut',
          ),
          [],
        );
      }
      return;
    }
    if (!document.requiredCapabilities.contains('series.donut.concentric.v1')) {
      throw const _HydrationFailure(
        ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.invalidArtifact,
          message:
              'Concentric Donut configuration must declare series.donut.concentric.v1.',
          path: r'$.document.requiredCapabilities',
        ),
        [],
      );
    }
    if (rings.length < 2 || rings.length != series.length) {
      throw const _HydrationFailure(
        ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.invalidArtifact,
          message:
              'Concentric Donut configuration requires two or more Donut series and cannot mix chart families.',
          path: r'$.document.configuration.concentricDonut',
        ),
        [],
      );
    }
    try {
      ConcentricDonutLayoutCalculator.calculate(
        series: rings,
        config: config,
        availableRadius: 100,
      );
    } on ArgumentError catch (error) {
      throw _HydrationFailure(
        ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.invalidArtifact,
          message: 'Invalid Concentric Donut composition: ${error.message}',
          path: r'$.document.configuration.concentricDonut',
        ),
        const [],
      );
    }
  }

  static void _validatePolarComposition({
    required ChartDocument document,
    required List<ChartSeries> series,
    required PolarChartConfig? config,
  }) {
    final polarSeries = series.whereType<PolarColumnChartSeries>().toList(
      growable: false,
    );
    if (config == null) {
      if (polarSeries.isNotEmpty) {
        throw const _HydrationFailure(
          ChartArtifactError(
            code: ChartArtifactDiagnosticCodes.invalidArtifact,
            message:
                'Polar Column series require chart-level Polar configuration.',
            path: r'$.document.configuration.polarChart',
          ),
          [],
        );
      }
      return;
    }
    if (!document.requiredCapabilities.contains('chart.polar.config.v1')) {
      throw const _HydrationFailure(
        ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.invalidArtifact,
          message: 'Polar configuration must declare chart.polar.config.v1.',
          path: r'$.document.requiredCapabilities',
        ),
        [],
      );
    }
    if (polarSeries.isEmpty || polarSeries.length != series.length) {
      throw const _HydrationFailure(
        ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.invalidArtifact,
          message:
              'Polar configuration requires Polar Column series and cannot mix chart families.',
          path: r'$.document.configuration.polarChart',
        ),
        [],
      );
    }
    if (config.thresholds.isNotEmpty &&
        !document.requiredCapabilities.contains('chart.polar.thresholds.v1')) {
      throw const _HydrationFailure(
        ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.invalidArtifact,
          message: 'Polar thresholds must declare chart.polar.thresholds.v1.',
          path: r'$.document.requiredCapabilities',
        ),
        [],
      );
    }
    if (polarSeries.any((series) => series.targetValues.isNotEmpty) &&
        !document.requiredCapabilities.contains(
          'series.polar.column.targets.v1',
        )) {
      throw const _HydrationFailure(
        ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.invalidArtifact,
          message:
              'Polar Column targets must declare series.polar.column.targets.v1.',
          path: r'$.document.requiredCapabilities',
        ),
        [],
      );
    }
    if (polarSeries.any((series) => series.hasIntervals) &&
        !document.requiredCapabilities.contains(
          'series.polar.column.intervals.v1',
        )) {
      throw const _HydrationFailure(
        ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.invalidArtifact,
          message:
              'Polar Column intervals must declare series.polar.column.intervals.v1.',
          path: r'$.document.requiredCapabilities',
        ),
        [],
      );
    }
    if (polarSeries.length > 1 &&
        !document.requiredCapabilities.contains(
          PolarColumnComposition.multipleSeriesCapability,
        )) {
      throw const _HydrationFailure(
        ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.invalidArtifact,
          message:
              'Multiple Polar Column series must declare chart.polar.multiple-series.v1.',
          path: r'$.document.requiredCapabilities',
        ),
        [],
      );
    }
    if (config.composition.mode == PolarColumnCompositionMode.grouped &&
        !document.requiredCapabilities.contains(
          PolarColumnComposition.groupedSeriesCapability,
        )) {
      throw const _HydrationFailure(
        ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.invalidArtifact,
          message:
              'Grouped Polar Column series must declare chart.polar.grouped-series.v1.',
          path: r'$.document.requiredCapabilities',
        ),
        [],
      );
    }
    if (config.composition.mode == PolarColumnCompositionMode.stacked &&
        !document.requiredCapabilities.contains(
          PolarColumnComposition.stackedSeriesCapability,
        )) {
      throw const _HydrationFailure(
        ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.invalidArtifact,
          message:
              'Stacked Polar Column series must declare chart.polar.stacked-series.v1.',
          path: r'$.document.requiredCapabilities',
        ),
        [],
      );
    }
    try {
      PolarColumnComposition.validate(polarSeries, config: config);
    } on ArgumentError catch (error) {
      throw _HydrationFailure(
        ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.invalidArtifact,
          message: 'Invalid Polar Column composition: ${error.message}',
          path: r'$.document.configuration.polarChart',
        ),
        const [],
      );
    }
  }

  static ChartAnnotation _decodeAnnotation(
    ChartAnnotationDocument document,
    ChartExtensionRegistry extensions,
    List<ChartArtifactWarning> warnings,
  ) {
    if (_builtInAnnotationTypes.contains(document.type)) {
      return _requireValue(
        ChartAnnotationDocumentCodec.decode(document),
        warnings,
      );
    }
    final codec = extensions.annotationCodecs[document.type];
    if (codec == null) {
      throw _HydrationFailure(
        ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.unsupportedModelType,
          message: 'No annotation extension codec for "${document.type}".',
          path: r'$.document.annotations',
        ),
        const [],
      );
    }
    try {
      return codec.decode(document);
    } on Object catch (error) {
      throw _HydrationFailure(
        ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.invalidArtifact,
          message:
              'Annotation extension codec "${codec.typeId}" failed: $error',
          path: r'$.document.annotations',
        ),
        const [],
      );
    }
  }

  static String Function(double)? _resolveFormatter(
    JsonObjectValue? document,
    ChartFormatterRegistry registry,
    List<ChartArtifactWarning> warnings,
    String path,
  ) {
    if (document == null) return null;
    final descriptor = ChartFormatterDescriptor.fromDocument(document);
    final resolution = registry.resolve(descriptor);
    if (resolution.warning != null) {
      warnings.add(
        ChartArtifactWarning(
          code: resolution.warning!.code,
          message: resolution.warning!.message,
          path: path,
        ),
      );
    }
    return resolution.formatter;
  }

  static AxisSwapMode _axisSwapMode(String? name) {
    if (name == null) return AxisSwapMode.sticky;
    for (final value in AxisSwapMode.values) {
      if (value.name == name) return value;
    }
    throw FormatException('Unknown axis swap mode "$name".');
  }

  static ChartTheme _requireHostTheme(ChartTheme? theme) {
    if (theme != null) return theme;
    throw const _HydrationFailure(
      ChartArtifactError(
        code: ChartArtifactDiagnosticCodes.runtimeBindingRequired,
        message: 'hostOverride hydration requires a host theme.',
        path: r'$.options.hostTheme',
      ),
      [],
    );
  }
}

class _HydrationFailure implements Exception {
  const _HydrationFailure(this.error, this.warnings);

  final ChartArtifactError error;
  final List<ChartArtifactWarning> warnings;
}

T _requireValue<T>(
  ChartArtifactResult<T> result,
  List<ChartArtifactWarning> warnings,
) => switch (result) {
  ChartArtifactSuccess<T>() => _recordSuccess(result, warnings),
  ChartArtifactFailure<T>() => throw _HydrationFailure(
    result.error,
    result.warnings,
  ),
};

T _recordSuccess<T>(
  ChartArtifactSuccess<T> result,
  List<ChartArtifactWarning> warnings,
) {
  warnings.addAll(result.warnings);
  return result.value;
}
