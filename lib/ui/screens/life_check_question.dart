import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/push.dart';
import '../../core/services/succession_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'shared_with_me.dart';

/// Opens the screen a tapped notification points to.
void openNotificationRoute(BuildContext context, NotificationRoute route) {
  switch (route.type) {
    case 'lifeCheckQuestion':
      if (route.id.isEmpty) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => CheckOnOwnerScreen(questionId: route.id)));
    default:
      // Owner Life Check alerts land on the dashboard, which shows "I'm OK".
      break;
  }
}

/// Dashboard card shown to a confidant while someone they know hasn't responded.
class LifeCheckQuestionBanner extends StatelessWidget {
  const LifeCheckQuestionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = context.read<SuccessionService>();
    return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      stream: svc.lifeCheckQuestionsForMe(),
      builder: (context, snap) {
        final open = snap.data ?? const [];
        if (open.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(children: [
            for (final q in open)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Glass(
                  radius: 28,
                  padding: const EdgeInsets.all(12),
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => CheckOnOwnerScreen(questionId: q.id))),
                  child: Row(children: [
                    const AmberOrb(icon: CupertinoIcons.person_crop_circle_badge_exclam, size: 46),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Is someone you know OK?', style: Theme.of(context).textTheme.titleSmall),
                        Text('Tap to let us know if they\'re around',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: GlassColors.of(context).muted)),
                      ]),
                    ),
                    const Icon(CupertinoIcons.chevron_right, size: 16),
                  ]),
                ),
              ),
          ]),
        );
      },
    );
  }
}

/// "Is <owner> around?" — asked of a confidant after the owner missed their
/// Life Check several times. Deliberately says nothing about what the owner
/// may have left for them.
class CheckOnOwnerScreen extends StatefulWidget {
  const CheckOnOwnerScreen({super.key, required this.questionId});
  final String questionId;
  @override
  State<CheckOnOwnerScreen> createState() => _CheckOnOwnerScreenState();
}

class _CheckOnOwnerScreenState extends State<CheckOnOwnerScreen> {
  late final Future<LifeCheckQuestion?> _q = context.read<SuccessionService>().lifeCheckQuestion(widget.questionId);

  Future<void> _alive(LifeCheckQuestion q) async {
    final ok = await runBusy(context, () async {
      await context.read<SuccessionService>().answerLifeCheck(q.id, alive: true);
      return true;
    }, label: 'Letting them know…');
    if (ok == true && mounted) {
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Thank you'),
          content: Text('We\'ve let ${q.ownerName} know, and their check-in has been reset.'),
          actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Done'))],
        ),
      );
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _notAlive(LifeCheckQuestion q) async {
    final sure = await confirm(
      context,
      'Report that ${q.ownerName} can\'t respond?',
      'Only confirm if you know they have passed away or are seriously unwell. Our verification team will review '
          'official evidence before anything happens, and ${q.ownerName} is told in case they are actually well.',
      ok: 'Yes, report it',
      destructive: true,
    );
    if (!sure || !mounted) return;
    final ok = await runBusy(context, () async {
      await context.read<SuccessionService>().answerLifeCheck(q.id, alive: false);
      return true;
    }, label: 'Recording…');
    if (ok != true || !mounted) return;
    final triggers = q.triggers;
    if (triggers != null && triggers.isNotEmpty) {
      // Next: evidence (e.g. death certificate) for the verification team.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => RequestAccessScreen(ownerUid: q.ownerUid, ownerName: q.ownerName, triggers: triggers)),
      );
    } else {
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('We\'re very sorry'),
          content: Text('Thank you for letting us know. Our verification team will follow up about ${q.ownerName}. '
              'Nothing happens without verified evidence.'),
          actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Close'))],
        ),
      );
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: FutureBuilder<LifeCheckQuestion?>(
        future: _q,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          final q = snap.data;
          if (q == null || !q.open) {
            return const EmptyState(
              icon: CupertinoIcons.checkmark_circle,
              title: 'Nothing to answer',
              message: 'This question was already answered or is no longer needed. Thank you.',
            );
          }
          return ListView(padding: const EdgeInsets.fromLTRB(22, 8, 22, 32), children: [
            const Center(child: AmberOrb(icon: CupertinoIcons.person_crop_circle_badge_exclam, size: 88)),
            const SizedBox(height: 24),
            Text('Is ${q.ownerName} OK?',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 34), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(
              '${q.ownerName} listed you as a trusted contact. We haven\'t heard from them for a while and want to '
              'make sure they\'re all right.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: g.muted, height: 1.45),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            PillButton(
              label: 'Yes, they\'re around',
              icon: CupertinoIcons.checkmark_alt,
              amber: true,
              onPressed: () => _alive(q),
            ),
            const SizedBox(height: 12),
            PillButton(
              label: 'No, they\'ve passed away or can\'t respond',
              icon: CupertinoIcons.exclamationmark_triangle,
              onPressed: () => _notAlive(q),
            ),
            const SizedBox(height: 24),
            const InfoBanner(
              'If you\'re not sure, try to reach them first. Answering "yes" resets their check-in; '
              'answering "no" asks you for evidence, which our team verifies before anything happens.',
            ),
          ]);
        },
      ),
    );
  }
}
