import 'package:test/test.dart';

// The annotations live in the root braven_charts package (package-internal,
// not barrel-exported) and must stay pure Dart so the generator toolchain
// can load them without a Flutter dependency.
// ignore: avoid_relative_lib_imports
import '../../../lib/src/meta/chart_surface.dart';

void main() {
  group('ChartSurface', () {
    test('defaults are empty metadata collections', () {
      const annotation = ChartSurface();
      expect(annotation.presetFactories, isEmpty);
      expect(annotation.sealedVariants, isEmpty);
      expect(annotation.combinedSetters, isEmpty);
      expect(annotation.excluded, isEmpty);
      expect(annotation.clearFlags, isEmpty);
    });

    test('all metadata fields round-trip', () {
      const annotation = ChartSurface(
        presetFactories: ['tracking', 'defaultConfig'],
        sealedVariants: ['OverlayPresentation', 'AnnotationPresentation'],
        combinedSetters: [
          CombinedSetter('withVisibleRange', ['min', 'max']),
        ],
        excluded: ['onPlacementChanged', 'controller'],
        clearFlags: {'trackingStyle': 'clearTrackingStyle'},
      );
      expect(annotation.presetFactories, ['tracking', 'defaultConfig']);
      expect(annotation.sealedVariants,
          ['OverlayPresentation', 'AnnotationPresentation']);
      expect(annotation.combinedSetters, hasLength(1));
      expect(annotation.excluded, ['onPlacementChanged', 'controller']);
      expect(annotation.clearFlags, {'trackingStyle': 'clearTrackingStyle'});
    });

    test('is const-constructible', () {
      const a = ChartSurface();
      const b = ChartSurface();
      expect(identical(a, b), isTrue);
    });
  });

  group('CombinedSetter', () {
    test('name and params round-trip', () {
      const setter = CombinedSetter('withVisibleRange', ['min', 'max']);
      expect(setter.name, 'withVisibleRange');
      expect(setter.params, ['min', 'max']);
    });
  });

  group('chartSurface constant', () {
    test('is a default ChartSurface instance', () {
      expect(chartSurface, isA<ChartSurface>());
      expect(chartSurface.presetFactories, isEmpty);
      expect(chartSurface.sealedVariants, isEmpty);
      expect(chartSurface.combinedSetters, isEmpty);
      expect(chartSurface.excluded, isEmpty);
      expect(chartSurface.clearFlags, isEmpty);
    });
  });

  group('ChartSurfaceExempt', () {
    test('carries the exemption reason', () {
      const exempt = ChartSurfaceExempt('value object, not a config');
      expect(exempt.reason, 'value object, not a config');
    });
  });
}
