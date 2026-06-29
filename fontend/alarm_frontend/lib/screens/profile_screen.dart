import 'package:alarm_frontend/models/auth_model_user.dart';
import 'package:alarm_frontend/models/section_card.dart';
import 'package:alarm_frontend/providers/user_provider.dart';
import 'package:alarm_frontend/routes/app_routes.dart';
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
                    _tile(context, "Calendar", Icons.calendar_today, AppRoutes.calendar),
                    _tile(context, "Gmail", Icons.mail, AppRoutes.gmail),
                    _tile(context, "Message", Icons.message, AppRoutes.message),
                  ],
                ),

                const SizedBox(height: 16),

                SectionCard(
                  title: "Data Privacy",
                  children: [
                    _tile(context, "Data Encryption", Icons.lock, AppRoutes.dataEncryption),
                    _tile(context, "Clear History", Icons.history, AppRoutes.clearHistory),
                    _tile(context, "Delete Account", Icons.delete, AppRoutes.deleteAccount),
                  ],
                ),

                const SizedBox(height: 16),

                SectionCard(
                  children: [
                    _tile(context, "Feedback", Icons.warning_amber, AppRoutes.feedback),
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
}

Widget _tile(
  BuildContext context,
  String title,
  IconData icon,
  String? route,
) {
  return ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: AppColors.primary),
    title: Text(
      title,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
    ),
    trailing: const Icon(
      Icons.arrow_forward_ios,
      size: 16,
      color: AppColors.textSecondary,
    ),
    onTap: route == null
        ? null
        : () => Navigator.pushNamed(context, route),
  );
}
