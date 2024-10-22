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

  @override
  void initState() {
    super.initState();
    filterAssets();
  }

  User? firebaseUser = FirebaseAuth.instance.currentUser;

  void filterAssets() {
    final clientProvider =
        Provider.of<clientusers>(context, listen: false).userInfo;
    final assetProvider =
        Provider.of<myassets>(context, listen: false).myassetinfo;

    if (assetProvider != null) {
      filteredAssets = [];
      if (assetProvider.CurrentUserid == firebaseUser?.uid) {
        filteredAssets.add(assetProvider);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientProvider = Provider.of<clientusers>(context).userInfo;
    final assetProvider = Provider.of<myassets>(context).myassetinfo;
    final DatabaseReference _databaseReference =
    FirebaseDatabase.instance.ref().child('Assets');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Your Assets',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.black87,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: Container(
              height: 115,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
              ),
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start, // Aligns text at the top
                  children: [
                    // Total Assets section
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Total Assets",
                            style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "${filteredAssets.length}",
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    // Vertical Divider
                    Container(
                      width: 1, // Thickness of the vertical line
                      height: 40, // Height of the vertical line
                      color: Colors.white24, // Line color
                    ),
                    SizedBox(width: 10), // Add space between sections

                    // Categories section
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Categories",
                            style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold),

                          ),
                          SizedBox(height: 5),
                          Text(
                            assetProvider?.AssetType ?? "N/A",
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    // Vertical Divider
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white24,
                    ),
                    SizedBox(width: 10),

                    // Username section
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Owner",
                            style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 5),
                          Text(
                            clientProvider?.username ?? "",
                            style: TextStyle(color: Colors.white70, fontSize: 16),
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
          Expanded(
            child: StreamBuilder(
              stream: _databaseReference
                  .orderByChild('CurrentUser')
                  .equalTo(firebaseUser?.uid)
                  .onValue,
              builder: (BuildContext context,
                  AsyncSnapshot<DatabaseEvent> snapshot) {
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
                    myassets.fromMap(value.cast<String, dynamic>(),key);
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
                            vertical: 10.0, horizontal: 17),
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
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
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
    );
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
                    print('document$docid');
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
                        'documentId': notificationId, // Save the document ID here
                      });

                      // Optionally, show a success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Notification scheduled successfully"),
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





