import 'package:alarm_frontend/models/auth_model_user.dart';
import 'package:alarm_frontend/models/section_card.dart';
import 'package:alarm_frontend/providers/user_provider.dart';
import 'package:alarm_frontend/screens/calendar_screen.dart';
import 'package:alarm_frontend/screens/clear_history_screen.dart';
import 'package:alarm_frontend/screens/data_encryption_screen.dart';
import 'package:alarm_frontend/screens/delete_account_screen.dart';
import 'package:alarm_frontend/screens/feedback_screen.dart';
import 'package:alarm_frontend/screens/gmail_screen.dart';
import 'package:alarm_frontend/screens/message_screen.dart';
import 'package:alarm_frontend/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  final AuthUserModel user;
  const ProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
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
                  backgroundImage: user.profileImage.isNotEmpty
                      ? NetworkImage(user.profileImage)
                      : null,
                  child: user.profileImage.isEmpty
                      ? const Icon(Icons.person, size: 40)
                      : null,
                ),

                const SizedBox(height: 10),

                Text(
                  user.fullName.isEmpty ? "User Name" : user.fullName,
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
                    _tile(
                      context,
                      "Calendar",
                      Icons.calendar_today,
                      const CalendarScreen(),
                    ),
                    _tile(context, "Gmail", Icons.mail, const GmailScreen()),
                    _tile(
                      context,
                      "Message",
                      Icons.message,
                      const MessageScreen(),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                SectionCard(
                  title: "Data Privacy",
                  children: [
                    _tile(
                      context,
                      "Data Encryption",
                      Icons.lock,
                      const DataEncryptionScreen(),
                    ),
                    _tile(
                      context,
                      "Clear History",
                      Icons.history,
                      const ClearHistoryScreen(),
                    ),
                    _tile(
                      context,
                      "Delete Account",
                      Icons.delete,
                      const DeleteAccountScreen(),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                SectionCard(
                  children: [
                    _tile(
                      context,
                      "Feedback",
                      Icons.warning_amber,
                      const FeedbackScreen(),
                    ),
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
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SplashScreen(),
                              ),
                              (route) => false,
                            );
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
  Widget? screen,
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
    onTap: screen == null
        ? null
        : () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>  screen,
              ),
            );
          },
  );
}
