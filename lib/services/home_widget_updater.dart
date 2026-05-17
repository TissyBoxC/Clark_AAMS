import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class HomeWidgetUpdater {
  const HomeWidgetUpdater._();

  static const _channel = MethodChannel('clark_aams/home_widget');

  static Future<void> update() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('update');
    } catch (_) {
      // The widget bridge is best-effort and must not block local data saves.
    }
  }

  static Future<bool> pin([String variant = 'themed_2x2']) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      return await _channel.invokeMethod<bool>('pin', {'variant': variant}) ??
          false;
    } catch (_) {
      return false;
    }
  }
}
