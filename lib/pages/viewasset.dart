import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';  // For formatting date and time

import '../constants.dart';
import '../models/clientuser.dart';
import '../models/myassest.dart';
import '../widget/progressdialog.dart';

class ViewAsset extends StatefulWidget {
  const ViewAsset({super.key});

  @override
  State<ViewAsset> createState() => _ViewAssetState();
}

class _ViewAssetState extends State<ViewAsset> {
  List<myassets> filteredAssets = [];
  List<myassets> allAssets = []; // Assuming you have a list of assets

  int totalAssets = 0;
  @override
  void initState() {
    super.initState();
    getAllAssets();
    filterAssets(allAssets);

  }

  User? firebaseUser = FirebaseAuth.instance.currentUser;

  Future<void> getAllAssets() async {
    final DatabaseReference databaseReference = FirebaseDatabase.instance.ref('Assets');
    try {
      // Fetch assets from Realtime Database
      DatabaseEvent event = await databaseReference.once();
      final dataSnapshot = event.snapshot;

      // Check if data exists
      if (dataSnapshot.exists) {
        // Convert the snapshot into a list of myassets objects
        Map<dynamic, dynamic> assetsMap = dataSnapshot.value as Map<dynamic, dynamic>;

        allAssets = assetsMap.entries.map((entry) {
          // Safely convert the value to Map<String, dynamic>
          final assetData = Map<String, dynamic>.from(entry.value as Map); // Safe conversion
          return myassets.fromMap(assetData, entry.key.toString()); // Use the entry key as the ID
        }).toList();

        // Count the total number of assets
        // totalAssets = allAssets.length;
        print('Total assets: $totalAssets');

        // Call filterAssets to filter by the current user
        filterAssets(allAssets);
      } else {
        print('No assets found.');
      }
    } catch (e) {
      print('Error fetching assets: $e');
    }
  }



  void filterAssets(List<myassets> allAssets) {
    final User? firebaseUser = FirebaseAuth.instance.currentUser;

    // Clear previous filtered results
    List<myassets> updatedFilteredAssets = [];

    // Filter assets based on the CurrentUserId
    for (var asset in allAssets) {
      if (asset.CurrentUserid == firebaseUser?.uid) {
        updatedFilteredAssets.add(asset);
      }
    }

    // Update the state to refresh UI with filtered results
    setState(() {
      filteredAssets = updatedFilteredAssets;
      totalAssets=updatedFilteredAssets.length;
    });
  }


  @override
  Widget build(BuildContext context) {
    final clientProvider = Provider.of<clientusers>(context).userInfo;
    final assetProvider = Provider.of<myassets>(context).myassetinfo;
    final DatabaseReference _databaseReference =
    FirebaseDatabase.instance.ref().child('Assets');

    return Scaffold(

      // appBar: AppBar(
      //   title: Text(
      //     'Your Assets',
      //     style: TextStyle(color: Colors.white, fontSize: 18),
      //   ),
      //   centerTitle: true,
      //   backgroundColor: Colors.black87,
      //   leading: IconButton(
      //     icon: Icon(Icons.arrow_back, color: Colors.white),
      //     onPressed: () {
      //       Navigator.of(context).pop();
      //     },
      //   ),
      // ),
      body: CustomPaint(
        painter: GradientBackgroundPainter(),
        child: Column(
          children: [
            SizedBox(height: 88),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: Container(
                height: 115,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.white, blurRadius: 6)],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Total Assets Section
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                "Total Assets",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 5),
                            Center(
                              child: Text(
                                "${totalAssets}",
                                style: TextStyle(color: Colors.black, fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Vertical Divider
                      Container(
                        width: 4,
                        height: 70,
                        color: Colors.black,
                      ),
                      SizedBox(width: 10),
                      // Owner Section
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                "Owner",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 5),
                            Center(
                              child: Text(
                                clientProvider?.username ?? "",
                                style: TextStyle(color: Colors.black, fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                width: MediaQuery.of(context).size.width,
              ),
            ),
            // StreamBuilder Section
            Expanded(
              child: StreamBuilder(
                stream: _databaseReference
                    .orderByChild('CurrentUser')
                    .equalTo(firebaseUser?.uid)
                    .onValue,
                builder: (BuildContext context, AsyncSnapshot<DatabaseEvent> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  List<myassets> filteredAssets = [];
                  if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                    Map<dynamic, dynamic>? map =
                    snapshot.data!.snapshot.value as Map<dynamic, dynamic>?;
                    map!.forEach((key, value) {
                      myassets asset =
                      myassets.fromMap(value.cast<String, dynamic>(), key);
                      filteredAssets.add(asset);
                    });
                  }

                  return ListView.builder(
                    itemCount: filteredAssets.length,
                    itemBuilder: (context, index) {
                      final asset = filteredAssets[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AssetDetailsScreen(
                                asset: asset,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10.0, horizontal: 13),
                          child: Container(
                            height: 110,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.4),
                                  spreadRadius: 1,
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      asset.AssetImages ?? '',
                                      height: 70,
                                      width: 90,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        Text(
                                          asset.AssetName ?? '',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'Worth: ${asset.AssetWorth ?? ''}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class GradientBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.amber,
          Colors.white,
          // Colors.white,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Draw the gradient background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class AssetDetailsScreen extends StatelessWidget {
  final myassets asset;

  const AssetDetailsScreen({Key? key, required this.asset}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(asset.AssetName ?? "Asset Details"),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(

          children: [
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Asset Worth
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Icon(Icons.monetization_on, color: Colors.green, size: 24),
                        const SizedBox(width: 10),
                        Text(
                          '${asset.AssetWorth ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),

                    // Asset Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16.0),
                      child: Image.network(
                        asset.AssetImages ?? 'https://via.placeholder.com/400x200',
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Asset Name
                    Text(
                      asset.AssetName ?? 'Unnamed Asset',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Asset Category
                    Row(
                      children: [
                        const Icon(Icons.category, color: Colors.blueAccent, size: 24),
                        const SizedBox(width: 10),
                        Text(
                          'Category: ${asset.AssetType ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Buttons for Scheduling and Editing Notifications

                  ],
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.notifications, color: Colors.white),
                  label: const Text(""),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  onPressed: () {
                  String?  docid=asset.id;
                    // print('document$docid');
                    _showScheduleNotificationDialog(context);
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.edit_notifications, color: Colors.white),
                  label: const Text(""),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                  ),
                  onPressed: () {
                    _editScheduledNotification(context);
                  },
                ),
              ],
            ),
          ],
        ),


      ),
    );
  }

  // Show schedule notification dialog
  void _showScheduleNotificationDialog(BuildContext context) {
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    String? selectedProtocol;
    String? selectedInterval;
    final clientProvider = Provider.of<clientusers>(context,listen: false).userInfo;
    final assetProvider = Provider.of<myassets>(context,listen: false).myassetinfo;
    final List<String> protocolList = ["Email", "Text Message"];
    final List<String> intervalList = ["Monthly", "Yearly", "Two Years"];

    final DatabaseReference _notificationDatabaseRef = FirebaseDatabase.instance.ref().child('Notifications');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'Schedule Notification',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Date Picker
                      ListTile(
                        leading: const Icon(Icons.calendar_today, color: Colors.blueAccent),
                        title: Text(
                          selectedDate == null
                              ? 'Select Date'
                              : DateFormat('yMMMd').format(selectedDate!),
                          style: const TextStyle(fontSize: 16),
                        ),
                        onTap: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              selectedDate = pickedDate;
                            });
                          }
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          side: const BorderSide(color: Colors.grey, width: 1.0),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      ),

                      const SizedBox(height: 10),

                      // Time Picker
                      ListTile(
                        leading: const Icon(Icons.access_time, color: Colors.blueAccent),
                        title: Text(
                          selectedTime == null
                              ? 'Select Time'
                              : selectedTime!.format(context),
                          style: const TextStyle(fontSize: 16),
                        ),
                        onTap: () async {
                          TimeOfDay? pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (pickedTime != null) {
                            setState(() {
                              selectedTime = pickedTime;
                            });
                          }
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          side: const BorderSide(color: Colors.grey, width: 1.0),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      ),

                      const SizedBox(height: 10),

                      // Protocol Dropdown
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: "Protocol",
                          icon: Icon(Icons.email, color: Colors.blueAccent),
                          border: OutlineInputBorder(),
                        ),
                        value: selectedProtocol,
                        items: protocolList.map((protocol) {
                          return DropdownMenuItem<String>(
                            value: protocol,
                            child: Text(protocol),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            selectedProtocol = newValue;
                          });
                        },
                      ),

                      const SizedBox(height: 10),

                      // Interval Dropdown
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: "Interval",
                          icon: Icon(Icons.schedule, color: Colors.blueAccent),
                          border: OutlineInputBorder(),
                        ),
                        value: selectedInterval,
                        items: intervalList.map((interval) {
                          return DropdownMenuItem<String>(
                            value: interval,
                            child: Text(interval),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            selectedInterval = newValue;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedDate != null &&
                        selectedTime != null &&
                        selectedProtocol != null &&
                        selectedInterval != null) {
                      String formattedDate = DateFormat('yMMMd').format(selectedDate!);
                      String formattedTime = selectedTime!.format(context);

                      // Generate a document ID for the notification
                      String notificationId = _notificationDatabaseRef.push().key!;

                      // Save the notification details to the Firebase database
                      await _notificationDatabaseRef.child(notificationId).set({
                        'assetId': assetProvider?.id,
                        'protocol': selectedProtocol,
                        'interval': selectedInterval,
                        'scheduledDate': formattedDate,
                        'scheduledTime': formattedTime,
                        'NotificationID': notificationId, // Save the document ID here
                      });

                      // Optionally, show a success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            "Notification scheduled successfully",
                            style: TextStyle(
                              color: Colors.black, // Text color
                              fontWeight: FontWeight.bold, // Bold text
                            ),
                          ),
                          backgroundColor: Colors.white, // Background color
                          behavior: SnackBarBehavior.floating, // Makes the snackbar float above the bottom of the screen
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10), // Rounded corners
                          ),
                          duration: const Duration(seconds: 2), // Duration the snack bar is shown
                          action: SnackBarAction(
                            label: "Undo",
                            textColor: Colors.yellow, // Button text color
                            onPressed: () {
                              // Your undo action code here
                            },
                          ),
                        ),
                      );


                      Navigator.pop(context);
                    } else {
                      // Show an error if the user hasn't completed the form
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please fill out all fields"),
                        ),
                      );
                    }
                  },
                  child: const Text('Schedule'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                  ),
                ),
              ],
            );

          },
        );
      },
    );
  }
  // Function to edit the scheduled notification
  void _editScheduledNotification(BuildContext context) {
    // This function can contain your logic to edit an existing scheduled notification.
  }
}





