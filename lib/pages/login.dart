import 'package:dossier/pages/register.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key,  this.title}) : super(key: key);
  final String ?title;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  var rememberValue = false;

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
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
                height: 140,
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
                          offset: Offset(0, 3), // changes position of shadow
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
                                    offset: Offset(0, 3), // changes position of shadow
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
                                      child: const Icon(Icons.email)),
                                  contentPadding: EdgeInsets.symmetric(vertical: 16.0,horizontal: 16), // Adjust vertical padding
          
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
                                    offset: Offset(0, 3), // changes position of shadow
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
                                suffixIcon:  Container(
                                    height: 60,
                                    width: 60,
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(100)
                                    ),
          
                                    child: Icon(Icons.lock)),
                                hintText: 'Enter your password',
                                contentPadding: EdgeInsets.symmetric(vertical: 16.0,horizontal: 16), // Adjust vertical padding
                                border: InputBorder.none, // Removes the underline
                                // ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left:18.0),
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
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {}
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black54,
                            padding: const EdgeInsets.fromLTRB(40, 15, 40, 15),
                          ),
                          child: const Text(
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
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const RegisterPage(title: 'Register UI'),
                                  ),
                                );
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




}
