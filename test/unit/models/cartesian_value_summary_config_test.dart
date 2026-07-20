import 'dart:ui' show Color, Offset;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/painting.dart' show Alignment, EdgeInsets;
import 'package:flutter_test/flutter_test.dart';

/// Compiles only while [CartesianValueSummaryPresentation] stays sealed and
/// the switch remains exhaustive without a wildcard case.
String _describePresentation(CartesianValueSummaryPresentation presentation) =>
    switch (presentation) {
      CartesianValueSummaryOverlay() => 'overlay',
      CartesianValueSummaryAnnotation() => 'annotation',
    };

/// Compiles only while [CartesianValueSummaryContent] stays sealed and the
/// switch remains exhaustive without a wildcard case.
String _describeContent(CartesianValueSummaryContent content) =>
    switch (content) {
      CartesianValueSummaryAutomaticContent() => 'automatic',
      CartesianValueSummaryBuilderContent() => 'builder',
    };

CartesianValueSummaryContentModel _emptyModel(
  CartesianTrackingSnapshot snapshot,
) => const CartesianValueSummaryContentModel();

class _StubController implements CartesianValueSummaryController {
  @override
  ChartPointRef? get pinnedPoint => null;

  @override
  void pin(ChartPointRef point) {}

  @override
  void clearPin() {}

  @override
  void resetPlacement() {}
}

void main() {
  group('ChartOverlayPlacement', () {
    test('defaults to a zero offset from the anchor', () {
      const placement = ChartOverlayPlacement(anchor: Alignment.bottomRight);

      expect(placement.anchor, Alignment.bottomRight);
      expect(placement.offset, Offset.zero);
    });

    test('topLeft preset uses a 12 pixel inset', () {
      expect(ChartOverlayPlacement.topLeft.anchor, Alignment.topLeft);
      expect(ChartOverlayPlacement.topLeft.offset, const Offset(12, 12));
    });

    test('copyWith replaces only the given fields', () {
      const placement = ChartOverlayPlacement(
        anchor: Alignment.topRight,
        offset: Offset(4, 6),
      );

      final moved = placement.copyWith(offset: const Offset(20, 30));
      expect(moved.anchor, Alignment.topRight);
      expect(moved.offset, const Offset(20, 30));

      final reAnchored = placement.copyWith(anchor: Alignment.bottomLeft);
      expect(reAnchored.anchor, Alignment.bottomLeft);
      expect(reAnchored.offset, const Offset(4, 6));
    });

    test('uses value equality', () {
      const left = ChartOverlayPlacement(
        anchor: Alignment.topLeft,
        offset: Offset(12, 12),
      );

      expect(left, ChartOverlayPlacement.topLeft);
      expect(left.hashCode, ChartOverlayPlacement.topLeft.hashCode);
      expect(
        left,
        isNot(const ChartOverlayPlacement(anchor: Alignment.topLeft)),
      );
      expect(
        left,
        isNot(
          const ChartOverlayPlacement(
            anchor: Alignment.bottomRight,
            offset: Offset(12, 12),
          ),
        ),
      );
    });
  });

  group('CartesianValueSummaryPresentation', () {
    test('overlay defaults to the topLeft placement preset', () {
      const presentation = CartesianValueSummaryPresentation.overlay();

      expect(presentation, isA<CartesianValueSummaryOverlay>());
      final overlay = presentation as CartesianValueSummaryOverlay;
      expect(overlay.placement, ChartOverlayPlacement.topLeft);
    });

    test('annotation defaults to non-draggable, clamped, topLeft', () {
      const presentation = CartesianValueSummaryPresentation.annotation();

      expect(presentation, isA<CartesianValueSummaryAnnotation>());
      final annotation = presentation as CartesianValueSummaryAnnotation;
      expect(annotation.placement, ChartOverlayPlacement.topLeft);
      expect(annotation.draggable, isFalse);
      expect(annotation.clampToPlot, isTrue);
    });

    test('both kinds use value equality', () {
      expect(
        const CartesianValueSummaryPresentation.overlay(),
        const CartesianValueSummaryPresentation.overlay(),
      );
      expect(
        const CartesianValueSummaryPresentation.annotation(draggable: true),
        const CartesianValueSummaryPresentation.annotation(draggable: true),
      );
      expect(
        const CartesianValueSummaryPresentation.overlay(),
        isNot(const CartesianValueSummaryPresentation.annotation()),
      );
      expect(
        const CartesianValueSummaryPresentation.annotation(),
        isNot(const CartesianValueSummaryPresentation.annotation(
          draggable: true,
        )),
      );
      expect(
        const CartesianValueSummaryPresentation.overlay(),
        isNot(
          const CartesianValueSummaryPresentation.overlay(
            placement: ChartOverlayPlacement(anchor: Alignment.bottomRight),
          ),
        ),
      );
    });

    test('switch over the sealed kinds is exhaustive', () {
      expect(
        _describePresentation(const CartesianValueSummaryPresentation.overlay()),
        'overlay',
      );
      expect(
        _describePresentation(
          const CartesianValueSummaryPresentation.annotation(),
        ),
        'annotation',
      );
    });
  });

  group('CartesianValueSummaryContent', () {
    test('automatic defaults exclude trends and hidden series', () {
      const content = CartesianValueSummaryContent.automatic();

      expect(content, isA<CartesianValueSummaryAutomaticContent>());
      final automatic = content as CartesianValueSummaryAutomaticContent;
      expect(automatic.includeTrends, isFalse);
      expect(automatic.includeHiddenSeries, isFalse);
    });

    test('automatic content uses value equality', () {
      expect(
        const CartesianValueSummaryContent.automatic(),
        const CartesianValueSummaryContent.automatic(),
      );
      expect(
        const CartesianValueSummaryContent.automatic(),
        isNot(const CartesianValueSummaryContent.automatic(
          includeTrends: true,
        )),
      );
    });

    test('builder content keeps the builder and optional descriptor id', () {
      final content = CartesianValueSummaryContent.builder(
        _emptyModel,
        descriptorId: 'training-summary',
      );

      expect(content, isA<CartesianValueSummaryBuilderContent>());
      final builderContent = content as CartesianValueSummaryBuilderContent;
      expect(builderContent.builder, same(_emptyModel));
      expect(builderContent.descriptorId, 'training-summary');
    });

    test('builder content compares builder identity and descriptor id', () {
      final left = CartesianValueSummaryContent.builder(_emptyModel);
      final right = CartesianValueSummaryContent.builder(_emptyModel);
      final other = CartesianValueSummaryContent.builder(
        (snapshot) => const CartesianValueSummaryContentModel(),
      );

      expect(left, right);
      expect(left.hashCode, right.hashCode);
      expect(left, isNot(other));
      expect(
        CartesianValueSummaryContent.builder(_emptyModel, descriptorId: 'a'),
        isNot(
          CartesianValueSummaryContent.builder(_emptyModel, descriptorId: 'b'),
        ),
      );
    });

    test('switch over the sealed kinds is exhaustive', () {
      expect(
        _describeContent(const CartesianValueSummaryContent.automatic()),
        'automatic',
      );
      expect(
        _describeContent(CartesianValueSummaryContent.builder(_emptyModel)),
        'builder',
      );
    });
  });

  group('CartesianValueSummaryContentModel', () {
    test('defaults to an empty untitled model', () {
      const model = CartesianValueSummaryContentModel();

      expect(model.title, isNull);
      expect(model.subtitle, isNull);
      expect(model.accentColor, isNull);
      expect(model.rows, isEmpty);
    });

    test('model and rows use value equality', () {
      const row = CartesianValueSummaryRow(label: 'Close', value: '104.20');

      expect(row, const CartesianValueSummaryRow(label: 'Close', value: '104.20'));
      expect(
        row,
        isNot(const CartesianValueSummaryRow(label: 'Open', value: '104.20')),
      );
      expect(
        row,
        isNot(
          const CartesianValueSummaryRow(
            label: 'Close',
            value: '104.20',
            semanticValue: '104.20 dollars',
          ),
        ),
      );

      const model = CartesianValueSummaryContentModel(
        title: 'AAPL',
        rows: [row],
      );
      expect(
        model,
        const CartesianValueSummaryContentModel(title: 'AAPL', rows: [row]),
      );
      expect(
        model,
        isNot(const CartesianValueSummaryContentModel(title: 'AAPL')),
      );
    });
  });

  group('CartesianValueSummaryStyle', () {
    test('every field defaults to inherit', () {
      const style = CartesianValueSummaryStyle();

      expect(style.backgroundColor.isInherit, isTrue);
      expect(style.backgroundOpacity.isInherit, isTrue);
      expect(style.borderColor.isInherit, isTrue);
      expect(style.borderWidth.isInherit, isTrue);
      expect(style.borderRadius.isInherit, isTrue);
      expect(style.padding.isInherit, isTrue);
      expect(style.textStyle.isInherit, isTrue);
      expect(style.labelStyle.isInherit, isTrue);
      expect(style.accentColor.isInherit, isTrue);
      expect(style.shadow.isInherit, isTrue);
      expect(style.minWidth.isInherit, isTrue);
      expect(style.maxWidth.isInherit, isTrue);
      expect(style.rowGap.isInherit, isTrue);
    });

    test('cleared fields stay distinct from inherited fields', () {
      const cleared = CartesianValueSummaryStyle(
        backgroundColor: ChartStyleValue<Color>.none(),
      );

      expect(cleared.backgroundColor.isNone, isTrue);
      expect(cleared, isNot(const CartesianValueSummaryStyle()));
    });

    test('copyWith replaces only the given fields', () {
      const style = CartesianValueSummaryStyle(
        backgroundColor: ChartStyleValue<Color>.value(Color(0xFF112233)),
        rowGap: ChartStyleValue<double>.value(6),
      );

      final updated = style.copyWith(
        borderWidth: const ChartStyleValue<double>.value(2),
        padding: const ChartStyleValue<EdgeInsets>.value(EdgeInsets.all(10)),
      );

      expect(
        updated.backgroundColor,
        const ChartStyleValue<Color>.value(Color(0xFF112233)),
      );
      expect(updated.rowGap, const ChartStyleValue<double>.value(6));
      expect(updated.borderWidth, const ChartStyleValue<double>.value(2));
      expect(
        updated.padding,
        const ChartStyleValue<EdgeInsets>.value(EdgeInsets.all(10)),
      );
      expect(updated.textStyle.isInherit, isTrue);
    });

    test('uses value equality across all fields', () {
      const left = CartesianValueSummaryStyle(
        accentColor: ChartStyleValue<Color>.value(Color(0xFF445566)),
      );
      const right = CartesianValueSummaryStyle(
        accentColor: ChartStyleValue<Color>.value(Color(0xFF445566)),
      );

      expect(left, right);
      expect(left.hashCode, right.hashCode);
      expect(
        left,
        isNot(
          const CartesianValueSummaryStyle(
            accentColor: ChartStyleValue<Color>.none(),
          ),
        ),
      );
    });
  });

  group('CartesianValueSummaryConfig', () {
    test('defaults to disabled with tracking-then-latest automatic content',
        () {
      const config = CartesianValueSummaryConfig();

      expect(config.enabled, isFalse);
      expect(config.presentation, isA<CartesianValueSummaryOverlay>());
      expect(
        config.valuePolicy,
        CartesianValueSummaryValuePolicy.trackingThenLatest,
      );
      expect(config.content, isA<CartesianValueSummaryAutomaticContent>());
      expect(config.style, const CartesianValueSummaryStyle());
      expect(config.showSeriesAccent, isTrue);
      expect(config.announceChanges, isFalse);
      expect(config.onPlacementChanged, isNull);
      expect(config.controller, isNull);
    });

    test('const defaults are equal', () {
      expect(
        const CartesianValueSummaryConfig(),
        const CartesianValueSummaryConfig(),
      );
      expect(
        const CartesianValueSummaryConfig().hashCode,
        const CartesianValueSummaryConfig().hashCode,
      );
    });

    test('onPlacementChanged is excluded from equality and hashCode', () {
      final withCallback = CartesianValueSummaryConfig(
        enabled: true,
        onPlacementChanged: (placement) {},
      );
      const withoutCallback = CartesianValueSummaryConfig(enabled: true);

      expect(withCallback, withoutCallback);
      expect(withCallback.hashCode, withoutCallback.hashCode);
    });

    test('controller is excluded from equality and hashCode', () {
      final withController = CartesianValueSummaryConfig(
        enabled: true,
        controller: _StubController(),
      );
      const withoutController = CartesianValueSummaryConfig(enabled: true);

      expect(withController, withoutController);
      expect(withController.hashCode, withoutController.hashCode);
    });

    test('value fields participate in equality', () {
      const base = CartesianValueSummaryConfig();

      expect(base, isNot(const CartesianValueSummaryConfig(enabled: true)));
      expect(
        base,
        isNot(
          const CartesianValueSummaryConfig(
            presentation: CartesianValueSummaryPresentation.annotation(),
          ),
        ),
      );
      expect(
        base,
        isNot(
          const CartesianValueSummaryConfig(
            valuePolicy: CartesianValueSummaryValuePolicy.explicitOnly,
          ),
        ),
      );
      expect(
        base,
        isNot(
          const CartesianValueSummaryConfig(
            content: CartesianValueSummaryContent.automatic(
              includeTrends: true,
            ),
          ),
        ),
      );
      expect(
        base,
        isNot(
          const CartesianValueSummaryConfig(
            style: CartesianValueSummaryStyle(
              backgroundColor: ChartStyleValue<Color>.none(),
            ),
          ),
        ),
      );
      expect(
        base,
        isNot(const CartesianValueSummaryConfig(showSeriesAccent: false)),
      );
      expect(
        base,
        isNot(const CartesianValueSummaryConfig(announceChanges: true)),
      );
    });

    test('copyWith replaces only the given fields', () {
      const base = CartesianValueSummaryConfig();
      final controller = _StubController();

      final updated = base.copyWith(
        enabled: true,
        valuePolicy:
            CartesianValueSummaryValuePolicy.pinnedThenTrackingThenLatest,
        controller: controller,
      );

      expect(updated.enabled, isTrue);
      expect(
        updated.valuePolicy,
        CartesianValueSummaryValuePolicy.pinnedThenTrackingThenLatest,
      );
      expect(updated.controller, same(controller));
      expect(updated.presentation, base.presentation);
      expect(updated.content, base.content);
      expect(updated.style, base.style);
      expect(updated.showSeriesAccent, isTrue);
      expect(updated.announceChanges, isFalse);
    });
  });

  group('InteractionConfig.valueSummary', () {
    test('defaults to the disabled summary config', () {
      const config = InteractionConfig();

      expect(config.valueSummary, const CartesianValueSummaryConfig());
      expect(config.valueSummary.enabled, isFalse);
    });

    test('none() disables the value summary', () {
      expect(InteractionConfig.none().valueSummary.enabled, isFalse);
    });

    test('equality includes valueSummary value semantics', () {
      const base = InteractionConfig();
      const sameValue = InteractionConfig(
        valueSummary: CartesianValueSummaryConfig(),
      );
      const enabled = InteractionConfig(
        valueSummary: CartesianValueSummaryConfig(enabled: true),
      );

      expect(base, sameValue);
      expect(base.hashCode, sameValue.hashCode);
      expect(base, isNot(enabled));

      final callbackOnly = InteractionConfig(
        valueSummary: CartesianValueSummaryConfig(
          onPlacementChanged: (placement) {},
        ),
      );
      expect(base, callbackOnly);
    });

    test('copyWith threads the valueSummary sub-config', () {
      const base = InteractionConfig();
      const summary = CartesianValueSummaryConfig(enabled: true);

      final updated = base.copyWith(valueSummary: summary);

      expect(updated.valueSummary, summary);
      expect(base.copyWith(enableZoom: false).valueSummary, base.valueSummary);
    });
  });
}
