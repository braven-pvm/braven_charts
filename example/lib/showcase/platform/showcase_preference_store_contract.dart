// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

abstract interface class ShowcasePreferenceStore {
  String? read(String key);

  void write(String key, String value);

  void remove(String key);
}
