// lib/main_pages/access_requests.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AccessRequestsPage extends StatefulWidget {
  @override
  _AccessRequestsPageState createState() => _AccessRequestsPageState();
}

class _AccessRequestsPageState extends State<AccessRequestsPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("accessRequests");
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  String? _getCurrentUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  Future<void> _loadRequests() async {
    final userId = _getCurrentUserId();
    if (userId == null) return;

    setState(() => _isLoading = true);
    
    final snapshot = await _dbRef
        .orderByChild("userId")
        .equalTo(userId)
        .get();
    
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        _requests = data.entries.map((entry) => {
          "key": entry.key,
          "requesterName": entry.value["requesterName"] ?? "",
          "requesterEmail": entry.value["requesterEmail"] ?? "",
          "relationship": entry.value["relationship"] ?? "",
          "status": entry.value["status"] ?? "pending",
          "requestedAt": entry.value["requestedAt"] ?? "",
          "message": entry.value["message"] ?? "",
        }).toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateRequestStatus(String key, String status) async {
    await _dbRef.child(key).update({
      "status": status,
      "respondedAt": DateTime.now().toIso8601String(),
    });
    _loadRequests();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Request $status"), backgroundColor: status == "approved" ? Colors.green : Colors.orange),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Access Requests"),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(40),
          child: Container(
            padding: EdgeInsets.all(8),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "These are requests from your trusted contacts to view your dossier.",
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
          : _requests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text("No access requests", style: TextStyle(fontSize: 18)),
                      SizedBox(height: 8),
                      Text("When someone requests access, you'll see it here"),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _requests.length,
                  itemBuilder: (context, index) {
                    final request = _requests[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 2,
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(request["status"]).withOpacity(0.2),
                          child: Icon(Icons.person, color: _getStatusColor(request["status"])),
                        ),
                        title: Text(request["requesterName"], style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Requested: ${_formatDate(request["requestedAt"])}"),
                        trailing: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(request["status"]).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            request["status"].toUpperCase(),
                            style: TextStyle(color: _getStatusColor(request["status"]), fontSize: 11),
                          ),
                        ),
                        children: [
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Email: ${request["requesterEmail"]}"),
                                SizedBox(height: 8),
                                Text("Relationship: ${request["relationship"] ?? "Not specified"}"),
                                if (request["message"] != null && request["message"].isNotEmpty) ...[
                                  SizedBox(height: 8),
                                  Text("Message: ${request["message"]}", style: TextStyle(fontStyle: FontStyle.italic)),
                                ],
                                SizedBox(height: 16),
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "⚠️ Note: Approving this request will give them READ-ONLY access to your stored information for 7 days. They will NOT have access to your login or ability to modify anything.",
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ),
                                SizedBox(height: 16),
                                if (request["status"] == "pending")
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => _updateRequestStatus(request["key"], "approved"),
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                          child: Text("Approve"),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => _updateRequestStatus(request["key"], "rejected"),
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                          child: Text("Reject"),
                                        ),
                                      ),
                                    ],
                                  ),
                                if (request["status"] == "approved")
                                  Text(
                                    "✓ Approved - This contact can now view your dossier",
                                    style: TextStyle(color: Colors.green),
                                  ),
                                if (request["status"] == "rejected")
                                  Text(
                                    "✗ Rejected - This request has been denied",
                                    style: TextStyle(color: Colors.red),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}