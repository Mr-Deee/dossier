import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../crypto/crypto_primitives.dart';
import '../crypto/key_manager.dart';
import '../models/record.dart';
import 'firebase_refs.dart';
import 'session.dart';
import 'vault_repository.dart';

class DirectoryEntry {
  DirectoryEntry(this.uid, this.publicKey);
  final String uid;
  final Uint8List publicKey;
}

/// A grant is the cryptographic half of naming a confidant: the selected
/// category keys sealed to the confidant's public key. Firestore rules keep the
/// grant (and the records it unlocks) unreadable to the confidant until a
/// verified release sets status = "released" — which only the server can do.
class Grant {
  Grant(this.id, this.data);
  final String id;
  final Map<String, dynamic> data;

  String get ownerUid => data['ownerUid'] as String;
  String get granteeUid => data['granteeUid'] as String;
  List<String> get categories => List<String>.from(data['categories'] as List? ?? const []);
  List<String> get triggers => List<String>.from(data['triggers'] as List? ?? const []);
  String get status => data['status'] as String? ?? 'sealed';
  bool get released => status == 'released';
  String? get releasedFor => data['releasedFor'] as String?;
}

class SharedDossier {
  SharedDossier({
    required this.ownerUid,
    required this.ownerName,
    required this.grant,
    required this.records,
  });
  final String ownerUid;
  final String ownerName;
  final Grant grant;
  final List<DossierRecord> records;

  List<DossierRecord> ofKind(String kind) => records.where((r) => r.kind == kind).toList();
  DossierRecord? byId(String? id) {
    for (final r in records) {
      if (r.id == id) return r;
    }
    return null;
  }
}

class SuccessionService {
  SuccessionService(this.session, this.repo);

  final Session session;
  final VaultRepository repo;
  String get _uid => session.uid;

  // ---- Owner side -------------------------------------------------------------

  Future<DirectoryEntry?> lookup(String email) async {
    final hash = await sha256Hex(normaliseEmail(email));
    final snap = await Refs.directory(hash).get();
    final d = snap.data();
    if (d == null) return null;
    return DirectoryEntry(d['uid'] as String, unb64(d['publicKey'] as String));
  }

  Stream<List<Grant>> myGrants() => Refs.grants(_uid)
      .snapshots()
      .map((s) => s.docs.map((d) => Grant(d.id, d.data())).toList());

  /// Names [confidant] (a confidant record) and seals the chosen category keys to them.
  Future<void> saveGrant({
    required DossierRecord confidant,
    required DirectoryEntry entry,
    required List<String> categories,
    required List<String> triggers,
  }) async {
    if (entry.uid == _uid) throw StateError('You cannot name yourself as a confidant.');
    final sealed = await session.keys.sealGrant(
      keyring: session.keyring,
      ownerUid: _uid,
      granteeUid: entry.uid,
      granteePublicKey: entry.publicKey,
      categories: categories,
    );
    final ownerName = await sealToPublicKey(entry.publicKey, utf8.encode(repo.displayName),
        context: KeyManager.nominationContext(_uid, entry.uid));
    final batch = Refs.db.batch();
    batch.set(Refs.grants(_uid).doc(entry.uid), {
      'ownerUid': _uid,
      'granteeUid': entry.uid,
      'confidantRecordId': confidant.id,
      'categories': categories,
      'triggers': triggers,
      'sealedKeys': sealed,
      'status': 'sealed',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(Refs.nominations.doc('${_uid}_${entry.uid}'), {
      'ownerUid': _uid,
      'granteeUid': entry.uid,
      'ownerName': ownerName,
      'triggers': triggers,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    await repo.logAudit('grant.save', target: entry.uid);
  }

  Future<void> revokeGrant(String granteeUid) async {
    final batch = Refs.db.batch()
      ..delete(Refs.grants(_uid).doc(granteeUid))
      ..delete(Refs.nominations.doc('${_uid}_$granteeUid'));
    await batch.commit();
    await repo.logAudit('grant.revoke', target: granteeUid);
  }

  /// Owner regains capacity: re-seal a released grant.
  Future<void> resealGrant(String granteeUid) async {
    await Refs.grants(_uid).doc(granteeUid).update({'status': 'sealed', 'releasedFor': null, 'releasedAt': null});
    await repo.logAudit('grant.reseal', target: granteeUid);
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> requestsAboutMe() => Refs.accessRequests
      .where('ownerUid', isEqualTo: _uid)
      .snapshots()
      .map((s) => [...s.docs]..sort(_newestFirst));

  Future<void> objectTo(String requestId, String reason) async {
    await Refs.accessRequests.doc(requestId).update({
      'status': 'objected',
      'objectionReason': reason,
      'decidedAt': FieldValue.serverTimestamp(),
    });
    await repo.logAudit('request.objected', target: requestId);
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> auditLog() => Refs.audit(_uid)
      .orderBy('at', descending: true)
      .limit(200)
      .snapshots()
      .map((s) => s.docs);

  // ---- Confidant side ---------------------------------------------------------

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> nominationsForMe() =>
      Refs.nominations.where('granteeUid', isEqualTo: _uid).snapshots().map((s) => s.docs);

  Future<String> openOwnerName(Map<String, dynamic> nomination) async {
    try {
      final clear = await openSealed(session.keyring.identity, nomination['ownerName'] as String,
          context: KeyManager.nominationContext(nomination['ownerUid'] as String, _uid));
      return utf8.decode(clear);
    } catch (_) {
      return 'Unknown (could not decrypt)';
    }
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> myRequests() => Refs.accessRequests
      .where('requesterUid', isEqualTo: _uid)
      .snapshots()
      .map((s) => [...s.docs]..sort(_newestFirst));

  /// Starts the Legacy Switch process. Evidence (e.g. a death certificate or a
  /// medical report) is readable by the verification team — it is the one
  /// thing in the process that is not end-to-end encrypted, by necessity.
  Future<void> requestAccess({
    required String ownerUid,
    required String circumstance,
    required String statement,
    Uint8List? evidence,
    String? evidenceName,
  }) async {
    final ref = Refs.accessRequests.doc();
    String? evidencePath;
    if (evidence != null && evidenceName != null) {
      evidencePath = Refs.evidencePath(_uid, ref.id, evidenceName.replaceAll(RegExp(r'[^\w.\-]'), '_'));
      await Refs.storage.ref(evidencePath).putData(evidence, SettableMetadata(contentType: _mime(evidenceName)));
    }
    await ref.set({
      'ownerUid': ownerUid,
      'requesterUid': _uid,
      'circumstance': circumstance,
      'statement': statement,
      if (evidencePath != null) 'evidencePath': evidencePath,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancelRequest(String requestId) =>
      Refs.accessRequests.doc(requestId).update({'status': 'cancelled', 'decidedAt': FieldValue.serverTimestamp()});

  /// Opens a released Dossier read-only. Fails with permission-denied if the
  /// grant has not been released.
  Future<SharedDossier> openShared(String ownerUid, String ownerName) async {
    final g = await Refs.grants(ownerUid).doc(_uid).get();
    if (!g.exists) throw StateError('No released access for this Dossier.');
    final grant = Grant(g.id, g.data()!);
    final keys = await session.keys.openGrant(
      myKeyring: session.keyring,
      ownerUid: ownerUid,
      myUid: _uid,
      sealed: grant.data['sealedKeys'] as String,
    );
    final records = <DossierRecord>[];
    for (final cat in grant.categories) {
      final key = keys[cat];
      if (key == null) continue;
      final snap = await Refs.records(ownerUid).where('cat', isEqualTo: cat).get();
      for (final d in snap.docs) {
        try {
          records.add(await VaultRepository.decryptRecord(ownerUid: ownerUid, id: d.id, data: d.data(), categoryKey: key));
        } catch (_) {/* skip unreadable */}
      }
    }
    await repo.logAudit('released.view', ownerUid: ownerUid);
    return SharedDossier(ownerUid: ownerUid, ownerName: ownerName, grant: grant, records: records);
  }

  // ---- Verification team --------------------------------------------------------

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> pendingForVerifier() => Refs.accessRequests
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((s) => [...s.docs]..sort(_newestFirst));

  Future<String> evidenceUrl(String path) => Refs.storage.ref(path).getDownloadURL();

  /// Returns a human-readable outcome. Releases need approvals from
  /// REQUIRED_APPROVALS distinct verifiers (default 2) — see functions/src/index.ts.
  Future<String> decide(String requestId, {required bool approve, required String note}) async {
    final res = await Refs.functions
        .httpsCallable(approve ? 'approveAccessRequest' : 'rejectAccessRequest')
        .call({'requestId': requestId, 'note': note});
    final d = Map<String, dynamic>.from(res.data as Map);
    if (!approve) return 'Request rejected';
    if (d['blocked'] == true) return 'Blocked: the owner checked in after the request — nothing released.';
    if (d['released'] == true) return 'Verified and released.';
    return 'Approval recorded (${d['approvals']} of ${d['required']}). A different verifier must also confirm.';
  }

  static int _newestFirst(QueryDocumentSnapshot<Map<String, dynamic>> a, QueryDocumentSnapshot<Map<String, dynamic>> b) {
    final ta = tsToDate(a.data()['createdAt']) ?? DateTime.now();
    final tb = tsToDate(b.data()['createdAt']) ?? DateTime.now();
    return tb.compareTo(ta);
  }

  static String _mime(String name) {
    final n = name.toLowerCase();
    if (n.endsWith('.pdf')) return 'application/pdf';
    if (n.endsWith('.png')) return 'image/png';
    if (n.endsWith('.jpg') || n.endsWith('.jpeg')) return 'image/jpeg';
    return 'application/octet-stream';
  }
}
