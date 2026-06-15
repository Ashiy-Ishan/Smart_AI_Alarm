import 'package:alarm_frontend/models/auth_model_user.dart';
import 'package:alarm_frontend/providers/user_provider.dart';
import 'package:alarm_frontend/routes/app_router.dart';
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

  /// One dedicated NavigatorKey per tab so each tab keeps its own back-stack.
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(), // Home
    GlobalKey<NavigatorState>(), // Schedule
    GlobalKey<NavigatorState>(), // Hub
    GlobalKey<NavigatorState>(), // Insight
    GlobalKey<NavigatorState>(), // Profile
  ];

  void changeTab(int index) {
    if (currentIndex == index) {
      // Tapping the active tab pops back to its root screen
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
      // Reset the tab we're leaving so returning to it always shows its root
      _navigatorKeys[currentIndex].currentState?.popUntil((route) => route.isFirst);
      setState(() => currentIndex = index);
    }
  }

  /// Wraps each tab's root screen in its own Navigator.
  /// Using Offstage keeps all navigators alive so state is preserved.
  Widget _buildTabNavigator(int index, Widget rootScreen) {
    return Offstage(
      offstage: currentIndex != index,
      child: Navigator(
        key: _navigatorKeys[index],
        // The first route in each tab is always the tab's root screen.
        // Any named push inside a tab is handled by AppRouter.
        onGenerateRoute: (settings) {
          if (settings.name == Navigator.defaultRouteName) {
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => rootScreen,
            );
          }
          return AppRouter.onGenerateRoute(settings);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user ?? const AuthUserModel();

    return PopScope(
      // Let the tab's own navigator handle back presses first
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final nav = _navigatorKeys[currentIndex].currentState;
        if (nav != null && nav.canPop()) {
          nav.pop();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            _buildTabNavigator(0, const HomeScreen()),
            _buildTabNavigator(1, const ScheduleScreen()),
            _buildTabNavigator(2, const HubScreen()),
            _buildTabNavigator(3, const InsightScreen()),
            _buildTabNavigator(4, ProfileScreen(user: user)),
          ],
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: currentIndex,
          onTap: changeTab,
        ),
      ),
    );
  }
}