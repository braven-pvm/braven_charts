import 'dart:ui' show Color;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChartSelectionConfig', () {
    test('defaults to direct replacement with portable modifiers', () {
      const config = ChartSelectionConfig();

      expect(config.acquisitionMode, ChartSelectionAcquisitionMode.point);
      expect(config.scope, ChartSelectionScope.mark);
      expect(config.operation, ChartSelectionOperation.replace);
      expect(config.dragActivation, ChartSelectionDragActivation.primaryButton);
      expect(config.clearOnBackgroundTap, isTrue);
      expect(config.useModifierKeys, isTrue);
      expect(config.dataPointHitRadius, 20);
      expect(config.completeSeriesHitRadius, 22);
      expect(config.dataPointHoverScale, 1.5);
      expect(config.dataPointSelectionScale, 2.67);
      expect(config.completeSeriesHoverStrokeScale, 1.75);
      expect(config.completeSeriesSelectionStrokeScale, 1.5);
      expect(config.brush.enabled, isFalse);
      expect(config.brush.initialVisible, isFalse);
      expect(config.brush.initialRange, isNull);
      expect(config.ownsPrimaryDrag(), isFalse);
      expect(
        config.resolveOperation(controlOrMeta: true),
        ChartSelectionOperation.toggle,
      );
      expect(config.resolveOperation(shift: true), ChartSelectionOperation.add);
      expect(
        config.resolveOperation(alt: true),
        ChartSelectionOperation.subtract,
      );
    });

    test('modifier precedence is deterministic', () {
      const config = ChartSelectionConfig();

      expect(
        config.resolveOperation(controlOrMeta: true, shift: true),
        ChartSelectionOperation.add,
      );
      expect(
        config.resolveOperation(controlOrMeta: true, shift: true, alt: true),
        ChartSelectionOperation.subtract,
      );
    });

    test('can preserve an explicit operation when modifiers are disabled', () {
      const config = ChartSelectionConfig(
        acquisitionMode: ChartSelectionAcquisitionMode.lasso,
        scope: ChartSelectionScope.wholeSeries,
        operation: ChartSelectionOperation.add,
        clearOnBackgroundTap: false,
        useModifierKeys: false,
      );

      expect(
        config.resolveOperation(controlOrMeta: true, shift: true, alt: true),
        ChartSelectionOperation.add,
      );
      expect(
        config
            .copyWith(acquisitionMode: ChartSelectionAcquisitionMode.rectangle)
            .acquisitionMode,
        ChartSelectionAcquisitionMode.rectangle,
      );
      expect(config.copyWith().scope, ChartSelectionScope.wholeSeries);
      expect(
        config.copyWith(
          scope: ChartSelectionScope.markOrWholeSeries,
          dataPointHitRadius: 14,
          completeSeriesHitRadius: 30,
          dataPointHoverScale: 1.8,
          dataPointSelectionScale: 3.2,
          completeSeriesHoverStrokeScale: 2.1,
          completeSeriesSelectionStrokeScale: 1.9,
        ),
        const ChartSelectionConfig(
          acquisitionMode: ChartSelectionAcquisitionMode.lasso,
          scope: ChartSelectionScope.markOrWholeSeries,
          operation: ChartSelectionOperation.add,
          clearOnBackgroundTap: false,
          useModifierKeys: false,
          dataPointHitRadius: 14,
          completeSeriesHitRadius: 30,
          dataPointHoverScale: 1.8,
          dataPointSelectionScale: 3.2,
          completeSeriesHoverStrokeScale: 2.1,
          completeSeriesSelectionStrokeScale: 1.9,
        ),
      );
    });

    test(
      'drag ownership is explicit and independent from viewport gestures',
      () {
        const rectangle = ChartSelectionConfig(
          acquisitionMode: ChartSelectionAcquisitionMode.rectangle,
        );
        const modifiedRectangle = ChartSelectionConfig(
          acquisitionMode: ChartSelectionAcquisitionMode.rectangle,
          dragActivation: ChartSelectionDragActivation.shiftPrimaryButton,
        );

        expect(rectangle.ownsPrimaryDrag(), isTrue);
        expect(rectangle.ownsPrimaryDrag(shift: true), isTrue);
        expect(modifiedRectangle.ownsPrimaryDrag(), isFalse);
        expect(modifiedRectangle.ownsPrimaryDrag(shift: true), isTrue);
        expect(
          modifiedRectangle.copyWith(
            dragActivation: ChartSelectionDragActivation.primaryButton,
          ),
          rectangle,
        );
        for (final acquisitionMode in const [
          ChartSelectionAcquisitionMode.xInterval,
          ChartSelectionAcquisitionMode.yInterval,
          ChartSelectionAcquisitionMode.lasso,
        ]) {
          expect(
            ChartSelectionConfig(
              acquisitionMode: acquisitionMode,
            ).ownsPrimaryDrag(),
            isTrue,
          );
        }
      },
    );

    test('persistent brush state and styling are immutable and portable', () {
      const range = ChartSelectionBrushRange(
        minimum: 2,
        maximum: 6,
        referenceSeriesId: 'temperature',
      );
      const style = ChartSelectionBrushStyle(
        fillColor: Color(0xFF2563EB),
        fillOpacity: 0.22,
        borderColor: Color(0xFF1D4ED8),
        borderWidth: 2,
        borderRadius: 6,
        handleFillColor: Color(0xFFFFFFFF),
        handleBorderColor: Color(0xFF1D4ED8),
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
          lineWidth: 1.5,
          pattern: ChartSelectionBrushGridPattern.dashed,
        ),
      );
      const brush = ChartSelectionBrushConfig(
        enabled: true,
        keyboardEnabled: true,
        initialVisible: true,
        initialRange: range,
        style: style,
      );
      const config = ChartSelectionConfig(
        acquisitionMode: ChartSelectionAcquisitionMode.xInterval,
        brush: brush,
      );

      expect(config.brush, brush);
      expect(
        range.copyWith(minimum: 3, maximum: 7),
        const ChartSelectionBrushRange(
          minimum: 3,
          maximum: 7,
          referenceSeriesId: 'temperature',
        ),
      );
      expect(
        range.copyWith(clearReferenceSeriesId: true).referenceSeriesId,
        isNull,
      );
      expect(style.copyWith(clearFillColor: true).fillColor, isNull);
      expect(style.copyWith(clearBorderColor: true).borderColor, isNull);
      expect(style.grid.showsHorizontal, isTrue);
      expect(style.grid.showsVertical, isTrue);
      expect(style.grid.rows * style.grid.columns, 12);
      expect(
        style.copyWith(clearHandleFillColor: true).handleFillColor,
        isNull,
      );
      expect(
        style.copyWith(clearHandleBorderColor: true).handleBorderColor,
        isNull,
      );
      expect(
        style
            .copyWith(clearKeyboardFocusBorderColor: true)
            .keyboardFocusBorderColor,
        isNull,
      );
      expect(
        brush.copyWith(clearInitialRange: true),
        const ChartSelectionBrushConfig(
          enabled: true,
          keyboardEnabled: true,
          initialVisible: true,
          style: style,
        ),
      );
      expect(
        brush
            .copyWith(clearInitialRange: true)
            .withInitialState(range, false),
        const ChartSelectionBrushConfig(
          enabled: true,
          keyboardEnabled: true,
          initialRange: range,
          style: style,
        ),
      );
      expect(config.copyWith(), config);
    });

    test('box bounds are ordered, immutable, and separately configurable', () {
      const box = ChartSelectionBrushBox(
        minimumX: 2,
        maximumX: 6,
        minimumY: 30,
        maximumY: 55,
        referenceSeriesId: 'signal',
      );
      expect(
        box.copyWith(minimumX: 3, maximumY: 60),
        const ChartSelectionBrushBox(
          minimumX: 3,
          maximumX: 6,
          minimumY: 30,
          maximumY: 60,
          referenceSeriesId: 'signal',
        ),
      );
      expect(
        const ChartSelectionBrushConfig(
          enabled: true,
          initialVisible: true,
          initialBox: box,
        ).copyWith(clearInitialRange: true).initialBox,
        box,
      );
    });
  });
}
