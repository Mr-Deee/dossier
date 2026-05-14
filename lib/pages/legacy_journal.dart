// lib/main_pages/legacy_journal.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class LegacyJournalPage extends StatefulWidget {
  @override
  _LegacyJournalPageState createState() => _LegacyJournalPageState();
}

class _LegacyJournalPageState extends State<LegacyJournalPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("legacyEntries");
  List<Map<String, dynamic>> _entries = [];
  bool _isLoading = true;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  String? _getCurrentUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  Future<void> _loadEntries() async {
    final userId = _getCurrentUserId();
    if (userId == null) return;

    setState(() => _isLoading = true);
    
    final snapshot = await _dbRef.child(userId).get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        _entries = data.entries.map((entry) => {
          "key": entry.key,
          "title": entry.value["title"] ?? "",
          "message": entry.value["message"] ?? "",
          "createdAt": entry.value["createdAt"] ?? "",
        }).toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addEntry() async {
    final userId = _getCurrentUserId();
    if (userId == null) return;

    final newEntry = {
      "title": _titleController.text.trim(),
      "message": _messageController.text.trim(),
      "createdAt": DateTime.now().toIso8601String(),
      "type": "legacy_message",
    };
    
    await _dbRef.child(userId).push().set(newEntry);
    _titleController.clear();
    _messageController.clear();
    _loadEntries();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Legacy message saved"), backgroundColor: Colors.green),
    );
  }

  Future<void> _deleteEntry(String key) async {
    final userId = _getCurrentUserId();
    if (userId == null) return;
    
    await _dbRef.child(userId).child(key).remove();
    _loadEntries();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Message deleted"), backgroundColor: Colors.red),
    );
  }

  void _showAddEntryDialog() {
    _titleController.clear();
    _messageController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Write Your Legacy", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: "Title", hintText: "e.g., Letter to my children", border: OutlineInputBorder()),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _messageController,
              decoration: InputDecoration(labelText: "Your Message", border: OutlineInputBorder()),
              maxLines: 8,
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Your words matter. Leave wisdom, love, and guidance for your loved ones.",
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (_titleController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please enter a title")));
                return;
              }
              if (_messageController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please enter a message")));
                return;
              }
              await _addEntry();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: Text("Save Message"),
          ),
        ],
      ),
    );
  }

  void _showEntryDetails(Map<String, dynamic> entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(entry["title"]),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                entry["message"],
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                "Written: ${_formatDate(entry["createdAt"])}",
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Close")),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return "Unknown";
    try {
      final date = DateTime.parse(dateString);
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Legacy Journal"),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(40),
          child: Container(
            padding: EdgeInsets.all(8),
            color: Colors.purple.shade50,
            child: Row(
              children: [
                Icon(Icons.favorite, color: Colors.purple, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Leave messages, wisdom, and wishes for your loved ones. Your voice preserved.",
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
          : _entries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.book, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text("No legacy messages yet", style: TextStyle(fontSize: 18)),
                      SizedBox(height: 8),
                      Text("Tap + to write your first message to loved ones"),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _entries.length,
                  itemBuilder: (context, index) {
                    final entry = _entries[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.purple.shade100,
                          child: Icon(Icons.favorite, color: Colors.purple),
                        ),
                        title: Text(entry["title"], style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          entry["message"].length > 100 ? "${entry["message"].substring(0, 100)}..." : entry["message"],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteEntry(entry["key"]),
                        ),
                        onTap: () => _showEntryDetails(entry),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEntryDialog,
        child: Icon(Icons.edit),
        backgroundColor: Colors.purple,
      ),
    );
  }
}