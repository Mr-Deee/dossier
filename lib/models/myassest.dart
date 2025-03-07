import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // Added to use buttons

User? currentfirebaseUser;

class myassets extends ChangeNotifier {
  String? id;
  String? CurrentUserid;
  String? AssetName;
  String? AssetType;
  String? AssetHandler;
  String? AssetWorth;
  String? KinsMan;
  String? location;
  String? Tenure;
  List<String>? AssetImages;
  String? notifications ;

  myassets({
    this.id,
    this.CurrentUserid,
    this.AssetName,
    this.AssetType,
    this.AssetHandler,
    this.AssetWorth,
    this.KinsMan,
    this.location,
    this.Tenure,
    this.AssetImages,
    this.notifications
  });

  static myassets fromMap(Map<String, dynamic> map, String id) {
    return myassets(
      id:id,
      CurrentUserid: map['CurrentUser'],
      AssetName: map['AssetName'],
      location: map["location"],
      AssetType: map["AssetType"],
      AssetHandler: map["AssetHandler"].toString(),
      AssetWorth: map["AssetWorth"].toString(),
      Tenure: map["Tenure"],
      AssetImages: (map["AssetImages"] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],

      // AssetImages: map["AssetImages"][0].toString(),
      KinsMan: map["KinsMan"],
      notifications: map["Notification"].toString(),
    );
  }

  myassets? myassetinfo;

  myassets? get myassetuserInfo => myassetinfo;

  void setASSUser(myassets cliuser) {
    myassetinfo = cliuser;
    notifyListeners();
  }



  // Function to schedule notification to next of kin
  void scheduleNotificationToNextOfKin(BuildContext context) {
    // Criteria: Only send notification if asset worth is greater than a threshold (e.g., 10000)
    double assetWorthValue = double.tryParse(AssetWorth ?? '0') ?? 0;
    if (assetWorthValue > 10000) {
      // Notification data to be sent
      Map<String, dynamic> notificationData = {
        'KinsMan': KinsMan,
        'AssetName': AssetName,
        'notificationTime': DateTime.now().add(Duration(days: 7)).toIso8601String(), // Schedule for a week later
        'message': 'Reminder: Asset $AssetName is scheduled for review.'
      };

      // Write to Firebase Database
      DatabaseReference notificationRef = FirebaseDatabase.instance
          .reference()
          .child('notifications')
          .child(CurrentUserid!);
      notificationRef.push().set(notificationData).then((_) {
        // Notify user of success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notification scheduled successfully')),
        );
      }).catchError((error) {
        // Handle error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to schedule notification: $error')),
        );
      });
    } else {
      // Criteria not met
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Asset worth is too low to schedule a notification.')),
      );
    }
  }

  // Add a button for scheduling the notification in the UI
  Widget buildAssetCard(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text(AssetName ?? 'Unknown Asset'),
            subtitle: Text('Worth: $AssetWorth'),
          ),
          ButtonBar(
            alignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  // Schedule notification button
                  scheduleNotificationToNextOfKin(context);
                },
                child: Text('Schedule Notification to Next of Kin'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Add other actions if necessary
                },
                child: Text('Other Action'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
