// lib/main_pages/settings_page.dart
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../widget/themeprovider.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _autoLogout = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text("Settings")),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text("Dark Mode"),
            subtitle: Text("Toggle light/dark theme"),
            value: themeProvider.isDarkMode,
            onChanged: (value) => themeProvider.toggleTheme(value),
          ),
          Divider(),
          SwitchListTile(
            title: Text("Email Notifications"),
            subtitle: Text("Receive updates about access requests"),
            value: _notificationsEnabled,
            onChanged: (value) => setState(() => _notificationsEnabled = value),
          ),
          SwitchListTile(
            title: Text("Auto Logout"),
            subtitle: Text("Logout after 30 minutes of inactivity"),
            value: _autoLogout,
            onChanged: (value) => setState(() => _autoLogout = value),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.privacy_tip, color: Colors.amber),
            title: Text("Privacy Policy"),
            onTap: () => _showPrivacyPolicy(),
          ),
          ListTile(
            leading: Icon(Icons.gavel, color: Colors.amber),
            title: Text("Terms of Service"),
            onTap: () => _showTermsOfService(),
          ),
          ListTile(
            leading: Icon(Icons.equalizer_sharp, color: Colors.amber),
            title: Text("Legal Disclaimer"),
            onTap: () => _showLegalDisclaimer(),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.delete_forever, color: Colors.red),
            title: Text("Delete My Data", style: TextStyle(color: Colors.red)),
            onTap: () => _confirmDeleteData(),
          ),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text("Logout", style: TextStyle(color: Colors.red)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Privacy Policy"),
        content: SingleChildScrollView(
          child: Text(
            "DOSSIER PRIVACY POLICY\n\n"
            "1. Data Collection: We collect your name, email, and information you voluntarily store.\n\n"
            "2. Data Usage: Your data is stored securely and only released to verified trusted contacts after death confirmation.\n\n"
            "3. Data Protection: We comply with Ghana's Data Protection Act, 2012 (Act 843).\n\n"
            "4. Your Rights: You may request deletion of your data at any time.\n\n"
            "5. Data Retention: Data is retained until you delete your account.\n\n"
            "6. Contact: For data requests, contact our Data Protection Officer.",
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Close")),
        ],
      ),
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Terms of Service"),
        content: SingleChildScrollView(
          child: Text(
            "DOSSIER TERMS OF SERVICE\n\n"
            "1. DOSSIER is an information storage tool, not a legal service.\n\n"
            "2. We do not provide legal advice or create legally binding documents.\n\n"
            "3. You are responsible for creating proper legal wills with a lawyer.\n\n"
            "4. Information stored is for family reference only.\n\n"
            "5. Access requires death certificate verification.\n\n"
            "6. We reserve the right to update these terms.\n\n"
            "7. Ghanaian law governs these terms.",
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Close")),
        ],
      ),
    );
  }

  void _showLegalDisclaimer() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Legal Disclaimer"),
        content: SingleChildScrollView(
          child: Text(
            "⚠️ IMPORTANT LEGAL DISCLAIMER\n\n"
            "1. NOT A LEGAL WILL: DOSSIER does NOT create, execute, or validate legal wills under Ghanaian law. The Electronic Transactions Act, 2008 (Act 772) explicitly excludes wills from electronic recognition.\n\n"
            "2. NO INHERITANCE RIGHTS: Designating a trusted contact or beneficiary in this app has NO legal effect for asset transfer. Only Probate or Letters of Administration from a court can transfer assets.\n\n"
            "3. NO FINANCIAL SERVICES: DOSSIER does not provide banking, lending, or financial advisory services.\n\n"
            "4. CONSULT A LAWYER: For legal will preparation and estate planning, please consult a qualified Ghanaian lawyer.\n\n"
            "5. ACCESS REQUIREMENT: Your trusted contacts will ONLY receive access after submitting a valid death certificate and manual verification.\n\n"
            "By using DOSSIER, you acknowledge that you have read and understood this disclaimer.",
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("I Understand")),
        ],
      ),
    );
  }

  void _confirmDeleteData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete All Data?"),
        content: Text(
          "This will permanently delete all your assets, legacy messages, contacts, and documents. This action cannot be undone.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await FirebaseDatabase.instance.ref("assets/${user.uid}").remove();
                await FirebaseDatabase.instance.ref("legacyEntries/${user.uid}").remove();
                await FirebaseDatabase.instance.ref("trustedContacts/${user.uid}").remove();
                await FirebaseDatabase.instance.ref("documents/${user.uid}").remove();
                await user.delete();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("All data deleted")));
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text("Delete Permanently"),
          ),
        ],
      ),
    );
  }
}