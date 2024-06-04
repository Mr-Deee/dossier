import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

import '../main.dart';

class AddAsset extends StatefulWidget {
  const AddAsset({super.key});

  @override
  State<AddAsset> createState() => _AddAssetState();
}

class _AddAssetState extends State<AddAsset> {

  final DatabaseReference  _database = FirebaseDatabase.instance.reference();
final modelname = TextEditingController();
final vehiclenumber = TextEditingController();
final kinsmanname = TextEditingController();
final kinsmanmobilenumber = TextEditingController();
final type = TextEditingController();
final price = TextEditingController();
final Tenure = TextEditingController();
final assethandler = TextEditingController();
final location = TextEditingController();

List<File?> _images = [];

List<String> _imageUrls = [];
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
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
              Container(
                margin: EdgeInsets.only(top: 8),
                padding: EdgeInsets.all(10),
                child: TextField(
                  controller: kinsmanname,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Name Of Kinsman',
                    suffixIcon: Icon(Icons.drive_file_rename_outline),
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
                  controller: kinsmanmobilenumber,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'KinsMan Number',
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
              Column(
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 8),
                    padding: EdgeInsets.all(10),
                    child: TextField(
                      controller: type,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'AssetType',
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
                ],
              ),
              Container(
                margin: EdgeInsets.only(top: 8),
                padding: EdgeInsets.all(10),
                child: TextField(
                  controller: Tenure,
                  keyboardType: TextInputType.numberWithOptions(
                      signed: false, decimal: false),
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Tenure',
                    suffixIcon: Icon(Icons.calendar_month),
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
                  controller: assethandler,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Asset  Handler',
                    suffixIcon: Icon(Icons.drag_handle),
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
                  onPressed:()async{

                    addVehicle();
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

  void addVehicle() async {
    showLoadingDialog();
    try {
      // Upload images to Firebase Storage concurrently
      List<Future<void>> uploadFutures = _images.map((imageFile) async {
        if (imageFile != null) {
          final storageRef = FirebaseStorage.instance.ref().child(
            'vehicle_images/${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
          await storageRef.putFile(imageFile);
          final downloadURL = await storageRef.getDownloadURL();
          _imageUrls.add(downloadURL);
        }
      }).toList();

      await Future.wait(uploadFutures);

      addVehicledb();
    } catch (e) {
      // Handle errors
      print("Failed to upload images: $e");
      Navigator.pop(context); // Close the loading dialog
    }
  }

  void addVehicledb() {
    _database.child('vehicles').push().set({
      'AssetImages': _imageUrls,
      'AssetName': modelname.text,
      'KinsMan': kinsmanname.text,
      'AssetType': type,
      'Tenure': Tenure.text,
      'Location Of Assets': location.text,
      'AssetHandler': assethandler.text,
      'AssetWorth': double.tryParse(price.text) ?? 0.0,
      'location': location.text,
    }).then((_) {
      Navigator.pop(context); // Close the loading dialog
      displayToast("Added Successfully", context);
    }).catchError((error) {
      // Handle errors
      print("Failed to add vehicle: $error");
      Navigator.pop(context); // Close the loading dialog
    });
  }
  void showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            margin: EdgeInsets.all(15.0),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Padding(
              padding: EdgeInsets.all(15.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    SizedBox(width: 6.0),
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                    SizedBox(width: 26.0),
                    Text("Adding Asset, please wait..."),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

}
