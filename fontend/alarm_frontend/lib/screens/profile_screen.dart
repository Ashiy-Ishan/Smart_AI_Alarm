import 'package:alarm_frontend/models/auth_model_user.dart';
import 'package:alarm_frontend/models/section_card.dart';
import 'package:alarm_frontend/providers/user_provider.dart';
import 'package:alarm_frontend/providers/theme_provider.dart';
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

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _isGoogleLinked = false;
  bool _isLoadingStatus = true;

  @override
  void initState() {
    super.initState();
    _refreshLinkStatus();
  }

  // check true status from google service
  Future<void> _refreshLinkStatus() async {
    if (!mounted) return;
    setState(() => _isLoadingStatus = true);

    final linked = await GoogleSyncService().isLinked();

    if (mounted) {
      setState(() {
        _isGoogleLinked = linked;
        _isLoadingStatus = false;
      });
    }
  }

  // handle switch toggle
  void _handleToggleLink(bool value) async {
    if (value) {
      // linking flow
      final account = await GoogleSyncService().linkAccount();
      if (account != null && mounted) {
        setState(() => _isGoogleLinked = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Google Account Linked Successfully!")),
        );
      } else if (mounted) {
        setState(() => _isGoogleLinked = false);
      }
    } else {
      // unlinking flow with confirmation
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: const Text("Unlink Google?"),
          content: const Text("Gmail and Calendar sync will be disabled."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                "Unlink",
                style: TextStyle(color: Colors.redAccent),
              ),
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
      } else if (mounted) {
        // revert switch if canceled
        setState(() => _isGoogleLinked = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
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
                  widget.user.fullName.isEmpty
                      ? "User Name"
                      : widget.user.fullName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 25),

                // Appearance
                SectionCard(
                  title: "Appearance",
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        themeProvider.isDarkMode
                            ? Icons.dark_mode
                            : Icons.light_mode,
                        color: AppColors.primary,
                      ),
                      title: const Text(
                        "Dark Mode",
                        style: TextStyle(fontSize: 15),
                      ),
                      trailing: Switch(
                        value: themeProvider.isDarkMode,
                        onChanged: (v) => themeProvider.toggleTheme(),
                        activeThumbColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Account Linking
                SectionCard(
                  title: "Account Linking",
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.link, color: AppColors.primary),
                      title: const Text(
                        "Google Services",
                        style: TextStyle(fontSize: 15),
                      ),
                      subtitle: Text(
                        _isLoadingStatus
                            ? "Checking..."
                            : (_isGoogleLinked
                                  ? "Sync Active"
                                  : "Link for AI Insights"),
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: _isLoadingStatus
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                          : Switch(
                              value: _isGoogleLinked,
                              onChanged: _handleToggleLink,
                              activeThumbColor: AppColors.primary,
                            ),
                    ),
                    _tile(
                      context,
                      "Calendar",
                      Icons.calendar_today,
                      AppRoutes.calendar,
                      _isGoogleLinked,
                    ),
                    _tile(
                      context,
                      "Gmail",
                      Icons.mail,
                      AppRoutes.gmail,
                      _isGoogleLinked,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Privacy & Danger Zone
                SectionCard(
                  title: "Security",
                  children: [
                    _tile(
                      context,
                      "Data Encryption",
                      Icons.lock,
                      AppRoutes.dataEncryption,
                      true,
                    ),
                    _tile(
                      context,
                      "Clear History",
                      Icons.history,
                      AppRoutes.clearHistory,
                      true,
                    ),
                    _tile(
                      context,
                      "Delete Account",
                      Icons.delete,
                      AppRoutes.deleteAccount,
                      true,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                SectionCard(
                  children: [
<<<<<<< HEAD
                    _tile(
                      context,
                      "Feedback",
                      Icons.warning_amber,
                      AppRoutes.feedback,
                      true,
                    ),
=======
                    _tile(context, "Notification Control", Icons.notifications_active_outlined, AppRoutes.notificationControl, true),
                    _tile(context, "Terms & Conditions", Icons.description_outlined, AppRoutes.termsAndConditions, true),
                    _tile(context, "Feedback", Icons.warning_amber, AppRoutes.feedback, true),
>>>>>>> origin/main
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.logout,
                        color: Colors.redAccent,
                      ),
                      title: const Text(
                        "Log Out",
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: Theme.of(context).cardColor,
                            title: const Text("Log Out"),
                            content: const Text("Are you sure?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text(
                                  "Log Out",
                                  style: TextStyle(color: Colors.redAccent),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && context.mounted) {
                          await Provider.of<UserProvider>(
                            context,
                            listen: false,
                          ).signOut(context);
                          if (!context.mounted) return;
                          Navigator.of(
                            context,
                            rootNavigator: true,
                          ).pushNamedAndRemoveUntil(
                            AppRoutes.splash,
                            (route) => false,
                          );
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
    final theme = Theme.of(context);
    final color = isEnabled
        ? theme.textTheme.bodyLarge?.color
        : Colors.grey.shade400;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: isEnabled ? AppColors.primary : Colors.grey.shade400,
      ),
      title: Text(title, style: TextStyle(color: color, fontSize: 15)),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: isEnabled ? AppColors.textSecondary : Colors.grey.shade300,
      ),
      onTap: (route == null || !isEnabled)
          ? null
          : () => Navigator.pushNamed(context, route),
    );
  }
}
