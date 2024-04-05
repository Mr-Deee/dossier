import 'package:dossier/pages/login.dart';
import 'package:dossier/pages/onboarding/onboarding.dart';
import 'package:dossier/pages/register.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import 'models/clientuser.dart';

void main() {
  runApp(
      MultiProvider(providers: [
        ChangeNotifierProvider<clientusers>(
          create: (context) => clientusers(),
        ),

      ],

          child: MyApp()
      )
  );
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

        initialRoute: FirebaseAuth.instance.currentUser == null
            ? '/authpage'
            : '/GasDash',
        routes: {

          // "/splash": (context) => SplashScreen(),
          // "/search": (context) => SearchScreen(),
          "/login": (context) => LoginPage(),
          "/register": (context) => RegisterPage(),
          // "/Homepage": (context) =>Homepage(),
        });

  }
}



