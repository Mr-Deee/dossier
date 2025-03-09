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
        // title: const Text('About Dossier',style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.white,
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
                const SizedBox(height: 10),
                SizedBox(
                  height: 203,
                  width: 400,
                  child: Card(
                    color: Colors.amber,
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "What's Dosseir?",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 6),
                          Padding(
                            padding: EdgeInsets.only(top:2.0,left: 4,right: 5),
                            child: Text("Dossier is your secure digital asset keeper, designed to store and manage important information like legal documents, "
                                "financial records, and memories. It ensures your assets are protected, organized, "
                                "and accessible when needed, offering peace of mind with advanced security and intuitive tools for modern legacy planning.",),
                          )

                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 23,
                ),
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
                          subtitle:
                              'All your sensitive information is securely stored.',
                        ),
                        FeatureTile(
                          icon: Icons.person_add,
                          title: 'Next of Kin Management',
                          subtitle:
                              'Easily add and manage next of kin information.',
                        ),
                        FeatureTile(
                          icon: Icons.description,
                          title: 'Digital Will Creation',
                          subtitle:
                              'Create a detailed digital will for your loved ones.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // // Call to Action Button
                // ElevatedButton(
                //   onPressed: () {
                //     Navigator.of(context).pushNamed("/bank");
                //   },
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: Colors.black,
                //     padding: const EdgeInsets.symmetric(
                //         horizontal: 30, vertical: 15),
                //     shape: RoundedRectangleBorder(
                //       borderRadius: BorderRadius.circular(10),
                //     ),
                //   ),
                //   child: const Text(
                //     'BANK PORTAL',
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
