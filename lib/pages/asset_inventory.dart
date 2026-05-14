import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import '../widget/themeprovider.dart';

class AssetInventoryPage extends StatefulWidget {
  const AssetInventoryPage({super.key});

  @override
  State<AssetInventoryPage> createState() => _AssetInventoryPageState();
}

class _AssetInventoryPageState extends State<AssetInventoryPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("assets");
  final DatabaseReference _trustedContactsRef = FirebaseDatabase.instance.ref("trustedContacts");
  List<Map<String, dynamic>> _assets = [];
  List<Map<String, dynamic>> _existingContacts = [];
  List<Beneficiary> _beneficiariesFromContacts = []; // Added for beneficiaries from trusted contacts
  bool _isLoading = true;

  // Controllers for add/edit
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _estimatedValueController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _selectedAssetType = "Bank Account";
  List<Beneficiary> _beneficiaries = [];

  final List<String> _assetTypes = [
    "Bank Account", "Property", "Vehicle", "Investment",
    "Insurance Policy", "Digital Asset", "Jewelry", "Cash", "Business", "Other"
  ];

  @override
  void initState() {
    super.initState();
    _loadAssets();
    _loadTrustedContacts();
    _loadBeneficiariesFromTrustedContacts();
  }

  String? _getCurrentUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  Future<void> _loadBeneficiariesFromTrustedContacts() async {
    final userId = _getCurrentUserId();
    if (userId == null) return;

    final snapshot = await _trustedContactsRef.child(userId).get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        _beneficiariesFromContacts = data.entries.map((entry) {
          final contact = entry.value;
          return Beneficiary(
            name: contact["name"] ?? "",
            relationship: contact["relationship"] ?? "",
            contact: contact["phone"]?.toString() ?? contact["email"] ?? "",
            sharePercentage: "0",
            shareType: "Percentage",
            source: "trusted_contacts",
          );
        }).toList();
      });
    }
  }

  Future<void> _loadTrustedContacts() async {
    final userId = _getCurrentUserId();
    if (userId == null) return;

    final snapshot = await _trustedContactsRef.child(userId).get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        _existingContacts = data.entries.map((entry) => {
          "key": entry.key,
          "name": entry.value["name"] ?? "",
          "email": entry.value["email"] ?? "",
          "phone": entry.value["phone"] ?? "",
          "relationship": entry.value["relationship"] ?? "",
        }).toList();
      });
    }
  }

  Future<void> _loadAssets() async {
    final userId = _getCurrentUserId();
    if (userId == null) return;

    setState(() => _isLoading = true);

    final snapshot = await _dbRef.child(userId).get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        _assets = data.entries.map((entry) {
          final assetData = Map<String, dynamic>.from(entry.value);
          return {
            "key": entry.key,
            "type": assetData["type"] ?? "Other",
            "description": assetData["description"] ?? "",
            "estimatedValue": assetData["estimatedValue"] ?? "",
            "location": assetData["location"] ?? "",
            "beneficiaries": assetData["beneficiaries"] ?? [],
            "notes": assetData["notes"] ?? "",
            "updatedAt": assetData["updatedAt"] ?? "",
          };
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

    // Auto-sync beneficiaries to trusted contacts
    for (var beneficiary in _beneficiaries) {
      await _syncToTrustedContacts(beneficiary);
    }

    final newAsset = {
      "type": _selectedAssetType,
      "description": _descriptionController.text.trim(),
      "estimatedValue": _estimatedValueController.text.trim(),
      "location": _locationController.text.trim(),
      "beneficiaries": _beneficiaries.map((b) => b.toJson()).toList(),
      "notes": _notesController.text.trim(),
      "updatedAt": DateTime.now().toIso8601String(),
    };

    await _dbRef.child(userId).push().set(newAsset);
    _clearControllers();
    _loadAssets();
    _loadTrustedContacts();
    _loadBeneficiariesFromTrustedContacts();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Asset added successfully! Beneficiaries added to Trusted Contacts."),
          backgroundColor: Color(0xFFD4AF37),
        ),
      );
    }
  }

  Future<void> _syncToTrustedContacts(Beneficiary beneficiary) async {
    final userId = _getCurrentUserId();
    if (userId == null) return;

    // Check if contact already exists
    bool exists = _existingContacts.any(
            (contact) => contact["name"].toLowerCase() == beneficiary.name.toLowerCase()
    );

    if (!exists) {
      final newContact = {
        "name": beneficiary.name,
        "email": beneficiary.contact.contains('@') ? beneficiary.contact : "",
        "phone": beneficiary.contact.contains('@') ? "" : beneficiary.contact,
        "relationship": beneficiary.relationship,
        "addedFromAsset": true,
        "addedAt": DateTime.now().toIso8601String(),
      };

      await _trustedContactsRef.child(userId).push().set(newContact);
    }
  }

  void _clearControllers() {
    _descriptionController.clear();
    _estimatedValueController.clear();
    _locationController.clear();
    _notesController.clear();
    _beneficiaries.clear();
    _selectedAssetType = "Bank Account";
  }

  Future<void> _deleteAsset(String key) async {
    final userId = _getCurrentUserId();
    if (userId == null) return;

    showDialog(
      context: context,
      builder: (context) => _buildGoldDialog(
        title: "Delete Asset",
        content: "Are you sure you want to delete this asset? This action cannot be undone.",
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Color(0xFFD4AF37))),
          ),
          ElevatedButton(
            onPressed: () async {
              await _dbRef.child(userId).child(key).remove();
              _loadAssets();
              Navigator.pop(context);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Asset deleted"), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // FULL SCREEN ADD ASSET DIALOG - White & Gold Theme
  void _showAddAssetDialog() {
    _clearControllers();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            insetPadding: EdgeInsets.zero,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.white,
              child: Column(
                children: [
                  // Gold App Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFD4AF37),
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.black, size: 28),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Add New Asset",
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: () async {
                            if (_descriptionController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Please enter a description")),
                              );
                              return;
                            }
                            await _addAsset();
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.save),
                          label: const Text("Save Asset"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: const Color(0xFFD4AF37),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Scrollable Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Asset Type Selection
                          const Text(
                            "Asset Type",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                              ],
                            ),
                            child: DropdownButtonFormField(
                              value: _selectedAssetType,
                              items: _assetTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                              onChanged: (value) => setDialogState(() => _selectedAssetType = value!),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Asset Details Section
                          const Text(
                            "Asset Details",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
                          ),
                          const SizedBox(height: 12),
                          _buildWhiteFormCard(
                            child: Column(
                              children: [
                                TextField(
                                  controller: _descriptionController,
                                  style: const TextStyle(color: Colors.black),
                                  decoration: const InputDecoration(
                                    labelText: "Description *",
                                    hintText: "e.g., Savings account at GCB",
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.description, color: Color(0xFFD4AF37)),
                                    labelStyle: TextStyle(color: Color(0xFFD4AF37)),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _estimatedValueController,
                                  style: const TextStyle(color: Colors.black),
                                  decoration: const InputDecoration(
                                    labelText: "Estimated Value",
                                    hintText: "e.g., GHS 10,000",
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.monetization_on, color: Color(0xFFD4AF37)),
                                    labelStyle: TextStyle(color: Color(0xFFD4AF37)),
                                  ),
                                  keyboardType: TextInputType.text,
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _locationController,
                                  style: const TextStyle(color: Colors.black),
                                  decoration: const InputDecoration(
                                    labelText: "Location / Account Details",
                                    hintText: "e.g., Branch: Accra Main, Account #1234",
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.location_on, color: Color(0xFFD4AF37)),
                                    labelStyle: TextStyle(color: Color(0xFFD4AF37)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Beneficiaries Section
                          Row(
                            children: [
                              const Text(
                                "Beneficiaries",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () => _showAddBeneficiaryDialog(setDialogState),
                                icon: const Icon(Icons.add_circle, color: Color(0xFFD4AF37)),
                                label: const Text("Add Beneficiary", style: TextStyle(color: Color(0xFFD4AF37))),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Show beneficiaries from Trusted Contacts
                          if (_beneficiariesFromContacts.isNotEmpty) ...[
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4AF37).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "📋 From Your Trusted Contacts",
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _beneficiariesFromContacts.map((contact) {
                                      final isSelected = _beneficiaries.any((b) => b.name == contact.name);
                                      return FilterChip(
                                        label: Text(contact.name),
                                        selected: isSelected,
                                        onSelected: (selected) {
                                          setDialogState(() {
                                            if (selected) {
                                              _beneficiaries.add(contact);
                                            } else {
                                              _beneficiaries.removeWhere((b) => b.name == contact.name);
                                            }
                                          });
                                        },
                                        selectedColor: const Color(0xFFD4AF37).withOpacity(0.3),
                                        checkmarkColor: const Color(0xFFD4AF37),
                                        labelStyle: TextStyle(
                                          color: isSelected ? const Color(0xFFD4AF37) : Colors.black,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Selected beneficiaries list
                          if (_beneficiaries.isNotEmpty) ...[
                            const Text(
                              "Selected Beneficiaries",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black54),
                            ),
                            const SizedBox(height: 8),
                            ..._beneficiaries.map((beneficiary) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5)),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: const Color(0xFFD4AF37).withOpacity(0.2),
                                      child: Text(
                                        beneficiary.name[0].toUpperCase(),
                                        style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(beneficiary.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                                          Text(beneficiary.relationship, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    if (beneficiary.source != "trusted_contacts")
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () {
                                          setDialogState(() {
                                            _beneficiaries.remove(beneficiary);
                                          });
                                        },
                                      ),
                                  ],
                                ),
                              );
                            }),
                          ],

                          const SizedBox(height: 20),

                          // Additional Notes
                          const Text(
                            "Additional Notes",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
                          ),
                          const SizedBox(height: 12),
                          _buildWhiteFormCard(
                            child: TextField(
                              controller: _notesController,
                              style: const TextStyle(color: Colors.black),
                              decoration: const InputDecoration(
                                hintText: "Any extra information...",
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.note_add, color: Color(0xFFD4AF37)),
                              ),
                              maxLines: 4,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Auto-Sync Notice
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.sync, color: Color(0xFFD4AF37)),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "✨ Beneficiaries will be automatically added to your Trusted Contacts list",
                                    style: TextStyle(color: Colors.black87, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Legal Notice
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.withOpacity(0.3)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.gavel, color: Colors.red),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "⚠️ LEGAL NOTICE",
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.red),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        "Beneficiary designation here has no legal effect. Legal transfer requires will or Probate under Ghanaian law.",
                                        style: TextStyle(fontSize: 11, color: Colors.black87),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // FULL SCREEN BENEFICIARY DIALOG - White & Gold Theme
  void _showAddBeneficiaryDialog(Function setDialogState) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController relationshipController = TextEditingController();
    final TextEditingController shareController = TextEditingController();
    final TextEditingController contactController = TextEditingController();
    String selectedShareType = "Percentage";

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.zero,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.white,
          child: Column(
            children: [
              // Gold App Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                color: const Color(0xFFD4AF37),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Add Beneficiary",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Illustration
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.people_alt, size: 60, color: Color(0xFFD4AF37)),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Form Fields
                      _buildWhiteFormCard(
                        child: Column(
                          children: [
                            TextField(
                              controller: nameController,
                              style: const TextStyle(color: Colors.black),
                              decoration: const InputDecoration(
                                labelText: "Full Name *",
                                hintText: "e.g., John Mensah",
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person, color: Color(0xFFD4AF37)),
                                labelStyle: TextStyle(color: Color(0xFFD4AF37)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: relationshipController,
                              style: const TextStyle(color: Colors.black),
                              decoration: const InputDecoration(
                                labelText: "Relationship *",
                                hintText: "e.g., Son, Daughter, Spouse",
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.family_restroom, color: Color(0xFFD4AF37)),
                                labelStyle: TextStyle(color: Color(0xFFD4AF37)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: contactController,
                              style: const TextStyle(color: Colors.black),
                              decoration: const InputDecoration(
                                labelText: "Contact Information",
                                hintText: "e.g., Phone number or email",
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.contact_phone, color: Color(0xFFD4AF37)),
                                labelStyle: TextStyle(color: Color(0xFFD4AF37)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Auto-Sync Info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.sync, color: Color(0xFFD4AF37)),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "This beneficiary will be automatically added to your Trusted Contacts list",
                                style: TextStyle(color: Colors.black87, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: const BorderSide(color: Color(0xFFD4AF37)),
                                foregroundColor: const Color(0xFFD4AF37),
                              ),
                              child: const Text("Cancel"),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (nameController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Please enter beneficiary name")),
                                  );
                                  return;
                                }
                                if (relationshipController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Please enter relationship")),
                                  );
                                  return;
                                }

                                final newBeneficiary = Beneficiary(
                                  name: nameController.text.trim(),
                                  relationship: relationshipController.text.trim(),
                                  contact: contactController.text.trim(),
                                  sharePercentage: "0",
                                  shareType: "Percentage",
                                  source: "manual",
                                );

                                setDialogState(() {
                                  _beneficiaries.add(newBeneficiary);
                                });
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD4AF37),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text("Add Beneficiary", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWhiteFormCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  // FULL SCREEN ASSET DETAILS - White & Gold Theme
  void _showAssetDetails(Map<String, dynamic> asset) {
    final List<Beneficiary> beneficiaries = (asset["beneficiaries"] as List?)
        ?.map((b) => Beneficiary.fromJson(b))
        .toList() ?? [];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.zero,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.white,
          child: Column(
            children: [
              // Gold App Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                color: const Color(0xFFD4AF37),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        asset["description"],
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Asset Type Badge
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_getIconForType(asset["type"]), color: const Color(0xFFD4AF37)),
                              const SizedBox(width: 8),
                              Text(
                                asset["type"],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFD4AF37),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Asset Details Section
                      const Text(
                        "Asset Details",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
                      ),
                      const SizedBox(height: 16),
                      _buildWhiteDetailCard(
                        icon: Icons.description,
                        label: "Description",
                        value: asset["description"],
                      ),
                      const SizedBox(height: 12),
                      _buildWhiteDetailCard(
                        icon: Icons.monetization_on,
                        label: "Estimated Value",
                        value: asset["estimatedValue"] ?? "Not specified",
                      ),
                      const SizedBox(height: 12),
                      _buildWhiteDetailCard(
                        icon: Icons.location_on,
                        label: "Location / Details",
                        value: asset["location"] ?? "Not specified",
                      ),
                      const SizedBox(height: 24),

                      // Beneficiaries Section
                      const Text(
                        "Beneficiaries",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
                      ),
                      const SizedBox(height: 16),
                      if (beneficiaries.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text("No beneficiaries assigned to this asset", style: TextStyle(color: Colors.black54)),
                          ),
                        )
                      else
                        ...beneficiaries.map((b) => _buildWhiteBeneficiaryCard(b)),
                      const SizedBox(height: 24),

                      // Additional Notes
                      if (asset["notes"] != null && asset["notes"].isNotEmpty) ...[
                        const Text(
                          "Additional Notes",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
                        ),
                        const SizedBox(height: 16),
                        _buildWhiteDetailCard(
                          icon: Icons.note,
                          label: "Notes",
                          value: asset["notes"],
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Legal Notice
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.gavel, color: Colors.red),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "⚠️ LEGAL NOTICE",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.red),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "This information is for planning purposes only. Legal asset transfer requires will or Probate under Ghanaian law.",
                                    style: TextStyle(fontSize: 11, color: Colors.black87),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWhiteDetailCard({required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFFD4AF37), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFFD4AF37))),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 16, color: Colors.black)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhiteBeneficiaryCard(Beneficiary beneficiary) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFD4AF37).withOpacity(0.2),
            radius: 25,
            child: Text(
              beneficiary.name[0].toUpperCase(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(beneficiary.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                Text(beneficiary.relationship, style: const TextStyle(color: Color(0xFFD4AF37))),
                if (beneficiary.contact.isNotEmpty)
                  Text(beneficiary.contact, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              beneficiary.sharePercentage,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoldDialog({
    required String title,
    required String content,
    required List<Widget> actions,
  }) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text(title, style: const TextStyle(color: Color(0xFFD4AF37))),
      content: Text(content, style: const TextStyle(color: Colors.black87)),
      actions: actions,
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case "Bank Account": return Icons.account_balance;
      case "Property": return Icons.house;
      case "Vehicle": return Icons.directions_car;
      case "Investment": return Icons.trending_up;
      default: return Icons.inventory_2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final crossAxisCount = isTablet ? (screenWidth > 900 ? 4 : 3) : 2;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Asset Inventory", style: TextStyle(color: Colors.black)),
        backgroundColor: const Color(0xFFD4AF37),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFD4AF37),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.black, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Track what you own. Beneficiaries auto-sync to Trusted Contacts.",
                    style: TextStyle(fontSize: 11, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37))))
          : _assets.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text("No assets added yet", style: TextStyle(fontSize: 18, color: Colors.black87)),
            const SizedBox(height: 8),
            const Text("Tap the + button to add your first asset", style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddAssetDialog,
              icon: const Icon(Icons.add),
              label: const Text("Add Asset"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isTablet ? 1.1 : 0.9,
          ),
          itemCount: _assets.length,
          itemBuilder: (context, index) {
            final asset = _assets[index];
            final beneficiaries = (asset["beneficiaries"] as List?)?.length ?? 0;

            return GestureDetector(
              onTap: () => _showAssetDetails(asset),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFD4AF37).withOpacity(0.15),
                      Colors.white,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIconForType(asset["type"]),
                        size: 40,
                        color: const Color(0xFFD4AF37),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        asset["description"],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      asset["estimatedValue"] ?? "Value not set",
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    if (beneficiaries > 0) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "$beneficiaries beneficiary${beneficiaries > 1 ? 'ies' : ''}",
                          style: const TextStyle(fontSize: 10, color: Color(0xFFD4AF37)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAssetDialog,
        child: const Icon(Icons.add, color: Colors.black),
        backgroundColor: const Color(0xFFD4AF37),
      ),
    );
  }
}

// Updated Beneficiary Model with source field
class Beneficiary {
  final String name;
  final String relationship;
  final String contact;
  final String sharePercentage;
  final String shareType;
  final String? source; // Added to track if from trusted contacts

  Beneficiary({
    required this.name,
    required this.relationship,
    required this.contact,
    required this.sharePercentage,
    required this.shareType,
    this.source,
  });

  Map<String, dynamic> toJson() => {
    "name": name,
    "relationship": relationship,
    "contact": contact,
    "sharePercentage": sharePercentage,
    "shareType": shareType,
    "source": source,
  };

  factory Beneficiary.fromJson(Map<String, dynamic> json) => Beneficiary(
    name: json["name"] ?? "",
    relationship: json["relationship"] ?? "",
    contact: json["contact"] ?? "",
    sharePercentage: json["sharePercentage"] ?? "",
    shareType: json["shareType"] ?? "Percentage",
    source: json["source"],
  );
}