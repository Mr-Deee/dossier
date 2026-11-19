import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/firebase_refs.dart';
import '../../core/services/local_notifications.dart';
import '../../core/services/push.dart';
import '../../core/services/session.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'life_check_question.dart';

Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> notificationsFor(String uid) =>
    Refs.notifications(uid).orderBy('createdAt', descending: true).limit(50).snapshots().map((s) => s.docs);

/// Mirrors alerts the server writes (access requests, releases, Life Check
/// reminders) as phone notifications while the app is running. Each alert is
/// shown once, even across restarts.
class ServerAlertRelay {
  ServerAlertRelay(this.uid);
  final String uid;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  static const _prefsKey = 'notified_alert_ids';

  Future<void> start() async {
    final prefs = await SharedPreferences.getInstance();
    final shown = (prefs.getStringList(_prefsKey) ?? const []).toSet();
    var asked = false;
    _sub = Refs.notifications(uid).where('read', isEqualTo: false).snapshots().listen((snap) async {
      for (final d in snap.docs) {
        if (shown.contains(d.id)) continue;
        final created = tsToDate(d.data()['createdAt']);
        // Skip stale alerts from long ago; they are still in the inbox.
        if (created != null && DateTime.now().difference(created).inDays > 3) {
          shown.add(d.id);
          continue;
        }
        if (!asked) {
          asked = true;
          await LocalNotifications.requestPermission();
        }
        shown.add(d.id);
        // In the background the server's push notification already shows it.
        final foreground = WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
        if (Push.supported && !foreground) continue;
        final type = d.data()['type'] as String?;
        await LocalNotifications.showNow(
          key: 'alert/${d.id}',
          title: d.data()['title'] as String? ?? 'The Dossier',
          body: d.data()['body'] as String? ?? '',
          payload: type == null ? null : NotificationRoute(type, d.data()['refId'] as String? ?? '').payload,
        );
      }
      final keep = shown.toList();
      await prefs.setStringList(_prefsKey, keep.length > 200 ? keep.sublist(keep.length - 200) : keep);
    }, onError: (Object e) => debugPrint('Alert relay: $e'));
  }

  void stop() => _sub?.cancel();
}

/// Bell with an unread-count badge; opens the inbox.
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = context.read<Session>().uid;
    return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      stream: notificationsFor(uid),
      builder: (context, snap) {
        final unread = (snap.data ?? const []).where((d) => d.data()['read'] != true).length;
        return GlassIconButton(
          icon: unread > 0 ? CupertinoIcons.bell_fill : CupertinoIcons.bell,
          tooltip: unread > 0 ? '$unread unread notifications' : 'Notifications',
          badge: unread > 0,
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
        );
      },
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<Session>().uid;
    final g = GlassColors.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
        stream: notificationsFor(uid),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final items = snap.data!;
          if (items.isEmpty) {
            return const EmptyState(
              icon: CupertinoIcons.bell,
              title: 'No notifications',
              message: 'Access requests, releases and Life Check reminders will appear here.',
            );
          }
          return ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 32), children: [
            for (final d in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Glass(
                  radius: 22,
                  padding: const EdgeInsets.all(14),
                  onTap: () {
                    if (d.data()['read'] != true) d.reference.update({'read': true});
                    final type = d.data()['type'] as String?;
                    if (type != null) {
                      openNotificationRoute(context, NotificationRoute(type, d.data()['refId'] as String? ?? ''));
                    }
                  },
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(top: 6, right: 12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: d.data()['read'] == true ? Colors.transparent : Brand.amber,
                      ),
                    ),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(d.data()['title'] as String? ?? '', style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 4),
                        Text(d.data()['body'] as String? ?? '', style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 6),
                        Text(fmtDate(tsToDate(d.data()['createdAt'])),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: g.muted)),
                      ]),
                    ),
                  ]),
                ),
              ),
          ]);
        },
      ),
    );
  }
}
