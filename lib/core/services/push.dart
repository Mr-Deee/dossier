import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'firebase_refs.dart';

/// Where a tapped notification should take the user.
class NotificationRoute {
  const NotificationRoute(this.type, this.id);
  final String type;
  final String id;

  static NotificationRoute? parse(String? payload) {
    if (payload == null || !payload.contains('|')) return null;
    final i = payload.indexOf('|');
    return NotificationRoute(payload.substring(0, i), payload.substring(i + 1));
  }

  String get payload => '$type|$id';
}

/// Push notifications (Firebase Cloud Messaging): they arrive even when the
/// app is closed. Not used on web, where the in-app relay shows alerts while
/// the tab is open.
class Push {
  Push._();

  /// The notification the user tapped to open the app, until the app handles it.
  static final pendingRoute = ValueNotifier<NotificationRoute?>(null);

  static bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  static bool _listening = false;
  static StreamSubscription<String>? _tokenSub;

  static NotificationRoute? _fromMessage(RemoteMessage m) {
    final type = m.data['type'] as String?;
    if (type == null || type.isEmpty) return null;
    return NotificationRoute(type, (m.data['id'] as String?) ?? '');
  }

  /// Call once at startup: remembers which notification opened the app.
  static Future<void> listenForTaps() async {
    if (!supported || _listening) return;
    _listening = true;
    try {
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) pendingRoute.value = _fromMessage(initial);
      FirebaseMessaging.onMessageOpenedApp.listen((m) => pendingRoute.value = _fromMessage(m));
    } catch (e) {
      debugPrint('Push tap listener unavailable: $e');
    }
  }

  /// Registers this device so the server can reach [uid] when the app is closed.
  static Future<void> register(String uid) async {
    if (!supported) return;
    try {
      final m = FirebaseMessaging.instance;
      final settings = await m.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      Future<void> save(String token) => Refs.user(uid).collection('devices').doc(token).set({
            'token': token,
            'platform': defaultTargetPlatform.name,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      final token = await m.getToken();
      if (token != null) await save(token);
      await _tokenSub?.cancel();
      _tokenSub = m.onTokenRefresh.listen(save);
    } catch (e) {
      // iOS without the Push capability / APNs key, emulators without Play services…
      debugPrint('Push registration failed: $e');
    }
  }

  /// Signing out: stop pushes to this device for [uid].
  static Future<void> unregister(String uid) async {
    if (!supported) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await Refs.user(uid).collection('devices').doc(token).delete();
      await _tokenSub?.cancel();
    } catch (_) {}
  }
}
