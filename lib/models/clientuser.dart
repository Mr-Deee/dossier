import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';

// User? firebaseUser;


User? currentfirebaseUser;

class clientusers extends ChangeNotifier {
  String? id;
  String? email;
  String? firstname;
  String? lastname;
  String? profilepicture;
  String?phone;

  clientusers({
    this.id,
    this.email,
    this.firstname,
    this.lastname,
    this.profilepicture,
    this.phone,
  });

  static clientusers fromMap(Map<String, dynamic> map) {
    return clientusers(
      id:map['id'],
      email : map["email"],
      firstname : map["firstName"],
      lastname: map["lastName"],
      profilepicture: map["Profilepicture"].toString(),
      phone : map["phone"],

    );
  }

  clientusers? _userInfo;

  clientusers? get userInfo => _userInfo;

  void setUser(clientusers cliuser) {
    _userInfo = cliuser;
    notifyListeners();
  }
}



