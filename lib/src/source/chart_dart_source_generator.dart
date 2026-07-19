import 'package:flutter/material.dart';

import '../artifacts/chart_artifact_diagnostics.dart';
import '../artifacts/chart_document_hydrator.dart';
import '../artifacts/chart_document_extractor.dart';
import '../artifacts/chart_view_state.dart';
import '../models/annotation_style.dart';
import '../models/bar_chart_style.dart';
import '../models/chart_annotation.dart';
import '../models/chart_data_point.dart';
import '../models/chart_series.dart';
import '../models/chart_theme.dart';
import '../models/concentric_donut_config.dart';
import '../models/data_point_label_config.dart';
import '../models/donut_chart_config.dart';
import '../models/donut_chart_series.dart';
import '../models/grid_config.dart';
import '../models/interaction_config.dart';
import '../models/legend_style.dart';
import '../models/pie_chart_config.dart';
import '../models/pie_chart_series.dart';
import '../models/polar_chart_config.dart';
import '../models/polar_column_chart_series.dart';
import '../models/radial_category_series.dart';
import '../models/radial_selection_style.dart';
import '../models/scatter_marker_style.dart';
import '../models/segment_style.dart';
import '../models/series_inline_label_config.dart';
import '../models/x_axis_config.dart';
import '../models/y_axis_config.dart';
import '../theming/components/animation_theme.dart';
import '../theming/components/annotation_theme.dart';
import '../theming/components/axis_style.dart';
import '../theming/components/grid_style.dart';
import '../theming/components/interaction_theme.dart';
import '../theming/components/scrollbar_config.dart';
import '../theming/components/series_theme.dart' as series_theme;
import '../theming/components/typography_theme.dart';
import '../theming/styles/label_style.dart';
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
    );
    if (hydrated case ChartArtifactFailure<HydratedChartConfiguration>()) {
      return ChartArtifactFailure(
        error: hydrated.error,
        warnings: hydrated.warnings,
      );
    }

    final success =
        hydrated as ChartArtifactSuccess<HydratedChartConfiguration>;
    final emitter = _ChartDartEmitter(
      snapshot: snapshot,
      configuration: success.value,
      options: options,
    );
    final generated = emitter.generate();
    return ChartArtifactSuccess(value: generated, warnings: success.warnings);
  }
}

class _ChartDartEmitter {
  _ChartDartEmitter({
    required this.snapshot,
    required this.configuration,
    required this.options,
  });

  final ChartDocumentSnapshot snapshot;
  final HydratedChartConfiguration configuration;
  final ChartDartSourceOptions options;
  final List<ChartSourceWarning> _warnings = [];
  late final bool _omitData =
      snapshot.document.pointCount > options.maxInlinePoints;

  ChartGeneratedSource generate() {
    _captureKnownLimitations();
    final body = DartSourceWriter();
    final viewState = options.includeViewState ? snapshot.viewState : null;
    final controllerName = '${options.variableName}Controller';
    if (viewState != null) {
      body.writeLine('final $controllerName = BravenChartController();');
      body.writeLine();
    }
    body.writeLine('final ${options.variableName} = BravenChartPlus(');
    body.indented(() {
      if (viewState != null) {
        body.namedArgument('bravenChartController', controllerName);
      }
      _optionalString(body, 'title', configuration.title);
      _optionalString(body, 'subtitle', configuration.subtitle);
      _emitSeriesList(body);
      final concentricDonutConfig = configuration.concentricDonutConfig;
      if (concentricDonutConfig != null) {
        _emitConcentricDonutConfig(body, concentricDonutConfig);
      }
      if (configuration.polarChartConfig case final polarConfig?) {
        _emitPolarChartConfig(body, polarConfig);
      }
      if (configuration.annotations.isNotEmpty) {
        _emitAnnotationList(body, 'annotations', configuration.annotations);
      }
      _emitXAxis(body, configuration.xAxis);
      final primaryAxis = configuration.primaryYAxis;
      if (primaryAxis != null) _emitYAxis(body, 'yAxis', primaryAxis);
      _emitThemeReference(body);
      _emitInteraction(body, configuration.interaction);
      _emitGrid(body, configuration.grid);
      _valueIf(
        body,
        'showLegend',
        configuration.showLegend,
        defaultValue: true,
      );
      _emitLegendStyle(body, configuration.legendStyle);
      _valueIf(
        body,
        'showToolbar',
        configuration.showToolbar,
        defaultValue: false,
      );
      _valueIf(
        body,
        'interactiveAnnotations',
        configuration.interactiveAnnotations,
        defaultValue: true,
      );
      _valueIf(
        body,
        'maxAxesPerSide',
        configuration.maxAxesPerSide,
        defaultValue: 3,
      );
      _enumIf(
        body,
        'axisSwapMode',
        'AxisSwapMode',
        configuration.axisSwapMode.name,
        defaultName: 'sticky',
      );
      _enumIf(
        body,
        'normalizationMode',
        'NormalizationMode',
        configuration.normalizationMode.name,
        defaultName: 'none',
      );
      _optionalNumber(body, 'width', configuration.width);
      _optionalNumber(body, 'height', configuration.height);
      if (snapshot.document.layout.backgroundColor != null) {
        body.namedArgument(
          'backgroundColor',
          DartSourceWriter.colorLiteral(configuration.backgroundColor),
        );
      }
    });
    body.writeLine(');');
    if (viewState != null) {
      body.writeLine();
      _emitViewStateRestoration(body, viewState, controllerName);
    }

    // Build the header after the body so warnings discovered while emitting a
    // nested option are visible both in the result metadata and in copied code.
    final writer = DartSourceWriter();
    if (options.includeImports) {
      writer.writeLine("import 'package:braven_charts/braven_charts.dart';");
      writer.writeLine("import 'package:flutter/material.dart';");
      writer.writeLine();
    }
    if (_warnings.isNotEmpty) {
      writer.writeLine(
        '// Generated from the current effective chart configuration.',
      );
      for (final warning in _warnings) {
        writer.writeLine('// ${warning.message}');
      }
      writer.writeLine();
    }
    writer.write(body.toString());

    final omittedPointCount = _omitData ? snapshot.document.pointCount : 0;
    return ChartGeneratedSource(
      source: writer.toString(),
      revision: snapshot.revision,
      completeness: _warnings.isEmpty
          ? ChartGeneratedSourceCompleteness.complete
          : ChartGeneratedSourceCompleteness.portableWithPlaceholders,
      warnings: _warnings,
      seriesCount: configuration.series.length,
      pointCount: snapshot.document.pointCount,
      omittedPointCount: omittedPointCount,
    );
  }

  void _captureKnownLimitations() {
    if (_omitData) {
      _warn(
        code: ChartSourceWarningCodes.dataOmitted,
        message:
            '${snapshot.document.pointCount} points omitted because maxInlinePoints is ${options.maxInlinePoints}. Supply application data in the generated point lists.',
        path: r'$.series[*].data',
      );
    }
    if (snapshot.document.interaction.requiredBindings.isNotEmpty) {
      final bindings = snapshot.document.interaction.requiredBindings.toList()
        ..sort();
      _warn(
        code: ChartSourceWarningCodes.runtimeValueOmitted,
        message:
            'Runtime interaction bindings omitted: ${bindings.join(', ')}. Provide these callbacks from your application.',
        path: r'$.interaction.requiredBindings',
      );
    }
  }

  void _emitSeriesList(DartSourceWriter writer) {
    writer.writeLine('series: [');
    writer.indented(() {
      for (var index = 0; index < configuration.series.length; index++) {
        _emitSeries(writer, configuration.series[index], index);
      }
    });
    writer.writeLine('],');
  }

  void _emitSeries(
    DartSourceWriter writer,
    ChartSeries series,
    int seriesIndex,
  ) {
    final constructor = switch (series) {
      LineChartSeries() => 'LineChartSeries',
      ScatterChartSeries() => 'ScatterChartSeries',
      AreaChartSeries() => 'AreaChartSeries',
      BarChartSeries() => 'BarChartSeries',
      PieChartSeries() => 'PieChartSeries',
      DonutChartSeries() => 'DonutChartSeries',
      PolarColumnChartSeries() => 'PolarColumnChartSeries',
      ChartSeries() => 'ChartSeries',
    };
    writer.writeLine('$constructor(');
    writer.indented(() {
      writer.namedArgument('id', DartSourceWriter.stringLiteral(series.id));
      _optionalString(writer, 'name', series.name);
      _emitPoints(writer, series, seriesIndex);
      _optionalColor(writer, 'color', series.color);
      if (series.metadata != null && series.metadata!.isNotEmpty) {
        writer.namedArgument('metadata', _dynamicLiteral(series.metadata!));
      }
      if (series.annotations.isNotEmpty) {
        _emitAnnotationList(
          writer,
          'annotations',
          series.annotations,
          pathPrefix: '\$.series[$seriesIndex].annotations',
        );
      }
      if (series is! PolarColumnChartSeries) {
        _valueIf(
          writer,
          'isXOrdered',
          series.isXOrdered,
          defaultValue: series is PieChartSeries || series is DonutChartSeries,
        );
      }
      _optionalString(writer, 'yAxisId', series.yAxisId);
      if (series.yAxisConfig != null) {
        _emitYAxis(writer, 'yAxisConfig', series.yAxisConfig!);
      }
      _optionalString(writer, 'unit', series.unit);
      switch (series) {
        case LineChartSeries():
          _emitLineOptions(writer, series);
        case AreaChartSeries():
          _emitAreaOptions(writer, series);
        case ScatterChartSeries():
          _numberIf(writer, 'markerRadius', series.markerRadius, 5);
          _enumIf(
            writer,
            'markerShape',
            'SeriesMarkerShape',
            series.markerShape.name,
            defaultName: 'circle',
          );
          if (series.markerStyle != null) {
            _emitScatterMarkerStyle(writer, 'markerStyle', series.markerStyle!);
          }
          if (series.sizeEncoding != null) {
            _emitScatterSizeEncoding(writer, series.sizeEncoding!);
          }
          if (series.colorEncoding != null) {
            _emitScatterColorEncoding(writer, series.colorEncoding!);
          }
          if (series.opacityEncoding != null) {
            _emitScatterOpacityEncoding(writer, series.opacityEncoding!);
          }
          if (series.interactionStyle != const ScatterInteractionStyle()) {
            _emitScatterInteraction(
              writer,
              'interactionStyle',
              series.interactionStyle,
            );
          }
        case BarChartSeries():
          _emitBarOptions(writer, series, seriesIndex);
        case PieChartSeries():
          _emitPieOptions(writer, series, seriesIndex);
        case DonutChartSeries():
          _emitDonutOptions(writer, series, seriesIndex);
        case PolarColumnChartSeries():
          _emitPolarColumnOptions(writer, series);
        case ChartSeries():
          break;
      }
    });
    writer.writeLine('),');
  }

  void _emitPoints(
    DartSourceWriter writer,
    ChartSeries series,
    int seriesIndex,
  ) {
    writer.writeLine('points: [');
    writer.indented(() {
      if (_omitData) {
        writer.writeLine(
          '// ${series.points.length} points omitted. Supply this series data here.',
        );
        return;
      }
      for (
        var pointIndex = 0;
        pointIndex < series.points.length;
        pointIndex++
      ) {
        _emitPoint(writer, series.points[pointIndex], seriesIndex, pointIndex);
      }
    });
    writer.writeLine('],');
  }

  void _emitPoint(
    DartSourceWriter writer,
    ChartDataPoint point,
    int seriesIndex,
    int pointIndex,
  ) {
    writer.writeLine('ChartDataPoint(');
    writer.indented(() {
      writer.namedArgument('x', DartSourceWriter.numberLiteral(point.x));
      writer.namedArgument('y', DartSourceWriter.numberLiteral(point.y));
      _optionalNumber(writer, 'magnitude', point.magnitude);
      _optionalNumber(writer, 'colorValue', point.colorValue);
      _optionalNumber(writer, 'opacityValue', point.opacityValue);
      if (point.timestamp != null) {
        writer.namedArgument(
          'timestamp',
          'DateTime.parse(${DartSourceWriter.stringLiteral(point.timestamp!.toIso8601String())})',
        );
      }
      _optionalString(writer, 'label', point.label);
      if (point.segmentStyle != null) {
        _emitSegmentStyle(writer, point.segmentStyle!);
      }
      if (point.pointStyle != null) {
        _emitPointStyle(writer, point.pointStyle!);
      }
      if (point.metadata != null && point.metadata!.isNotEmpty) {
        writer.namedArgument('metadata', _dynamicLiteral(point.metadata!));
      }
    });
    writer.writeLine('),');
  }

  void _emitSegmentStyle(DartSourceWriter writer, SegmentStyle style) {
    writer.writeLine('segmentStyle: SegmentStyle(');
    writer.indented(() {
      _optionalColor(writer, 'color', style.color);
      _optionalNumber(writer, 'strokeWidth', style.strokeWidth);
      _optionalNumberList(writer, 'dashPattern', style.dashPattern);
    });
    writer.writeLine('),');
  }

  void _emitPointStyle(DartSourceWriter writer, PointStyle style) {
    writer.writeLine('pointStyle: PointStyle(');
    writer.indented(() {
      _optionalColor(writer, 'color', style.color);
      _optionalNumber(writer, 'size', style.size);
      if (style.scatterMarkerShape != null) {
        writer.namedArgument(
          'scatterMarkerShape',
          'SeriesMarkerShape.${style.scatterMarkerShape!.name}',
        );
      }
      if (style.scatterMarkerStyle != null) {
        _emitScatterMarkerStyle(
          writer,
          'scatterMarkerStyle',
          style.scatterMarkerStyle!,
        );
      }
    });
    writer.writeLine('),');
  }

  void _emitScatterMarkerStyle(
    DartSourceWriter writer,
    String argument,
    ScatterMarkerStyle style,
  ) {
    writer.writeLine('$argument: ScatterMarkerStyle(');
    writer.indented(() {
      _optionalColor(writer, 'fillColor', style.fillColor);
      _optionalColor(writer, 'strokeColor', style.strokeColor);
      _optionalNumber(writer, 'strokeWidth', style.strokeWidth);
      _optionalNumber(writer, 'opacity', style.opacity);
      _optionalNumber(writer, 'width', style.width);
      _optionalNumber(writer, 'height', style.height);
      _optionalNumber(writer, 'rotationDegrees', style.rotationDegrees);
    });
    writer.writeLine('),');
  }

  void _emitScatterSizeEncoding(
    DartSourceWriter writer,
    ScatterSizeEncoding encoding,
  ) {
    writer.writeLine('sizeEncoding: ScatterSizeEncoding(');
    writer.indented(() {
      _numberIf(writer, 'minimumRadius', encoding.minimumRadius, 4);
      _numberIf(writer, 'maximumRadius', encoding.maximumRadius, 24);
      _numberIf(writer, 'minimumValue', encoding.minimumValue, 0);
      _optionalNumber(writer, 'maximumValue', encoding.maximumValue);
      if (options.includeDefaultValues || encoding.label != 'Magnitude') {
        writer.namedArgument(
          'label',
          DartSourceWriter.stringLiteral(encoding.label),
        );
      }
      _optionalString(writer, 'unit', encoding.unit);
      _valueIf(writer, 'showLegend', encoding.showLegend, defaultValue: true);
    });
    writer.writeLine('),');
  }

  void _emitScatterColorEncoding(
    DartSourceWriter writer,
    ScatterColorEncoding encoding,
  ) {
    writer.writeLine('colorEncoding: ScatterColorEncoding(');
    writer.indented(() {
      writer.writeLine('colors: [');
      writer.indented(() {
        for (final color in encoding.colors) {
          writer.writeLine('${DartSourceWriter.colorLiteral(color)},');
        }
      });
      writer.writeLine('],');
      if (encoding.scaleType != ScatterColorScaleType.continuous) {
        writer.namedArgument(
          'scaleType',
          'ScatterColorScaleType.${encoding.scaleType.name}',
        );
      }
      if (encoding.thresholds.isNotEmpty) {
        writer.namedArgument(
          'thresholds',
          '[${encoding.thresholds.map(DartSourceWriter.numberLiteral).join(', ')}]',
        );
      }
      if (encoding.bandLabels.isNotEmpty) {
        writer.namedArgument(
          'bandLabels',
          '[${encoding.bandLabels.map(DartSourceWriter.stringLiteral).join(', ')}]',
        );
      }
      _optionalNumber(writer, 'minimumValue', encoding.minimumValue);
      _optionalNumber(writer, 'maximumValue', encoding.maximumValue);
      if (options.includeDefaultValues || encoding.label != 'Color value') {
        writer.namedArgument(
          'label',
          DartSourceWriter.stringLiteral(encoding.label),
        );
      }
      _optionalString(writer, 'unit', encoding.unit);
      _valueIf(writer, 'showLegend', encoding.showLegend, defaultValue: true);
    });
    writer.writeLine('),');
  }

  void _emitScatterOpacityEncoding(
    DartSourceWriter writer,
    ScatterOpacityEncoding encoding,
  ) {
    writer.writeLine('opacityEncoding: ScatterOpacityEncoding(');
    writer.indented(() {
      _numberIf(writer, 'minimumOpacity', encoding.minimumOpacity, 0.2);
      _numberIf(writer, 'maximumOpacity', encoding.maximumOpacity, 1);
      _optionalNumber(writer, 'minimumValue', encoding.minimumValue);
      _optionalNumber(writer, 'maximumValue', encoding.maximumValue);
      if (options.includeDefaultValues || encoding.label != 'Opacity value') {
        writer.namedArgument(
          'label',
          DartSourceWriter.stringLiteral(encoding.label),
        );
      }
      _optionalString(writer, 'unit', encoding.unit);
      _valueIf(writer, 'showLegend', encoding.showLegend, defaultValue: true);
    });
    writer.writeLine('),');
  }

  void _emitScatterInteraction(
    DartSourceWriter writer,
    String argument,
    ScatterInteractionStyle style,
  ) {
    writer.writeLine('$argument: ScatterInteractionStyle(');
    writer.indented(() {
      _optionalColor(writer, 'hoverColor', style.hoverColor);
      writer.namedArgument(
        'hoverScale',
        DartSourceWriter.numberLiteral(style.hoverScale),
      );
      writer.namedArgument(
        'hoverStrokeWidth',
        DartSourceWriter.numberLiteral(style.hoverStrokeWidth),
      );
      writer.namedArgument(
        'pressedColor',
        DartSourceWriter.colorLiteral(style.pressedColor),
      );
      writer.namedArgument(
        'pressedScale',
        DartSourceWriter.numberLiteral(style.pressedScale),
      );
      writer.namedArgument(
        'pressedOpacity',
        DartSourceWriter.numberLiteral(style.pressedOpacity),
      );
      _optionalColor(writer, 'selectionColor', style.selectionColor);
      writer.namedArgument(
        'selectionScale',
        DartSourceWriter.numberLiteral(style.selectionScale),
      );
      writer.namedArgument(
        'selectionOpacity',
        DartSourceWriter.numberLiteral(style.selectionOpacity),
      );
      writer.namedArgument(
        'selectionStrokeWidth',
        DartSourceWriter.numberLiteral(style.selectionStrokeWidth),
      );
      _optionalColor(writer, 'focusColor', style.focusColor);
      writer.namedArgument(
        'focusGap',
        DartSourceWriter.numberLiteral(style.focusGap),
      );
      writer.namedArgument(
        'focusStrokeWidth',
        DartSourceWriter.numberLiteral(style.focusStrokeWidth),
      );
      writer.namedArgument(
        'dimmedOpacity',
        DartSourceWriter.numberLiteral(style.dimmedOpacity),
      );
    });
    writer.writeLine('),');
  }

  void _emitAnnotationList(
    DartSourceWriter writer,
    String argument,
    List<ChartAnnotation> annotations, {
    String pathPrefix = r'$.annotations',
  }) {
    writer.writeLine('$argument: [');
    writer.indented(() {
      for (var index = 0; index < annotations.length; index++) {
        _emitAnnotation(writer, annotations[index], '$pathPrefix[$index]');
      }
    });
    writer.writeLine('],');
  }

  void _emitAnnotation(
    DartSourceWriter writer,
    ChartAnnotation annotation,
    String path,
  ) {
    final constructor = switch (annotation) {
      PointAnnotation() => 'PointAnnotation',
      RangeAnnotation() => 'RangeAnnotation',
      TextAnnotation(isRichText: true) => 'TextAnnotation.rich',
      TextAnnotation() => 'TextAnnotation',
      ThresholdAnnotation() => 'ThresholdAnnotation',
      PinAnnotation() => 'PinAnnotation',
      TrendAnnotation() => 'TrendAnnotation',
      ChordAnnotation() => 'ChordAnnotation',
      LegendAnnotation() => 'LegendAnnotation',
    };
    writer.writeLine('$constructor(');
    writer.indented(() {
      writer.namedArgument('id', DartSourceWriter.stringLiteral(annotation.id));
      _optionalString(writer, 'label', annotation.label);
      _valueIf(
        writer,
        'allowDragging',
        annotation.allowDragging,
        defaultValue: _annotationDefaultDragging(annotation),
      );
      _valueIf(
        writer,
        'allowEditing',
        annotation.allowEditing,
        defaultValue: annotation is RangeAnnotation,
      );
      _numberIf(writer, 'zIndex', annotation.zIndex, 0);
      if (annotation.style != const AnnotationStyle()) {
        _emitAnnotationStyle(writer, annotation.style);
      }
      switch (annotation) {
        case PointAnnotation():
          _emitPointAnnotation(writer, annotation);
        case RangeAnnotation():
          _emitRangeAnnotation(writer, annotation);
        case TextAnnotation():
          _emitTextAnnotation(writer, annotation);
        case ThresholdAnnotation():
          _emitThresholdAnnotation(writer, annotation);
        case PinAnnotation():
          _emitPinAnnotation(writer, annotation);
        case TrendAnnotation():
          _emitTrendAnnotation(writer, annotation);
        case ChordAnnotation():
          _emitChordAnnotation(writer, annotation, path);
        case LegendAnnotation():
          _emitLegendAnnotation(writer, annotation, path);
      }
    });
    writer.writeLine('),');
  }

  bool _annotationDefaultDragging(ChartAnnotation annotation) =>
      switch (annotation) {
        RangeAnnotation() => true,
        LegendAnnotation() => annotation.legendStyle.allowDragging,
        _ => false,
      };

  void _emitAnnotationStyle(
    DartSourceWriter writer,
    AnnotationStyle style, {
    String name = 'style',
  }) {
    writer.writeLine('$name: AnnotationStyle(');
    writer.indented(() {
      _emitTextStyle(writer, 'textStyle', style.textStyle);
      _optionalColor(writer, 'backgroundColor', style.backgroundColor);
      _optionalColor(writer, 'borderColor', style.borderColor);
      _numberIf(writer, 'borderWidth', style.borderWidth, 1);
      if (style.borderRadius != null) {
        writer.namedArgument(
          'borderRadius',
          _borderRadiusLiteral(style.borderRadius!),
        );
      }
      if (style.padding != null) {
        writer.namedArgument('padding', _edgeInsetsLiteral(style.padding!));
      }
    });
    writer.writeLine('),');
  }

  void _emitPointAnnotation(
    DartSourceWriter writer,
    PointAnnotation annotation,
  ) {
    writer.namedArgument(
      'seriesId',
      DartSourceWriter.stringLiteral(annotation.seriesId),
    );
    writer.namedArgument(
      'dataPointIndex',
      annotation.dataPointIndex.toString(),
    );
    _offsetIf(writer, 'offset', annotation.offset, Offset.zero);
    _enumIf(
      writer,
      'markerShape',
      'MarkerShape',
      annotation.markerShape.name,
      defaultName: 'circle',
    );
    _numberIf(writer, 'markerSize', annotation.markerSize, 8);
    _colorIf(writer, 'markerColor', annotation.markerColor, Colors.blue);
    _numberIf(writer, 'labelMargin', annotation.labelMargin, 4);
  }

  void _emitRangeAnnotation(
    DartSourceWriter writer,
    RangeAnnotation annotation,
  ) {
    _valueIf(
      writer,
      'snapToValue',
      annotation.snapToValue,
      defaultValue: false,
    );
    _numberIf(writer, 'snapIncrement', annotation.snapIncrement, 0.5);
    _numberIf(writer, 'snapTolerance', annotation.snapTolerance, 0.05);
    _optionalNumber(writer, 'startX', annotation.startX);
    _optionalNumber(writer, 'endX', annotation.endX);
    _optionalNumber(writer, 'startY', annotation.startY);
    _optionalNumber(writer, 'endY', annotation.endY);
    _optionalString(writer, 'seriesId', annotation.seriesId);
    _optionalColor(writer, 'fillColor', annotation.fillColor);
    _optionalColor(writer, 'borderColor', annotation.borderColor);
    _enumIf(
      writer,
      'labelPosition',
      'AnnotationLabelPosition',
      annotation.labelPosition.name,
      defaultName: 'topLeft',
    );
    _numberIf(writer, 'labelMargin', annotation.labelMargin, 8);
  }

  void _emitTextAnnotation(DartSourceWriter writer, TextAnnotation annotation) {
    if (annotation.isRichText) {
      writer.namedArgument(
        'richTextDelta',
        _dynamicLiteral(annotation.richTextDelta!),
      );
    } else {
      writer.namedArgument(
        'text',
        DartSourceWriter.stringLiteral(annotation.text!),
      );
    }
    writer.namedArgument('position', _offsetLiteral(annotation.position));
    _enumIf(
      writer,
      'anchor',
      'AnnotationAnchor',
      annotation.anchor.name,
      defaultName: 'topLeft',
    );
    _optionalColor(writer, 'backgroundColor', annotation.backgroundColor);
    _optionalColor(writer, 'borderColor', annotation.borderColor);
  }

  void _emitThresholdAnnotation(
    DartSourceWriter writer,
    ThresholdAnnotation annotation,
  ) {
    writer.namedArgument('axis', 'AnnotationAxis.${annotation.axis.name}');
    writer.namedArgument(
      'value',
      DartSourceWriter.numberLiteral(annotation.value),
    );
    _optionalString(writer, 'seriesId', annotation.seriesId);
    _colorIf(writer, 'lineColor', annotation.lineColor, Colors.black);
    _numberIf(writer, 'lineWidth', annotation.lineWidth, 1);
    _optionalNumberList(writer, 'dashPattern', annotation.dashPattern);
    _enumIf(
      writer,
      'labelPosition',
      'AnnotationLabelPosition',
      annotation.labelPosition.name,
      defaultName: 'topLeft',
    );
    _numberIf(writer, 'labelMargin', annotation.labelMargin, 8);
    _numberIf(writer, 'elevation', annotation.elevation, 0);
  }

  void _emitPinAnnotation(DartSourceWriter writer, PinAnnotation annotation) {
    writer.namedArgument('x', DartSourceWriter.numberLiteral(annotation.x));
    writer.namedArgument('y', DartSourceWriter.numberLiteral(annotation.y));
    _enumIf(
      writer,
      'markerShape',
      'MarkerShape',
      annotation.markerShape.name,
      defaultName: 'circle',
    );
    _numberIf(writer, 'markerSize', annotation.markerSize, 8);
    _colorIf(writer, 'markerColor', annotation.markerColor, Colors.blue);
    _numberIf(writer, 'labelMargin', annotation.labelMargin, 4);
  }

  void _emitTrendAnnotation(
    DartSourceWriter writer,
    TrendAnnotation annotation,
  ) {
    _optionalString(writer, 'seriesId', annotation.seriesId);
    writer.namedArgument('trendType', 'TrendType.${annotation.trendType.name}');
    if (annotation.windowSize != null) {
      writer.namedArgument('windowSize', annotation.windowSize.toString());
    }
    _numberIf(writer, 'degree', annotation.degree, 2);
    _colorIf(writer, 'lineColor', annotation.lineColor, Colors.blue);
    _numberIf(writer, 'lineWidth', annotation.lineWidth, 2);
    _optionalNumberList(writer, 'dashPattern', annotation.dashPattern);
    _numberIf(writer, 'elevation', annotation.elevation, 0);
  }

  void _emitChordAnnotation(
    DartSourceWriter writer,
    ChordAnnotation annotation,
    String path,
  ) {
    writer.namedArgument(
      'seriesId',
      DartSourceWriter.stringLiteral(annotation.seriesId),
    );
    writer.namedArgument('startIndex', annotation.startIndex.toString());
    writer.namedArgument('endIndex', annotation.endIndex.toString());
    _colorIf(writer, 'lineColor', annotation.lineColor, Colors.blue);
    _numberIf(writer, 'lineWidth', annotation.lineWidth, 2);
    _optionalNumberList(writer, 'dashPattern', annotation.dashPattern);
    _numberIf(writer, 'elevation', annotation.elevation, 0);
    if (annotation.perpendicularIndex != null) {
      writer.namedArgument(
        'perpendicularIndex',
        annotation.perpendicularIndex.toString(),
      );
    }
    _optionalString(
      writer,
      'perpendicularLabel',
      annotation.perpendicularLabel,
    );
    _offsetIf(
      writer,
      'perpendicularLabelOffset',
      annotation.perpendicularLabelOffset,
      Offset.zero,
    );
    _optionalColor(
      writer,
      'perpendicularLineColor',
      annotation.perpendicularLineColor,
    );
    _optionalNumber(
      writer,
      'perpendicularLineWidth',
      annotation.perpendicularLineWidth,
    );
    _optionalNumberList(
      writer,
      'perpendicularDashPattern',
      annotation.perpendicularDashPattern,
    );
    _optionalNumber(
      writer,
      'perpendicularElevation',
      annotation.perpendicularElevation,
    );
    if (annotation.perpendicularLabelStyle != null) {
      _emitAnnotationStyle(
        writer,
        annotation.perpendicularLabelStyle!,
        name: 'perpendicularLabelStyle',
      );
    }
  }

  void _emitLegendAnnotation(
    DartSourceWriter writer,
    LegendAnnotation annotation,
    String path,
  ) {
    writer.writeLine('series: [');
    writer.indented(() {
      for (var index = 0; index < annotation.series.length; index++) {
        _emitSeries(writer, annotation.series[index], index);
      }
    });
    writer.writeLine('],');
    if (annotation.trendAnnotations.isNotEmpty) {
      _emitAnnotationList(
        writer,
        'trendAnnotations',
        annotation.trendAnnotations,
        pathPrefix: '$path.trendAnnotations',
      );
    }
    final sizeScale = annotation.sizeScale;
    if (sizeScale != null) {
      writer.writeLine('sizeScale: LegendSizeScale(');
      writer.indented(() {
        writer.namedArgument(
          'label',
          DartSourceWriter.stringLiteral(sizeScale.label),
        );
        writer.namedArgument(
          'color',
          DartSourceWriter.colorLiteral(sizeScale.color),
        );
        writer.writeLine('samples: [');
        writer.indented(() {
          for (final sample in sizeScale.samples) {
            writer.writeLine('LegendSizeSample(');
            writer.indented(() {
              writer.namedArgument(
                'radius',
                DartSourceWriter.numberLiteral(sample.radius),
              );
              writer.namedArgument(
                'label',
                DartSourceWriter.stringLiteral(sample.label),
              );
            });
            writer.writeLine('),');
          }
        });
        writer.writeLine('],');
      });
      writer.writeLine('),');
    }
    final colorScale = annotation.colorScale;
    if (colorScale != null) {
      writer.writeLine('colorScale: LegendColorScale(');
      writer.indented(() {
        writer.namedArgument(
          'label',
          DartSourceWriter.stringLiteral(colorScale.label),
        );
        writer.writeLine('colors: [');
        writer.indented(() {
          for (final color in colorScale.colors) {
            writer.writeLine('${DartSourceWriter.colorLiteral(color)},');
          }
        });
        writer.writeLine('],');
        if (colorScale.type != LegendColorScaleType.continuous) {
          writer.namedArgument(
            'type',
            'LegendColorScaleType.${colorScale.type.name}',
          );
        }
        if (colorScale.segmentLabels.isNotEmpty) {
          writer.namedArgument(
            'segmentLabels',
            '[${colorScale.segmentLabels.map(DartSourceWriter.stringLiteral).join(', ')}]',
          );
        }
        writer.namedArgument(
          'minimumLabel',
          DartSourceWriter.stringLiteral(colorScale.minimumLabel),
        );
        _optionalString(writer, 'midpointLabel', colorScale.midpointLabel);
        writer.namedArgument(
          'maximumLabel',
          DartSourceWriter.stringLiteral(colorScale.maximumLabel),
        );
      });
      writer.writeLine('),');
    }
    final opacityScale = annotation.opacityScale;
    if (opacityScale != null) {
      writer.writeLine('opacityScale: LegendOpacityScale(');
      writer.indented(() {
        writer.namedArgument(
          'label',
          DartSourceWriter.stringLiteral(opacityScale.label),
        );
        writer.namedArgument(
          'color',
          DartSourceWriter.colorLiteral(opacityScale.color),
        );
        writer.namedArgument(
          'minimumOpacity',
          DartSourceWriter.numberLiteral(opacityScale.minimumOpacity),
        );
        writer.namedArgument(
          'maximumOpacity',
          DartSourceWriter.numberLiteral(opacityScale.maximumOpacity),
        );
        writer.namedArgument(
          'minimumLabel',
          DartSourceWriter.stringLiteral(opacityScale.minimumLabel),
        );
        _optionalString(writer, 'midpointLabel', opacityScale.midpointLabel);
        writer.namedArgument(
          'maximumLabel',
          DartSourceWriter.stringLiteral(opacityScale.maximumLabel),
        );
      });
      writer.writeLine('),');
    }
    _emitLegendStyle(writer, annotation.legendStyle, force: true);
    if (annotation.hiddenSeriesIds.isNotEmpty) {
      final ids = annotation.hiddenSeriesIds.toList()..sort();
      writer.namedArgument(
        'hiddenSeriesIds',
        '{${ids.map(DartSourceWriter.stringLiteral).join(', ')}}',
      );
    }
    _optionalOffset(writer, 'customPosition', annotation.customPosition);
    if (annotation.onSeriesToggle != null) {
      writer.writeLine(
        '// onSeriesToggle: (seriesId) { ... }, // Supply application state.',
      );
      _warn(
        code: ChartSourceWarningCodes.runtimeValueOmitted,
        message:
            'The canvas legend toggle callback was omitted. Provide it from your application.',
        path: '$path.onSeriesToggle',
      );
    }
  }

  void _emitLineOptions(DartSourceWriter writer, LineChartSeries series) {
    _enumIf(
      writer,
      'interpolation',
      'LineInterpolation',
      series.interpolation.name,
      defaultName: 'linear',
    );
    _numberIf(writer, 'strokeWidth', series.strokeWidth, 2);
    _numberIf(writer, 'tension', series.tension, 0.25);
    _valueIf(
      writer,
      'showDataPointMarkers',
      series.showDataPointMarkers,
      defaultValue: false,
    );
    _numberIf(writer, 'dataPointMarkerRadius', series.dataPointMarkerRadius, 3);
    _enumIf(
      writer,
      'dataPointMarkerStyle',
      'DataPointMarkerStyle',
      series.dataPointMarkerStyle.name,
      defaultName: 'filled',
    );
    _numberIf(writer, 'lineGlow', series.lineGlow, 0);
    _optionalNumberList(writer, 'dashPattern', series.dashPattern);
    _emitSeriesLabelConfig(
      writer,
      dataPointLabels: series.dataPointLabels,
      inlineLabel: series.inlineLabel,
    );
  }

  void _emitAreaOptions(DartSourceWriter writer, AreaChartSeries series) {
    _emitLineLikeAreaOptions(writer, series);
    _numberIf(writer, 'fillOpacity', series.fillOpacity, 0.3);
    _optionalNumber(writer, 'baselineValue', series.baselineValue);
    _optionalColor(
      writer,
      'aboveBaselineFillColor',
      series.aboveBaselineFillColor,
    );
    _optionalColor(
      writer,
      'belowBaselineFillColor',
      series.belowBaselineFillColor,
    );
    _emitSeriesLabelConfig(
      writer,
      dataPointLabels: series.dataPointLabels,
      inlineLabel: series.inlineLabel,
    );
  }

  void _emitLineLikeAreaOptions(
    DartSourceWriter writer,
    AreaChartSeries series,
  ) {
    _enumIf(
      writer,
      'interpolation',
      'LineInterpolation',
      series.interpolation.name,
      defaultName: 'linear',
    );
    _numberIf(writer, 'strokeWidth', series.strokeWidth, 2);
    _numberIf(writer, 'tension', series.tension, 0.25);
    _valueIf(
      writer,
      'showDataPointMarkers',
      series.showDataPointMarkers,
      defaultValue: false,
    );
    _numberIf(writer, 'dataPointMarkerRadius', series.dataPointMarkerRadius, 3);
    _enumIf(
      writer,
      'dataPointMarkerStyle',
      'DataPointMarkerStyle',
      series.dataPointMarkerStyle.name,
      defaultName: 'filled',
    );
    _numberIf(writer, 'lineGlow', series.lineGlow, 0);
    _optionalNumberList(writer, 'dashPattern', series.dashPattern);
  }

  void _emitSeriesLabelConfig(
    DartSourceWriter writer, {
    required DataPointLabelConfig? dataPointLabels,
    required SeriesInlineLabelConfig? inlineLabel,
  }) {
    if (dataPointLabels != null) {
      writer.writeLine('dataPointLabels: DataPointLabelConfig(');
      writer.indented(() {
        _valueIf(writer, 'show', dataPointLabels.show, defaultValue: false);
        _enumIf(
          writer,
          'position',
          'DataPointLabelPosition',
          dataPointLabels.position.name,
          defaultName: 'above',
        );
        _numberIf(writer, 'offsetX', dataPointLabels.offsetX, 0);
        _numberIf(writer, 'offsetY', dataPointLabels.offsetY, 0);
        _optionalColor(writer, 'labelColor', dataPointLabels.labelColor);
        _numberIf(writer, 'fontSize', dataPointLabels.fontSize, 10);
        _fontWeightIf(
          writer,
          'fontWeight',
          dataPointLabels.fontWeight,
          FontWeight.w600,
        );
        _valueIf(
          writer,
          'showUnit',
          dataPointLabels.showUnit,
          defaultValue: false,
        );
        _optionalColor(writer, 'background', dataPointLabels.background);
        _numberIf(
          writer,
          'backgroundOpacity',
          dataPointLabels.backgroundOpacity,
          0.85,
        );
        if (dataPointLabels.formatter != null) {
          writer.writeLine(
            '// formatter: (point) => ..., // Supply application formatting.',
          );
          _warn(
            code: ChartSourceWarningCodes.runtimeValueOmitted,
            message:
                'A data-point label formatter callback was omitted. Provide it from your application.',
            path: r'$.series[*].style.dataPointLabels.formatter',
          );
        }
      });
      writer.writeLine('),');
    }
    if (inlineLabel != null) {
      writer.writeLine('inlineLabel: SeriesInlineLabelConfig(');
      writer.indented(() {
        writer.namedArgument(
          'text',
          DartSourceWriter.stringLiteral(inlineLabel.text),
        );
        _enumIf(
          writer,
          'position',
          'SeriesLabelPosition',
          inlineLabel.position.name,
          defaultName: 'right',
        );
        _numberIf(writer, 'offsetY', inlineLabel.offsetY, 0);
        _optionalColor(writer, 'color', inlineLabel.color);
        _numberIf(writer, 'fontSize', inlineLabel.fontSize, 11);
        _fontWeightIf(
          writer,
          'fontWeight',
          inlineLabel.fontWeight,
          FontWeight.w500,
        );
        final background = inlineLabel.background;
        if (background != null) {
          writer.writeLine('background: SeriesLabelBackground(');
          writer.indented(() {
            writer.namedArgument(
              'color',
              DartSourceWriter.colorLiteral(background.color),
            );
            _optionalNumber(writer, 'cornerRadius', background.cornerRadius);
            _edgeInsetsIf(
              writer,
              'padding',
              background.padding,
              const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            );
            _optionalColor(writer, 'borderColor', background.borderColor);
            _numberIf(writer, 'borderWidth', background.borderWidth, 1);
          });
          writer.writeLine('),');
        }
      });
      writer.writeLine('),');
    }
  }

  void _emitBarOptions(
    DartSourceWriter writer,
    BarChartSeries series,
    int seriesIndex,
  ) {
    _optionalNumber(writer, 'barWidthPercent', series.barWidthPercent);
    _optionalNumber(writer, 'barWidthPixels', series.barWidthPixels);
    _numberIf(writer, 'minWidth', series.minWidth, 4);
    _numberIf(writer, 'maxWidth', series.maxWidth, 100);
    _numberIf(writer, 'barGap', series.barGap, 2);
    _enumIf(
      writer,
      'orientation',
      'BarOrientation',
      series.orientation.name,
      defaultName: 'vertical',
    );
    _enumIf(
      writer,
      'layoutMode',
      'BarLayoutMode',
      series.layoutMode.name,
      defaultName: 'grouped',
    );
    _optionalString(writer, 'groupId', series.groupId);
    _numberIf(writer, 'overlayWidthFactor', series.overlayWidthFactor, 1);
    _numberIf(writer, 'overlayOffsetFactor', series.overlayOffsetFactor, 0);
    _numberIf(writer, 'baselineValue', series.baselineValue, 0);
    _numberIf(writer, 'minBarLength', series.minBarLength, 0);
    _optionalNullableNumberList(
      writer,
      'rangeStartValues',
      series.rangeStartValues,
    );
    if (series.waterfallTotalIndices.isNotEmpty) {
      final indices = series.waterfallTotalIndices.toList()..sort();
      writer.namedArgument('waterfallTotalIndices', '{${indices.join(', ')}}');
    }
    _emitBarWaterfallStyle(writer, series.waterfallStyle);
    _emitBarChartStyle(writer, series.barStyle);
    if (series.trackStyle != null) {
      _emitBarTrackStyle(writer, series.trackStyle!);
    }
    _optionalNullableNumberList(writer, 'targetValues', series.targetValues);
    _emitBarTargetMarkerStyle(writer, series.targetMarkerStyle);
    _optionalNullableNumberList(
      writer,
      'errorLowerValues',
      series.errorLowerValues,
    );
    _optionalNullableNumberList(
      writer,
      'errorUpperValues',
      series.errorUpperValues,
    );
    _emitBarErrorStyle(writer, series.errorBarStyle);
    _emitBarLabelStyle(writer, series.labelStyle, seriesIndex);
  }

  void _emitBarChartStyle(DartSourceWriter writer, BarChartStyle style) {
    if (!options.includeDefaultValues && style == const BarChartStyle()) return;
    writer.writeLine('barStyle: BarChartStyle(');
    writer.indented(() {
      _numberIf(writer, 'cornerRadius', style.cornerRadius, 0);
      _enumIf(
        writer,
        'cornerRadiusPolicy',
        'BarCornerRadiusPolicy',
        style.cornerRadiusPolicy.name,
        defaultName: 'valueEnd',
      );
      if (style.gradient != null) {
        writer.writeLine('gradient: BarGradient(');
        writer.indented(() {
          writer.namedArgument(
            'colors',
            '[${style.gradient!.colors.map(DartSourceWriter.colorLiteral).join(', ')}]',
          );
          _optionalNumberList(writer, 'stops', style.gradient!.stops);
        });
        writer.writeLine('),');
      }
      if (style.border != null) {
        _emitBarBorder(writer, 'border', style.border!);
      }
      _numberIf(writer, 'opacity', style.opacity, 1);
      _emitBarInteractionStyle(writer, style.interaction);
      _enumIf(
        writer,
        'animationMode',
        'BarAnimationMode',
        style.animationMode.name,
        defaultName: 'grow',
      );
    });
    writer.writeLine('),');
  }

  void _emitBarInteractionStyle(
    DartSourceWriter writer,
    BarInteractionStyle style,
  ) {
    if (!options.includeDefaultValues && style == const BarInteractionStyle()) {
      return;
    }
    writer.writeLine('interaction: BarInteractionStyle(');
    writer.indented(() {
      _optionalColor(writer, 'hoverColor', style.hoverColor);
      _numberIf(writer, 'hoverOpacity', style.hoverOpacity, 0.12);
      _numberIf(writer, 'hoverBorderWidth', style.hoverBorderWidth, 2);
      _colorIf(writer, 'pressedColor', style.pressedColor, Colors.black);
      _numberIf(writer, 'pressedOpacity', style.pressedOpacity, 0.16);
      _optionalColor(writer, 'selectionColor', style.selectionColor);
      _numberIf(writer, 'selectionOpacity', style.selectionOpacity, 0.14);
      _numberIf(
        writer,
        'selectionBorderWidth',
        style.selectionBorderWidth,
        2.5,
      );
      _optionalColor(writer, 'focusColor', style.focusColor);
      _numberIf(writer, 'focusBorderWidth', style.focusBorderWidth, 2.5);
      _numberIf(writer, 'focusGap', style.focusGap, 3);
      _numberIf(writer, 'dimmedOpacity', style.dimmedOpacity, 0.42);
    });
    writer.writeLine('),');
  }

  void _emitBarWaterfallStyle(
    DartSourceWriter writer,
    BarWaterfallStyle style,
  ) {
    if (!options.includeDefaultValues && style == const BarWaterfallStyle()) {
      return;
    }
    writer.writeLine('waterfallStyle: BarWaterfallStyle(');
    writer.indented(() {
      _optionalColor(writer, 'increaseColor', style.increaseColor);
      _optionalColor(writer, 'decreaseColor', style.decreaseColor);
      _optionalColor(writer, 'totalColor', style.totalColor);
      if (options.includeDefaultValues ||
          style.connector != const BarWaterfallConnectorStyle()) {
        writer.writeLine('connector: BarWaterfallConnectorStyle(');
        writer.indented(() {
          _valueIf(writer, 'show', style.connector.show, defaultValue: true);
          _colorIf(
            writer,
            'color',
            style.connector.color,
            const Color(0xFF9CA3AF),
          );
          _numberIf(writer, 'width', style.connector.width, 1);
        });
        writer.writeLine('),');
      }
    });
    writer.writeLine('),');
  }

  void _emitBarTrackStyle(DartSourceWriter writer, BarTrackStyle style) {
    writer.writeLine('trackStyle: BarTrackStyle(');
    writer.indented(() {
      writer.namedArgument('color', DartSourceWriter.colorLiteral(style.color));
      _optionalNumber(writer, 'value', style.value);
      _numberIf(writer, 'opacity', style.opacity, 1);
      _optionalNumber(writer, 'cornerRadius', style.cornerRadius);
      if (style.border != null) _emitBarBorder(writer, 'border', style.border!);
    });
    writer.writeLine('),');
  }

  void _emitBarBorder(
    DartSourceWriter writer,
    String name,
    BarBorderStyle style,
  ) {
    writer.writeLine('$name: BarBorderStyle(');
    writer.indented(() {
      writer.namedArgument('color', DartSourceWriter.colorLiteral(style.color));
      _numberIf(writer, 'width', style.width, 1);
    });
    writer.writeLine('),');
  }

  void _emitBarTargetMarkerStyle(
    DartSourceWriter writer,
    BarTargetMarkerStyle style,
  ) {
    if (!options.includeDefaultValues &&
        style == const BarTargetMarkerStyle()) {
      return;
    }
    writer.writeLine('targetMarkerStyle: BarTargetMarkerStyle(');
    writer.indented(() {
      _optionalColor(writer, 'color', style.color);
      _numberIf(writer, 'width', style.width, 2);
      _numberIf(writer, 'lengthFactor', style.lengthFactor, 1.3);
      _numberIf(writer, 'opacity', style.opacity, 1);
    });
    writer.writeLine('),');
  }

  void _emitBarErrorStyle(DartSourceWriter writer, BarErrorBarStyle style) {
    if (!options.includeDefaultValues && style == const BarErrorBarStyle()) {
      return;
    }
    writer.writeLine('errorBarStyle: BarErrorBarStyle(');
    writer.indented(() {
      _optionalColor(writer, 'color', style.color);
      _numberIf(writer, 'width', style.width, 1.5);
      _numberIf(writer, 'capLengthFactor', style.capLengthFactor, 0.6);
      _numberIf(writer, 'opacity', style.opacity, 1);
    });
    writer.writeLine('),');
  }

  void _emitBarLabelStyle(
    DartSourceWriter writer,
    BarLabelStyle style,
    int seriesIndex,
  ) {
    if (!options.includeDefaultValues && style == const BarLabelStyle()) return;
    writer.writeLine('labelStyle: BarLabelStyle(');
    writer.indented(() {
      _valueIf(writer, 'show', style.show, defaultValue: false);
      _enumIf(
        writer,
        'position',
        'BarLabelPosition',
        style.position.name,
        defaultName: 'auto',
      );
      _enumIf(
        writer,
        'valueMode',
        'BarLabelValueMode',
        style.valueMode.name,
        defaultName: 'value',
      );
      _optionalColor(writer, 'color', style.color);
      _numberIf(writer, 'fontSize', style.fontSize, 10);
      _fontWeightIf(writer, 'fontWeight', style.fontWeight, FontWeight.w600);
      _valueIf(writer, 'showUnit', style.showUnit, defaultValue: false);
      _numberIf(writer, 'padding', style.padding, 4);
      if (style.formatter != null) {
        writer.writeLine(
          '// formatter: (point) => ..., // Supply application formatting.',
        );
        _warn(
          code: ChartSourceWarningCodes.runtimeValueOmitted,
          message:
              'A Bar label formatter callback was omitted. Provide it from your application.',
          path: '\$.series[$seriesIndex].style.barLabels.formatter',
        );
      }
    });
    writer.writeLine('),');
  }

  void _emitPieOptions(
    DartSourceWriter writer,
    PieChartSeries series,
    int seriesIndex,
  ) {
    _emitRadialStyle(writer, 'pieStyle', 'PieChartStyle', series.pieStyle);
    _emitRadialSelectionStyle(writer, series.selectionStyle);
    _emitRadialLabels(writer, series.dataLabels, seriesIndex);
    _emitAdvancedRadial(writer, series, seriesIndex);
  }

  void _emitPolarColumnOptions(
    DartSourceWriter writer,
    PolarColumnChartSeries series,
  ) {
    _enumIf(
      writer,
      'preset',
      'PolarColumnPreset',
      series.preset.name,
      defaultName: 'standard',
    );
    final style = series.polarStyle;
    if (options.includeDefaultValues || style != const PolarColumnStyle()) {
      writer.writeLine('polarStyle: PolarColumnStyle(');
      writer.indented(() {
        _numberIf(writer, 'cornerRadius', style.cornerRadius, 4);
        _numberIf(writer, 'opacity', style.opacity, 1);
        _optionalColor(writer, 'borderColor', style.borderColor);
        _numberIf(writer, 'borderWidth', style.borderWidth, 1);
        _valueIf(
          writer,
          'showDataLabels',
          style.showDataLabels,
          defaultValue: true,
        );
      });
      writer.writeLine('),');
    }
    _emitRadialSelectionStyle(writer, series.selectionStyle);
  }

  void _emitRadialSelectionStyle(
    DartSourceWriter writer,
    RadialSelectionStyle style,
  ) {
    if (!options.includeDefaultValues &&
        style == const RadialSelectionStyle()) {
      return;
    }
    writer.writeLine('selectionStyle: RadialSelectionStyle(');
    writer.indented(() {
      _enumIf(
        writer,
        'effect',
        'RadialSelectionEffect',
        style.effect.name,
        defaultName: 'explode',
      );
      _numberIf(writer, 'liftScale', style.liftScale, 1.08);
      _numberIf(writer, 'liftOffset', style.liftOffset, 6);
      _numberIf(writer, 'backdropBlur', style.backdropBlur, 1.25);
    });
    writer.writeLine('),');
  }

  void _emitDonutOptions(
    DartSourceWriter writer,
    DonutChartSeries series,
    int seriesIndex,
  ) {
    _emitRadialStyle(
      writer,
      'donutStyle',
      'DonutChartStyle',
      series.donutStyle,
      innerRadiusFactor: series.donutStyle.innerRadiusFactor,
      sweepAngleDegrees: series.donutStyle.sweepAngleDegrees,
    );
    _emitRadialSelectionStyle(writer, series.selectionStyle);
    final center = series.centerContent;
    if (center != DonutCenterContent.hidden) {
      writer.writeLine('centerContent: DonutCenterContent(');
      writer.indented(() {
        _valueIf(writer, 'isVisible', center.isVisible, defaultValue: true);
        _optionalString(writer, 'label', center.label);
        _enumIf(
          writer,
          'valueMode',
          'DonutCenterValueMode',
          center.valueMode.name,
          defaultName: 'total',
        );
        _optionalString(writer, 'customValue', center.customValue);
        if (center.labelStyle != null) {
          _emitLabelStyle(writer, 'labelStyle', center.labelStyle!);
        }
        if (center.valueStyle != null) {
          _emitLabelStyle(writer, 'valueStyle', center.valueStyle!);
        }
        if (center.valueFormatter != null) {
          writer.writeLine(
            '// valueFormatter: (value) => ..., // Supply application formatting.',
          );
          _warn(
            code: ChartSourceWarningCodes.runtimeValueOmitted,
            message:
                'A Donut center formatter callback was omitted. Provide it from your application.',
            path: '\$.series[$seriesIndex].style.centerContent.valueFormatter',
          );
        }
      });
      writer.writeLine('),');
    }
    _emitRadialLabels(writer, series.dataLabels, seriesIndex);
    _emitAdvancedRadial(writer, series, seriesIndex);
  }

  void _emitConcentricDonutConfig(
    DartSourceWriter writer,
    ConcentricDonutConfig config,
  ) {
    writer.writeLine('concentricDonutConfig: ConcentricDonutConfig(');
    writer.indented(() {
      _numberIf(writer, 'innerRadiusFactor', config.innerRadiusFactor, 0.32);
      _numberIf(writer, 'outerRadiusFactor', config.outerRadiusFactor, 1);
      _numberIf(writer, 'ringGap', config.ringGap, 4);
      _enumIf(
        writer,
        'order',
        'ConcentricRingOrder',
        config.order.name,
        defaultName: 'outerToInner',
      );
      if (config.ringWeights.isNotEmpty) {
        final entries = config.ringWeights.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));
        writer.writeLine('ringWeights: {');
        writer.indented(() {
          for (final entry in entries) {
            writer.writeLine(
              '${DartSourceWriter.stringLiteral(entry.key)}: '
              '${DartSourceWriter.numberLiteral(entry.value)},',
            );
          }
        });
        writer.writeLine('},');
      }
      _enumIf(
        writer,
        'legendMode',
        'ConcentricDonutLegendMode',
        config.legendMode.name,
        defaultName: 'groupedByRing',
      );
      if (options.includeDefaultValues ||
          config.centerContent != const DonutCenterContent()) {
        _emitConcentricCenterContent(writer, config.centerContent);
      }
    });
    writer.writeLine('),');
  }

  void _emitPolarChartConfig(DartSourceWriter writer, PolarChartConfig config) {
    writer.writeLine('polarChartConfig: PolarChartConfig(');
    writer.indented(() {
      final pane = config.pane;
      if (options.includeDefaultValues || pane != const PolarPaneConfig()) {
        writer.writeLine('pane: PolarPaneConfig(');
        writer.indented(() {
          _numberIf(writer, 'startAngleDegrees', pane.startAngleDegrees, -90);
          _numberIf(writer, 'sweepAngleDegrees', pane.sweepAngleDegrees, 360);
          _valueIf(writer, 'clockwise', pane.clockwise, defaultValue: true);
          _numberIf(writer, 'innerRadiusFactor', pane.innerRadiusFactor, 0);
          _numberIf(writer, 'outerRadiusFactor', pane.outerRadiusFactor, 0.88);
          _valueIf(writer, 'clipMarks', pane.clipMarks, defaultValue: true);
        });
        writer.writeLine('),');
      }
      final angular = config.angularAxis;
      if (options.includeDefaultValues ||
          angular != const PolarCategoryAxisConfig()) {
        writer.writeLine('angularAxis: PolarCategoryAxisConfig(');
        writer.indented(() {
          _numberIf(writer, 'innerPadding', angular.innerPadding, 0.12);
          _numberIf(writer, 'outerPadding', angular.outerPadding, 0.04);
          _valueIf(
            writer,
            'showLabels',
            angular.showLabels,
            defaultValue: true,
          );
          _valueIf(
            writer,
            'showGridLines',
            angular.showGridLines,
            defaultValue: true,
          );
        });
        writer.writeLine('),');
      }
      final radial = config.radialAxis;
      if (options.includeDefaultValues ||
          radial != const PolarNumericAxisConfig()) {
        writer.writeLine('radialAxis: PolarNumericAxisConfig(');
        writer.indented(() {
          _optionalNumber(writer, 'minimum', radial.minimum);
          _optionalNumber(writer, 'maximum', radial.maximum);
          if (radial.scaleMode case final scaleMode?) {
            writer.namedArgument(
              'scaleMode',
              'PolarRadialScaleMode.${scaleMode.name}',
            );
          }
          if (options.includeDefaultValues || radial.tickCount != 5) {
            writer.namedArgument('tickCount', radial.tickCount.toString());
          }
          _valueIf(writer, 'showLabels', radial.showLabels, defaultValue: true);
          _valueIf(
            writer,
            'showGridLines',
            radial.showGridLines,
            defaultValue: true,
          );
        });
        writer.writeLine('),');
      }
    });
    writer.writeLine('),');
  }

  void _emitConcentricCenterContent(
    DartSourceWriter writer,
    DonutCenterContent center,
  ) {
    writer.writeLine('centerContent: DonutCenterContent(');
    writer.indented(() {
      _valueIf(writer, 'isVisible', center.isVisible, defaultValue: true);
      _optionalString(writer, 'label', center.label);
      _enumIf(
        writer,
        'valueMode',
        'DonutCenterValueMode',
        center.valueMode.name,
        defaultName: 'total',
      );
      _optionalString(writer, 'customValue', center.customValue);
      if (center.labelStyle != null) {
        _emitLabelStyle(writer, 'labelStyle', center.labelStyle!);
      }
      if (center.valueStyle != null) {
        _emitLabelStyle(writer, 'valueStyle', center.valueStyle!);
      }
      if (center.valueFormatter != null) {
        writer.writeLine(
          '// valueFormatter: (value) => ..., // Supply application formatting.',
        );
        _warn(
          code: ChartSourceWarningCodes.runtimeValueOmitted,
          message:
              'A Concentric Donut center formatter callback was omitted. Provide it from your application.',
          path: r'$.configuration.concentricDonut.centerContent.valueFormatter',
        );
      }
    });
    writer.writeLine('),');
  }

  void _emitRadialStyle(
    DartSourceWriter writer,
    String argument,
    String constructor,
    PieChartStyle style, {
    double? innerRadiusFactor,
    double? sweepAngleDegrees,
  }) {
    final isDefault = constructor == 'PieChartStyle'
        ? style == const PieChartStyle()
        : style == const DonutChartStyle();
    if (!options.includeDefaultValues && isDefault) return;
    writer.writeLine('$argument: $constructor(');
    writer.indented(() {
      _optionalNumber(writer, 'innerRadiusFactor', innerRadiusFactor);
      _optionalNumber(writer, 'sweepAngleDegrees', sweepAngleDegrees);
      _numberIf(writer, 'startAngleDegrees', style.startAngleDegrees, -90);
      _valueIf(writer, 'clockwise', style.clockwise, defaultValue: true);
      _numberIf(writer, 'radiusFactor', style.radiusFactor, 0.9);
      _numberIf(writer, 'sliceGap', style.sliceGap, 2);
      _numberIf(writer, 'borderWidth', style.borderWidth, 1);
      _optionalColor(writer, 'borderColor', style.borderColor);
      if (style.borderColorMode != null) {
        writer.namedArgument(
          'borderColorMode',
          'PieBorderColorMode.${style.borderColorMode!.name}',
        );
      }
      _optionalNumber(
        writer,
        'borderHueShiftDegrees',
        style.borderHueShiftDegrees,
      );
      _optionalNumber(
        writer,
        'borderSaturationShift',
        style.borderSaturationShift,
      );
      _optionalNumber(
        writer,
        'borderLightnessShift',
        style.borderLightnessShift,
      );
      _numberIf(
        writer,
        'selectionExplodeOffset',
        style.selectionExplodeOffset,
        8,
      );
      _optionalNumber(writer, 'opacity', style.opacity);
      _optionalNumber(writer, 'cornerRadius', style.cornerRadius);
      if (style.cornerTreatment != null) {
        writer.namedArgument(
          'cornerTreatment',
          'PieCornerTreatment.${style.cornerTreatment!.name}',
        );
      }
      if (style.animationMode != null) {
        writer.namedArgument(
          'animationMode',
          'PieAnimationMode.${style.animationMode!.name}',
        );
      }
      _enumIf(
        writer,
        'dataTransitionMode',
        'RadialDataTransitionMode',
        style.dataTransitionMode.name,
        defaultName: 'automatic',
      );
      if (style.gradient != null) {
        _emitPieGradient(writer, style.gradient!);
      }
      if (style.shadow != null) {
        _emitPieElevation(writer, 'shadow', style.shadow!);
      }
      if (style.selectedElevation != null) {
        _emitPieElevation(
          writer,
          'selectedElevation',
          style.selectedElevation!,
        );
      }
    });
    writer.writeLine('),');
  }

  void _emitRadialLabels(
    DartSourceWriter writer,
    PieDataLabelConfig labels,
    int seriesIndex,
  ) {
    if (!options.includeDefaultValues && labels == const PieDataLabelConfig()) {
      return;
    }
    writer.writeLine('dataLabels: PieDataLabelConfig(');
    writer.indented(() {
      _valueIf(writer, 'isVisible', labels.isVisible, defaultValue: true);
      _enumIf(
        writer,
        'position',
        'PieDataLabelPosition',
        labels.position.name,
        defaultName: 'outside',
      );
      _enumIf(
        writer,
        'content',
        'PieDataLabelContent',
        labels.content.name,
        defaultName: 'categoryAndPercentage',
      );
      if (labels.secondaryContent != null) {
        writer.writeLine(
          'secondaryContent: PieDataLabelContent.'
          '${labels.secondaryContent!.name},',
        );
        writer.writeLine(
          'secondaryPosition: PieDataLabelPosition.'
          '${labels.secondaryPosition.name},',
        );
      }
      _numberIf(writer, 'minimumShare', labels.minimumShare, 0.03);
      _numberIf(writer, 'minimumSweepDegrees', labels.minimumSweepDegrees, 8);
      _numberIf(writer, 'padding', labels.padding, 6);
      _numberIf(writer, 'insideOffset', labels.insideOffset, 0);
      _numberIf(writer, 'outsideOffset', labels.outsideOffset, 0);
      _numberIf(writer, 'connectorLength', labels.connectorLength, 14);
      _numberIf(writer, 'connectorWidth', labels.connectorWidth, 1);
      _optionalColor(writer, 'connectorColor', labels.connectorColor);
      _enumIf(
        writer,
        'collisionStrategy',
        'PieDataLabelCollisionStrategy',
        labels.collisionStrategy.name,
        defaultName: 'shiftAndHide',
      );
      if (labels.calloutStyle != null) {
        _emitLabelStyle(writer, 'calloutStyle', labels.calloutStyle!);
      }
      if (labels.secondaryCalloutStyle != null) {
        _emitLabelStyle(
          writer,
          'secondaryCalloutStyle',
          labels.secondaryCalloutStyle!,
        );
      }
      if (labels.valueFormatter != null) {
        writer.writeLine(
          '// valueFormatter: (value) => ..., // Supply application formatting.',
        );
      }
      if (labels.percentageFormatter != null) {
        writer.writeLine(
          '// percentageFormatter: (share) => ..., // Supply application formatting.',
        );
      }
    });
    writer.writeLine('),');
    if (labels.valueFormatter != null || labels.percentageFormatter != null) {
      _warn(
        code: ChartSourceWarningCodes.runtimeValueOmitted,
        message:
            'Radial label formatter callbacks were omitted. Provide them from your application.',
        path: '\$.series[$seriesIndex].style.dataLabels',
      );
    }
  }

  void _emitPieGradient(DartSourceWriter writer, PieGradientStyle style) {
    writer.writeLine('gradient: PieGradientStyle(');
    writer.indented(() {
      _valueIf(writer, 'enabled', style.enabled, defaultValue: true);
      _enumIf(
        writer,
        'type',
        'PieGradientType',
        style.type.name,
        defaultName: 'linear',
      );
      _optionalColor(writer, 'startColor', style.startColor);
      _optionalColor(writer, 'endColor', style.endColor);
      _numberIf(writer, 'startLightnessShift', style.startLightnessShift, 0.16);
      _numberIf(writer, 'endLightnessShift', style.endLightnessShift, -0.12);
      _numberIf(writer, 'angleDegrees', style.angleDegrees, -45);
    });
    writer.writeLine('),');
  }

  void _emitPieElevation(
    DartSourceWriter writer,
    String name,
    PieElevationStyle style,
  ) {
    writer.writeLine('$name: PieElevationStyle(');
    writer.indented(() {
      _optionalColor(writer, 'color', style.color);
      _numberIf(writer, 'blurRadius', style.blurRadius, 0);
      _numberIf(writer, 'spreadRadius', style.spreadRadius, 0);
      _offsetIf(writer, 'offset', style.offset, Offset.zero);
      _numberIf(writer, 'opacity', style.opacity, 1);
    });
    writer.writeLine('),');
  }

  void _emitLabelStyle(DartSourceWriter writer, String name, LabelStyle style) {
    writer.writeLine('$name: LabelStyle(');
    writer.indented(() {
      _emitTextStyle(writer, 'textStyle', style.textStyle);
      writer.namedArgument(
        'backgroundColor',
        DartSourceWriter.colorLiteral(style.backgroundColor),
      );
      writer.namedArgument(
        'borderColor',
        DartSourceWriter.colorLiteral(style.borderColor),
      );
      writer.namedArgument(
        'borderWidth',
        DartSourceWriter.numberLiteral(style.borderWidth),
      );
      writer.namedArgument(
        'borderRadius',
        DartSourceWriter.numberLiteral(style.borderRadius),
      );
      writer.namedArgument('padding', _edgeInsetsLiteral(style.padding));
      _optionalColor(writer, 'shadowColor', style.shadowColor);
      _optionalNumber(writer, 'shadowBlurRadius', style.shadowBlurRadius);
    });
    writer.writeLine('),');
  }

  void _emitAdvancedRadial(
    DartSourceWriter writer,
    RadialCategorySeries series,
    int seriesIndex,
  ) {
    final radius = series.sliceRadiusConfig;
    if (radius != null) {
      writer.writeLine('sliceRadiusConfig: PieSliceRadiusConfig(');
      writer.indented(() {
        _numberIf(writer, 'minimumFactor', radius.minimumFactor, 0.35);
        _enumIf(
          writer,
          'scale',
          'PieSliceRadiusScale',
          radius.scale.name,
          defaultName: 'area',
        );
        _optionalString(writer, 'label', radius.label);
        _optionalString(writer, 'unit', radius.unit);
        if (radius.formatter != null) {
          writer.writeLine(
            '// formatter: (value) => ..., // Supply application formatting.',
          );
          _warn(
            code: ChartSourceWarningCodes.runtimeValueOmitted,
            message:
                'A radial radius formatter callback was omitted. Provide it from your application.',
            path: '\$.series[$seriesIndex].style.sliceRadiusConfig.formatter',
          );
        }
      });
      writer.writeLine('),');
    }
    final grouping = series.sliceGroupingConfig;
    if (grouping != null) {
      writer.writeLine('sliceGroupingConfig: RadialSliceGroupingConfig(');
      writer.indented(() {
        _numberIf(writer, 'minimumShare', grouping.minimumShare, 0.05);
        _numberIf(writer, 'minimumSourceCount', grouping.minimumSourceCount, 2);
        _optionalString(writer, 'label', grouping.label);
        _optionalColor(writer, 'color', grouping.color);
        if (grouping.radiusAggregation != null) {
          writer.namedArgument(
            'radiusAggregation',
            'RadialSliceRadiusAggregation.${grouping.radiusAggregation!.name}',
          );
        }
      });
      writer.writeLine('),');
    }
  }

  void _emitXAxis(DartSourceWriter writer, XAxisConfig axis) {
    writer.writeLine('xAxisConfig: XAxisConfig(');
    writer.indented(() => _emitAxisFields(writer, axis));
    writer.writeLine('),');
  }

  void _emitYAxis(DartSourceWriter writer, String argument, YAxisConfig axis) {
    writer.writeLine('$argument: YAxisConfig(');
    writer.indented(() {
      writer.namedArgument('position', 'YAxisPosition.${axis.position.name}');
      _optionalColor(writer, 'color', axis.color);
      _optionalString(writer, 'label', axis.label);
      _optionalString(writer, 'unit', axis.unit);
      _optionalNumber(writer, 'min', axis.min);
      _optionalNumber(writer, 'max', axis.max);
      _optionalNumber(writer, 'renderMin', axis.renderMin);
      _optionalNumber(writer, 'renderMax', axis.renderMax);
      _valueIf(writer, 'visible', axis.visible, defaultValue: true);
      _valueIf(writer, 'showAxisLine', axis.showAxisLine, defaultValue: true);
      _valueIf(writer, 'showTicks', axis.showTicks, defaultValue: true);
      _valueIf(
        writer,
        'showTickLabels',
        axis.showTickLabels,
        defaultValue: true,
      );
      _valueIf(
        writer,
        'showCrosshairLabel',
        axis.showCrosshairLabel,
        defaultValue: true,
      );
      _enumIf(
        writer,
        'crosshairLabelPosition',
        'CrosshairLabelPosition',
        axis.crosshairLabelPosition.name,
        defaultName: 'overAxis',
      );
      _enumIf(
        writer,
        'labelDisplay',
        'AxisLabelDisplay',
        axis.labelDisplay.name,
        defaultName: 'labelWithUnit',
      );
      _numberIf(writer, 'minWidth', axis.minWidth, 0);
      _numberIf(writer, 'maxWidth', axis.maxWidth, 80);
      _numberIf(writer, 'tickLabelPadding', axis.tickLabelPadding, 4);
      _numberIf(writer, 'axisLabelPadding', axis.axisLabelPadding, 5);
      _numberIf(writer, 'axisMargin', axis.axisMargin, 8);
      if (axis.tickCount != null) {
        writer.namedArgument('tickCount', axis.tickCount.toString());
      }
      _valueIf(
        writer,
        'showMinorTicks',
        axis.showMinorTicks,
        defaultValue: false,
      );
      _numberIf(writer, 'minorTickCount', axis.minorTickCount, 4);
      _numberIf(writer, 'minorTickLength', axis.minorTickLength, 3);
      if (axis.labelFormatter != null) {
        _warn(
          code: ChartSourceWarningCodes.runtimeValueOmitted,
          message:
              'A Y-axis label formatter callback was omitted. Provide it from your application.',
          path: r'$.axes[*].formatter',
        );
      }
    });
    writer.writeLine('),');
  }

  void _emitAxisFields(DartSourceWriter writer, XAxisConfig axis) {
    _optionalColor(writer, 'color', axis.color);
    _optionalString(writer, 'label', axis.label);
    _optionalString(writer, 'unit', axis.unit);
    _optionalNumber(writer, 'min', axis.min);
    _optionalNumber(writer, 'max', axis.max);
    _optionalNumber(writer, 'renderMin', axis.renderMin);
    _optionalNumber(writer, 'renderMax', axis.renderMax);
    _valueIf(writer, 'visible', axis.visible, defaultValue: true);
    _valueIf(writer, 'showAxisLine', axis.showAxisLine, defaultValue: true);
    _valueIf(writer, 'showTicks', axis.showTicks, defaultValue: true);
    _valueIf(writer, 'showTickLabels', axis.showTickLabels, defaultValue: true);
    _valueIf(
      writer,
      'showCrosshairLabel',
      axis.showCrosshairLabel,
      defaultValue: true,
    );
    _enumIf(
      writer,
      'crosshairLabelPosition',
      'CrosshairLabelPosition',
      axis.crosshairLabelPosition.name,
      defaultName: 'overAxis',
    );
    _enumIf(
      writer,
      'labelDisplay',
      'AxisLabelDisplay',
      axis.labelDisplay.name,
      defaultName: 'labelWithUnit',
    );
    _numberIf(writer, 'minHeight', axis.minHeight, 0);
    _numberIf(writer, 'maxHeight', axis.maxHeight, 60);
    _numberIf(writer, 'tickLabelPadding', axis.tickLabelPadding, 4);
    _numberIf(writer, 'axisLabelPadding', axis.axisLabelPadding, 5);
    _numberIf(writer, 'axisMargin', axis.axisMargin, 8);
    if (axis.tickCount != null) {
      writer.namedArgument('tickCount', axis.tickCount.toString());
    }
    _valueIf(
      writer,
      'showMinorTicks',
      axis.showMinorTicks,
      defaultValue: false,
    );
    _numberIf(writer, 'minorTickCount', axis.minorTickCount, 4);
    _numberIf(writer, 'minorTickLength', axis.minorTickLength, 3);
    if (axis.labelFormatter != null) {
      _warn(
        code: ChartSourceWarningCodes.runtimeValueOmitted,
        message:
            'The X-axis label formatter callback was omitted. Provide it from your application.',
        path: r'$.xAxis.formatter',
      );
    }
  }

  void _emitViewStateRestoration(
    DartSourceWriter writer,
    ChartViewState state,
    String controllerName,
  ) {
    final variable = options.variableName;
    final functionName =
        'restore${variable[0].toUpperCase()}${variable.substring(1)}ViewState';
    writer.writeLine('// Call after $variable is mounted.');
    writer.writeLine('void $functionName() {');
    writer.indented(() {
      writer.writeLine('$controllerName.restoreViewState(');
      writer.indented(() {
        writer.writeLine('ChartViewState(');
        writer.indented(() {
          final bounds = state.visibleBounds;
          if (bounds != null) {
            writer.writeLine('visibleBounds: ChartBoundsDocument(');
            writer.indented(() {
              writer.namedArgument(
                'xMin',
                DartSourceWriter.numberLiteral(bounds.xMin),
              );
              writer.namedArgument(
                'xMax',
                DartSourceWriter.numberLiteral(bounds.xMax),
              );
              writer.namedArgument(
                'yMin',
                DartSourceWriter.numberLiteral(bounds.yMin),
              );
              writer.namedArgument(
                'yMax',
                DartSourceWriter.numberLiteral(bounds.yMax),
              );
            });
            writer.writeLine('),');
          }
          if (state.hiddenSeriesIds.isNotEmpty) {
            final ids = state.hiddenSeriesIds.toList()..sort();
            writer.namedArgument(
              'hiddenSeriesIds',
              '{${ids.map(DartSourceWriter.stringLiteral).join(', ')}}',
            );
          }
          _optionalString(writer, 'selectedSeriesId', state.selectedSeriesId);
          if (state.selectedPointRefs.isNotEmpty) {
            writer.writeLine('selectedPointRefs: [');
            writer.indented(() {
              for (final point in state.selectedPointRefs) {
                writer.writeLine('ChartPointRef(');
                writer.indented(() {
                  writer.namedArgument(
                    'seriesId',
                    DartSourceWriter.stringLiteral(point.seriesId),
                  );
                  writer.namedArgument(
                    'pointIndex',
                    point.pointIndex.toString(),
                  );
                });
                writer.writeLine('),');
              }
            });
            writer.writeLine('],');
          }
          if (state.visibleAxisIds.isNotEmpty) {
            writer.namedArgument(
              'visibleAxisIds',
              '[${state.visibleAxisIds.map(DartSourceWriter.stringLiteral).join(', ')}]',
            );
          }
          if (state.overflowAxisIds.isNotEmpty) {
            writer.namedArgument(
              'overflowAxisIds',
              '[${state.overflowAxisIds.map(DartSourceWriter.stringLiteral).join(', ')}]',
            );
          }
          _optionalString(
            writer,
            'selectedAnnotationId',
            state.selectedAnnotationId,
          );
          final legendPosition = state.legendPosition;
          if (legendPosition != null) {
            writer.writeLine('legendPosition: ChartPositionDocument(');
            writer.indented(() {
              writer.namedArgument(
                'x',
                DartSourceWriter.numberLiteral(legendPosition.x),
              );
              writer.namedArgument(
                'y',
                DartSourceWriter.numberLiteral(legendPosition.y),
              );
            });
            writer.writeLine('),');
          }
        });
        writer.writeLine('),');
      });
      writer.writeLine(');');
    });
    writer.writeLine('}');
  }

  void _emitThemeReference(DartSourceWriter writer) {
    final reference = snapshot.document.theme.reference;
    final expression = switch (reference) {
      'braven.light' => 'ChartTheme.light',
      'braven.dark' => 'ChartTheme.dark',
      'braven.corporateBlue' => 'ChartTheme.corporateBlue',
      'braven.vibrant' => 'ChartTheme.vibrant',
      'braven.minimal' => 'ChartTheme.minimal',
      'braven.highContrast' => 'ChartTheme.highContrast',
      'braven.colorblindFriendly' => 'ChartTheme.colorblindFriendly',
      _ => null,
    };
    if (expression != null) {
      writer.namedArgument('theme', expression);
    } else if (reference == null) {
      _emitResolvedTheme(writer, configuration.theme);
    } else {
      _warn(
        code: ChartSourceWarningCodes.unsupportedPortableValue,
        message:
            'Theme reference "$reference" is host-owned and was omitted. Provide the matching ChartTheme from your application.',
        path: r'$.theme.reference',
      );
    }
  }

  void _emitResolvedTheme(DartSourceWriter writer, ChartTheme theme) {
    writer.writeLine('theme: ChartTheme(');
    writer.indented(() {
      writer.namedArgument(
        'backgroundColor',
        DartSourceWriter.colorLiteral(theme.backgroundColor),
      );
      _emitThemeGridStyle(writer, theme.gridStyle);
      _emitThemeAxisStyle(writer, theme.axisStyle);
      _emitThemeSeriesStyle(writer, theme.seriesTheme);
      _emitThemeInteractionStyle(writer, theme.interactionTheme);
      _emitTypographyTheme(writer, theme.typographyTheme);
      _emitAnimationTheme(writer, theme.animationTheme);
      _emitAnnotationTheme(writer, theme.annotationTheme);
      _emitScrollbarTheme(writer, theme.scrollbarConfig);
      _emitLegendStyle(writer, theme.legendStyle, force: true);
      _emitPieChartTheme(writer, theme.pieChartTheme);
      writer.namedArgument(
        'focusBorderColor',
        DartSourceWriter.colorLiteral(theme.focusBorderColor),
      );
      writer.namedArgument(
        'focusBorderWidth',
        DartSourceWriter.numberLiteral(theme.focusBorderWidth),
      );
      writer.namedArgument(
        'focusBorderRadius',
        DartSourceWriter.numberLiteral(theme.focusBorderRadius),
      );
    });
    writer.writeLine('),');
  }

  void _emitThemeGridStyle(DartSourceWriter writer, GridStyle style) {
    writer.writeLine('gridStyle: GridStyle(');
    writer.indented(() {
      writer.namedArgument(
        'majorColor',
        DartSourceWriter.colorLiteral(style.majorColor),
      );
      writer.namedArgument(
        'majorWidth',
        DartSourceWriter.numberLiteral(style.majorWidth),
      );
      writer.namedArgument(
        'majorDashPattern',
        '[${style.majorDashPattern.map(DartSourceWriter.numberLiteral).join(', ')}]',
      );
      _optionalColor(writer, 'minorColor', style.minorColor);
      _optionalNumber(writer, 'minorWidth', style.minorWidth);
      writer.namedArgument(
        'minorDashPattern',
        '[${style.minorDashPattern.map(DartSourceWriter.numberLiteral).join(', ')}]',
      );
      writer.namedArgument('showMinor', style.showMinor.toString());
    });
    writer.writeLine('),');
  }

  void _emitThemeAxisStyle(DartSourceWriter writer, AxisStyle style) {
    writer.writeLine('axisStyle: AxisStyle(');
    writer.indented(() {
      writer.namedArgument(
        'lineColor',
        DartSourceWriter.colorLiteral(style.lineColor),
      );
      writer.namedArgument(
        'lineWidth',
        DartSourceWriter.numberLiteral(style.lineWidth),
      );
      _emitTextStyle(writer, 'labelStyle', style.labelStyle);
      _emitTextStyle(writer, 'titleStyle', style.titleStyle);
      writer.namedArgument('showTicks', style.showTicks.toString());
      writer.namedArgument(
        'tickLength',
        DartSourceWriter.numberLiteral(style.tickLength),
      );
      writer.namedArgument(
        'tickColor',
        DartSourceWriter.colorLiteral(style.tickColor),
      );
      writer.namedArgument(
        'tickWidth',
        DartSourceWriter.numberLiteral(style.tickWidth),
      );
    });
    writer.writeLine('),');
  }

  void _emitThemeSeriesStyle(
    DartSourceWriter writer,
    series_theme.SeriesTheme theme,
  ) {
    writer.writeLine('seriesTheme: SeriesTheme(');
    writer.indented(() {
      writer.namedArgument(
        'colors',
        '[${theme.colors.map(DartSourceWriter.colorLiteral).join(', ')}]',
      );
      writer.namedArgument(
        'lineWidths',
        '[${theme.lineWidths.map(DartSourceWriter.numberLiteral).join(', ')}]',
      );
      writer.namedArgument(
        'markerSizes',
        '[${theme.markerSizes.map(DartSourceWriter.numberLiteral).join(', ')}]',
      );
      writer.namedArgument(
        'markerShapes',
        '[${theme.markerShapes.map((shape) => 'SeriesMarkerShape.${shape.name}').join(', ')}]',
      );
    });
    writer.writeLine('),');
  }

  void _emitThemeInteractionStyle(
    DartSourceWriter writer,
    InteractionTheme theme,
  ) {
    writer.writeLine('interactionTheme: InteractionTheme(');
    writer.indented(() {
      writer.namedArgument(
        'crosshairColor',
        DartSourceWriter.colorLiteral(theme.crosshairColor),
      );
      writer.namedArgument(
        'crosshairWidth',
        DartSourceWriter.numberLiteral(theme.crosshairWidth),
      );
      writer.namedArgument(
        'crosshairDashPattern',
        '[${theme.crosshairDashPattern.map(DartSourceWriter.numberLiteral).join(', ')}]',
      );
      _emitLabelStyle(writer, 'crosshairLabelStyle', theme.crosshairLabelStyle);
      _emitLabelStyle(writer, 'tooltipStyle', theme.tooltipStyle);
      writer.namedArgument(
        'selectionColor',
        DartSourceWriter.colorLiteral(theme.selectionColor),
      );
    });
    writer.writeLine('),');
  }

  void _emitTypographyTheme(DartSourceWriter writer, TypographyTheme theme) {
    writer.writeLine('typographyTheme: TypographyTheme(');
    writer.indented(() {
      writer.namedArgument(
        'fontFamily',
        DartSourceWriter.stringLiteral(theme.fontFamily),
      );
      writer.namedArgument(
        'baseFontSize',
        DartSourceWriter.numberLiteral(theme.baseFontSize),
      );
      writer.namedArgument(
        'scaleFactorMobile',
        DartSourceWriter.numberLiteral(theme.scaleFactorMobile),
      );
      writer.namedArgument(
        'scaleFactorTablet',
        DartSourceWriter.numberLiteral(theme.scaleFactorTablet),
      );
      writer.namedArgument(
        'scaleFactorDesktop',
        DartSourceWriter.numberLiteral(theme.scaleFactorDesktop),
      );
      writer.namedArgument(
        'titleMultiplier',
        DartSourceWriter.numberLiteral(theme.titleMultiplier),
      );
      writer.namedArgument(
        'labelMultiplier',
        DartSourceWriter.numberLiteral(theme.labelMultiplier),
      );
    });
    writer.writeLine('),');
  }

  void _emitAnimationTheme(DartSourceWriter writer, AnimationTheme theme) {
    writer.writeLine('animationTheme: AnimationTheme(');
    writer.indented(() {
      writer.namedArgument(
        'dataUpdateDuration',
        'Duration(microseconds: ${theme.dataUpdateDuration.inMicroseconds})',
      );
      writer.namedArgument(
        'dataUpdateCurve',
        _curveLiteral(theme.dataUpdateCurve),
      );
      writer.namedArgument(
        'themeChangeDuration',
        'Duration(microseconds: ${theme.themeChangeDuration.inMicroseconds})',
      );
      writer.namedArgument(
        'themeChangeCurve',
        _curveLiteral(theme.themeChangeCurve),
      );
      writer.namedArgument(
        'interactionDuration',
        'Duration(microseconds: ${theme.interactionDuration.inMicroseconds})',
      );
      writer.namedArgument(
        'interactionCurve',
        _curveLiteral(theme.interactionCurve),
      );
    });
    writer.writeLine('),');
  }

  String _curveLiteral(Curve curve) {
    final name = switch (curve) {
      Curves.linear => 'linear',
      Curves.easeIn => 'easeIn',
      Curves.easeOut => 'easeOut',
      Curves.easeInOut => 'easeInOut',
      Curves.easeInCubic => 'easeInCubic',
      Curves.easeOutCubic => 'easeOutCubic',
      Curves.easeInOutCubic => 'easeInOutCubic',
      Curves.fastOutSlowIn => 'fastOutSlowIn',
      Curves.bounceIn => 'bounceIn',
      Curves.bounceOut => 'bounceOut',
      Curves.bounceInOut => 'bounceInOut',
      Curves.elasticIn => 'elasticIn',
      Curves.elasticOut => 'elasticOut',
      Curves.elasticInOut => 'elasticInOut',
      Curves.easeOutBack => 'easeOutBack',
      _ => null,
    };
    if (name == null) {
      _warn(
        code: ChartSourceWarningCodes.unsupportedPortableValue,
        message:
            'A custom animation curve was replaced with Curves.linear. Reapply the application curve in the generated theme.',
        path: r'$.theme.resolved.animationTheme',
      );
      return 'Curves.linear';
    }
    return 'Curves.$name';
  }

  void _emitAnnotationTheme(DartSourceWriter writer, AnnotationTheme theme) {
    writer.writeLine('annotationTheme: AnnotationTheme(');
    writer.indented(() {
      final point = theme.pointDefaults;
      writer.writeLine('pointDefaults: PointAnnotationDefaults(');
      writer.indented(() {
        writer.namedArgument(
          'markerShape',
          'SeriesMarkerShape.${point.markerShape.name}',
        );
        writer.namedArgument(
          'markerSize',
          DartSourceWriter.numberLiteral(point.markerSize),
        );
        _requiredColor(writer, 'normalColor', point.normalColor);
        _requiredColor(writer, 'selectedColor', point.selectedColor);
        _requiredColor(writer, 'hoveredColor', point.hoveredColor);
        _requiredColor(writer, 'draggingColor', point.draggingColor);
        writer.namedArgument(
          'ghostOpacity',
          DartSourceWriter.numberLiteral(point.ghostOpacity),
        );
        writer.namedArgument(
          'previewOpacity',
          DartSourceWriter.numberLiteral(point.previewOpacity),
        );
        writer.namedArgument(
          'previewScale',
          DartSourceWriter.numberLiteral(point.previewScale),
        );
        _emitLabelStyle(writer, 'labelStyle', point.labelStyle);
      });
      writer.writeLine('),');

      final range = theme.rangeDefaults;
      writer.writeLine('rangeDefaults: RangeAnnotationDefaults(');
      writer.indented(() {
        _requiredColor(writer, 'normalFillColor', range.normalFillColor);
        _requiredColor(writer, 'selectedFillColor', range.selectedFillColor);
        _requiredColor(writer, 'hoveredFillColor', range.hoveredFillColor);
        _requiredColor(writer, 'draggingFillColor', range.draggingFillColor);
        _requiredColor(writer, 'normalBorderColor', range.normalBorderColor);
        _requiredColor(
          writer,
          'selectedBorderColor',
          range.selectedBorderColor,
        );
        _requiredColor(writer, 'hoveredBorderColor', range.hoveredBorderColor);
        _requiredColor(
          writer,
          'draggingBorderColor',
          range.draggingBorderColor,
        );
        writer.namedArgument(
          'borderWidth',
          DartSourceWriter.numberLiteral(range.borderWidth),
        );
        _emitLabelStyle(writer, 'labelStyle', range.labelStyle);
      });
      writer.writeLine('),');

      final text = theme.textDefaults;
      writer.writeLine('textDefaults: TextAnnotationDefaults(');
      writer.indented(() {
        _emitTextStyle(writer, 'textStyle', text.textStyle);
        _requiredColor(writer, 'backgroundColor', text.backgroundColor);
        _requiredColor(writer, 'borderColor', text.borderColor);
        writer.namedArgument(
          'borderWidth',
          DartSourceWriter.numberLiteral(text.borderWidth),
        );
        writer.namedArgument(
          'borderRadius',
          DartSourceWriter.numberLiteral(text.borderRadius),
        );
        writer.namedArgument('padding', _edgeInsetsLiteral(text.padding));
      });
      writer.writeLine('),');

      final threshold = theme.thresholdDefaults;
      writer.writeLine('thresholdDefaults: ThresholdAnnotationDefaults(');
      writer.indented(() {
        _requiredColor(writer, 'lineColor', threshold.lineColor);
        writer.namedArgument(
          'lineWidth',
          DartSourceWriter.numberLiteral(threshold.lineWidth),
        );
        writer.namedArgument(
          'dashPattern',
          '[${threshold.dashPattern.map(DartSourceWriter.numberLiteral).join(', ')}]',
        );
        _emitLabelStyle(writer, 'labelStyle', threshold.labelStyle);
      });
      writer.writeLine('),');

      final trend = theme.trendDefaults;
      writer.writeLine('trendDefaults: TrendAnnotationDefaults(');
      writer.indented(() {
        _requiredColor(writer, 'lineColor', trend.lineColor);
        writer.namedArgument(
          'lineWidth',
          DartSourceWriter.numberLiteral(trend.lineWidth),
        );
        writer.namedArgument(
          'dashPattern',
          '[${trend.dashPattern.map(DartSourceWriter.numberLiteral).join(', ')}]',
        );
        _requiredColor(
          writer,
          'confidenceBandColor',
          trend.confidenceBandColor,
        );
        writer.namedArgument(
          'confidenceBandOpacity',
          DartSourceWriter.numberLiteral(trend.confidenceBandOpacity),
        );
        _emitLabelStyle(writer, 'labelStyle', trend.labelStyle);
      });
      writer.writeLine('),');
    });
    writer.writeLine('),');
  }

  void _emitScrollbarTheme(DartSourceWriter writer, ScrollbarConfig config) {
    writer.writeLine('scrollbarConfig: ScrollbarConfig(');
    writer.indented(() {
      writer.namedArgument(
        'thickness',
        DartSourceWriter.numberLiteral(config.thickness),
      );
      writer.namedArgument(
        'minHandleSize',
        DartSourceWriter.numberLiteral(config.minHandleSize),
      );
      _requiredColor(writer, 'trackColor', config.trackColor);
      _requiredColor(writer, 'handleColor', config.handleColor);
      _requiredColor(writer, 'handleHoverColor', config.handleHoverColor);
      _requiredColor(writer, 'edgeZoneColor', config.edgeZoneColor);
      _requiredColor(writer, 'edgeHoverColor', config.edgeHoverColor);
      _requiredColor(writer, 'handleActiveColor', config.handleActiveColor);
      _requiredColor(writer, 'handleDisabledColor', config.handleDisabledColor);
      _requiredColor(writer, 'trackHoverColor', config.trackHoverColor);
      writer.namedArgument(
        'borderRadius',
        DartSourceWriter.numberLiteral(config.borderRadius),
      );
      writer.namedArgument(
        'edgeGripWidth',
        DartSourceWriter.numberLiteral(config.edgeGripWidth),
      );
      writer.namedArgument(
        'showGripIndicator',
        config.showGripIndicator.toString(),
      );
      _requiredColor(writer, 'gripIndicatorColor', config.gripIndicatorColor);
      writer.namedArgument('autoHide', config.autoHide.toString());
      writer.namedArgument(
        'autoHideDelay',
        'Duration(microseconds: ${config.autoHideDelay.inMicroseconds})',
      );
      writer.namedArgument(
        'fadeDuration',
        'Duration(microseconds: ${config.fadeDuration.inMicroseconds})',
      );
      writer.namedArgument(
        'enableResizeHandles',
        config.enableResizeHandles.toString(),
      );
      writer.namedArgument(
        'minZoomRatio',
        DartSourceWriter.numberLiteral(config.minZoomRatio),
      );
      writer.namedArgument(
        'maxZoomRatio',
        DartSourceWriter.numberLiteral(config.maxZoomRatio),
      );
      writer.namedArgument(
        'padding',
        DartSourceWriter.numberLiteral(config.padding),
      );
      writer.namedArgument(
        'forcedColorsMode',
        config.forcedColorsMode.toString(),
      );
      writer.namedArgument(
        'prefersReducedMotion',
        config.prefersReducedMotion.toString(),
      );
    });
    writer.writeLine('),');
  }

  void _emitPieChartTheme(DartSourceWriter writer, PieChartTheme theme) {
    writer.writeLine('pieChartTheme: PieChartTheme(');
    writer.indented(() {
      writer.namedArgument(
        'opacity',
        DartSourceWriter.numberLiteral(theme.opacity),
      );
      writer.namedArgument(
        'cornerRadius',
        DartSourceWriter.numberLiteral(theme.cornerRadius),
      );
      writer.namedArgument(
        'cornerTreatment',
        'PieCornerTreatment.${theme.cornerTreatment.name}',
      );
      _emitPieElevation(writer, 'shadow', theme.shadow);
      _emitPieElevation(writer, 'selectedElevation', theme.selectedElevation);
      writer.namedArgument(
        'borderColorMode',
        'PieBorderColorMode.${theme.borderColorMode.name}',
      );
      writer.namedArgument(
        'borderHueShiftDegrees',
        DartSourceWriter.numberLiteral(theme.borderHueShiftDegrees),
      );
      writer.namedArgument(
        'borderSaturationShift',
        DartSourceWriter.numberLiteral(theme.borderSaturationShift),
      );
      writer.namedArgument(
        'borderLightnessShift',
        DartSourceWriter.numberLiteral(theme.borderLightnessShift),
      );
      if (theme.gradient != null) {
        _emitPieGradient(writer, theme.gradient!);
      }
      if (theme.calloutStyle != null) {
        _emitLabelStyle(writer, 'calloutStyle', theme.calloutStyle!);
      }
      if (theme.centerLabelStyle != null) {
        _emitLabelStyle(writer, 'centerLabelStyle', theme.centerLabelStyle!);
      }
      if (theme.centerValueStyle != null) {
        _emitLabelStyle(writer, 'centerValueStyle', theme.centerValueStyle!);
      }
      writer.namedArgument(
        'animationMode',
        'PieAnimationMode.${theme.animationMode.name}',
      );
    });
    writer.writeLine('),');
  }

  void _requiredColor(DartSourceWriter writer, String name, Color value) {
    writer.namedArgument(name, DartSourceWriter.colorLiteral(value));
  }

  void _emitInteraction(
    DartSourceWriter writer,
    InteractionConfig interaction,
  ) {
    writer.writeLine('interactionConfig: InteractionConfig(');
    writer.indented(() {
      _valueIf(writer, 'enabled', interaction.enabled, defaultValue: true);
      _valueIf(
        writer,
        'enableZoom',
        interaction.enableZoom,
        defaultValue: true,
      );
      _valueIf(writer, 'enablePan', interaction.enablePan, defaultValue: true);
      _valueIf(
        writer,
        'enableSelection',
        interaction.enableSelection,
        defaultValue: true,
      );
      _valueIf(
        writer,
        'showFocusBorder',
        interaction.showFocusBorder,
        defaultValue: false,
      );
      _valueIf(
        writer,
        'enableFocusOnHover',
        interaction.enableFocusOnHover,
        defaultValue: true,
      );
      _valueIf(
        writer,
        'showXScrollbar',
        interaction.showXScrollbar,
        defaultValue: false,
      );
      _valueIf(
        writer,
        'showYScrollbar',
        interaction.showYScrollbar,
        defaultValue: false,
      );
      _numberIf(
        writer,
        'keyboardZoomPercent',
        interaction.keyboardZoomPercent,
        25,
      );
      _emitCrosshairConfig(writer, interaction.crosshair);
      _emitTooltipConfig(writer, interaction.tooltip);
      _emitGestureConfig(writer, interaction.gesture);
      _emitKeyboardConfig(writer, interaction.keyboard);
    });
    writer.writeLine('),');
  }

  void _emitCrosshairConfig(DartSourceWriter writer, CrosshairConfig config) {
    if (!options.includeDefaultValues && config == const CrosshairConfig()) {
      return;
    }
    writer.writeLine('crosshair: CrosshairConfig(');
    writer.indented(() {
      _valueIf(writer, 'enabled', config.enabled, defaultValue: true);
      _enumIf(
        writer,
        'mode',
        'CrosshairMode',
        config.mode.name,
        defaultName: 'both',
      );
      _valueIf(
        writer,
        'snapToDataPoint',
        config.snapToDataPoint,
        defaultValue: true,
      );
      _numberIf(writer, 'snapRadius', config.snapRadius, 20);
      _valueIf(
        writer,
        'showCoordinateLabels',
        config.showCoordinateLabels,
        defaultValue: true,
      );
      if (config.coordinateLabelStyle != null) {
        _emitTextStyle(
          writer,
          'coordinateLabelStyle',
          config.coordinateLabelStyle!,
        );
      }
      _emitCrosshairStyle(writer, config.style);
      _enumIf(
        writer,
        'displayMode',
        'CrosshairDisplayMode',
        config.displayMode.name,
        defaultName: 'auto',
      );
      _numberIf(
        writer,
        'trackingModeThreshold',
        config.trackingModeThreshold,
        250,
      );
      _valueIf(
        writer,
        'interpolateValues',
        config.interpolateValues,
        defaultValue: true,
      );
      _valueIf(
        writer,
        'showTrackingTooltip',
        config.showTrackingTooltip,
        defaultValue: true,
      );
      _valueIf(
        writer,
        'showIntersectionMarkers',
        config.showIntersectionMarkers,
        defaultValue: true,
      );
      _numberIf(
        writer,
        'intersectionMarkerRadius',
        config.intersectionMarkerRadius,
        4,
      );
    });
    writer.writeLine('),');
  }

  void _emitCrosshairStyle(DartSourceWriter writer, CrosshairStyle style) {
    if (!options.includeDefaultValues && style == const CrosshairStyle()) {
      return;
    }
    writer.writeLine('style: CrosshairStyle(');
    writer.indented(() {
      _colorIf(writer, 'lineColor', style.lineColor, const Color(0xFF666666));
      _numberIf(writer, 'lineWidth', style.lineWidth, 1);
      _optionalNumberList(writer, 'dashPattern', style.dashPattern);
      if (options.includeDefaultValues || style.strokeCap != StrokeCap.round) {
        writer.namedArgument('strokeCap', 'StrokeCap.${style.strokeCap.name}');
      }
      _colorIf(
        writer,
        'labelBackgroundColor',
        style.labelBackgroundColor,
        const Color(0xFF333333),
      );
      _colorIf(writer, 'labelTextColor', style.labelTextColor, Colors.white);
      _numberIf(writer, 'labelPadding', style.labelPadding, 4);
    });
    writer.writeLine('),');
  }

  void _emitTooltipConfig(DartSourceWriter writer, TooltipConfig config) {
    if (!options.includeDefaultValues && config == const TooltipConfig()) {
      return;
    }
    writer.writeLine('tooltip: TooltipConfig(');
    writer.indented(() {
      _valueIf(writer, 'enabled', config.enabled, defaultValue: true);
      _enumIf(
        writer,
        'triggerMode',
        'TooltipTriggerMode',
        config.triggerMode.name,
        defaultName: 'hover',
      );
      _enumIf(
        writer,
        'preferredPosition',
        'TooltipPosition',
        config.preferredPosition.name,
        defaultName: 'auto',
      );
      _durationIf(writer, 'showDelay', config.showDelay, Duration.zero);
      _durationIf(
        writer,
        'hideDelay',
        config.hideDelay,
        const Duration(milliseconds: 200),
      );
      _valueIf(
        writer,
        'followCursor',
        config.followCursor,
        defaultValue: false,
      );
      _numberIf(writer, 'offsetFromPoint', config.offsetFromPoint, 8);
      _emitTooltipStyle(writer, config.style);
      if (config.customBuilder != null) {
        writer.writeLine(
          '// customBuilder: (context, dataPoint) => ..., // Supply application UI.',
        );
      }
    });
    writer.writeLine('),');
  }

  void _emitTooltipStyle(DartSourceWriter writer, TooltipStyle style) {
    if (!options.includeDefaultValues && style == const TooltipStyle()) return;
    writer.writeLine('style: TooltipStyle(');
    writer.indented(() {
      _colorIf(
        writer,
        'backgroundColor',
        style.backgroundColor,
        const Color(0xE6FFFFFF),
      );
      _colorIf(
        writer,
        'borderColor',
        style.borderColor,
        const Color(0xFF999999),
      );
      _numberIf(writer, 'borderWidth', style.borderWidth, 1);
      _numberIf(writer, 'borderRadius', style.borderRadius, 4);
      _colorIf(writer, 'shadowColor', style.shadowColor, Colors.transparent);
      _numberIf(writer, 'shadowBlurRadius', style.shadowBlurRadius, 4);
      _numberIf(writer, 'padding', style.padding, 8);
      _colorIf(writer, 'textColor', style.textColor, const Color(0xFF333333));
      _numberIf(writer, 'fontSize', style.fontSize, 12);
    });
    writer.writeLine('),');
  }

  void _emitGestureConfig(DartSourceWriter writer, GestureConfig config) {
    if (!options.includeDefaultValues && config == const GestureConfig()) {
      return;
    }
    writer.writeLine('gesture: GestureConfig(');
    writer.indented(() {
      _durationIf(
        writer,
        'tapTimeout',
        config.tapTimeout,
        const Duration(milliseconds: 200),
      );
      _durationIf(
        writer,
        'longPressTimeout',
        config.longPressTimeout,
        const Duration(milliseconds: 500),
      );
      _numberIf(writer, 'panThreshold', config.panThreshold, 10);
      _numberIf(writer, 'pinchThreshold', config.pinchThreshold, 0.1);
    });
    writer.writeLine('),');
  }

  void _emitKeyboardConfig(DartSourceWriter writer, KeyboardConfig config) {
    if (!options.includeDefaultValues && config == const KeyboardConfig()) {
      return;
    }
    writer.writeLine('keyboard: KeyboardConfig(');
    writer.indented(() {
      _valueIf(writer, 'enabled', config.enabled, defaultValue: true);
      _numberIf(writer, 'panStep', config.panStep, 10);
      _numberIf(writer, 'zoomStep', config.zoomStep, 0.1);
      _valueIf(
        writer,
        'enableArrowKeys',
        config.enableArrowKeys,
        defaultValue: true,
      );
      _valueIf(
        writer,
        'enablePlusMinusKeys',
        config.enablePlusMinusKeys,
        defaultValue: true,
      );
      _valueIf(
        writer,
        'enableHomeEndKeys',
        config.enableHomeEndKeys,
        defaultValue: true,
      );
    });
    writer.writeLine('),');
  }

  void _emitGrid(DartSourceWriter writer, GridConfig grid) {
    if (!options.includeDefaultValues && grid == const GridConfig()) return;
    writer.writeLine('grid: GridConfig(');
    writer.indented(() {
      _valueIf(writer, 'horizontal', grid.horizontal, defaultValue: true);
      _valueIf(writer, 'vertical', grid.vertical, defaultValue: true);
      _optionalColor(writer, 'horizontalColor', grid.horizontalColor);
      _optionalColor(writer, 'verticalColor', grid.verticalColor);
      _numberIf(
        writer,
        'horizontalStrokeWidth',
        grid.horizontalStrokeWidth,
        0.5,
      );
      _numberIf(writer, 'verticalStrokeWidth', grid.verticalStrokeWidth, 0.5);
    });
    writer.writeLine('),');
  }

  void _emitLegendStyle(
    DartSourceWriter writer,
    LegendStyle style, {
    bool force = false,
  }) {
    if (!force && !options.includeDefaultValues && style == LegendStyle.light) {
      return;
    }
    writer.writeLine('legendStyle: LegendStyle(');
    writer.indented(() {
      _enumIf(
        writer,
        'position',
        'LegendPosition',
        style.position.name,
        defaultName: 'topRight',
      );
      _enumIf(
        writer,
        'orientation',
        'LegendOrientation',
        style.orientation.name,
        defaultName: 'horizontal',
      );
      _emitTextStyle(writer, 'textStyle', style.textStyle);
      _optionalColor(writer, 'backgroundColor', style.backgroundColor);
      _optionalColor(writer, 'borderColor', style.borderColor);
      _numberIf(writer, 'borderWidth', style.borderWidth, 0);
      if (style.borderRadius != null) {
        writer.namedArgument(
          'borderRadius',
          _borderRadiusLiteral(style.borderRadius!),
        );
      }
      if (style.padding != null) {
        writer.namedArgument('padding', _edgeInsetsLiteral(style.padding!));
      }
      _numberIf(writer, 'itemSpacing', style.itemSpacing, 6);
      _numberIf(writer, 'markerSize', style.markerSize, 16);
      _enumIf(
        writer,
        'markerShape',
        'LegendMarkerShape',
        style.markerShape.name,
        defaultName: 'line',
      );
      _numberIf(writer, 'markerLineWidth', style.markerLineWidth, 4);
      _numberIf(writer, 'markerLabelSpacing', style.markerLabelSpacing, 6);
      _valueIf(
        writer,
        'allowDragging',
        style.allowDragging,
        defaultValue: true,
      );
      _numberIf(writer, 'opacity', style.opacity, 1);
      _offsetIf(writer, 'offset', style.offset, Offset.zero);
    });
    writer.writeLine('),');
  }

  String _dynamicLiteral(Object? value) {
    return switch (value) {
      null => 'null',
      bool() => value.toString(),
      num() => DartSourceWriter.numberLiteral(value),
      String() => DartSourceWriter.stringLiteral(value),
      DateTime() =>
        'DateTime.parse(${DartSourceWriter.stringLiteral(value.toIso8601String())})',
      List() => '[${value.map(_dynamicLiteral).join(', ')}]',
      Set() => '{${value.map(_dynamicLiteral).join(', ')}}',
      Map() =>
        '{${value.entries.map((entry) => '${_dynamicLiteral(entry.key)}: ${_dynamicLiteral(entry.value)}').join(', ')}}',
      _ => throw ArgumentError.value(
        value,
        'value',
        'Generated chart metadata must contain Dart literal values',
      ),
    };
  }

  String _offsetLiteral(Offset value) =>
      'Offset(${DartSourceWriter.numberLiteral(value.dx)}, ${DartSourceWriter.numberLiteral(value.dy)})';

  void _emitTextStyle(DartSourceWriter writer, String name, TextStyle style) {
    writer.writeLine('$name: TextStyle(');
    writer.indented(() {
      _optionalColor(writer, 'color', style.color);
      _optionalColor(writer, 'backgroundColor', style.backgroundColor);
      _optionalNumber(writer, 'fontSize', style.fontSize);
      if (style.fontWeight != null) {
        writer.namedArgument(
          'fontWeight',
          _fontWeightLiteral(style.fontWeight!),
        );
      }
      if (style.fontStyle != null) {
        writer.namedArgument('fontStyle', 'FontStyle.${style.fontStyle!.name}');
      }
      _optionalNumber(writer, 'letterSpacing', style.letterSpacing);
      _optionalNumber(writer, 'wordSpacing', style.wordSpacing);
      _optionalNumber(writer, 'height', style.height);
      _optionalString(writer, 'fontFamily', style.fontFamily);
      if (style.decoration != null) {
        final decoration = _textDecorationLiteral(style.decoration!);
        if (decoration != null) {
          writer.namedArgument('decoration', decoration);
        } else {
          _warn(
            code: ChartSourceWarningCodes.unsupportedPortableValue,
            message:
                'A combined text decoration was omitted. Reapply it in the generated TextStyle.',
            path: r'$.style.textStyle.decoration',
          );
        }
      }
      _optionalColor(writer, 'decorationColor', style.decorationColor);
      if (style.decorationStyle != null) {
        writer.namedArgument(
          'decorationStyle',
          'TextDecorationStyle.${style.decorationStyle!.name}',
        );
      }
      _optionalNumber(writer, 'decorationThickness', style.decorationThickness);
    });
    writer.writeLine('),');
  }

  String _fontWeightLiteral(FontWeight weight) => 'FontWeight.w${weight.value}';

  void _fontWeightIf(
    DartSourceWriter writer,
    String name,
    FontWeight value,
    FontWeight defaultValue,
  ) {
    if (options.includeDefaultValues || value != defaultValue) {
      writer.namedArgument(name, _fontWeightLiteral(value));
    }
  }

  String? _textDecorationLiteral(TextDecoration decoration) {
    if (decoration == TextDecoration.none) return 'TextDecoration.none';
    if (decoration == TextDecoration.underline) {
      return 'TextDecoration.underline';
    }
    if (decoration == TextDecoration.overline) return 'TextDecoration.overline';
    if (decoration == TextDecoration.lineThrough) {
      return 'TextDecoration.lineThrough';
    }
    return null;
  }

  String _edgeInsetsLiteral(EdgeInsets value) =>
      'EdgeInsets.fromLTRB(${DartSourceWriter.numberLiteral(value.left)}, '
      '${DartSourceWriter.numberLiteral(value.top)}, '
      '${DartSourceWriter.numberLiteral(value.right)}, '
      '${DartSourceWriter.numberLiteral(value.bottom)})';

  void _edgeInsetsIf(
    DartSourceWriter writer,
    String name,
    EdgeInsets value,
    EdgeInsets defaultValue,
  ) {
    if (options.includeDefaultValues || value != defaultValue) {
      writer.namedArgument(name, _edgeInsetsLiteral(value));
    }
  }

  String _borderRadiusLiteral(BorderRadius value) {
    String radius(Radius value) => value.x == value.y
        ? 'Radius.circular(${DartSourceWriter.numberLiteral(value.x)})'
        : 'Radius.elliptical(${DartSourceWriter.numberLiteral(value.x)}, '
              '${DartSourceWriter.numberLiteral(value.y)})';
    return 'BorderRadius.only('
        'topLeft: ${radius(value.topLeft)}, '
        'topRight: ${radius(value.topRight)}, '
        'bottomLeft: ${radius(value.bottomLeft)}, '
        'bottomRight: ${radius(value.bottomRight)})';
  }

  void _optionalOffset(DartSourceWriter writer, String name, Offset? value) {
    if (value != null) writer.namedArgument(name, _offsetLiteral(value));
  }

  void _offsetIf(
    DartSourceWriter writer,
    String name,
    Offset value,
    Offset defaultValue,
  ) {
    if (options.includeDefaultValues || value != defaultValue) {
      writer.namedArgument(name, _offsetLiteral(value));
    }
  }

  void _optionalNumberList(
    DartSourceWriter writer,
    String name,
    List<double>? values,
  ) {
    if (values == null) return;
    writer.namedArgument(
      name,
      '[${values.map(DartSourceWriter.numberLiteral).join(', ')}]',
    );
  }

  void _optionalNullableNumberList(
    DartSourceWriter writer,
    String name,
    List<double?> values,
  ) {
    if (values.isEmpty) return;
    writer.namedArgument(
      name,
      '[${values.map((value) => value == null ? 'null' : DartSourceWriter.numberLiteral(value)).join(', ')}]',
    );
  }

  void _colorIf(
    DartSourceWriter writer,
    String name,
    Color value,
    Color defaultValue,
  ) {
    if (options.includeDefaultValues || value != defaultValue) {
      writer.namedArgument(name, DartSourceWriter.colorLiteral(value));
    }
  }

  void _warn({required String code, required String message, String? path}) {
    final warning = ChartSourceWarning(
      code: code,
      message: message,
      path: path,
    );
    if (!_warnings.contains(warning)) _warnings.add(warning);
  }

  void _optionalString(DartSourceWriter writer, String name, String? value) {
    if (value != null) {
      writer.namedArgument(name, DartSourceWriter.stringLiteral(value));
    }
  }

  void _optionalColor(DartSourceWriter writer, String name, Color? value) {
    if (value != null) {
      writer.namedArgument(name, DartSourceWriter.colorLiteral(value));
    }
  }

  void _optionalNumber(DartSourceWriter writer, String name, num? value) {
    if (value != null) {
      writer.namedArgument(name, DartSourceWriter.numberLiteral(value));
    }
  }

  void _valueIf<T>(
    DartSourceWriter writer,
    String name,
    T value, {
    required T defaultValue,
  }) {
    if (options.includeDefaultValues || value != defaultValue) {
      writer.namedArgument(name, value.toString());
    }
  }

  void _numberIf(
    DartSourceWriter writer,
    String name,
    num value,
    num defaultValue,
  ) {
    if (options.includeDefaultValues || value != defaultValue) {
      writer.namedArgument(name, DartSourceWriter.numberLiteral(value));
    }
  }

  void _durationIf(
    DartSourceWriter writer,
    String name,
    Duration value,
    Duration defaultValue,
  ) {
    if (options.includeDefaultValues || value != defaultValue) {
      writer.namedArgument(
        name,
        'Duration(microseconds: ${value.inMicroseconds})',
      );
    }
  }

  void _enumIf(
    DartSourceWriter writer,
    String name,
    String enumType,
    String valueName, {
    required String defaultName,
  }) {
    if (options.includeDefaultValues || valueName != defaultName) {
      writer.namedArgument(name, '$enumType.$valueName');
    }
  }
}
