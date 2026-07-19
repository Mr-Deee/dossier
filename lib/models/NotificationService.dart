// ==================== NOTIFICATION MODEL ====================
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

enum NotificationType { email, push, both }
enum NotificationFrequency { once, daily, weekly, monthly, quarterly, yearly }
// Helper function for type conversion
Map<String, dynamic> _safeCast(Map<dynamic, dynamic> data) {
  return Map<String, dynamic>.fromEntries(
      data.entries.map((entry) => MapEntry(entry.key.toString(), entry.value))
  );
}

extension NotificationFrequencyExtension on NotificationFrequency {
  String get displayName {
    switch (this) {
      case NotificationFrequency.once: return "Once";
      case NotificationFrequency.daily: return "Daily";
      case NotificationFrequency.weekly: return "Weekly";
      case NotificationFrequency.monthly: return "Monthly";
      case NotificationFrequency.quarterly: return "Quarterly";
      case NotificationFrequency.yearly: return "Yearly";
    }
  }
}

class NotificationSchedule {
  final String id;
  final String assetId;
  final String assetName;
  final NotificationType type;
  final NotificationFrequency frequency;
  final DateTime scheduledTime;
  final String? recipientEmail;
  final String? recipientPhone;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastSent;

  NotificationSchedule({
    required this.id,
    required this.assetId,
    required this.assetName,
    required this.type,
    required this.frequency,
    required this.scheduledTime,
    this.recipientEmail,
    this.recipientPhone,
    required this.isActive,
    required this.createdAt,
    this.lastSent,
  });

  factory NotificationSchedule.fromJson(Map<String, dynamic> json, String id) {
    return NotificationSchedule(
      id: id,
      assetId: json["assetId"]?.toString() ?? "",
      assetName: json["assetName"]?.toString() ?? "",
      type: NotificationType.values.firstWhere(
            (e) => e.toString() == json["type"],
        orElse: () => NotificationType.email,
      ),
      frequency: NotificationFrequency.values.firstWhere(
            (e) => e.toString() == json["frequency"],
        orElse: () => NotificationFrequency.once,
      ),
      scheduledTime: DateTime.parse(json["scheduledTime"]?.toString() ?? DateTime.now().toIso8601String()),
      recipientEmail: json["recipientEmail"]?.toString(),
      recipientPhone: json["recipientPhone"]?.toString(),
      isActive: json["isActive"] == true,
      createdAt: DateTime.parse(json["createdAt"]?.toString() ?? DateTime.now().toIso8601String()),
      lastSent: json["lastSent"] != null ? DateTime.parse(json["lastSent"]) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "assetId": assetId,
    "assetName": assetName,
    "type": type.toString(),
    "frequency": frequency.toString(),
    "scheduledTime": scheduledTime.toIso8601String(),
    "recipientEmail": recipientEmail,
    "recipientPhone": recipientPhone,
    "isActive": isActive,
    "createdAt": createdAt.toIso8601String(),
    "lastSent": lastSent?.toIso8601String(),
  };
}

// ==================== NOTIFICATION SERVICE ====================
class NotificationService {
  final DatabaseReference _notificationsRef = FirebaseDatabase.instance.ref("notificationSchedules");

  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  Future<List<NotificationSchedule>> getNotificationSchedules() async {
    if (_currentUserId == null) return [];

    try {
      final snapshot = await _notificationsRef.child(_currentUserId!).get();
      if (!snapshot.exists) return [];

      final data = snapshot.value as Map<dynamic, dynamic>;
      return data.entries.map((entry) =>
          NotificationSchedule.fromJson(_safeCast(entry.value), entry.key.toString())
      ).toList();
    } catch (e) {
      print("Error loading notifications: $e");
      return [];
    }
  }

  Future<void> scheduleNotification(NotificationSchedule schedule) async {
    if (_currentUserId == null) return;
    final notificationRef = _notificationsRef.child(_currentUserId!).child(schedule.id);
    await notificationRef.set(schedule.toJson());
  }

  Future<void> updateNotificationSchedule(NotificationSchedule schedule) async {
    if (_currentUserId == null) return;
    await _notificationsRef.child(_currentUserId!).child(schedule.id).update(schedule.toJson());
  }

  Future<void> deleteNotificationSchedule(String id) async {
    if (_currentUserId == null) return;
    await _notificationsRef.child(_currentUserId!).child(id).remove();
  }
}
