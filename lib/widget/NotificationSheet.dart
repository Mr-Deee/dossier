// ==================== NOTIFICATION SETTINGS SHEET ====================
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/NotificationService.dart';
import '../pages/asset_inventory.dart';

class NotificationSettingsSheet extends StatefulWidget {
  const NotificationSettingsSheet({super.key});

  @override
  State<NotificationSettingsSheet> createState() => _NotificationSettingsSheetState();
}

class _NotificationSettingsSheetState extends State<NotificationSettingsSheet> {
  List<NotificationSchedule> _schedules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() => _isLoading = true);
    final notificationService = NotificationService();
    final schedules = await notificationService.getNotificationSchedules();
    setState(() {
      _schedules = schedules;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          GoldAppBar(
            title: "Notification Settings",
            subtitle: "Manage your scheduled notifications",
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGold))
                : _schedules.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    "No scheduled notifications",
                    style: TextStyle(fontSize: 18, color: AppColors.black54),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Add notifications from asset details",
                    style: TextStyle(color: AppColors.black54),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _schedules.length,
              itemBuilder: (context, index) {
                final schedule = _schedules[index];
                return GoldCard(
                  onTap: () async {
                    await showDialog(
                      context: context,
                      builder: (context) => EditNotificationDialog(
                        schedule: schedule,
                        onUpdate: () => _loadSchedules(),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: schedule.isActive ? AppColors.primaryGoldLight : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              schedule.isActive ? "Active" : "Inactive",
                              style: TextStyle(
                                fontSize: 10,
                                color: schedule.isActive ? AppColors.primaryGold : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            schedule.frequency.displayName,
                            style: const TextStyle(fontSize: 12, color: AppColors.primaryGold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        schedule.assetName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 14, color: AppColors.black54),
                          const SizedBox(width: 4),
                          Text(
                            "${schedule.scheduledTime.toLocal().toString().split('.').first}",
                            style: const TextStyle(fontSize: 12, color: AppColors.black54),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            schedule.type == NotificationType.email ? Icons.email :
                            schedule.type == NotificationType.push ? Icons.notifications_active :
                            Icons.email,
                            size: 14,
                            color: AppColors.primaryGold,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            schedule.type.toString().split('.').last.toUpperCase(),
                            style: const TextStyle(fontSize: 12, color: AppColors.primaryGold, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      if (schedule.recipientEmail != null || schedule.recipientPhone != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          schedule.recipientEmail ?? schedule.recipientPhone ?? "",
                          style: const TextStyle(fontSize: 11, color: AppColors.black54),
                        ),
                      ],
                    ],
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


// ==================== EDIT NOTIFICATION DIALOG ====================
class EditNotificationDialog extends StatefulWidget {
  final NotificationSchedule schedule;
  final VoidCallback onUpdate;

  const EditNotificationDialog({
    super.key,
    required this.schedule,
    required this.onUpdate,
  });

  @override
  State<EditNotificationDialog> createState() => _EditNotificationDialogState();
}

class _EditNotificationDialogState extends State<EditNotificationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  late NotificationType _selectedType;
  late NotificationFrequency _selectedFrequency;
  late DateTime _selectedDateTime;
  late TimeOfDay _selectedTime;
  late bool _isActive;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.schedule.type;
    _selectedFrequency = widget.schedule.frequency;
    _selectedDateTime = widget.schedule.scheduledTime;
    _selectedTime = TimeOfDay.fromDateTime(widget.schedule.scheduledTime);
    _isActive = widget.schedule.isActive;
    _emailController.text = widget.schedule.recipientEmail ?? "";
    _phoneController.text = widget.schedule.recipientPhone ?? "";
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: _selectedTime,
      );

      if (time != null && mounted) {
        setState(() {
          _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
          _selectedTime = time;
        });
      }
    }
  }

  void _handleUpdate() {
    if (_formKey.currentState!.validate()) {
      _updateNotification();
    }
  }

  Future<void> _updateNotification() async {
    setState(() => _isLoading = true);

    final updatedSchedule = NotificationSchedule(
      id: widget.schedule.id,
      assetId: widget.schedule.assetId,
      assetName: widget.schedule.assetName,
      type: _selectedType,
      frequency: _selectedFrequency,
      scheduledTime: _selectedDateTime,
      recipientEmail: _selectedType != NotificationType.push ? _emailController.text.trim() : null,
      recipientPhone: _selectedType != NotificationType.email ? _phoneController.text.trim() : null,
      isActive: _isActive,
      createdAt: widget.schedule.createdAt,
      lastSent: widget.schedule.lastSent,
    );

    final notificationService = NotificationService();
    await notificationService.updateNotificationSchedule(updatedSchedule);

    if (mounted) {
      widget.onUpdate();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Notification updated successfully"), backgroundColor: Colors.green),
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _handleDelete() {
    _deleteNotification();
  }

  Future<void> _deleteNotification() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Notification"),
        content: const Text("Are you sure you want to delete this notification?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final notificationService = NotificationService();
      await notificationService.deleteNotificationSchedule(widget.schedule.id);
      widget.onUpdate();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Notification deleted"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.white,
        child: Column(
          children: [
            GoldAppBar(
              title: "Edit Notification",
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile(
                        title: const Text("Active", style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text("Enable or disable this notification"),
                        value: _isActive,
                        onChanged: (value) => setState(() => _isActive = value),
                        activeColor: AppColors.primaryGold,
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        "Notification Type",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryGold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: NotificationType.values.map((type) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: FilterChip(
                                label: Text(type.toString().split('.').last.toUpperCase()),
                                selected: _selectedType == type,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) _selectedType = type;
                                  });
                                },
                                selectedColor: AppColors.primaryGoldMedium,
                                checkmarkColor: AppColors.primaryGold,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      if (_selectedType != NotificationType.push) ...[
                        GoldFormField(
                          controller: _emailController,
                          label: "Recipient Email",
                          hint: "Enter email address",
                          prefixIcon: Icons.email,
                          isRequired: true,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Please enter recipient email";
                            }
                            if (!value.contains('@')) {
                              return "Please enter a valid email";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (_selectedType != NotificationType.email) ...[
                        GoldFormField(
                          controller: _phoneController,
                          label: "Recipient Phone",
                          hint: "Enter phone number",
                          prefixIcon: Icons.phone,
                          isRequired: true,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Please enter recipient phone number";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      const Text(
                        "Notification Frequency",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryGold),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<NotificationFrequency>(
                        value: _selectedFrequency,
                        items: NotificationFrequency.values.map((freq) {
                          return DropdownMenuItem(
                            value: freq,
                            child: Text(freq.displayName),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedFrequency = value!),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        "Schedule Date & Time",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryGold),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _selectDateTime,
                        child: GoldCard(
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, color: AppColors.primaryGold),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Select Date & Time", style: TextStyle(fontSize: 12, color: AppColors.black54)),
                                    Text(
                                      "${_selectedDateTime.toLocal().toString().split('.').first}",
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.primaryGold),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      GoldButton(
                        text: _isLoading ? "Updating..." : "Update Notification",
                        icon: Icons.save,
                        onPressed: _isLoading ? null : _handleUpdate,
                      ),
                      const SizedBox(height: 16),

                      GoldButton(
                        text: "Delete Notification",
                        icon: Icons.delete,
                        onPressed: _handleDelete,
                        isPrimary: false,
                        isOutlined: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// ==================== ADD NOTIFICATION DIALOG ====================
class AddNotificationDialog extends StatefulWidget {
  final Asset asset;
  final Function(NotificationSchedule) onSave;

  const AddNotificationDialog({
    super.key,
    required this.asset,
    required this.onSave,
  });

  @override
  State<AddNotificationDialog> createState() => _AddNotificationDialogState();
}

class _AddNotificationDialogState extends State<AddNotificationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  NotificationType _selectedType = NotificationType.email;
  NotificationFrequency _selectedFrequency = NotificationFrequency.once;
  DateTime _selectedDateTime = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: _selectedTime,
      );

      if (time != null && mounted) {
        setState(() {
          _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
          _selectedTime = time;
        });
      }
    }
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      _saveNotification();
    }
  }

  Future<void> _saveNotification() async {
    setState(() => _isLoading = true);

    final schedule = NotificationSchedule(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      assetId: widget.asset.key ?? "",
      assetName: widget.asset.description,
      type: _selectedType,
      frequency: _selectedFrequency,
      scheduledTime: _selectedDateTime,
      recipientEmail: _selectedType != NotificationType.push ? _emailController.text.trim() : null,
      recipientPhone: _selectedType != NotificationType.email ? _phoneController.text.trim() : null,
      isActive: true,
      createdAt: DateTime.now(),
    );

    await widget.onSave(schedule);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Notification scheduled successfully"), backgroundColor: Colors.green),
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.white,
        child: Column(
          children: [
            GoldAppBar(
              title: "Schedule Notification",
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GoldCard(
                        child: Row(
                          children: [
                            Icon(AssetType.getIcon(widget.asset.type), color: AppColors.primaryGold),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Asset", style: TextStyle(fontSize: 12, color: AppColors.primaryGold)),
                                  Text(widget.asset.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        "Notification Type",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryGold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: NotificationType.values.map((type) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: FilterChip(
                                label: Text(type.toString().split('.').last.toUpperCase()),
                                selected: _selectedType == type,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) _selectedType = type;
                                  });
                                },
                                selectedColor: AppColors.primaryGoldMedium,
                                checkmarkColor: AppColors.primaryGold,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      if (_selectedType != NotificationType.push) ...[
                        GoldFormField(
                          controller: _emailController,
                          label: "Recipient Email",
                          hint: "Enter email address",
                          prefixIcon: Icons.email,
                          isRequired: true,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Please enter recipient email";
                            }
                            if (!value.contains('@')) {
                              return "Please enter a valid email";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (_selectedType != NotificationType.email) ...[
                        GoldFormField(
                          controller: _phoneController,
                          label: "Recipient Phone",
                          hint: "Enter phone number",
                          prefixIcon: Icons.phone,
                          isRequired: true,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Please enter recipient phone number";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      const Text(
                        "Notification Frequency",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryGold),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<NotificationFrequency>(
                        value: _selectedFrequency,
                        items: NotificationFrequency.values.map((freq) {
                          return DropdownMenuItem(
                            value: freq,
                            child: Text(freq.displayName),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedFrequency = value!),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        "Schedule Date & Time",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryGold),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _selectDateTime,
                        child: GoldCard(
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, color: AppColors.primaryGold),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Select Date & Time", style: TextStyle(fontSize: 12, color: AppColors.black54)),
                                    Text(
                                      "${_selectedDateTime.toLocal().toString().split('.').first}",
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.primaryGold),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      GoldButton(
                        text: _isLoading ? "Scheduling..." : "Schedule Notification",
                        icon: Icons.notifications_active,
                        onPressed: _isLoading ? null : _handleSave,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

