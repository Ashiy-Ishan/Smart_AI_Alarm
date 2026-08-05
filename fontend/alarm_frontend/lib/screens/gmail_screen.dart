import 'package:alarm_frontend/services/google_sync_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:alarm_frontend/utils/app_text_styles.dart';
import 'package:alarm_frontend/components/sync_status_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:googleapis/gmail/v1.dart';

class GmailScreen extends StatefulWidget {
  const GmailScreen({super.key});

  @override
  State<GmailScreen> createState() => _GmailScreenState();
}

class _GmailScreenState extends State<GmailScreen> {
  final GoogleSyncService _syncService = GoogleSyncService();
  List<Message> _emails = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEmails();
  }

  Future<void> _fetchEmails() async {
    setState(() => _isLoading = true);
    final emails = await _syncService.fetchLatestEmails();
    if (mounted) {
      setState(() {
        _emails = emails;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? 'Unknown User';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Gmail', style: AppTextStyles.heading),
              Text(userEmail, style: AppTextStyles.subHeading),
            ],
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _fetchEmails,
          color: AppColors.primary,
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  SyncStatusCard(
                    statusText: 'Synced ${_emails.length} unread emails',
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Recent Unread Messages',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  if (_emails.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: Text("No unread emails found.", style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    )
                  else
                    ..._emails.map((msg) => _buildEmailTile(msg)).toList(),
                ],
              ),
        ),
      ),
    );
  }

  Widget _buildEmailTile(Message msg) {
    // Basic extraction of Subject and From from headers
    String subject = "No Subject";
    String from = "Unknown";
    
    if (msg.payload?.headers != null) {
      for (var header in msg.payload!.headers!) {
        if (header.name == 'Subject') subject = header.value ?? subject;
        if (header.name == 'From') from = header.value ?? from;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(from, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          Text(subject, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(msg.snippet ?? "", style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
