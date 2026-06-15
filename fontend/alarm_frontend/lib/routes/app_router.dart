import 'package:alarm_frontend/models/auth_page_model.dart';
import 'package:alarm_frontend/screens/account_verified_screen.dart';
import 'package:alarm_frontend/screens/accuracy_score_screen.dart';
import 'package:alarm_frontend/screens/activity_records_screen.dart';
import 'package:alarm_frontend/screens/auth_screen.dart';
import 'package:alarm_frontend/screens/calendar_screen.dart';
import 'package:alarm_frontend/screens/clear_history_screen.dart';
import 'package:alarm_frontend/screens/data_encryption_screen.dart';
import 'package:alarm_frontend/screens/delete_account_screen.dart';
import 'package:alarm_frontend/screens/export_motion_data_screen.dart';
import 'package:alarm_frontend/screens/feedback_screen.dart';
import 'package:alarm_frontend/screens/gmail_screen.dart';
import 'package:alarm_frontend/screens/main_screen.dart';
import 'package:alarm_frontend/screens/message_screen.dart';
import 'package:alarm_frontend/screens/motion_log_screen.dart';
import 'package:alarm_frontend/screens/set_alarm_screen.dart';
import 'package:alarm_frontend/screens/splash_screen.dart';
import 'package:alarm_frontend/screens/today_summary_screen.dart';
import 'package:alarm_frontend/screens/verify_account_screen.dart';
import 'package:alarm_frontend/screens/weekly_motion_report_screen.dart';
import 'package:flutter/material.dart';
import 'app_routes.dart';

/// Single source of truth for route generation.
///
/// Register this in MaterialApp:
/// ```dart
/// MaterialApp(
///   initialRoute: AppRoutes.splash,
///   onGenerateRoute: AppRouter.onGenerateRoute,
/// )
/// ```
///
/// IMPORTANT: Auth-flow screens (splash, auth, main) must always use
/// [rootNavigator: true] so they escape the nested tab navigators.
/// Screens inside a tab can use plain Navigator.of(context).push() / named routes.
class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      // ── Auth flow ────────────────────────────────────────────────────────
      case AppRoutes.splash:
        return _fade(const SplashScreen());

      case AppRoutes.auth:
        return _slide(AuthScreen(initialPage: AuthPageModel.login()));

      case AppRoutes.verifyAccount:
        return _slide(const VerifyAccountScreen());

      case AppRoutes.accountVerified:
        return _fade(const AccountVerifiedScreen());

      // ── Main shell ───────────────────────────────────────────────────────
      case AppRoutes.main:
        return _fade(const MainScreen());

      // ── Home tab sub-screens ─────────────────────────────────────────────
      case AppRoutes.todaySummary:
        return _slide(const TodaySummaryScreen());

      case AppRoutes.setAlarm:
        return _slide(const StopAlarmScreen());

      // ── Profile tab sub-screens ──────────────────────────────────────────
      case AppRoutes.calendar:
        return _slide(const CalendarScreen());

      case AppRoutes.gmail:
        return _slide(const GmailScreen());

      case AppRoutes.message:
        return _slide(const MessageScreen());

      case AppRoutes.dataEncryption:
        return _slide(const DataEncryptionScreen());

      case AppRoutes.clearHistory:
        return _slide(const ClearHistoryScreen());

      case AppRoutes.deleteAccount:
        return _slide(const DeleteAccountScreen());

      case AppRoutes.feedback:
        return _slide(const FeedbackScreen());

      // ── Insight tab sub-screens ──────────────────────────────────────────
      case AppRoutes.accuracyScore:
        return _slide(const AccuracyScoreScreen());

      case AppRoutes.activityRecords:
        return _slide(const ActivityRecordsScreen());

      case AppRoutes.weeklyMotionReport:
        return _slide(const WeeklyMotionReportScreen());

      case AppRoutes.motionLog:
        return _slide(const MotionLogScreen());

      case AppRoutes.exportMotionData:
        return _slide(const ExportMotionDataScreen());

      // ── Fallback ─────────────────────────────────────────────────────────
      default:
        return _fade(const SplashScreen());
    }
  }

  // ── Transition helpers ────────────────────────────────────────────────────

  /// Fade transition — used for root-level screens (splash, main).
  static PageRouteBuilder<void> _fade(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 250),
    );
  }

  /// Slide-up transition — used for sub-screens and auth steps.
  static PageRouteBuilder<void> _slide(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) {
        final tween = Tween(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeInOut));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 280),
    );
  }
}
