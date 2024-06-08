import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../Assistants/assistantMethods.dart';
import '../models/clientuser.dart';
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
  AssistantMethods.getCurrentOnlineUserInfo(context);
  AssistantMethods.getCurrentAssetInfo(context);
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

int _selectedIndex = 0;

  void _onItemTapped(int index) {
  setState(() {
    _selectedIndex = index;
  });
}
  @override
  Widget build(BuildContext context) {
    final clientprovider = Provider.of<clientusers>(context).userInfo;
    final Size size = MediaQuery.of(context).size;


    List<Widget> _widgetOptions = <Widget>[

      Column(
        children: [

          Row(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 18.0, left: 18),
                    child: Text(
// '                       'Hi ' + '${clientProvider?.username ?? ""}!',
'                      style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)',
                    ),
                  ),
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0, left: 22),
                        child: Text(
                          '${_getSalutation()}',
                          style: TextStyle(fontSize: 15, color: Colors.black26),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ],
          ),
          SizedBox(height: 26),
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black, // Set border color to black
                  width: 4.0, // Set border thickness
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 18.0, left: 1),
                        child: Text('Welcome!', style: TextStyle(fontSize: 20)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 1.0, left: 8),
                        child: Text(
                          'Build Your Dossier!',
                          style: TextStyle(fontSize: 18, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 94, child: Image.asset(Cards.kcard4)),
                ],
              ),
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.all(8.0),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MyCard(),
                ViewAssetsCard(),
              ],
            ),
          ),
          SizedBox(height: 23),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              height: 190,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black,
                  width: 4.0,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 1.0, left: 8),
                        child: Text(
                          'Build Your Dossier!',
                          style: TextStyle(fontSize: 18, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 94, child: Image.asset(Cards.kcard4)),
                ],
              ),
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.all(8.0),
            ),
          ),
        ],
      ),
      // Add more widgets for different tabs
      Center(child: Text('Restaurant Menu')),
      Center(child: Text('Bookmark')),
      Center(child: Text('Notifications')),
    ];
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
                    child: Text('Hi '+'${clientprovider?.username??""}!', style: TextStyle(fontSize: 25,fontWeight: FontWeight.bold)),
                  ),
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0,left: 22),
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(

                  mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                MyCard(),
                ViewAssetsCard(),
              ]),
            ),

  SizedBox(height: 23,),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                height: 190,
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


]
      ),
    ),

    );
  }

}
class BNBCustomePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    Path path = Path()..moveTo(0, 20);
    path.quadraticBezierTo(size.width * .20, 0, size.width * .35, 0);
    path.quadraticBezierTo(size.width * .40, 0, size.width * .40, 20);
    path.arcToPoint(Offset(size.width * .60, 20),
        radius: Radius.circular(10.0), clockwise: false);

    path.quadraticBezierTo(size.width * .60, 0, size.width * .65, 0);
    path.quadraticBezierTo(size.width * .80, 0, size.width , 20);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawShadow(path, Colors.black, 5, true);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}