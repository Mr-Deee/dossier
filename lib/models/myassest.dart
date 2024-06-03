import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';

// User? firebaseUser;


User? currentfirebaseUser;

class myassets extends ChangeNotifier {
  String? id;
  String? CurrentUserid;
  String? AssetName;
  String? AssetType;
  String? AssetWorth;
  String? KinsMan;
  String? location;
  String? Tenure;
  String?AssetImages;

  myassets({
    this.id,
    this.CurrentUserid,
    this.AssetName,
    this.AssetType,
    this.AssetWorth,
    this.KinsMan,
    this.location,
    this.Tenure,
    this.AssetImages,
  });

  static myassets fromMap(Map<String, dynamic> map) {
    return myassets(
      id:map['id'],
      CurrentUserid:map['CurrentUser'],
      AssetName:map['AssetName'],
      location : map["email"],
      AssetType : map["AssetType"],
      AssetWorth : map["AssetWorth"].toString(),
      Tenure: map["Tenure"],
      AssetImages: map["AssetImages"][0].toString(),
      KinsMan : map["KinsMan"],

    );
  }

  myassets? myassetinfo;

  myassets? get myassetuserInfo => myassetinfo;

  void setASSUser(myassets cliuser) {
    myassetinfo = cliuser;
    notifyListeners();
  }
}



