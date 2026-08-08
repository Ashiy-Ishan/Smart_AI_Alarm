/// Central registry of all named routes in the app.
/// Use these constants everywhere instead of raw strings.
class AppRoutes {
  AppRoutes._(); // prevent instantiation

  // ── Auth flow ──────────────────────────────────────────────────────────────
  static const String splash         = '/';
  static const String auth           = '/auth';
  static const String verifyAccount  = '/verify-account';
  static const String accountVerified = '/account-verified';

  // ── Main shell ─────────────────────────────────────────────────────────────
  static const String main           = '/main';

  // ── Home tab sub-screens ───────────────────────────────────────────────────
  static const String todaySummary   = '/today-summary';
  static const String setAlarm       = '/set-alarm';

  // ── Profile tab sub-screens ────────────────────────────────────────────────
  static const String calendar       = '/calendar';
  static const String gmail          = '/gmail';
  static const String dataEncryption = '/data-encryption';
  static const String clearHistory   = '/clear-history';
  static const String deleteAccount  = '/delete-account';
  static const String feedback       = '/feedback';

  // ── Insight tab sub-screens ────────────────────────────────────────────────
  static const String accuracyScore       = '/accuracy-score';
  static const String activityRecords     = '/activity-records';
  static const String weeklyMotionReport  = '/weekly-motion-report';
  static const String motionLog           = '/motion-log';
  static const String exportMotionData    = '/export-motion-data';
}
