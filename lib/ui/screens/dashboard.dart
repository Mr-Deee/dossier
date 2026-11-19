import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/logic/analysis.dart';
import '../../core/schema/record_types.dart';
import '../../core/services/firebase_refs.dart';
import '../../core/services/session.dart';
import '../../core/services/succession_service.dart';
import '../../core/services/vault_repository.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/record_form.dart';
import 'documents.dart';
import 'intelligence.dart';
import 'legacy.dart';
import 'life_check_question.dart';
import 'notifications.dart';
import 'records.dart';
import 'succession.dart';

/// Bottom sheet to pick one of several record kinds, then open its form.
Future<void> pickKindAndAdd(BuildContext context, List<String> kinds, {String title = 'Add'}) async {
  final kind = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (c) => SafeArea(
      child: ListView(shrinkWrap: true, children: [
        Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 8), child: Text(title, style: Theme.of(c).textTheme.titleMedium)),
        for (final k in kinds)
          ListTile(
            leading: Icon(typeOf(k).icon, color: Brand.gold),
            title: Text(typeOf(k).label),
            onTap: () => Navigator.pop(c, k),
          ),
      ]),
    ),
  );
  if (kind != null && context.mounted) await RecordFormScreen.open(context, kind);
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.onNavigate});
  final void Function(int tab) onNavigate;

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<Session>();
    final repo = context.watch<VaultRepository>();
    final idx = RecordIndex(repo.all);
    final nw = netWorth(idx);
    final primary = nw[s.displayCurrency] ?? (nw.isEmpty ? CurrencyTotals() : nw.values.first);
    final primaryCur = nw.containsKey(s.displayCurrency) || nw.isEmpty ? s.displayCurrency : nw.keys.first;
    final rem = reminders(idx);
    final recent = [...repo.all.where((r) => r.kind != Kinds.allocation)]
      ..sort((a, b) => (b.updatedAt ?? DateTime(2000)).compareTo(a.updatedAt ?? DateTime(2000)));
    final theme = Theme.of(context);
    final g = GlassColors.of(context);
    final first = repo.displayName.trim().split(' ').first;
    void push(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 130),
          children: [
            // Header
            Row(children: [
              GestureDetector(
                onTap: () => shellScaffoldKey.currentState?.openDrawer(),
                child: Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: Brand.amberGradient,
                    border: Border.all(color: g.border, width: 2),
                    boxShadow: [BoxShadow(color: Brand.amber.withValues(alpha: 0.35), blurRadius: 16)],
                  ),
                  child: Text(first.isEmpty ? '·' : first[0].toUpperCase(),
                      style: const TextStyle(color: Brand.ink, fontWeight: FontWeight.w700, fontSize: 20)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(first.isEmpty ? 'Welcome' : first,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                  Text(_greeting(), style: theme.textTheme.bodySmall?.copyWith(color: g.muted)),
                ]),
              ),
              const NotificationBell(),
              const SizedBox(width: 10),
              GlassIconButton(icon: CupertinoIcons.lock, tooltip: 'Lock', onPressed: s.lock, badge: rem.isNotEmpty),
            ]),
            const SizedBox(height: 26),
            Text('Your life,\nin one place.', style: theme.textTheme.displaySmall?.copyWith(fontSize: 38)),
            const SizedBox(height: 6),
            Text(DateFormat.yMMMMEEEEd().format(DateTime.now()), style: theme.textTheme.bodyMedium?.copyWith(color: g.muted)),
            const SizedBox(height: 22),
            const LifeCheckQuestionBanner(),
            const _LifeCheckCard(),
            if (repo.undecryptable.isNotEmpty) ...[
              InfoBanner('${repo.undecryptable.length} record(s) could not be decrypted and are hidden.',
                  icon: CupertinoIcons.exclamationmark_triangle, color: Brand.danger),
              const SizedBox(height: 14),
            ],

            // Hero
            _NetWorthHero(
              value: money(primary.net, primaryCur),
              currencies: nw.length,
              assets: idx.ofKinds(Kinds.assets).length,
              documents: idx.ofKind(Kinds.document).length,
              onTap: () => onNavigate(2),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              child: Row(children: [
                Expanded(
                  child: StatTile(
                    label: 'Liabilities',
                    value: money(primary.liabilities, primaryCur),
                    icon: CupertinoIcons.doc_text,
                    onTap: () => push(const RecordListScreen(kind: Kinds.liability)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatTile(
                    label: 'Encrypted documents',
                    value: '${idx.ofKind(Kinds.document).length}',
                    icon: CupertinoIcons.lock_shield,
                    onTap: () => onNavigate(3),
                  ),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
              child: Text('Values are your own estimates, not verified valuations.',
                  style: theme.textTheme.bodySmall?.copyWith(color: g.muted)),
            ),

            // Readiness
            SectionHeader('Legacy readiness',
                trailing: GestureDetector(onTap: () => push(const IntelligenceScreen()), child: const Text('Details'))),
            StreamBuilder<List<Grant>>(
              stream: context.read<SuccessionService>().myGrants(),
              builder: (context, snap) {
                final score = readiness(idx, confidantGrants: snap.data?.length ?? 0);
                final todo = score.items.where((i) => !i.complete).take(3).toList();
                return Glass(
                  radius: 30,
                  onTap: () => push(const IntelligenceScreen()),
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                  child: Column(children: [
                    ArcGauge(value: score.score / 100, label: 'Readiness score', size: 210),
                    const SizedBox(height: 14),
                    if (todo.isEmpty)
                      Text('Everything is documented. Review it yearly.', style: theme.textTheme.bodyMedium)
                    else
                      for (final t in todo)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(color: Brand.amber, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(t.label, style: theme.textTheme.bodyMedium)),
                          ]),
                        ),
                  ]),
                );
              },
            ),

            // Quick actions
            const SectionHeader('Quick actions'),
            SizedBox(
              height: 148,
              child: ListView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                children: [
                  _ActionCard(
                    icon: CupertinoIcons.house_alt,
                    title: 'Add an asset',
                    subtitle: 'Property, accounts, policies',
                    featured: true,
                    onTap: () => pickKindAndAdd(context, [...Kinds.assets, Kinds.liability, Kinds.insurance],
                        title: 'What would you like to add?'),
                  ),
                  _ActionCard(
                    icon: CupertinoIcons.cloud_upload,
                    title: 'Upload',
                    subtitle: 'Encrypted document',
                    onTap: () => startDocumentUpload(context),
                  ),
                  _ActionCard(
                    icon: CupertinoIcons.pencil_outline,
                    title: 'Will draft',
                    subtitle: 'Guided builder',
                    onTap: () => push(const WillBuilderScreen()),
                  ),
                  _ActionCard(
                    icon: CupertinoIcons.shield_lefthalf_fill,
                    title: 'Confidant',
                    subtitle: 'Trusted person',
                    onTap: () => push(const SuccessionScreen()),
                  ),
                  _ActionCard(
                    icon: CupertinoIcons.envelope_open,
                    title: 'Legacy note',
                    subtitle: 'Message for later',
                    onTap: () => RecordFormScreen.open(context, Kinds.legacyMessage),
                  ),
                  _ActionCard(
                    icon: CupertinoIcons.rosette,
                    title: 'Achievement',
                    subtitle: 'Record a milestone',
                    onTap: () => RecordFormScreen.open(context, Kinds.achievement),
                  ),
                ],
              ),
            ),

            // Reminders
            const SectionHeader('Upcoming'),
            if (rem.isEmpty)
              const InfoBanner('Nothing expiring in the next 90 days. Add expiry dates to documents and policies to get reminders.')
            else
              for (final r in rem.take(5))
                NavTile(
                  icon: r.daysLeft(DateTime.now()) < 0 ? CupertinoIcons.exclamationmark_circle : CupertinoIcons.calendar,
                  title: r.label,
                  subtitle: r.daysLeft(DateTime.now()) < 0
                      ? 'Overdue since ${fmtDate(r.date)}'
                      : '${fmtDate(r.date)} · in ${r.daysLeft(DateTime.now())} days',
                  onTap: () => push(RecordDetailScreen(recordId: r.record.id)),
                ),

            // Recent
            const SectionHeader('Recent activity'),
            if (recent.isEmpty)
              const InfoBanner('Start by completing your personal profile or adding your first asset.')
            else
              for (final r in recent.take(5))
                NavTile(
                  icon: typeOf(r.kind).icon,
                  title: typeOf(r.kind).title(r),
                  subtitle: '${typeOf(r.kind).label} · updated ${fmtDate(r.updatedAt)}',
                  onTap: () => push(RecordDetailScreen(recordId: r.id)),
                ),
          ],
        ),
      ),
    );
  }
}

/// Ink-black card with a molten amber light source — the dashboard's hero.
class _NetWorthHero extends StatelessWidget {
  const _NetWorthHero({
    required this.value,
    required this.currencies,
    required this.assets,
    required this.documents,
    required this.onTap,
  });
  final String value;
  final int currencies;
  final int assets;
  final int documents;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      height: 210,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: Brand.ink,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 30, offset: const Offset(0, 16))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            child: Stack(children: [
              Positioned(
                right: -70,
                top: -80,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      Brand.amberGlow.withValues(alpha: 0.95),
                      Brand.amber.withValues(alpha: 0.6),
                      Brand.amberDeep.withValues(alpha: 0),
                    ], stops: const [0, 0.4, 1]),
                  ),
                ),
              ),
              Positioned(
                left: -60,
                bottom: -110,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      Brand.amberDeep.withValues(alpha: 0.35),
                      Brand.amberDeep.withValues(alpha: 0),
                    ]),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 16, 20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(CupertinoIcons.sparkles, size: 14, color: Brand.amber),
                        const SizedBox(width: 6),
                        Text('Estimated net worth${currencies > 1 ? ' · $currencies currencies' : ''}',
                            style: t.labelMedium?.copyWith(color: Colors.white.withValues(alpha: 0.85))),
                      ]),
                    ),
                    const Spacer(),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                      child: const Icon(CupertinoIcons.arrow_up_right, size: 18, color: Brand.ink),
                    ),
                  ]),
                  const Spacer(),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(value,
                        style: t.displaySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 40)),
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    _heroChip(context, '$assets assets'),
                    const SizedBox(width: 8),
                    _heroChip(context, '$documents documents'),
                  ]),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _heroChip(BuildContext context, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withValues(alpha: 0.08),
        ),
        child: Text(label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white.withValues(alpha: 0.7))),
      );
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.title, required this.subtitle, required this.onTap, this.featured = false});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final g = GlassColors.of(context);
    final body = Padding(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: featured ? Brand.ink.withValues(alpha: 0.9) : Brand.amber.withValues(alpha: 0.2),
          ),
          child: Icon(icon, size: 20, color: featured ? Brand.amber : g.accentText),
        ),
        const Spacer(),
        Text(title, style: t.titleSmall?.copyWith(fontSize: 15.5, color: featured ? Brand.ink : null)),
        const SizedBox(height: 2),
        Text(subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: t.bodySmall?.copyWith(color: featured ? Brand.ink.withValues(alpha: 0.65) : g.muted)),
      ]),
    );
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: SizedBox(
        width: 136,
        child: featured
            ? DecoratedBox(
                decoration: BoxDecoration(
                  gradient: Brand.amberGradient,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [BoxShadow(color: Brand.amber.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(borderRadius: BorderRadius.circular(26), onTap: onTap, child: body),
                ),
              )
            : Glass(radius: 26, onTap: onTap, child: body),
      ),
    );
  }
}

class _LifeCheckCard extends StatelessWidget {
  const _LifeCheckCard();
  @override
  Widget build(BuildContext context) {
    final s = context.watch<Session>();
    final lc = s.lifeCheck;
    if (lc['enabled'] != true) return const SizedBox.shrink();
    final due = tsToDate(lc['nextDue']);
    if (due == null) return const SizedBox.shrink();
    final days = due.difference(DateTime.now()).inDays;
    if (days > 7) return const SizedBox.shrink();
    final until = fmtUntil(due);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Glass(
        radius: 28,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Row(children: [
          const AmberOrb(icon: CupertinoIcons.heart_fill, size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Life Check', style: Theme.of(context).textTheme.titleSmall),
              Text(until == 'overdue' ? 'Overdue — let us know you\'re OK' : 'Due $until',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: GlassColors.of(context).muted)),
            ]),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(80, 46)),
            onPressed: () => runBusy(context, s.checkIn, success: 'Thanks — check-in recorded.'),
            child: const Text("I'm OK"),
          ),
        ]),
      ),
    );
  }
}
