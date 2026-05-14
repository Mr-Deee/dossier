// lib/main_pages/asset_inventory.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import '../widget/themeprovider.dart';

class AssetInventoryPage extends StatefulWidget {
  @override
  _AssetInventoryPageState createState() => _AssetInventoryPageState();
}

class _AssetInventoryPageState extends State<AssetInventoryPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("assets");
  List<Map<String, dynamic>> _assets = [];
  bool _isLoading = true;

  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _estimatedValueController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _beneficiaryController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _selectedAssetType = "Bank Account";

  final List<String> _assetTypes = [
    "Bank Account", "Property", "Vehicle", "Investment", 
    "Insurance Policy", "Digital Asset", "Jewelry", "Cash", "Other"
  ];

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  String? _getCurrentUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  Future<void> _loadAssets() async {
    final userId = _getCurrentUserId();
    if (userId == null) return;

    setState(() => _isLoading = true);
    
    final snapshot = await _dbRef.child(userId).get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        _assets = data.entries.map((entry) => {
          "key": entry.key,
          "type": entry.value["type"] ?? "Other",
          "description": entry.value["description"] ?? "",
          "estimatedValue": entry.value["estimatedValue"] ?? "",
          "location": entry.value["location"] ?? "",
          "beneficiary": entry.value["beneficiary"] ?? "",
          "notes": entry.value["notes"] ?? "",
          "updatedAt": entry.value["updatedAt"] ?? "",
        }).toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addAsset() async {
    final userId = _getCurrentUserId();
    if (userId == null) return;

    final newAsset = {
      "type": _selectedAssetType,
      "description": _descriptionController.text.trim(),
      "estimatedValue": _estimatedValueController.text.trim(),
      "location": _locationController.text.trim(),
      "beneficiary": _beneficiaryController.text.trim(),
      "notes": _notesController.text.trim(),
      "updatedAt": DateTime.now().toIso8601String(),
    };
    
    await _dbRef.child(userId).push().set(newAsset);
    _clearControllers();
    _loadAssets();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Asset added successfully"), backgroundColor: Colors.green),
    );
  }

  void _clearControllers() {
    _descriptionController.clear();
    _estimatedValueController.clear();
    _locationController.clear();
    _beneficiaryController.clear();
    _notesController.clear();
  }

  Future<void> _deleteAsset(String key) async {
    final userId = _getCurrentUserId();
    if (userId == null) return;
    
    await _dbRef.child(userId).child(key).remove();
    _loadAssets();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Asset deleted"), backgroundColor: Colors.red),
    );
  }

  void _showAddAssetDialog() {
    _clearControllers();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text("Add Asset", style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField(
                    value: _selectedAssetType,
                    items: _assetTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                    onChanged: (value) => setDialogState(() => _selectedAssetType = value!),
                    decoration: InputDecoration(labelText: "Asset Type", border: OutlineInputBorder()),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(labelText: "Description", hintText: "e.g., Savings account at GCB", border: OutlineInputBorder()),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _estimatedValueController,
                    decoration: InputDecoration(labelText: "Estimated Value", hintText: "e.g., GHS 10,000", border: OutlineInputBorder()),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _locationController,
                    decoration: InputDecoration(labelText: "Location/Details", hintText: "e.g., Branch: Accra Main, Account #1234", border: OutlineInputBorder()),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _beneficiaryController,
                    decoration: InputDecoration(labelText: "Beneficiary", hintText: "Who should get this?", border: OutlineInputBorder()),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    decoration: InputDecoration(labelText: "Additional Notes", border: OutlineInputBorder()),
                    maxLines: 2,
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
                        Text("⚠️ LEGAL NOTICE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        SizedBox(height: 4),
                        Text(
                          "This is information storage only. Beneficiary designation here has no legal effect. Legal transfer requires will or Probate under Ghanaian law.",
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
                  if (_descriptionController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please enter a description")));
                    return;
                  }
                  await _addAsset();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                child: Text("Save Asset"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAssetDetails(Map<String, dynamic> asset) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(asset["description"] ?? "Asset Details"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow("Type", asset["type"]),
              _buildDetailRow("Estimated Value", asset["estimatedValue"]),
              _buildDetailRow("Location/Details", asset["location"]),
              _buildDetailRow("Beneficiary", asset["beneficiary"] ?? "Not specified"),
              if (asset["notes"] != null && asset["notes"].isNotEmpty)
                _buildDetailRow("Notes", asset["notes"]),
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
                      "This information is for planning purposes only. It does not constitute a legal transfer of assets. Please consult a lawyer for legal will preparation.",
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
      padding: EdgeInsets.only(bottom: 8),
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text("Asset Inventory"),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(40),
          child: Container(
            padding: EdgeInsets.all(8),
            color: Colors.amber.shade50,
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber.shade900, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "List what you own. Helps family know where to look. Not legally binding.",
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
          : _assets.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text("No assets added yet", style: TextStyle(fontSize: 18)),
                      SizedBox(height: 8),
                      Text("Tap the + button to add your first asset"),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _assets.length,
                  itemBuilder: (context, index) {
                    final asset = _assets[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: themeProvider.isDarkMode ? Colors.amber.shade700 : Colors.amber.shade100,
                          child: Icon(Icons.attach_money, color: themeProvider.isDarkMode ? Colors.black : Colors.amber.shade900),
                        ),
                        title: Text(asset["description"] ?? "Unnamed Asset", style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${asset["type"]} • ${asset["estimatedValue"]}"),
                            if (asset["beneficiary"] != null && asset["beneficiary"].isNotEmpty)
                              Text("→ ${asset["beneficiary"]}", style: TextStyle(fontSize: 12, color: Colors.green)),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteAsset(asset["key"]),
                        ),
                        onTap: () => _showAssetDetails(asset),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAssetDialog,
        child: Icon(Icons.add),
        backgroundColor: Colors.amber,
      ),
    );
  }
}