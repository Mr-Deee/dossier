import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/logic/analysis.dart';
import '../../core/schema/record_types.dart';
import '../../core/services/succession_service.dart';
import '../../core/services/vault_repository.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'records.dart';

class IntelligenceScreen extends StatelessWidget {
  const IntelligenceScreen({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Dossier Intelligence'),
            bottom: const TabBar(tabs: [Tab(text: 'Assistant'), Tab(text: 'Readiness index')]),
          ),
          body: const TabBarView(children: [_Assistant(), _ReadinessTab()]),
        ),
      );
}

class _Msg {
  _Msg(this.fromUser, this.text, [this.answer]);
  final bool fromUser;
  final String text;
  final AssistantAnswer? answer;
}

class _Assistant extends StatefulWidget {
  const _Assistant();
  @override
  State<_Assistant> createState() => _AssistantState();
}

class _AssistantState extends State<_Assistant> with AutomaticKeepAliveClientMixin {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _msgs = [];
  int _grants = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    context.read<SuccessionService>().myGrants().first.then((g) {
      if (mounted) setState(() => _grants = g.length);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _ask(String q) {
    if (q.trim().isEmpty) return;
    final repo = context.read<VaultRepository>();
    final a = ask(q, RecordIndex(repo.all), confidantGrants: _grants);
    setState(() {
      _msgs.add(_Msg(true, q));
      _msgs.add(_Msg(false, a.text, a));
    });
    _ctrl.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final repo = context.watch<VaultRepository>();
    return Column(children: [
      Expanded(
        child: ListView(controller: _scroll, padding: const EdgeInsets.all(16), children: [
          const InfoBanner(
            'The assistant runs entirely on this device over your decrypted records. Nothing is sent to any AI service, '
            'so your end-to-end encryption is preserved.',
            icon: Icons.phonelink_lock,
          ),
          const SizedBox(height: 12),
          if (_msgs.isEmpty)
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final s in assistantSuggestions) ActionChip(label: Text(s), onPressed: () => _ask(s)),
            ]),
          for (final m in _msgs)
            Align(
              alignment: m.fromUser ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                constraints: const BoxConstraints(maxWidth: 520),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: m.fromUser ? Brand.gold.withValues(alpha: 0.2) : Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m.text),
                  if (m.answer != null)
                    for (final r in m.answer!.records.take(15))
                      InkWell(
                        onTap: () {
                          if (repo.byId(r.id) == null) return;
                          Navigator.push(context, MaterialPageRoute(builder: (_) => RecordDetailScreen(recordId: r.id)));
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(children: [
                            Icon(typeOf(r.kind).icon, size: 16, color: Brand.gold),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text('${typeOf(r.kind).title(r)} · ${typeOf(r.kind).label}',
                                  style: const TextStyle(decoration: TextDecoration.underline)),
                            ),
                          ]),
                        ),
                      ),
                ]),
              ),
            ),
        ]),
      ),
      SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                onSubmitted: _ask,
                decoration: const InputDecoration(hintText: 'Ask about your Dossier…'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(onPressed: () => _ask(_ctrl.text), icon: const Icon(Icons.send)),
          ]),
        ),
      ),
    ]);
  }
}

class _ReadinessTab extends StatelessWidget {
  const _ReadinessTab();
  @override
  Widget build(BuildContext context) {
    final repo = context.watch<VaultRepository>();
    return StreamBuilder<List<Grant>>(
      stream: context.read<SuccessionService>().myGrants(),
      builder: (context, snap) {
        final r = readiness(RecordIndex(repo.all), confidantGrants: snap.data?.length ?? 0);
        final theme = Theme.of(context);
        return ListView(padding: const EdgeInsets.all(16), children: [
          Center(
            child: SizedBox(
              width: 140,
              height: 140,
              child: Stack(fit: StackFit.expand, children: [
                CircularProgressIndicator(
                  value: r.score / 100,
                  strokeWidth: 10,
                  color: Brand.gold,
                  backgroundColor: Brand.gold.withValues(alpha: 0.15),
                ),
                Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('${r.score}', style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700)),
                    const Text('/ 100'),
                  ]),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Legacy Readiness Index measures how completely your Dossier is documented. It does not measure legal validity '
            'or financial security.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          for (final i in r.items)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(i.complete ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: i.complete ? Brand.ok : Brand.gold),
                title: Text(i.label),
                subtitle: i.complete ? null : Text(i.hint),
                trailing: Text('${i.points.round()}/${i.max.round()}'),
              ),
            ),
        ]);
      },
    );
  }
}
