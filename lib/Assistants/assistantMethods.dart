import 'dart:convert';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';


import 'package:provider/provider.dart';

import '../main.dart';
import '../models/clientuser.dart';
import '../models/configmaps.dart';


class AssistantMethods {



  // static sendNotificationToWMS(String token, context, String wms_request_id) async
  // {
  //   print("noti started");
  //   var destination = Provider.of<AppData>(context, listen: false).dropOfflocation;
  //   print("+des"'$destination');
  //   Map<String, String> headerMap =
  //   {
  //     'Content-Type': 'application/json',
  //
  //     'Authorization': serverToken,
  //   };
  //
  //   Map notificationMap =
  //   {
  //     'body': 'WMS Address,', "ACCRA"
  //       'title': 'New BIN Request'
  //   };
  //
  //   Map dataMap =
  //   {
  //     'click_action': 'FLUTTER_NOTIFICATION_CLICK',
  //     'id': '1',
  //     'status': 'done',
  //     'WMS_request_id': wms_request_id,
  //   };
  //
  //   Map sendNotificationMap =
  //   {
  //     "notification": notificationMap,
  //     "data": dataMap,
  //     "priority": "high",
  //     "to": token,
  //   };
  //
  //   var res = await http.post(Uri.parse(
  //       'https://fcm.googleapis.com/fcm/send'),
  //     headers: headerMap,
  //     body: jsonEncode(sendNotificationMap),
  //   );
  // }
  //



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