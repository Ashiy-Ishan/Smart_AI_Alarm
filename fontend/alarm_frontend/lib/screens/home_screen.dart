import 'package:alarm_frontend/providers/user_provider.dart';
import 'package:alarm_frontend/routes/app_routes.dart';
import 'package:alarm_frontend/services/weather_service.dart';
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
  String temperature = "--°F";
  String weatherMain = "Loading...";
  final WeatherService _weatherService = WeatherService();

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    final weatherData = await _weatherService.fetchWeather();
    if (weatherData != null && mounted) {
      setState(() {
        double temp = weatherData['main']['temp'].toDouble();
        temperature = "${temp.round()}°F";
        weatherMain = weatherData['weather'][0]['main'];
      });
    }
  }

  (String greeting, String secondary, String asset) _getTimeBasedData() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return ("Good Morning", "Have a great morning", "assets/lotties/morning.json");
    } else if (hour >= 12 && hour < 17) {
      return ("Good Afternoon", "Have a productive afternoon", "assets/lotties/day.json");
    } else if (hour >= 17 && hour < 21) {
      return ("Good Evening", "Enjoy your evening", "assets/lotties/night.json");
    } else {
      return ("Good Night", "Get some good rest", "assets/lotties/night.json");
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final String fullName = userProvider.user?.fullName ?? "";
    final String firstName = fullName.isNotEmpty ? fullName.split(' ').first : "User";
    
    final (greeting, secondaryGreeting, lottieAsset) = _getTimeBasedData();

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
                const SizedBox(height: 10),
                
                // Header: Greeting & Notifications
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "$greeting,\n$firstName",
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 26,
                        height: 1.2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _loadWeather,
                          icon: const Icon(Icons.refresh, color: AppColors.primary),
                        ),
                        _buildNotificationIcon(),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),

                // Lottie Animation & Weather Section
                _buildWeatherSection(lottieAsset, secondaryGreeting, firstName),

                const SizedBox(height: 30),

                // Featured Sections
                _buildNextEventCard(),
                const SizedBox(height: 20),
                _buildAlarmCard(),
                const SizedBox(height: 20),
                _buildSummaryCard(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(8),
      child: const Icon(
        Icons.notifications_none,
        color: AppColors.primary,
        size: 30,
      ),
    );
  }

  Widget _buildWeatherSection(String asset, String secondaryGreeting, String name) {
    return Column(
      children: [
        Center(
          child: SizedBox(
            height: 150,
            child: Lottie.asset(
              asset,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Lottie.asset('assets/lotties/home.json'),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "$secondaryGreeting,\n$name",
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  temperature,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  weatherMain,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNextEventCard() {
    return Container(
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
              Icon(Icons.calendar_today, size: 22, color: AppColors.primary),
              SizedBox(width: 8),
              Text("9:30 AM", style: TextStyle(color: AppColors.textPrimary, fontSize: 17)),
              SizedBox(width: 10),
              Text("•", style: TextStyle(color: AppColors.textSecondary, fontSize: 17)),
              SizedBox(width: 10),
              Text("Product Sync", style: TextStyle(color: AppColors.textPrimary, fontSize: 17)),
            ],
          ),
          SizedBox(height: 6),
          Text(
            "Tue, Nov 12 • 1hr 15m left",
            style: TextStyle(color: AppColors.primaryDark, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmCard() {
    return Container(
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
              Text("Alarm", style: TextStyle(color: AppColors.textPrimary, fontSize: 20)),
              SizedBox(height: 2),
              Text(
                "7:00 AM",
                style: TextStyle(color: AppColors.textPrimary, fontSize: 25, fontWeight: FontWeight.bold),
              ),
              Text("Mon - Fri", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          Switch(
            value: isAlarmOn,
            activeThumbColor: AppColors.primary,
            onChanged: (val) => setState(() => isAlarmOn = val),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, AppRoutes.todaySummary),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's Summary",
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 20),
                ),
                Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 18),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Text("8h Sleep", style: TextStyle(color: AppColors.textPrimary)),
                SizedBox(width: 30),
                Text("|", style: TextStyle(color: AppColors.textSecondary)),
                SizedBox(width: 30),
                Text("1 Active Event", style: TextStyle(color: AppColors.textPrimary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
