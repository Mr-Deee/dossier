import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/firebase_refs.dart';
import '../../core/services/succession_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'succession.dart' show circumstanceLabels;

/// For accounts with the `verifier` custom claim (legal / verification partners).
///
/// Verifiers see the request, the requester's statement and evidence — never the
/// owner's records, which stay encrypted with keys the verifier does not hold.
class VerifierDeskScreen extends StatelessWidget {
  const VerifierDeskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = context.read<SuccessionService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Verification desk')),
      body: StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
        stream: svc.pendingForVerifier(),
        builder: (context, snap) {
          if (snap.hasError) return EmptyState(icon: Icons.error_outline, title: friendlyError(snap.error!));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final reqs = snap.data!;
          if (reqs.isEmpty) return const EmptyState(icon: Icons.inbox_outlined, title: 'No pending requests');
          return ListView(padding: const EdgeInsets.all(16), children: [
            const InfoBanner(
              'Approve only after independently confirming the event (e.g. with the Births and Deaths Registry, the '
              'hospital, or a court order). Approval is blocked by the server until the objection period has ended.',
              icon: Icons.verified_user_outlined,
            ),
            const SizedBox(height: 12),
            for (final r in reqs) _RequestCard(doc: r),
          ]);
        },
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.doc});
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  @override
  Widget build(BuildContext context) {
    final d = doc.data();
    final deadline = tsToDate(d['objectionDeadline']);
    final ready = deadline != null && deadline.isBefore(DateTime.now());
    final svc = context.read<SuccessionService>();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${circumstanceLabels[d['circumstance']] ?? d['circumstance']} · request ${doc.id.substring(0, 8)}',
              style: Theme.of(context).textTheme.titleMedium),
          Text('Submitted ${fmtDate(tsToDate(d['createdAt']))} · objection period ends ${fmtDate(deadline)}'),
          const SizedBox(height: 8),
          Text('Statement: ${d['statement'] ?? '—'}'),
          Text('Verifier approvals so far: ${(d['approvals'] as List?)?.length ?? 0}'),
          if (d['evidencePath'] != null)
            TextButton.icon(
              onPressed: () async {
                final url = await runBusy(context, () => svc.evidenceUrl(d['evidencePath'] as String));
                if (url != null) await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              },
              icon: const Icon(Icons.attach_file),
              label: const Text('View evidence'),
            ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _decide(context, approve: false),
                child: const Text('Reject'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: ready ? () => _decide(context, approve: true) : null,
                child: Text(ready ? 'Approve release' : 'Waiting period'),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Future<void> _decide(BuildContext context, {required bool approve}) async {
    final c = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(approve ? 'Approve and release' : 'Reject request'),
        content: TextField(
          controller: c,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: approve ? 'How was this independently verified?' : 'Reason',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
          FilledButton(
            style: approve ? null : FilledButton.styleFrom(backgroundColor: Brand.danger, foregroundColor: Colors.white),
            onPressed: () {
              if (c.text.trim().length >= 10) Navigator.pop(d, c.text.trim());
            },
            child: Text(approve ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
    if (note == null || !context.mounted) return;
    final outcome = await runBusy(context, () => context.read<SuccessionService>().decide(doc.id, approve: approve, note: note));
    if (outcome != null && context.mounted) toast(context, outcome);
  }
}
