import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../widget/themeprovider.dart'; // Ensure you have provider set up



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
  final TextEditingController passwordController = TextEditingController(); // Password Controller
  String? selectedAssetType;
  List<String> assetTypes = ['Car', 'House', 'Land', 'Equipment'];

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
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'New Asset',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
        child: Lottie.asset(
          'assets/animations/loading.json',
          width: 120,
          height: 120,
        ),
      )
          : Stepper(
        currentStep: _currentStep,
        onStepContinue: _nextStep,
        onStepCancel: _prevStep,
        type: StepperType.vertical,
        controlsBuilder: (BuildContext context, ControlsDetails details) {
          return Row(
            children: <Widget>[
              if (_currentStep != 0)
                ElevatedButton(
                  onPressed: details.onStepCancel,
                  child: const Text('Back',style: TextStyle(color: Colors.white),),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                  ),
                ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: details.onStepContinue,
                child: Text(
                  _currentStep == 3 ? 'Submit' : 'Next',
                  style: TextStyle(color: Colors.white),
                ),
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
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: Text('Details'),
            content: _buildDetailsForm(),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: Text('Notification'),
            content: _buildNotificationForm(),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: Text('Password'),
            content: _buildPasswordForm(), // New step for password
            isActive: _currentStep >= 3,
            state: _currentStep > 3 ? StepState.complete : StepState.indexed,
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    if (_currentStep == 0) {
      // Validate Image Selection
      if (_images.isEmpty) {
        _showCustomSnackBar('Please select at least one image');
        return;
      }
    } else if (_currentStep == 1) {
      // Validate Details Form
      if (modelname.text.isEmpty ||
           nameofT.text.isEmpty ||
          contactoft.text.isEmpty ||
           kinsmanmobilenumber.text.isEmpty ||
           kinsmanname.text.isEmpty ||
           assetTypes.isEmpty ||
          tenure.text.isEmpty ||
          price.text.isEmpty ||
          assethandler.text.isEmpty ||
          location.text.isEmpty) {
        _showCustomSnackBar('Please fill out all fields');
        return;
      }
    } else if (_currentStep == 2) {
      // Validate Notification Fields
      if (selectedDate == null ||
          selectedTime == null ||
          selectedProtocol == null ||
          selectedInterval == null) {
        _showCustomSnackBar('Please complete the notification schedule');
        return;
      }
    } else if (_currentStep == 3) {
      // Validate Password
      if (passwordController.text.isEmpty) {
        _showCustomSnackBar('Please enter your password');
        return;
      }
      // Submit the form
      addAsset();
      return;
    }

    if (_currentStep < 3) {
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

  void _showCustomSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
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
        SizedBox(height: 12),

        _buildTextField(controller: nameofT, label: 'Trustworthy Person', icon: Icons.security),
        SizedBox(height: 12),
        _buildTextField(controller: contactoft, label: 'Phone Number Trustworthy Person', icon: Icons.phone, isNumber: true),
        SizedBox(height: 12),
        _buildTextField(controller: kinsmanmobilenumber, label: 'Kinsman Mobile Number', icon: Icons.phone, isNumber: true),
        SizedBox(height: 12),
        _buildTextField(controller: kinsmanname, label: 'Name of Kinsman', icon: Icons.person),
        SizedBox(height: 12),
        _buildDropdownField(), // Replaced text field with a dropdown menu
        SizedBox(height: 12),
        _buildTextField(controller: tenure, label: 'Tenure', icon: Icons.access_time),
        SizedBox(height: 12),
        _buildTextField(controller: price, label: 'Asset Price', icon: Icons.attach_money, isNumber: true),
        SizedBox(height: 12),
        _buildTextField(controller: assethandler, label: 'Asset Handler', icon: Icons.person_add),
        SizedBox(height: 12),
        _buildTextField(controller: location, label: 'Location', icon: Icons.location_on),
      ],
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.black),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildNotificationForm() {
    return Column(
      children: [
        ListTile(
          title: Text('Select Notification Protocol'),
          trailing: DropdownButton(
            value: selectedProtocol, // Set the current value
            items: protocolList.map((protocol) {
              return DropdownMenuItem(
                child: Text(protocol),
                value: protocol,
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedProtocol = value; // Update the selected value
              });
            },
            hint: Text('Select Protocol'),
          ),
        ),
        ListTile(
          title: Text('Select Notification Interval'),
          trailing: DropdownButton(
            value: selectedInterval, // Set the current value
            items: intervalList.map((interval) {
              return DropdownMenuItem(
                child: Text(interval),
                value: interval,
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedInterval = value; // Update the selected value
              });
            },
            hint: Text('Select Interval'),
          ),
        ),
        ListTile(
          title: Text('Select Date'),
          trailing: TextButton(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: selectedDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
              );
              setState(() {
                selectedDate = date;
              });
            },
            child: Text(selectedDate != null ? DateFormat('yyyy-MM-dd').format(selectedDate!) : 'Choose Date'),
          ),
        ),
        ListTile(
          title: Text('Select Time'),
          trailing: TextButton(
            onPressed: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: selectedTime ?? TimeOfDay.now(),
              );
              setState(() {
                selectedTime = time;
              });
            },
            child: Text(selectedTime != null ? selectedTime!.format(context) : 'Choose Time'),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Asset Type',
        prefixIcon: Icon(Icons.category),
        border: OutlineInputBorder(),
      ),
      value: selectedAssetType,
      items: assetTypes.map((String assetType) {
        return DropdownMenuItem<String>(
          value: assetType,
          child: Text(assetType),
        );
      }).toList(),
      onChanged: (newValue) {
        setState(() {
          selectedAssetType = newValue;
        });
      },
      validator: (value) => value == null ? 'Please select an asset type' : null,
    );
  }




  Widget _buildPasswordForm() {
    return TextField(
      controller: passwordController,
      obscureText: true,
      decoration: InputDecoration(
        labelText: 'Enter Password',
        prefixIcon: Icon(Icons.lock, color: Colors.black),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void addAsset() async {
    if (selectedDate == null || selectedTime == null || selectedProtocol == null || selectedInterval == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please complete the notification schedule')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final userId = user.uid;
      final email = user.email;
      final assetRef = _database.child('Assets').push();
      final notificationRef = _database.child('Notifications').push();

      // **1. Upload images concurrently with controlled concurrency**
      final List<Future<String>> uploadTasks = _images
          .where((image) => image != null)
          .map((imageFile) async {
        final storageRef = FirebaseStorage.instance.ref().child(
          'asset_images/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        final uploadTask = storageRef.putFile(imageFile!);
        return uploadTask.then((task) => task.ref.getDownloadURL());
      })
          .toList();

      // Start uploading images while preparing data
      final Future<List<String>> imageUploadFuture = Future.wait(uploadTasks);

      // **2. Prepare asset and notification data**
      final assetData = {
        'uid': userId,
        'email': email,
        'AssetName': modelname.text,
        'CurrentUser': userId,
        'KinsMan': kinsmanname.text,
        'AssetType': selectedAssetType,
        'ContactofTrustworthy': contactoft.text,
        'NameofTrustworthy': nameofT.text,
        'Tenure': tenure.text,
        'Location': location.text,
        'AssetHandler': assethandler.text,
        'AssetWorth': double.tryParse(price.text) ?? 0.0,
      };

      final notificationData = {
        'assetId': assetRef.key,
        'protocol': selectedProtocol,
        'interval': selectedInterval,
        'scheduledDate': DateFormat('yMMMd').format(selectedDate!),
        'scheduledTime': selectedTime!.format(context),
        'NotificationID': notificationRef.key,
      };

      // **3. Upload images & write data in parallel**
      final List<String> imageUrls = await imageUploadFuture; // Get image URLs
      assetData['AssetImages'] = imageUrls; // Attach images

      await _database.update({
        '/Assets/${assetRef.key}': assetData,
        '/Notifications/${notificationRef.key}': notificationData,
      });

      // **4. Completion**
      _showCustomSnackBar('Asset added successfully!');
      _clearFields();
    } catch (error) {
      print('Error adding asset: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add asset. Please try again.')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

void _clearFields() {
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
  passwordController.clear();
  _images.clear();
  _imageUrls.clear();
  selectedDate = null;
  selectedTime = null;
  selectedProtocol = null;
  selectedInterval = null;
  _currentStep = 0;
}

}
