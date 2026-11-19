import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/services/local_notifications.dart';
import 'core/services/push.dart';
import 'core/services/session.dart';
import 'core/services/succession_service.dart';
import 'core/services/vault_repository.dart';
import 'firebase_options.dart';
import 'ui/screens/auth.dart';
import 'ui/screens/onboarding.dart';
import 'ui/screens/shell.dart';
import 'ui/theme.dart';
import 'ui/widgets/common.dart';
import 'ui/widgets/file_actions.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await purgeDecryptedTemp();
  await LocalNotifications.init();
  await Push.listenForTaps();
  final prefs = await SharedPreferences.getInstance();
  final onboarded = prefs.getBool(_onboardedKey) ?? false;

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider<Session>(create: (_) => Session()),
      ChangeNotifierProvider<VaultRepository>(create: (c) => VaultRepository(c.read<Session>())),
      ProxyProvider2<Session, VaultRepository, SuccessionService>(
        update: (_, s, r, prev) => prev ?? SuccessionService(s, r),
      ),
    ],
    child: DossierApp(onboarded: onboarded),
  ));
}

const _onboardedKey = 'onboarding_complete';

class DossierApp extends StatelessWidget {
  const DossierApp({super.key, required this.onboarded});
  final bool onboarded;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final pref = (session.userDoc['prefs'] as Map?)?['theme'] as String?;
    return MaterialApp(
      title: 'The Dossier',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: switch (pref) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      home: _Gate(onboarded: onboarded),
    );
  }
}

class _Gate extends StatefulWidget {
  const _Gate({required this.onboarded});
  final bool onboarded;
  @override
  State<_Gate> createState() => _GateState();
}

class _GateState extends State<_Gate> {
  SessionState? _last;
  late bool _onboarded = widget.onboarded;
  bool _showOnboarding = false;
  bool _registerFirst = false;

  Future<void> _finishOnboarding({required bool register}) async {
    setState(() {
      _onboarded = true;
      _showOnboarding = false;
      _registerFirst = register;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardedKey, true);
    } catch (_) {/* not critical: onboarding simply shows again next launch */}
  }

  Widget _signedOut() {
    if (_showOnboarding) {
      return OnboardingScreen(key: const ValueKey('onboarding'), onFinish: _finishOnboarding);
    }
    return SignInScreen(
      key: ValueKey('signin-$_registerFirst'),
      initialRegister: _registerFirst,
      onBack: () => setState(() => _showOnboarding = true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.select<Session, SessionState>((s) => s.state);
    if (_last == SessionState.unlocked && state != SessionState.unlocked) {
      // Vault locked or signed out: close any open screens and remove decrypted temp files.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).popUntil((r) => r.isFirst);
        purgeDecryptedTemp();
      });
    }
    _last = state;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOutCubic,
      // First launch shows the introduction whatever the sign-in state.
      child: !_onboarded
          ? OnboardingScreen(
              key: const ValueKey('onboarding-first'),
              signedIn: state != SessionState.signedOut && state != SessionState.loading,
              onFinish: _finishOnboarding,
            )
          : switch (state) {
              SessionState.loading => const Scaffold(
                  key: ValueKey('loading'),
                  body: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      AppLogo(size: 112, glow: true),
                      SizedBox(height: 22),
                      Wordmark(size: 30, showLogo: false),
                    ]),
                  ),
                ),
              SessionState.signedOut => _signedOut(),
              SessionState.needsSetup => const VaultSetupScreen(key: ValueKey('setup')),
              SessionState.locked => const UnlockScreen(key: ValueKey('unlock')),
              SessionState.unlocked => const Shell(key: ValueKey('shell')),
            },
    );
  }
}
