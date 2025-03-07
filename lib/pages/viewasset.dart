import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
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
  StreamSubscription<DatabaseEvent>? _assetsSubscription;

  int totalAssets = 0;
  @override
  void initState() {
    super.initState();
    startAssetsListener();
    filterAssets(allAssets);

  }

  User? firebaseUser = FirebaseAuth.instance.currentUser;

  void startAssetsListener() {
    final DatabaseReference databaseReference = FirebaseDatabase.instance.ref('Assets');
    _assetsSubscription = databaseReference.onValue.listen((DatabaseEvent event) {
      final dataSnapshot = event.snapshot;

      if (dataSnapshot.exists) {
        // Convert the snapshot into a list of myassets objects
        Map<dynamic, dynamic> assetsMap = dataSnapshot.value as Map<dynamic, dynamic>;

        List<myassets> updatedAssets = assetsMap.entries.map((entry) {
          // Safely convert the value to Map<String, dynamic>
          final assetData = Map<String, dynamic>.from(entry.value as Map); // Safe conversion
          return myassets.fromMap(assetData, entry.key.toString()); // Use the entry key as the ID
        }).toList();

        // Update all assets and filter them
        setState(() {
          allAssets = updatedAssets;
          filterAssets(allAssets);
        });
      } else {
        print('No assets found.');
        setState(() {
          allAssets = [];
          filteredAssets = [];
          totalAssets = 0;
        });
      }
    }, onError: (error) {
      print('Error fetching assets: $error');
    });
  }

  void filterAssets(List<myassets> allAssets) {
    final User? firebaseUser = FirebaseAuth.instance.currentUser;

    // Filter assets based on the CurrentUserId
    List<myassets> updatedFilteredAssets = allAssets
        .where((asset) => asset.CurrentUserid == firebaseUser?.uid)
        .toList();

    setState(() {
      filteredAssets = updatedFilteredAssets;
      totalAssets = updatedFilteredAssets.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final clientProvider = Provider.of<clientusers>(context).userInfo;
    final assetProvider = Provider.of<myassets>(context).myassetinfo;
    final DatabaseReference _databaseReference =
    FirebaseDatabase.instance.ref().child('Assets');

    return Scaffold(

      body:CustomPaint(
        painter: GradientBackgroundPainter(),
        child: Column(
          children: [
            SizedBox(height: 88),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: Container(
                height: 130,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      // Total Assets Section
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "Total Assets",
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "${totalAssets}",
                              style: TextStyle(
                                color: Colors.teal,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      VerticalDivider(
                        color: Colors.grey[300],
                        thickness: 1,
                        width: 40,
                      ),
                      // Owner Section
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "Owner",
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              clientProvider?.username ?? "N/A",
                              style: TextStyle(
                                color: Colors.teal,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            // StreamBuilder Section
            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                stream: _databaseReference
                    .orderByChild('CurrentUser')
                    .equalTo(firebaseUser?.uid)
                    .onValue,  // Keeps listening and updating in real time
                builder: (BuildContext context, AsyncSnapshot<DatabaseEvent> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  List<myassets> filteredAssets = [];
                  if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                    Map<dynamic, dynamic>? map =
                    snapshot.data!.snapshot.value as Map<dynamic, dynamic>?;
                    map?.forEach((key, value) {
                      myassets asset = myassets.fromMap(value.cast<String, dynamic>(), key);
                      filteredAssets.add(asset);
                    });
                  }

                  if (filteredAssets.isEmpty) {
                    return Center(
                      child: Text(
                        "No Assets Found",
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    itemCount: filteredAssets.length,
                    itemBuilder: (context, index) {
                      final asset = filteredAssets[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AssetDetailsScreen(asset: asset),
                            ),
                          );
                        },
                        child: Card(
                          margin: EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: CachedNetworkImage(
                                    imageUrl: asset.AssetImages?.isNotEmpty == true ? asset.AssetImages! : 'https://via.placeholder.com/70',
                                    height: 70,
                                    width: 70,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      height: 70,
                                      width: 70,
                                      alignment: Alignment.center,
                                      color: Colors.grey[200],
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      height: 70,
                                      width: 70,
                                      color: Colors.grey[300],
                                      alignment: Alignment.center,
                                      child: Icon(
                                        Icons.broken_image,
                                        size: 40,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ),                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        asset.AssetName ?? '',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[800],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Worth: ${asset.AssetWorth ?? ''}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey[500],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            )

          ],
        ),
      )

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
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                        IconButton(
                          onPressed: () async {
                            // Await the result of the confirmation dialog
                            bool confirmDelete = await _showDeleteConfirmationDialog(context);
                            if (confirmDelete) {
                              // Perform deletion logic (e.g., remove from database)
                              String? assetId = asset.id;
                              if (assetId != null) {
                                await FirebaseDatabase.instance.ref('Assets/$assetId').remove();
                              }

                              // Optionally show a success message
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Asset deleted successfully"),
                                  backgroundColor: Colors.green,
                                ),
                              );

                              // Navigate back to the previous screen
                              Navigator.pop(context);
                            }
                          },                          icon: const Icon(Icons.delete, color: Colors.red),
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


  Future<bool> _showDeleteConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Asset"),
          content: const Text("Are you sure you want to delete this asset?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // User canceled
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true); // User confirmed
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    ) ?? false; // Default to false if dialog is dismissed
  }

  void _deleteAsset(BuildContext context) {
    // Implement the logic to delete the asset
    // Example: Call Firebase or backend API to delete the asset from the database
    // After deletion, navigate back to the previous screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Asset deleted successfully")),
    );

    Navigator.of(context).pop(); // Navigate back to the previous screen
  }


}





