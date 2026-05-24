import 'package:alarm_frontend/providers/user_provider.dart';
import 'package:alarm_frontend/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isAlarmOn = true;

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final String fullName = userProvider.user?.fullName ?? "";
    final String firstName = fullName.isNotEmpty ? fullName.split(' ').first : "Alex";

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Good Morning,\n$firstName",
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Icon(
                      Icons.notifications_none,
                      color: AppColors.primary,
                      size: 40,
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Stack(
                  children: [
                    Container(
                      height: 270,
                      decoration: BoxDecoration(color: AppColors.background),
                    ),

                    /// Lottie Animation
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Lottie.asset(
                          "assets/lotties/home.json",
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    /// Weather Info (RIGHT)
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: const [
                          Text(
                            "72°F",
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Sunny",
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// Greeting Overlay (LEFT)
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Text(
                        "Greeting,\nmorning, $firstName",
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Next Event",
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 22,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "9:30 AM",
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 17,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            "•",
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 17,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Product Sync",
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      Text(
                        "Tue, Nov 12 • 1hr 15m left",
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Alarm",
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "7:00 AM",
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Mon - Fri",
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: isAlarmOn,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) {
                          setState(() => isAlarmOn = val);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// Today Summary Navigation
                InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.todaySummary);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Today's Summary",
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: AppColors.textSecondary,
                              size: 18,
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              "8h Sleep",
                              style: TextStyle(color: AppColors.textPrimary),
                            ),
                            SizedBox(width: 30),
                            Text(
                              "|",
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            SizedBox(width: 30),
                            Text(
                              "1 Active Event",
                              style: TextStyle(color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
