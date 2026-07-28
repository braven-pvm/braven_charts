// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

@TestOn('browser')
library;

import 'package:braven_charts_example/showcase/platform/showcase_preference_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('web preference store round-trips through localStorage', () {
    final store = createShowcasePreferenceStore();
    const key = 'braven_charts.test.chart_panel_height';
    addTearDown(() => store.remove(key));

    store.remove(key);
    expect(store.read(key), isNull);

    store.write(key, '612.0');
    expect(store.read(key), '612.0');

    store.remove(key);
    expect(store.read(key), isNull);
  });
}
