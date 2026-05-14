// lib/main_pages/contact_us.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' show launchUrl;

class ContactUsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Contact Us")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Icon(Icons.support_agent, size: 80, color: Colors.amber),
            ),
            SizedBox(height: 24),
            Text(
              "Get in Touch",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "Have questions about DOSSIER? Need help with access requests? Contact our support team.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 32),
            _buildContactCard(
              icon: Icons.email,
              title: "Email Support",
              detail: "support@dossierapp.com",
              onTap: () => _launchEmail("support@dossierapp.com"),
            ),
            SizedBox(height: 16),
            _buildContactCard(
              icon: Icons.phone,
              title: "Phone Support",
              detail: "+233 (0) 30 000 0000",
              onTap: () => _launchPhone("+233300000000"),
            ),
            SizedBox(height: 16),
            _buildContactCard(
              icon: Icons.web,
              title: "Website",
              detail: "www.dossierapp.com",
              onTap: () => _launchUrl("https://www.dossierapp.com"),
            ),
            SizedBox(height: 32),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "📌 For Access Requests",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "If you are requesting access to a deceased person's dossier, please email support with:\n\n"
                    "• Your full name\n"
                    "• Relationship to the deceased\n"
                    "• Death certificate (attachment)\n\n"
                    "We will verify and respond within 7 business days.",
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String detail,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.amber.shade100,
                child: Icon(icon, color: Colors.amber.shade900),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(detail, style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // FIXED: Using correct url_launcher methods
  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: email);
    if (await launchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      throw 'Could not launch $emailUri';
    }
  }

  Future<void> _launchPhone(String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    if (await launchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      throw 'Could not launch $phoneUri';
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await launchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }
}