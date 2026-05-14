// lib/main_pages/homepage.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import '../widget/themeprovider.dart';
import 'asset_inventory.dart';
import 'legacy_journal.dart';
import 'trusted_contacts.dart';
import 'document_vault.dart';
import 'settings_page.dart';
import 'contact_us.dart';
import 'access_request.dart';

class homepage extends StatefulWidget {
  const homepage({super.key});

  @override
  State<homepage> createState() => _homepageState();
}

class _homepageState extends State<homepage> {
  int _selectedIndex = 0;
  String _userName = "";

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await FirebaseDatabase.instance.ref("users/${user.uid}/username").get();
      if (snapshot.exists) {
        setState(() => _userName = snapshot.value as String);
      }
    }
  }

  String _getSalutation() {
    var hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 18) return 'Good Afternoon';
    return 'Good Evening';
  }

  final List<Widget> _pages = [
    HomeContent(),
    AssetInventoryPage(),
    LegacyJournalPage(),
    TrustedContactsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "DOSSIER.",
          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          Switch(
            value: themeProvider.isDarkMode,
            onChanged: (value) => themeProvider.toggleTheme(value),
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Assets'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Legacy'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Contacts'),
        ],
      ),
    );
  }
}

// Home Content Widget
class HomeContent extends StatefulWidget {
  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  String _userName = "";
  int _pendingRequests = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await FirebaseDatabase.instance.ref("users/${user.uid}/username").get();
      if (snapshot.exists) {
        setState(() => _userName = snapshot.value as String);
      }
      
      // Count pending access requests
      final requestsSnapshot = await FirebaseDatabase.instance
          .ref("accessRequests")
          .orderByChild("userId")
          .equalTo(user.uid)
          .get();
      
      if (requestsSnapshot.exists) {
        final requests = requestsSnapshot.value as Map<dynamic, dynamic>;
        setState(() {
          _pendingRequests = requests.values.where((r) => r["status"] == "pending").length;
        });
      }
    }
  }

  String _getSalutation() {
    var hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 18) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_getSalutation()}, $_userName!',
            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            "Your legacy organizer. Keep everything your family needs to know.",
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
          ),
          SizedBox(height: 24),
          
          // Legal Disclaimer Card
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              border: Border.all(color: Colors.amber, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 30),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "⚠️ LEGAL NOTICE",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "DOSSIER is an information storage tool only. Not a legal will. Access requires death certificate verification.",
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 24),
          
          // Pending Requests Card
          if (_pendingRequests > 0)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AccessRequestsPage()),
                );
              },
              child: Container(
                padding: EdgeInsets.all(16),
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  border: Border.all(color: Colors.blue, width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notification_important, color: Colors.blue, size: 30),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "$_pendingRequests pending access request(s) awaiting your approval",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              ),
            ),
          
          // Quick Stats
          Text(
            "Quick Overview",
            style: theme.textTheme.titleLarge,
          ),
          SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(Icons.inventory_2, "Assets", "Track what you own", Colors.blue, themeProvider),
              _buildStatCard(Icons.book, "Legacy", "Leave your wishes", Colors.purple, themeProvider),
              _buildStatCard(Icons.people, "Trusted", "Your people", Colors.green, themeProvider),
              _buildStatCard(Icons.folder, "Documents", "Store references", Colors.orange, themeProvider),
            ],
          ),
          
          SizedBox(height: 24),
          
          // How It Works
          Text(
            "How DOSSIER Works",
            style: theme.textTheme.titleLarge,
          ),
          SizedBox(height: 16),
          _buildStepCard("1", "Store", "Add your assets, legacy messages, and trusted contacts"),
          _buildStepCard("2", "Rest", "Your information stays secure and private"),
          _buildStepCard("3", "Request", "Trusted contacts request access when needed"),
          _buildStepCard("4", "Verify", "Death certificate required for access"),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String title, String subtitle, Color color, ThemeProvider themeProvider) {
    return Container(
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: color),
          SizedBox(height: 8),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(subtitle, style: TextStyle(fontSize: 11), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildStepCard(String number, String title, String description) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.amber,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(number, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                Text(description, style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}