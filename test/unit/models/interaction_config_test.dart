import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('focus border is opt-in by default', () {
    expect(const InteractionConfig().showFocusBorder, isFalse);
    expect(InteractionConfig.defaultConfig().showFocusBorder, isFalse);
    expect(InteractionConfig.all().showFocusBorder, isFalse);
  });

  test('tap profile keeps only touch details and selection enabled', () {
    final config = InteractionConfig.tap();

    expect(config.enabled, isTrue);
    expect(config.crosshair.enabled, isFalse);
    expect(config.tooltip.enabled, isTrue);
    expect(config.tooltip.triggerMode, TooltipTriggerMode.tap);
    expect(config.keyboard.enabled, isFalse);
    expect(config.enableZoom, isFalse);
    expect(config.enablePan, isFalse);
    expect(config.enableSelection, isTrue);
    expect(config.valueSummary.enabled, isFalse);
    expect(config.showFocusBorder, isFalse);
    expect(config.enableFocusOnHover, isFalse);
    expect(config.showXScrollbar, isFalse);
    expect(config.showYScrollbar, isFalse);
  });

  test('tap profile can expose details or selection independently', () {
    final detailsOnly = InteractionConfig.tap(enableSelection: false);
    final selectionOnly = InteractionConfig.tap(enableTooltip: false);

    expect(detailsOnly.tooltip.enabled, isTrue);
    expect(detailsOnly.enableSelection, isFalse);
    expect(selectionOnly.tooltip.enabled, isFalse);
    expect(selectionOnly.enableSelection, isTrue);
  });

  test('none profile is a literal master interaction opt-out', () {
    final config = InteractionConfig.none();

    expect(config.enabled, isFalse);
    expect(config.crosshair.enabled, isFalse);
    expect(config.tooltip.enabled, isFalse);
    expect(config.keyboard.enabled, isFalse);
    expect(config.enableZoom, isFalse);
    expect(config.enablePan, isFalse);
    expect(config.enableSelection, isFalse);
    expect(config.valueSummary.enabled, isFalse);
    expect(config.enableFocusOnHover, isFalse);
    expect(config.showXScrollbar, isFalse);
    expect(config.showYScrollbar, isFalse);
  });
}
