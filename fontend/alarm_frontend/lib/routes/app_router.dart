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
import 'package:alarm_frontend/screens/motion_log_screen.dart';
import 'package:alarm_frontend/screens/set_alarm_screen.dart';
import 'package:alarm_frontend/screens/splash_screen.dart';
import 'package:alarm_frontend/screens/terms_conditions_screen.dart';
import 'package:alarm_frontend/screens/today_summary_screen.dart';
import 'package:alarm_frontend/screens/verify_account_screen.dart';
import 'package:alarm_frontend/screens/weekly_motion_report_screen.dart';
import 'package:flutter/material.dart';
import 'app_routes.dart';

class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _fade(const SplashScreen());

      case AppRoutes.auth:
        return _slide(AuthScreen(initialPage: AuthPageModel.login()));

      case AppRoutes.verifyAccount:
        return _slide(const VerifyAccountScreen());

      case AppRoutes.accountVerified:
        return _fade(const AccountVerifiedScreen());

      case AppRoutes.main:
        return _fade(const MainScreen());

      case AppRoutes.todaySummary:
        return _slide(const TodaySummaryScreen());

      case AppRoutes.setAlarm:
        final alarmId = settings.arguments is String
            ? settings.arguments! as String
            : 'manual-alarm';
        return _slide(StopAlarmScreen(alarmId: alarmId));

      case AppRoutes.calendar:
        return _slide(const CalendarScreen());

      case AppRoutes.gmail:
        return _slide(const GmailScreen());

      case AppRoutes.dataEncryption:
        return _slide(const DataEncryptionScreen());

      case AppRoutes.clearHistory:
        return _slide(const ClearHistoryScreen());

      case AppRoutes.deleteAccount:
        return _slide(const DeleteAccountScreen());

      case AppRoutes.feedback:
        return _slide(const FeedbackScreen());

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

      case AppRoutes.termsAndConditions:
        return _slide(const TermsConditionsScreen());

      default:
        return _fade(const SplashScreen());
    }
  }


  static PageRouteBuilder<void> _fade(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 250),
    );
  }

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
