import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import '../crypto/crypto_primitives.dart';

/// Optional "unlock with biometrics on this device".
///
/// When enabled, the vault master key is kept in the platform keystore
/// (Android Keystore-backed EncryptedSharedPreferences / iOS Keychain,
/// this-device-only) and released after a successful biometric or device
/// credential check. It never leaves the device and is not backed up.
class DeviceUnlock {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.unlocked_this_device),
  );

  final LocalAuthentication _auth = LocalAuthentication();

  String _mkKey(String uid) => 'dossier.mk.$uid';

  Future<bool> isSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  Future<bool> isEnabled(String uid) => _storage.containsKey(key: _mkKey(uid));

  Future<bool> enable(String uid, Uint8List masterKey) async {
    final ok = await _authenticate('Confirm to enable quick unlock');
    if (!ok) return false;
    await _storage.write(key: _mkKey(uid), value: b64(masterKey));
    return true;
  }

  Future<void> disable(String uid) => _storage.delete(key: _mkKey(uid));

  /// Returns the stored master key after authentication, or null.
  Future<Uint8List?> unlock(String uid) async {
    if (!await isEnabled(uid)) return null;
    final ok = await _authenticate('Unlock your Dossier');
    if (!ok) return null;
    final v = await _storage.read(key: _mkKey(uid));
    return v == null ? null : unb64(v);
  }

  Future<bool> _authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(stickyAuth: true),
      );
    } on PlatformException {
      return false;
    }
  }
}
