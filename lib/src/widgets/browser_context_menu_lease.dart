import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Reference-counted browser context-menu suppression for mounted charts.
///
/// Flutter exposes one application-global browser menu switch. A lease keeps
/// one chart from restoring the browser menu while another chart still needs
/// native chart context menus.
class BrowserContextMenuLease {
  BrowserContextMenuLease._();

  static int _leaseCount = 0;
  static bool _restoreWhenReleased = false;
  static Future<void> _pending = Future<void>.value();

  static void acquire() {
    if (!kIsWeb) return;
    _leaseCount++;
    if (_leaseCount != 1) return;
    _restoreWhenReleased = BrowserContextMenu.enabled;
    if (!_restoreWhenReleased) return;
    _enqueue(BrowserContextMenu.disableContextMenu, 'disable');
  }

  static void release() {
    if (!kIsWeb || _leaseCount == 0) return;
    _leaseCount--;
    if (_leaseCount != 0 || !_restoreWhenReleased) return;
    _restoreWhenReleased = false;
    _enqueue(BrowserContextMenu.enableContextMenu, 'restore');
  }

  static void _enqueue(Future<void> Function() operation, String action) {
    _pending = _pending.then((_) => operation()).catchError((
      Object error,
      StackTrace stackTrace,
    ) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'braven_charts',
          context: ErrorDescription(
            'while attempting to $action the browser context menu',
          ),
        ),
      );
    });
    unawaited(_pending);
  }
}
