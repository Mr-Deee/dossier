import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddAsset extends StatefulWidget {
  const AddAsset({super.key});

  @override
  State<AddAsset> createState() => _AddAssetState();
}

class _AddAssetState extends State<AddAsset> {
  final DatabaseReference _database = FirebaseDatabase.instance.reference();
  final TextEditingController modelname = TextEditingController();
  final TextEditingController vehiclenumber = TextEditingController();
  final TextEditingController kinsmanname = TextEditingController();
  final TextEditingController kinsmanmobilenumber = TextEditingController();
  final TextEditingController type = TextEditingController();
  final TextEditingController price = TextEditingController();
  final TextEditingController tenure = TextEditingController();
  final TextEditingController assethandler = TextEditingController();
  final TextEditingController location = TextEditingController();

  List<File?> _images = [];
  List<String> _imageUrls = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Add New Asset',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ListView(
            children: [
              SizedBox(height: 20),
              _buildImagePicker(),
              SizedBox(height: 20),
              _buildTextField(controller: modelname, label: 'Asset Name', icon: Icons.car_rental_rounded),
              _buildTextField(controller: kinsmanname, label: 'Name of Kinsman', icon: Icons.person),
              _buildTextField(controller: kinsmanmobilenumber, label: 'Kinsman Mobile Number', icon: Icons.phone),
              _buildTextField(controller: type, label: 'Asset Type', icon: Icons.category),
              _buildTextField(controller: tenure, label: 'Tenure (Years)', icon: Icons.calendar_today),
              _buildTextField(controller: price, label: 'Asset Worth', icon: Icons.attach_money, isNumber: true),
              _buildTextField(controller: assethandler, label: 'Asset Handler', icon: Icons.supervisor_account),
              _buildTextField(controller: location, label: 'Location of Asset', icon: Icons.pin_drop),
              SizedBox(height: 30),
              _buildConfirmButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(3, (index) => _imageSelectorContainer(index)),
      ),
    );
  }

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
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey),
        ),
        child: _images.length > index && _images[index] != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            _images[index]!,
            fit: BoxFit.cover,
          ),
        )
            : Icon(Icons.add_a_photo, color: Colors.grey[600]),
      ),
    );
  }

  Future<void> _pickImage(int index) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (_images.length < 3) {
          _images.add(File(pickedFile.path));
        }
      });
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isNumber = false,
  }) {
    return Container(
      margin: EdgeInsets.only(top: 16),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.grey[600]),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return Container(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          addVehicle();
        },
        child: Text('Confirm', style: TextStyle(fontSize: 18)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  void addVehicle() async {
    showLoadingDialog();
    try {
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
      print("Failed to upload images: $e");
      Navigator.pop(context); // Close loading dialog
    }
  }

  void addVehicledb() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    _database.child('Assets').push().set({
      'AssetImages': _imageUrls,
      'AssetName': modelname.text,
      'CurrentUser': userId,
      'KinsMan': kinsmanname.text,
      'AssetType': type.text,
      'Tenure': tenure.text,
      'Location': location.text,
      'AssetHandler': assethandler.text,
      'AssetWorth': double.tryParse(price.text) ?? 0.0,
    }).then((_) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Asset Added Successfully')),
      );
    }).catchError((error) {
      Navigator.pop(context); // Close loading dialog
    });
  }

  void showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
