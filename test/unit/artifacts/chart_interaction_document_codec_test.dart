import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChartInteractionDocumentCodec', () {
    test('round-trips every portable interaction field', () {
      const source = InteractionConfig(
        enabled: false,
        crosshair: CrosshairConfig(
          enabled: false,
          mode: CrosshairMode.horizontal,
          snapToDataPoint: false,
          snapRadius: 17.5,
          showCoordinateLabels: false,
          coordinateLabelStyle: TextStyle(
            color: Color(0xFF112233),
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
          style: CrosshairStyle(
            lineColor: Color(0xFF223344),
            lineWidth: 2.5,
            dashPattern: [7, 2],
            strokeCap: StrokeCap.square,
            labelBackgroundColor: Color(0xFF334455),
            labelTextColor: Color(0xFFCCDDEE),
            labelPadding: 6,
          ),
          displayMode: CrosshairDisplayMode.tracking,
          trackingModeThreshold: 777,
          interpolateValues: false,
          showTrackingTooltip: false,
          showIntersectionMarkers: false,
          intersectionMarkerRadius: 6.5,
        ),
        tooltip: TooltipConfig(
          enabled: false,
          triggerMode: TooltipTriggerMode.both,
          preferredPosition: TooltipPosition.left,
          showDelay: Duration(microseconds: 123456),
          hideDelay: Duration(microseconds: 654321),
          followCursor: true,
          offsetFromPoint: 12.5,
          style: TooltipStyle(
            backgroundColor: Color(0xEEFFFFFF),
            borderColor: Color(0xFF445566),
            borderWidth: 2,
            borderRadius: 9,
            shadowColor: Color(0x66000000),
            shadowBlurRadius: 7,
            padding: 11,
            textColor: Color(0xFF102030),
            fontSize: 14,
          ),
        ),
        gesture: GestureConfig(
          tapTimeout: Duration(microseconds: 222222),
          longPressTimeout: Duration(microseconds: 888888),
          panThreshold: 13.5,
          pinchThreshold: 0.25,
        ),
        touch: TouchInteractionConfig(
          enabled: false,
          profile: TouchInteractionProfile.explore,
          enablePinchZoom: false,
          enablePan: false,
          enablePanInertia: true,
          panInertiaDeceleration: 4.5,
          maximumPanInertiaVelocity: 1800,
          enableLongPressTracking: false,
          enableHapticFeedback: false,
        ),
        keyboard: KeyboardConfig(
          enabled: false,
          panStep: 15,
          zoomStep: 0.2,
          enableArrowKeys: false,
          enablePlusMinusKeys: false,
          enableHomeEndKeys: false,
        ),
        enableZoom: false,
        enablePan: false,
        enableSelection: false,
        selection: ChartSelectionConfig(
          acquisitionMode: ChartSelectionAcquisitionMode.lasso,
          scope: ChartSelectionScope.markOrWholeSeries,
          operation: ChartSelectionOperation.subtract,
          dragActivation: ChartSelectionDragActivation.shiftPrimaryButton,
          clearOnBackgroundTap: false,
          useModifierKeys: false,
          dataPointHitRadius: 14,
          completeSeriesHitRadius: 30,
          dataPointHoverScale: 1.8,
          dataPointSelectionScale: 3.2,
          completeSeriesHoverStrokeScale: 2.1,
          completeSeriesSelectionStrokeScale: 1.9,
          brush: ChartSelectionBrushConfig(
            enabled: true,
            keyboardEnabled: true,
            initialVisible: true,
            initialRange: ChartSelectionBrushRange(
              minimum: 2.5,
              maximum: 7.5,
              referenceSeriesId: 'signal',
            ),
            initialBox: ChartSelectionBrushBox(
              minimumX: 2.5,
              maximumX: 7.5,
              minimumY: 20,
              maximumY: 60,
              referenceSeriesId: 'signal',
            ),
            style: ChartSelectionBrushStyle(
              fillColor: Color(0xFF123456),
              fillOpacity: 0.22,
              borderColor: Color(0xFF654321),
              borderWidth: 2.5,
              borderRadius: 6,
              handleFillColor: Color(0xFFABCDEF),
              handleBorderColor: Color(0xFF102030),
              keyboardFocusBorderColor: Color(0xFFF97316),
              handleBorderWidth: 2,
              handleSize: 12,
              handleHitSize: 48,
              hoverOpacity: 0.28,
              activeOpacity: 0.34,
              grid: ChartSelectionBrushGridStyle(
                direction: ChartSelectionBrushGridDirection.both,
                rows: 3,
                columns: 4,
                color: Color(0xFF334155),
                lineWidth: 1.75,
                pattern: ChartSelectionBrushGridPattern.dashed,
              ),
            ),
          ),
        ),
        showFocusBorder: true,
        enableFocusOnHover: false,
        showXScrollbar: true,
        showYScrollbar: true,
        keyboardZoomPercent: 35,
      );

      final document = _success(ChartInteractionDocumentCodec.encode(source));
      final decoded = _success(
        ChartInteractionDocumentCodec.decode(
          ChartInteractionDocument.fromJson(document.toJson()),
        ),
      );

      expect(decoded, source);
      expect(document.requiredBindings, isEmpty);
    });

    test('defaults older selection documents to a disabled brush', () {
      final document = _success(
        ChartInteractionDocumentCodec.encode(
          const InteractionConfig(
            selection: ChartSelectionConfig(
              acquisitionMode: ChartSelectionAcquisitionMode.xInterval,
            ),
          ),
        ),
      );
      final configuration = Map<String, Object?>.from(
        document.configuration.toJson() as Map,
      );
      final selection = Map<String, Object?>.from(
        configuration['selection']! as Map,
      )..remove('brush');
      configuration['selection'] = selection;

      final decoded = _success(
        ChartInteractionDocumentCodec.decode(
          ChartInteractionDocument(
            configuration: JsonValue.fromJson(configuration) as JsonObjectValue,
          ),
        ),
      );

      expect(decoded.selection.brush, const ChartSelectionBrushConfig());
    });

    test('defaults older selection documents to mark scope', () {
      final document = _success(
        ChartInteractionDocumentCodec.encode(
          const InteractionConfig(
            selection: ChartSelectionConfig(
              scope: ChartSelectionScope.wholeSeries,
            ),
          ),
        ),
      );
      final configuration = Map<String, Object?>.from(
        document.configuration.toJson() as Map,
      );
      final selection = Map<String, Object?>.from(
        configuration['selection']! as Map,
      )..remove('scope');
      configuration['selection'] = selection;

      final decoded = _success(
        ChartInteractionDocumentCodec.decode(
          ChartInteractionDocument(
            configuration: JsonValue.fromJson(configuration) as JsonObjectValue,
          ),
        ),
      );

      expect(decoded.selection.scope, ChartSelectionScope.mark);
    });

    test('decodes legacy selection field and scope names', () {
      final document = _success(
        ChartInteractionDocumentCodec.encode(
          const InteractionConfig(
            selection: ChartSelectionConfig(
              acquisitionMode: ChartSelectionAcquisitionMode.rectangle,
              scope: ChartSelectionScope.categoryStack,
            ),
          ),
        ),
      );
      final configuration = Map<String, Object?>.from(
        document.configuration.toJson() as Map,
      );
      final selection = Map<String, Object?>.from(
        configuration['selection']! as Map,
      );
      selection['mode'] = selection.remove('acquisitionMode');
      selection['scope'] = 'stack';
      selection['dragActivation'] = 'shiftPrimary';
      configuration['selection'] = selection;

      final decoded = _success(
        ChartInteractionDocumentCodec.decode(
          ChartInteractionDocument(
            configuration: JsonValue.fromJson(configuration) as JsonObjectValue,
          ),
        ),
      );

      expect(
        decoded.selection.acquisitionMode,
        ChartSelectionAcquisitionMode.rectangle,
      );
      expect(decoded.selection.scope, ChartSelectionScope.categoryStack);
      expect(
        decoded.selection.dragActivation,
        ChartSelectionDragActivation.shiftPrimaryButton,
      );
    });

    test('maps the legacy combined scope to exclusive dual targeting', () {
      final document = _success(
        ChartInteractionDocumentCodec.encode(
          const InteractionConfig(
            selection: ChartSelectionConfig(
              scope: ChartSelectionScope.markOrWholeSeries,
            ),
          ),
        ),
      );
      final configuration = Map<String, Object?>.from(
        document.configuration.toJson() as Map,
      );
      final selection = Map<String, Object?>.from(
        configuration['selection']! as Map,
      )..['scope'] = 'mark_and_series';
      configuration['selection'] = selection;

      final decoded = _success(
        ChartInteractionDocumentCodec.decode(
          ChartInteractionDocument(
            configuration: JsonValue.fromJson(configuration) as JsonObjectValue,
          ),
        ),
      );

      expect(decoded.selection.scope, ChartSelectionScope.markOrWholeSeries);
    });

    test('round-trips every implemented semantic group scope', () {
      for (final scope in const <ChartSelectionScope>[
        ChartSelectionScope.category,
        ChartSelectionScope.categoryStack,
      ]) {
        final document = _success(
          ChartInteractionDocumentCodec.encode(
            InteractionConfig(selection: ChartSelectionConfig(scope: scope)),
          ),
        );
        final decoded = _success(
          ChartInteractionDocumentCodec.decode(document),
        );

        expect(decoded.selection.scope, scope);
      }
    });

    test('round-trips every acquisition geometry', () {
      for (final acquisitionMode in ChartSelectionAcquisitionMode.values) {
        final document = _success(
          ChartInteractionDocumentCodec.encode(
            InteractionConfig(
              selection: ChartSelectionConfig(acquisitionMode: acquisitionMode),
            ),
          ),
        );
        final decoded = _success(
          ChartInteractionDocumentCodec.decode(document),
        );

        expect(decoded.selection.acquisitionMode, acquisitionMode);
      }
    });

    test('requires explicit descriptors for executable callbacks', () {
      final result = ChartInteractionDocumentCodec.encode(
        InteractionConfig(onDataPointTap: (point, position) {}),
      );

      expect(result, isA<ChartArtifactFailure<ChartInteractionDocument>>());
      final failure = result as ChartArtifactFailure<ChartInteractionDocument>;
      expect(
        failure.error.code,
        ChartArtifactDiagnosticCodes.runtimeBindingRequired,
      );
      expect(failure.error.path, contains('onDataPointTap'));
    });

    test('records callback descriptors and required binding ids', () {
      final descriptor =
          JsonValue.fromJson({
                'id': 'app.chart.pointTap.v1',
                'arguments': {'surface': 'comparison'},
              })
              as JsonObjectValue;
      final document = _success(
        ChartInteractionDocumentCodec.encode(
          InteractionConfig(onDataPointTap: (point, position) {}),
          runtimeBindingDescriptors: {
            ChartInteractionDocumentCodec.dataPointTapBinding: descriptor,
          },
        ),
      );

      expect(document.requiredBindings, {'app.chart.pointTap.v1'});
      final callbacks =
          (document.configuration.toJson() as Map<String, Object?>)['callbacks']
              as Map<String, Object?>;
      expect(
        callbacks[ChartInteractionDocumentCodec.dataPointTapBinding],
        descriptor.toJson(),
      );

      final hydrationResult = ChartInteractionDocumentCodec.decode(document);
      expect(hydrationResult, isA<ChartArtifactSuccess<InteractionConfig>>());
      final degraded =
          hydrationResult as ChartArtifactSuccess<InteractionConfig>;
      expect(degraded.value.onDataPointTap, isNull);
      expect(
        degraded.warnings.single.code,
        ChartArtifactDiagnosticCodes.runtimeBindingRequired,
      );

      var tapped = false;
      void onTap(ChartDataPoint point, Offset position) => tapped = true;
      final rebound = _success(
        ChartInteractionDocumentCodec.decode(
          document,
          bindings: ChartRuntimeBindings(
            callbacks: ChartCallbackRegistry(
              callbacks: {'app.chart.pointTap.v1': onTap},
            ),
          ),
        ),
      );
      rebound.onDataPointTap?.call(
        const ChartDataPoint(x: 1, y: 2),
        Offset.zero,
      );
      expect(tapped, isTrue);
    });

    test('covers every callback field with a stable binding key', () {
      final descriptors = <String, JsonObjectValue>{};
      for (final key in [
        ChartInteractionDocumentCodec.tooltipBuilderBinding,
        ChartInteractionDocumentCodec.dataPointTapBinding,
        ChartInteractionDocumentCodec.dataPointHoverBinding,
        ChartInteractionDocumentCodec.dataPointLongPressBinding,
        ChartInteractionDocumentCodec.selectionChangedBinding,
        ChartInteractionDocumentCodec.zoomChangedBinding,
        ChartInteractionDocumentCodec.panChangedBinding,
        ChartInteractionDocumentCodec.viewportChangedBinding,
        ChartInteractionDocumentCodec.crosshairChangedBinding,
        ChartInteractionDocumentCodec.tooltipChangedBinding,
        ChartInteractionDocumentCodec.keyboardActionBinding,
      ]) {
        descriptors[key] =
            JsonValue.fromJson({'id': 'app.$key.v1'}) as JsonObjectValue;
      }

      final document = _success(
        ChartInteractionDocumentCodec.encode(
          InteractionConfig(
            tooltip: TooltipConfig(
              customBuilder: (context, dataPoint) => const SizedBox(),
            ),
            onDataPointTap: (point, position) {},
            onDataPointHover: (point, position) {},
            onDataPointLongPress: (point, position) {},
            onSelectionChanged: (points) {},
            onZoomChanged: (x, y) {},
            onPanChanged: (offset) {},
            onViewportChanged: (bounds) {},
            onCrosshairChanged: (position, points) {},
            onTooltipChanged: (visible, point) {},
            onKeyboardAction: (action, point) {},
          ),
          runtimeBindingDescriptors: descriptors,
        ),
      );

      expect(document.requiredBindings, hasLength(descriptors.length));
    });

    test('rejects malformed or unknown configuration values', () {
      final valid = _success(
        ChartInteractionDocumentCodec.encode(const InteractionConfig()),
      );
      final json = valid.configuration.toJson() as Map<String, Object?>;
      final crosshair = Map<String, Object?>.from(json['crosshair']! as Map)
        ..['mode'] = 'futureMode';
      json['crosshair'] = crosshair;

      final result = ChartInteractionDocumentCodec.decode(
        ChartInteractionDocument(
          configuration: JsonValue.fromJson(json) as JsonObjectValue,
        ),
      );

      expect(result, isA<ChartArtifactFailure<InteractionConfig>>());
      expect(
        (result as ChartArtifactFailure<InteractionConfig>).error.code,
        ChartArtifactDiagnosticCodes.invalidArtifact,
      );
    });
  });
}

T _success<T>(ChartArtifactResult<T> result) {
  expect(result, isA<ChartArtifactSuccess<T>>());
  return (result as ChartArtifactSuccess<T>).value;
}
