import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/crypto/crypto_primitives.dart';
import '../../core/schema/record_types.dart';
import '../../core/services/firebase_refs.dart';
import '../../core/services/session.dart';
import '../../core/services/vault_repository.dart';
import '../theme.dart';
import 'onboarding.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool? _deviceUnlock;
  bool _deviceSupported = false;
  String? _fingerprint;

  @override
  void initState() {
    super.initState();
    final s = context.read<Session>();
    s.device.isEnabled(s.uid).then((v) {
      if (mounted) setState(() => _deviceUnlock = v);
    });
    s.device.isSupported().then((v) {
      if (mounted) setState(() => _deviceSupported = v);
    });
    s.keyFingerprint().then((v) {
      if (mounted) setState(() => _fingerprint = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<Session>();
    final repo = context.read<VaultRepository>();
    final theme = (s.userDoc['prefs'] as Map?)?['theme'] as String? ?? 'system';
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 32), children: [
        const SectionHeader('Appearance'),
        Card(
          child: Column(children: [
            ListTile(
              leading: const Icon(Icons.auto_awesome_outlined),
              title: const Text('Replay introduction'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (c) => OnboardingScreen(signedIn: true, onFinish: ({required register}) => Navigator.pop(c)),
                ),
              ),
            ),
            ListTile(
              title: const Text('Theme'),
              trailing: DropdownButton<String>(
                value: theme,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 'system', child: Text('System')),
                  DropdownMenuItem(value: 'light', child: Text('Light')),
                  DropdownMenuItem(value: 'dark', child: Text('Dark')),
                ],
                onChanged: (v) => s.updatePrefs({'theme': v}),
              ),
            ),
            ListTile(
              title: const Text('Display currency'),
              trailing: DropdownButton<String>(
                value: s.displayCurrency,
                underline: const SizedBox.shrink(),
                items: [for (final c in currencies) DropdownMenuItem(value: c, child: Text(c))],
                onChanged: (v) => s.updatePrefs({'currency': v}),
              ),
            ),
          ]),
        ),
        const SectionHeader('Security'),
        Card(
          child: Column(children: [
            ListTile(
              title: const Text('Auto-lock after'),
              subtitle: const Text('Keys are wiped from memory when the vault locks'),
              trailing: DropdownButton<int>(
                value: [1, 5, 15, 30].contains(s.autoLockMinutes) ? s.autoLockMinutes : 5,
                underline: const SizedBox.shrink(),
                items: [for (final m in [1, 5, 15, 30]) DropdownMenuItem(value: m, child: Text('$m min'))],
                onChanged: (v) => s.updatePrefs({'autoLockMinutes': v}),
              ),
            ),
            if (_deviceSupported)
              SwitchListTile(
                title: const Text('Quick unlock with biometrics'),
                subtitle: const Text('Keeps your vault key in this device\'s secure keystore. Never synced.'),
                value: _deviceUnlock ?? false,
                onChanged: (v) async {
                  if (v) {
                    final ok = await s.device.enable(s.uid, s.keyring.masterKey);
                    if (mounted) setState(() => _deviceUnlock = ok);
                  } else {
                    await s.device.disable(s.uid);
                    if (mounted) setState(() => _deviceUnlock = false);
                  }
                },
              ),
            ListTile(
              leading: const Icon(Icons.password),
              title: const Text('Change vault passphrase'),
              onTap: () => _changePassphrase(context, s),
            ),
            ListTile(
              leading: const Icon(Icons.key),
              title: const Text('Generate a new recovery key'),
              subtitle: const Text('Your old recovery key will stop working'),
              onTap: () => _rotateRecovery(context, s),
            ),
            ListTile(
              leading: const Icon(Icons.fingerprint),
              title: const Text('My key fingerprint'),
              subtitle: SelectableText(_fingerprint ?? '…', style: const TextStyle(fontFamily: 'monospace', letterSpacing: 1)),
              isThreeLine: false,
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
          child: Text(
            'Read your fingerprint aloud to anyone naming you as a confidant so they can confirm it is really you.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SectionHeader('Your data'),
        Card(
          child: Column(children: [
            ListTile(
              leading: const Icon(Icons.download_outlined),
              title: const Text('Export decrypted copy (JSON)'),
              subtitle: const Text('Leaves the app unencrypted — store it carefully'),
              onTap: () async {
                if (!await confirm(context, 'Export unencrypted data?',
                    'The export file is NOT encrypted. Anyone with the file can read it.', ok: 'Export')) {
                  return;
                }
                final json = repo.exportJson();
                await Share.shareXFiles([
                  XFile.fromData(Uint8List.fromList(utf8.encode(json)), mimeType: 'application/json', name: 'dossier-export.json'),
                ], subject: 'Dossier export');
                await repo.logAudit('data.export');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever_outlined, color: Brand.danger),
              title: const Text('Delete my Dossier and account', style: TextStyle(color: Brand.danger)),
              onTap: () => _deleteAll(context, s, repo),
            ),
          ]),
        ),
        const SectionHeader('Account'),
        Card(
          child: Column(children: [
            ListTile(leading: const Icon(Icons.mail_outline), title: Text(s.email)),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign out'),
              onTap: () {
                Navigator.popUntil(context, (r) => r.isFirst);
                s.signOut();
              },
            ),
          ]),
        ),
        const SizedBox(height: 16),
        Center(child: Text('The Dossier · end-to-end encrypted · v1.0', style: Theme.of(context).textTheme.bodySmall)),
      ]),
    );
  }

  Future<void> _changePassphrase(BuildContext context, Session s) async {
    final cur = TextEditingController();
    final next = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Change vault passphrase'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: cur, obscureText: true, decoration: const InputDecoration(labelText: 'Current passphrase')),
          const SizedBox(height: 12),
          TextField(controller: next, obscureText: true, decoration: const InputDecoration(labelText: 'New passphrase (12+ chars)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Change')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    if (next.text.length < 12 || PassphraseStrength.score(next.text) < 3) {
      toast(context, 'New passphrase is too weak.', error: true);
      return;
    }
    await runBusy(context, () => s.changePassphrase(cur.text, next.text),
        label: 'Re-wrapping your keys…', success: 'Passphrase changed');
  }

  Future<void> _rotateRecovery(BuildContext context, Session s) async {
    if (!await confirm(context, 'New recovery key?', 'Your current recovery key will stop working immediately.', ok: 'Generate')) {
      return;
    }
    if (!context.mounted) return;
    final key = await runBusy(context, s.rotateRecoveryKey, label: 'Generating…');
    if (key == null || !context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (d) => AlertDialog(
        title: const Text('Your new recovery key'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Write it down now. It will not be shown again.'),
          const SizedBox(height: 12),
          SelectableText(key, style: const TextStyle(fontFamily: 'monospace', fontSize: 16, letterSpacing: 1.2)),
        ]),
        actions: [FilledButton(onPressed: () => Navigator.pop(d), child: const Text('I have saved it'))],
      ),
    );
  }

  Future<void> _deleteAll(BuildContext context, Session s, VaultRepository repo) async {
    if (!await confirm(context, 'Delete everything?',
        'All records, encrypted files, confidant grants and your account will be permanently deleted. This cannot be undone.',
        ok: 'Delete everything', destructive: true)) {
      return;
    }
    if (!context.mounted) return;
    final done = await runBusy(context, () async {
      await repo.eraseEverything();
      final hash = await sha256Hex(normaliseEmail(s.email));
      await Refs.directory(hash).delete();
      await s.device.disable(s.uid);
      await Refs.user(s.uid).delete();
      await FirebaseAuth.instance.currentUser?.delete();
      return true;
    }, label: 'Deleting…');
    if (done == true && context.mounted) Navigator.popUntil(context, (r) => r.isFirst);
  }
}
