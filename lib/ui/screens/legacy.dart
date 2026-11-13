import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/logic/analysis.dart';
import '../../core/logic/will_draft.dart';
import '../../core/models/record.dart';
import '../../core/schema/record_types.dart';
import '../../core/services/vault_repository.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/record_form.dart';
import 'life.dart';
import 'records.dart';

class LegacyScreen extends StatelessWidget {
  const LegacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<VaultRepository>();
    final issues = willHealthCheck(RecordIndex(repo.all));
    final critical = issues.where((i) => i.severity == Severity.critical).length;
    int n(String k) => repo.ofKind(k).length;
    void push(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w));
    return Scaffold(
      appBar: AppBar(leading: const MenuButton(), leadingWidth: 68, toolbarHeight: 72, title: const Text('My Legacy')),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 130), children: [
        const InfoBanner(
          'The Dossier helps you prepare and organise. A generated draft is not a valid will until reviewed by a lawyer '
          'and signed in front of two witnesses as required by the Wills Act, 1971 (Act 360).',
          icon: Icons.gavel_outlined,
        ),
        const SectionHeader('Will builder'),
        NavTile(
          icon: Icons.pie_chart_outline,
          title: 'Allocate assets to beneficiaries',
          subtitle: '${n(Kinds.allocation)} allocations across ${n(Kinds.beneficiary)} beneficiaries',
          onTap: () => push(const WillBuilderScreen()),
        ),
        NavTile(
          icon: Icons.health_and_safety_outlined,
          title: 'Will health check',
          subtitle: issues.isEmpty ? 'No issues found' : '${issues.length} item(s) · $critical critical',
          trailing: critical > 0 ? const Icon(Icons.error_outline, color: Brand.danger) : null,
          onTap: () => push(const WillHealthScreen()),
        ),
        NavTile(
          icon: Icons.history_edu_outlined,
          title: 'Will drafts & versions',
          subtitle: '${n(Kinds.willVersion)} version(s)',
          onTap: () => push(const WillDraftsScreen()),
        ),
        const SectionHeader('People & wishes'),
        for (final k in [Kinds.beneficiary, Kinds.executor, Kinds.wish, Kinds.legacyMessage])
          NavTile(icon: typeOf(k).icon, title: typeOf(k).plural, subtitle: '${n(k)} recorded', onTap: () => openKind(context, k)),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------

class WillBuilderScreen extends StatelessWidget {
  const WillBuilderScreen({super.key});

  Future<void> _generate(BuildContext context) async {
    final repo = context.read<VaultRepository>();
    final idx = RecordIndex(repo.all);
    final critical = willHealthCheck(idx).where((i) => i.severity == Severity.critical).toList();
    if (critical.isNotEmpty) {
      final go = await confirm(context, 'Gaps found',
          '${critical.map((c) => '• ${c.message}').join('\n')}\n\nGenerate a draft anyway?', ok: 'Generate');
      if (!go || !context.mounted) return;
    }
    final version = repo.ofKind(Kinds.willVersion).length + 1;
    for (final old in repo.ofKind(Kinds.willVersion).where((v) => v.str('status') == 'Draft')) {
      await repo.save(Kinds.willVersion, {...old.data, 'status': 'Superseded'}, id: old.id);
    }
    final rec = await runBusy(context, () => repo.save(Kinds.willVersion, {
          'label': 'Draft v$version',
          'status': 'Draft',
          'createdOn': DateFormat('yyyy-MM-dd').format(DateTime.now()),
          'text': buildWillDraft(idx),
        }), label: 'Generating and encrypting draft…');
    if (rec != null && context.mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => WillDraftView(recordId: rec.id)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<VaultRepository>();
    final assets = repo.ofKinds(Kinds.assets);
    final bens = repo.ofKind(Kinds.beneficiary);
    final allocs = repo.ofKind(Kinds.allocation);
    final executors = repo.ofKind(Kinds.executor);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Will builder')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: () => _generate(context),
            icon: const Icon(Icons.description_outlined),
            label: const Text('Generate will draft'),
          ),
        ),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
        const SectionHeader('1 · Beneficiaries', padding: EdgeInsets.fromLTRB(4, 8, 4, 8)),
        if (bens.isEmpty) const InfoBanner('Add the people or organisations who should inherit.'),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final b in bens)
            InputChip(
              avatar: const Icon(Icons.person_outline, size: 18),
              label: Text(b.str('name')),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RecordDetailScreen(recordId: b.id))),
            ),
          ActionChip(
            avatar: const Icon(Icons.add, size: 18),
            label: const Text('Beneficiary'),
            onPressed: () => RecordFormScreen.open(context, Kinds.beneficiary),
          ),
        ]),
        const SectionHeader('2 · Executor'),
        if (executors.isEmpty)
          NavTile(
            icon: Icons.gavel_outlined,
            title: 'Nominate an executor',
            onTap: () => RecordFormScreen.open(context, Kinds.executor, initial: {'role': 'Primary executor'}),
          )
        else
          for (final e in executors)
            NavTile(
              icon: Icons.gavel_outlined,
              title: e.str('name'),
              subtitle: e.str('role'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RecordDetailScreen(recordId: e.id))),
            ),
        const SectionHeader('3 · Allocate each asset'),
        if (assets.isEmpty) const InfoBanner('Document your assets in My Wealth first — they are imported here automatically.'),
        for (final a in assets) _assetCard(context, a, allocs.where((x) => x.str('assetId') == a.id).toList(), repo, theme, bens.isEmpty),
      ]),
    );
  }

  Widget _assetCard(BuildContext context, DossierRecord a, List<DossierRecord> mine, VaultRepository repo, ThemeData theme, bool noBens) {
    final total = mine.fold<double>(0, (s, x) => s + (x.num_('percent') ?? 0));
    final over = total > 100.0001;
    final color = over ? Brand.danger : (total >= 99.9999 ? Brand.ok : Brand.gold);
    final t = typeOf(a.kind);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(t.icon, color: Brand.gold, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(t.title(a), style: theme.textTheme.titleSmall)),
              Text('${total.toStringAsFixed(total % 1 == 0 ? 0 : 1)}%',
                  style: theme.textTheme.titleSmall?.copyWith(color: color, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (total / 100).clamp(0, 1).toDouble(),
                minHeight: 5,
                color: color,
                backgroundColor: color.withValues(alpha: 0.12),
              ),
            ),
            if (over) Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Allocations exceed 100%', style: TextStyle(color: Brand.danger, fontSize: 12)),
            ),
            for (final x in mine)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(repo.titleOf(x.str('beneficiaryId'))),
                subtitle: Text([
                  if (x.has('condition')) x.str('condition'),
                  if (x.has('alternateId')) 'Alternative: ${repo.titleOf(x.str('alternateId'))}',
                ].join(' · ')),
                trailing: Text('${(x.num_('percent') ?? 0).toStringAsFixed((x.num_('percent') ?? 0) % 1 == 0 ? 0 : 1)}%'),
                onTap: () => RecordFormScreen.open(context, Kinds.allocation, existing: x),
              ),
            Row(children: [
              TextButton.icon(
                onPressed: noBens
                    ? () => toast(context, 'Add a beneficiary first.')
                    : () => RecordFormScreen.open(context, Kinds.allocation,
                        initial: {'assetId': a.id, if (total < 100) 'percent': 100 - total}),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Allocate'),
              ),
              if (mine.isNotEmpty)
                TextButton(
                  onPressed: () async {
                    if (await confirm(context, 'Clear allocations?', 'Remove all allocations for "${t.title(a)}"?',
                        ok: 'Clear', destructive: true)) {
                      for (final x in mine) {
                        await repo.delete(x.id);
                      }
                    }
                  },
                  child: const Text('Clear'),
                ),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class WillHealthScreen extends StatelessWidget {
  const WillHealthScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final repo = context.watch<VaultRepository>();
    final issues = willHealthCheck(RecordIndex(repo.all));
    return Scaffold(
      appBar: AppBar(title: const Text('Will health check')),
      body: issues.isEmpty
          ? const EmptyState(icon: Icons.verified_outlined, title: 'No issues found', message: 'Review again whenever your circumstances change.')
          : ListView(padding: const EdgeInsets.all(16), children: [
              for (final i in issues)
                NavTile(
                  icon: switch (i.severity) {
                    Severity.critical => Icons.error_outline,
                    Severity.warning => Icons.warning_amber_outlined,
                    Severity.info => Icons.info_outline,
                  },
                  title: i.message,
                  subtitle: i.severity.name.toUpperCase(),
                  trailing: i.recordId == null || repo.byId(i.recordId) == null ? const SizedBox.shrink() : null,
                  onTap: i.recordId == null || repo.byId(i.recordId) == null
                      ? null
                      : () => Navigator.push(context, MaterialPageRoute(builder: (_) => RecordDetailScreen(recordId: i.recordId!))),
                ),
            ]),
    );
  }
}

class WillDraftsScreen extends StatelessWidget {
  const WillDraftsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final repo = context.watch<VaultRepository>();
    final versions = repo.ofKind(Kinds.willVersion)
      ..sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
    return Scaffold(
      appBar: AppBar(title: const Text('Will drafts & versions')),
      body: versions.isEmpty
          ? EmptyState(
              icon: Icons.history_edu_outlined,
              title: 'No drafts yet',
              action: FilledButton(
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WillBuilderScreen())),
                child: const Text('Open will builder'),
              ),
            )
          : ListView(padding: const EdgeInsets.all(16), children: [
              for (final v in versions)
                NavTile(
                  icon: v.str('status') == 'Signed and witnessed' ? Icons.verified_outlined : Icons.history_edu_outlined,
                  title: v.str('label'),
                  subtitle: '${v.str('status')} · ${fmtDateStr(v.str('createdOn'))}',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WillDraftView(recordId: v.id))),
                ),
            ]),
    );
  }
}

class WillDraftView extends StatelessWidget {
  const WillDraftView({super.key, required this.recordId});
  final String recordId;
  @override
  Widget build(BuildContext context) {
    final repo = context.watch<VaultRepository>();
    final v = repo.byId(recordId);
    if (v == null) return Scaffold(appBar: AppBar(), body: const EmptyState(icon: Icons.delete_outline, title: 'Draft deleted'));
    return Scaffold(
      appBar: AppBar(
        title: Text(v.str('label')),
        actions: [
          IconButton(
            tooltip: 'Status & execution details',
            icon: const Icon(Icons.edit_note),
            onPressed: () => RecordFormScreen.open(context, Kinds.willVersion, existing: v),
          ),
          IconButton(
            tooltip: 'Share with your lawyer',
            icon: const Icon(Icons.ios_share),
            onPressed: () async {
              if (await confirm(context, 'Share decrypted draft?',
                  'The draft will leave The Dossier as plain text. Share only with your lawyer through a channel you trust.',
                  ok: 'Share')) {
                await Share.share(v.str('text'), subject: '${v.str('label')} — will draft for legal review');
                await repo.logAudit('will.shared', target: v.id);
              }
            },
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.flag_outlined, color: Brand.gold),
            title: Text(v.str('status')),
            subtitle: Text([
              'Created ${fmtDateStr(v.str('createdOn'))}',
              if (v.has('reviewer')) 'Reviewer: ${v.str('reviewer')}',
              if (v.has('storedAt')) 'Original kept at: ${v.str('storedAt')}',
            ].join('\n')),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SelectableText(v.str('text'), style: const TextStyle(fontFamily: 'serif', height: 1.5)),
          ),
        ),
      ]),
    );
  }
}
