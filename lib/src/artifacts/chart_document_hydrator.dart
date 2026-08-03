import 'dart:async';
import 'dart:ui' as ui;

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
import '../models/gauge_center_builder.dart';
import '../models/gauge_chart_config.dart';
import '../models/gauge_chart_series.dart';
import '../models/interaction_config.dart';
import '../models/heatmap_chart_series.dart';
import '../models/heatmap_viewport_source.dart';
import '../models/legend_style.dart';
import '../models/normalization_mode.dart';
import '../models/polar_chart_config.dart';
import '../models/polar_column_chart_series.dart';
import '../models/radial_bar_chart_config.dart';
import '../models/radial_bar_chart_series.dart';
import '../models/series_callout_config.dart';
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
import 'heatmap_viewport_provider_binding.dart';
import 'heatmap_raster_viewport_provider_binding.dart';
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
    Iterable<HeatmapViewportProviderDescriptor> heatmapViewportProviders =
        const [],
    this.heatmapRasterViewportProvider,
    this.viewState,
    this.title,
    this.subtitle,
    this.width,
    this.height,
    this.concentricDonutConfig,
    this.polarChartConfig,
    this.radialBarChartConfig,
    this.gaugeChartConfig,
    this.seriesCallouts = const SeriesCalloutConfig(),
  }) : series = List.unmodifiable(series),
       annotations = List.unmodifiable(annotations),
       axes = List.unmodifiable(axes),
       heatmapViewportProviders = List.unmodifiable(heatmapViewportProviders);

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

  /// Portable provider descriptors resolved by [runtimeBindings] per mount.
  final List<HeatmapViewportProviderDescriptor> heatmapViewportProviders;

  /// Portable image-backed provider resolved by [runtimeBindings] per mount.
  final HeatmapRasterViewportProviderDescriptor? heatmapRasterViewportProvider;

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

  /// Plot-level pane, tracks, and guides restored for a Radial Bar chart.
  final RadialBarChartConfig? radialBarChartConfig;

  /// Plot-level pane, ticks, zones, and center fallback restored for Gauge.
  final GaugeChartConfig? gaugeChartConfig;

  /// Collision-aware label-callout policy restored with the chart document.
  final SeriesCalloutConfig seriesCallouts;

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
    GaugeCenterBuilder? gaugeCenterBuilder,
    DonutCenterBuilder? donutCenterBuilder,
    DonutCenterTapCallback? onDonutCenterTap,
  }) => HydratedBravenChart(
    key: key,
    configuration: this,
    bravenChartController: bravenChartController,
    gaugeCenterBuilder: gaugeCenterBuilder,
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
    this.gaugeCenterBuilder,
    this.donutCenterBuilder,
    this.onDonutCenterTap,
  });

  final HydratedChartConfiguration configuration;
  final BravenChartController? bravenChartController;
  final GaugeCenterBuilder? gaugeCenterBuilder;
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
  late List<ChartSeries> _runtimeSeries;
  final Map<String, _MountedHeatmapViewportProvider> _heatmapProviders = {};
  _MountedHeatmapRasterViewportProvider? _heatmapRasterProvider;

  @override
  void initState() {
    super.initState();
    _annotationController = AnnotationController(
      initialAnnotations: widget.configuration.annotations,
    );
    _ownsBravenController = widget.bravenChartController == null;
    _bravenController = widget.bravenChartController ?? BravenChartController();
    _initializeHeatmapProviders();
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
      _disposeHeatmapProviders();
      _initializeHeatmapProviders();
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

  void _initializeHeatmapProviders() {
    _runtimeSeries = widget.configuration.series;
    final registry =
        widget.configuration.runtimeBindings.heatmapViewportProviders;
    for (final descriptor in widget.configuration.heatmapViewportProviders) {
      final template = widget.configuration.series
          .whereType<HeatmapChartSeries>()
          .singleWhere((series) => series.id == descriptor.seriesId);
      final factory = registry.resolve(descriptor.providerId)!;
      final runtime = factory(descriptor, template);
      final mounted = _MountedHeatmapViewportProvider(
        descriptor: descriptor,
        template: template,
        runtime: runtime,
      );
      _heatmapProviders[descriptor.seriesId] = mounted;
      runtime.controller.addListener(_handleHeatmapProviderChanged);
    }
    final rasterDescriptor = widget.configuration.heatmapRasterViewportProvider;
    if (rasterDescriptor != null) {
      final rasterRegistry =
          widget.configuration.runtimeBindings.heatmapRasterViewportProviders;
      final rasterFactory = rasterRegistry.resolve(rasterDescriptor.providerId);
      if (rasterFactory != null) {
        final semanticTemplate = rasterDescriptor.semanticSeriesId == null
            ? null
            : widget.configuration.series
                  .whereType<HeatmapChartSeries>()
                  .singleWhere(
                    (series) => series.id == rasterDescriptor.semanticSeriesId,
                  );
        final runtime = rasterFactory(rasterDescriptor, semanticTemplate);
        final runtimeSemanticId =
            runtime.controller.semanticDescriptor?.seriesId;
        if (runtimeSemanticId != rasterDescriptor.semanticSeriesId) {
          throw StateError(
            'Heatmap raster provider "${rasterDescriptor.providerId}" '
            'returned semantic series "$runtimeSemanticId"; expected '
            '"${rasterDescriptor.semanticSeriesId}".',
          );
        }
        _heatmapRasterProvider = _MountedHeatmapRasterViewportProvider(
          descriptor: rasterDescriptor,
          runtime: runtime,
        );
      }
    }
    _materializeHeatmapProviderSeries();
    if (_heatmapProviders.isNotEmpty || _heatmapRasterProvider != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        for (final provider in _heatmapProviders.values) {
          unawaited(
            provider.runtime.controller.loadViewport(
              provider.descriptor.initialViewport,
            ),
          );
        }
        if (_heatmapRasterProvider case final provider?) {
          unawaited(
            provider.runtime.controller.loadViewport(
              provider.descriptor.initialViewport,
            ),
          );
        }
      });
    }
  }

  void _handleHeatmapProviderChanged() {
    if (!mounted) return;
    setState(_materializeHeatmapProviderSeries);
  }

  void _materializeHeatmapProviderSeries() {
    final rasterSemanticSeriesId =
        _heatmapRasterProvider?.descriptor.semanticSeriesId;
    _runtimeSeries = [
      for (final series in widget.configuration.series)
        // A mounted raster controller supplies the refreshed semantic
        // companion. Keeping the captured fallback would collide with that
        // canonical series ID inside BravenChartPlus.
        if (series.id != rasterSemanticSeriesId)
          if (_heatmapProviders[series.id] case final provider?)
            _materializeProviderSeries(provider)
          else
            series,
    ];
  }

  ChartSeries _materializeProviderSeries(
    _MountedHeatmapViewportProvider provider,
  ) {
    final snapshot = provider.runtime.controller.snapshot;
    if (snapshot.generation == 0 || snapshot.cells.isEmpty) {
      return provider.template;
    }
    return snapshot.materializeSeries(provider.template);
  }

  void _handleProviderViewportChanged(Map<String, double> visibleBounds) {
    widget.configuration.interaction.onViewportChanged?.call(visibleBounds);
    final request = HeatmapViewportRequest.fromVisibleBounds(visibleBounds);
    for (final provider in _heatmapProviders.values) {
      provider.runtime.controller.requestViewport(request);
    }
    if (_heatmapRasterProvider case final provider?) {
      unawaited(provider.runtime.controller.loadViewport(request));
    }
  }

  void _disposeHeatmapProviders() {
    for (final provider in _heatmapProviders.values) {
      provider.runtime.controller.removeListener(_handleHeatmapProviderChanged);
      if (provider.runtime.disposeController) {
        provider.runtime.controller.dispose();
      }
    }
    _heatmapProviders.clear();
    if (_heatmapRasterProvider case final provider?) {
      if (provider.runtime.disposeController) {
        provider.runtime.controller.dispose();
      }
      _heatmapRasterProvider = null;
    }
  }

  @override
  void dispose() {
    _disposeHeatmapProviders();
    _annotationController.dispose();
    if (_ownsBravenController) _bravenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.configuration;
    final bindings = config.runtimeBindings;
    final providerInitialViewport =
        _heatmapRasterProvider?.descriptor.initialViewport ??
        (_heatmapProviders.isEmpty
            ? null
            : _heatmapProviders.values.first.descriptor.initialViewport);
    final hasViewportProvider =
        _heatmapProviders.isNotEmpty || _heatmapRasterProvider != null;
    final interaction = !hasViewportProvider
        ? config.interaction
        : config.interaction.copyWith(
            onViewportChanged: _handleProviderViewportChanged,
          );
    return BravenChartPlus(
      key: ObjectKey(_runtimeIdentity),
      series: _runtimeSeries,
      heatmapRasterViewportController:
          _heatmapRasterProvider?.runtime.controller,
      heatmapRasterOpacity: _heatmapRasterProvider?.descriptor.opacity ?? 1,
      heatmapRasterFilterQuality: _rasterFilterQuality(
        _heatmapRasterProvider?.descriptor.filterQuality,
      ),
      annotationController: _annotationController,
      bravenChartController: _bravenController,
      xAxisConfig: config.xAxis,
      yAxis: config.primaryYAxis,
      theme: config.theme,
      interactionConfig: interaction,
      resetViewportBounds: providerInitialViewport == null
          ? null
          : ChartBoundsDocument(
              xMin: providerInitialViewport.minimumX,
              xMax: providerInitialViewport.maximumX,
              yMin: providerInitialViewport.minimumY,
              yMax: providerInitialViewport.maximumY,
            ),
      grid: config.grid,
      legendStyle: config.legendStyle,
      seriesCallouts: config.seriesCallouts,
      showLegend: config.showLegend,
      concentricDonutConfig:
          config.concentricDonutConfig ?? const ConcentricDonutConfig(),
      polarChartConfig: config.polarChartConfig ?? const PolarChartConfig(),
      radialBarChartConfig:
          config.radialBarChartConfig ?? const RadialBarChartConfig(),
      gaugeChartConfig: config.gaugeChartConfig ?? const GaugeChartConfig(),
      gaugeCenterBuilder: widget.gaugeCenterBuilder,
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
      showXScrollbar: interaction.showXScrollbar,
      showYScrollbar: interaction.showYScrollbar,
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

final class _MountedHeatmapViewportProvider {
  const _MountedHeatmapViewportProvider({
    required this.descriptor,
    required this.template,
    required this.runtime,
  });

  final HeatmapViewportProviderDescriptor descriptor;
  final HeatmapChartSeries template;
  final HeatmapViewportProviderRuntime runtime;
}

final class _MountedHeatmapRasterViewportProvider {
  const _MountedHeatmapRasterViewportProvider({
    required this.descriptor,
    required this.runtime,
  });

  final HeatmapRasterViewportProviderDescriptor descriptor;
  final HeatmapRasterViewportProviderRuntime runtime;
}

ui.FilterQuality _rasterFilterQuality(
  HeatmapRasterProviderFilterQuality? quality,
) => switch (quality ?? HeatmapRasterProviderFilterQuality.low) {
  HeatmapRasterProviderFilterQuality.none => ui.FilterQuality.none,
  HeatmapRasterProviderFilterQuality.low => ui.FilterQuality.low,
  HeatmapRasterProviderFilterQuality.medium => ui.FilterQuality.medium,
  HeatmapRasterProviderFilterQuality.high => ui.FilterQuality.high,
};

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
    'series.rangeArea',
    'series.rangeArea.interval.v1',
    'series.rangeArea.gradient.v1',
    'series.heatmap',
    'series.heatmap.cell.v1',
    'series.heatmap.color-scale.v1',
    HeatmapViewportProviderDescriptor.capabilityId,
    HeatmapRasterViewportProviderDescriptor.capabilityId,
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
    'series.radialBar',
    'series.polar.column.v1',
    PolarColumnChartSeries.cornerRadiusModeCapability,
    PolarColumnChartSeries.appearanceCapability,
    'series.polar.column.targets.v1',
    'series.polar.column.intervals.v1',
    'series.radial.bar.v1',
    'chart.radial.bar.config.v1',
    'series.gauge',
    'series.gauge.v1',
    'chart.gauge.config.v1',
    'chart.polar.config.v1',
    'chart.polar.thresholds.v1',
    'chart.cartesian.value-summary.v1',
    PolarChartConfig.labelAppearanceCapability,
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
    'rangeArea',
    'heatmap',
    'bar',
    'candlestick',
    'pie',
    'donut',
    'polarColumn',
    'radialBar',
    'gauge',
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
      final heatmapViewportProviders = _decodeHeatmapViewportProviders(
        document,
        series,
        runtimeBindings,
      );
      final heatmapRasterViewportProvider =
          _decodeHeatmapRasterViewportProvider(
            document,
            series,
            heatmapViewportProviders,
            runtimeBindings,
          );
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
      final seriesCallouts = _requireValue(
        ChartConfigurationDocumentCodec.decodeSeriesCallouts(
          document.configuration,
        ),
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
      final radialBarChartConfig = _requireValue(
        ChartConfigurationDocumentCodec.decodeRadialBarChart(
          document.configuration,
        ),
        warnings,
      );
      _validateRadialBarComposition(
        document: document,
        series: series,
        config: radialBarChartConfig,
      );
      final gaugeChartConfig = _requireValue(
        ChartConfigurationDocumentCodec.decodeGaugeChart(
          document.configuration,
        ),
        warnings,
      );
      _validateGaugeComposition(
        document: document,
        series: series,
        config: gaugeChartConfig,
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
          heatmapViewportProviders: heatmapViewportProviders,
          heatmapRasterViewportProvider: heatmapRasterViewportProvider,
          viewState: options.restoreViewState ? viewState : null,
          title: document.title,
          subtitle: document.subtitle,
          width: layout.width?.asDouble,
          height: layout.height?.asDouble,
          concentricDonutConfig: concentricDonutConfig,
          polarChartConfig: polarChartConfig,
          radialBarChartConfig: radialBarChartConfig,
          gaugeChartConfig: gaugeChartConfig,
          seriesCallouts: seriesCallouts,
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

  static List<HeatmapViewportProviderDescriptor>
  _decodeHeatmapViewportProviders(
    ChartDocument document,
    List<ChartSeries> series,
    ChartRuntimeBindings runtimeBindings,
  ) {
    final raw = document.configuration.values['heatmapViewportProviders'];
    final declaresCapability = document.requiredCapabilities.contains(
      HeatmapViewportProviderDescriptor.capabilityId,
    );
    if (raw == null) {
      if (declaresCapability) {
        throw const _HydrationFailure(
          ChartArtifactError(
            code: ChartArtifactDiagnosticCodes.invalidArtifact,
            message:
                'Heatmap viewport provider capability requires provider descriptors.',
            path: r'$.document.configuration.heatmapViewportProviders',
          ),
          [],
        );
      }
      return const [];
    }
    if (!declaresCapability) {
      throw const _HydrationFailure(
        ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.missingRequiredCapability,
          message:
              'Heatmap viewport provider descriptors require series.heatmap.viewport-provider.v1.',
          path: r'$.document.requiredCapabilities',
        ),
        [],
      );
    }
    if (raw is! JsonArrayValue) {
      throw const _HydrationFailure(
        ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.invalidArtifact,
          message: 'Heatmap viewport providers must be an array.',
          path: r'$.document.configuration.heatmapViewportProviders',
        ),
        [],
      );
    }
    final seriesById = {for (final item in series) item.id: item};
    final seenSeriesIds = <String>{};
    final descriptors = <HeatmapViewportProviderDescriptor>[];
    for (var index = 0; index < raw.values.length; index++) {
      final value = raw.values[index];
      if (value is! JsonObjectValue) {
        throw _HydrationFailure(
          ChartArtifactError(
            code: ChartArtifactDiagnosticCodes.invalidArtifact,
            message: 'Heatmap viewport provider must be an object.',
            path:
                r'$.document.configuration.heatmapViewportProviders['
                '$index]',
          ),
          const [],
        );
      }
      final descriptor = HeatmapViewportProviderDescriptor.fromDocument(value);
      if (!seenSeriesIds.add(descriptor.seriesId)) {
        throw _HydrationFailure(
          ChartArtifactError(
            code: ChartArtifactDiagnosticCodes.invalidArtifact,
            message:
                'Heatmap series "${descriptor.seriesId}" has more than one viewport provider.',
            path:
                r'$.document.configuration.heatmapViewportProviders['
                '$index].seriesId',
          ),
          const [],
        );
      }
      if (seriesById[descriptor.seriesId] is! HeatmapChartSeries) {
        throw _HydrationFailure(
          ChartArtifactError(
            code: ChartArtifactDiagnosticCodes.invalidArtifact,
            message:
                'Heatmap viewport provider target "${descriptor.seriesId}" is not a decoded Heatmap series.',
            path:
                r'$.document.configuration.heatmapViewportProviders['
                '$index].seriesId',
          ),
          const [],
        );
      }
      if (!runtimeBindings.heatmapViewportProviders.contains(
        descriptor.providerId,
      )) {
        throw _HydrationFailure(
          ChartArtifactError(
            code: ChartArtifactDiagnosticCodes.runtimeBindingRequired,
            message:
                'Heatmap viewport provider "${descriptor.providerId}" is not registered by the host.',
            path:
                r'$.document.configuration.heatmapViewportProviders['
                '$index].providerId',
          ),
          const [],
        );
      }
      descriptors.add(descriptor);
    }
    return List.unmodifiable(descriptors);
  }

  static HeatmapRasterViewportProviderDescriptor?
  _decodeHeatmapRasterViewportProvider(
    ChartDocument document,
    List<ChartSeries> series,
    List<HeatmapViewportProviderDescriptor> cellProviders,
    ChartRuntimeBindings runtimeBindings,
  ) {
    final raw = document.configuration.values['heatmapRasterViewportProvider'];
    final declaresCapability = document.requiredCapabilities.contains(
      HeatmapRasterViewportProviderDescriptor.capabilityId,
    );
    if (raw == null) {
      if (declaresCapability) {
        throw const _HydrationFailure(
          ChartArtifactError(
            code: ChartArtifactDiagnosticCodes.invalidArtifact,
            message:
                'Heatmap raster provider capability requires a provider descriptor.',
            path: r'$.document.configuration.heatmapRasterViewportProvider',
          ),
          [],
        );
      }
      return null;
    }
    if (!declaresCapability) {
      throw const _HydrationFailure(
        ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.missingRequiredCapability,
          message:
              'Heatmap raster provider descriptor requires series.heatmap.raster-provider.v1.',
          path: r'$.document.requiredCapabilities',
        ),
        [],
      );
    }
    if (raw is! JsonObjectValue) {
      throw const _HydrationFailure(
        ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.invalidArtifact,
          message: 'Heatmap raster viewport provider must be an object.',
          path: r'$.document.configuration.heatmapRasterViewportProvider',
        ),
        [],
      );
    }

    final descriptor = HeatmapRasterViewportProviderDescriptor.fromDocument(
      raw,
    );
    final semanticSeriesId = descriptor.semanticSeriesId;
    if (semanticSeriesId != null) {
      final target = series.where(
        (candidate) => candidate.id == semanticSeriesId,
      );
      if (target.length != 1 || target.single is! HeatmapChartSeries) {
        throw _HydrationFailure(
          ChartArtifactError(
            code: ChartArtifactDiagnosticCodes.invalidArtifact,
            message:
                'Heatmap raster semantic target "$semanticSeriesId" is not one decoded Heatmap series.',
            path:
                r'$.document.configuration.heatmapRasterViewportProvider.semanticSeriesId',
          ),
          const [],
        );
      }
      if (cellProviders.any(
        (provider) => provider.seriesId == semanticSeriesId,
      )) {
        throw _HydrationFailure(
          ChartArtifactError(
            code: ChartArtifactDiagnosticCodes.invalidArtifact,
            message:
                'Heatmap series "$semanticSeriesId" cannot use cell and raster viewport providers together.',
            path:
                r'$.document.configuration.heatmapRasterViewportProvider.semanticSeriesId',
          ),
          const [],
        );
      }
    }

    final hasRuntime = runtimeBindings.heatmapRasterViewportProviders.contains(
      descriptor.providerId,
    );
    if (!hasRuntime &&
        descriptor.fallback == HeatmapRasterProviderFallback.hardFailure) {
      throw _HydrationFailure(
        ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.runtimeBindingRequired,
          message:
              'Heatmap raster viewport provider "${descriptor.providerId}" is not registered by the host.',
          path:
              r'$.document.configuration.heatmapRasterViewportProvider.providerId',
        ),
        const [],
      );
    }
    return descriptor;
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
    if (config.hasCustomLabelAppearance &&
        !document.requiredCapabilities.contains(
          PolarChartConfig.labelAppearanceCapability,
        )) {
      throw const _HydrationFailure(
        ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.invalidArtifact,
          message: 'Custom Polar labels must declare chart.polar.labels.v1.',
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
    if (polarSeries.any(
          (series) =>
              series.polarStyle.cornerRadiusMode !=
              PolarColumnCornerRadiusMode.outerEnd,
        ) &&
        !document.requiredCapabilities.contains(
          PolarColumnChartSeries.cornerRadiusModeCapability,
        )) {
      throw const _HydrationFailure(
        ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.invalidArtifact,
          message:
              'Non-default Polar Column corner placement must declare series.polar.column.corner-radius-mode.v1.',
          path: r'$.document.requiredCapabilities',
        ),
        [],
      );
    }
    if (polarSeries.any((series) => series.polarStyle.hasAdvancedAppearance) &&
        !document.requiredCapabilities.contains(
          PolarColumnChartSeries.appearanceCapability,
        )) {
      throw const _HydrationFailure(
        ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.invalidArtifact,
          message:
              'Custom Polar Column appearance must declare series.polar.column.appearance.v1.',
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

  static void _validateRadialBarComposition({
    required ChartDocument document,
    required List<ChartSeries> series,
    required RadialBarChartConfig? config,
  }) {
    final radialBarSeries = series.whereType<RadialBarChartSeries>().toList(
      growable: false,
    );
    if (config == null) {
      if (radialBarSeries.isNotEmpty) {
        throw const _HydrationFailure(
          ChartArtifactError(
            code: ChartArtifactDiagnosticCodes.invalidArtifact,
            message:
                'Radial Bar series require chart-level Radial Bar configuration.',
            path: r'$.document.configuration.radialBarChart',
          ),
          [],
        );
      }
      return;
    }
    if (!document.requiredCapabilities.contains('chart.radial.bar.config.v1')) {
      throw const _HydrationFailure(
        ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.invalidArtifact,
          message:
              'Radial Bar configuration must declare chart.radial.bar.config.v1.',
          path: r'$.document.requiredCapabilities',
        ),
        [],
      );
    }
    if (radialBarSeries.length != 1 || series.length != 1) {
      throw const _HydrationFailure(
        ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.invalidArtifact,
          message:
              'Radial Bar v0.1 requires exactly one Radial Bar series and cannot mix chart families.',
          path: r'$.document.configuration.radialBarChart',
        ),
        [],
      );
    }
    final radialBar = radialBarSeries.single;
    for (final (index, threshold) in config.thresholds.indexed) {
      if (threshold.value < radialBar.minimum ||
          threshold.value > radialBar.maximum) {
        throw _HydrationFailure(
          ChartArtifactError(
            code: ChartArtifactDiagnosticCodes.invalidArtifact,
            message:
                'Radial Bar threshold ${threshold.value} is outside the series domain.',
            path:
                r'$.document.configuration.radialBarChart.thresholds['
                '$index]',
          ),
          const [],
        );
      }
    }
  }

  static void _validateGaugeComposition({
    required ChartDocument document,
    required List<ChartSeries> series,
    required GaugeChartConfig? config,
  }) {
    final gauges = series.whereType<GaugeChartSeries>().toList(growable: false);
    if (config == null) {
      if (gauges.isNotEmpty) {
        throw const _HydrationFailure(
          ChartArtifactError(
            code: ChartArtifactDiagnosticCodes.invalidArtifact,
            message: 'Gauge series require chart-level Gauge configuration.',
            path: r'$.document.configuration.gaugeChart',
          ),
          [],
        );
      }
      return;
    }
    if (!document.requiredCapabilities.contains('chart.gauge.config.v1')) {
      throw const _HydrationFailure(
        ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.invalidArtifact,
          message: 'Gauge configuration must declare chart.gauge.config.v1.',
          path: r'$.document.requiredCapabilities',
        ),
        [],
      );
    }
    if (gauges.length != 1 || series.length != 1) {
      throw const _HydrationFailure(
        ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.invalidArtifact,
          message:
              'Gauge V1 requires exactly one Gauge series and cannot mix chart families.',
          path: r'$.document.configuration.gaugeChart',
        ),
        [],
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
