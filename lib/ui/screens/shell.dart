import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/session.dart';
import '../../core/services/vault_repository.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'dashboard.dart';
import 'documents.dart';
import 'family.dart';
import 'intelligence.dart';
import 'legacy.dart';
import 'life.dart';
import 'settings.dart';
import 'shared_with_me.dart';
import 'succession.dart';
import 'verifier_desk.dart';
import 'wealth.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _index = 0;

  static const _tabs = [
    (CupertinoIcons.house, CupertinoIcons.house_fill, 'Home'),
    (CupertinoIcons.person, CupertinoIcons.person_fill, 'Life'),
    (CupertinoIcons.chart_pie, CupertinoIcons.chart_pie_fill, 'Wealth'),
    (CupertinoIcons.lock_shield, CupertinoIcons.lock_shield_fill, 'Vault'),
    (CupertinoIcons.book, CupertinoIcons.book_fill, 'Legacy'),
  ];

  void goTo(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<VaultRepository>();
    final pages = [
      DashboardScreen(onNavigate: goTo),
      const LifeScreen(),
      const WealthScreen(),
      const DocumentsScreen(),
      const LegacyScreen(),
    ];
    return Scaffold(
      key: shellScaffoldKey,
      extendBody: true,
      drawer: const _AppDrawer(),
      body: repo.loading
          ? const Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                AmberOrb(icon: CupertinoIcons.lock_open, size: 76),
                SizedBox(height: 22),
                Text('Decrypting your Dossier…'),
              ]),
            )
          : IndexedStack(index: _index, children: pages),
      bottomNavigationBar: _GlassNavBar(index: _index, onTap: goTo, tabs: _tabs),
    );
  }
}

class _GlassNavBar extends StatelessWidget {
  const _GlassNavBar({required this.index, required this.onTap, required this.tabs});
  final int index;
  final ValueChanged<int> onTap;
  final List<(IconData, IconData, String)> tabs;

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottom > 0 ? bottom : 14),
      child: Glass(
        radius: 40,
        blur: 30,
        strong: true,
        padding: const EdgeInsets.all(7),
        child: SizedBox(
          height: 60,
          child: Row(children: [
            for (var i = 0; i < tabs.length; i++)
              Expanded(
                flex: i == index ? 2 : 1,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Semantics(
                    selected: i == index,
                    button: true,
                    label: tabs[i].$3,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: i == index ? Brand.amberGradient : null,
                        boxShadow: i == index
                            ? [BoxShadow(color: Brand.amber.withValues(alpha: 0.45), blurRadius: 18, offset: const Offset(0, 6))]
                            : null,
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(i == index ? tabs[i].$2 : tabs[i].$1,
                            size: 22, color: i == index ? Brand.ink : g.muted),
                        if (i == index) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(tabs[i].$3,
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(color: Brand.ink, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ]),
                    ),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<Session>();
    final repo = context.watch<VaultRepository>();
    final g = GlassColors.of(context);
    void push(Widget w) {
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(builder: (_) => w));
    }

    final name = repo.displayName.trim();
    final initials = name.isEmpty
        ? '·'
        : name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2).map((p) => p[0].toUpperCase()).join();

    Widget item(IconData icon, String label, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          child: ListTile(
            leading: Icon(icon, size: 22),
            title: Text(label),
            trailing: Icon(CupertinoIcons.chevron_right, size: 14, color: g.muted),
            onTap: onTap,
          ),
        );

    return Drawer(
      child: SafeArea(
        child: ListView(padding: const EdgeInsets.only(bottom: 24), children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Wordmark(size: 24),
              const SizedBox(height: 24),
              Glass(
                radius: 24,
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(shape: BoxShape.circle, gradient: Brand.amberGradient),
                    child: Text(initials,
                        style: const TextStyle(color: Brand.ink, fontWeight: FontWeight.w700, fontSize: 17)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name.isEmpty ? 'Your Dossier' : name,
                          style: Theme.of(context).textTheme.titleMedium, overflow: TextOverflow.ellipsis),
                      Text(s.email,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: g.muted),
                          overflow: TextOverflow.ellipsis),
                    ]),
                  ),
                ]),
              ),
            ]),
          ),
          item(CupertinoIcons.person_3, 'My Family', () => push(const FamilyScreen())),
          item(CupertinoIcons.shield_lefthalf_fill, 'My Succession', () => push(const SuccessionScreen())),
          item(CupertinoIcons.sparkles, 'Dossier Intelligence', () => push(const IntelligenceScreen())),
          item(CupertinoIcons.person_2, 'Shared with me', () => push(const SharedWithMeScreen())),
          if (s.isVerifier) item(CupertinoIcons.checkmark_shield, 'Verification desk', () => push(const VerifierDeskScreen())),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Divider()),
          item(CupertinoIcons.gear, 'Settings', () => push(const SettingsScreen())),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: PillButton(
              label: 'Lock now',
              icon: CupertinoIcons.lock_fill,
              amber: true,
              onPressed: () {
                Navigator.pop(context);
                s.lock();
              },
            ),
          ),
        ]),
      ),
    );
  }
}
