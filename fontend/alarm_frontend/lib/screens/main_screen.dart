import 'package:alarm_frontend/models/auth_model_user.dart';
import 'package:alarm_frontend/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  int currentIndex = 0;

  void changeTab(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user ?? const AuthUserModel();

    final List<Widget> screens = [
      const HomeScreen(),
      const ScheduleScreen(),
      const HubScreen(),
      const InsightScreen(),
      ProfileScreen(user: user),
    ];

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: screens),

      bottomNavigationBar: BottomNavBar(
        currentIndex: currentIndex,
        onTap: changeTab,
      ),
    );
  }
}

