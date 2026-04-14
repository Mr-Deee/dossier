import 'package:dossier/pages/homepage.dart';
import 'package:dossier/pages/register.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../Assistants/assistantMethods.dart';
import '../main.dart';
import '../widget/progressdialog.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key, this.title}) : super(key: key);
  final String? title;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  var rememberValue = false;

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool _isNavigating = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Container(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(
                height: 110,
              ),
              const Text(
                'Dossier',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 40,
                ),
              ),
              const SizedBox(
                height: 90,
              ),
              Container(
                child: Form(
                  key: _formKey,
                  child: Container(
                    decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white,
                            spreadRadius: 5,
                            blurRadius: 7,
                            offset: Offset(0, 3),
                          ),
                        ],
                        color: Colors.white54,
                        borderRadius: BorderRadius.circular(30)
                    ),
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 10,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Container(
                            decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 5,
                                    blurRadius: 7,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                                color: Colors.white54,
                                borderRadius: BorderRadius.circular(30)
                            ),
                            child: TextFormField(
                              validator: (value) => EmailValidator.validate(value!)
                                  ? null
                                  : "Please enter a valid email",
                              maxLines: 1,
                              controller: _emailController,
                              decoration: InputDecoration(
                                hintText: 'Enter your email',
                                prefixIcon: Container(
                                    height: 60,
                                    width: 60,
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(100)
                                    ),
                                    child: const Icon(Icons.email)
                                ),
                                contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Container(
                            decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 5,
                                    blurRadius: 7,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                                color: Colors.white54,
                                borderRadius: BorderRadius.circular(30)
                            ),
                            child: TextFormField(
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                return null;
                              },
                              controller: _passwordController,
                              maxLines: 1,
                              obscureText: true,
                              decoration: InputDecoration(
                                suffixIcon: Container(
                                    height: 60,
                                    width: 60,
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(100)
                                    ),
                                    child: Icon(Icons.lock)
                                ),
                                hintText: 'Enter your password',
                                contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 18.0),
                          child: CheckboxListTile(
                            title: const Text("Remember me"),
                            contentPadding: EdgeInsets.zero,
                            value: rememberValue,
                            activeColor: Theme.of(context).colorScheme.primary,
                            onChanged: (newValue) {
                              setState(() {
                                rememberValue = newValue!;
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        ElevatedButton(
                          onPressed: (_isLoading || _isNavigating) ? null : () {
                            if (_formKey.currentState!.validate()) {
                              _loginAndAuthenticateUser();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black54,
                            padding: const EdgeInsets.fromLTRB(40, 15, 40, 15),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                              : const Text(
                            'Sign in',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Not registered yet?'),
                            TextButton(
                              onPressed: () {
                                if (!_isNavigating) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                      const RegisterPage(title: 'Register UI'),
                                    ),
                                  );
                                }
                              },
                              child: const Text('Create an account'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _loginAndAuthenticateUser() async {
    // Prevent multiple login attempts
    if (_isLoading || _isNavigating) return;

    // Set loading state
    setState(() {
      _isLoading = true;
    });

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    // Validate inputs
    if (email.isEmpty || password.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _displayToast("Please enter email and password");
      }
      return;
    }

    try {
      UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      // Check if widget is still mounted before proceeding
      if (!mounted) return;

      // Get user info
      await AssistantMethods.getCurrentOnlineUserInfo(context);

      // Mark that we're navigating to prevent any further UI updates
      if (mounted) {
        setState(() {
          _isNavigating = true;
        });

        // Use a delayed navigation to ensure all UI updates are complete
        await Future.delayed(const Duration(milliseconds: 100));

        if (mounted) {
          // Clear all routes and navigate to homepage
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => homepage()),
                (Route<dynamic> route) => false,
          );
          _displayToast("Logged in successfully");
        }
      }

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      // Handle specific Firebase errors
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = "No user found with this email";
          break;
        case 'wrong-password':
          errorMessage = "Wrong password provided";
          break;
        case 'invalid-email':
          errorMessage = "Invalid email format";
          break;
        case 'user-disabled':
          errorMessage = "This user has been disabled";
          break;
        case 'too-many-requests':
          errorMessage = "Too many requests. Try again later";
          break;
        case 'network-request-failed':
          errorMessage = "Network error. Check your internet connection";
          break;
        default:
          errorMessage = "Login failed: ${e.message}";
      }

      _displayToast(errorMessage);
      print("Firebase auth error: ${e.code} - ${e.message}");

    } catch (e) {
      if (!mounted) return;
      _displayToast("Error: ${e.toString()}");
      print("Login error: ${e.toString()}");
    } finally {
      // Reset loading state only if not navigating
      if (mounted && !_isNavigating) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _displayToast(String message) {
    Fluttertoast.showToast(msg: message);
  }
}