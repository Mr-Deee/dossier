import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../crypto/crypto_primitives.dart';
import '../crypto/key_manager.dart';
import 'device_unlock.dart';
import 'firebase_refs.dart';

enum SessionState { loading, signedOut, needsSetup, locked, unlocked }

// Argon2id is CPU/memory heavy: run it on a background isolate so the UI stays responsive.
Future<Uint8List> _kdfInIsolate(String passphrase, KdfParams params) =>
    compute(_kdfEntry, <Object>[passphrase, params.toMap()]);

Future<Uint8List> _kdfEntry(List<Object> args) =>
    argon2idDerive(args[0] as String, KdfParams.fromMap(Map<String, dynamic>.from(args[1] as Map)));

String normaliseEmail(String email) => email.trim().toLowerCase();

/// Owns authentication state and the in-memory keyring.
///
/// The keyring exists only while the vault is unlocked; locking wipes it.
class Session extends ChangeNotifier with WidgetsBindingObserver {
  Session() {
    WidgetsBinding.instance.addObserver(this);
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  final KeyManager keys = KeyManager(kdf: _kdfInIsolate);
  final DeviceUnlock device = DeviceUnlock();

  late final StreamSubscription<User?> _authSub;
  SessionState state = SessionState.loading;
  User? user;
  Map<String, dynamic> userDoc = {};
  Keyring? _keyring;
  bool isVerifier = false;
  String? pendingRecoveryKey;
  DateTime? _pausedAt;

  String get uid => user!.uid;
  String get email => user?.email ?? '';
  Keyring get keyring => _keyring ?? (throw StateError('Vault is locked'));
  bool get isUnlocked => _keyring != null;
  int get autoLockMinutes => ((userDoc['prefs'] as Map?)?['autoLockMinutes'] as num?)?.toInt() ?? 5;
  String get displayCurrency => ((userDoc['prefs'] as Map?)?['currency'] as String?) ?? 'GHS';
  Map<String, dynamic> get lifeCheck => Map<String, dynamic>.from((userDoc['lifeCheck'] as Map?) ?? const {});

  void _set(SessionState s) {
    state = s;
    notifyListeners();
  }

  Future<void> _onAuthChanged(User? u) async {
    _wipeKeys();
    user = u;
    if (u == null) {
      userDoc = {};
      isVerifier = false;
      _set(SessionState.signedOut);
      return;
    }
    await refresh();
  }

  /// Re-reads auth + vault metadata and decides which screen to show.
  Future<void> refresh() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) { _set(SessionState.signedOut); return; }
    try {
      await u.reload();
    } catch (_) {/* offline: continue with cached user */}
    user = FirebaseAuth.instance.currentUser;
    try {
      final token = await user!.getIdTokenResult(true);
      isVerifier = token.claims?['verifier'] == true;
    } catch (_) {
      isVerifier = false;
    }
    try {
      final snap = await Refs.user(uid).get();
      userDoc = snap.data() ?? {};
    } catch (e) {
      debugPrint('Could not load vault metadata, retrying: $e');
      Future.delayed(const Duration(seconds: 3), refresh);
      return;
    }
    if (pendingRecoveryKey != null) { _set(SessionState.needsSetup); return; }
    if (!userDoc.containsKey('mkByPassphrase')) { _set(SessionState.needsSetup); return; }
    _set(isUnlocked ? SessionState.unlocked : SessionState.locked);
  }

  // ---- Auth -----------------------------------------------------------------

  /// Creates the account and signs straight in — no email verification step.
  Future<void> register(String email, String password) async {
    await FirebaseAuth.instance.createUserWithEmailAndPassword(email: normaliseEmail(email), password: password);
  }

  Future<void> signIn(String email, String password) =>
      FirebaseAuth.instance.signInWithEmailAndPassword(email: normaliseEmail(email), password: password);

  Future<void> resetAccountPassword(String email) =>
      FirebaseAuth.instance.sendPasswordResetEmail(email: normaliseEmail(email));

  Future<void> signOut() async {
    _wipeKeys();
    await FirebaseAuth.instance.signOut();
  }

  // ---- Vault lifecycle ------------------------------------------------------

  /// Step 1 of setup: creates keys, stores only wrapped keys, returns the
  /// recovery key for the user to write down. Vault stays "needsSetup" until
  /// [confirmRecoverySaved].
  Future<String> createVault(String passphrase) async {
    final setup = await keys.createVault(uid, passphrase);
    final now = DateTime.now();
    await Refs.user(uid).set({
      ...setup.userDocFields,
      'createdAt': FieldValue.serverTimestamp(),
      'prefs': {'autoLockMinutes': 5, 'currency': 'GHS'},
      'lifeCheck': {
        'enabled': true,
        'intervalDays': 30,
        'lastCheckIn': Timestamp.fromDate(now),
        'nextDue': Timestamp.fromDate(now.add(const Duration(days: 30))),
        'missed': 0,
      },
    }, SetOptions(merge: true));
    _keyring = setup.keyring;
    pendingRecoveryKey = setup.recoveryKey;
    await _publishDirectoryEntry();
    final snap = await Refs.user(uid).get();
    userDoc = snap.data() ?? {};
    notifyListeners();
    return setup.recoveryKey;
  }

  void confirmRecoverySaved() {
    pendingRecoveryKey = null;
    _set(SessionState.unlocked);
  }

  Future<void> unlockWithPassphrase(String passphrase) async {
    final mk = await keys.unlockWithPassphrase(uid, userDoc, passphrase);
    await _openWith(mk);
  }

  Future<bool> unlockWithDevice() async {
    final mk = await device.unlock(uid);
    if (mk == null) return false;
    try {
      await _openWith(mk);
      return true;
    } on CryptoError {
      await device.disable(uid); // stale key on device
      return false;
    }
  }

  /// Forgotten passphrase: recovery key opens the vault and sets a new passphrase.
  Future<void> recover(String recoveryKey, String newPassphrase) async {
    final mk = await keys.unlockWithRecoveryKey(uid, userDoc, recoveryKey);
    final fields = await keys.changePassphrase(uid, mk, newPassphrase);
    await Refs.user(uid).update(fields);
    userDoc.addAll(fields);
    await _openWith(mk);
  }

  Future<void> _openWith(Uint8List mk) async {
    _keyring = await keys.openKeyring(uid, userDoc, mk);
    await _publishDirectoryEntry();
    _set(SessionState.unlocked);
  }

  /// Publishes {uid, publicKey} under sha256(email) so other users can name
  /// this person as a confidant. Contains no private data.
  Future<void> _publishDirectoryEntry() async {
    if (_keyring == null || user?.email == null) return;
    try {
      final hash = await sha256Hex(normaliseEmail(user!.email!));
      await Refs.directory(hash).set({
        'uid': uid,
        'publicKey': b64(_keyring!.identity.publicKey),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Directory publish failed: $e');
    }
  }

  void lock() {
    if (!isUnlocked) return;
    _wipeKeys();
    _set(SessionState.locked);
  }

  void _wipeKeys() {
    _keyring?.wipeAll();
    _keyring = null;
  }

  // ---- Settings ---------------------------------------------------------------

  Future<void> changePassphrase(String current, String next) async {
    await keys.unlockWithPassphrase(uid, userDoc, current); // verifies current
    final fields = await keys.changePassphrase(uid, keyring.masterKey, next);
    await Refs.user(uid).update(fields);
    userDoc.addAll(fields);
    notifyListeners();
  }

  Future<String> rotateRecoveryKey() async {
    final r = await keys.rotateRecoveryKey(uid, keyring.masterKey);
    await Refs.user(uid).update(r.fields);
    userDoc.addAll(r.fields);
    return r.recoveryKey;
  }

  Future<void> updatePrefs(Map<String, dynamic> prefs) async {
    final merged = {...?(userDoc['prefs'] as Map?)?.cast<String, dynamic>(), ...prefs};
    await Refs.user(uid).set({'prefs': merged}, SetOptions(merge: true));
    userDoc['prefs'] = merged;
    notifyListeners();
  }

  Future<String> keyFingerprint() => fingerprint(keyring.identity.publicKey);

  // ---- Life Check -------------------------------------------------------------

  Future<void> checkIn() async {
    final now = DateTime.now();
    final days = (lifeCheck['intervalDays'] as num?)?.toInt() ?? 30;
    final lc = {
      ...lifeCheck,
      'lastCheckIn': Timestamp.fromDate(now),
      'nextDue': Timestamp.fromDate(now.add(Duration(days: days))),
      'missed': 0,
      'pausedUntil': null,
    };
    await Refs.user(uid).set({'lifeCheck': lc}, SetOptions(merge: true));
    userDoc['lifeCheck'] = lc;
    notifyListeners();
  }

  Future<void> configureLifeCheck({bool? enabled, int? intervalDays, DateTime? pausedUntil, bool clearPause = false}) async {
    final lc = {...lifeCheck};
    if (enabled != null) lc['enabled'] = enabled;
    if (intervalDays != null) {
      lc['intervalDays'] = intervalDays;
      final last = tsToDate(lc['lastCheckIn']) ?? DateTime.now();
      lc['nextDue'] = Timestamp.fromDate(last.add(Duration(days: intervalDays)));
    }
    if (pausedUntil != null) lc['pausedUntil'] = Timestamp.fromDate(pausedUntil);
    if (clearPause) lc['pausedUntil'] = null;
    await Refs.user(uid).set({'lifeCheck': lc}, SetOptions(merge: true));
    userDoc['lifeCheck'] = lc;
    notifyListeners();
  }

  // ---- Auto-lock --------------------------------------------------------------

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.paused || s == AppLifecycleState.hidden) {
      _pausedAt ??= DateTime.now();
    } else if (s == AppLifecycleState.resumed) {
      final p = _pausedAt;
      _pausedAt = null;
      if (p != null && isUnlocked && DateTime.now().difference(p).inMinutes >= autoLockMinutes) {
        lock();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSub.cancel();
    _wipeKeys();
    super.dispose();
  }
}
