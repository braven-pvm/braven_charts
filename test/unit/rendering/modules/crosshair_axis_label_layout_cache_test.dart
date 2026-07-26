// Copyright (c) 2025 braven_charts. All rights reserved.

import 'package:braven_charts/src/rendering/modules/crosshair_axis_label_layout_cache.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CrosshairAxisLabelLayoutEnvironment', () {
    test('provides safe ambient defaults', () {
      const environment = CrosshairAxisLabelLayoutEnvironment();

      expect(environment.textDirection, TextDirection.ltr);
      expect(environment.locale, isNull);
      expect(environment.textScaler, TextScaler.noScaling);
      expect(environment.devicePixelRatio, 1);
    });

    test('retains every ambient layout input', () {
      const environment = CrosshairAxisLabelLayoutEnvironment(
        textDirection: TextDirection.rtl,
        locale: Locale('ar'),
        textScaler: TextScaler.linear(1.5),
        devicePixelRatio: 2,
      );

      expect(environment.textDirection, TextDirection.rtl);
      expect(environment.locale, const Locale('ar'));
      expect(environment.textScaler, const TextScaler.linear(1.5));
      expect(environment.devicePixelRatio, 2);
    });

    test('rejects a non-positive device pixel ratio', () {
      expect(
        () => CrosshairAxisLabelLayoutEnvironment(devicePixelRatio: 0),
        throwsAssertionError,
      );
    });
  });

  group('CrosshairAxisLabelLayoutRequest', () {
    test('equal requests compare and hash equally', () {
      final first = _request();
      final second = _request();

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    test('rejects invalid device pixel ratio and width constraints', () {
      expect(() => _request(devicePixelRatio: 0), throwsAssertionError);
      expect(() => _request(minWidth: -1), throwsAssertionError);
      expect(() => _request(minWidth: 20, maxWidth: 10), throwsAssertionError);
    });
  });

  group('CrosshairAxisLabelLayoutCache', () {
    late CrosshairAxisLabelLayoutCache cache;

    setUp(() {
      cache = CrosshairAxisLabelLayoutCache(capacity: 2);
    });

    tearDown(() {
      cache.dispose();
    });

    test('returns the identical painter for an exact compatible request', () {
      final first = cache.layout(_request());
      final second = cache.layout(_request());

      expect(second, same(first));
      expect(cache.debugEntryCount, 1);
      expect(cache.debugHitCount, 1);
      expect(cache.debugMissCount, 1);
      expect(cache.debugDisposedPainterCount, 0);
    });

    final incompatibleRequests =
        <String, CrosshairAxisLabelLayoutRequest Function()>{
          'text': () => _request(text: '43.00'),
          'style': () => _request(style: const TextStyle(fontSize: 12)),
          'direction': () => _request(textDirection: TextDirection.rtl),
          'locale': () => _request(locale: const Locale('ar')),
          'scaler': () => _request(textScaler: const TextScaler.linear(1.5)),
          'device pixel ratio': () => _request(devicePixelRatio: 2),
          'minimum width': () => _request(minWidth: 20),
          'maximum width': () => _request(maxWidth: 80),
        };

    for (final MapEntry(key: input, value: incompatibleRequest)
        in incompatibleRequests.entries) {
      test('misses when only $input changes', () {
        final first = cache.layout(_request());
        final second = cache.layout(incompatibleRequest());

        expect(second, isNot(same(first)));
        expect(cache.debugHitCount, 0);
        expect(cache.debugMissCount, 2);
      });
    }

    test('builds and lays out a painter from every paragraph input', () {
      final painter = cache.layout(
        _request(
          text: '43.00',
          style: const TextStyle(fontSize: 12),
          textDirection: TextDirection.rtl,
          locale: const Locale('ar'),
          textScaler: const TextScaler.linear(1.5),
          devicePixelRatio: 2,
          minWidth: 20,
          maxWidth: 80,
        ),
      );
      final span = painter.text! as TextSpan;

      expect(span.text, '43.00');
      expect(span.style, const TextStyle(fontSize: 12));
      expect(painter.textDirection, TextDirection.rtl);
      expect(painter.locale, const Locale('ar'));
      expect(painter.textScaler, const TextScaler.linear(1.5));
      expect(painter.width, inInclusiveRange(20, 80));
    });

    test(
      'evicts the least recently used painter and clear disposes the rest',
      () {
        final one = cache.layout(_request(text: 'one'));
        final two = cache.layout(_request(text: 'two'));

        expect(cache.layout(_request(text: 'one')), same(one));

        final three = cache.layout(_request(text: 'three'));

        expect(cache.debugEntryCount, 2);
        expect(cache.debugDisposedPainterCount, 1);
        expect(one.debugDisposed, isFalse);
        expect(two.debugDisposed, isTrue);
        expect(three.debugDisposed, isFalse);

        cache.clear();

        expect(cache.debugEntryCount, 0);
        expect(cache.debugDisposedPainterCount, 3);
        expect(one.debugDisposed, isTrue);
        expect(three.debugDisposed, isTrue);
      },
    );

    test('dispose is idempotent and rejects subsequent layout', () {
      cache.layout(_request(text: 'one'));
      cache.layout(_request(text: 'two'));

      cache.dispose();
      cache.dispose();

      expect(cache.debugEntryCount, 0);
      expect(cache.debugDisposedPainterCount, 2);
      expect(() => cache.layout(_request(text: 'three')), throwsStateError);
      expect(cache.debugHitCount, 0);
      expect(cache.debugMissCount, 2);
    });
  });
}

CrosshairAxisLabelLayoutRequest _request({
  String text = '42.00',
  TextStyle style = const TextStyle(fontSize: 11),
  TextDirection textDirection = TextDirection.ltr,
  Locale? locale = const Locale('en', 'ZA'),
  TextScaler textScaler = TextScaler.noScaling,
  double devicePixelRatio = 1,
  double minWidth = 0,
  double maxWidth = double.infinity,
}) {
  return CrosshairAxisLabelLayoutRequest(
    text: text,
    style: style,
    textDirection: textDirection,
    locale: locale,
    textScaler: textScaler,
    devicePixelRatio: devicePixelRatio,
    minWidth: minWidth,
    maxWidth: maxWidth,
  );
}
