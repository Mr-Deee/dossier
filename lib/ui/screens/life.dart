import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/record.dart';
import '../../core/schema/record_types.dart';
import '../../core/services/vault_repository.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/record_form.dart';
import 'records.dart';

void openKind(BuildContext context, String kind) {
  final repo = context.read<VaultRepository>();
  final t = typeOf(kind);
  if (t.singleton) {
    final existing = repo.single(kind);
    if (existing == null) {
      RecordFormScreen.open(context, kind);
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => RecordDetailScreen(recordId: existing.id)));
    }
    return;
  }
  Navigator.push(context, MaterialPageRoute(builder: (_) => RecordListScreen(kind: kind)));
}

class LifeScreen extends StatelessWidget {
  const LifeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<VaultRepository>();
    final profile = repo.single(Kinds.profile);
    int n(String k) => repo.ofKind(k).length;
    return Scaffold(
      appBar: AppBar(leading: const MenuButton(), leadingWidth: 68, toolbarHeight: 72, title: const Text('My Life')),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 130), children: [
        NavTile(
          icon: Icons.badge_outlined,
          title: profile == null ? 'Create your personal profile' : typeOf(Kinds.profile).title(profile),
          subtitle: profile == null ? 'Identity, contact and biography' : 'Personal profile',
          onTap: () => openKind(context, Kinds.profile),
        ),
        const SectionHeader('Your story'),
        NavTile(
          icon: Icons.timeline,
          title: 'Life timeline',
          subtitle: 'Your milestones in order',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TimelineScreen())),
        ),
        NavTile(
          icon: Icons.military_tech_outlined,
          title: 'Life scorecard',
          subtitle: 'Your documented achievements at a glance',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LifeScorecardScreen())),
        ),
        const SectionHeader('Records'),
        for (final k in [Kinds.education, Kinds.career, Kinds.achievement, Kinds.lifeEvent, Kinds.value])
          NavTile(
            icon: typeOf(k).icon,
            title: typeOf(k).plural,
            subtitle: '${n(k)} recorded',
            onTap: () => openKind(context, k),
          ),
      ]),
    );
  }
}

class _TimelineEntry {
  _TimelineEntry(this.date, this.title, this.subtitle, this.record);
  final DateTime date;
  final String title;
  final String subtitle;
  final DossierRecord record;
}

class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<VaultRepository>();
    final entries = <_TimelineEntry>[];
    final p = repo.single(Kinds.profile);
    if (p?.date('dateOfBirth') != null) {
      entries.add(_TimelineEntry(p!.date('dateOfBirth')!, 'Born', p.str('placeOfBirth'), p));
    }
    for (final r in repo.ofKind(Kinds.lifeEvent)) {
      if (r.date('date') != null) entries.add(_TimelineEntry(r.date('date')!, r.str('title'), r.str('type'), r));
    }
    for (final r in repo.ofKind(Kinds.education)) {
      final d = r.date('endDate') ?? r.date('startDate');
      if (d != null) entries.add(_TimelineEntry(d, r.str('qualification'), r.str('institution'), r));
    }
    for (final r in repo.ofKind(Kinds.career)) {
      if (r.date('startDate') != null) {
        entries.add(_TimelineEntry(r.date('startDate')!, 'Joined ${r.str('organisation')}', r.str('position'), r));
      }
    }
    for (final r in repo.ofKind(Kinds.achievement)) {
      if (r.date('date') != null) entries.add(_TimelineEntry(r.date('date')!, r.str('title'), r.str('type'), r));
    }
    for (final r in repo.ofKind(Kinds.property)) {
      if (r.date('acquisitionDate') != null) {
        entries.add(_TimelineEntry(r.date('acquisitionDate')!, 'Acquired ${r.str('name')}', r.str('propertyType'), r));
      }
    }
    entries.sort((a, b) => a.date.compareTo(b.date));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Life timeline')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => RecordFormScreen.open(context, Kinds.lifeEvent),
        backgroundColor: Brand.gold,
        foregroundColor: Brand.navy,
        child: const Icon(Icons.add),
      ),
      body: entries.isEmpty
          ? const EmptyState(
              icon: Icons.timeline,
              title: 'Your timeline is empty',
              message: 'Add your date of birth, education, career and life events — they appear here automatically.',
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: entries.length,
              itemBuilder: (context, i) {
                final e = entries[i];
                final showYear = i == 0 || entries[i - 1].date.year != e.date.year;
                return IntrinsicHeight(
                  child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    SizedBox(
                      width: 56,
                      child: showYear
                          ? Padding(
                              padding: const EdgeInsets.only(top: 14),
                              child: Text('${e.date.year}',
                                  style: theme.textTheme.titleSmall?.copyWith(color: Brand.gold, fontWeight: FontWeight.w700)),
                            )
                          : null,
                    ),
                    Column(children: [
                      Expanded(child: Container(width: 2, color: i == 0 ? Colors.transparent : Brand.gold.withValues(alpha: 0.4))),
                      Container(width: 12, height: 12, decoration: const BoxDecoration(color: Brand.gold, shape: BoxShape.circle)),
                      Expanded(
                        child: Container(
                            width: 2, color: i == entries.length - 1 ? Colors.transparent : Brand.gold.withValues(alpha: 0.4)),
                      ),
                    ]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Card(
                          child: ListTile(
                            title: Text(e.title),
                            subtitle: Text([fmtDate(e.date), e.subtitle].where((x) => x.isNotEmpty).join(' · ')),
                            onTap: () => Navigator.push(
                                context, MaterialPageRoute(builder: (_) => RecordDetailScreen(recordId: e.record.id))),
                          ),
                        ),
                      ),
                    ),
                  ]),
                );
              },
            ),
    );
  }
}

class LifeScorecardScreen extends StatelessWidget {
  const LifeScorecardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final repo = context.watch<VaultRepository>();
    final ach = repo.ofKind(Kinds.achievement);
    final byType = <String, int>{};
    for (final a in ach) {
      final t = a.str('type').isEmpty ? 'Other' : a.str('type');
      byType[t] = (byType[t] ?? 0) + 1;
    }
    final stats = [
      ('Qualifications', repo.ofKind(Kinds.education).length, Icons.school_outlined),
      ('Roles held', repo.ofKind(Kinds.career).length, Icons.work_outline),
      ('Achievements', ach.length, Icons.emoji_events_outlined),
      ('Life milestones', repo.ofKind(Kinds.lifeEvent).length, Icons.flag_outlined),
      ('Businesses', repo.ofKind(Kinds.business).length, Icons.storefront_outlined),
      ('Family members', repo.ofKind(Kinds.familyMember).length, Icons.people_outline),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Life scorecard')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.95,
          children: [for (final s in stats) StatTile(label: s.$1, value: '${s.$2}', icon: s.$3)],
        ),
        const SectionHeader('Achievements by type'),
        if (byType.isEmpty)
          const InfoBanner('Record awards, publications, leadership roles and community work in Achievements.')
        else
          for (final e in byType.entries)
            NavTile(icon: Icons.emoji_events_outlined, title: e.key, trailing: Text('${e.value}')),
      ]),
    );
  }
}
