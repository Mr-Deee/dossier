import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/session.dart';
import '../theme.dart';
import '../widgets/common.dart';

class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold({required this.children, this.leading});
  final List<Widget> children;
  final Widget? leading;
  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    if (leading != null) ...[leading!, const SizedBox(width: 12)],
                    const Wordmark(size: 22),
                    const SizedBox(width: 12),
                    const Spacer(),
                    const Flexible(child: _E2EBadge()),
                  ]),
                  const SizedBox(height: 36),
                  ...children,
                ]),
              ),
            ),
          ),
        ),
      );
}

class _E2EBadge extends StatelessWidget {
  const _E2EBadge();
  @override
  Widget build(BuildContext context) => Glass(
        radius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(CupertinoIcons.lock_fill, size: 13, color: GlassColors.of(context).accentText),
          const SizedBox(width: 6),
          Flexible(
            child: Text('End-to-end encrypted',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
          ),
        ]),
      );
}

/// Big editorial headline, as in the onboarding.
class _Hero extends StatelessWidget {
  const _Hero(this.title, {super.key, this.subtitle, this.eyebrow});
  final String title;
  final String? subtitle;
  final String? eyebrow;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final g = GlassColors.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (eyebrow != null) ...[
        Row(children: [
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Brand.amber, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(eyebrow!, style: t.labelLarge?.copyWith(color: g.accentText, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 12),
      ],
      Text(title, style: t.displaySmall?.copyWith(fontSize: 42)),
      if (subtitle != null) ...[
        const SizedBox(height: 12),
        Text(subtitle!, style: t.bodyLarge?.copyWith(color: g.muted, height: 1.45)),
      ],
      const SizedBox(height: 28),
    ]);
  }
}

// ---------------------------------------------------------------------------

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, this.initialRegister = false, this.onBack});
  final bool initialRegister;

  /// Shown as a back button (e.g. to return to onboarding).
  final VoidCallback? onBack;
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  late bool _register = widget.initialRegister;
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    final s = context.read<Session>();
    try {
      if (_register) {
        await s.register(_email.text, _password.text);
      } else {
        await s.signIn(_email.text, _password.text);
      }
    } catch (e) {
      if (mounted) toast(context, friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgot() async {
    if (_email.text.trim().isEmpty) {
      toast(context, 'Enter your email first.');
      return;
    }
    await runBusy(context, () => context.read<Session>().resetAccountPassword(_email.text),
        success: 'Password reset email sent. This resets your account password only — not your vault passphrase.');
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(
      leading: widget.onBack == null
          ? null
          : GlassIconButton(icon: CupertinoIcons.chevron_back, size: 44, onPressed: widget.onBack, tooltip: 'Back'),
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _register
              ? const _Hero('Create your\nDossier.',
                  key: ValueKey('r'),
                  eyebrow: 'New here',
                  subtitle: 'One private place for your life, wealth and legacy.')
              : const _Hero('Welcome\nback.',
                  key: ValueKey('s'), eyebrow: 'Sign in', subtitle: 'Pick up where you left off.'),
        ),
        _ModeToggle(register: _register, onChanged: (v) => setState(() => _register = v)),
        const SizedBox(height: 22),
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(children: [
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(CupertinoIcons.mail, size: 20)),
                validator: (v) =>
                    v != null && RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim()) ? null : 'Enter a valid email',
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _password,
                obscureText: _obscure,
                textInputAction: _register ? TextInputAction.next : TextInputAction.done,
                onFieldSubmitted: _register ? null : (_) => _submit(),
                autofillHints: [_register ? AutofillHints.newPassword : AutofillHints.password],
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(CupertinoIcons.lock, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? CupertinoIcons.eye : CupertinoIcons.eye_slash, size: 20),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) => (v ?? '').length < (_register ? 8 : 1) ? 'At least 8 characters' : null,
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: _register
                    ? Column(children: [
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _confirm,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: const InputDecoration(
                              labelText: 'Confirm password', prefixIcon: Icon(CupertinoIcons.lock, size: 20)),
                          validator: (v) => !_register || v == _password.text ? null : 'Passwords do not match',
                        ),
                        const SizedBox(height: 14),
                        const InfoBanner(
                          'This password signs you in. Next you will create a separate vault passphrase that '
                          'encrypts your data — we never see it.',
                          icon: CupertinoIcons.shield_lefthalf_fill,
                        ),
                      ])
                    : Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: TextButton(onPressed: _forgot, child: const Text('Forgot password?')),
                        ),
                      ),
              ),
              const SizedBox(height: 22),
              PillButton(
                label: _register ? 'Create account' : 'Sign in',
                busy: _busy,
                onPressed: _submit,
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

/// Sliding glass segmented control: Sign in | Create account.
class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.register, required this.onChanged});
  final bool register;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    final dark = g.dark;
    final t = Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 15);
    Widget label(String s, bool active) => Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(s != 'Sign in'),
            child: Center(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: t!.copyWith(color: active ? (dark ? Brand.ink : Colors.white) : g.muted),
                child: Text(s),
              ),
            ),
          ),
        );
    return Glass(
      radius: 30,
      padding: const EdgeInsets.all(5),
      child: SizedBox(
        height: 48,
        child: Stack(children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            alignment: register ? Alignment.centerRight : Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: dark ? null : Brand.ink,
                  gradient: dark ? Brand.amberGradient : null,
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
            ),
          ),
          Row(children: [label('Sign in', !register), label('Create account', register)]),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class VaultSetupScreen extends StatefulWidget {
  const VaultSetupScreen({super.key});
  @override
  State<VaultSetupScreen> createState() => _VaultSetupScreenState();
}

class _VaultSetupScreenState extends State<VaultSetupScreen> {
  final _form = GlobalKey<FormState>();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  bool _acknowledged = false;
  bool _savedKey = false;
  bool _obscure = true;

  @override
  void dispose() {
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_form.currentState!.validate()) return;
    if (!_acknowledged) {
      toast(context, 'Please confirm you understand the passphrase cannot be reset by us.', error: true);
      return;
    }
    final s = context.read<Session>();
    await runBusy(context, () => s.createVault(_pass.text), label: 'Generating your encryption keys…');
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<Session>();
    final rk = s.pendingRecoveryKey;
    if (rk != null) return _recoveryView(s, rk);
    return _AuthScaffold(children: [
      const _Hero('Create your\nvault key.',
          eyebrow: 'Step 2 of 2',
          subtitle: 'Everything you record is encrypted on this device with a key derived from this passphrase. '
              'No one — including The Dossier team — can read it or reset it for you.'),
      Form(
        key: _form,
        child: Column(children: [
          TextFormField(
            controller: _pass,
            obscureText: _obscure,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Vault passphrase',
              prefixIcon: const Icon(CupertinoIcons.lock_shield, size: 20),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? CupertinoIcons.eye : CupertinoIcons.eye_slash, size: 20),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              helperText: 'Use 4+ random words or 12+ characters. Different from your account password.',
              helperMaxLines: 2,
            ),
            validator: (v) => (v ?? '').length < 12
                ? 'Use at least 12 characters'
                : PassphraseStrength.score(v!) < 3
                    ? 'Too weak — make it longer or mix in numbers/symbols'
                    : null,
          ),
          const SizedBox(height: 12),
          PassphraseStrength(_pass.text),
          const SizedBox(height: 14),
          TextFormField(
            controller: _confirm,
            obscureText: _obscure,
            decoration: const InputDecoration(
                labelText: 'Confirm passphrase', prefixIcon: Icon(CupertinoIcons.lock_shield, size: 20)),
            validator: (v) => v == _pass.text ? null : 'Passphrases do not match',
          ),
          const SizedBox(height: 16),
          _CheckRow(
            value: _acknowledged,
            onChanged: (v) => setState(() => _acknowledged = v),
            text: 'I understand that if I lose both my passphrase and my recovery key, my data cannot be recovered.',
          ),
          const SizedBox(height: 20),
          PillButton(label: 'Create encrypted vault', icon: CupertinoIcons.lock_fill, onPressed: _create),
          const SizedBox(height: 8),
          TextButton(onPressed: s.signOut, child: const Text('Sign out')),
        ]),
      ),
    ]);
  }

  Widget _recoveryView(Session s, String rk) => _AuthScaffold(children: [
        const _Hero('Save your\nrecovery key.',
            eyebrow: 'Important',
            subtitle: 'If you forget your vault passphrase, this key is the only way back in. Write it down and keep it '
                'somewhere safe and offline. It will not be shown again.'),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Brand.ink,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(color: Brand.amber.withValues(alpha: 0.25), blurRadius: 30, offset: const Offset(0, 12))],
            border: Border.all(color: Brand.amber.withValues(alpha: 0.6)),
          ),
          child: Column(children: [
            const Icon(CupertinoIcons.lock_shield_fill, color: Brand.amber, size: 28),
            const SizedBox(height: 14),
            SelectableText(
              rk,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'monospace', fontSize: 18, letterSpacing: 1.5, color: Brand.amberGlow, height: 1.6),
            ),
          ]),
        ),
        const SizedBox(height: 18),
        _CheckRow(
          value: _savedKey,
          onChanged: (v) => setState(() => _savedKey = v),
          text: 'I have written down my recovery key',
        ),
        const SizedBox(height: 18),
        PillButton(label: 'Open my Dossier', onPressed: _savedKey ? s.confirmRecoverySaved : null),
      ]);
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.value, required this.onChanged, required this.text});
  final bool value;
  final ValueChanged<bool> onChanged;
  final String text;
  @override
  Widget build(BuildContext context) => Glass(
        radius: 20,
        onTap: () => onChanged(!value),
        padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
        child: Row(children: [
          Checkbox(value: value, onChanged: (v) => onChanged(v ?? false)),
          const SizedBox(width: 4),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4))),
        ]),
      );
}

// ---------------------------------------------------------------------------

class UnlockScreen extends StatefulWidget {
  const UnlockScreen({super.key});
  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  final _pass = TextEditingController();
  bool _busy = false;
  bool _deviceEnabled = false;
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final s = context.read<Session>();
    s.device.isEnabled(s.uid).then((v) {
      if (!mounted) return;
      setState(() => _deviceEnabled = v);
      if (v) _device();
    });
  }

  @override
  void dispose() {
    _pass.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    if (_pass.text.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<Session>().unlockWithPassphrase(_pass.text);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _device() async {
    final ok = await context.read<Session>().unlockWithDevice();
    if (!ok && mounted) setState(() => _error = 'Quick unlock was cancelled or unavailable.');
  }

  @override
  Widget build(BuildContext context) {
    final s = context.read<Session>();
    final g = GlassColors.of(context);
    return _AuthScaffold(children: [
      const Center(child: AmberOrb(icon: CupertinoIcons.lock_fill, size: 96)),
      const SizedBox(height: 28),
      const _Hero('Unlock your\nDossier.', subtitle: 'Enter your vault passphrase to decrypt your records on this device.'),
      TextField(
        controller: _pass,
        obscureText: _obscure,
        autofocus: !_deviceEnabled,
        onSubmitted: (_) => _unlock(),
        decoration: InputDecoration(
          labelText: 'Vault passphrase',
          errorText: _error,
          prefixIcon: const Icon(CupertinoIcons.lock_shield, size: 20),
          suffixIcon: IconButton(
            icon: Icon(_obscure ? CupertinoIcons.eye : CupertinoIcons.eye_slash, size: 20),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
      ),
      const SizedBox(height: 20),
      Row(children: [
        if (_deviceEnabled) ...[
          GlassIconButton(icon: Icons.fingerprint, size: 62, tooltip: 'Use biometrics', onPressed: _device),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: PillButton(
            label: _busy ? 'Deriving key…' : 'Unlock',
            icon: CupertinoIcons.lock_open_fill,
            busy: _busy,
            onPressed: _unlock,
          ),
        ),
      ]),
      const SizedBox(height: 14),
      TextButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecoveryScreen())),
        child: const Text('Forgot passphrase? Use recovery key'),
      ),
      TextButton(
        onPressed: s.signOut,
        style: TextButton.styleFrom(foregroundColor: g.muted),
        child: Text('Sign out · ${s.email}', overflow: TextOverflow.ellipsis),
      ),
    ]);
  }
}

class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key});
  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  final _form = GlobalKey<FormState>();
  final _key = TextEditingController();
  final _pass = TextEditingController();

  @override
  void dispose() {
    _key.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _recover() async {
    if (!_form.currentState!.validate()) return;
    final s = context.read<Session>();
    final ok = await runBusy(context, () async {
      await s.recover(_key.text, _pass.text);
      return true;
    }, label: 'Recovering vault…');
    if (ok == true && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => _AuthScaffold(
        leading: GlassIconButton(
            icon: CupertinoIcons.chevron_back, size: 44, tooltip: 'Back', onPressed: () => Navigator.pop(context)),
        children: [
          const _Hero('Recover\nyour vault.',
              eyebrow: 'Recovery',
              subtitle: 'Enter the recovery key you saved when you created your vault, then choose a new passphrase.'),
          Form(
            key: _form,
            child: Column(children: [
              TextFormField(
                controller: _key,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                    labelText: 'Recovery key',
                    hintText: 'XXXX-XXXX-XXXX-…',
                    prefixIcon: Icon(CupertinoIcons.number, size: 20)),
                style: const TextStyle(fontFamily: 'monospace'),
                validator: (v) =>
                    (v ?? '').replaceAll(RegExp(r'[\s-]'), '').length == 32 ? null : 'Recovery keys have 32 characters',
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _pass,
                obscureText: true,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                    labelText: 'New vault passphrase', prefixIcon: Icon(CupertinoIcons.lock_shield, size: 20)),
                validator: (v) => (v ?? '').length < 12 ? 'Use at least 12 characters' : null,
              ),
              const SizedBox(height: 12),
              PassphraseStrength(_pass.text),
              const SizedBox(height: 24),
              PillButton(label: 'Recover & set passphrase', onPressed: _recover),
            ]),
          ),
        ],
      );
}
