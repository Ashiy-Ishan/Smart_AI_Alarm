import 'package:alarm_frontend/models/auth_model_user.dart';
import 'package:alarm_frontend/models/section_card.dart';
import 'package:alarm_frontend/providers/user_provider.dart';
import 'package:alarm_frontend/routes/app_routes.dart';
import 'package:alarm_frontend/services/google_sync_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  final AuthUserModel user;
  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _isGoogleLinked = false;
  bool _isLoadingStatus = true;

  @override
  void initState() {
    super.initState();
    _checkLinkStatus();
  }

  Future<void> _checkLinkStatus() async {
    final linked = await GoogleSyncService().isLinked();
    if (mounted) {
      setState(() {
        _isGoogleLinked = linked;
        _isLoadingStatus = false;
      });
    }
  }

  void _handleToggleLink(bool value) async {
    if (value) {
      final account = await GoogleSyncService().linkAccount();
      if (account != null && mounted) {
        setState(() => _isGoogleLinked = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Google Account Linked Successfully!")),
        );
      }
    } else {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text("Unlink Google?", style: TextStyle(color: AppColors.textPrimary)),
          content: const Text("This will stop syncing your Gmail and Calendar data.", style: TextStyle(color: AppColors.textSecondary)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Unlink", style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await GoogleSyncService().unlinkAccount();
        if (mounted) {
          setState(() => _isGoogleLinked = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Google Account Unlinked.")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Profile",
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primary,
                  backgroundImage: widget.user.profileImage.isNotEmpty
                      ? NetworkImage(widget.user.profileImage)
                      : null,
                  child: widget.user.profileImage.isEmpty
                      ? const Icon(Icons.person, size: 40)
                      : null,
                ),

                const SizedBox(height: 10),

                Text(
                  widget.user.fullName.isEmpty ? "User Name" : widget.user.fullName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 25),

                SectionCard(
                  title: "Account Linking",
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.link, color: AppColors.primary),
                      title: const Text("Google Services", style: TextStyle(color: AppColors.textPrimary, fontSize: 15)),
                      subtitle: Text(_isLoadingStatus ? "Checking status..." : (_isGoogleLinked ? "Active" : "Not Linked"), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      trailing: _isLoadingStatus 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Switch(
                            value: _isGoogleLinked,
                            onChanged: _handleToggleLink,
                            activeColor: AppColors.primary,
                          ),
                    ),
                    _tile(context, "Calendar", Icons.calendar_today, AppRoutes.calendar, _isGoogleLinked),
                    _tile(context, "Gmail", Icons.mail, AppRoutes.gmail, _isGoogleLinked),
                  ],
                ),

                const SizedBox(height: 16),

                SectionCard(
                  title: "Data Privacy",
                  children: [
                    _tile(context, "Data Encryption", Icons.lock, AppRoutes.dataEncryption, true),
                    _tile(context, "Clear History", Icons.history, AppRoutes.clearHistory, true),
                    _tile(context, "Delete Account", Icons.delete, AppRoutes.deleteAccount, true),
                  ],
                ),

                const SizedBox(height: 16),

                SectionCard(
                  children: [
                    _tile(context, "Feedback", Icons.warning_amber, AppRoutes.feedback, true),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.logout, color: Colors.redAccent),
                      title: const Text(
                        "Log Out",
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.redAccent,
                      ),
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: AppColors.card,
                            title: const Text(
                              "Log Out",
                              style: TextStyle(color: AppColors.textPrimary),
                            ),
                            content: const Text(
                              "Are you sure you want to log out?",
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text(
                                  "Cancel",
                                  style: TextStyle(color: AppColors.textSecondary),
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text(
                                  "Log Out",
                                  style: TextStyle(color: Colors.redAccent),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          if (context.mounted) {
                            await Provider.of<UserProvider>(context, listen: false)
                                .signOut(context);
                            if (!context.mounted) return;
                            Navigator.of(context, rootNavigator: true)
                                .pushNamedAndRemoveUntil(
                                    AppRoutes.splash, (route) => false);
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    String title,
    IconData icon,
    String? route,
    bool isEnabled,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: isEnabled ? AppColors.primary : Colors.grey),
      title: Text(
        title,
        style: TextStyle(color: isEnabled ? AppColors.textPrimary : Colors.grey, fontSize: 15),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: isEnabled ? AppColors.textSecondary : Colors.grey.withOpacity(0.5),
      ),
      onTap: (route == null || !isEnabled)
          ? null
          : () => Navigator.pushNamed(context, route),
    );
  }
}
