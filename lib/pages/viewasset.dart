import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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
    final clientProvider = Provider.of<clientusers>(context, listen: false).userInfo;
    final  assetProvider = Provider.of<myassets>(context, listen: false).myassetinfo ;

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
    final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref().child('Assets');
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            // Navigate back to the previous screen
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Column(
        children: [ SizedBox(
          height: 3,
        ),
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Container(
              height: 195,
              decoration: BoxDecoration(
                color: Colors.black87,
                border: Border.all(),
                borderRadius: BorderRadius.circular(20),
              ),
              // Set the background color to black
              child: Column(
                // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(height: 104, child: Image.asset(Cards.kcard4)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 12.0),
                        child: Text(
                          '${clientProvider?.username ?? ""}',
                          style: TextStyle(color: Colors.white70, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              width: MediaQuery.of(context).size.width,
              // Set the width to match the screen size
              padding: EdgeInsets.all(8.0), // Optional: Add padding to the container
            ),
          ),
Expanded(child:  StreamBuilder(
              stream: _databaseReference.orderByChild('CurrentUser').equalTo(firebaseUser?.uid).onValue,
              builder: (BuildContext context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(), // Circular progress indicator
                  );
                }
            
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
            
                List<myassets> filteredAssets = [];
                if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                  Map<dynamic, dynamic>? map = snapshot.data!.snapshot.value as Map<dynamic, dynamic>?;
                  map!.forEach((key, value) {
                    // Assuming MyAsset is the class representing assets
                    myassets asset = myassets.fromMap(value.cast<String, dynamic>());
                    filteredAssets.add(asset);
                  });
                }
            
                return ListView.builder(
                  itemCount: filteredAssets.length,
                  itemBuilder: (context, index) {
                    final asset = filteredAssets[index];
                    return Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          border: Border.all(width: 0),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        width: MediaQuery.of(context).size.width,
                        child: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                asset.AssetName ?? '',
                                style: TextStyle(color: Colors.white70, fontSize: 18),
                              ),
                              Text(
                                asset.AssetType ?? '',
                                style: TextStyle(color: Colors.white54, fontSize: 15),
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
          ),
        ],
      ),
    );
  }
}