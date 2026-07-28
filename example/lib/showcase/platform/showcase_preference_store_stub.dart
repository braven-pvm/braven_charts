// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'showcase_preference_store_contract.dart';

ShowcasePreferenceStore createShowcasePreferenceStore() =>
    const _UnavailableShowcasePreferenceStore();

final class _UnavailableShowcasePreferenceStore
    implements ShowcasePreferenceStore {
  const _UnavailableShowcasePreferenceStore();

  @override
  String? read(String key) => null;

  @override
  void remove(String key) {}

  @override
  void write(String key, String value) {}
}
