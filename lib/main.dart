import 'package:dossier/pages/onboarding/onboarding.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

void main() {
  runApp(const MyApp());
}
  DatabaseReference Clientsdb = FirebaseDatabase.instance.ref().child("Clients");
displayToast(String message, BuildContext context) {
  Fluttertoast.showToast(msg: message);
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return MaterialApp(
      title: 'The Dossier.',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),

      home:  Onboarding(screenHeight: screenHeight,),
    );
  }
}



