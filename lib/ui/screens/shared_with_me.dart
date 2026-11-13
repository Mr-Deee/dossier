import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/crypto/key_manager.dart';
import '../../core/logic/analysis.dart';
import '../../core/models/record.dart';
import '../../core/schema/record_types.dart';
import '../../core/services/firebase_refs.dart';
import '../../core/services/succession_service.dart';
import '../../core/services/vault_repository.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'records.dart';
import 'succession.dart' show circumstanceLabels;

/// The confidant's side of the Legacy Switch.
class SharedWithMeScreen extends StatelessWidget {
  const SharedWithMeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = context.read<SuccessionService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Shared with me')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const InfoBanner(
          'People who named you as a trusted confidant appear here. You cannot see their records unless a death or '
          'incapacity has been verified and the notice period has passed without objection.',
          icon: Icons.shield_outlined,
        ),
        const SectionHeader('Nominations'),
        StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
          stream: svc.nominationsForMe(),
          builder: (context, snap) {
            if (!snap.hasData) return const LinearProgressIndicator();
            if (snap.data!.isEmpty) return const InfoBanner('No one has named you as a confidant yet.');
            return Column(children: [for (final n in snap.data!) _NominationCard(nomination: n.data())]);
          },
        ),
        const SectionHeader('My access requests'),
        StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
          stream: svc.myRequests(),
          builder: (context, snap) {
            final reqs = snap.data ?? const [];
            if (reqs.isEmpty) return const InfoBanner('You have not made any requests.');
            return Column(children: [
              for (final r in reqs)
                NavTile(
                  icon: Icons.outgoing_mail,
                  title:
                      '${circumstanceLabels[r.data()['circumstance']] ?? ''} request — ${(r.data()['status'] as String).toUpperCase()}',
                  subtitle: [
                    'Submitted ${fmtDate(tsToDate(r.data()['createdAt']))}',
                    if (r.data()['objectionDeadline'] != null)
                      'Notice period ends ${fmtDate(tsToDate(r.data()['objectionDeadline']))}',
                    if (r.data()['decisionNote'] != null) 'Note: ${r.data()['decisionNote']}',
                  ].join('\n'),
                  trailing: r.data()['status'] == 'pending'
                      ? TextButton(
                          onPressed: () => runBusy(context, () => svc.cancelRequest(r.id)), child: const Text('Cancel'))
                      : const SizedBox.shrink(),
                ),
            ]);
          },
        ),
      ]),
    );
  }
}

class _NominationCard extends StatelessWidget {
  const _NominationCard({required this.nomination});
  final Map<String, dynamic> nomination;

  @override
  Widget build(BuildContext context) {
    final svc = context.read<SuccessionService>();
    final ownerUid = nomination['ownerUid'] as String;
    final triggers = List<String>.from(nomination['triggers'] as List? ?? const []);
    return FutureBuilder<String>(
      future: svc.openOwnerName(nomination),
      builder: (context, snap) {
        final name = snap.data ?? '…';
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: Theme.of(context).textTheme.titleMedium),
                Text(
                    'Named you as a confidant · release on ${triggers.map((t) => circumstanceLabels[t] ?? t).join(' or ')}'),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                RequestAccessScreen(ownerUid: ownerUid, ownerName: name, triggers: triggers))),
                    icon: const Icon(Icons.outgoing_mail),
                    label: const Text('Request access'),
                  ),
                  FilledButton.icon(
                    onPressed: () async {
                      final shared = await runBusy(context, () => svc.openShared(ownerUid, name),
                          label: 'Checking release and decrypting…');
                      if (shared != null && context.mounted) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => SharedDossierScreen(shared: shared)));
                      }
                    },
                    icon: const Icon(Icons.lock_open),
                    label: const Text('Open if released'),
                  ),
                ]),
              ]),
            ),
          ),
        );
      },
    );
  }
}

class RequestAccessScreen extends StatefulWidget {
  const RequestAccessScreen({super.key, required this.ownerUid, required this.ownerName, required this.triggers});
  final String ownerUid;
  final String ownerName;
  final List<String> triggers;
  @override
  State<RequestAccessScreen> createState() => _RequestAccessScreenState();
}

class _RequestAccessScreenState extends State<RequestAccessScreen> {
  late String _circumstance = widget.triggers.isNotEmpty ? widget.triggers.first : 'death';
  final _statement = TextEditingController();
  PlatformFile? _evidence;

  @override
  void dispose() {
    _statement.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_statement.text.trim().length < 10) {
      toast(context, 'Please describe the circumstances.', error: true);
      return;
    }
    if (_evidence == null) {
      toast(context, 'Attach supporting evidence (e.g. death certificate or medical report).', error: true);
      return;
    }
    final ok = await runBusy(context, () async {
      await context.read<SuccessionService>().requestAccess(
            ownerUid: widget.ownerUid,
            circumstance: _circumstance,
            statement: _statement.text.trim(),
            evidence: _evidence!.bytes,
            evidenceName: _evidence!.name,
          );
      return true;
    }, label: 'Submitting request…', success: 'Request submitted for verification');
    if (ok == true && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('Request access · ${widget.ownerName}')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          const InfoBanner(
            'What happens next: ① the owner is notified immediately and can object; ② the verification team reviews your '
            'evidence; ③ after the notice period with no objection, only the categories the owner chose are released to '
            'you. Every step is logged. Your evidence is visible to the verification team.',
          ),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: [
              for (final t in widget.triggers) ButtonSegment(value: t, label: Text(circumstanceLabels[t] ?? t)),
            ],
            selected: {_circumstance},
            onSelectionChanged: (s) => setState(() => _circumstance = s.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _statement,
            maxLines: 5,
            decoration:
                const InputDecoration(labelText: 'Statement', hintText: 'What happened, when, and your relationship'),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              final r = await FilePicker.platform
                  .pickFiles(withData: true, type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png']);
              if (r != null) setState(() => _evidence = r.files.single);
            },
            icon: const Icon(Icons.attach_file),
            label: Text(_evidence?.name ?? 'Attach evidence (PDF/photo)'),
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: _submit, child: const Text('Submit for verification')),
        ]),
      );
}

// ---------------------------------------------------------------------------

class SharedDossierScreen extends StatelessWidget {
  const SharedDossierScreen({super.key, required this.shared});
  final SharedDossier shared;

  @override
  Widget build(BuildContext context) {
    final isEstate = shared.grant.releasedFor == 'death';
    final byCat = <String, List<DossierRecord>>{};
    for (final r in shared.records.where((r) => r.kind != Kinds.allocation)) {
      byCat.putIfAbsent(r.category, () => []).add(r);
    }
    return DefaultTabController(
      length: isEstate ? 2 : 1,
      child: Scaffold(
        appBar: AppBar(
          title: Text(shared.ownerName),
          bottom: TabBar(tabs: [
            if (isEstate) const Tab(text: 'Estate dashboard'),
            const Tab(text: 'Released records'),
          ]),
        ),
        body: TabBarView(children: [
          if (isEstate) _EstateDashboard(shared: shared),
          ListView(padding: const EdgeInsets.all(16), children: [
            InfoBanner(
              'Read-only. Released for ${shared.grant.releasedFor}. Your access is logged in ${shared.ownerName}\'s activity log.',
              icon: Icons.visibility_outlined,
            ),
            for (final cat in Categories.all)
              if (byCat[cat] != null) ...[
                SectionHeader(Categories.labels[cat]!),
                for (final r in byCat[cat]!)
                  NavTile(
                    icon: _sealedUntil(shared, r) != null ? CupertinoIcons.lock_fill : typeOf(r.kind).icon,
                    title: typeOf(r.kind).title(r),
                    subtitle: _sealedUntil(shared, r) != null
                        ? '${typeOf(r.kind).label} · opens ${fmtDate(_sealedUntil(shared, r))}'
                        : typeOf(r.kind).label,
                    onTap: () => openSharedRecord(context, shared, r),
                  ),
              ],
            for (final cat in Categories.all.where((c) => !shared.grant.categories.contains(c)))
              ListTile(
                dense: true,
                leading: const Icon(Icons.lock_outline, size: 18),
                title: Text('${Categories.labels[cat]} — not shared with you'),
              ),
          ]),
        ]),
      ),
    );
  }
}

/// A legacy message the owner scheduled for later: when it opens, or null if
/// it can be read now.
DateTime? _sealedUntil(SharedDossier shared, DossierRecord r) {
  if (r.kind != Kinds.legacyMessage) return null;
  final opens = messageOpensAt(r, releasedAt: tsToDate(shared.grant.data['releasedAt']));
  return opens != null && opens.isAfter(DateTime.now()) ? opens : null;
}

void openSharedRecord(BuildContext context, SharedDossier shared, DossierRecord r) {
  final sealed = _sealedUntil(shared, r);
  if (sealed != null) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => _SealedMessageScreen(record: r, opensAt: sealed)));
    return;
  }
  final repo = context.read<VaultRepository>();
  String resolve(String? id) {
    final x = shared.byId(id);
    return x == null ? '(not shared)' : typeOf(x.kind).title(x);
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(typeOf(r.kind).label)),
        body: RecordView(
          record: r,
          resolve: resolve,
          ownerUid: shared.ownerUid,
          linkedDocuments: Kinds.assets.contains(r.kind)
              ? shared.ofKind(Kinds.document).where((d) => d.str('relatedRecord') == r.id).toList()
              : null,
          onOpenRef: (id) {
            final x = shared.byId(id);
            if (x != null) openSharedRecord(context, shared, x);
          },
          onFileOpened: (_) => repo.logAudit('released.file', target: r.id, ownerUid: shared.ownerUid),
        ),
      ),
    ),
  );
}

class _EstateDashboard extends StatelessWidget {
  const _EstateDashboard({required this.shared});
  final SharedDossier shared;

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<VaultRepository>();
    final progress = repo.ofKind(Kinds.estateProgress).where((p) => p.str('ownerUid') == shared.ownerUid).firstOrNull;
    final done = progress?.list('done').toSet() ?? <String>{};
    final idx = RecordIndex(shared.records);
    final cats = shared.grant.categories;

    Future<void> toggle(String key, bool v) async {
      final next = {...done};
      v ? next.add(key) : next.remove(key);
      await repo.save(
          Kinds.estateProgress, {'ownerUid': shared.ownerUid, 'ownerName': shared.ownerName, 'done': next.toList()},
          id: progress?.id);
    }

    final wills = idx.ofKind(Kinds.willVersion)
      ..sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
    final signed = wills.where((w) => w.str('status') == 'Signed and witnessed').toList();
    final nw = netWorth(idx);

    final tasks = <(String key, String title, String detail, List<DossierRecord> recs, bool available)>[
      (
        'will',
        'Locate the latest will',
        signed.isNotEmpty
            ? 'Signed version: ${signed.first.str('label')}${signed.first.has('storedAt') ? ' — original kept at ${signed.first.str('storedAt')}' : ''}'
            : wills.isEmpty
                ? 'No will draft recorded.'
                : 'Only unsigned drafts recorded — they are not valid wills.',
        signed.isNotEmpty ? signed : wills.take(1).toList(),
        cats.contains(Categories.legacy),
      ),
      (
        'inventory',
        'Review the documented estate inventory',
        nw.entries
            .map((e) =>
                '${e.key}: assets ${money(e.value.assets, e.key)}, liabilities ${money(e.value.liabilities, e.key)}')
            .join('\n'),
        idx.ofKinds(Kinds.assets),
        cats.contains(Categories.wealth),
      ),
      (
        'banks',
        'Identify financial institutions',
        idx.ofKind(Kinds.financialAccount).map((a) => a.str('institution')).toSet().join(', '),
        idx.ofKind(Kinds.financialAccount),
        cats.contains(Categories.wealth),
      ),
      (
        'insurance',
        'Locate insurance policies',
        '${idx.ofKind(Kinds.insurance).length} policies',
        idx.ofKind(Kinds.insurance),
        cats.contains(Categories.wealth)
      ),
      (
        'liabilities',
        'Identify outstanding liabilities',
        '${idx.ofKind(Kinds.liability).length} liabilities',
        idx.ofKind(Kinds.liability),
        cats.contains(Categories.wealth)
      ),
      (
        'legal',
        'Contact executors & legal representatives',
        idx.ofKind(Kinds.executor).map((e) => '${e.str('name')} (${e.str('role')})').join(', '),
        idx.ofKind(Kinds.executor),
        cats.contains(Categories.legacy)
      ),
      (
        'business',
        'Identify business interests',
        '${idx.ofKind(Kinds.business).length} businesses',
        idx.ofKind(Kinds.business),
        cats.contains(Categories.wealth)
      ),
      (
        'wishes',
        'Review recorded wishes & messages',
        '${idx.ofKinds([Kinds.wish, Kinds.legacyMessage]).length} items',
        idx.ofKinds([Kinds.wish, Kinds.legacyMessage]),
        cats.contains(Categories.legacy)
      ),
      (
        'probate',
        'Apply for probate / letters of administration',
        'Through the High Court Probate Registry, with your lawyer.',
        const [],
        true
      ),
    ];
    final completed = tasks.where((t) => done.contains(t.$1)).length;

    return ListView(padding: const EdgeInsets.all(16), children: [
      const InfoBanner(
        'The Dossier organises information to help you coordinate. It does not replace lawyers, the courts, '
        'or financial institutions, and does not by itself give you legal authority to act.',
        icon: Icons.gavel_outlined,
      ),
      const SizedBox(height: 12),
      LinearProgressIndicator(value: completed / tasks.length, minHeight: 6, color: Brand.gold),
      Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text('$completed of ${tasks.length} tasks complete')),
      for (final t in tasks)
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            leading: Checkbox(value: done.contains(t.$1), onChanged: (v) => toggle(t.$1, v ?? false)),
            title: Text(t.$2),
            subtitle: t.$5 ? null : const Text('Not shared with you'),
            children: [
              if (t.$3.isNotEmpty) Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 8), child: Text(t.$3)),
              for (final r in t.$4)
                ListTile(
                  dense: true,
                  leading: Icon(typeOf(r.kind).icon, size: 18),
                  title: Text(typeOf(r.kind).title(r)),
                  onTap: () => openSharedRecord(context, shared, r),
                ),
            ],
          ),
        ),
    ]);
  }
}

class _SealedMessageScreen extends StatelessWidget {
  const _SealedMessageScreen({required this.record, required this.opensAt});
  final DossierRecord record;
  final DateTime opensAt;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final g = GlassColors.of(context);
    final days = opensAt.difference(DateTime.now()).inDays;
    final note = record.str('releaseNote');
    return Scaffold(
      appBar: AppBar(title: const Text('Legacy message')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const AmberOrb(icon: CupertinoIcons.envelope_fill, size: 104),
            const SizedBox(height: 28),
            Text(record.str('title'), textAlign: TextAlign.center, style: t.headlineMedium),
            const SizedBox(height: 6),
            Text('For ${record.str('recipient')}', style: t.bodyLarge?.copyWith(color: g.muted)),
            const SizedBox(height: 24),
            Glass(
              radius: 26,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: Column(children: [
                Text(days <= 0 ? 'Opens today' : 'Opens in $days ${days == 1 ? 'day' : 'days'}',
                    style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(DateFormat.yMMMMd().format(opensAt), style: t.bodyMedium?.copyWith(color: g.accentText)),
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text('"$note"',
                      textAlign: TextAlign.center, style: t.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
                ],
              ]),
            ),
            const SizedBox(height: 18),
            Text(
                'The author chose to have this message opened later. '
                'Come back on that day to read it.',
                textAlign: TextAlign.center,
                style: t.bodySmall?.copyWith(color: g.muted)),
          ]),
        ),
      ),
    );
  }
}
