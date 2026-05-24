import 'package:alarm_frontend/components/event_card.dart';
import 'package:alarm_frontend/models/event_model.dart';
import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:flutter/material.dart';

class TodaySummaryScreen extends StatefulWidget {
  const TodaySummaryScreen({super.key});

  @override
  State<TodaySummaryScreen> createState() => _TodaySummaryScreenState();
}

class _TodaySummaryScreenState extends State<TodaySummaryScreen> {
  final List<EventModel> events = const [
    EventModel(
      time: "9:30 AM",
      title: "Product Sync",
      extra: "115m left",
      highlight: true,
    ),
    EventModel(time: "2:00 PM", title: "Client Call", rightTime: "2:00 PM"),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          "Today’s Summary",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: AppColors.border),

                  const SizedBox(height: 40),

                  const Text(
                    "Today’s Events",
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      return EventCard(event: events[index]);
                    },
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
