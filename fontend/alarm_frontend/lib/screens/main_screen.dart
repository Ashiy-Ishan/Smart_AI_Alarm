import 'package:flutter/material.dart';
import '../components/bottom_nav_bar.dart';
import 'home_screen.dart';
import 'schedule_screen.dart';
import 'hub_screen.dart';
import 'insight_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final List<Widget> screens = const [
    HomeScreen(),
    ScheduleScreen(),
    HubScreen(),
    InsightScreen(),
    ProfileScreen(),
  ];

  void onTabTapped(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  void openScreen(Widget screen) {
    navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Navigator(
        key: navigatorKey,
        onGenerateRoute: (settings) {
          return MaterialPageRoute(builder: (_) => screens[currentIndex]);
        },
      ),

      bottomNavigationBar: BottomNavBar(
        currentIndex: currentIndex,
        onTap: onTabTapped,
      ),
    );
  }
}
