import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Must match the region in functions/src/index.ts.
const String functionsRegion = 'europe-west1';

class Refs {
  static FirebaseFirestore get db => FirebaseFirestore.instance;
  static FirebaseStorage get storage => FirebaseStorage.instance;
  static FirebaseFunctions get functions => FirebaseFunctions.instanceFor(region: functionsRegion);

  static DocumentReference<Map<String, dynamic>> user(String uid) => db.collection('users').doc(uid);
  static CollectionReference<Map<String, dynamic>> records(String uid) => user(uid).collection('records');
  static CollectionReference<Map<String, dynamic>> grants(String uid) => user(uid).collection('grants');
  static CollectionReference<Map<String, dynamic>> audit(String uid) => user(uid).collection('audit');
  static CollectionReference<Map<String, dynamic>> notifications(String uid) => user(uid).collection('notifications');
  static DocumentReference<Map<String, dynamic>> directory(String emailHash) => db.collection('directory').doc(emailHash);
  static CollectionReference<Map<String, dynamic>> get nominations => db.collection('nominations');
  static CollectionReference<Map<String, dynamic>> get invites => db.collection('invites');
  static CollectionReference<Map<String, dynamic>> get accessRequests => db.collection('accessRequests');

  static String filePath(String uid, String category, String fileId) => 'users/$uid/files/$category/$fileId.bin';
  static String evidencePath(String uid, String requestId, String name) => 'evidence/$uid/$requestId/$name';
}

DateTime? tsToDate(Object? v) {
  if (v is Timestamp) return v.toDate();
  if (v is String) return DateTime.tryParse(v);
  return null;
}
