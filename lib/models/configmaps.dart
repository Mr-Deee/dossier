import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
String mapKey ="AIzaSyC6UDM8O3wlMa5SNLHfcM8MGEFJ3ejc55U";
// String mapKey ="AIzaSyAoWcS8ouThAVE4whiZVTRwanEqq8nSMT8";
User? firebaseUser;
int wmsRequestTimeOut = 40;
User? userCurrentInfo;

String RequestStatus = "";



