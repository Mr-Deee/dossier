// Key hierarchy for a user's Dossier.
//
//   Vault passphrase ──Argon2id──► KEK_pass ─┐
//   Recovery key ──────HKDF──────► KEK_rec  ─┼─ wrap ─► Master Key (MK, random 256-bit)
//                                            │
//   MK ── wraps ─► Keyring { category keys (life, wealth, vault, legacy, family,
//                            succession), X25519 identity private key }
//
//   Category key ── AES-GCM ─► every record in that category
//   Per-file key (inside the encrypted record) ── AES-GCM ─► uploaded file
//
// Firestore stores only the wrapped forms. Neither the passphrase, the recovery
// key, the MK nor any category key ever leaves the device unencrypted, so the
// database (and anyone with console access to it) sees only ciphertext.

import 'dart:convert';
import 'dart:typed_data';

import 'crypto_primitives.dart';

/// Pillars of the Dossier. Each has its own key so a confidant can be given
/// access to, say, "wealth" without "family".
class Categories {
  static const life = 'life';
  static const wealth = 'wealth';
  static const vault = 'vault';
  static const legacy = 'legacy';
  static const family = 'family';
  static const succession = 'succession';

  static const all = [life, wealth, vault, legacy, family, succession];

  static const labels = {
    life: 'My Life',
    wealth: 'My Wealth',
    vault: 'My Vault (documents)',
    legacy: 'My Legacy (will, wishes, messages)',
    family: 'My Family',
    succession: 'My Succession',
  };
}

typedef KdfFunction = Future<Uint8List> Function(String passphrase, KdfParams params);

class Keyring {
  Keyring({
    required this.masterKey,
    required this.categoryKeys,
    required this.identity,
  });

  final Uint8List masterKey;
  final Map<String, Uint8List> categoryKeys;
  final IdentityKeyPair identity;

  Uint8List keyFor(String category) {
    final k = categoryKeys[category];
    if (k == null) throw CryptoError('No key for category "$category"');
    return k;
  }

  String toJson() => jsonEncode({
        'v': 1,
        'cats': categoryKeys.map((k, v) => MapEntry(k, b64(v))),
        'idPriv': b64(identity.privateKey),
        'idPub': b64(identity.publicKey),
      });

  static Keyring fromJson(Uint8List masterKey, String json) {
    final m = jsonDecode(json) as Map<String, dynamic>;
    final cats = (m['cats'] as Map<String, dynamic>).map((k, v) => MapEntry(k, unb64(v as String)));
    return Keyring(
      masterKey: masterKey,
      categoryKeys: cats,
      identity: IdentityKeyPair(unb64(m['idPriv'] as String), unb64(m['idPub'] as String)),
    );
  }

  void wipeAll() {
    wipe(masterKey);
    categoryKeys.values.forEach(wipe);
    wipe(identity.privateKey);
  }
}

class VaultSetup {
  VaultSetup({required this.userDocFields, required this.recoveryKey, required this.keyring});

  /// Fields to merge into users/{uid}. Contains only ciphertext + public data.
  final Map<String, dynamic> userDocFields;

  /// Shown to the user exactly once. Never stored anywhere by the app.
  final String recoveryKey;
  final Keyring keyring;
}

class KeyManager {
  KeyManager({KdfFunction? kdf}) : _kdf = kdf ?? argon2idDerive;

  final KdfFunction _kdf;

  static String _aadMkPass(String uid) => 'dossier/v1/mk/passphrase/$uid';
  static String _aadMkRecovery(String uid) => 'dossier/v1/mk/recovery/$uid';
  static String _aadKeyring(String uid) => 'dossier/v1/keyring/$uid';

  static String recordAad(String ownerUid, String category, String recordId) =>
      'dossier/v1/record/$ownerUid/$category/$recordId';

  static String fileAad(String ownerUid, String category, String fileId) =>
      'dossier/v1/file/$ownerUid/$category/$fileId';

  /// Creates a brand-new vault for [uid].
  Future<VaultSetup> createVault(String uid, String passphrase, {KdfParams? params}) async {
    final kdf = params ?? KdfParams.generate();
    final mk = randomBytes(32);
    final identity = await generateIdentity();
    final keyring = Keyring(
      masterKey: mk,
      categoryKeys: {for (final c in Categories.all) c: randomBytes(32)},
      identity: identity,
    );

    final kekPass = await _kdf(passphrase, kdf);
    final recoveryBytes = randomBytes(20);
    final recoverySalt = randomBytes(16);
    final kekRec = await _recoveryKek(recoveryBytes, recoverySalt);

    final fields = <String, dynamic>{
      'schema': 1,
      'kdf': kdf.toMap(),
      'recoverySalt': b64(recoverySalt),
      'mkByPassphrase': await aeadSeal(kekPass, mk, aad: _aadMkPass(uid)),
      'mkByRecovery': await aeadSeal(kekRec, mk, aad: _aadMkRecovery(uid)),
      'keyring': await aeadSealString(mk, keyring.toJson(), aad: _aadKeyring(uid)),
      'publicKey': b64(identity.publicKey),
    };
    final recoveryKey = encodeRecoveryKey(recoveryBytes);
    wipe(kekPass);
    wipe(kekRec);
    wipe(recoveryBytes);
    return VaultSetup(userDocFields: fields, recoveryKey: recoveryKey, keyring: keyring);
  }

  Future<Uint8List> _recoveryKek(List<int> recoveryBytes, List<int> salt) =>
      hkdfSha256(recoveryBytes, salt: salt, info: 'dossier/v1/recovery-kek');

  /// Returns the master key, or throws [CryptoError] if the passphrase is wrong.
  Future<Uint8List> unlockWithPassphrase(String uid, Map<String, dynamic> userDoc, String passphrase) async {
    final params = KdfParams.fromMap(Map<String, dynamic>.from(userDoc['kdf'] as Map));
    final kek = await _kdf(passphrase, params);
    try {
      return await aeadOpen(kek, userDoc['mkByPassphrase'] as String, aad: _aadMkPass(uid));
    } on CryptoError {
      throw CryptoError('Incorrect vault passphrase');
    } finally {
      wipe(kek);
    }
  }

  Future<Uint8List> unlockWithRecoveryKey(String uid, Map<String, dynamic> userDoc, String recoveryKey) async {
    final bytes = decodeRecoveryKey(recoveryKey);
    final kek = await _recoveryKek(bytes, unb64(userDoc['recoverySalt'] as String));
    try {
      return await aeadOpen(kek, userDoc['mkByRecovery'] as String, aad: _aadMkRecovery(uid));
    } on CryptoError {
      throw CryptoError('That recovery key does not match this vault');
    } finally {
      wipe(kek);
      wipe(bytes);
    }
  }

  /// Verifies a master key (e.g. one cached on-device) by opening the keyring.
  Future<Keyring> openKeyring(String uid, Map<String, dynamic> userDoc, Uint8List mk) async {
    final json = await aeadOpenString(mk, userDoc['keyring'] as String, aad: _aadKeyring(uid));
    final keyring = Keyring.fromJson(mk, json);
    // Forward compatibility: add keys for categories introduced after setup.
    for (final c in Categories.all) {
      keyring.categoryKeys.putIfAbsent(c, () => randomBytes(32));
    }
    return keyring;
  }

  Future<String> sealKeyring(String uid, Keyring keyring) =>
      aeadSealString(keyring.masterKey, keyring.toJson(), aad: _aadKeyring(uid));

  /// Re-wraps the MK under a new passphrase. Records are untouched.
  Future<Map<String, dynamic>> changePassphrase(String uid, Uint8List mk, String newPassphrase) async {
    final kdf = KdfParams.generate();
    final kek = await _kdf(newPassphrase, kdf);
    final fields = {
      'kdf': kdf.toMap(),
      'mkByPassphrase': await aeadSeal(kek, mk, aad: _aadMkPass(uid)),
    };
    wipe(kek);
    return fields;
  }

  /// Issues a new recovery key; the old one stops working.
  Future<({Map<String, dynamic> fields, String recoveryKey})> rotateRecoveryKey(String uid, Uint8List mk) async {
    final bytes = randomBytes(20);
    final salt = randomBytes(16);
    final kek = await _recoveryKek(bytes, salt);
    final fields = {
      'recoverySalt': b64(salt),
      'mkByRecovery': await aeadSeal(kek, mk, aad: _aadMkRecovery(uid)),
    };
    final display = encodeRecoveryKey(bytes);
    wipe(kek);
    wipe(bytes);
    return (fields: fields, recoveryKey: display);
  }

  // ---- Sharing --------------------------------------------------------------

  static String grantContext(String ownerUid, String granteeUid) => 'grant/$ownerUid/$granteeUid';
  static String nominationContext(String ownerUid, String granteeUid) => 'nomination/$ownerUid/$granteeUid';

  /// Seals the selected category keys to a confidant's public key.
  Future<String> sealGrant({
    required Keyring keyring,
    required String ownerUid,
    required String granteeUid,
    required List<int> granteePublicKey,
    required List<String> categories,
  }) {
    final payload = jsonEncode({
      'owner': ownerUid,
      'cats': {for (final c in categories) c: b64(keyring.keyFor(c))},
    });
    return sealToPublicKey(granteePublicKey, utf8.encode(payload),
        context: grantContext(ownerUid, granteeUid));
  }

  /// Opens a grant addressed to me; returns category -> key.
  Future<Map<String, Uint8List>> openGrant({
    required Keyring myKeyring,
    required String ownerUid,
    required String myUid,
    required String sealed,
  }) async {
    final clear = await openSealed(myKeyring.identity, sealed, context: grantContext(ownerUid, myUid));
    final m = jsonDecode(utf8.decode(clear)) as Map<String, dynamic>;
    if (m['owner'] != ownerUid) throw CryptoError('Grant owner mismatch');
    return (m['cats'] as Map<String, dynamic>).map((k, v) => MapEntry(k, unb64(v as String)));
  }
}
