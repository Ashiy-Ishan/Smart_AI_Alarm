import 'package:alarm_frontend/components/event_card.dart';
import 'package:alarm_frontend/models/event_model.dart';
import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:alarm_frontend/services/api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TodaySummaryScreen extends StatefulWidget {
  const TodaySummaryScreen({super.key});

  @override
  State<TodaySummaryScreen> createState() => _TodaySummaryScreenState();
}

class _TodaySummaryScreenState extends State<TodaySummaryScreen> {
  Map<String, dynamic>? _sensorData;
  bool _isLoadingSensor = true;
  String? _sensorError;
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
  void initState() {
    super.initState();
    _loadSensorSummary();
  }

  Future<void> _loadSensorSummary() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('User is not logged in');
      }

      final response = await ApiService.get('/iot/sensor/${user.uid}/latest');

      if (!mounted) return;

      setState(() {
        if (response != null) {
          _sensorData = Map<String, dynamic>.from(response);
        }

        _sensorError = null;
        _isLoadingSensor = false;
      });
    } catch (e) {
      debugPrint('Today summary backend error: $e');

      if (!mounted) return;

      setState(() {
        _sensorError = 'Unable to load sensor summary';
        _isLoadingSensor = false;
      });
    }
  }

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
                    child: _isLoadingSensor
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          )
                        : _sensorError != null
                        ? Text(
                            _sensorError!,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Icon(
                                    Icons.thermostat,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '${_sensorData?['temperature'] ?? '--'}°C',
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    'Temperature',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),

                              Column(
                                children: [
                                  const Icon(
                                    Icons.water_drop_outlined,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '${_sensorData?['humidity'] ?? '--'}%',
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    'Humidity',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),

                              Column(
                                children: [
                                  const Icon(
                                    Icons.directions_walk,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    _sensorData?['motion'] == 1 ||
                                            _sensorData?['motion'] == true
                                        ? 'Detected'
                                        : 'Still',
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    'Motion',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
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
