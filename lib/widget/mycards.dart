import 'dart:io';
import 'dart:ui';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

import '../pages/viewasset.dart';

class MyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _showPopup(context);
      },
      child: Container(
        height: 180,
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
              flex: 1,
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

  void _showPopup(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Stack(
              alignment: Alignment.center,
              children: [
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
                Container(

                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: NewVehicle()
                ),
              ],
            ),
          );
        });
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
        height: 180,
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

  void _showPopup(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Stack(
              alignment: Alignment.center,
              children: [
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
                Container(

                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: NewVehicle()
                ),
              ],
            ),
          );
        });
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


class NewVehicle extends StatefulWidget {
  const NewVehicle({Key? key}) : super(key: key);

  @override
  State<NewVehicle> createState() => _NewVehicleState();
}

class _NewVehicleState extends State<NewVehicle> {
  final DatabaseReference  _database = FirebaseDatabase.instance.reference();
  final modelname = TextEditingController();
  final vehiclenumber = TextEditingController();
  final mobilenumber = TextEditingController();
  final type = TextEditingController();
  final price = TextEditingController();
  final seat = TextEditingController();
  final location = TextEditingController();

  List<File?> _images = [];

  List<String> _imageUrls = [];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white.withOpacity(0.8),
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0),
        elevation: 0,
        title: Text(
          'Add Asset ',
          style: TextStyle(
            fontFamily: 'Bowlby',
            color: Colors.black,
            fontSize: MediaQuery.of(context).size.aspectRatio * 70,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          scrollDirection: Axis.vertical,
          children: [
            Column(
              children: <Widget>[
                // Your existing text fields...
                // Add image picker button
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    margin: EdgeInsets.only(top: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _imageSelectorContainer(0),
                        _imageSelectorContainer(1),
                        _imageSelectorContainer(2),
                      ],
                    ),
                  ),
                ),

                Container(
                  margin: EdgeInsets.only(top: 25),
                  padding: EdgeInsets.all(10),
                  child: TextField(
                    controller: modelname,
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Asset Name',
                      suffixIcon: Icon(Icons.car_rental_rounded),
                      floatingLabelStyle: TextStyle(
                          color: Colors.blue,
                          fontSize: 25,
                          fontWeight: FontWeight.bold),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(17),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                        (BorderSide(width: 1.0, color: Colors.black)),
                        borderRadius: BorderRadius.all(
                          Radius.circular(17),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                        (BorderSide(width: 1.0, color: Colors.blue)),
                        borderRadius: BorderRadius.all(
                          Radius.circular(17),
                        ),
                      ),
                    ),
                  ),
                ),
                // Container(
                //   margin: EdgeInsets.only(top: 8),
                //   padding: EdgeInsets.all(10),
                //   child: TextField(
                //     controller: vehiclenumber,
                //     keyboardType: TextInputType.text,
                //     textInputAction: TextInputAction.next,
                //     decoration: InputDecoration(
                //       labelText: 'Vehicle Number',
                //       suffixIcon: Icon(Icons.numbers_rounded),
                //       floatingLabelStyle: TextStyle(
                //           color: Colors.blue,
                //           fontSize: 25,
                //           fontWeight: FontWeight.bold),
                //       border: OutlineInputBorder(
                //         borderRadius: BorderRadius.all(
                //           Radius.circular(17),
                //         ),
                //       ),
                //       enabledBorder: OutlineInputBorder(
                //         borderSide:
                //         (BorderSide(width: 1.0, color: Colors.black)),
                //         borderRadius: BorderRadius.all(
                //           Radius.circular(17),
                //         ),
                //       ),
                //       focusedBorder: OutlineInputBorder(
                //         borderSide:
                //         (BorderSide(width: 1.0, color: Colors.blue)),
                //         borderRadius: BorderRadius.all(
                //           Radius.circular(17),
                //         ),
                //       ),
                //     ),
                //   ),
                // ),
                Container(
                  margin: EdgeInsets.only(top: 8),
                  padding: EdgeInsets.all(10),
                  child: TextField(
                    controller: mobilenumber,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Mobile Number',
                      suffixIcon: Icon(Icons.phone_android_rounded),
                      floatingLabelStyle: TextStyle(
                          color: Colors.blue,
                          fontSize: 25,
                          fontWeight: FontWeight.bold),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(17),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                        (BorderSide(width: 1.0, color: Colors.black)),
                        borderRadius: BorderRadius.all(
                          Radius.circular(17),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                        (BorderSide(width: 1.0, color: Colors.blue)),
                        borderRadius: BorderRadius.all(
                          Radius.circular(17),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 8),
                  padding: EdgeInsets.all(10),
                  child: TextField(
                    controller: type,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Type',
                      suffixIcon: Icon(Icons.select_all_sharp),
                      floatingLabelStyle: TextStyle(
                          color: Colors.blue,
                          fontSize: 25,
                          fontWeight: FontWeight.bold),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(17),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                        (BorderSide(width: 1.0, color: Colors.black)),
                        borderRadius: BorderRadius.all(
                          Radius.circular(17),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                        (BorderSide(width: 1.0, color: Colors.blue)),
                        borderRadius: BorderRadius.all(
                          Radius.circular(17),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 8),
                  padding: EdgeInsets.all(10),
                  child: TextField(
                    controller: seat,
                    keyboardType: TextInputType.numberWithOptions(
                        signed: false, decimal: false),
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'No.of Seats',
                      suffixIcon: Icon(Icons.chair),
                      floatingLabelStyle: TextStyle(
                          color: Colors.blue,
                          fontSize: 25,
                          fontWeight: FontWeight.bold),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(17),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                        (BorderSide(width: 1.0, color: Colors.black)),
                        borderRadius: BorderRadius.all(
                          Radius.circular(17),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                        (BorderSide(width: 1.0, color: Colors.blue)),
                        borderRadius: BorderRadius.all(
                          Radius.circular(17),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 8),
                  padding: EdgeInsets.all(10),
                  child: TextField(
                    controller: price,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      //labelText: 'Price',
                      hintText: 'Worth Of Asset',
                      prefixIcon: Icon(Icons.attach_money),
                      floatingLabelStyle: TextStyle(
                          color: Colors.blue,
                          fontSize: 25,
                          fontWeight: FontWeight.bold),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(17),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                        (BorderSide(width: 1.0, color: Colors.black)),
                        borderRadius: BorderRadius.all(
                          Radius.circular(17),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                        (BorderSide(width: 1.0, color: Colors.blue)),
                        borderRadius: BorderRadius.all(
                          Radius.circular(17),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 8),
                  padding: EdgeInsets.all(10),
                  child: TextField(
                    controller: location,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'Location Of Asset',
                      suffixIcon: Icon(Icons.pin_drop),
                      floatingLabelStyle: TextStyle(
                          color: Colors.blue,
                          fontSize: 25,
                          fontWeight: FontWeight.bold),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(17),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                        (BorderSide(width: 1.0, color: Colors.black)),
                        borderRadius: BorderRadius.all(
                          Radius.circular(17),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                        (BorderSide(width: 1.0, color: Colors.blue)),
                        borderRadius: BorderRadius.all(
                          Radius.circular(17),
                        ),
                      ),
                    ),
                  ),
                ),

                // ElevatedButton(
                //   onPressed: () {
                //     _pickImage(index);
                //   },
                //   child: Text('Select Image'),
                // ),
                SizedBox(height: 10),
                // Display selected images

                Container(
                  margin: EdgeInsets.only(top: 10, left: 10),
                  width: MediaQuery.of(context).size.width * 0.5,
                  height: MediaQuery.of(context).size.height * 0.075,
                  child: ElevatedButton(
                    onPressed:(){

                      addvehicle();
                      // addVehicledb();
                    },
                    child: Text(
                      'Confirm',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontFamily: 'DelaGothic',
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      enableFeedback: false,
                      elevation: 20,
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // void addvehicle() async {
  //   // Upload images to Firebase Storage
  //   for (var imageFile in _images) {
  //     if (imageFile != null) {
  //       // You need to implement Firebase initialization before this step
  //       final storageRef =
  //       firebase_storage.FirebaseStorage.instance.ref().child(
  //         'vehicle_images/${DateTime.now().millisecondsSinceEpoch}.jpg',
  //       );
  //       await storageRef.putFile(imageFile);
  //       // Get download URL of uploaded image (you can save this URL to Firestore or Realtime Database)
  //       final String downloadURL = await storageRef.getDownloadURL();
  //       // Here you can do something with the download URL, like saving it to Firestore
  //       print('Download URL: $downloadURL');
  //     }
  //   }
  //
  //   // Rest of your code...
  //   Navigator.pushReplacementNamed(context, '/homepage', arguments: {
  //     'modelname': modelname.text,
  //     'price': price.text,
  //     'type': type.text,
  //     'mobilenumber': mobilenumber.text,
  //     'seat': seat.text,
  //     'vehiclenumber': vehiclenumber.text,
  //     'location': location.text,
  //   });
  // }

  Widget _imageSelectorContainer(int index) {
    return GestureDetector(
      onTap: () {
        _pickImage(index);
      },
      child: Container(
        width: 100,
        height: 100,
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: _images.length > index && _images[index] != null
              ? Image.file(_images[index]!)
              : Icon(Icons.add),
        ),
      ),
    );
  }
  void _pickImage(int index) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (_images.length < 3) {
          _images.add(File(pickedFile.path));
        } else {
          // Show error message or limit reached message
          // You can use a SnackBar for this purpose
        }
      });
    }
  }

  void addvehicle() async {
    // Upload images to Firebase Storage
    for (var imageFile in _images) {
      if (imageFile != null) {
        final storageRef =
        FirebaseStorage.instance.ref().child(
          'vehicle_images/${DateTime
              .now()
              .millisecondsSinceEpoch}.jpg',
        );
        await storageRef.putFile(imageFile);
        final downloadURL = await storageRef.getDownloadURL();
        _imageUrls.add(downloadURL);
      }
    }
  }


}