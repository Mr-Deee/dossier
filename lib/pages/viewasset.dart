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
                                    imageUrl: (asset.AssetImages != null && asset.AssetImages!.isNotEmpty)
                                        ? asset.AssetImages!.first.trim()
                                        : 'https://via.placeholder.com/70',
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

class AssetDetailsScreen extends StatefulWidget {
  final myassets asset;

  AssetDetailsScreen({required this.asset});

  @override
  _AssetDetailsScreenState createState() => _AssetDetailsScreenState();
}

class _AssetDetailsScreenState extends State<AssetDetailsScreen> {
  late String selectedImage;

  @override
  void initState() {
    super.initState();
    selectedImage = widget.asset.AssetImages?.isNotEmpty == true
        ? widget.asset.AssetImages![0]
        : "https://via.placeholder.com/200"; // Fallback image
  }

  void updateSelectedImage(String imageUrl) {
    setState(() {
      selectedImage = imageUrl;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Asset Details")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          selectedImage,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, size: 100),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text("Asset Name: ${widget.asset.AssetName}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("Senior: ${widget.asset.KinsMan}", style: TextStyle(fontSize: 16)),
                    Text("Stuff: ${widget.asset.myassetinfo}", style: TextStyle(fontSize: 16)),
                    Text("Status: ${widget.asset.Tenure}", style: TextStyle(fontSize: 16, color: Colors.green)),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            if (widget.asset.AssetImages != null && widget.asset.AssetImages!.isNotEmpty) ...[
              Text("More Images", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              SizedBox(
                height: 100, // Set a fixed height
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: widget.asset.AssetImages!.map((imageUrl) {
                    return GestureDetector(
                      onTap: () => updateSelectedImage(imageUrl),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            height: 80,
                            width: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}




