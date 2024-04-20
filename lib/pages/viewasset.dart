import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../models/clientuser.dart';

class ViewAsset extends StatefulWidget {
  const ViewAsset({super.key});

  @override
  State<ViewAsset> createState() => _ViewAssetState();
}

class _ViewAssetState extends State<ViewAsset> {


  @override
  Widget build(BuildContext context) {
    final clientprovider = Provider.of<clientusers>(context).userInfo;

    return  Scaffold(
appBar: AppBar( leading: IconButton(
  icon: Icon(Icons.arrow_back),
  onPressed: () {
    // Navigate back to the previous screen
    Navigator.of(context).pop();
  },
),),

      body: Column(
        children: [
      SizedBox(height: 3,),
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Container(

              height: 320,
              decoration: BoxDecoration(
                  color: Colors.black87,
                  border: Border.all(
                   // Set border color to black
                    width: 0// Set border thickness
                  ),
                  borderRadius: BorderRadius.circular(20)),
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
                        child: Text('${clientprovider?.username??""}',style: TextStyle(color: Colors.white24,fontSize: 15),),
                      ),
                    ],
                  ),
                  SizedBox(height:102),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 10.0),
                        child: Text("Daniel",style: TextStyle(color: Colors.white,fontSize: 24),),
                      ),
                      Text("|",style: TextStyle(color: Colors.white,fontSize: 24)),
                      Padding(
                        padding: const EdgeInsets.only(left: 10.0),
                        child: Text("Assets",style: TextStyle(color: Colors.white,fontSize: 24),),
                      ),
                      Text("|",style: TextStyle(color: Colors.white,fontSize: 24)),
                      Padding(
                        padding: const EdgeInsets.only(left: 10.0),
                        child: Text("Kins",style: TextStyle(color: Colors.white,fontSize: 24),),
                      ),

                    ],
                  ),

                ],
              ),
              width: MediaQuery.of(context).size.width,
              // Set the width to match the screen size
              padding: EdgeInsets.all(
                  8.0), // Optional: Add padding to the container
            ),
          ),
        ],
      ),
    );
  }
}
