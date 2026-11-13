import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/logic/analysis.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/models/record.dart';
import '../../core/schema/record_types.dart';
import '../../core/services/vault_repository.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/file_actions.dart';
import '../widgets/record_form.dart';

String formatFieldValue(FieldSpec f, DossierRecord r, String Function(String? id) resolve) {
  final v = r.data[f.key];
  if (v == null || (v is String && v.isEmpty)) return '';
  switch (f.type) {
    case FieldType.date:
      return fmtDateStr(v.toString());
    case FieldType.money:
      final cur = r.str('currency').isEmpty ? '' : '${r.str('currency')} ';
      final n = v is num ? v : double.tryParse(v.toString());
      return n == null ? v.toString() : '$cur${NumberFormat.decimalPattern().format(n)}';
    case FieldType.percent:
      return '${v is num && v == v.roundToDouble() ? v.toInt() : v}%';
    case FieldType.toggle:
      return v == true ? 'Yes' : 'No';
    case FieldType.ref:
      return resolve(v.toString());
    default:
      return v.toString();
  }
}

String subtitleFor(RecordType t, DossierRecord r) {
  final parts = <String>[];
  for (final k in t.subtitleKeys) {
    final f = t.field(k);
    if (f == null) continue;
    final s = formatFieldValue(f, r, (_) => '');
    if (s.isNotEmpty && s != '—') parts.add(s);
  }
  final owed = outstandingBalance(r);
  if (owed != null) {
    parts.add('${money(owed, r.str('currency').isEmpty ? 'GHS' : r.str('currency'))} left to pay');
  }
  return parts.join('  ·  ');
}

/// Lists all records of one kind, with add/search.
class RecordListScreen extends StatefulWidget {
  const RecordListScreen({super.key, required this.kind});
  final String kind;
  @override
  State<RecordListScreen> createState() => _RecordListScreenState();
}

class _RecordListScreenState extends State<RecordListScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<VaultRepository>();
    final type = typeOf(widget.kind);
    var items = repo.ofKind(widget.kind);
    if (_q.isNotEmpty) {
      items = items.where((r) => r.data.values.any((v) => v.toString().toLowerCase().contains(_q))).toList();
    }
    return Scaffold(
      appBar: AppBar(title: Text(type.plural)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => RecordFormScreen.open(context, widget.kind),
        icon: const Icon(Icons.add),
        label: Text('Add'),
        backgroundColor: Brand.gold,
        foregroundColor: Brand.navy,
      ),
      body: repo.ofKind(widget.kind).isEmpty
          ? EmptyState(
              icon: type.icon,
              title: 'No ${type.plural.toLowerCase()} yet',
              message: type.description,
              action: FilledButton.icon(
                onPressed: () => RecordFormScreen.open(context, widget.kind),
                icon: const Icon(Icons.add),
                label: Text('Add ${type.label.toLowerCase()}'),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              children: [
                if (type.description != null) ...[InfoBanner(type.description!), const SizedBox(height: 12)],
                if (repo.ofKind(widget.kind).length > 6)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search'),
                      onChanged: (v) => setState(() => _q = v.toLowerCase()),
                    ),
                  ),
                for (final r in items)
                  NavTile(
                    icon: type.icon,
                    title: type.title(r),
                    subtitle: subtitleFor(type, r).isEmpty ? null : subtitleFor(type, r),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RecordDetailScreen(recordId: r.id))),
                  ),
              ],
            ),
    );
  }
}

/// Owner's live view of a record (edit, delete, linked documents).
class RecordDetailScreen extends StatelessWidget {
  const RecordDetailScreen({super.key, required this.recordId});
  final String recordId;

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<VaultRepository>();
    final r = repo.byId(recordId);
    if (r == null) {
      return Scaffold(appBar: AppBar(), body: const EmptyState(icon: Icons.delete_outline, title: 'This record was deleted'));
    }
    final type = typeOf(r.kind);
    return Scaffold(
      appBar: AppBar(
        title: Text(type.label),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => RecordFormScreen.open(context, r.kind, existing: r),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              if (await confirm(context, 'Delete ${type.label.toLowerCase()}?',
                  '"${type.title(r)}" will be permanently deleted${r.kind == Kinds.document ? ' with its encrypted files' : ''}.',
                  ok: 'Delete', destructive: true)) {
                if (!context.mounted) return;
                final ok = await runBusy(context, () async {
                  await repo.delete(r.id);
                  return true;
                }, label: 'Deleting…');
                if (ok == true && context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: RecordView(
        record: r,
        resolve: repo.titleOf,
        linkedDocuments: Kinds.assets.contains(r.kind) || r.kind == Kinds.insurance || r.kind == Kinds.liability
            ? repo.documentsFor(r.id)
            : null,
        ownerUid: repo.session.uid,
        onOpenRef: (id) => Navigator.push(context, MaterialPageRoute(builder: (_) => RecordDetailScreen(recordId: id))),
      ),
    );
  }
}

/// Read-only rendering of a record. Shared by the owner view and the
/// confidant's released view.
class RecordView extends StatefulWidget {
  const RecordView({
    super.key,
    required this.record,
    required this.resolve,
    required this.ownerUid,
    this.linkedDocuments,
    this.onOpenRef,
    this.onFileOpened,
  });

  final DossierRecord record;
  final String Function(String? id) resolve;
  final String ownerUid;
  final List<DossierRecord>? linkedDocuments;
  final void Function(String id)? onOpenRef;
  final void Function(Map<String, dynamic> file)? onFileOpened;

  @override
  State<RecordView> createState() => _RecordViewState();
}

class _RecordViewState extends State<RecordView> {
  final Set<String> _revealed = {};

  @override
  Widget build(BuildContext context) {
    final r = widget.record;
    final type = typeOf(r.kind);
    final theme = Theme.of(context);
    final files = VaultRepository.fileVersions(r);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Row(children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Brand.gold.withValues(alpha: 0.15),
            foregroundColor: Brand.gold,
            child: Icon(type.icon),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(type.title(r), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600))),
        ]),
        if (r.updatedAt != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text('Last updated ${fmtDate(r.updatedAt)}', style: theme.textTheme.bodySmall),
          ),
        const SizedBox(height: 16),
        if (isPayingInstallments(r)) ...[InstallmentCard(record: r), const SizedBox(height: 12)],
        if (r.kind == Kinds.legacyMessage) ...[
          InfoBanner('Delivery: ${deliverySummary(r)}', icon: CupertinoIcons.clock),
          const SizedBox(height: 12),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(children: [
              for (final f in type.fields)
                if (f.visibleWith(r.data) && formatFieldValue(f, r, widget.resolve).isNotEmpty) _row(f, r),
            ]),
          ),
        ),
        if (files.isNotEmpty) ...[
          const SectionHeader('Encrypted files'),
          for (final (i, f) in files.reversed.indexed)
            NavTile(
              icon: Icons.insert_drive_file_outlined,
              title: f['fileName'] as String? ?? 'File',
              subtitle: '${i == 0 ? 'Current version' : 'Previous version'} · ${fmtBytes(f['size'] as num? ?? 0)} · ${fmtDateStr(f['uploadedAt'] as String?)}',
              trailing: const Icon(Icons.lock_open_outlined),
              onTap: () => openDecryptedFile(context,
                  ownerUid: widget.ownerUid,
                  category: r.category,
                  fileMeta: f,
                  onOpened: () => widget.onFileOpened?.call(f)),
            ),
        ],
        if (widget.linkedDocuments != null) ...[
          const SectionHeader('Supporting documents'),
          if (widget.linkedDocuments!.isEmpty)
            const InfoBanner('No documents linked. Upload one in My Vault and choose this record as the related record.')
          else
            for (final d in widget.linkedDocuments!)
              NavTile(
                icon: Icons.description_outlined,
                title: d.str('title'),
                subtitle: d.str('docCategory'),
                onTap: widget.onOpenRef == null ? null : () => widget.onOpenRef!(d.id),
              ),
        ],
      ],
    );
  }

  Widget _row(FieldSpec f, DossierRecord r) {
    final value = formatFieldValue(f, r, widget.resolve);
    final masked = f.sensitive && !_revealed.contains(f.key);
    final isRef = f.type == FieldType.ref && widget.onOpenRef != null && r.str(f.key).isNotEmpty;
    return ListTile(
      dense: true,
      title: Text(f.label, style: Theme.of(context).textTheme.bodySmall),
      subtitle: Text(
        masked ? '••••••••  (tap to reveal)' : value,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      trailing: isRef ? const Icon(Icons.open_in_new, size: 18) : null,
      onTap: masked
          ? () => setState(() => _revealed.add(f.key))
          : isRef
              ? () => widget.onOpenRef!(r.str(f.key))
              : null,
    );
  }
}


/// Progress of an asset being paid off in installments.
class InstallmentCard extends StatelessWidget {
  const InstallmentCard({super.key, required this.record});
  final DossierRecord record;

  @override
  Widget build(BuildContext context) {
    final r = record;
    final g = GlassColors.of(context);
    final t = Theme.of(context).textTheme;
    final cur = r.str('currency').isEmpty ? 'GHS' : r.str('currency');
    final owed = outstandingBalance(r);
    final paid = r.num_('amountPaid');
    final frac = paidFraction(r);
    final next = r.date('nextPaymentDate');
    final inst = r.num_('installmentAmount');
    final freq = r.str('installmentFrequency');
    return Glass(
      radius: 26,
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const AmberOrb(icon: CupertinoIcons.creditcard, size: 40),
          const SizedBox(width: 12),
          Expanded(child: Text('Paying in installments', style: t.titleMedium)),
          if (frac != null) Text('${(frac * 100).round()}% paid', style: t.labelLarge?.copyWith(color: g.accentText)),
        ]),
        const SizedBox(height: 16),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Balance left', style: t.bodySmall?.copyWith(color: g.muted)),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(owed == null ? '—' : money(owed, cur),
                    style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
          if (paid != null)
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('Paid so far', style: t.bodySmall?.copyWith(color: g.muted)),
              Text(money(paid, cur), style: t.titleSmall),
            ]),
        ]),
        if (frac != null) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(children: [
              Container(height: 10, color: g.hairline),
              FractionallySizedBox(
                widthFactor: frac,
                child: Container(height: 10, decoration: const BoxDecoration(gradient: Brand.amberGradient)),
              ),
            ]),
          ),
        ],
        if (inst != null || next != null) ...[
          const SizedBox(height: 12),
          Text(
            [
              if (inst != null) '${money(inst, cur)}${freq.isEmpty || freq == 'Irregular' ? '' : ' every ${freq.toLowerCase()}'}',
              if (next != null) 'next due ${fmtDate(next)}',
            ].join(' · '),
            style: t.bodySmall?.copyWith(color: g.muted),
          ),
        ],
      ]),
    );
  }
}
