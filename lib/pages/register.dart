import 'package:fluttertoast/fluttertoast.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import 'login.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  var rememberValue = false;
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme
          .of(context)
          .colorScheme
          .background,
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Dossier',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 40,
              ),
            ),
            const SizedBox(
              height: 60,
            ),
            Form(
              key: _formKey,
              child: Container(
                decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white,
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset: Offset(0, 3), // changes position of shadow
                      ),
                    ],
                    color: Colors.white54,
                    borderRadius: BorderRadius.circular(30)),
                child: Column(
                  children: [
                    const SizedBox(
                      height: 20,
                    ),
                    Row(
                      children: [


                        const SizedBox(
                          height: 1,

                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.5),
                                      spreadRadius: 5,
                                      blurRadius: 7,
                                      offset: Offset(
                                          0, 3), // changes position of shadow
                                    ),
                                  ],
                                  color: Colors.white54,
                                  borderRadius: BorderRadius.circular(30)),
                              child: TextFormField(
                                controller: _usernameController,
                                validator: (value) =>
                                EmailValidator.validate(value!)
                                    ? null
                                    : "Please enter a valid email",
                                maxLines: 1,
                                decoration: InputDecoration(
                                    hintText: 'Username',
                                    prefixIcon: const Icon(Icons.person),
                                    border: InputBorder.none),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 5,
                                blurRadius: 7,
                                offset:
                                Offset(0, 3), // changes position of shadow
                              ),
                            ],
                            color: Colors.white54,
                            borderRadius: BorderRadius.circular(30)),
                        child: TextFormField(
                          controller: _emailController,
                          validator: (value) =>
                          EmailValidator.validate(value!)
                              ? null
                              : "Please enter a valid email",
                          maxLines: 1,
                          decoration: InputDecoration(
                              hintText: 'Enter your email',
                              prefixIcon: const Icon(Icons.email),
                              border: InputBorder.none),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 5,
                                blurRadius: 7,
                                offset:
                                Offset(0, 3), // changes position of shadow
                              ),
                            ],
                            color: Colors.white54,
                            borderRadius: BorderRadius.circular(30)),
                        child: TextFormField(
                          controller: _passwordController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                          maxLines: 1,
                          obscureText: true,
                          decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.lock),
                              hintText: 'Enter your password',
                              border: InputBorder.none),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          registerNewUser(context);

                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black54,
                        padding: const EdgeInsets.fromLTRB(40, 15, 40, 15),
                      ),
                      child: const Text(
                        'Sign up',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Already registered?'),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                const LoginPage(title: 'Login UI'),
                              ),
                            );
                          },
                          child: const Text('Sign in'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  User? firebaseUser;
  User? currentfirebaseUser;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<void> registerNewUser(BuildContext context) async {
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
                      borderRadius: BorderRadius.circular(20.0)
                  ),
                  child: Padding(
                      padding: EdgeInsets.all(15.0),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            SizedBox(width: 6.0,),
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.black),),
                            SizedBox(width: 26.0,),
                            Text("Signing up,please wait...")

                          ],
                        ),
                      ))));
        });


    firebaseUser = (await _firebaseAuth
        .createUserWithEmailAndPassword(
        email: _emailController.text, password: _passwordController.text)
        .catchError((errMsg) {
      Navigator.pop(context);
      displayToast("Error" + errMsg.toString(), context);
    }))
        .user;


    if (firebaseUser != null) // user created

        {
      //save use into to database

      Map userDataMap = {


        "UserName": _usernameController.text.trim().toString(),
        "Email": _emailController.text.trim().toString(),
        "Password": _passwordController.text.trim().toString(),

      };
      Clientsdb.child(firebaseUser!.uid).set(userDataMap);
      // admin.child(firebaseUser!.uid).set(userDataMap);

      currentfirebaseUser = firebaseUser;
      // registerInfirestore(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              LoginPage(),
        ),
      );
    } else {
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(builder: (context) {
      //     return login();
      //   }),
      // );      // Navigator.pop(context);
      // error occured - display error
      displayToast("user has not been created", context);
    }
  }
}
