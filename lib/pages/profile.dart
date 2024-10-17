import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/clientuser.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {

  final String profileImageUrl = 'https://example.com/profile.jpg'; // Replace with your image URL
  final String userName = 'John Doe';
  final String userEmail = 'john.doe@example.com';
  final String userPhone = '+1234567890';

  @override
  Widget build(BuildContext context) {
    final clientProvider = Provider.of<clientusers>(context).userInfo;
    final String? userName =  clientProvider?.username;
    final String? userEmail = clientProvider?.email;
    final String userPhone = '+1234567890';

    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Profile'),
      //   centerTitle: true,
      //   backgroundColor: Colors.blueAccent,
      // ),
      body:
    Column(
      children: [
        SizedBox(height: 22,),
        Padding(
          padding: const EdgeInsets.all(18.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(

                )

              ]
            ),
            child: Row(
              children: [
                Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: CircleAvatar(
                            radius: 60,
                            backgroundImage: NetworkImage(profileImageUrl),
                          ),
                        ),
                        const SizedBox(height: 16),

                  //       const SizedBox(height: 8),
                  //       Center(
                  //         child: Text(
                  //           userPhone,
                  //           style: const TextStyle(
                  //             fontSize: 16,
                  //             color: Colors.grey,
                  //           ),
                  //         ),
                  //       ),
                  //       const SizedBox(height: 24),
                  //       ElevatedButton(
                  //         onPressed: () {
                  //           // Add your edit profile functionality here
                  //         },
                  //         child: const Text('Edit Profile'),
                  //         style: ElevatedButton.styleFrom(
                  //           backgroundColor: Colors.blueAccent,
                  //           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  //           textStyle: const TextStyle(fontSize: 16),
                  //         ),
                  //       ),
                  //       const SizedBox(height: 16),
                  //       const Divider(thickness: 2),
                  //       const SizedBox(height: 16),
                  //       const Text(
                  //         'About Me',
                  //         style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  //       ),
                  //       const SizedBox(height: 8),
                  //       const Text(
                  //         'A brief description about yourself goes here. You can include your interests, hobbies, or anything you want to share.',
                  //         style: TextStyle(fontSize: 16),
                  //       ),
                  //     ],
                  //   ),
                  // ),

                ])),

                Column(
                  children: [
                    Column(
                      children: [
                        Center(
                          child: Text(
                            userName!??"",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children: [
                        Center(
                          child: Text(
                            userEmail!??"",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),


              ],
            ),
          ),
        ),
      ],
    ));
  }
}
