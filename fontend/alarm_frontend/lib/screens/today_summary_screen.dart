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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.textTheme.bodyLarge?.color),
        title: const Text(
          "Today’s Summary",
          style: TextStyle(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(color: theme.dividerColor),

                const SizedBox(height: 40),

                const Text(
                  "Today’s Events",
                  style: TextStyle(
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

                Divider(color: theme.dividerColor),

                const SizedBox(height: 20),

                const Text(
                  "Activity Summary",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Icon(
                            Icons.directions_walk,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            "4,867",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Steps",
                            style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ?? AppColors.textSecondary),
                          ),
                        ],
                      ),

                      Column(
                        children: [
                          const Text(
                            "37 min",
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Movement",
                            style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ?? AppColors.textSecondary),
                          ),
                        ],
                      ),

                      Column(
                        children: [
                          const Text(
                            "230",
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Cal",
                            style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ?? AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Divider(color: theme.dividerColor),

                const SizedBox(height: 20),

                const Text(
                  "Health Insights",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Container(height: 4, width: 40, color: AppColors.primary),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text(
                    "Sleep quality improved today",
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
