import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/logic/analysis.dart';
import '../../core/schema/record_types.dart';
import '../../core/services/session.dart';
import '../../core/services/vault_repository.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'dashboard.dart';
import 'life.dart';

class WealthScreen extends StatelessWidget {
  const WealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<VaultRepository>();
    final s = context.watch<Session>();
    final idx = RecordIndex(repo.all);
    final nw = netWorth(idx);
    final currencies = nw.keys.toList()
      ..sort((a, b) => a == s.displayCurrency ? -1 : (b == s.displayCurrency ? 1 : a.compareTo(b)));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(leading: const MenuButton(), leadingWidth: 68, toolbarHeight: 72, title: const Text('My Wealth')),
      // Lift above the Shell's floating glass nav bar.
      floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: kShellNavClearance),
          child: FloatingActionButton.extended(
            onPressed: () =>
                pickKindAndAdd(context, [...Kinds.assets, Kinds.liability, Kinds.insurance], title: 'Add to My Wealth'),
            icon: const Icon(Icons.add),
            label: const Text('Add'),
            backgroundColor: Brand.gold,
            foregroundColor: Brand.navy,
          )),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 130), children: [
        if (nw.isEmpty)
          const InfoBanner('Add your assets and liabilities to see your estimated net worth.')
        else
          for (final c in currencies) _NetWorthCard(currency: c, totals: nw[c]!),
        Padding(
          padding: const EdgeInsets.only(top: 6, left: 4),
          child: Text(
            'Net worth = your share of documented assets − documented liabilities (including balances still owed on '
            'assets you are paying off in installments). Figures are estimates unless '
            'professionally verified, and currencies are not converted.',
            style: theme.textTheme.bodySmall,
          ),
        ),
        const SectionHeader('Assets'),
        for (final k in Kinds.assets) _kindTile(context, repo, k, nw),
        const SectionHeader('Obligations & protection'),
        _kindTile(context, repo, Kinds.liability, nw),
        _kindTile(context, repo, Kinds.insurance, nw),
      ]),
    );
  }

  Widget _kindTile(BuildContext context, VaultRepository repo, String k, Map<String, CurrencyTotals> nw) {
    final t = typeOf(k);
    final items = repo.ofKind(k);
    String sub = '${items.length} recorded';
    if (Kinds.assets.contains(k) && items.isNotEmpty) {
      final parts = nw.entries.where((e) => (e.value.byKind[k] ?? 0) > 0).map((e) => money(e.value.byKind[k]!, e.key));
      if (parts.isNotEmpty) sub += ' · ${parts.join(' + ')}';
    }
    return NavTile(icon: t.icon, title: t.plural, subtitle: sub, onTap: () => openKind(context, k));
  }
}

class _NetWorthCard extends StatelessWidget {
  const _NetWorthCard({required this.currency, required this.totals});
  final String currency;
  final CurrencyTotals totals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxV = totals.byKind.values.fold<double>(0, (a, b) => a > b ? a : b);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Estimated net worth · $currency', style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(money(totals.net, currency),
                style: theme.textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w700, color: totals.net < 0 ? Brand.danger : null)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _kv(context, 'Assets', money(totals.assets, currency))),
              Expanded(child: _kv(context, 'Liabilities', money(totals.liabilities, currency))),
            ]),
            if (totals.byKind.isNotEmpty) ...[
              const SizedBox(height: 14),
              for (final e in (totals.byKind.entries.toList()..sort((a, b) => b.value.compareTo(a.value))))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(typeOf(e.key).plural, style: theme.textTheme.bodySmall)),
                      Text(money(e.value, currency), style: theme.textTheme.bodySmall),
                    ]),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: maxV == 0 ? 0 : e.value / maxV,
                        minHeight: 6,
                        color: Brand.gold,
                        backgroundColor: Brand.gold.withValues(alpha: 0.12),
                      ),
                    ),
                  ]),
                ),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(k, style: Theme.of(context).textTheme.bodySmall),
        Text(v, style: Theme.of(context).textTheme.titleSmall),
      ]);
}
