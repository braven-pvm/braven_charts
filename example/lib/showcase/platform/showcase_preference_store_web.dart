// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:web/web.dart' as web;

import 'showcase_preference_store_contract.dart';

ShowcasePreferenceStore createShowcasePreferenceStore() =>
    const _WebShowcasePreferenceStore();

final class _WebShowcasePreferenceStore implements ShowcasePreferenceStore {
  const _WebShowcasePreferenceStore();

  @override
  String? read(String key) {
    try {
      return web.window.localStorage.getItem(key);
    } on Object {
      return null;
    }
  }

  @override
  void remove(String key) {
    try {
      web.window.localStorage.removeItem(key);
    } on Object {
      // Storage can be blocked by privacy policy. Resizing must still work for
      // the current session.
    }
  }

  @override
  void write(String key, String value) {
    try {
      web.window.localStorage.setItem(key, value);
    } on Object {
      // Storage can be blocked or full. Keep the in-memory preference active.
    }
  }
}
