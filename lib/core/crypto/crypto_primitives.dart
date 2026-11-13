// Low-level cryptographic building blocks for The Dossier.
//
// Everything here is pure Dart (no Flutter imports) so it can be unit tested
// on the Dart VM. Algorithms:
//   * AES-256-GCM            authenticated encryption of records, keys, files
//   * Argon2id               passphrase -> key-encryption-key (memory hard)
//   * HKDF-SHA256            key derivation from random secrets / ECDH output
//   * X25519                 sealing keys to another user (sharing/succession)
//   * SHA-256                fingerprints, email hashing
//
// Text ciphertext format:  g1.<nonce>.<ciphertext>.<mac>      (base64url, no padding)
// Sealed-to-user format:   x1.<ephemeralPublicKey>.<g1 ciphertext>
// Binary file format:      "DSF1" | nonce(12) | ciphertext | mac(16)

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

class CryptoError implements Exception {
  CryptoError(this.message);
  final String message;
  @override
  String toString() => 'CryptoError: $message';
}

final Random _rng = Random.secure();

Uint8List randomBytes(int length) {
  final out = Uint8List(length);
  for (var i = 0; i < length; i++) {
    out[i] = _rng.nextInt(256);
  }
  return out;
}

String b64(List<int> bytes) => base64Url.encode(bytes).replaceAll('=', '');

Uint8List unb64(String s) => Uint8List.fromList(base64Url.decode(base64Url.normalize(s)));

/// Overwrites key material in memory. Dart cannot guarantee no copies were
/// made by the runtime, but this removes the copies we control.
void wipe(Uint8List? bytes) {
  if (bytes == null) return;
  for (var i = 0; i < bytes.length; i++) {
    bytes[i] = 0;
  }
}

// ---------------------------------------------------------------------------
// AES-256-GCM
// ---------------------------------------------------------------------------

final AesGcm _aes = AesGcm.with256bits();
const int _nonceLength = 12;
const int _macLength = 16;
const String _textPrefix = 'g1';
const List<int> _fileMagic = [0x44, 0x53, 0x46, 0x31]; // "DSF1"

/// Encrypts [plaintext] with a 32-byte [key]. [aad] binds the ciphertext to
/// its context (owner, category, record id) so it cannot be swapped elsewhere.
Future<String> aeadSeal(List<int> key, List<int> plaintext, {required String aad}) async {
  _checkKey(key);
  final box = await _aes.encrypt(
    plaintext,
    secretKey: SecretKey(List<int>.of(key)),
    nonce: randomBytes(_nonceLength),
    aad: utf8.encode(aad),
  );
  return '$_textPrefix.${b64(box.nonce)}.${b64(box.cipherText)}.${b64(box.mac.bytes)}';
}

Future<Uint8List> aeadOpen(List<int> key, String sealed, {required String aad}) async {
  _checkKey(key);
  final parts = sealed.split('.');
  if (parts.length != 4 || parts[0] != _textPrefix) {
    throw CryptoError('Unsupported ciphertext format');
  }
  try {
    final clear = await _aes.decrypt(
      SecretBox(unb64(parts[2]), nonce: unb64(parts[1]), mac: Mac(unb64(parts[3]))),
      secretKey: SecretKey(List<int>.of(key)),
      aad: utf8.encode(aad),
    );
    return Uint8List.fromList(clear);
  } on SecretBoxAuthenticationError {
    throw CryptoError('Decryption failed: wrong key or data was modified');
  } on FormatException {
    throw CryptoError('Corrupted ciphertext');
  }
}

Future<String> aeadSealString(List<int> key, String text, {required String aad}) =>
    aeadSeal(key, utf8.encode(text), aad: aad);

Future<String> aeadOpenString(List<int> key, String sealed, {required String aad}) async =>
    utf8.decode(await aeadOpen(key, sealed, aad: aad));

/// Binary variant for files (avoids base64 overhead in Cloud Storage).
Future<Uint8List> aeadSealBytes(List<int> key, List<int> plaintext, {required String aad}) async {
  _checkKey(key);
  final nonce = randomBytes(_nonceLength);
  final box = await _aes.encrypt(
    plaintext,
    secretKey: SecretKey(List<int>.of(key)),
    nonce: nonce,
    aad: utf8.encode(aad),
  );
  final out = BytesBuilder(copy: false)
    ..add(_fileMagic)
    ..add(nonce)
    ..add(box.cipherText)
    ..add(box.mac.bytes);
  return out.toBytes();
}

Future<Uint8List> aeadOpenBytes(List<int> key, List<int> data, {required String aad}) async {
  _checkKey(key);
  const header = 4 + _nonceLength;
  if (data.length < header + _macLength) throw CryptoError('Encrypted file is truncated');
  for (var i = 0; i < 4; i++) {
    if (data[i] != _fileMagic[i]) throw CryptoError('Not a Dossier encrypted file');
  }
  final nonce = data.sublist(4, header);
  final cipherText = data.sublist(header, data.length - _macLength);
  final mac = data.sublist(data.length - _macLength);
  try {
    final clear = await _aes.decrypt(
      SecretBox(cipherText, nonce: nonce, mac: Mac(mac)),
      secretKey: SecretKey(List<int>.of(key)),
      aad: utf8.encode(aad),
    );
    return Uint8List.fromList(clear);
  } on SecretBoxAuthenticationError {
    throw CryptoError('File decryption failed: wrong key or file was modified');
  }
}

void _checkKey(List<int> key) {
  if (key.length != 32) throw CryptoError('Keys must be 32 bytes');
}

// ---------------------------------------------------------------------------
// Key derivation
// ---------------------------------------------------------------------------

/// Argon2id parameters, stored (non-secret) with the user's vault so they can
/// be raised later without breaking existing vaults.
class KdfParams {
  const KdfParams({
    required this.salt,
    this.memoryKiB = 19456, // 19 MiB — OWASP 2024 minimum for Argon2id
    this.iterations = 2,
    this.parallelism = 1,
  });

  factory KdfParams.generate() => KdfParams(salt: b64(randomBytes(16)));

  factory KdfParams.fromMap(Map<String, dynamic> m) {
    if (m['alg'] != 'argon2id') throw CryptoError('Unsupported KDF ${m['alg']}');
    return KdfParams(
      salt: m['salt'] as String,
      memoryKiB: (m['memoryKiB'] as num).toInt(),
      iterations: (m['iterations'] as num).toInt(),
      parallelism: (m['parallelism'] as num).toInt(),
    );
  }

  final String salt;
  final int memoryKiB;
  final int iterations;
  final int parallelism;

  Map<String, dynamic> toMap() => {
        'alg': 'argon2id',
        'salt': salt,
        'memoryKiB': memoryKiB,
        'iterations': iterations,
        'parallelism': parallelism,
      };
}

/// Passphrase -> 32-byte key-encryption-key. CPU/memory heavy by design:
/// call it off the UI thread (see KeyManager's `kdf` hook).
Future<Uint8List> argon2idDerive(String passphrase, KdfParams p) async {
  final algo = Argon2id(
    memory: p.memoryKiB,
    iterations: p.iterations,
    parallelism: p.parallelism,
    hashLength: 32,
  );
  final key = await algo.deriveKey(
    secretKey: SecretKey(utf8.encode(passphrase)),
    nonce: unb64(p.salt),
  );
  return Uint8List.fromList(await key.extractBytes());
}

Future<Uint8List> hkdfSha256(List<int> ikm, {required List<int> salt, required String info, int length = 32}) async {
  final h = Hkdf(hmac: Hmac.sha256(), outputLength: length);
  final key = await h.deriveKey(secretKey: SecretKey(List<int>.of(ikm)), nonce: salt, info: utf8.encode(info));
  return Uint8List.fromList(await key.extractBytes());
}

Future<Uint8List> sha256(List<int> data) async => Uint8List.fromList((await Sha256().hash(data)).bytes);

Future<String> sha256Hex(String text) async => hex(await sha256(utf8.encode(text)));

String hex(List<int> bytes) => bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

// ---------------------------------------------------------------------------
// X25519 sealing (ECIES-style) — used to hand keys to trusted confidants
// ---------------------------------------------------------------------------

final X25519 _x25519 = X25519();

class IdentityKeyPair {
  IdentityKeyPair(this.privateKey, this.publicKey);
  final Uint8List privateKey;
  final Uint8List publicKey;
}

Future<IdentityKeyPair> generateIdentity() async {
  final kp = await _x25519.newKeyPair();
  final priv = Uint8List.fromList(await kp.extractPrivateKeyBytes());
  final pub = Uint8List.fromList((await kp.extractPublicKey()).bytes);
  return IdentityKeyPair(priv, pub);
}

/// Encrypts [plaintext] so only the holder of the private key matching
/// [recipientPublicKey] can open it. [context] is bound into the key
/// derivation and AAD (e.g. "grant/<owner>/<grantee>").
Future<String> sealToPublicKey(List<int> recipientPublicKey, List<int> plaintext, {required String context}) async {
  final eph = await _x25519.newKeyPair();
  final ephPub = (await eph.extractPublicKey()).bytes;
  final shared = await _x25519.sharedSecretKey(
    keyPair: eph,
    remotePublicKey: SimplePublicKey(List<int>.of(recipientPublicKey), type: KeyPairType.x25519),
  );
  final key = await hkdfSha256(
    await shared.extractBytes(),
    salt: [...ephPub, ...recipientPublicKey],
    info: 'dossier/v1/seal/$context',
  );
  final inner = await aeadSeal(key, plaintext, aad: 'dossier/v1/seal/$context');
  wipe(key);
  return 'x1.${b64(ephPub)}.$inner';
}

Future<Uint8List> openSealed(IdentityKeyPair me, String sealed, {required String context}) async {
  final i1 = sealed.indexOf('.');
  final i2 = i1 < 0 ? -1 : sealed.indexOf('.', i1 + 1);
  if (i1 < 0 || i2 < 0 || sealed.substring(0, i1) != 'x1') {
    throw CryptoError('Unsupported sealed format');
  }
  final ephPub = unb64(sealed.substring(i1 + 1, i2));
  final inner = sealed.substring(i2 + 1);
  final kp = await _x25519.newKeyPairFromSeed(List<int>.of(me.privateKey));
  final shared = await _x25519.sharedSecretKey(
    keyPair: kp,
    remotePublicKey: SimplePublicKey(ephPub, type: KeyPairType.x25519),
  );
  final key = await hkdfSha256(
    await shared.extractBytes(),
    salt: [...ephPub, ...me.publicKey],
    info: 'dossier/v1/seal/$context',
  );
  try {
    return await aeadOpen(key, inner, aad: 'dossier/v1/seal/$context');
  } finally {
    wipe(key);
  }
}

/// Human-comparable fingerprint of a public key, e.g. "3F2A 9C10 77B4 E0D1 5A6B".
Future<String> fingerprint(List<int> publicKey) async {
  final h = hex(await sha256(publicKey)).toUpperCase().substring(0, 20);
  return [for (var i = 0; i < h.length; i += 4) h.substring(i, i + 4)].join(' ');
}

// ---------------------------------------------------------------------------
// Recovery key encoding (Crockford base32, grouped for readability)
// ---------------------------------------------------------------------------

const String _crockford = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

String encodeRecoveryKey(List<int> bytes) {
  var buffer = 0;
  var bits = 0;
  final out = StringBuffer();
  for (final b in bytes) {
    buffer = (buffer << 8) | b;
    bits += 8;
    while (bits >= 5) {
      out.write(_crockford[(buffer >> (bits - 5)) & 31]);
      bits -= 5;
    }
  }
  if (bits > 0) out.write(_crockford[(buffer << (5 - bits)) & 31]);
  final s = out.toString();
  return [for (var i = 0; i < s.length; i += 4) s.substring(i, min(i + 4, s.length))].join('-');
}

Uint8List decodeRecoveryKey(String input, {int expectedBytes = 20}) {
  final clean = input
      .toUpperCase()
      .replaceAll(RegExp(r'[\s-]'), '')
      .replaceAll('I', '1')
      .replaceAll('L', '1')
      .replaceAll('O', '0');
  var buffer = 0;
  var bits = 0;
  final out = <int>[];
  for (final ch in clean.split('')) {
    final v = _crockford.indexOf(ch);
    if (v < 0) throw CryptoError('Recovery key contains an invalid character "$ch"');
    buffer = ((buffer << 5) | v) & 0xFFFF;
    bits += 5;
    if (bits >= 8) {
      out.add((buffer >> (bits - 8)) & 0xFF);
      bits -= 8;
    }
  }
  if (out.length != expectedBytes) throw CryptoError('Recovery key has the wrong length');
  return Uint8List.fromList(out);
}
