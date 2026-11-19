import 'records.dart';
import '../widgets/record_form.dart';
import '../../core/logic/analysis.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/crypto/crypto_primitives.dart';
import '../../core/crypto/key_manager.dart';
import '../../core/models/record.dart';
import '../../core/schema/record_types.dart';
import '../../core/services/firebase_refs.dart';
import '../../core/services/session.dart';
import '../../core/services/succession_service.dart';
import '../../core/services/vault_repository.dart';
import '../theme.dart';
import '../widgets/common.dart';

const circumstanceLabels = {'death': 'Death', 'incapacity': 'Incapacity'};

class SuccessionScreen extends StatelessWidget {
  const SuccessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<VaultRepository>();
    final svc = context.read<SuccessionService>();
    final confidants = repo.ofKind(Kinds.confidant);
    return Scaffold(
      appBar: AppBar(title: const Text('My Succession')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConfidantEditor())),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Add confidant'),
        backgroundColor: Brand.gold,
        foregroundColor: Brand.navy,
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 96), children: [
        const InfoBanner(
          'Legacy Switch: confidants receive the keys to the categories you choose, sealed so only their app can open '
          'them. The server keeps everything hidden until a death or incapacity is verified by the verification team, '
          'after a notice period during which you can object. A missed Life Check alone never releases anything.',
          icon: Icons.shield_outlined,
        ),
        const SectionHeader('Life Check'),
        const _LifeCheckSettings(),
        const SectionHeader('Trusted confidants'),
        StreamBuilder<List<Grant>>(
          stream: svc.myGrants(),
          builder: (context, snap) {
            final grants = {for (final g in snap.data ?? <Grant>[]) g.data['confidantRecordId']: g};
            if (confidants.isEmpty) {
              return const InfoBanner('No confidants yet. Add a spouse, lawyer, executor or business partner.');
            }
            return Column(children: [
              for (final c in confidants)
                NavTile(
                  icon: Icons.shield_outlined,
                  title: c.str('name'),
                  subtitle: _grantSummary(grants[c.id]),
                  trailing: grants[c.id]?.released == true ? const Icon(Icons.lock_open, color: Brand.danger) : null,
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => ConfidantEditor(existing: c, grant: grants[c.id]))),
                ),
            ]);
          },
        ),
        SectionHeader(
          'Succession messages',
          trailing: GestureDetector(
            onTap: () => RecordFormScreen.open(context, Kinds.legacyMessage),
            child: const Text('Add'),
          ),
        ),
        _SuccessionMessages(messages: repo.ofKind(Kinds.legacyMessage), grants: svc.myGrants()),
        const SectionHeader('Access requests about me'),
        StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
          stream: svc.requestsAboutMe(),
          builder: (context, snap) {
            final reqs = snap.data ?? const [];
            if (reqs.isEmpty) return const InfoBanner('No one has requested access to your Dossier.');
            return Column(children: [for (final r in reqs) _RequestAboutMe(doc: r)]);
          },
        ),
        const SectionHeader('Transparency'),
        NavTile(
          icon: Icons.receipt_long_outlined,
          title: 'Legacy activity log',
          subtitle: 'Every grant, request, verification and release',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuditLogScreen())),
        ),
      ]),
    );
  }

  String _grantSummary(Grant? g) {
    if (g == null) return 'No access granted yet';
    final cats = g.categories.map((c) => Categories.labels[c]?.split(' (').first ?? c).join(', ');
    final when = g.triggers.map((t) => circumstanceLabels[t] ?? t).join(' or ');
    return g.released ? 'RELEASED (${g.releasedFor}) · $cats' : 'Sealed · $cats · on $when';
  }
}

/// Short intervals are for testing reminders; days are for real use.
const _lifeCheckOptions = [
  Duration(minutes: 5),
  Duration(hours: 1),
  Duration(hours: 3),
  Duration(hours: 24),
  Duration(days: 7),
  Duration(days: 14),
  Duration(days: 30),
  Duration(days: 60),
  Duration(days: 90),
  Duration(days: 180),
];

class _LifeCheckSettings extends StatelessWidget {
  const _LifeCheckSettings();
  @override
  Widget build(BuildContext context) {
    final s = context.watch<Session>();
    final lc = s.lifeCheck;
    final enabled = lc['enabled'] == true;
    final interval = s.lifeCheckInterval;
    final options = [..._lifeCheckOptions, if (!_lifeCheckOptions.contains(interval)) interval];
    final short = interval < const Duration(days: 1);
    final paused = tsToDate(lc['pausedUntil']);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Periodic Life Check'),
            subtitle:
                const Text('We remind you to confirm you are well. Missed check-ins alert you and your confidants '
                    'that someone should look in — they never prove death or release data.'),
            value: enabled,
            onChanged: (v) => runBusy(context, () => s.configureLifeCheck(enabled: v)),
          ),
          if (enabled) ...[
            Row(children: [
              const Text('Every'),
              const SizedBox(width: 12),
              DropdownButton<Duration>(
                value: interval,
                items: [
                  for (final d in options)
                    DropdownMenuItem(
                      value: d,
                      child: Text(d < const Duration(days: 1) ? '${fmtInterval(d)} (test)' : fmtInterval(d)),
                    )
                ],
                onChanged: (v) => runBusy(context, () => s.configureLifeCheck(interval: v)),
              ),
            ]),
            Builder(builder: (context) {
              final f = short ? fmtDateTime : fmtDate;
              final due = tsToDate(lc['nextDue']);
              return Text('Last check-in: ${f(tsToDate(lc['lastCheckIn']))} · '
                  'Next due: ${f(due)}${due == null ? '' : ' (${fmtUntil(due)})'}');
            }),
            if (short)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Test interval: your phone will remind you when the check-in is due. '
                  'Switch back to days before real use.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: GlassColors.of(context).muted),
                ),
              ),
            if (paused != null && paused.isAfter(DateTime.now())) Text('Paused until ${fmtDate(paused)}'),
            const SizedBox(height: 10),
            Wrap(spacing: 8, children: [
              FilledButton(
                  onPressed: () => runBusy(context, s.checkIn, success: 'Check-in recorded'),
                  child: const Text("I'm OK")),
              OutlinedButton(
                onPressed: () async {
                  if (paused != null && paused.isAfter(DateTime.now())) {
                    await runBusy(context, () => s.configureLifeCheck(clearPause: true));
                    return;
                  }
                  final d = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 14)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    helpText: 'Pause reminders until (e.g. travel)',
                  );
                  if (d != null && context.mounted) await runBusy(context, () => s.configureLifeCheck(pausedUntil: d));
                },
                child: Text(paused != null && paused.isAfter(DateTime.now()) ? 'Resume' : 'Temporary absence'),
              ),
            ]),
          ],
        ]),
      ),
    );
  }
}

class _RequestAboutMe extends StatelessWidget {
  const _RequestAboutMe({required this.doc});
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  @override
  Widget build(BuildContext context) {
    final d = doc.data();
    final repo = context.read<VaultRepository>();
    final confidant = repo.ofKind(Kinds.confidant);
    final status = d['status'] as String? ?? 'pending';
    final deadline = tsToDate(d['objectionDeadline']);
    final pending = status == 'pending';
    return Card(
      color: pending ? Brand.danger.withValues(alpha: 0.08) : null,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(pending ? Icons.warning_amber : Icons.history, color: pending ? Brand.danger : null),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                  '${circumstanceLabels[d['circumstance']] ?? d['circumstance']} access request — ${status.toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 6),
          FutureBuilder<String>(
            future: _requesterName(context, d['requesterUid'] as String, confidant),
            builder: (_, s) => Text('From: ${s.data ?? '…'}'),
          ),
          Text('Received ${fmtDate(tsToDate(d['createdAt']))}'),
          if (pending && deadline != null) Text('You can object until ${fmtDate(deadline)}.'),
          if (d['statement'] != null)
            Padding(padding: const EdgeInsets.only(top: 6), child: Text('"${d['statement']}"')),
          if (pending)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: Brand.danger, foregroundColor: Colors.white),
                onPressed: () async {
                  final reason = await _ask(context);
                  if (reason == null || !context.mounted) return;
                  await runBusy(context, () => context.read<SuccessionService>().objectTo(doc.id, reason),
                      success: 'Objection recorded. Nothing will be released.');
                },
                icon: const Icon(Icons.block),
                label: const Text('Object — I am fine'),
              ),
            ),
        ]),
      ),
    );
  }

  Future<String> _requesterName(BuildContext context, String requesterUid, List<DossierRecord> confidants) async {
    final svc = context.read<SuccessionService>();
    final grants = await svc.myGrants().first;
    for (final g in grants) {
      if (g.granteeUid == requesterUid) {
        final rec = confidants.where((c) => c.id == g.data['confidantRecordId']).firstOrNull;
        if (rec != null) return rec.str('name');
      }
    }
    return 'Someone you named as a confidant';
  }

  Future<String?> _ask(BuildContext context) {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Object to this request'),
        content: TextField(controller: c, decoration: const InputDecoration(labelText: 'Note (optional)'), maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(d, c.text.isEmpty ? 'Owner confirmed they are well' : c.text),
              child: const Text('Object')),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class ConfidantEditor extends StatefulWidget {
  const ConfidantEditor({super.key, this.existing, this.grant});
  final DossierRecord? existing;
  final Grant? grant;
  @override
  State<ConfidantEditor> createState() => _ConfidantEditorState();
}

class _ConfidantEditorState extends State<ConfidantEditor> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.str('name'));
  late final _email = TextEditingController(text: widget.existing?.str('email'));
  late final _phone = TextEditingController(text: widget.existing?.str('phone'));
  late final _resp = TextEditingController(text: widget.existing?.str('responsibilities'));
  late String? _relationship =
      widget.existing?.str('relationship').isEmpty ?? true ? null : widget.existing!.str('relationship');
  late final Set<String> _cats = {...?widget.grant?.categories};
  late final Set<String> _triggers = {...?widget.grant?.triggers};

  @override
  void initState() {
    super.initState();
    if (widget.grant == null && _triggers.isEmpty) _triggers.addAll(['death', 'incapacity']);
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _resp]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_cats.isNotEmpty && _triggers.isEmpty) {
      toast(context, 'Choose when access may be released.', error: true);
      return;
    }
    final repo = context.read<VaultRepository>();
    final svc = context.read<SuccessionService>();
    final rec = await runBusy(
        context,
        () => repo.save(
            Kinds.confidant,
            {
              'name': _name.text.trim(),
              'relationship': _relationship,
              'email': normaliseEmail(_email.text),
              'phone': _phone.text.trim(),
              'responsibilities': _resp.text.trim(),
            },
            id: widget.existing?.id),
        label: 'Encrypting…');
    if (rec == null || !mounted) return;

    if (_cats.isEmpty) {
      if (widget.grant != null) await runBusy(context, () => svc.revokeGrant(widget.grant!.granteeUid));
      if (mounted) Navigator.pop(context);
      return;
    }
    final entry = await runBusy(context, () => svc.lookup(_email.text), label: 'Looking up confidant…');
    if (!mounted) return;
    if (entry == null) {
      final email = normaliseEmail(_email.text);
      final invite = await confirm(
        context,
        'Not on The Dossier yet',
        '${_name.text} needs a Dossier account before their access can be sealed. Your confidant record is saved.\n\n'
            'Email them an invitation at $email? Their email and your name are sent to our server to deliver it — '
            'nothing from your vault is included. We\'ll notify you when they join.',
        ok: 'Email invitation',
      );
      if (invite && mounted) {
        await runBusy(context, () => svc.inviteConfidant(name: _name.text, email: email),
            label: 'Sending invitation…', success: 'Invitation sent to $email');
      }
      if (mounted) Navigator.pop(context);
      return;
    }
    final fp = await fingerprint(entry.publicKey);
    if (!mounted) return;
    final ok = await confirm(
      context,
      'Confirm ${_name.text}\'s key',
      'Ask ${_name.text} to open Settings → Security in their app and read you their key fingerprint. It must match:\n\n$fp\n\n'
          'If it does not match, cancel — someone may be impersonating them.',
      ok: 'It matches — seal keys',
    );
    if (!ok || !mounted) return;
    final sealed = await runBusy(context, () async {
      await svc.saveGrant(confidant: rec, entry: entry, categories: _cats.toList(), triggers: _triggers.toList());
      return true;
    }, label: 'Sealing keys to ${_name.text}…', success: 'Access granted (sealed until a verified release)');
    if (sealed == true && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.grant;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Add confidant' : 'Confidant'),
        actions: [
          if (widget.existing != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                if (!await confirm(context, 'Remove confidant?', 'Their sealed access will be revoked.',
                    ok: 'Remove', destructive: true)) {
                  return;
                }
                if (!context.mounted) return;
                final repo = context.read<VaultRepository>();
                final svc = context.read<SuccessionService>();
                await runBusy(context, () async {
                  if (g != null) await svc.revokeGrant(g.granteeUid);
                  await repo.delete(widget.existing!.id);
                });
                if (context.mounted) Navigator.pop(context);
              },
            ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          if (g?.released == true) ...[
            InfoBanner('Access was RELEASED for ${g!.releasedFor}. If you have regained capacity, re-seal it.',
                icon: Icons.lock_open, color: Brand.danger),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => runBusy(context, () => context.read<SuccessionService>().resealGrant(g.granteeUid),
                  success: 'Access sealed again'),
              child: const Text('Re-seal access'),
            ),
            const SizedBox(height: 16),
          ],
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Full name *'),
            validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _relationship,
            decoration: const InputDecoration(labelText: 'Relationship *'),
            items: [for (final r in relationships) DropdownMenuItem(value: r, child: Text(r))],
            onChanged: (v) => setState(() => _relationship = v),
            validator: (v) => v == null ? 'Required' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email of their Dossier account *'),
            validator: (v) =>
                RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch((v ?? '').trim()) ? null : 'Enter a valid email',
          ),
          const SizedBox(height: 14),
          TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone')),
          const SizedBox(height: 14),
          TextFormField(
              controller: _resp, maxLines: 3, decoration: const InputDecoration(labelText: 'Responsibilities')),
          const SectionHeader('What they can access after a verified release'),
          for (final c in Categories.all)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _cats.contains(c),
              title: Text(Categories.labels[c]!),
              onChanged: (v) => setState(() => v == true ? _cats.add(c) : _cats.remove(c)),
            ),
          const SectionHeader('Release only in case of'),
          for (final t in circumstanceLabels.entries)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _triggers.contains(t.key),
              title: Text(t.value),
              subtitle: Text(t.key == 'death'
                  ? 'Verified with a death certificate; 14-day objection period'
                  : 'Verified with a medical/court document; 7-day objection period; you can re-seal on recovery'),
              onChanged: (v) => setState(() => v == true ? _triggers.add(t.key) : _triggers.remove(t.key)),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
              onPressed: _save, icon: const Icon(Icons.lock_outline), label: const Text('Save & seal access')),
          const SizedBox(height: 8),
          Text(
            'Changing categories later re-seals keys. Note: once someone has been released a category key, '
            'revoking stops future reads but cannot undo what they already saw.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class AuditLogScreen extends StatelessWidget {
  const AuditLogScreen({super.key});

  static const _labels = {
    'record.create': 'Record created',
    'record.update': 'Record updated',
    'record.delete': 'Record deleted',
    'grant.save': 'Confidant access sealed',
    'grant.revoke': 'Confidant access revoked',
    'grant.reseal': 'Released access re-sealed',
    'request.created': 'Access request received',
    'request.objected': 'Objection recorded',
    'request.approved': 'Request verified & approved — access released',
    'request.rejected': 'Request rejected by verifier',
    'released.view': 'Confidant opened released records',
    'released.file': 'Confidant opened a released document',
    'lifecheck.missed': 'Life Check missed',
    'will.shared': 'Will draft shared',
  };

  @override
  Widget build(BuildContext context) {
    final s = context.read<Session>();
    return Scaffold(
      appBar: AppBar(title: const Text('Legacy activity log')),
      body: StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
        stream: context.read<SuccessionService>().auditLog(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final items = snap.data!;
          if (items.isEmpty) return const EmptyState(icon: Icons.receipt_long_outlined, title: 'No activity yet');
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final d = items[i].data();
              final actor = d['actor'] as String?;
              return ListTile(
                dense: true,
                title: Text(_labels[d['action']] ?? d['action'].toString()),
                subtitle: Text(
                    '${fmtDate(tsToDate(d['at']))} · ${actor == s.uid ? 'You' : actor == 'system' ? 'System' : 'Another user'}'),
              );
            },
          );
        },
      ),
    );
  }
}

/// Legacy messages with when each one will open for confidants.
class _SuccessionMessages extends StatelessWidget {
  const _SuccessionMessages({required this.messages, required this.grants});
  final List<DossierRecord> messages;
  final Stream<List<Grant>> grants;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return NavTile(
        icon: CupertinoIcons.envelope_badge,
        title: 'Write a message',
        subtitle: 'Choose when it opens: on release, a set time after, or on a date',
        onTap: () => RecordFormScreen.open(context, Kinds.legacyMessage),
      );
    }
    final sorted = [...messages]..sort((a, b) {
        final da = messageOpensAt(a, releasedAt: DateTime(2000)) ?? DateTime(1900);
        final db = messageOpensAt(b, releasedAt: DateTime(2000)) ?? DateTime(1900);
        return da.compareTo(db);
      });
    return StreamBuilder<List<Grant>>(
      stream: grants,
      builder: (context, snap) {
        final hasLegacyConfidant = (snap.data ?? const <Grant>[]).any((g) => g.categories.contains(Categories.legacy));
        return Column(children: [
          if (snap.hasData && !hasLegacyConfidant) ...[
            const InfoBanner(
              'No confidant has "My Legacy" access yet, so these messages cannot be delivered. '
              'Open a confidant above and tick My Legacy.',
              icon: CupertinoIcons.exclamationmark_triangle,
            ),
            const SizedBox(height: 10),
          ],
          for (final m in sorted)
            NavTile(
              icon: switch (m.str('deliveryMode')) {
                deliverOnDate => CupertinoIcons.calendar,
                deliverAfterDelay => CupertinoIcons.hourglass,
                _ => CupertinoIcons.bolt,
              },
              title: m.str('title'),
              subtitle: 'For ${m.str('recipient')} · ${deliverySummary(m)}',
              onTap: () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) => RecordDetailScreen(recordId: m.id))),
            ),
        ]);
      },
    );
  }
}
