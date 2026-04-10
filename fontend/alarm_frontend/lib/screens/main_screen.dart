import 'package:alarm_frontend/models/auth_model_user.dart';
import 'package:flutter/material.dart';
import '../components/bottom_nav_bar.dart';
import 'home_screen.dart';
import 'schedule_screen.dart';
import 'hub_screen.dart';
import 'insight_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  
  const MainScreen({super.key});
  static final GlobalKey<MainScreenState> globalKey =
      GlobalKey<MainScreenState>();

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  late int currentIndex=0;

  void changeTab(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  final List<Widget> screens = const [
    HomeScreen(),
    ScheduleScreen(),
    HubScreen(),
    InsightScreen(),
    ProfileScreen(user: AuthUserModel()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),

      bottomNavigationBar: BottomNavBar(
        currentIndex: currentIndex,
        onTap: changeTab,
      ),
    );
  }
}
