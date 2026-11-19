import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// Uses the browser's Notification API.
///
/// Browsers have no way to schedule a notification for later, so scheduled
/// ones are held in timers: they only fire while the tab stays open.
class WebNotifier {
  WebNotifier._();
  static final _timers = <int, Timer>{};

  static bool get supported => web.window.has('Notification');

  static Future<bool> requestPermission() async {
    if (!supported) return false;
    try {
      if (web.Notification.permission == 'granted') return true;
      final r = await web.Notification.requestPermission().toDart;
      return r.toDart == 'granted';
    } catch (e) {
      debugPrint('Browser notification permission failed: $e');
      return false;
    }
  }

  static void show(int id, String title, String body) {
    if (!supported || web.Notification.permission != 'granted') return;
    try {
      web.Notification(title, web.NotificationOptions(body: body, tag: '$id', icon: 'icons/Icon-192.png'));
    } catch (e) {
      debugPrint('Could not show browser notification: $e');
    }
  }

  static void schedule(int id, DateTime when, String title, String body) {
    cancel(id);
    final delay = when.difference(DateTime.now());
    _timers[id] = Timer(delay.isNegative ? Duration.zero : delay, () {
      _timers.remove(id);
      show(id, title, body);
    });
  }

  static void cancel(int id) => _timers.remove(id)?.cancel();

  static int get pending => _timers.length;
}
