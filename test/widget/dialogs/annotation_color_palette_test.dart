import 'package:braven_charts/src/widgets/dialogs/annotation_color_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('always clears preset and custom color selections', (
    tester,
  ) async {
    Color? selected = const Color(0xFF123456);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            child: StatefulBuilder(
              builder: (context, setState) => AnnotationColorPalette(
                value: selected,
                keyPrefix: 'test-color',
                onChanged: (color) => setState(() => selected = color),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('test-color-clear')), findsOneWidget);
    expect(find.byKey(const ValueKey('test-color-custom')), findsOneWidget);
    expect(find.text('Custom'), findsNothing);
    final redSwatch = find.byKey(
      ValueKey('test-color-${Colors.red.toARGB32()}'),
    );
    final orangeSwatch = find.byKey(
      ValueKey('test-color-${Colors.orange.toARGB32()}'),
    );
    expect(tester.getRect(redSwatch).right, tester.getRect(orangeSwatch).left);
    expect(
      tester.getSize(redSwatch).width,
      greaterThan(tester.getSize(redSwatch).height),
    );
    expect(tester.widget<InkWell>(redSwatch).borderRadius, BorderRadius.zero);
    final swatchContainer = tester.widget<Container>(
      find.descendant(of: redSwatch, matching: find.byType(Container)),
    );
    expect(swatchContainer.decoration, isNull);

    await tester.tap(find.byKey(const ValueKey('test-color-clear')));
    await tester.pump();
    expect(selected, isNull);

    await tester.tap(redSwatch);
    await tester.pump();
    expect(selected, Colors.red);

    await tester.tap(redSwatch);
    await tester.pump();
    expect(selected, isNull);
  });

  group('custom color dialog', () {
    testWidgets('edits RGB without committing or losing the initial opacity', (
      tester,
    ) async {
      final changes = <Color?>[];
      await _mountPalette(tester, changes, value: const Color(0x80123456));
      await _openCustom(tester);
      expect(_hexText(tester), '80123456');
      await tester.enterText(_hex, '#abcdef');
      await tester.pump();
      expect(changes, isEmpty);
      await _select(tester);
      expect(changes.single?.toARGB32(), 0x80ABCDEF);
    });

    testWidgets(
      'accepts explicit ARGB and blocks invalid hex until corrected',
      (tester) async {
        final changes = <Color?>[];
        await _mountPalette(tester, changes);
        await _openCustom(tester);
        await tester.enterText(_hex, 'not-a-color');
        await tester.pump();
        expect(find.text('Use 6 RGB or 8 ARGB hex digits.'), findsOneWidget);
        expect(tester.widget<FilledButton>(_selectButton).onPressed, isNull);
        expect(changes, isEmpty);
        await tester.enterText(_hex, '40112233');
        await tester.pump();
        await _select(tester);
        expect(changes.single?.toARGB32(), 0x40112233);
      },
    );

    for (final dismissal in ['Cancel', 'Escape', 'barrier']) {
      testWidgets('$dismissal discards the dialog draft', (tester) async {
        final changes = <Color?>[];
        await _mountPalette(tester, changes);
        await _openCustom(tester);
        await tester.enterText(_hex, 'FFABCDEF');
        if (dismissal == 'Cancel') {
          await tester.tap(find.text('Cancel'));
        } else if (dismissal == 'Escape') {
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        } else {
          await tester.tapAt(const Offset(5, 5));
        }
        await tester.pumpAndSettle();
        expect(find.text('Select Color'), findsNothing);
        expect(changes, isEmpty);
      });
    }

    testWidgets(
      'initializes from fallback and otherwise from translucent blue',
      (tester) async {
        final changes = <Color?>[];
        await _mountPalette(
          tester,
          changes,
          fallback: const Color(0x40123456),
          presetOpacity: 0.25,
        );
        await _openCustom(tester);
        await _select(tester);
        expect(changes.single?.toARGB32(), 0x40123456);
        await _mountPalette(tester, changes, presetOpacity: 0.25);
        await _openCustom(tester);
        await _select(tester);
        expect(
          changes.last?.toARGB32(),
          Colors.blue.withValues(alpha: 0.25).toARGB32(),
        );
      },
    );

    testWidgets(
      'opacity and HSV controls change the draft using real gestures',
      (tester) async {
        final changes = <Color?>[];
        await _mountPalette(tester, changes, value: Colors.red);
        await _openCustom(tester);
        await _slide(tester, 'Hue', 0.5);
        await _slide(tester, 'Saturation', 0.5);
        await _slide(tester, 'Brightness', 0.5);
        await _slide(tester, 'Opacity', 0.5);
        expect(changes, isEmpty);
        await _select(tester);
        final color = changes.single!;
        final hsv = HSVColor.fromColor(color);
        expect(color.a, closeTo(0.5, 0.02));
        expect(hsv.hue, closeTo(180, 3));
        expect(hsv.saturation, closeTo(0.5, 0.02));
        expect(hsv.value, closeTo(0.5, 0.02));
      },
    );

    testWidgets('primary and accent shades preserve opacity', (tester) async {
      final changes = <Color?>[];
      await _mountPalette(tester, changes, value: const Color(0x80123456));
      await _openCustom(tester);
      await tester.tap(find.byTooltip('Primary Blue'));
      await tester.pump();
      await _tapVisible(tester, find.byTooltip('Shade 700'));
      expect(_hexText(tester), '801976D2');
      await _tapVisible(tester, find.text('Accent'));
      await _tapVisible(tester, find.byTooltip('Accent Pink'));
      await _tapVisible(tester, find.byTooltip('Shade 400'));
      expect(changes, isEmpty);
      await _select(tester);
      expect(
        changes.single?.toARGB32(),
        Colors.pinkAccent.shade400.withValues(alpha: 128 / 255).toARGB32(),
      );
    });

    testWidgets('starts material colors on their own shade family', (
      tester,
    ) async {
      final changes = <Color?>[];
      await _mountPalette(tester, changes, value: Colors.red.shade700);
      await _openCustom(tester);
      expect(find.text('Red shades'), findsOneWidget);
      await _tapVisible(tester, find.byTooltip('Shade 500'));
      await _select(tester);
      expect(changes.single?.toARGB32(), Colors.red.toARGB32());
    });

    testWidgets('retains chosen hue while brightness is zero', (tester) async {
      final changes = <Color?>[];
      await _mountPalette(tester, changes, value: Colors.black);
      await _openCustom(tester);
      await _slide(tester, 'Hue', 0.5);
      await _slide(tester, 'Saturation', 1);
      await _slide(tester, 'Brightness', 1);
      await _select(tester);
      expect(changes.single, const Color(0xFF00FFFF));
    });

    testWidgets('exposes descriptive names for color adjustment sliders', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        await _mountPalette(tester, <Color?>[]);
        await _openCustom(tester);
        for (final label in ['Hue', 'Saturation', 'Brightness', 'Opacity']) {
          await tester.ensureVisible(
            find.byKey(ValueKey('test-color-${label.toLowerCase()}')),
          );
          await tester.pumpAndSettle();
          expect(find.bySemanticsLabel(label), findsOneWidget);
        }
      } finally {
        semantics.dispose();
      }
    });

    testWidgets(
      'transparent drafts keep palette colors visible and preserve alpha',
      (tester) async {
        final changes = <Color?>[];
        await _mountPalette(tester, changes, value: const Color(0x00123456));
        await _openCustom(tester);
        final blue = find.byTooltip('Primary Blue');
        final paint = tester.widget<Material>(
          find.descendant(of: blue, matching: find.byType(Material)),
        );
        expect(paint.color?.toARGB32(), Colors.blue.toARGB32());
        await tester.tap(blue);
        await _select(tester);
        expect(changes.single?.toARGB32(), Colors.blue.toARGB32() & 0xFFFFFF);
      },
    );

    testWidgets('keeps five distinct confirmed recents in this palette only', (
      tester,
    ) async {
      final changes = <Color?>[];
      await _mountPalette(tester, changes);
      for (var i = 1; i <= 6; i++) {
        await _openCustom(tester);
        await tester.enterText(_hex, 'FF00000$i');
        await _select(tester);
      }
      await _openCustom(tester);
      expect(find.byTooltip('Recent #FF000001'), findsNothing);
      expect(find.byTooltip('Recent #FF000002'), findsOneWidget);
      await _tapVisible(tester, find.byTooltip('Recent #FF000003'));
      await _select(tester);
      expect(changes.last?.toARGB32(), 0xFF000003);
      await _openCustom(tester);
      expect(find.byTooltip('Recent #FF000003'), findsOneWidget);
      await tester.enterText(_hex, 'FFFF0000');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await _openCustom(tester);
      expect(find.byTooltip('Recent #FFFF0000'), findsNothing);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      // A second palette must not inherit state from an unrelated editor.
      await _mountPalette(tester, changes, keyPrefix: 'other-color');
      await tester.tap(find.byKey(const ValueKey('other-color-custom')));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Recent #FF000003'), findsNothing);
    });

    for (final size in [const Size(390, 844), const Size(320, 420)]) {
      testWidgets('custom picker scrolls without overflow at $size', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final changes = <Color?>[];
        await _mountPalette(tester, changes);
        await _openCustom(tester);
        await tester.ensureVisible(_hex);
        await tester.enterText(_hex, '7F123ABC');
        tester.view.viewInsets = const FakeViewPadding(bottom: 180);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();
        await _select(tester);
        expect(changes.single?.toARGB32(), 0x7F123ABC);
        expect(tester.takeException(), isNull);
      });
    }
  });
}

final _hex = find.byKey(const ValueKey('test-color-hex'));
final _selectButton = find.widgetWithText(FilledButton, 'Select');

Future<void> _mountPalette(
  WidgetTester tester,
  List<Color?> changes, {
  Color? value,
  Color? fallback,
  double presetOpacity = 1,
  String keyPrefix = 'test-color',
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ChartColorPalette(
          key: ValueKey(keyPrefix),
          value: value,
          keyPrefix: keyPrefix,
          customColorFallback: fallback,
          presetOpacity: presetOpacity,
          onChanged: changes.add,
        ),
      ),
    ),
  );
}

Future<void> _openCustom(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('test-color-custom')));
  await tester.pumpAndSettle();
  expect(_hex, findsOneWidget);
}

String _hexText(WidgetTester tester) =>
    tester.widget<TextField>(_hex).controller!.text;

Future<void> _select(WidgetTester tester) async {
  await tester.tap(_selectButton);
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _slide(WidgetTester tester, String label, double fraction) async {
  final finder = find.byKey(ValueKey('test-color-${label.toLowerCase()}'));
  await tester.ensureVisible(finder);
  final rect = tester.getRect(finder);
  await tester.tapAt(
    Offset(rect.left + 24 + (rect.width - 48) * fraction, rect.center.dy),
  );
  await tester.pumpAndSettle();
}
