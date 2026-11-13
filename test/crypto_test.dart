// Run with: flutter test
import 'dart:convert';
import 'dart:typed_data';

import 'package:dossier/core/crypto/crypto_primitives.dart';
import 'package:dossier/core/crypto/key_manager.dart';
import 'package:flutter_test/flutter_test.dart';

// Low-cost Argon2id parameters so tests run fast. Production uses 19 MiB / t=2.
KdfParams fastKdf() => KdfParams(salt: b64(randomBytes(16)), memoryKiB: 64, iterations: 1);

void main() {
  group('AES-256-GCM', () {
    test('round-trips text and rejects wrong AAD / key / tampering', () async {
      final key = randomBytes(32);
      final sealed = await aeadSealString(key, 'Title deed: East Legon', aad: 'ctx-a');
      expect(sealed.startsWith('g1.'), isTrue);
      expect(sealed.contains('East Legon'), isFalse);
      expect(await aeadOpenString(key, sealed, aad: 'ctx-a'), 'Title deed: East Legon');

      expect(() => aeadOpenString(key, sealed, aad: 'ctx-b'), throwsA(isA<CryptoError>()));
      expect(() => aeadOpenString(randomBytes(32), sealed, aad: 'ctx-a'), throwsA(isA<CryptoError>()));

      final parts = sealed.split('.');
      final ct = unb64(parts[2]);
      ct[0] ^= 1;
      final tampered = [parts[0], parts[1], b64(ct), parts[3]].join('.');
      expect(() => aeadOpenString(key, tampered, aad: 'ctx-a'), throwsA(isA<CryptoError>()));
    });

    test('ciphertext matches the shape enforced by firestore.rules', () async {
      final sealed = await aeadSealString(randomBytes(32), jsonEncode({'k': 'property'}), aad: 'x');
      final rule = RegExp(r'^g1\.[A-Za-z0-9_-]{16}\.[A-Za-z0-9_-]*\.[A-Za-z0-9_-]{22}$');
      expect(rule.hasMatch(sealed), isTrue);
    });

    test('binary file format round-trips', () async {
      final key = randomBytes(32);
      final data = Uint8List.fromList(List.generate(100000, (i) => i % 251));
      final enc = await aeadSealBytes(key, data, aad: 'file');
      expect(enc.sublist(0, 4), [0x44, 0x53, 0x46, 0x31]);
      expect(await aeadOpenBytes(key, enc, aad: 'file'), data);
      enc[enc.length - 1] ^= 1;
      expect(() => aeadOpenBytes(key, enc, aad: 'file'), throwsA(isA<CryptoError>()));
    });

    test('nonces are unique', () async {
      final key = randomBytes(32);
      final a = await aeadSealString(key, 'same', aad: 'x');
      final b = await aeadSealString(key, 'same', aad: 'x');
      expect(a, isNot(b));
    });
  });

  group('Recovery key encoding', () {
    test('round-trips and tolerates formatting/ambiguous characters', () {
      final bytes = randomBytes(20);
      final text = encodeRecoveryKey(bytes);
      expect(text.replaceAll('-', '').length, 32);
      expect(decodeRecoveryKey(text), bytes);
      expect(decodeRecoveryKey(text.toLowerCase().replaceAll('-', ' ')), bytes);
      expect(() => decodeRecoveryKey('ABCD-EFGH'), throwsA(isA<CryptoError>()));
    });
  });

  group('X25519 sealing', () {
    test('only the intended recipient and context can open', () async {
      final alice = await generateIdentity();
      final mallory = await generateIdentity();
      final sealed = await sealToPublicKey(alice.publicKey, utf8.encode('secret'), context: 'grant/o/a');
      expect(RegExp(r'^x1\.[A-Za-z0-9_-]{43}\.g1\..+$').hasMatch(sealed), isTrue);
      expect(utf8.decode(await openSealed(alice, sealed, context: 'grant/o/a')), 'secret');
      expect(() => openSealed(mallory, sealed, context: 'grant/o/a'), throwsA(isA<CryptoError>()));
      expect(() => openSealed(alice, sealed, context: 'grant/o/b'), throwsA(isA<CryptoError>()));
    });

    test('fingerprint is stable and formatted', () async {
      final id = await generateIdentity();
      final fp = await fingerprint(id.publicKey);
      expect(fp, await fingerprint(id.publicKey));
      expect(RegExp(r'^([0-9A-F]{4} ){4}[0-9A-F]{4}$').hasMatch(fp), isTrue);
    });
  });

  group('KeyManager', () {
    final km = KeyManager();

    test('create → unlock with passphrase → open keyring', () async {
      final setup = await km.createVault('uid1', 'correct horse battery staple', params: fastKdf());
      final doc = setup.userDocFields;
      expect(doc.values.whereType<String>().any((v) => v.contains('correct horse')), isFalse);
      final mk = await km.unlockWithPassphrase('uid1', doc, 'correct horse battery staple');
      final kr = await km.openKeyring('uid1', doc, mk);
      for (final c in Categories.all) {
        expect(kr.keyFor(c), setup.keyring.keyFor(c));
      }
      expect(kr.identity.publicKey, setup.keyring.identity.publicKey);
    });

    test('wrong passphrase and wrong uid are rejected', () async {
      final setup = await km.createVault('uid1', 'passphrase-number-one', params: fastKdf());
      expect(() => km.unlockWithPassphrase('uid1', setup.userDocFields, 'nope-nope-nope'), throwsA(isA<CryptoError>()));
      // Copying a vault blob to another account fails because AAD binds the uid.
      expect(() => km.unlockWithPassphrase('uid2', setup.userDocFields, 'passphrase-number-one'),
          throwsA(isA<CryptoError>()));
    });

    test('recovery key recovers the same master key; rotation invalidates old key', () async {
      final setup = await km.createVault('u', 'first passphrase 123', params: fastKdf());
      final doc = Map<String, dynamic>.from(setup.userDocFields);
      final mk1 = await km.unlockWithPassphrase('u', doc, 'first passphrase 123');
      final mk2 = await km.unlockWithRecoveryKey('u', doc, setup.recoveryKey);
      expect(mk2, mk1);

      doc.addAll(await km.changePassphrase('u', mk1, 'second passphrase 456'));
      expect(await km.unlockWithPassphrase('u', doc, 'second passphrase 456'), mk1);

      final rotated = await km.rotateRecoveryKey('u', mk1);
      doc.addAll(rotated.fields);
      expect(await km.unlockWithRecoveryKey('u', doc, rotated.recoveryKey), mk1);
      expect(() => km.unlockWithRecoveryKey('u', doc, setup.recoveryKey), throwsA(isA<CryptoError>()));
    });

    test('grant gives confidant only the selected category keys', () async {
      final owner = await km.createVault('owner', 'owner passphrase 1', params: fastKdf());
      final friend = await km.createVault('friend', 'friend passphrase 1', params: fastKdf());
      final sealed = await km.sealGrant(
        keyring: owner.keyring,
        ownerUid: 'owner',
        granteeUid: 'friend',
        granteePublicKey: friend.keyring.identity.publicKey,
        categories: [Categories.wealth, Categories.legacy],
      );
      final keys = await km.openGrant(myKeyring: friend.keyring, ownerUid: 'owner', myUid: 'friend', sealed: sealed);
      expect(keys.keys.toSet(), {Categories.wealth, Categories.legacy});
      expect(keys[Categories.wealth], owner.keyring.keyFor(Categories.wealth));

      // A record the owner encrypted can now be read by the friend…
      final blob = await aeadSealString(owner.keyring.keyFor(Categories.wealth), '{"k":"property"}',
          aad: KeyManager.recordAad('owner', Categories.wealth, 'r1'));
      expect(await aeadOpenString(keys[Categories.wealth]!, blob, aad: KeyManager.recordAad('owner', Categories.wealth, 'r1')),
          '{"k":"property"}');
      // …but a stranger cannot open the grant.
      final stranger = await km.createVault('x', 'stranger passphrase', params: fastKdf());
      expect(() => km.openGrant(myKeyring: stranger.keyring, ownerUid: 'owner', myUid: 'x', sealed: sealed),
          throwsA(isA<CryptoError>()));
    });
  });

  test('production Argon2id parameters derive a 32-byte key', () async {
    final k = await argon2idDerive('a long vault passphrase', KdfParams.generate());
    expect(k.length, 32);
  }, timeout: const Timeout(Duration(minutes: 2)));
}
