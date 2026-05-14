// lib/main_pages/homepage.dart - Updated with animated DOSSIER. and tap theme toggle
import 'dart:async';
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

  final List<Widget> _pages = [
    const HomeContent(),
    const AssetInventoryPage(),
     LegacyJournalPage(),
     TrustedContactsPage(),
  ];

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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const AnimatedDossierTitle(),
        actions: [
          // Replace Switch with IconButton for theme toggle
          IconButton(
            onPressed: () {
              themeProvider.toggleTheme(!themeProvider.isDarkMode);
            },
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                key: ValueKey(themeProvider.isDarkMode),
                color: themeProvider.isDarkMode ? Colors.amber : Colors.black,
              ),
            ),
            tooltip: themeProvider.isDarkMode ? "Switch to Light Mode" : "Switch to Dark Mode",
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              } else if (value == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) =>  SettingsPage()),
                );
              } else if (value == 'contact') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) =>  ContactUsPage()),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'settings', child: ListTile(leading: Icon(Icons.settings), title: Text("Settings"))),
              const PopupMenuItem(value: 'contact', child: ListTile(leading: Icon(Icons.contact_support), title: Text("Contact Us"))),
              const PopupMenuItem(value: 'logout', child: ListTile(leading: Icon(Icons.logout), title: Text("Logout"))),
            ],
          ),
        ],
      ),
      body: _pages[_selectedIndex],
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
}

// Animated Dossier Title with color-changing dot
class AnimatedDossierTitle extends StatefulWidget {
  const AnimatedDossierTitle({super.key});

  @override
  State<AnimatedDossierTitle> createState() => _AnimatedDossierTitleState();
}

class _AnimatedDossierTitleState extends State<AnimatedDossierTitle> with SingleTickerProviderStateMixin {
  late AnimationController _colorController;
  int _colorIndex = 0;
  final List<Color> _dotColors = [Colors.red, Colors.amber, Colors.red, Colors.orange, Colors.red];

  @override
  void initState() {
    super.initState();
    _colorController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _colorIndex = (_colorIndex + 1) % _dotColors.length;
        });
        _colorController.forward(from: 0.0);
      }
    });
    _colorController.forward();
  }

  @override
  void dispose() {
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: "DOSSIER",
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
            ),
          ),
          WidgetSpan(
            child: AnimatedBuilder(
              animation: _colorController,
              builder: (context, child) {
                return ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      _dotColors[_colorIndex],
                      _dotColors[_colorIndex].withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(
                    ".",
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Home Content Widget - This is the overview/dashboard
class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  String _userName = "";
  int _pendingRequests = 0;
  int _totalAssets = 0;
  int _totalLegacyEntries = 0;
  int _totalContacts = 0;
  int _totalDocuments = 0;
  bool _isLoading = true;

  // Dynamic Island / Carousel variables
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _carouselTimer;

  // Carousel items
  final List<CarouselItem> _carouselItems = [
    CarouselItem(
      icon: Icons.warning_amber_rounded,
      title: "⚠️ LEGAL NOTICE",
      message: "DOSSIER is an information storage tool only. Not a legal will. Access requires death certificate verification.",
      color: Colors.amber,
    ),
    CarouselItem(
      icon: Icons.security,
      title: "🔒 YOUR DATA IS SAFE",
      message: "All your information is encrypted and stored securely. Only you can grant access to trusted contacts.",
      color: Colors.green,
    ),
    CarouselItem(
      icon: Icons.family_restroom,
      title: "👨‍👩‍👧‍👦 LEGACY PLANNING",
      message: "Create a lasting legacy for your loved ones. Store important messages, assets, and instructions.",
      color: Colors.blue,
    ),
    CarouselItem(
      icon: Icons.verified,
      title: "✅ ACCESS PROTOCOL",
      message: "Access requires death certificate verification. Your information remains private until then.",
      color: Colors.purple,
    ),
    CarouselItem(
      icon: Icons.tips_and_updates,
      title: "💡 PRO TIP",
      message: "Regularly update your information and inform trusted contacts about DOSSIER's existence.",
      color: Colors.orange,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startCarouselTimer();
    _loadData();
  }

  void _startCarouselTimer() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        final nextPage = (_currentPage + 1) % _carouselItems.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // Load user name
      final nameSnapshot = await FirebaseDatabase.instance.ref("users/${user.uid}/username").get();
      if (nameSnapshot.exists) {
        setState(() => _userName = nameSnapshot.value as String);
      }

      // Load pending access requests
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

      // Load all counts
      await _loadAssetsCount(user.uid);
      await _loadLegacyEntriesCount(user.uid);
      await _loadContactsCount(user.uid);
      await _loadDocumentsCount(user.uid);

    } catch (e) {
      debugPrint("Error loading data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAssetsCount(String userId) async {
    try {
      final assetsSnapshot = await FirebaseDatabase.instance.ref("assets/$userId").get();
      if (assetsSnapshot.exists) {
        final assets = assetsSnapshot.value as Map<dynamic, dynamic>;
        setState(() => _totalAssets = assets.length);
      } else {
        setState(() => _totalAssets = 0);
      }
    } catch (e) {
      debugPrint("Error loading assets count: $e");
      setState(() => _totalAssets = 0);
    }
  }

  Future<void> _loadLegacyEntriesCount(String userId) async {
    try {
      final legacySnapshot = await FirebaseDatabase.instance.ref("legacyEntries/$userId").get();
      if (legacySnapshot.exists) {
        final entries = legacySnapshot.value as Map<dynamic, dynamic>;
        setState(() => _totalLegacyEntries = entries.length);
      } else {
        setState(() => _totalLegacyEntries = 0);
      }
    } catch (e) {
      debugPrint("Error loading legacy entries count: $e");
      setState(() => _totalLegacyEntries = 0);
    }
  }

  Future<void> _loadContactsCount(String userId) async {
    try {
      final contactsSnapshot = await FirebaseDatabase.instance.ref("trustedContacts/$userId").get();
      if (contactsSnapshot.exists) {
        final contacts = contactsSnapshot.value as Map<dynamic, dynamic>;
        setState(() => _totalContacts = contacts.length);
      } else {
        setState(() => _totalContacts = 0);
      }
    } catch (e) {
      debugPrint("Error loading contacts count: $e");
      setState(() => _totalContacts = 0);
    }
  }

  Future<void> _loadDocumentsCount(String userId) async {
    try {
      final documentsSnapshot = await FirebaseDatabase.instance.ref("documents/$userId").get();
      if (documentsSnapshot.exists) {
        final documents = documentsSnapshot.value as Map<dynamic, dynamic>;
        setState(() => _totalDocuments = documents.length);
      } else {
        setState(() => _totalDocuments = 0);
      }
    } catch (e) {
      debugPrint("Error loading documents count: $e");
      setState(() => _totalDocuments = 0);
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

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting Section
            Text(
              '${_getSalutation()}, ${_userName.isEmpty ? "User" : _userName}!',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Your legacy organizer. Keep everything your family needs to know.",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),

            // Dynamic Island / Rotating Carousel
            SizedBox(
              height: 120,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _carouselItems.length,
                itemBuilder: (context, index) {
                  final item = _carouselItems[index];
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          item.color.withOpacity(0.15),
                          item.color.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: item.color, width: 1.5),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: item.color.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: item.color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(item.icon, color: item.color, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  item.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: item.color,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.message,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                                    height: 1.3,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Page Indicator Dots
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _carouselItems.length,
                    (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? Colors.amber
                        : Colors.grey.withOpacity(0.4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Loading Indicator
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              // Pending Requests Card (if any)
              if (_pendingRequests > 0)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) =>  AccessRequestsPage()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      border: Border.all(color: Colors.red, width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notification_important, color: Colors.red, size: 30),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "$_pendingRequests pending access request(s) awaiting your approval",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                  ),
                ),

              // Stats Cards Row - Tappable navigation cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.inventory_2,
                      title: "Assets",
                      value: _totalAssets.toString(),
                      subtitle: "items tracked",
                      color: Colors.blue,
                      themeProvider: themeProvider,
                      onTap: () {
                        _navigateToPage(1);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.book,
                      title: "Legacy",
                      value: _totalLegacyEntries.toString(),
                      subtitle: "messages saved",
                      color: Colors.purple,
                      themeProvider: themeProvider,
                      onTap: () {
                        _navigateToPage(2);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.people,
                      title: "Contacts",
                      value: _totalContacts.toString(),
                      subtitle: "trusted people",
                      color: Colors.green,
                      themeProvider: themeProvider,
                      onTap: () {
                        _navigateToPage(3);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.folder,
                      title: "Documents",
                      value: _totalDocuments.toString(),
                      subtitle: "files referenced",
                      color: Colors.orange,
                      themeProvider: themeProvider,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => DocumentVaultPage()),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Recent Activity Section
              if (_totalAssets > 0 || _totalLegacyEntries > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Recent Activity",
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildRecentActivityCard(),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("📦 You have $_totalAssets asset(s) tracked"),
              if (_totalAssets > 0)
                TextButton(
                  onPressed: () => _navigateToPage(1),
                  child: const Text("View All"),
                ),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("📝 $_totalLegacyEntries legacy message(s) saved"),
              if (_totalLegacyEntries > 0)
                TextButton(
                  onPressed: () => _navigateToPage(2),
                  child: const Text("View All"),
                ),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("👥 $_totalContacts trusted contact(s) added"),
              if (_totalContacts > 0)
                TextButton(
                  onPressed: () => _navigateToPage(3),
                  child: const Text("View All"),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _navigateToPage(int index) {
    final homepageState = context.findAncestorStateOfType<_homepageState>();
    if (homepageState != null) {
      homepageState.setState(() {
        homepageState._selectedIndex = index;
      });
    }
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required ThemeProvider themeProvider,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: themeProvider.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.amber,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(description, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Carousel Item Model
class CarouselItem {
  final IconData icon;
  final String title;
  final String message;
  final Color color;

  CarouselItem({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });
}