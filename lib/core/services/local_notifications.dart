import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'push.dart';
import 'web_notifier.dart';

/// On-device notifications. Scheduled locally, so nothing about a message
/// (not even its title) is sent to any server or push service.
///
/// Notification text never includes message titles or contents: it can be
/// seen on a locked screen.
class LocalNotifications {
  LocalNotifications._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'succession_messages',
      'Succession messages',
      channelDescription: 'When a message someone left for you becomes readable',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
    macOS: DarwinNotificationDetails(),
  );

  static const _alertDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'dossier_alerts',
      'Dossier alerts',
      channelDescription: 'Access requests, releases and Life Check reminders',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
    macOS: DarwinNotificationDetails(),
  );

  static Future<void> init() async {
    if (!_supported || _ready) return;
    try {
      tzdata.initializeTimeZones();
      const darwin = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: darwin,
          macOS: darwin,
        ),
        onDidReceiveNotificationResponse: (r) {
          final route = NotificationRoute.parse(r.payload);
          if (route != null) Push.pendingRoute.value = route;
        },
      );
      // Push notifications from the server use this channel on Android.
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            'dossier_alerts',
            'Dossier alerts',
            description: 'Life Check, confidant and release alerts',
            importance: Importance.high,
          ));
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp == true) {
        final route = NotificationRoute.parse(launch!.notificationResponse?.payload);
        if (route != null) Push.pendingRoute.value = route;
      }
      _ready = true;
    } catch (e) {
      debugPrint('Notifications unavailable: $e');
    }
  }

  /// Asks the OS for permission. Returns false if refused or unsupported.
  static Future<bool> requestPermission() async {
    if (kIsWeb) return WebNotifier.requestPermission();
    await init();
    if (!_ready) return false;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) return await android.requestNotificationsPermission() ?? false;
      final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) return await ios.requestPermissions(alert: true, badge: true, sound: true) ?? false;
      final mac = _plugin.resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>();
      if (mac != null) return await mac.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    } catch (e) {
      debugPrint('Notification permission request failed: $e');
    }
    return false;
  }

  /// Stable 31-bit id for a string key (FNV-1a), so rescheduling the same
  /// message replaces its notification instead of duplicating it.
  static int idFor(String key) {
    var h = 0x811c9dc5;
    for (final c in key.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h & 0x7fffffff;
  }

  /// Notifies when a scheduled succession message becomes readable.
  /// Times in the past are ignored.
  static Future<void> scheduleMessageOpening({
    required String key,
    required String fromName,
    required DateTime opensAt,
  }) async {
    if (!opensAt.isAfter(DateTime.now())) return;
    if (kIsWeb) {
      WebNotifier.schedule(idFor(key), opensAt, 'A message is ready for you',
          '$fromName left you a message that can now be opened in The Dossier.');
      return;
    }
    await init();
    if (!_ready) return;
    try {
      await _plugin.zonedSchedule(
        id: idFor(key),
        scheduledDate: tz.TZDateTime.from(opensAt.toUtc(), tz.UTC),
        notificationDetails: _details,
        // Inexact keeps us clear of Android's exact-alarm permission; Android may
        // deliver it a few minutes late while the phone is idle.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: 'A message is ready for you',
        body: '$fromName left you a message that can now be opened in The Dossier.',
      );
    } catch (e) {
      debugPrint('Could not schedule notification: $e');
    }
  }

  /// Reminds the user to tap "I'm OK" when their Life Check falls due.
  static Future<void> scheduleLifeCheck(String uid, DateTime due) async {
    if (kIsWeb) {
      WebNotifier.schedule(idFor('lifecheck/$uid'), due, 'Life Check due',
          "Open The Dossier and tap \"I'm OK\" so your confidants know you're well.");
      return;
    }
    await init();
    if (!_ready) return;
    final when = due.isAfter(DateTime.now()) ? due : DateTime.now().add(const Duration(seconds: 5));
    try {
      await _plugin.zonedSchedule(
        id: idFor('lifecheck/$uid'),
        scheduledDate: tz.TZDateTime.from(when.toUtc(), tz.UTC),
        notificationDetails: _alertDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: 'Life Check due',
        body: "Open The Dossier and tap \"I'm OK\" so your confidants know you're well.",
      );
    } catch (e) {
      debugPrint('Could not schedule Life Check reminder: $e');
    }
  }

  static Future<void> cancelLifeCheck(String uid) async {
    if (kIsWeb) return WebNotifier.cancel(idFor('lifecheck/$uid'));
    await init();
    if (!_ready) return;
    try {
      await _plugin.cancel(id: idFor('lifecheck/$uid'));
    } catch (_) {}
  }

  /// Shows a notification immediately (server alerts, tests).
  static Future<void> showNow({required String key, required String title, required String body, String? payload}) async {
    if (kIsWeb) return WebNotifier.show(idFor(key), title, body);
    await init();
    if (!_ready) return;
    try {
      await _plugin.show(id: idFor(key), title: title, body: body, notificationDetails: _alertDetails, payload: payload);
    } catch (e) {
      debugPrint('Could not show notification: $e');
    }
  }

  /// Schedules a test notification [delay] from now.
  static Future<void> scheduleTest(Duration delay) async {
    if (kIsWeb) {
      WebNotifier.schedule(idFor('test-${delay.inSeconds}'), DateTime.now().add(delay), 'Test: a message is ready for you',
          'This is how a succession message notification will look.');
      return;
    }
    await init();
    if (!_ready) return;
    await _plugin.zonedSchedule(
      id: idFor('test-${delay.inSeconds}'),
      scheduledDate: tz.TZDateTime.from(DateTime.now().add(delay).toUtc(), tz.UTC),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: 'Test: a message is ready for you',
      body: 'This is how a succession message notification will look.',
    );
  }

  static Future<int> pendingCount() async {
    if (kIsWeb) return WebNotifier.pending;
    await init();
    if (!_ready) return 0;
    try {
      return (await _plugin.pendingNotificationRequests()).length;
    } catch (_) {
      return 0;
    }
  }
}
