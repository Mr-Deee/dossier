import 'dart:convert';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';


import 'package:provider/provider.dart';

import '../main.dart';
import '../models/clientuser.dart';
import '../models/configmaps.dart';
import '../models/myassest.dart';


class AssistantMethods {

  static void getCurrentOnlineUserInfo(BuildContext context) async {
    print('assistant methods step 3:: get current online user info');
    firebaseUser =
        FirebaseAuth.instance.currentUser; // CALL FIREBASE AUTH INSTANCE
    print('assistant methods step 4:: call firebase auth instance');
    String? userId =
        firebaseUser!.uid; // ASSIGN UID FROM FIREBASE TO LOCAL STRING
    print('assistant methods step 5:: assign firebase uid to string');
    DatabaseReference reference =
    FirebaseDatabase.instance.ref().child("Clients").child(userId);
    print(
        'assistant methods step 6:: call users document from firebase database using userId');
    reference.once().then((event) async {
      final dataSnapshot = event.snapshot;
      if (dataSnapshot.value != null) {
        //userCurrentInfo = Users.fromSnapshot(dataSnapshot);
        // IF DATA CALLED FROM THE FIREBASE DOCUMENT ISN'T NULL
        // =userCurrentInfo = Users.fromSnapshot(
        //     dataSnapShot);ASSIGN DATA FROM SNAPSHOT TO 'USERS' OBJECT

        DatabaseEvent event = await reference.once();

        context.read<clientusers>().setUser(clientusers.fromMap(
            Map<String, dynamic>.from(event.snapshot.value as dynamic)));
        print(
            'assistant methods step 7:: assign users data to usersCurrentInfo object');
      }
    });
  }
  static void getCurrentAssetInfo(BuildContext context) async {
    print('assistant methods step 32:: get current asset user info');

    // Get the current user from Firebase Authentication
    User? firebaseUser = FirebaseAuth.instance.currentUser;

    // Ensure the user is signed in
    if (firebaseUser == null) {
      print("No user is currently signed in.");
      return;
    }

    // Assign UID from Firebase to local string
    String userId = firebaseUser.uid;
    print('assistant methods step 5:: assign firebase uid to string');

    // Create a reference to the Firebase Realtime Database
    DatabaseReference reference = FirebaseDatabase.instance.ref().child("Assets");
    print('assistant methods step 6:: call users document from firebase database using userId');

    // Query the database to find assets where 'CurrentUser' equals the current user's ID
    Query query = reference.orderByChild('CurrentUser').equalTo(userId);

    try {
      DatabaseEvent event = await query.once();
      DataSnapshot dataSnapshot = event.snapshot;

      if (dataSnapshot.value != null) {
        // Assuming the result is a map of assets
        Map<String, dynamic> assetsData = Map<String, dynamic>.from(dataSnapshot.value as dynamic);

        // Iterate through the assets and update the context
        for (var asset in assetsData.values) {
          myassets currentUserAssets = myassets.fromMap(Map<String, dynamic>.from(asset));
          context.read<myassets>().setASSUser(currentUserAssets);
          print('assistant methods step 78:: assign users data to AssetuserCurrentInfo object');
        }
      } else {
        print("No asset data found for the current user.");
      }
    } catch (error) {
      print("Failed to retrieve asset data: $error");
    }
  }
  static double createRandomNumber(int num) {
    var random = Random();
    int radNumber = random.nextInt(num);
    return radNumber.toDouble();
  }





  // static String formatTripDate(String date) {
  //   DateTime dateTime = DateTime.parse(date);
  //   String formattedDate =
  //       "${DateFormat.MMMd().format(dateTime)}, ${DateFormat.y().format(dateTime)} - ${DateFormat.jm().format(dateTime)}";
  //
  //   return formattedDate;
  // }
}