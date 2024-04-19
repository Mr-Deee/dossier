import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../constants.dart';

class ViewAsset extends StatefulWidget {
  const ViewAsset({super.key});

  @override
  State<ViewAsset> createState() => _ViewAssetState();
}

class _ViewAssetState extends State<ViewAsset> {
  @override
  Widget build(BuildContext context) {
    return  Scaffold(


      body: Column(
        children: [
SizedBox(height: 39,),
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.black, // Set border color to black
                    width: 4.0, // Set border thickness
                  ),
                  borderRadius: BorderRadius.circular(20)),
              // Set the background color to black
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 18.0, left: 1),
                        child:
                        Text('Welcome!', style: TextStyle(fontSize: 20)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 1.0, left: 8),
                        child: Text('Build Your Dossier!',
                            style: TextStyle(
                                fontSize: 18, color: Colors.black54)),
                      ),
                    ],
                  ),

                  SizedBox(height: 94, child: Image.asset(Cards.kcard4)),

                  // Add your children widgets here
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
