import 'dart:ui';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../Assistants/assistantMethods.dart';
import '../models/clientuser.dart';
import '../widget/mycards.dart';

class homepage extends StatefulWidget {
  const homepage({super.key});

  @override
  State<homepage> createState() => _homepageState();
}

class _homepageState extends State<homepage> {
  @override
  void initState() {
    _getSalutation();
    // TODO: implement initState
    super.initState();
    AssistantMethods.getCurrentOnlineUserInfo(context);
    AssistantMethods.getCurrentAssetInfo(context);
  }

  String _getSalutation() {
    var hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 18) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final clientprovider = Provider.of<clientusers>(context).userInfo;
    final Size size = MediaQuery.of(context).size;

    List<Widget> _widgetOptions = <Widget>[
      Column(
        children: [
          Row(
            children: [
              Column(
                children: [
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0, left: 22),
                        child: Text(
                          '${_getSalutation()}',
                          style: TextStyle(fontSize: 15, color: Colors.black26),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ],
          ),
          SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black, // Set border color to black
                  width: 4.0, // Set border thickness
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 13.0, left: 8),
                        child: Text('Welcome!', style: TextStyle(fontSize: 20)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 1.0, left: 8),
                        child: Text(
                          'Build Your Dossier!',
                          style: TextStyle(fontSize: 18, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 94, child: Image.asset(Cards.kcard4)),
                ],
              ),
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.all(8.0),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MyCard(),
                ViewAssetsCard(),
              ],
            ),
          ),
          SizedBox(height: 13),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              height: 190,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black,
                  width: 4.0,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 1.0, left: 8),
                        child: Text(
                          'Build Your Dossier!',
                          style: TextStyle(fontSize: 18, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 94, child: Image.asset(Cards.kcard4)),
                ],
              ),
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.all(8.0),
            ),
          ),
        ],
      ),
      // Add more widgets for different tabs
      // Center(child: Text('Restaurant Menu')),
      // Center(child: Text('Bookmark')),
      // Center(child: Text('Notifications',style: TextStyle(color: Colors.black),)),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "DOSSIER.",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        child: SingleChildScrollView(
          child: Column(children: [
            Row(children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 18.0, left: 18),
                    child: Text('Hi ' + '${clientprovider?.username ?? ""}!',
                        style: TextStyle(
                            fontSize: 25, fontWeight: FontWeight.bold)),
                  ),
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0, left: 22),
                        child: Text('${_getSalutation()}',
                            style:
                                TextStyle(fontSize: 15, color: Colors.black26)),
                      ),
                    ],
                  )
                ],
              ),
            ]),
            SizedBox(
              height: 26,
            ),
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.black, // Set border color to black
                      width: 4.0, // Set border thickness
                    ),
                    borderRadius: BorderRadius.circular(20)),
                // Set the background color to black
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: 18.0, left: 1),
                            child: Text('Welcome!',
                                style: TextStyle(fontSize: 20)),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 1.0, left: 8),
                            child: Text('Build Your Dossier!',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.black54)),
                          ),
                        ],
                      ),

                      SizedBox(height: 94, child: Image.asset(Cards.kcard4)),

                      // Add your children widgets here
                    ],
                  ),
                ),
                width: MediaQuery.of(context).size.width,
                // Set the width to match the screen size
                padding: EdgeInsets.all(
                    8.0), // Optional: Add padding to the container
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MyCard(),
                    ViewAssetsCard(),
                  ]),
            ),
            SizedBox(
              height: 23,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                height: 211,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.black, // Set border color to black
                    width: 4.0, // Set border thickness
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                width: MediaQuery.of(context).size.width,
                // Match the screen width
                padding: EdgeInsets.all(8.0),
                // Add padding to the container
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left Column
                    Flexible(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 1.0, left: 8),
                            child: Text(
                              'Upcoming Events!',
                              style: TextStyle(
                                  fontSize: 15, color: Colors.black54),
                            ),
                          ),
                          SizedBox(height: 10), // Spacing
                          Expanded(
                            child: GridView.builder(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 10.0,
                                mainAxisSpacing: 6.0,
                              ),
                              itemCount: icons.length,
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DetailPage(
                                          title: icons[index]['title']!,
                                          contentBuilder: icons[index]
                                              ['contentBuilder'],
                                        ),
                                      ),
                                    );
                                  },
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: CircleAvatar(
                                          backgroundColor: Colors.amber,
                                          child: Icon(
                                            icons[index]['icon'],
                                            size: 25,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        icons[index]['title'],
                                        // Fixed to correctly access the title
                                        style: TextStyle(fontSize: 12),
                                        // Smaller font size for the text
                                        textAlign: TextAlign.center,
                                      )
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Right Image
                    Flexible(
                      flex: 1,
                      child: SizedBox(
                        height: 94,
                        // Ensure the image fits within the layout
                        child: Image.asset(Cards.kcard4, fit: BoxFit.cover),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

// Icon data with unique content
  final List<Map<String, dynamic>> icons = [
    {
      'icon': Icons.monetization_on,
      'title': 'My Savings',
      'contentBuilder': () => SavingsPage(),
    },
    {
      'icon': Icons.add_chart_outlined,
      'title': 'Legacy',
      'contentBuilder': () => LegacyPage(),
    },
    {
      'icon': Icons.notifications,
      'title': 'SOS',
      'contentBuilder': () => NotificationPage(),
    },
    {
      'icon': Icons.settings,
      'title': 'Settings',
      'contentBuilder': () => SettingsPage(),
    },
    {
      'icon': Icons.contact_page,
      'title': 'Contact Us',
      'contentBuilder': () => ContactUsPage(),
    },
  ];
}

class BNBCustomePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    Path path = Path()..moveTo(0, 20);
    path.quadraticBezierTo(size.width * .20, 0, size.width * .35, 0);
    path.quadraticBezierTo(size.width * .40, 0, size.width * .40, 20);
    path.arcToPoint(Offset(size.width * .60, 20),
        radius: Radius.circular(10.0), clockwise: false);

    path.quadraticBezierTo(size.width * .60, 0, size.width * .65, 0);
    path.quadraticBezierTo(size.width * .80, 0, size.width, 20);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawShadow(path, Colors.black, 5, true);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// Stateful Detail Page
class DetailPage extends StatefulWidget {
  final String title;
  final Widget Function() contentBuilder;

  const DetailPage(
      {Key? key, required this.title, required this.contentBuilder})
      : super(key: key);

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   // title: Text(widget.title),
      // ),
      body: widget.contentBuilder(),
    );
  }
}

class SavingsPage extends StatefulWidget {
  @override
  _SavingsPageState createState() => _SavingsPageState();
}

class _SavingsPageState extends State<SavingsPage> {
  int _currentIndex = 0;

  // Define the pages to be displayed in the body
  final List<Widget> _pages = [
    HomeContent(),
    ActivityContent(),
    CardContent(),
    ProfileContent(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.card_giftcard, color: Colors.green),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.red),
            onPressed: () {},
          ),
        ],
      ),
      body: _pages[_currentIndex], // Switch between pages
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Activity',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card),
            label: 'Card',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref("accountsTable");
  List<Map<dynamic, dynamic>> _accounts = [];

  @override
  void initState() {
    super.initState();
    _fetchAccounts();
  }

  void _fetchAccounts() {
    _database.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        setState(() {
          _accounts = data.entries.map((e) => Map<dynamic, dynamic>.from(e.value)).toList();
        });
      } else {
        setState(() {
          _accounts = [];
        });
      }
    });
  }

  Widget buildBalanceCard(Map<dynamic, dynamic> account) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        width: 233,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(2, 2),
              blurRadius: 2,
            ),
          ],
          color: Colors.amber,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '\$${account["balance"] ?? "0.00"}',
              style: TextStyle(color: Colors.black, fontSize: 24),
            ),
            SizedBox(height: 10),
            Text(
              'Account: ${account["accountName"] ?? "Unknown"}',
              style: TextStyle(color: Colors.black54, fontSize: 16),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '**** ${account["accountNumber"] ?? "XXXX"}',
                  style: TextStyle(color: Colors.black54),
                ),
                Text(
                  'Exp ${account["expiry"] ?? "N/A"}',
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
            SizedBox(height: 19),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                  ),
                  child: Text('Add Money', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAccountDialog() {
    TextEditingController accountNameController = TextEditingController();
    TextEditingController balanceController = TextEditingController();
    TextEditingController expiryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add Account"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: accountNameController,
              decoration: InputDecoration(labelText: "Account Name"),
            ),
            TextField(
              controller: balanceController,
              decoration: InputDecoration(labelText: "Balance"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: expiryController,
              decoration: InputDecoration(labelText: "Expiry Date (MM/YY)"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              String accountName = accountNameController.text.trim();
              String balance = balanceController.text.trim();
              String expiry = expiryController.text.trim();

              if (accountName.isNotEmpty && balance.isNotEmpty && expiry.isNotEmpty) {
                DatabaseReference newAccount = _database.push();
                await newAccount.set({
                  "accountName": accountName,
                  "balance": balance,
                  "expiry": expiry,
                  "accountNumber": "${newAccount.key?.substring(0, 4)}****",
                  "lastUpdated": DateTime.now().toString(),
                });

                Navigator.pop(context);
              }
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Your Accounts"),
        backgroundColor: Colors.amber,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Horizontal scrolling balance cards
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _accounts.map((account) => buildBalanceCard(account)).toList(),
                ),
              ),
              SizedBox(height: 15),
              Text('Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 15),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _accounts.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Icon(Icons.attach_money, color: Colors.blue),
                    title: Text('${_accounts[index]["accountName"] ?? "Account"}'),
                    subtitle: Text('Updated ${_accounts[index]["lastUpdated"] ?? "N/A"}'),
                    trailing: Text(
                      '\$${_accounts[index]["balance"] ?? "0.00"}',
                      style: TextStyle(color: Colors.green),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAccountDialog,
        child: Icon(Icons.add),
        backgroundColor: Colors.amber,
      ),
    );
  }
}
class ActivityContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Activity Page',
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}

// Card Page Content
class CardContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Card Page',
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}

// Profile Page Content
class ProfileContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Profile Page',
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}

class LegacyPage extends StatefulWidget {
  @override
  _LegacyPageState createState() => _LegacyPageState();
}

class _LegacyPageState extends State<LegacyPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("legacy");
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _timelineController = TextEditingController();

  List<Map<String, dynamic>> _legacies = [];

  @override
  void initState() {
    super.initState();
    _loadLegacyData();
  }

  Future<void> _addLegacy(String title, String details, String timeline) async {
    final key = _dbRef.push().key;
    if (key != null) {
      await _dbRef.child(key).set({
        "title": title,
        "details": details,
        "timeline": timeline,
        "timestamp": DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> _deleteLegacy(String key) async {
    await _dbRef.child(key).remove();
    setState(() {
      _legacies.removeWhere((legacy) => legacy['key'] == key);
    });
  }

  Future<void> _loadLegacyData() async {
    final snapshot = await _dbRef.get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        _legacies = data.entries
            .map((entry) => {
          "key": entry.key,
          "title": entry.value["title"],
          "details": entry.value["details"],
          "timeline": entry.value["timeline"],
          "timestamp": entry.value["timestamp"],
        })
            .toList();
      });
    }
  }

  void _showAddLegacyModal() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevents dismissing by tapping outside
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool isLoading = false; // Tracks loading state

            return Dialog(
              insetPadding: EdgeInsets.all(10), // Makes it almost full-screen
              child: Container(
                padding: const EdgeInsets.all(20.0),
                height: MediaQuery.of(context).size.height * 0.9, // 90% of screen height
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Add New Legacy",
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 28),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(fontSize: 18),
                      decoration: const InputDecoration(
                        labelText: "Title",
                        labelStyle: TextStyle(fontSize: 16),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: TextField(
                        controller: _detailsController,
                        style: const TextStyle(fontSize: 18),
                        decoration: const InputDecoration(
                          labelText: "Details",
                          labelStyle: TextStyle(fontSize: 16),
                          border: OutlineInputBorder(),
                        ),
                        maxLines: null,
                        expands: true,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _timelineController,
                      style: const TextStyle(fontSize: 18),
                      decoration: const InputDecoration(
                        labelText: "Timeline (e.g., 2024-12-31)",
                        labelStyle: TextStyle(fontSize: 16),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: isLoading
                          ? null // Disable button during loading
                          : () async {
                        final title = _titleController.text.trim();
                        final details = _detailsController.text.trim();
                        final timeline = _timelineController.text.trim();

                        if (title.isNotEmpty &&
                            details.isNotEmpty &&
                            timeline.isNotEmpty) {
                          setState(() {
                            isLoading = true;
                          });

                          // Simulate saving process
                          await Future.delayed(const Duration(seconds: 2));

                          await _addLegacy(title, details, timeline);
                          _titleController.clear();
                          _detailsController.clear();
                          _timelineController.clear();
                          _loadLegacyData();

                          setState(() {
                            isLoading = false;
                          });

                          // Show success message
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Legacy added successfully!",
                                style: TextStyle(fontSize: 16),
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        textStyle: const TextStyle(fontSize: 20),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                          : const Text("Save Legacy"),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Legacy Journal"),
      ),
      body: _legacies.isEmpty
          ? const Center(
        child: Text(
          "No legacies added yet. Tap the + button to add one.",
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
      )
          : ListView.builder(
        itemCount: _legacies.length,
        itemBuilder: (context, index) {
          final legacy = _legacies[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: ListTile(
              title: Text(legacy["title"]),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(legacy["details"]),
                  const SizedBox(height: 4),
                  Text(
                    "Timeline: ${legacy["timeline"]}",
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteLegacy(legacy["key"]),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddLegacyModal,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'This is the Notifications Page.',
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Configure your settings here.',
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}

class ContactUsPage extends StatefulWidget {
  @override
  _ContactUsPageState createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Get in touch with us here.',
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}
