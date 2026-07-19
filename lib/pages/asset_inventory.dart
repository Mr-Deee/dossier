import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/NotificationService.dart';
import '../widget/NotificationSheet.dart';

// ==================== APP COLORS ====================
class AppColors {
  static const Color primaryGold = Color(0xFFF5A623);
  static const Color primaryGoldLight = Color(0x33F5A623);
  static const Color primaryGoldMedium = Color(0x4DF5A623);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color black87 = Color(0xDD000000);
  static const Color black54 = Color(0x8A000000);
  static const Color red = Color(0xFFFF0000);
  static const Color redLight = Color(0x1AFF0000);
  static const Color grey50 = Color(0xFFFAFAFA);
}

// ==================== ASSET TYPE ====================
class AssetType {
  static const String bankAccount = "Bank Account";
  static const String property = "Property";
  static const String vehicle = "Vehicle";
  static const String investment = "Investment";
  static const String insurance = "Insurance Policy";
  static const String digitalAsset = "Digital Asset";
  static const String jewelry = "Jewelry";
  static const String cash = "Cash";
  static const String business = "Business";
  static const String other = "Other";

  static const List<String> all = [
    bankAccount, property, vehicle, investment,
    insurance, digitalAsset, jewelry, cash, business, other
  ];

  static IconData getIcon(String type) {
    switch (type) {
      case AssetType.bankAccount: return Icons.account_balance;
      case AssetType.property: return Icons.house;
      case AssetType.vehicle: return Icons.directions_car;
      case AssetType.investment: return Icons.trending_up;
      case AssetType.insurance: return Icons.security;
      case AssetType.digitalAsset: return Icons.devices;
      case AssetType.jewelry: return Icons.diamond;
      case AssetType.cash: return Icons.money;
      case AssetType.business: return Icons.business;
      default: return Icons.inventory_2;
    }
  }
}

// Helper function for type conversion
Map<String, dynamic> _safeCast(Map<dynamic, dynamic> data) {
  return Map<String, dynamic>.fromEntries(
      data.entries.map((entry) => MapEntry(entry.key.toString(), entry.value))
  );
}

// ==================== BENEFICIARY MODEL ====================
class Beneficiary {
  final String name;
  final String relationship;
  final String contact;
  final String sharePercentage;
  final String shareType;
  final String? source;

  const Beneficiary({
    required this.name,
    required this.relationship,
    required this.contact,
    required this.sharePercentage,
    required this.shareType,
    this.source,
  });

  factory Beneficiary.fromJson(Map<String, dynamic> json) => Beneficiary(
    name: json["name"]?.toString() ?? "",
    relationship: json["relationship"]?.toString() ?? "",
    contact: json["contact"]?.toString() ?? "",
    sharePercentage: json["sharePercentage"]?.toString() ?? "",
    shareType: json["shareType"]?.toString() ?? "Percentage",
    source: json["source"]?.toString(),
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "relationship": relationship,
    "contact": contact,
    "sharePercentage": sharePercentage,
    "shareType": shareType,
    "source": source,
  };
}

// ==================== ASSET MODEL ====================
class Asset {
  final String? key;
  final String type;
  final String description;
  final String estimatedValue;
  final String location;
  final List<Beneficiary> beneficiaries;
  final String notes;
  final String updatedAt;

  const Asset({
    this.key,
    required this.type,
    required this.description,
    required this.estimatedValue,
    required this.location,
    required this.beneficiaries,
    required this.notes,
    required this.updatedAt,
  });

  factory Asset.fromJson(Map<String, dynamic> json, {String? key}) {
    List<Beneficiary> beneficiaries = [];
    final beneficiariesData = json["beneficiaries"];
    if (beneficiariesData != null && beneficiariesData is List) {
      beneficiaries = beneficiariesData
          .map((b) {
        if (b is Map<String, dynamic>) {
          return Beneficiary.fromJson(b);
        } else if (b is Map) {
          return Beneficiary.fromJson(_safeCast(b));
        }
        return null;
      })
          .whereType<Beneficiary>()
          .toList();
    }

    return Asset(
      key: key,
      type: json["type"]?.toString() ?? AssetType.other,
      description: json["description"]?.toString() ?? "",
      estimatedValue: json["estimatedValue"]?.toString() ?? "",
      location: json["location"]?.toString() ?? "",
      beneficiaries: beneficiaries,
      notes: json["notes"]?.toString() ?? "",
      updatedAt: json["updatedAt"]?.toString() ?? "",
    );
  }

  Map<String, dynamic> toJson() => {
    "type": type,
    "description": description,
    "estimatedValue": estimatedValue,
    "location": location,
    "beneficiaries": beneficiaries.map((b) => b.toJson()).toList(),
    "notes": notes,
    "updatedAt": updatedAt,
  };
}

// ==================== CUSTOM WIDGETS ====================

class GoldAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final String? subtitle;
  final bool showBackButton; // Add this field

  const GoldAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.subtitle,
    this.showBackButton = false, // Default to false
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.amber,
      elevation: 4,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.primaryGold,
              ),
            ),
        ],
      ),
      leading: leading ??
          (showBackButton
              ? IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          )
              : null),
      actions: actions,
      bottom: subtitle != null
          ? PreferredSize(
        preferredSize: const Size.fromHeight(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.black.withOpacity(0.5),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.primaryGold, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  subtitle!,
                  style: const TextStyle(fontSize: 11, color: AppColors.white),
                ),
              ),
            ],
          ),
        ),
      )
          : null,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
    subtitle != null ? 100 : kToolbarHeight,
  );
}


class GoldCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final bool hasBorder;
  final VoidCallback? onTap;

  const GoldCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.hasBorder = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin ?? const EdgeInsets.only(bottom: 12),
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(12),
          border: hasBorder
              ? Border.all(color: AppColors.primaryGold.withOpacity(0.3))
              : null,
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: child,
      ),
    );
  }
}

class GoldFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final bool isRequired;
  final TextInputType keyboardType;
  final int? maxLines;
  final String? Function(String?)? validator;

  const GoldFormField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.isRequired = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: AppColors.black),
      decoration: InputDecoration(
        labelText: isRequired ? "$label *" : label,
        hintText: hint,
        border: const OutlineInputBorder(),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppColors.primaryGold) : null,
        labelStyle: const TextStyle(color: AppColors.primaryGold),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: isRequired
          ? (value) => value?.trim().isEmpty == true ? "Please enter $label" : null
          : validator,
    );
  }
}

class GoldButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isOutlined;

  const GoldButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.isPrimary = true,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon, color: AppColors.primaryGold) : const SizedBox.shrink(),
        label: Text(text),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: AppColors.primaryGold),
          foregroundColor: AppColors.primaryGold,
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon, color: isPrimary ? AppColors.black : AppColors.primaryGold) : const SizedBox.shrink(),
      label: Text(text, style: TextStyle(color: isPrimary ? AppColors.black : AppColors.primaryGold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? AppColors.primaryGold : AppColors.white,
        foregroundColor: isPrimary ? AppColors.black : AppColors.primaryGold,
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: isPrimary ? null : const BorderSide(color: AppColors.primaryGold),
      ),
    );
  }
}

// ==================== ASSET INVENTORY PAGE ====================
class AssetInventoryPage extends StatefulWidget {
  final VoidCallback? onBackToHome;
  final bool showAppBar; // NEW: Control app bar visibility

  final String? title;

  const AssetInventoryPage({
    super.key,
    this.title,
    this.onBackToHome,
    this.showAppBar = true, // Default to showing app bar
  });

  @override
  State<AssetInventoryPage> createState() => _AssetInventoryPageState();
}

class _AssetInventoryPageState extends State<AssetInventoryPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("assets");
  final DatabaseReference _trustedContactsRef = FirebaseDatabase.instance.ref("trustedContacts");




  List<Asset> _assets = [];
  List<Map<String, dynamic>> _existingContacts = [];
  List<Beneficiary> _beneficiariesFromContacts = [];
  bool _isLoading = true;
  bool _isDisposed = false;

  // Form state
  final _descriptionController = TextEditingController();
  final _estimatedValueController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedAssetType = AssetType.bankAccount;
  List<Beneficiary> _selectedBeneficiaries = [];

  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _descriptionController.dispose();
    _estimatedValueController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    if (_currentUserId == null) return;

    await Future.wait([
      _loadAssets(),
      _loadTrustedContacts(),
      _loadBeneficiariesFromTrustedContacts(),
    ]);
  }

  Future<void> _loadAssets() async {
    if (_currentUserId == null || _isDisposed) return;

    if (mounted && !_isDisposed) {
      setState(() => _isLoading = true);
    }

    try {
      final snapshot = await _dbRef.child(_currentUserId!).get();
      if (_isDisposed) return;

      if (snapshot.exists && mounted && !_isDisposed) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final List<Asset> loadedAssets = [];

        data.forEach((key, value) {
          if (value is Map) {
            final assetData = _safeCast(value);
            loadedAssets.add(Asset.fromJson(assetData, key: key.toString()));
          }
        });

        setState(() {
          _assets = loadedAssets;
          _isLoading = false;
        });
      } else if (mounted && !_isDisposed) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Error loading assets: $e");
      if (mounted && !_isDisposed) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadTrustedContacts() async {
    if (_currentUserId == null || _isDisposed) return;

    try {
      final snapshot = await _trustedContactsRef.child(_currentUserId!).get();
      if (_isDisposed) return;

      if (snapshot.exists && mounted && !_isDisposed) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final List<Map<String, dynamic>> contacts = [];

        data.forEach((key, value) {
          if (value is Map) {
            final contact = _safeCast(value);
            contacts.add({
              "key": key.toString(),
              "name": contact["name"] ?? "",
              "email": contact["email"] ?? "",
              "phone": contact["phone"] ?? "",
              "relationship": contact["relationship"] ?? "",
            });
          }
        });

        setState(() {
          _existingContacts = contacts;
        });
      }
    } catch (e) {
      print("Error loading trusted contacts: $e");
    }
  }

  Future<void> _loadBeneficiariesFromTrustedContacts() async {
    if (_currentUserId == null || _isDisposed) return;

    try {
      final snapshot = await _trustedContactsRef.child(_currentUserId!).get();
      if (_isDisposed) return;

      if (snapshot.exists && mounted && !_isDisposed) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final List<Beneficiary> beneficiaries = [];

        data.forEach((key, value) {
          if (value is Map) {
            final contact = _safeCast(value);
            beneficiaries.add(Beneficiary(
              name: contact["name"]?.toString() ?? "",
              relationship: contact["relationship"]?.toString() ?? "",
              contact: contact["phone"]?.toString() ?? contact["email"]?.toString() ?? "",
              sharePercentage: "0",
              shareType: "Percentage",
              source: "trusted_contacts",
            ));
          }
        });

        setState(() {
          _beneficiariesFromContacts = beneficiaries;
        });
      }
    } catch (e) {
      print("Error loading beneficiaries from contacts: $e");
    }
  }

  Future<void> _addAsset() async {
    if (_currentUserId == null || _isDisposed) return;

    // Sync beneficiaries to trusted contacts
    for (var beneficiary in _selectedBeneficiaries) {
      await _syncToTrustedContacts(beneficiary);
    }

    final asset = Asset(
      type: _selectedAssetType,
      description: _descriptionController.text.trim(),
      estimatedValue: _estimatedValueController.text.trim(),
      location: _locationController.text.trim(),
      beneficiaries: _selectedBeneficiaries,
      notes: _notesController.text.trim(),
      updatedAt: DateTime.now().toIso8601String(),
    );

    await _dbRef.child(_currentUserId!).push().set(asset.toJson());
    _resetForm();
    await _loadAllData();

    if (mounted && !_isDisposed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Asset added successfully! Beneficiaries added to Trusted Contacts."),
          backgroundColor: AppColors.primaryGold,
        ),
      );
    }
  }

  Future<void> _syncToTrustedContacts(Beneficiary beneficiary) async {
    if (_currentUserId == null) return;

    final exists = _existingContacts.any(
            (contact) => contact["name"].toString().toLowerCase() == beneficiary.name.toLowerCase()
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
      await _trustedContactsRef.child(_currentUserId!).push().set(newContact);
    }
  }

  Future<void> _deleteAsset(Asset asset) async {
    if (_currentUserId == null || asset.key == null || _isDisposed) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        title: const Text("Delete Asset", style: TextStyle(color: AppColors.primaryGold)),
        content: const Text("Are you sure you want to delete this asset? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: AppColors.primaryGold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted && !_isDisposed) {
      await _dbRef.child(_currentUserId!).child(asset.key!).remove();
      await _loadAssets();
      if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Asset deleted"), backgroundColor: AppColors.red),
        );
      }
    }
  }

  void _resetForm() {
    _descriptionController.clear();
    _estimatedValueController.clear();
    _locationController.clear();
    _notesController.clear();
    _selectedBeneficiaries.clear();
    _selectedAssetType = AssetType.bankAccount;
  }

  void _toggleBeneficiary(Beneficiary beneficiary, bool selected) {
    if (mounted && !_isDisposed) {
      setState(() {
        if (selected) {
          _selectedBeneficiaries.add(beneficiary);
        } else {
          _selectedBeneficiaries.removeWhere((b) => b.name == beneficiary.name);
        }
      });
    }
  }

  // ==================== NOTIFICATION METHODS ====================
  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NotificationSettingsSheet(),
    );
  }

  void _addNotificationForAsset(Asset asset) async {
    await showDialog(
      context: context,
      builder: (context) => AddNotificationDialog(
        asset: asset,
        onSave: (schedule) async {
          final notificationService = NotificationService();
          await notificationService.scheduleNotification(schedule);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Notification scheduled successfully"), backgroundColor: Colors.green),
            );
          }
        },
      ),
    );
  }

  // ==================== DIALOGS ====================
  void _showAddAssetDialog() {
    _resetForm();

    // Notification state for the dialog - always enabled now
    NotificationType selectedNotificationType = NotificationType.email;
    NotificationFrequency selectedFrequency = NotificationFrequency.once;
    DateTime scheduledDateTime = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = TimeOfDay.now();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();

    // Validation state
    String? emailError;
    String? phoneError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> selectDateTime() async {
            final date = await showDatePicker(
              context: context,
              initialDate: scheduledDateTime,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
            );

            if (date != null && mounted) {
              final time = await showTimePicker(
                context: context,
                initialTime: selectedTime,
              );

              if (time != null && mounted) {
                setDialogState(() {
                  scheduledDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                  selectedTime = time;
                });
              }
            }
          }

          bool validateNotification() {
            bool isValid = true;

            if (selectedNotificationType != NotificationType.push) {
              final email = emailController.text.trim();
              if (email.isEmpty) {
                emailError = "Email address is required";
                isValid = false;
              } else if (!email.contains('@') || !email.contains('.')) {
                emailError = "Please enter a valid email address";
                isValid = false;
              } else {
                emailError = null;
              }
            }

            if (selectedNotificationType != NotificationType.email) {
              final phone = phoneController.text.trim();
              if (phone.isEmpty) {
                phoneError = "Phone number is required";
                isValid = false;
              } else {
                phoneError = null;
              }
            }

            setDialogState(() {});
            return isValid;
          }

          return Dialog(
            insetPadding: EdgeInsets.zero,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: AppColors.white,
              child: Column(
                children: [
                  GoldAppBar(
                    title: "Add New Asset",
                    leading: IconButton(
                      icon: const Icon(Icons.close, color: AppColors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                    actions: [
                      GoldButton(
                        text: "Save Asset",
                        icon: Icons.save,
                        onPressed: () async {
                          if (_descriptionController.text.trim().isEmpty) {
                            if (mounted && !_isDisposed) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Please enter a description")),
                              );
                            }
                            return;
                          }

                          // Validate notification fields
                          if (!validateNotification()) {
                            if (mounted && !_isDisposed) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Please complete all required notification fields"),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                            return;
                          }

                          await _addAsset();

                          if (mounted && _assets.isNotEmpty) {
                            final latestAsset = _assets.last;
                            final schedule = NotificationSchedule(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              assetId: latestAsset.key ?? "",
                              assetName: latestAsset.description,
                              type: selectedNotificationType,
                              frequency: selectedFrequency,
                              scheduledTime: scheduledDateTime,
                              recipientEmail: selectedNotificationType != NotificationType.push ? emailController.text.trim() : null,
                              recipientPhone: selectedNotificationType != NotificationType.email ? phoneController.text.trim() : null,
                              isActive: true,
                              createdAt: DateTime.now(),
                            );

                            final notificationService = NotificationService();
                            await notificationService.scheduleNotification(schedule);

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("✓ Asset saved with notification scheduled!"),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          }

                          if (mounted && !_isDisposed) Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section: Basic Information
                          _buildSectionHeader(Icons.category, "Basic Information"),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: _selectedAssetType,
                              items: AssetType.all.map((type) => DropdownMenuItem(
                                value: type,
                                child: Row(
                                  children: [
                                    Icon(AssetType.getIcon(type), size: 20, color: AppColors.primaryGold),
                                    const SizedBox(width: 8),
                                    Text(type),
                                  ],
                                ),
                              )).toList(),
                              onChanged: (value) => setDialogState(() => _selectedAssetType = value!),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                prefixIcon: Icon(Icons.category, color: AppColors.primaryGold),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          GoldFormField(
                            controller: _descriptionController,
                            label: "Asset Description",
                            hint: "e.g., Savings Account - GCB Bank",
                            prefixIcon: Icons.description,
                            isRequired: true,
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: GoldFormField(
                                  controller: _estimatedValueController,
                                  label: "Estimated Value",
                                  hint: "GHS 10,000",
                                  prefixIcon: Icons.monetization_on,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GoldFormField(
                                  controller: _locationController,
                                  label: "Location",
                                  hint: "Accra, Ghana",
                                  prefixIcon: Icons.location_on,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Section: Beneficiaries
                          _buildSectionHeader(Icons.family_restroom, "Beneficiaries"),
                          const SizedBox(height: 8),

                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.grey50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.primaryGold.withOpacity(0.2)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      "Assign beneficiaries to this asset",
                                      style: TextStyle(color: AppColors.black54, fontSize: 12),
                                    ),
                                    const Spacer(),
                                    TextButton.icon(
                                      onPressed: () => _showAddBeneficiaryDialog(setDialogState, _selectedBeneficiaries),
                                      icon: const Icon(Icons.add_circle, color: AppColors.primaryGold, size: 20),
                                      label: const Text("Add", style: TextStyle(color: AppColors.primaryGold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                if (_beneficiariesFromContacts.isNotEmpty) ...[
                                  const Divider(),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _beneficiariesFromContacts.map((contact) {
                                      final isSelected = _selectedBeneficiaries.any((b) => b.name == contact.name);
                                      return ChoiceChip(
                                        label: Text(contact.name),
                                        selected: isSelected,
                                        onSelected: (selected) {
                                          setDialogState(() => _toggleBeneficiary(contact, selected));
                                        },
                                        selectedColor: AppColors.primaryGold,
                                        backgroundColor: Colors.grey.shade200,
                                        labelStyle: TextStyle(
                                          color: isSelected ? Colors.white : AppColors.black87,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        ),
                                        avatar: CircleAvatar(
                                          radius: 12,
                                          backgroundColor: AppColors.primaryGoldLight,
                                          child: Text(
                                            contact.name[0].toUpperCase(),
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],

                                if (_selectedBeneficiaries.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  const Divider(),
                                  const SizedBox(height: 8),
                                  ..._selectedBeneficiaries.map((beneficiary) => Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryGoldLight,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: AppColors.primaryGold,
                                          child: Text(
                                            beneficiary.name[0].toUpperCase(),
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(beneficiary.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                              Text(beneficiary.relationship, style: const TextStyle(fontSize: 11, color: AppColors.black54)),
                                            ],
                                          ),
                                        ),
                                        if (beneficiary.source != "trusted_contacts")
                                          GestureDetector(
                                            onTap: () => setDialogState(() => _selectedBeneficiaries.remove(beneficiary)),
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: AppColors.redLight,
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: const Icon(Icons.close, size: 16, color: AppColors.red),
                                            ),
                                          ),
                                      ],
                                    ),
                                  )),
                                ],

                                if (_selectedBeneficiaries.isEmpty && _beneficiariesFromContacts.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      children: [
                                        Icon(Icons.people_outline, size: 40, color: Colors.grey.shade400),
                                        const SizedBox(height: 8),
                                        Text(
                                          "No beneficiaries added",
                                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Section: Notification Settings (REQUIRED - always shown)
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [AppColors.primaryGoldLight, AppColors.white],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.primaryGold, width: 1.5),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Required Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.black,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(14),
                                      topRight: Radius.circular(14),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.notifications_active, color: AppColors.primaryGold, size: 16),
                                      SizedBox(width: 6),
                                      Text(
                                        "REQUIRED: Notification Settings",
                                        style: TextStyle(
                                          color: AppColors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Notification Type Selector
                                      const Text(
                                        "Delivery Method *",
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.black87),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: NotificationType.values.map((type) {
                                          final isSelected = selectedNotificationType == type;
                                          IconData icon;
                                          String label;
                                          switch (type) {
                                            case NotificationType.email:
                                              icon = Icons.email;
                                              label = "Email";
                                              break;
                                            case NotificationType.push:
                                              icon = Icons.notifications;
                                              label = "Push";
                                              break;
                                            case NotificationType.both:
                                              icon = Icons.email;
                                              label = "Both";
                                              break;
                                          }
                                          return Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 4),
                                              child: FilterChip(
                                                label: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.primaryGold),
                                                    const SizedBox(width: 4),
                                                    Text(label),
                                                  ],
                                                ),
                                                selected: isSelected,
                                                onSelected: (selected) {
                                                  if (selected) {
                                                    setDialogState(() {
                                                      selectedNotificationType = type;
                                                      emailError = null;
                                                      phoneError = null;
                                                    });
                                                  }
                                                },
                                                selectedColor: AppColors.primaryGold,
                                                backgroundColor: AppColors.white,
                                                checkmarkColor: Colors.white,
                                                labelStyle: TextStyle(
                                                  color: isSelected ? Colors.white : AppColors.primaryGold,
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                      const SizedBox(height: 16),

                                      // Email Field
                                      if (selectedNotificationType != NotificationType.push) ...[
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: emailError != null ? AppColors.red : Colors.grey.shade300,
                                              width: emailError != null ? 1.5 : 1,
                                            ),
                                          ),
                                          child: TextFormField(
                                            controller: emailController,
                                            decoration: InputDecoration(
                                              labelText: "Email Address *",
                                              hintText: "recipient@example.com",
                                              prefixIcon: Icon(Icons.email, color: AppColors.primaryGold, size: 20),
                                              suffixIcon: emailError == null
                                                  ? const Icon(Icons.check_circle, color: Colors.green, size: 18)
                                                  : const Icon(Icons.error, color: AppColors.red, size: 18),
                                              errorText: emailError,
                                              border: InputBorder.none,
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                            ),
                                            keyboardType: TextInputType.emailAddress,
                                            onChanged: (_) => validateNotification(),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                      ],

                                      // Phone Field
                                      if (selectedNotificationType != NotificationType.email) ...[
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: phoneError != null ? AppColors.red : Colors.grey.shade300,
                                              width: phoneError != null ? 1.5 : 1,
                                            ),
                                          ),
                                          child: TextFormField(
                                            controller: phoneController,
                                            decoration: InputDecoration(
                                              labelText: "Phone Number *",
                                              hintText: "+233 XX XXX XXXX",
                                              prefixIcon: Icon(Icons.phone, color: AppColors.primaryGold, size: 20),
                                              suffixIcon: phoneError == null
                                                  ? const Icon(Icons.check_circle, color: Colors.green, size: 18)
                                                  : const Icon(Icons.error, color: AppColors.red, size: 18),
                                              errorText: phoneError,
                                              border: InputBorder.none,
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                            ),
                                            keyboardType: TextInputType.phone,
                                            onChanged: (_) => validateNotification(),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                      ],

                                      // Frequency Selection
                                      const Text(
                                        "Repeat *",
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.black87),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.grey.shade300),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButtonFormField<NotificationFrequency>(
                                            value: selectedFrequency,
                                            items: NotificationFrequency.values.map((freq) {
                                              IconData icon;
                                              switch (freq) {
                                                case NotificationFrequency.once: icon = Icons.access_time;
                                                case NotificationFrequency.daily: icon = Icons.today;
                                                case NotificationFrequency.weekly: icon = Icons.weekend;
                                                case NotificationFrequency.monthly: icon = Icons.calendar_month;
                                                case NotificationFrequency.quarterly: icon = Icons.calendar_today;
                                                case NotificationFrequency.yearly: icon = Icons.calendar_view_day_rounded;
                                              }
                                              return DropdownMenuItem(
                                                value: freq,
                                                child: Row(
                                                  children: [
                                                    Icon(icon, size: 18, color: AppColors.primaryGold),
                                                    const SizedBox(width: 8),
                                                    Text(freq.displayName),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: (value) => setDialogState(() => selectedFrequency = value!),
                                            decoration: const InputDecoration(
                                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                              border: InputBorder.none,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),

                                      // Date & Time Picker
                                      const Text(
                                        "First Reminder *",
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.black87),
                                      ),
                                      const SizedBox(height: 8),
                                      InkWell(
                                        onTap: selectDateTime,
                                        child: Container(
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.grey.shade300),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primaryGoldLight,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Icon(Icons.calendar_today, color: AppColors.primaryGold, size: 20),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "${scheduledDateTime.toLocal().toString().split('.').first}",
                                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                                    ),
                                                    const Text(
                                                      "Click to change date & time",
                                                      style: TextStyle(fontSize: 11, color: AppColors.black54),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const Icon(Icons.chevron_right, color: AppColors.primaryGold),
                                            ],
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryGoldLight,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(Icons.info_outline, size: 14, color: AppColors.primaryGold),
                                            SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                "Notification is required for asset tracking. You'll receive reminders based on your settings.",
                                                style: TextStyle(fontSize: 10, color: AppColors.black54),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Section: Additional Notes
                          _buildSectionHeader(Icons.note_add, "Additional Notes"),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.grey50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.primaryGold.withOpacity(0.2)),
                            ),
                            child: GoldFormField(
                              controller: _notesController,
                              label: "Notes",
                              hint: "Any additional information about this asset...",
                              prefixIcon: Icons.edit_note,
                              maxLines: 3,
                            ),
                          ),

                          const SizedBox(height: 32),
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

  // Helper method for section headers
  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primaryGoldLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primaryGold, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.black87,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(left: 10),
          height: 2,
          width: 30,
          color: AppColors.primaryGold.withOpacity(0.5),
        ),
      ],
    );
  }
  void _showAddBeneficiaryDialog(Function setDialogState, List<Beneficiary> currentBeneficiaries) {
    final nameController = TextEditingController();
    final relationshipController = TextEditingController();
    final contactController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.zero,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: AppColors.white,
          child: Column(
            children: [
              GoldAppBar(
                title: "Add Beneficiary",
                showBackButton: true,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGoldLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.people_alt, size: 60, color: AppColors.primaryGold),
                        ),
                      ),
                      const SizedBox(height: 24),
                      GoldCard(
                        child: Column(
                          children: [
                            GoldFormField(
                              controller: nameController,
                              label: "Full Name",
                              hint: "e.g., John Mensah",
                              prefixIcon: Icons.person,
                              isRequired: true,
                            ),
                            const SizedBox(height: 16),
                            GoldFormField(
                              controller: relationshipController,
                              label: "Relationship",
                              hint: "e.g., Son, Daughter, Spouse",
                              prefixIcon: Icons.family_restroom,
                              isRequired: true,
                            ),
                            const SizedBox(height: 16),
                            GoldFormField(
                              controller: contactController,
                              label: "Contact Information",
                              hint: "e.g., Phone number or email",
                              prefixIcon: Icons.contact_phone,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: GoldButton(
                              text: "Cancel",
                              onPressed: () => Navigator.pop(context),
                              isPrimary: false,
                              isOutlined: true,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: GoldButton(
                              text: "Add Beneficiary",
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
                                  if (!currentBeneficiaries.any((b) => b.name == newBeneficiary.name)) {
                                    currentBeneficiaries.add(newBeneficiary);
                                  }
                                });
                                Navigator.pop(context);
                              },
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
  void _showAssetDetails(Asset asset) {
    // Create controllers with existing data
    final descriptionController = TextEditingController(text: asset.description);
    final estimatedValueController = TextEditingController(text: asset.estimatedValue);
    final locationController = TextEditingController(text: asset.location);
    final notesController = TextEditingController(text: asset.notes);

    String selectedAssetType = asset.type;
    List<Beneficiary> selectedBeneficiaries = List.from(asset.beneficiaries);
    bool isEditing = false;

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
              color: AppColors.white,
              child: Column(
                children: [
                  GoldAppBar(
                    title: isEditing ? "Edit Asset" : asset.description,
                    showBackButton: true,
                    actions: [
                      if (!isEditing) ...[
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.black),
                          onPressed: () {
                            setDialogState(() {
                              isEditing = true;
                            });
                          },
                          tooltip: "Edit Asset",
                        ),
                        IconButton(
                          icon: const Icon(Icons.notification_add, color: Colors.black),
                          onPressed: () {
                            Navigator.pop(context);
                            _addNotificationForAsset(asset);
                          },
                          tooltip: "Add Notification",
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: AppColors.red),
                          onPressed: () {
                            Navigator.pop(context);
                            _deleteAsset(asset);
                          },
                        ),
                      ] else ...[
                        GoldButton(
                          text: "Save",
                          icon: Icons.save,
                          onPressed: () async {
                            // Validate
                            if (descriptionController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Please enter a description")),
                              );
                              return;
                            }

                            // Update asset
                            final updatedAsset = Asset(
                              key: asset.key,
                              type: selectedAssetType,
                              description: descriptionController.text.trim(),
                              estimatedValue: estimatedValueController.text.trim(),
                              location: locationController.text.trim(),
                              beneficiaries: selectedBeneficiaries,
                              notes: notesController.text.trim(),
                              updatedAt: DateTime.now().toIso8601String(),
                            );

                            await _updateAsset(updatedAsset);

                            if (mounted && !_isDisposed) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Asset updated successfully!"),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }

                            Navigator.pop(context);
                            await _loadAssets(); // Refresh the list
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.red),
                          onPressed: () {
                            setDialogState(() {
                              isEditing = false;
                              // Reset to original values
                              descriptionController.text = asset.description;
                              estimatedValueController.text = asset.estimatedValue;
                              locationController.text = asset.location;
                              notesController.text = asset.notes;
                              selectedAssetType = asset.type;
                              selectedBeneficiaries = List.from(asset.beneficiaries);
                            });
                          },
                          tooltip: "Cancel Edit",
                        ),
                      ],
                    ],
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isEditing) ...[
                            // View Mode
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGoldLight,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(AssetType.getIcon(asset.type), color: AppColors.primaryGold),
                                    const SizedBox(width: 8),
                                    Text(asset.type, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGold)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            const Text(
                              "Asset Details",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryGold),
                            ),
                            const SizedBox(height: 16),
                            _buildDetailCard(Icons.description, "Description", asset.description),
                            const SizedBox(height: 12),
                            _buildDetailCard(Icons.monetization_on, "Estimated Value", asset.estimatedValue.isEmpty ? "Not specified" : asset.estimatedValue),
                            const SizedBox(height: 12),
                            _buildDetailCard(Icons.location_on, "Location / Details", asset.location.isEmpty ? "Not specified" : asset.location),
                            const SizedBox(height: 24),
                            const Text(
                              "Beneficiaries",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryGold),
                            ),
                            const SizedBox(height: 16),
                            if (asset.beneficiaries.isEmpty)
                              GoldCard(
                                padding: const EdgeInsets.all(32),
                                child: const Center(child: Text("No beneficiaries assigned to this asset", style: TextStyle(color: AppColors.black54))),
                              )
                            else
                              ...asset.beneficiaries.map((b) => _buildBeneficiaryCard(b)),
                            const SizedBox(height: 24),
                            if (asset.notes.isNotEmpty) ...[
                              const Text(
                                "Additional Notes",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryGold),
                              ),
                              const SizedBox(height: 16),
                              _buildDetailCard(Icons.note, "Notes", asset.notes),
                            ],
                          ] else ...[
                            // Edit Mode
                            _buildSectionHeader(Icons.category, "Basic Information"),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
                              ),
                              child: DropdownButtonFormField<String>(
                                value: selectedAssetType,
                                items: AssetType.all.map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Row(
                                    children: [
                                      Icon(AssetType.getIcon(type), size: 20, color: AppColors.primaryGold),
                                      const SizedBox(width: 8),
                                      Text(type),
                                    ],
                                  ),
                                )).toList(),
                                onChanged: (value) => setDialogState(() => selectedAssetType = value!),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  prefixIcon: Icon(Icons.category, color: AppColors.primaryGold),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            GoldFormField(
                              controller: descriptionController,
                              label: "Asset Description",
                              hint: "e.g., Savings Account - GCB Bank",
                              prefixIcon: Icons.description,
                              isRequired: true,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: GoldFormField(
                                    controller: estimatedValueController,
                                    label: "Estimated Value",
                                    hint: "GHS 10,000",
                                    prefixIcon: Icons.monetization_on,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: GoldFormField(
                                    controller: locationController,
                                    label: "Location",
                                    hint: "Accra, Ghana",
                                    prefixIcon: Icons.location_on,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildSectionHeader(Icons.family_restroom, "Beneficiaries"),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.grey50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.primaryGold.withOpacity(0.2)),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        "Assign beneficiaries to this asset",
                                        style: TextStyle(color: AppColors.black54, fontSize: 12),
                                      ),
                                      const Spacer(),
                                      TextButton.icon(
                                        onPressed: () => _showAddBeneficiaryDialog(setDialogState, selectedBeneficiaries),
                                        icon: const Icon(Icons.add_circle, color: AppColors.primaryGold, size: 20),
                                        label: const Text("Add", style: TextStyle(color: AppColors.primaryGold)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (_beneficiariesFromContacts.isNotEmpty) ...[
                                    const Divider(),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: _beneficiariesFromContacts.map((contact) {
                                        final isSelected = selectedBeneficiaries.any((b) => b.name == contact.name);
                                        return ChoiceChip(
                                          label: Text(contact.name),
                                          selected: isSelected,
                                          onSelected: (selected) {
                                            setDialogState(() {
                                              if (selected) {
                                                if (!selectedBeneficiaries.any((b) => b.name == contact.name)) {
                                                  selectedBeneficiaries.add(contact);
                                                }
                                              } else {
                                                selectedBeneficiaries.removeWhere((b) => b.name == contact.name);
                                              }
                                            });
                                          },
                                          selectedColor: AppColors.primaryGold,
                                          backgroundColor: Colors.grey.shade200,
                                          labelStyle: TextStyle(
                                            color: isSelected ? Colors.white : AppColors.black87,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          ),
                                          avatar: CircleAvatar(
                                            radius: 12,
                                            backgroundColor: AppColors.primaryGoldLight,
                                            child: Text(
                                              contact.name[0].toUpperCase(),
                                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                  if (selectedBeneficiaries.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    const Divider(),
                                    const SizedBox(height: 8),
                                    ...selectedBeneficiaries.map((beneficiary) => Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryGoldLight,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 16,
                                            backgroundColor: AppColors.primaryGold,
                                            child: Text(
                                              beneficiary.name[0].toUpperCase(),
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(beneficiary.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                                Text(beneficiary.relationship, style: const TextStyle(fontSize: 11, color: AppColors.black54)),
                                              ],
                                            ),
                                          ),
                                          if (beneficiary.source != "trusted_contacts")
                                            GestureDetector(
                                              onTap: () => setDialogState(() => selectedBeneficiaries.remove(beneficiary)),
                                              child: Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: AppColors.redLight,
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: const Icon(Icons.close, size: 16, color: AppColors.red),
                                              ),
                                            ),
                                        ],
                                      ),
                                    )),
                                  ],
                                  if (selectedBeneficiaries.isEmpty && _beneficiariesFromContacts.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        children: [
                                          Icon(Icons.people_outline, size: 40, color: Colors.grey.shade400),
                                          const SizedBox(height: 8),
                                          Text(
                                            "No beneficiaries added",
                                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildSectionHeader(Icons.note_add, "Additional Notes"),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.grey50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.primaryGold.withOpacity(0.2)),
                              ),
                              child: GoldFormField(
                                controller: notesController,
                                label: "Notes",
                                hint: "Any additional information about this asset...",
                                prefixIcon: Icons.edit_note,
                                maxLines: 3,
                              ),
                            ),
                          ],
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


  Future<void> _updateAsset(Asset updatedAsset) async {
    if (_currentUserId == null || updatedAsset.key == null || _isDisposed) return;

    try {
      await _dbRef
          .child(_currentUserId!)
          .child(updatedAsset.key!)
          .update(updatedAsset.toJson());

      // Refresh the assets list
      await _loadAssets();
    } catch (e) {
      print("Error updating asset: $e");
      if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error updating asset. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  Widget _buildDetailCard(IconData icon, String label, String value) {
    return GoldCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryGoldLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primaryGold, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.primaryGold)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 16, color: AppColors.black)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeneficiaryCard(Beneficiary beneficiary) {
    return GoldCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primaryGoldLight,
            radius: 25,
            child: Text(
              beneficiary.name[0].toUpperCase(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryGold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(beneficiary.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.black)),
                Text(beneficiary.relationship, style: const TextStyle(color: AppColors.primaryGold)),
                if (beneficiary.contact.isNotEmpty)
                  Text(beneficiary.contact, style: const TextStyle(fontSize: 12, color: AppColors.black54)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryGoldLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              beneficiary.sharePercentage,
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final crossAxisCount = isTablet ? (screenWidth > 900 ? 4 : 3) : 2;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: GoldAppBar(

        title: widget.title?? "Asset Inventory",
        showBackButton: widget.onBackToHome != null,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: AppColors.black),
            onPressed: _showNotificationSettings,
            tooltip: "Notification Settings",
          ),
        ],
      ) ,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGold)))
          : _assets.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text("No assets added yet", style: TextStyle(fontSize: 18, color: AppColors.black87)),
            const SizedBox(height: 8),
            const Text("Tap the + button to add your first asset", style: TextStyle(color: AppColors.black54)),
            const SizedBox(height: 24),
            GoldButton(
              text: "Add Asset",
              icon: Icons.add,
              onPressed: _showAddAssetDialog,
            ),
          ],
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 33,
            mainAxisSpacing: 26,
            childAspectRatio: isTablet ? 1.1 : 0.9,
          ),
          itemCount: _assets.length,
          itemBuilder: (context, index) {
            final asset = _assets[index];
            return GestureDetector(
              onTap: () => _showAssetDetails(asset),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryGoldLight, AppColors.white],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGoldMedium,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(AssetType.getIcon(asset.type), size: 40, color: AppColors.primaryGold),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        asset.description,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.black87),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      asset.estimatedValue.isEmpty ? "Value not set" : asset.estimatedValue,
                      style: const TextStyle(fontSize: 12, color: AppColors.black54),
                    ),
                    if (asset.beneficiaries.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGoldMedium,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${asset.beneficiaries.length} beneficiary${asset.beneficiaries.length > 1 ? 'ies' : ''}",
                          style: const TextStyle(fontSize: 10, color: AppColors.primaryGold),
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
      floatingActionButton: widget.showAppBar ? FloatingActionButton(
        onPressed: _showAddAssetDialog,
        child: const Icon(Icons.add, color: AppColors.black),
        backgroundColor: AppColors.primaryGold,
      ) : null,
    );
  }
}