import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';  // For formatting date and time
import '../constants.dart';
import '../models/clientuser.dart';
import '../models/myassest.dart';

class ViewAsset extends StatefulWidget {
  const ViewAsset({super.key});

  @override
  State<ViewAsset> createState() => _ViewAssetState();
}

class _ViewAssetState extends State<ViewAsset> {
  List<myassets> filteredAssets = [];
  List<myassets> allAssets = [];
  bool _isDataLoaded = false; // Flag to track if data is already loaded
  int totalAssets = 0;
  User? firebaseUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    if (!_isDataLoaded) {
      loadAssetsOnce();
    }
  }

  Future<void> loadAssetsOnce() async {
    final DatabaseReference databaseReference = FirebaseDatabase.instance.ref('Assets');

    try {
      final dataSnapshot = await databaseReference.get();
      if (dataSnapshot.exists) {
        Map<dynamic, dynamic> assetsMap = dataSnapshot.value as Map<dynamic, dynamic>;
        List<myassets> updatedAssets = assetsMap.entries.map((entry) {
          final assetData = Map<String, dynamic>.from(entry.value as Map);
          return myassets.fromMap(assetData, entry.key.toString());
        }).toList();

        setState(() {
          allAssets = updatedAssets;
          filterAssets(allAssets);
          _isDataLoaded = true; // Mark as loaded to prevent reloading
        });
      } else {
        setState(() {
          allAssets = [];
          filteredAssets = [];
          totalAssets = 0;
          _isDataLoaded = true;
        });
      }
    } catch (error) {
      print('Error fetching assets: $error');
    }
  }

  void filterAssets(List<myassets> allAssets) {
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

    return Scaffold(
      body: CustomPaint(
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
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text("Total Assets",
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                )),
                            SizedBox(height: 10),
                            Text("$totalAssets",
                                style: TextStyle(
                                  color: Colors.teal,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                )),
                          ],
                        ),
                      ),
                      VerticalDivider(
                        color: Colors.grey[300],
                        thickness: 1,
                        width: 40,
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text("Owner",
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                )),
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
            Expanded(
              child: _isDataLoaded
                  ? filteredAssets.isEmpty
                  ? Center(
                child: Text("No Assets Found",
                    style:
                    TextStyle(fontSize: 16, color: Colors.grey[600])),
              )
                  : ListView.builder(
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
                                imageUrl: (asset.AssetImages != null &&
                                    asset.AssetImages!.isNotEmpty)
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
                            ),
                            SizedBox(width: 16),
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
                            Icon(Icons.chevron_right, color: Colors.grey[500]),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              )
                  : Center(child: CircularProgressIndicator()), // Show loading indicator while fetching data
            )
          ],
        ),
      ),
    );
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
  List<String> imageList = [];

  @override
  void initState() {
    super.initState();
    if (widget.asset.AssetImages != null && widget.asset.AssetImages!.isNotEmpty) {
      imageList = widget.asset.AssetImages!;
      selectedImage = imageList.first;
    } else {
      selectedImage = 'https://via.placeholder.com/200';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.asset.AssetName ?? 'Asset Details')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: selectedImage,
                height: 200,
                width: 200,
                fit: BoxFit.cover,
                placeholder: (context, url) => CircularProgressIndicator(),
                errorWidget: (context, url, error) => Icon(Icons.error),
              ),
            ),
          ),
          SizedBox(height: 10),
          if (imageList.length > 1)
            SizedBox(
              height: 80,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: imageList.map((imgUrl) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedImage = imgUrl;
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: selectedImage == imgUrl ? Colors.blue : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: imgUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Asset Name: ${widget.asset.AssetName ?? 'N/A'}",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text("Worth: ${widget.asset.AssetWorth ?? 'N/A'}"),
                SizedBox(height: 10),
                Text("Tenure: ${widget.asset.Tenure ?? 'N/A'}"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GradientBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.amber, Colors.white],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
