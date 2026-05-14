// lib/main_pages/document_vault.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class DocumentVaultPage extends StatefulWidget {
  @override
  _DocumentVaultPageState createState() => _DocumentVaultPageState();
}

class _DocumentVaultPageState extends State<DocumentVaultPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("documents");
  List<Map<String, dynamic>> _documents = [];
  bool _isLoading = true;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  String _selectedDocType = "Will";

  final List<String> _docTypes = [
    "Will", "Insurance Policy", "Property Deed", "Birth Certificate", 
    "Marriage Certificate", "Business Document", "Password Reference", "Other"
  ];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  String? _getCurrentUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  Future<void> _loadDocuments() async {
    final userId = _getCurrentUserId();
    if (userId == null) return;

    setState(() => _isLoading = true);
    
    final snapshot = await _dbRef.child(userId).get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        _documents = data.entries.map((entry) => {
          "key": entry.key,
          "title": entry.value["title"] ?? "",
          "type": entry.value["type"] ?? "",
          "description": entry.value["description"] ?? "",
          "location": entry.value["location"] ?? "",
          "uploadedAt": entry.value["uploadedAt"] ?? "",
        }).toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addDocument() async {
    final userId = _getCurrentUserId();
    if (userId == null) return;

    final newDoc = {
      "title": _titleController.text.trim(),
      "type": _selectedDocType,
      "description": _descriptionController.text.trim(),
      "location": _locationController.text.trim(),
      "uploadedAt": DateTime.now().toIso8601String(),
    };
    
    await _dbRef.child(userId).push().set(newDoc);
    _titleController.clear();
    _descriptionController.clear();
    _locationController.clear();
    _loadDocuments();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Document reference added"), backgroundColor: Colors.green),
    );
  }

  Future<void> _deleteDocument(String key) async {
    final userId = _getCurrentUserId();
    if (userId == null) return;
    
    await _dbRef.child(userId).child(key).remove();
    _loadDocuments();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Document removed"), backgroundColor: Colors.red),
    );
  }

  void _showAddDocumentDialog() {
    _titleController.clear();
    _descriptionController.clear();
    _locationController.clear();
    _selectedDocType = "Will";
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text("Add Document Reference", style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField(
                    value: _selectedDocType,
                    items: _docTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                    onChanged: (value) => setDialogState(() => _selectedDocType = value!),
                    decoration: InputDecoration(labelText: "Document Type", border: OutlineInputBorder()),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(labelText: "Title/Description", border: OutlineInputBorder()),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      labelText: "Location",
                      hintText: "Where is this document stored? (e.g., Safe at home, Lawyer's office)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(labelText: "Notes", border: OutlineInputBorder()),
                    maxLines: 3,
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("⚠️ IMPORTANT NOTICE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        SizedBox(height: 4),
                        Text(
                          "For legal validity: A Will requires signatures from the testator and two witnesses under Ghanaian law. "
                          "This is a reference only, not a legal document.",
                          style: TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
              ElevatedButton(
                onPressed: () async {
                  if (_titleController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please enter a title")));
                    return;
                  }
                  await _addDocument();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: Text("Save Reference"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDocumentDetails(Map<String, dynamic> doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(doc["title"]),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow("Type", doc["type"]),
              _buildDetailRow("Location", doc["location"] ?? "Not specified"),
              _buildDetailRow("Notes", doc["description"] ?? "None"),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("⚠️ LEGAL NOTICE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    SizedBox(height: 4),
                    Text(
                      "This is a reference only. For legal validity, ensure you have properly executed documents meeting Ghana's legal requirements (witnesses, signatures where required).",
                      style: TextStyle(fontSize: 11),
                    ),
                  ],
                ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
          SizedBox(height: 4),
          Text(value.isEmpty ? "Not specified" : value, style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Document Vault"),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(40),
          child: Container(
            padding: EdgeInsets.all(8),
            color: Colors.orange.shade50,
            child: Row(
              children: [
                Icon(Icons.folder, color: Colors.orange, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Store references to important documents. Tell family where to find them.",
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
          : _documents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text("No documents stored", style: TextStyle(fontSize: 18)),
                      SizedBox(height: 8),
                      Text("Add references to your important documents"),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _documents.length,
                  itemBuilder: (context, index) {
                    final doc = _documents[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange.shade100,
                          child: Icon(Icons.description, color: Colors.orange),
                        ),
                        title: Text(doc["title"], style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${doc["type"]} • ${doc["location"] ?? "Location not specified"}"),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteDocument(doc["key"]),
                        ),
                        onTap: () => _showDocumentDetails(doc),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDocumentDialog,
        child: Icon(Icons.add),
        backgroundColor: Colors.orange,
      ),
    );
  }
}