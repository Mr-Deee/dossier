import 'dart:ui';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../Assistants/assistantMethods.dart';
import '../models/clientuser.dart';
import '../widget/mycards.dart';
import '../widget/themeprovider.dart';
import 'AccountDetails.dart';

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
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "DOSSIER.",
          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          Switch(
            value: themeProvider.isDarkMode,
            onChanged: (value) {
              themeProvider.toggleTheme(value);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildGreetingSection(clientprovider, theme),
            _buildWelcomeCard(size, theme),
            _buildHorizontalScrollCards(),
            SizedBox(height: 20),
            _buildUpcomingEventsCard(size, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingSection(clientusers? clientProvider, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Hi ${clientProvider?.username ?? ""}!',
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Text(
            _getSalutation(),
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(Size size, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Container(
        width: size.width,
        height: 120,
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.onSurface, width: 4.0),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8.0,left: 8.0,bottom: 4),
                  child: Text('Welcome!', style: theme.textTheme.titleLarge),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 1.0,left: 8,right: 8.0),
                  child: Text('Build Your Dossier!', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7))),
                ),
              ],
            ),
            Image.asset(Cards.kcard4, height: 94),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalScrollCards() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          MyCard(),
          ViewAssetsCard(),
        ],
      ),
    );
  }

  Widget _buildUpcomingEventsCard(Size size, ThemeData theme) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        width: size.width,
        height: 211,
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.onSurface, width: 4.0),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Upcoming Events!', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7))),
                  SizedBox(height: 10),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
                                  contentBuilder: icons[index]['contentBuilder'],
                                ),
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              CircleAvatar(
                                backgroundColor: themeProvider.isDarkMode ? Colors.amber : Colors.amber,
                                child: Icon(icons[index]['icon'], size: 25, color: themeProvider.isDarkMode ? Colors.black : Colors.black54),
                              ),
                              Text(
                                icons[index]['title'],
                                style: theme.textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Image.asset(Cards.kcard4, fit: BoxFit.cover),
            ),
          ],
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

  Map<String, Map<String, dynamic>> bankStyles = {
    "OmniBsic Bank": {
      "gradient": [Colors.blue, Colors.blueAccent],
      "logo": "assets/images/omnibsic.png",
    },
    "Zenith": {
      "gradient": [Colors.red, Colors.orange],
      "logo": "assets/bank_b_logo.png",
    },
    "Absa": {
      "gradient": [Colors.green, Colors.teal],
      "logo": "assets/bank_c_logo.png",
    },
  };

  Widget buildBalanceCard(Map<dynamic, dynamic> account) {
    String bank = account["bank"] ?? "Default Bank";
    List<Color> gradientColors = bankStyles[bank]?["gradient"] ?? [Colors.grey, Colors.black];
    String logoPath = bankStyles[bank]?["logo"] ?? "assets/default_logo.png";

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        width: 383,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradientColors),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(2, 2),
              blurRadius: 2,
            ),
          ],
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Image.asset(logoPath, width: 50, height: 50),
            ),
            Text(
              '\$${account["balance"] ?? "0.00"}',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Account: ${account["accountName"] ?? "Unknown"}',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '**** ${account["accountNumber"] ?? "XXXX"}',
                  style: TextStyle(color: Colors.white70),
                ),
                Text(
                  'Exp ${account["expiry"] ?? "N/A"}',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
            SizedBox(height: 19),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AccountDetailsPage(accountData: account),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                  child: Text('View Account', style: TextStyle(color: Colors.black)),
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
    String? selectedBank;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add Account"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: "Select Bank"),
              value: selectedBank,
              items: bankStyles.keys.map((bank) {
                return DropdownMenuItem(value: bank, child: Text(bank));
              }).toList(),
              onChanged: (value) {
                selectedBank = value;
              },
            ),
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
              if (selectedBank == null) return;

              String accountName = accountNameController.text.trim();
              String balance = balanceController.text.trim();
              String expiry = expiryController.text.trim();

              if (accountName.isNotEmpty && balance.isNotEmpty && expiry.isNotEmpty) {
                DatabaseReference newAccount = _database.push();
                await newAccount.set({
                  "accountName": accountName,
                  "balance": balance,
                  "expiry": expiry,
                  "bank": selectedBank,
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LegacyDetailsScreen(legacy: legacy),
                  ),
                );
              },
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




class LegacyDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> legacy;

  const LegacyDetailsScreen({Key? key, required this.legacy}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(legacy["title"]),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Details:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              legacy["details"],
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              "Timeline: ${legacy["timeline"]}",
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
          ],
        ),
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
