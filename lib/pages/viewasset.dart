import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../models/clientuser.dart';
import '../models/myassest.dart'; // Assuming you have a model for assets

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
                    myassets.fromMap(value.cast<String, dynamic>());
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

  const AssetDetailsScreen({required this.asset});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(asset.AssetName ?? "Asset Details"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              asset.AssetImages ?? '',
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            SizedBox(height: 16),
            Text(
              asset.AssetName ?? '',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Worth: ${asset.AssetWorth ?? ''}'),
            SizedBox(height: 8),
            Text('Category: ${asset.AssetType ?? 'N/A'}'),
            SizedBox(height: 8),
            Text('Description: ${asset.AssetName ?? 'No description available'}'),
          ],
        ),
      ),
    );
  }
}
