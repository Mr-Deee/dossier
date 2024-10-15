import 'package:flutter/material.dart';

class About extends StatefulWidget {
  const About({super.key});

  @override
  State<About> createState() => _AboutState();
}

class _AboutState extends State<About> {
  // Animation properties
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    // Simulate a loading effect
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _opacity = 1.0; // Fade in effect
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Dossier'),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(milliseconds: 800),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // App logo or header image (optional)
                // ClipRRect(
                //   borderRadius: BorderRadius.circular(10),
                //   child: Image.network(
                //     'https://via.placeholder.com/300x150', // Placeholder for Dossier logo or header image
                //     fit: BoxFit.cover,
                //   ),
                // ),
                const SizedBox(height: 20),

                // Title Card
                // Card(
                //   color: Colors.black,
                //   elevation: 5,
                //   shape: RoundedRectangleBorder(
                //     borderRadius: BorderRadius.circular(10),
                //   ),
                //   child: Padding(
                //     padding: const EdgeInsets.all(16.0),
                //     child: Column(
                //       children: [
                //         const Text(
                //           'Welcome to Dossier',
                //           style: TextStyle(
                //             fontSize: 28,
                //             fontWeight: FontWeight.bold,
                //             color: Colors.white,
                //           ),
                //         ),
                //         const SizedBox(height: 10),
                //         const Text(
                //           'Your secure and reliable digital will platform. Dossier helps you protect your legacy by managing your digital assets, adding next of kin, and providing clear instructions for your loved ones.',
                //           style: TextStyle(fontSize: 16, height: 1.5, color: Colors.white),
                //           textAlign: TextAlign.center,
                //         ),
                //       ],
                //     ),
                //   ),
                // ),
                const SizedBox(height: 20),

                // Key Features Card
                Card(
                  color: Colors.white,
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Key Features',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 10),
                        FeatureTile(
                          icon: Icons.lock,
                          title: 'Secure Storage',
                          subtitle: 'All your sensitive information is securely stored.',
                        ),
                        FeatureTile(
                          icon: Icons.person_add,
                          title: 'Next of Kin Management',
                          subtitle: 'Easily add and manage next of kin information.',
                        ),
                        FeatureTile(
                          icon: Icons.description,
                          title: 'Digital Will Creation',
                          subtitle: 'Create a detailed digital will for your loved ones.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // // Call to Action Button
                // ElevatedButton(
                //   onPressed: () {
                //     // Add functionality if needed
                //   },
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: Colors.black,
                //     padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                //     shape: RoundedRectangleBorder(
                //       borderRadius: BorderRadius.circular(10),
                //     ),
                //   ),
                //   child: const Text(
                //     'Get Started',
                //     style: TextStyle(fontSize: 18, color: Colors.white),
                //   ),
                // ),
                const SizedBox(height: 20),

                // Footer with Privacy Policy
                const Text(
                  'Your privacy and security are our top priorities. Learn more about our privacy policy and terms of use on our website.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const FeatureTile({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.black),
          title: Text(
            title,
            style: const TextStyle(fontSize: 16, color: Colors.black),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
        const Divider(color: Colors.black),
      ],
    );
  }
}
