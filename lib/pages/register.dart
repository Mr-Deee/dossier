import 'package:fluttertoast/fluttertoast.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import 'login.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key, this.title}) : super(key: key);
  final String? title;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  var rememberValue = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isDisposed = false;

  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Define custom colors
  final Color _primaryColor = const Color(0xFF2563EB);
  final Color _secondaryColor = const Color(0xFF3B82F6);

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _animationController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: SingleChildScrollView(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [




                    const SizedBox(height: 50),

                    // Welcome text
                    const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign up to get started',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        letterSpacing: 0.3,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Logo
                    Center(
                      child: Container(
                        height: 160,
                        width: 160,
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.account_circle,
                                size: 60,
                                color: Colors.grey,
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Form Container
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 30,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              // Username Field
                              TextFormField(
                                controller: _usernameController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your username';
                                  }
                                  if (value.length < 3) {
                                    return 'Username must be at least 3 characters';
                                  }
                                  return null;
                                },
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: 'Username',
                                  labelStyle: TextStyle(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.person_outline_rounded,
                                    color: Colors.grey[600],
                                    size: 22,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: _primaryColor,
                                      width: 2,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: Colors.red,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Email Field
                              TextFormField(
                                controller: _emailController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!EmailValidator.validate(value)) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: 'Email Address',
                                  labelStyle: TextStyle(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.email_outlined,
                                    color: Colors.grey[600],
                                    size: 22,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: _primaryColor,
                                      width: 2,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: Colors.red,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Password Field
                              TextFormField(
                                controller: _passwordController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) {
                                  if (_formKey.currentState!.validate()) {
                                    _registerNewUser();
                                  }
                                },
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  labelStyle: TextStyle(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.lock_outline_rounded,
                                    color: Colors.grey[600],
                                    size: 22,
                                  ),
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      color: Colors.grey[600],
                                      size: 22,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: _primaryColor,
                                      width: 2,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: Colors.red,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 12,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Password hint
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 16,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Password must be at least 6 characters',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Sign Up Button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : () {
                                    if (_formKey.currentState!.validate()) {
                                      _registerNewUser();
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber,
                                    foregroundColor: Colors.black,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    disabledBackgroundColor: _primaryColor.withOpacity(0.5),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                      : const Text(
                                    'Create Account',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Divider with OR text
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: Colors.grey[300],
                                      thickness: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      'OR',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: Colors.grey[300],
                                      thickness: 1,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Sign In link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Already have an account?",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 15,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      if (!_isDisposed) {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const LoginPage(title: 'Login UI'),
                                          ),
                                        );
                                      }
                                    },
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      'Sign In',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Footer
                    Center(
                      child: Text(
                        'By signing up, you agree to our Terms of Service',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _registerNewUser() async {
    if (_isLoading || _isDisposed) return;

    setState(() {
      _isLoading = true;
    });

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String username = _usernameController.text.trim();

    try {
      UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted || _isDisposed) return;

      // Save user data
      if (userCredential.user != null) {
        Map userDataMap = {
          "UserName": username,
          "Email": email,
          "Password": password,
        };

        // Uncomment these lines when you have your database setup
        // Clientsdb.child(userCredential.user!.uid).set(userDataMap);
        // currentfirebaseUser = userCredential.user;

        _displayToast("Account created successfully! 🎉");

        if (mounted && !_isDisposed) {
          setState(() {
            _isLoading = false;
          });

          // Navigate to login page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginPage(title: 'Login UI'),
            ),
          );
        }
      } else {
        _displayToast("User has not been created");
        if (mounted && !_isDisposed) {
          setState(() {
            _isLoading = false;
          });
        }
      }

    } on FirebaseAuthException catch (e) {
      if (!mounted || _isDisposed) return;

      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = "This email is already registered";
          break;
        case 'invalid-email':
          errorMessage = "Invalid email address format";
          break;
        case 'weak-password':
          errorMessage = "Password is too weak. Use at least 6 characters";
          break;
        case 'operation-not-allowed':
          errorMessage = "Email/password accounts are not enabled";
          break;
        case 'network-request-failed':
          errorMessage = "Network error. Check your connection";
          break;
        default:
          errorMessage = "Registration failed: ${e.message}";
      }

      _displayToast(errorMessage);
      print("Firebase auth error: ${e.code} - ${e.message}");

      if (mounted && !_isDisposed) {
        setState(() {
          _isLoading = false;
        });
      }

    } catch (e) {
      if (!mounted || _isDisposed) return;
      _displayToast("Error: ${e.toString()}");
      print("Registration error: ${e.toString()}");

      if (mounted && !_isDisposed) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _displayToast(String message) {
    if (mounted && !_isDisposed) {
      Fluttertoast.showToast(
        msg: message,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black87,
        textColor: Colors.white,
        fontSize: 14,
        toastLength: Toast.LENGTH_SHORT,
      );
    }
  }
}