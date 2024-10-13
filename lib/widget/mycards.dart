import 'dart:io';
import 'dart:ui';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

import '../pages/AddAsset.dart';
import '../pages/viewasset.dart';

class MyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                AddAsset(),
          ),
        );
      },
      child: Container(
        height: 150,
        width: 180,
        margin: EdgeInsets.all(10),

        decoration: BoxDecoration(
          color: Colors.amber,
          borderRadius: BorderRadius.circular(20),
          boxShadow:  [BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ]),
        child: Column(
          children: [

            Expanded(
              flex: 2,
              child: Image.asset(Cards.kcard1),
            ),
        Center(
                child: Padding(
                  padding: const EdgeInsets.only(top:2.0,bottom: 20),
                  child: Text(
                    'Add An Asset',
                    style: TextStyle(
                      color: Colors.black38,
                      fontSize: 18,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ),

          ],
        ),
      ),
    );
  }
}
class ViewAssetsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ViewAsset(),
          ),
        );
      },
      child: Container(
        height: 150,
        width: 180,
        margin: EdgeInsets.all(10),

        decoration: BoxDecoration(
          color: Colors.white70,
          borderRadius: BorderRadius.circular(20),
          boxShadow:  [
            BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ]),
        child: Column(
          children: [

            Expanded(
              flex: 1,
              child: Image.asset(Cards.kcard5),
            ),
        Center(
                child: Padding(
                  padding: const EdgeInsets.only(top:2.0,bottom: 20),
                  child: Text(
                    'View Assets',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 18,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ),

          ],
        ),
      ),
    );
  }

}
// class MyCard2 extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         _showPopup(context);
//       },
//       child: Container(
//         height: 200,
//         width: 150,
//         margin: EdgeInsets.all(10),
//
//         decoration: BoxDecoration(
//           color: Colors.black,
//           borderRadius: BorderRadius.circular(10),
//           boxShadow:  [BoxShadow(
//             color: Colors.grey.withOpacity(0.5),
//             spreadRadius: 5,
//             blurRadius: 7,
//             offset: Offset(0, 3),
//           ),
//         ]),
//         child: Column(
//           children: [
//
//             Expanded(
//               flex: 1,
//               child: Image.asset(Cards.kcard1),
//             ),
//         Center(
//                 child: Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: Text(
//                     'Exst -Asset',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold
//                     ),
//                   ),
//                 ),
//               ),
//
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _showPopup(BuildContext context) {
//     showDialog(
//         context: context,
//         builder: (BuildContext context) {
//           return Dialog(
//             backgroundColor: Colors.transparent,
//             child: Stack(
//               alignment: Alignment.center,
//               children: [
//                 BackdropFilter(
//                   filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//                   child: Container(
//                     color: Colors.black.withOpacity(0.5),
//                   ),
//                 ),
//               ],
//             ),
//           );
//
//
//         });
//   }
// }

class Cards {
  static const String kcard1 = 'assets/images/dd.png';
  static const String kcard2 = 'assets/images/assn.png';
  static const String kcard4 = 'assets/images/asset1.png';
  static const String kcard3 = 'assets/images/acc.jpg';
  static const String kcard5 = 'assets/images/assets2.png';
}


