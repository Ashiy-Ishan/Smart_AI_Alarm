import 'package:alarm_frontend/screens/home_screen.dart';
import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:flutter/material.dart';

class TodaySummaryScreen extends StatefulWidget {
  const TodaySummaryScreen({super.key});

  @override
  State<TodaySummaryScreen> createState() => _TodaySummaryScreenState();
}

class _TodaySummaryScreenState extends State<TodaySummaryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (_, _, _) =>
                                  const HomeScreen(),
                              transitionDuration: Duration.zero,
                              reverseTransitionDuration: Duration.zero,
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Today’s Summary",
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const Divider(color: AppColors.border),

                  const SizedBox(height: 20),

                  const Text(
                    "Today’s Events",
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  _eventCard(
                    time: "9:30 AM",
                    title: "Product Sync",
                    extra: "115m left",
                    highlight: true,
                  ),

                  const SizedBox(height: 12),

                  _eventCard(
                    time: "2:00 PM",
                    title: "Client Call",
                    rightTime: "2:00 PM",
                  ),

                  const SizedBox(height: 20),

                  const Divider(color: AppColors.border),

                  const SizedBox(height: 20),

                  const Text(
                    "Activity Summary",
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,

                      children: const [
                        Column(
                          children: [
                            Icon(
                              Icons.directions_walk,
                              color: AppColors.primary,
                            ),
                            SizedBox(height: 5),
                            Text(
                              "4,867",
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Steps",
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),

                        Column(
                          children: [
                            Text(
                              "37 min",
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Movement",
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),

                        Column(
                          children: [
                            Text(
                              "230",
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Cal",
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Divider(color: AppColors.border),

                  const SizedBox(height: 20),

                  const Text(
                    "Health Insights",
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Container(height: 4, width: 40, color: AppColors.primary),

                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      "Sleep quality improved today",
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _eventCard({
  required String time,
  required String title,
  String? extra,
  String? rightTime,
  bool highlight = false,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        /// Left Highlight Bar
        Container(
          width: 5,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),

        const SizedBox(width: 10),

        /// Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$time • $title",
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),

              if (extra != null)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    extra,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),

        if (rightTime != null)
          Text(
            rightTime,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
      ],
    ),
  );
}
