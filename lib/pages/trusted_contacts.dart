// lib/main_pages/trusted_contacts.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class TrustedContactsPage extends StatefulWidget {
  @override
  _TrustedContactsPageState createState() => _TrustedContactsPageState();
}

class _TrustedContactsPageState extends State<TrustedContactsPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("trustedContacts");
  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = true;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _relationshipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  String? _getCurrentUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  Future<void> _loadContacts() async {
    final userId = _getCurrentUserId();
    if (userId == null) return;

    setState(() => _isLoading = true);
    
    final snapshot = await _dbRef.child(userId).get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        _contacts = data.entries.map((entry) => {
          "key": entry.key,
          "name": entry.value["name"] ?? "",
          "email": entry.value["email"] ?? "",
          "phone": entry.value["phone"] ?? "",
          "relationship": entry.value["relationship"] ?? "",
          "addedAt": entry.value["addedAt"] ?? "",
        }).toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addContact() async {
    final userId = _getCurrentUserId();
    if (userId == null) return;

    final newContact = {
      "name": _nameController.text.trim(),
      "email": _emailController.text.trim(),
      "phone": _phoneController.text.trim(),
      "relationship": _relationshipController.text.trim(),
      "addedAt": DateTime.now().toIso8601String(),
    };
    
    await _dbRef.child(userId).push().set(newContact);
    _clearControllers();
    _loadContacts();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Trusted contact added"), backgroundColor: Colors.green),
    );
  }

  Future<void> _deleteContact(String key) async {
    final userId = _getCurrentUserId();
    if (userId == null) return;
    
    await _dbRef.child(userId).child(key).remove();
    _loadContacts();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Contact removed"), backgroundColor: Colors.red),
    );
  }

  void _clearControllers() {
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _relationshipController.clear();
  }

  void _showAddContactDialog() {
    _clearControllers();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add Trusted Contact", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: "Full Name", border: OutlineInputBorder()),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: "Email", border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(labelText: "Phone Number", border: OutlineInputBorder()),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 12),
            TextField(
              controller: _relationshipController,
              decoration: InputDecoration(labelText: "Relationship", border: OutlineInputBorder()),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("ℹ️ HOW THIS WORKS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  SizedBox(height: 4),
                  Text(
                    "These contacts can REQUEST access to your dossier after your death. "
                    "Access requires death certificate verification by DOSSIER administrators. "
                    "They have NO automatic rights to your assets.",
                    style: TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (_nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please enter a name")));
                return;
              }
              await _addContact();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: Text("Add Contact"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Trusted Contacts"),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(40),
          child: Container(
            padding: EdgeInsets.all(8),
            color: Colors.green.shade50,
            child: Row(
              children: [
                Icon(Icons.verified_user, color: Colors.green, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "These people can request access to your information when needed.",
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _contacts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text("No trusted contacts yet", style: TextStyle(fontSize: 18)),
                      SizedBox(height: 8),
                      Text("Add family members or legal representatives who should have access"),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _contacts.length,
                  itemBuilder: (context, index) {
                    final contact = _contacts[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Text(contact["name"][0].toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        title: Text(contact["name"], style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (contact["relationship"].isNotEmpty)
                              Text(contact["relationship"], style: TextStyle(fontSize: 12)),
                            if (contact["email"].isNotEmpty)
                              Text(contact["email"], style: TextStyle(fontSize: 11, color: Colors.grey)),
                            if (contact["phone"].isNotEmpty)
                              Text(contact["phone"], style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteContact(contact["key"]),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddContactDialog,
        child: Icon(Icons.person_add),
        backgroundColor: Colors.blue,
      ),
    );
  }
}