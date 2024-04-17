import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../widget/mycards.dart';

class homepage extends StatefulWidget {
  const homepage({super.key});

  @override
  State<homepage> createState() => _homepageState();
}

class _homepageState extends State<homepage> {
@override
  void initState() {
  _getSalutation();
    // TODO: implement initState
    super.initState();
  }
  String _getSalutation() {
    var hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 18) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "DOSSIER",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        child: Column(
          children: [
            Row(children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 18.0, left: 18),
                    child: Text('Hi Daniel!', style: TextStyle(fontSize: 25)),
                  ),
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Text('${_getSalutation()}',
                            style:
                                TextStyle(fontSize: 15, color: Colors.black26)),
                      ),
                    ],
                  )
                ],
              ),
            ]),
            SizedBox(
              height: 26,
            ),
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
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              MyCard(),
              ViewAssetsCard(),
            ]),
          ],
        ),
      ),
    );
  }
}
