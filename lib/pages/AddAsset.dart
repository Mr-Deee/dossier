import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:provider/provider.dart'; // Ensure you have provider set up

// Dummy Providers for demonstration. Replace with your actual providers.
class ClientUsers {
  final userInfo = {'id': 'user123', 'name': 'John Doe'};
}

class MyAssets {
  final myAssetInfo = {'id': 'asset123'};
}

class AddAsset extends StatefulWidget {
  const AddAsset({super.key});

  @override
  State<AddAsset> createState() => _AddAssetState();
}

class _AddAssetState extends State<AddAsset> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final TextEditingController modelname = TextEditingController();
  final TextEditingController vehiclenumber = TextEditingController();
  final TextEditingController kinsmanname = TextEditingController();
  final TextEditingController nameofT = TextEditingController();
  final TextEditingController contactoft = TextEditingController();
  final TextEditingController kinsmanmobilenumber = TextEditingController();
  final TextEditingController type = TextEditingController();
  final TextEditingController price = TextEditingController();
  final TextEditingController tenure = TextEditingController();
  final TextEditingController assethandler = TextEditingController();
  final TextEditingController location = TextEditingController();

  List<File?> _images = [];
  List<String> _imageUrls = [];

  int _currentStep = 0;
  bool _isLoading = false;

  // Controllers for Notification Scheduling
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String? selectedProtocol;
  String? selectedInterval;

  final List<String> protocolList = ["Email", "Text Message"];
  final List<String> intervalList = ["Monthly", "Yearly", "Two Years"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'New Asset',
          // style:GoogleFonts.cormorantInfant(
          //   fontWeight: FontWeight.bold
          // ),
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Stepper(
        currentStep: _currentStep,
        onStepContinue: _nextStep,
        onStepCancel: _prevStep,
        type: StepperType.horizontal,
        controlsBuilder: (BuildContext context, ControlsDetails details) {
          return Row(
            children: <Widget>[
              if (_currentStep != 0)
                ElevatedButton(
                  onPressed: details.onStepCancel,
                  child: const Text('Back'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                  ),
                ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: details.onStepContinue,
                child: Text(_currentStep == 2 ? 'Submit' : 'Next',style:TextStyle(color: Colors.white),),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                ),
              ),
            ],
          );
        },
        steps: [
          Step(
            title: Text('Images'),
            content: _buildImagePicker(),
            isActive: _currentStep >= 0,
            state: _currentStep > 0
                ? StepState.complete
                : StepState.indexed,
          ),
          Step(
            title: Text('Details'),
            content: _buildDetailsForm(),
            isActive: _currentStep >= 1,
            state: _currentStep > 1
                ? StepState.complete
                : StepState.indexed,
          ),
          Step(
            title: Text('Notification'),
            content: _buildNotificationForm(),
            isActive: _currentStep >= 2,
            state: _currentStep > 2
                ? StepState.complete
                : StepState.indexed,
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    if (_currentStep == 0) {
      // Validate Image Selection
      if (_images.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select at least one image')),
        );
        return;
      }
    } else if (_currentStep == 1) {
      // Validate Details Form
      if (modelname.text.isEmpty ||
          nameofT.text.isEmpty ||
          contactoft.text.isEmpty ||
          kinsmanmobilenumber.text.isEmpty ||
          kinsmanname.text.isEmpty ||
          type.text.isEmpty ||
          tenure.text.isEmpty ||
          price.text.isEmpty ||
          assethandler.text.isEmpty ||
          location.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please fill out all fields')),
        );
        return;
      }
    } else if (_currentStep == 2) {
      // Submit the form
      addAsset();
      return;
    }

    if (_currentStep < 2) {
      setState(() {
        _currentStep += 1;
      });
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep -= 1;
      });
    }
  }

  Widget _buildImagePicker() {
    return Column(
      children: [
        Text(
          'Add Asset Images',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(3, (index) => _imageSelectorContainer(index)),
          ),
        ),
      ],
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
          border: Border.all(color: Colors.black),
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
        if (_images.length > index) {
          _images[index] = File(pickedFile.path);
        } else {
          _images.add(File(pickedFile.path));
        }
      });
    }
  }

  Widget _buildDetailsForm() {
    return Column(
      children: [
        _buildTextField(controller: modelname, label: 'Asset Name', icon: Icons.car_rental_rounded),
        _buildTextField(controller: nameofT, label: 'Trustworthy Person', icon: Icons.security),
        _buildTextField(controller: contactoft, label: 'Phone Number Trustworthy Person', icon: Icons.phone, isNumber: true),
        _buildTextField(controller: kinsmanmobilenumber, label: 'Kinsman Mobile Number', icon: Icons.phone, isNumber: true),
        _buildTextField(controller: kinsmanname, label: 'Name of Kinsman', icon: Icons.person),
        _buildTextField(controller: type, label: 'Asset Type', icon: Icons.category),
        _buildTextField(controller: tenure, label: 'Tenure (Years)', icon: Icons.calendar_today, isNumber: true),
        _buildTextField(controller: price, label: 'Asset Worth', icon: Icons.attach_money, isNumber: true),
        _buildTextField(controller: assethandler, label: 'Asset Handler', icon: Icons.supervisor_account),
        _buildTextField(controller: location, label: 'Location of Asset', icon: Icons.pin_drop),
      ],
    );
  }

  Widget _buildNotificationForm() {
    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.calendar_today, color: Colors.blueAccent),
          title: Text(
            selectedDate == null
                ? 'Select Date'
                : DateFormat('yMMMd').format(selectedDate!),
            style: TextStyle(fontSize: 16),
          ),
          onTap: _pickDate,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: BorderSide(color: Colors.grey, width: 1.0),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        ),
        SizedBox(height: 10),
        ListTile(
          leading: Icon(Icons.access_time, color: Colors.blueAccent),
          title: Text(
            selectedTime == null
                ? 'Select Time'
                : selectedTime!.format(context),
            style: TextStyle(fontSize: 16),
          ),
          onTap: _pickTime,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: BorderSide(color: Colors.grey, width: 1.0),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        ),
        SizedBox(height: 10),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: "Protocol",
            icon: Icon(Icons.email, color: Colors.blueAccent),
            border: OutlineInputBorder(),
          ),
          value: selectedProtocol,
          items: protocolList.map((protocol) {
            return DropdownMenuItem<String>(
              value: protocol,
              child: Text(protocol),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              selectedProtocol = newValue;
            });
          },
        ),
        SizedBox(height: 10),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: "Interval",
            icon: Icon(Icons.schedule, color: Colors.blueAccent),
            border: OutlineInputBorder(),
          ),
          value: selectedInterval,
          items: intervalList.map((interval) {
            return DropdownMenuItem<String>(
              value: interval,
              child: Text(interval),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              selectedInterval = newValue;
            });
          },
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    DateTime initialDate = DateTime.now().add(Duration(days: 1));
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  Future<void> _pickTime() async {
    TimeOfDay initialTime = TimeOfDay.now();
    TimeOfDay? pickedTime =
    await showTimePicker(context: context, initialTime: initialTime);
    if (pickedTime != null) {
      setState(() {
        selectedTime = pickedTime;
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

  void addAsset() async {
    // Validate Notification Fields
    if (selectedDate == null ||
        selectedTime == null ||
        selectedProtocol == null ||
        selectedInterval == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please complete the notification schedule')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload images to Firebase Storage
      List<Future<void>> uploadFutures = _images.map((imageFile) async {
        if (imageFile != null) {
          final storageRef = FirebaseStorage.instance.ref().child(
            'asset_images/${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
          await storageRef.putFile(imageFile);
          final downloadURL = await storageRef.getDownloadURL();
          _imageUrls.add(downloadURL);
        }
      }).toList();

      await Future.wait(uploadFutures); // Wait for all uploads to complete

      // Add asset data to Firebase Database
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final email = FirebaseAuth.instance.currentUser?.email;
      final assetRef = _database.child('Assets').push();
      await assetRef.set({
        'uid': userId,
        'email': email,
        'AssetImages': _imageUrls,
        'AssetName': modelname.text,
        'CurrentUser': userId,
        'KinsMan': kinsmanname.text,
        'AssetType': type.text,
        'ContactofTrustworthy': contactoft.text,
        'NameofTrustworthy': nameofT.text,
        'Tenure': tenure.text,
        'Location': location.text,
        'AssetHandler': assethandler.text,
        'AssetWorth': double.tryParse(price.text) ?? 0.0,
        'Notification': {
          'notificationId': assetRef.key,    // Notification reference key
          'protocol': selectedProtocol,             // Protocol selected by the user
          'interval': selectedInterval,             // Interval for notification (daily, weekly, etc.)
          'scheduledDate': DateFormat('yMMMd').format(selectedDate!), // Scheduled date for the notification
          'scheduledTime': selectedTime!.format(context),             // Scheduled time for the notification
        },
      });

      // Schedule Notification
      final notificationRef = _database.child('Notifications').push();
      await notificationRef.set({
        'assetId': assetRef.key,
        'protocol': selectedProtocol,
        'interval': selectedInterval,
        'scheduledDate': DateFormat('yMMMd').format(selectedDate!),
        'scheduledTime': selectedTime!.format(context),
        'NotificationID': notificationRef.key,
      });

      setState(() {
        _isLoading = false;
      });

      // Show Success Snackbar with Custom Styling
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Asset Added and Notification Scheduled Successfully",
            style: TextStyle(
              color: Colors.white, // Text color
              fontWeight: FontWeight.bold, // Bold text
            ),
          ),
          backgroundColor: Colors.green, // Background color
          behavior: SnackBarBehavior.floating, // Makes the snackbar float
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10), // Rounded corners
          ),
          duration: const Duration(seconds: 3), // Duration the snackbar is shown
          action: SnackBarAction(
            label: "Undo",
            textColor: Colors.yellow, // Button text color
            onPressed: () {
              // Your undo action code here
              // For example, you might want to delete the recently added asset
            },
          ),
        ),
      );

      // Reset the form
      _resetForm();
    } catch (e) {
      print("Failed to add asset: $e");
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add asset. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _resetForm() {
    setState(() {
      _currentStep = 0;
      _images = [];
      _imageUrls = [];
      modelname.clear();
      vehiclenumber.clear();
      kinsmanname.clear();
      nameofT.clear();
      contactoft.clear();
      kinsmanmobilenumber.clear();
      type.clear();
      price.clear();
      tenure.clear();
      assethandler.clear();
      location.clear();
      selectedDate = null;
      selectedTime = null;
      selectedProtocol = null;
      selectedInterval = null;
    });
  }
}
