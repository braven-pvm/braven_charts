import 'package:flutter/material.dart';

import '../models/x_axis_config.dart';
import '../models/y_axis_config.dart';
import '../models/y_axis_position.dart';
import 'chart_artifact_diagnostics.dart';
import 'chart_data_payload.dart';
import 'chart_document.dart';
import 'json_value.dart';

/// Audited adapters for the complete built-in X- and Y-axis models.
abstract final class ChartAxisDocumentCodec {
  static ChartArtifactResult<ChartAxisDocument> encodeXAxis(
    XAxisConfig axis, {
    String id = 'x',
    JsonObjectValue? formatter,
  }) {
    if (axis.labelFormatter != null && formatter == null) {
      return _runtimeBindingFailure(r'$.xAxis.formatter');
    }
    return ChartArtifactSuccess(
      value: ChartAxisDocument(
        id: id,
        axisType: 'x',
        position: 'bottom',
        label: axis.label,
        unit: axis.unit,
        color: axis.color?.toARGB32(),
        minimum: _optionalNumber(axis.min),
        maximum: _optionalNumber(axis.max),
        renderMinimum: _optionalNumber(axis.renderMin),
        renderMaximum: _optionalNumber(axis.renderMax),
        visible: axis.visible,
        showAxisLine: axis.showAxisLine,
        showTicks: axis.showTicks,
        showTickLabels: axis.showTickLabels,
        showCrosshairLabel: axis.showCrosshairLabel,
        crosshairLabelPosition: axis.crosshairLabelPosition.name,
        labelDisplay: axis.labelDisplay.name,
        layoutMinimum: ChartNumberDocument.fromDouble(axis.minHeight),
        layoutMaximum: ChartNumberDocument.fromDouble(axis.maxHeight),
        tickLabelPadding: ChartNumberDocument.fromDouble(axis.tickLabelPadding),
        axisLabelPadding: ChartNumberDocument.fromDouble(axis.axisLabelPadding),
        axisMargin: ChartNumberDocument.fromDouble(axis.axisMargin),
        tickCount: axis.tickCount,
        showMinorTicks: axis.showMinorTicks,
        minorTickCount: axis.minorTickCount,
        minorTickLength: ChartNumberDocument.fromDouble(axis.minorTickLength),
        formatter: formatter,
      ),
    );
  }

  static ChartArtifactResult<XAxisConfig> decodeXAxis(
    ChartAxisDocument document, {
    XAxisLabelFormatter? formatter,
  }) {
    try {
      _requireAxisType(document, 'x');
      if (document.position != 'bottom') {
        throw const FormatException('X-axis position must be bottom.');
      }
      return ChartArtifactSuccess(
        value: XAxisConfig(
          color: _optionalColor(document.color),
          label: document.label,
          unit: document.unit,
          min: document.minimum?.asDouble,
          max: document.maximum?.asDouble,
          renderMin: document.renderMinimum?.asDouble,
          renderMax: document.renderMaximum?.asDouble,
          visible: document.visible,
          showAxisLine: document.showAxisLine,
          showTicks: document.showTicks,
          showTickLabels: document.showTickLabels,
          showCrosshairLabel: document.showCrosshairLabel,
          crosshairLabelPosition: _enum(
            document.crosshairLabelPosition,
            CrosshairLabelPosition.values,
          ),
          labelDisplay: _enum(document.labelDisplay, AxisLabelDisplay.values),
          minHeight: document.layoutMinimum?.asDouble ?? 0,
          maxHeight: document.layoutMaximum?.asDouble ?? 60,
          tickLabelPadding: document.tickLabelPadding?.asDouble ?? 4,
          axisLabelPadding: document.axisLabelPadding?.asDouble ?? 5,
          axisMargin: document.axisMargin?.asDouble ?? 8,
          tickCount: document.tickCount,
          showMinorTicks: document.showMinorTicks,
          minorTickCount: document.minorTickCount,
          minorTickLength: document.minorTickLength?.asDouble ?? 3,
          labelFormatter: formatter,
        ),
      );
    } on Object catch (error) {
      return _invalidAxisFailure(error, r'$.xAxis');
    }
  }

  static ChartArtifactResult<ChartAxisDocument> encodeYAxis(
    YAxisConfig axis, {
    JsonObjectValue? formatter,
  }) {
    if (axis.labelFormatter != null && formatter == null) {
      return _runtimeBindingFailure(r'$.axes.formatter');
    }
    return ChartArtifactSuccess(
      value: ChartAxisDocument(
        id: axis.id,
        axisType: 'y',
        position: axis.position.name,
        label: axis.label,
        unit: axis.unit,
        color: axis.color?.toARGB32(),
        minimum: _optionalNumber(axis.min),
        maximum: _optionalNumber(axis.max),
        renderMinimum: _optionalNumber(axis.renderMin),
        renderMaximum: _optionalNumber(axis.renderMax),
        visible: axis.visible,
        showAxisLine: axis.showAxisLine,
        showTicks: axis.showTicks,
        showTickLabels: axis.showTickLabels,
        showCrosshairLabel: axis.showCrosshairLabel,
        crosshairLabelPosition: axis.crosshairLabelPosition.name,
        labelDisplay: axis.labelDisplay.name,
        layoutMinimum: ChartNumberDocument.fromDouble(axis.minWidth),
        layoutMaximum: ChartNumberDocument.fromDouble(axis.maxWidth),
        tickLabelPadding: ChartNumberDocument.fromDouble(axis.tickLabelPadding),
        axisLabelPadding: ChartNumberDocument.fromDouble(axis.axisLabelPadding),
        axisMargin: ChartNumberDocument.fromDouble(axis.axisMargin),
        tickCount: axis.tickCount,
        showMinorTicks: axis.showMinorTicks,
        minorTickCount: axis.minorTickCount,
        minorTickLength: ChartNumberDocument.fromDouble(axis.minorTickLength),
        formatter: formatter,
      ),
    );
  }

  static ChartArtifactResult<YAxisConfig> decodeYAxis(
    ChartAxisDocument document, {
    YAxisLabelFormatter? formatter,
  }) {
    try {
      _requireAxisType(document, 'y');
      final axis = YAxisConfig(
        position: _enum(document.position, YAxisPosition.values),
        color: _optionalColor(document.color),
        label: document.label,
        unit: document.unit,
        min: document.minimum?.asDouble,
        max: document.maximum?.asDouble,
        renderMin: document.renderMinimum?.asDouble,
        renderMax: document.renderMaximum?.asDouble,
        visible: document.visible,
        showAxisLine: document.showAxisLine,
        showTicks: document.showTicks,
        showTickLabels: document.showTickLabels,
        showCrosshairLabel: document.showCrosshairLabel,
        crosshairLabelPosition: _enum(
          document.crosshairLabelPosition,
          CrosshairLabelPosition.values,
        ),
        labelDisplay: _enum(document.labelDisplay, AxisLabelDisplay.values),
        minWidth: document.layoutMinimum?.asDouble ?? 0,
        maxWidth: document.layoutMaximum?.asDouble ?? 80,
        tickLabelPadding: document.tickLabelPadding?.asDouble ?? 4,
        axisLabelPadding: document.axisLabelPadding?.asDouble ?? 5,
        axisMargin: document.axisMargin?.asDouble ?? 8,
        tickCount: document.tickCount,
        showMinorTicks: document.showMinorTicks,
        minorTickCount: document.minorTickCount,
        minorTickLength: document.minorTickLength?.asDouble ?? 3,
        labelFormatter: formatter,
      );
      return ChartArtifactSuccess(
        value: document.id.isEmpty ? axis : axis.copyWith(id: document.id),
      );
    } on Object catch (error) {
      return _invalidAxisFailure(error, r'$.axes');
    }
  }
}

ChartNumberDocument? _optionalNumber(double? value) =>
    value == null ? null : ChartNumberDocument.fromDouble(value);

Color? _optionalColor(int? value) => value == null ? null : Color(value);

void _requireAxisType(ChartAxisDocument document, String expected) {
  if (document.axisType != expected && document.axisType != 'value') {
    throw FormatException(
      'Expected $expected axis document, found ${document.axisType}.',
    );
  }
}

T _enum<T extends Enum>(String name, List<T> values) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  throw FormatException('Unknown enum value "$name".');
}

ChartArtifactFailure<T> _runtimeBindingFailure<T>(
  String path,
) => ChartArtifactFailure(
  error: ChartArtifactError(
    code: ChartArtifactDiagnosticCodes.runtimeBindingRequired,
    message:
        'Axis label formatters require an explicit runtime binding descriptor.',
    path: path,
  ),
);

ChartArtifactFailure<T> _invalidAxisFailure<T>(Object error, String path) =>
    ChartArtifactFailure(
      error: ChartArtifactError(
        code: ChartArtifactDiagnosticCodes.invalidArtifact,
        message: 'Invalid built-in axis document: $error',
        path: path,
      ),
    );
