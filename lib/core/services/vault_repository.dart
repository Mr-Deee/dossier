import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../crypto/crypto_primitives.dart';
import '../crypto/key_manager.dart';
import '../models/record.dart';
import '../schema/record_types.dart';
import 'firebase_refs.dart';
import 'session.dart';

const int maxFileBytes = 25 * 1024 * 1024; // AES-GCM is done in memory on device

/// Encrypts/decrypts records between the UI and Firestore.
///
/// Firestore document shape — users/{uid}/records/{id}:
///   { cat: "wealth", v: 1, blob: "g1.<nonce>.<ct>.<mac>", createdAt, updatedAt }
/// The record kind, every field value, file names and file keys live inside `blob`.
class VaultRepository extends ChangeNotifier {
  VaultRepository(this.session) {
    session.addListener(_onSession);
    _onSession();
  }

  final Session session;
  final Map<String, DossierRecord> _records = {};
  final List<String> undecryptable = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  String? _listeningUid;
  bool loading = true;
  Object? error;

  // ---- Lifecycle --------------------------------------------------------------

  void _onSession() {
    if (session.state == SessionState.unlocked) {
      if (_listeningUid != session.uid) _start();
    } else if (_listeningUid != null) {
      _stop();
    }
  }

  void _start() {
    _stop();
    _listeningUid = session.uid;
    loading = true;
    _sub = Refs.records(session.uid).snapshots().listen(_onSnapshot, onError: (Object e) {
      error = e;
      loading = false;
      notifyListeners();
    });
  }

  void _stop() {
    _sub?.cancel();
    _sub = null;
    _listeningUid = null;
    _records.clear(); // drop decrypted data from memory on lock
    undecryptable.clear();
    loading = true;
    notifyListeners();
  }

  Future<void> _onSnapshot(QuerySnapshot<Map<String, dynamic>> snap) async {
    if (!session.isUnlocked) return;
    for (final change in snap.docChanges) {
      final doc = change.doc;
      if (change.type == DocumentChangeType.removed) {
        _records.remove(doc.id);
        continue;
      }
      try {
        _records[doc.id] = await decryptRecord(
          ownerUid: session.uid,
          id: doc.id,
          data: doc.data()!,
          categoryKey: session.keyring.keyFor(doc.data()!['cat'] as String),
        );
        undecryptable.remove(doc.id);
      } catch (e) {
        if (!undecryptable.contains(doc.id)) undecryptable.add(doc.id);
        debugPrint('Could not decrypt record ${doc.id}: $e');
      }
    }
    loading = false;
    notifyListeners();
  }

  static Future<DossierRecord> decryptRecord({
    required String ownerUid,
    required String id,
    required Map<String, dynamic> data,
    required Uint8List categoryKey,
  }) async {
    final cat = data['cat'] as String;
    final json = await aeadOpenString(categoryKey, data['blob'] as String,
        aad: KeyManager.recordAad(ownerUid, cat, id));
    final payload = jsonDecode(json) as Map<String, dynamic>;
    return DossierRecord(
      id: id,
      kind: payload['k'] as String,
      category: cat,
      data: Map<String, dynamic>.from(payload['d'] as Map),
      createdAt: tsToDate(data['createdAt']),
      updatedAt: tsToDate(data['updatedAt']) ?? DateTime.now(),
    );
  }

  // ---- Queries ------------------------------------------------------------------

  List<DossierRecord> get all => _records.values.toList();

  DossierRecord? byId(String? id) => id == null ? null : _records[id];

  List<DossierRecord> ofKind(String kind) {
    final list = _records.values.where((r) => r.kind == kind).toList();
    final t = recordTypes[kind];
    list.sort((a, b) => (t?.title(a) ?? a.id).toLowerCase().compareTo((t?.title(b) ?? b.id).toLowerCase()));
    return list;
  }

  List<DossierRecord> ofKinds(Iterable<String> kinds) => kinds.expand(ofKind).toList();

  DossierRecord? single(String kind) {
    final l = ofKind(kind);
    return l.isEmpty ? null : l.first;
  }

  String titleOf(String? id) {
    final r = byId(id);
    if (r == null) return id == null || id.isEmpty ? '—' : '(deleted record)';
    return typeOf(r.kind).title(r);
  }

  /// Documents whose "related record" points at [recordId].
  List<DossierRecord> documentsFor(String recordId) =>
      ofKind(Kinds.document).where((d) => d.str('relatedRecord') == recordId).toList();

  String get displayName {
    final p = single(Kinds.profile);
    final n = p?.str('preferredName').isNotEmpty == true ? p!.str('preferredName') : p?.str('legalName') ?? '';
    return n.isNotEmpty ? n : session.email.split('@').first;
  }

  // ---- Writes -------------------------------------------------------------------

  Future<DossierRecord> save(String kind, Map<String, dynamic> data, {String? id}) async {
    final type = typeOf(kind);
    final cat = type.category;
    final uid = session.uid;
    final isNew = id == null;
    final ref = isNew ? Refs.records(uid).doc() : Refs.records(uid).doc(id);
    final clean = Map<String, dynamic>.from(data)..removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty));
    final blob = await aeadSealString(
      session.keyring.keyFor(cat),
      jsonEncode({'v': 1, 'k': kind, 'd': clean}),
      aad: KeyManager.recordAad(uid, cat, ref.id),
    );
    await ref.set({
      'cat': cat,
      'v': 1,
      'blob': blob,
      'updatedAt': FieldValue.serverTimestamp(),
      if (isNew) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    final rec = DossierRecord(
      id: ref.id,
      kind: kind,
      category: cat,
      data: clean,
      createdAt: _records[ref.id]?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _records[ref.id] = rec;
    notifyListeners();
    unawaited(logAudit(isNew ? 'record.create' : 'record.update', target: ref.id));
    return rec;
  }

  Future<void> delete(String id) async {
    final rec = _records[id];
    if (rec == null) return;
    final batch = Refs.db.batch()..delete(Refs.records(session.uid).doc(id));
    // Cascade: allocations pointing at a deleted asset/beneficiary.
    for (final a in ofKind(Kinds.allocation)) {
      if (a.str('assetId') == id || a.str('beneficiaryId') == id) {
        batch.delete(Refs.records(session.uid).doc(a.id));
        _records.remove(a.id);
      }
    }
    await batch.commit();
    if (rec.kind == Kinds.document) {
      for (final v in fileVersions(rec)) {
        try {
          await Refs.storage.ref(Refs.filePath(session.uid, rec.category, v['fileId'] as String)).delete();
        } catch (_) {/* already gone */}
      }
    }
    _records.remove(id);
    notifyListeners();
    unawaited(logAudit('record.delete', target: id));
  }

  // ---- Encrypted files ------------------------------------------------------------

  /// Encrypts [bytes] with a fresh per-file key and uploads only ciphertext.
  /// Returns metadata to store *inside* the encrypted document record.
  Future<Map<String, dynamic>> uploadFile({
    required Uint8List bytes,
    required String fileName,
    String category = Categories.vault,
    void Function(double progress)? onProgress,
  }) async {
    if (bytes.length > maxFileBytes) {
      throw StateError('File is larger than ${maxFileBytes ~/ (1024 * 1024)} MB');
    }
    final fileId = const Uuid().v4();
    final key = randomBytes(32);
    final enc = await aeadSealBytes(key, bytes, aad: KeyManager.fileAad(session.uid, category, fileId));
    final task = Refs.storage
        .ref(Refs.filePath(session.uid, category, fileId))
        .putData(enc, SettableMetadata(contentType: 'application/octet-stream'));
    final progressSub = task.snapshotEvents.listen((s) {
      if (s.totalBytes > 0) onProgress?.call(s.bytesTransferred / s.totalBytes);
    });
    await task;
    await progressSub.cancel();
    final meta = {
      'fileId': fileId,
      'fileName': fileName,
      'size': bytes.length,
      'sha256': hex(await sha256(bytes)),
      'key': b64(key),
      'uploadedAt': DateTime.now().toIso8601String(),
    };
    wipe(key);
    return meta;
  }

  static List<Map<String, dynamic>> fileVersions(DossierRecord doc) {
    final v = doc.data['files'];
    if (v is List) return v.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    return const [];
  }

  /// Downloads and decrypts a file. Works for the owner and for a released
  /// confidant (who passes the owner's uid; the file key is inside the record).
  static Future<Uint8List> downloadFile({
    required String ownerUid,
    required String category,
    required Map<String, dynamic> fileMeta,
  }) async {
    final fileId = fileMeta['fileId'] as String;
    final data = await Refs.storage.ref(Refs.filePath(ownerUid, category, fileId)).getData(maxFileBytes + 1024);
    if (data == null) throw StateError('File not found');
    final clear = await aeadOpenBytes(unb64(fileMeta['key'] as String), data,
        aad: KeyManager.fileAad(ownerUid, category, fileId));
    final expected = fileMeta['sha256'] as String?;
    if (expected != null && hex(await sha256(clear)) != expected) {
      throw CryptoError('File integrity check failed');
    }
    return clear;
  }

  // ---- Audit --------------------------------------------------------------------

  Future<void> logAudit(String action, {String? target, String? ownerUid}) async {
    try {
      await Refs.audit(ownerUid ?? session.uid).add({
        'at': FieldValue.serverTimestamp(),
        'actor': session.uid,
        'action': action,
        if (target != null) 'target': target,
      });
    } catch (e) {
      debugPrint('audit failed: $e');
    }
  }

  // ---- Export / erase -----------------------------------------------------------

  /// Plain-text JSON export of all records. Leaves the app unencrypted — the
  /// user explicitly asks for it.
  String exportJson() {
    final list = all
        .map((r) => {
              'id': r.id,
              'kind': r.kind,
              'category': r.category,
              'data': Map<String, dynamic>.from(r.data)..remove('files'),
              if (r.kind == Kinds.document)
                'files': fileVersions(r).map((f) => {'fileName': f['fileName'], 'size': f['size']}).toList(),
            })
        .toList();
    return const JsonEncoder.withIndent('  ').convert({
      'exportedAt': DateTime.now().toIso8601String(),
      'records': list,
    });
  }

  /// Deletes every record and file. Used by "Delete my Dossier".
  Future<void> eraseEverything() async {
    final uid = session.uid;
    for (final d in ofKind(Kinds.document)) {
      for (final v in fileVersions(d)) {
        try {
          await Refs.storage.ref(Refs.filePath(uid, d.category, v['fileId'] as String)).delete();
        } catch (_) {}
      }
    }
    Future<void> wipeCollection(CollectionReference<Map<String, dynamic>> c) async {
      final snap = await c.get();
      for (var i = 0; i < snap.docs.length; i += 400) {
        final b = Refs.db.batch();
        for (final d in snap.docs.skip(i).take(400)) {
          b.delete(d.reference);
        }
        await b.commit();
      }
    }

    await wipeCollection(Refs.records(uid));
    await wipeCollection(Refs.grants(uid));
    await wipeCollection(Refs.notifications(uid));
    final noms = await Refs.nominations.where('ownerUid', isEqualTo: uid).get();
    for (final n in noms.docs) {
      await n.reference.delete();
    }
    _records.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    session.removeListener(_onSession);
    _sub?.cancel();
    super.dispose();
  }
}
