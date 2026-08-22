import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_text_styles.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.textTheme.bodyLarge?.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Terms & Conditions', style: AppTextStyles.heading),
        titleSpacing: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Privacy Policy & Data Usage",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Last Updated: June 2026",
              style: TextStyle(
                fontSize: 12,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            
            _buildSection(
              context,
              "1. Information We Collect",
              "We collect information to provide a better experience and enable smart features:\n\n"
              "• Account Data: Your email, full name, and profile picture (via Firebase Auth).\n"
              "• Device Data: Hardware MAC addresses and system status of your connected Bedside Hub.\n"
              "• Sensor Data: Real-time temperature, humidity, light levels, and motion detection logs from your IoT devices."
            ),
            
            _buildSection(
              context,
              "2. Google Services Integration",
              "If you choose to link your Google Account, we request read-only access to:\n\n"
              "• Google Calendar: To sync your upcoming events and optimize alarm times.\n"
              "• Gmail: To scan for unread messages and provide morning briefings.\n\n"
              "We do not store your emails or calendar events on our servers; they are processed locally on your device."
            ),
            
            _buildSection(
              context,
              "3. Location Data",
              "The app requests access to your GPS location solely to provide accurate local weather updates. This data is not shared with third parties or stored in our database."
            ),
            
            _buildSection(
              context,
              "4. Data Security",
              "Your privacy is our priority. Sensitive motion logs and personal activity records are protected using industry-standard encryption. You can clear your history or delete your account at any time from the Profile settings."
            ),
            
            _buildSection(
              context,
              "5. User Consent",
              "By using the Smart AI Alarm, you agree to the collection and use of information in accordance with this policy. We do not sell your personal data."
            ),
            
            const SizedBox(height: 40),
            Center(
              child: Text(
                "© 2026 Smart AI Alarm. All rights reserved.",
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
