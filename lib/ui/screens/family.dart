import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/record.dart';
import '../../core/schema/record_types.dart';
import '../../core/services/vault_repository.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/record_form.dart';
import 'life.dart';
import 'records.dart';

class FamilyScreen extends StatelessWidget {
  const FamilyScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final repo = context.watch<VaultRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('My Family')),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 32), children: [
        NavTile(
          icon: Icons.account_tree_outlined,
          title: 'Family tree',
          subtitle: 'Generations at a glance',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyTreeScreen())),
        ),
        NavTile(
          icon: Icons.people_outline,
          title: 'Family members',
          subtitle: '${repo.ofKind(Kinds.familyMember).length} recorded',
          onTap: () => openKind(context, Kinds.familyMember),
        ),
        NavTile(
          icon: Icons.auto_stories_outlined,
          title: 'Family history archive',
          subtitle: 'Stories, traditions, ancestral property',
          onTap: () => openKind(context, Kinds.familyStory),
        ),
        const SizedBox(height: 12),
        const InfoBanner(
          'Family records are encrypted with your "My Family" key. To share them, name a family member as a trusted '
          'confidant and grant only the "My Family" category — they never get access to the rest of your Dossier.',
          icon: Icons.lock_outline,
        ),
      ]),
    );
  }
}

class FamilyTreeScreen extends StatelessWidget {
  const FamilyTreeScreen({super.key});

  static const _generations = <String, List<String>>{
    'Grandparents': ['Grandparent'],
    'Parents & elders': ['Parent', 'Aunt / Uncle', 'In-law'],
    'Your generation': ['Spouse', 'Sibling', 'Cousin'],
    'Children': ['Child', 'Niece / Nephew'],
    'Grandchildren': ['Grandchild'],
  };

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<VaultRepository>();
    final members = repo.ofKind(Kinds.familyMember);
    final placed = <String>{};
    Widget person(DossierRecord m) {
      placed.add(m.id);
      final deceased = m.data['deceased'] == true;
      return InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RecordDetailScreen(recordId: m.id))),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 120,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Brand.gold.withValues(alpha: deceased ? 0.3 : 0.8)),
          ),
          child: Column(children: [
            CircleAvatar(
              backgroundColor: Brand.gold.withValues(alpha: 0.15),
              foregroundColor: Brand.gold,
              child: Text(m.str('name').isEmpty ? '?' : m.str('name')[0].toUpperCase()),
            ),
            const SizedBox(height: 6),
            Text(m.str('name'), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
            Text('${m.str('relationship')}${deceased ? ' · †' : ''}',
                style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
          ]),
        ),
      );
    }

    final rows = <Widget>[];
    _generations.forEach((label, rels) {
      final inGen = members.where((m) => rels.contains(m.str('relationship'))).toList();
      final isYou = label == 'Your generation';
      if (inGen.isEmpty && !isYou) return;
      rows
        ..add(SectionHeader(label))
        ..add(Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 10, children: [
          if (isYou)
            Container(
              width: 120,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Brand.gold, borderRadius: BorderRadius.circular(12)),
              child: Column(children: [
                const CircleAvatar(backgroundColor: Brand.navy, foregroundColor: Brand.gold, child: Icon(Icons.person)),
                const SizedBox(height: 6),
                Text(repo.displayName,
                    textAlign: TextAlign.center, style: const TextStyle(color: Brand.navy, fontWeight: FontWeight.w700)),
                const Text('You', style: TextStyle(color: Brand.navy, fontSize: 12)),
              ]),
            ),
          ...inGen.map(person),
        ]));
    });
    final others = members.where((m) => !placed.contains(m.id)).toList();
    if (others.isNotEmpty) {
      rows
        ..add(const SectionHeader('Other relatives & friends'))
        ..add(Wrap(spacing: 10, runSpacing: 10, children: others.map(person).toList()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Family tree')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => RecordFormScreen.open(context, Kinds.familyMember),
        backgroundColor: Brand.gold,
        foregroundColor: Brand.navy,
        child: const Icon(Icons.person_add_alt),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 96), children: [
        if (members.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: InfoBanner('Add family members and choose their relationship to you to build your tree.'),
          ),
        ...rows,
      ]),
    );
  }
}
