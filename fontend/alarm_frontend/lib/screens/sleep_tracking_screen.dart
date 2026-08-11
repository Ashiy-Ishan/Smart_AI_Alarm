import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:alarm_frontend/services/api_service.dart';
import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:alarm_frontend/utils/app_text_styles.dart';

class SleepTrackingScreen extends StatefulWidget {
  const SleepTrackingScreen({super.key});

  @override
  State<SleepTrackingScreen> createState() => _SleepTrackingScreenState();
}

class _SleepTrackingScreenState extends State<SleepTrackingScreen> {
  DateTime? _sleepStart;

  Timer? _timer;

  Duration _elapsed = Duration.zero;

  bool _saving = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // =========================================================
  // START SLEEP TRACKING
  // =========================================================

  void _startSleep() {
    if (_sleepStart != null) {
      return;
    }

    final now = DateTime.now();

    setState(() {
      _sleepStart = now;
      _elapsed = Duration.zero;
    });

    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _sleepStart == null || _saving) {
        return;
      }

      setState(() {
        _elapsed = DateTime.now().difference(_sleepStart!);
      });
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Sleep tracking started')));
  }

  // =========================================================
  // END SLEEP TRACKING
  // =========================================================

  Future<void> _endSleep() async {
    if (_saving) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('You must be logged in.');

      return;
    }

    final start = _sleepStart;

    if (start == null) {
      _showMessage('Start sleep tracking first.');

      return;
    }

    final sleepEnd = DateTime.now();

    if (sleepEnd.isBefore(start) || sleepEnd.isAtSameMomentAs(start)) {
      _showMessage('Invalid sleep session.');

      return;
    }

    // Stop timer immediately when user presses End Sleep.
    _timer?.cancel();

    setState(() {
      _saving = true;

      // Freeze elapsed time at the exact end time.
      _elapsed = sleepEnd.difference(start);
    });

    try {
      final response = await ApiService.post('/sleep/session', {
        'user_id': user.uid,

        'sleep_start': start.toUtc().toIso8601String(),

        'sleep_end': sleepEnd.toUtc().toIso8601String(),

        'awakenings': 0,

        'motion_events': 0,

        'source': 'mobile',
      });

      debugPrint('Sleep session response: $response');

      if (!mounted) return;

      setState(() {
        _sleepStart = null;
        _elapsed = Duration.zero;
        _saving = false;
      });

      _showMessage('Sleep session saved successfully.');
    } catch (e) {
      debugPrint('Sleep session error: $e');

      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      _showMessage('Failed to save sleep session: $e');
    }
  }

  // =========================================================
  // CANCEL TRACKING
  // =========================================================

  Future<void> _cancelSleep() async {
    if (_sleepStart == null) {
      return;
    }

    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancel Sleep Tracking?'),
          content: const Text('The current sleep session will not be saved.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Keep Tracking'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Cancel Tracking'),
            ),
          ],
        );
      },
    );

    if (shouldCancel != true) {
      return;
    }

    _timer?.cancel();

    if (!mounted) return;

    setState(() {
      _sleepStart = null;
      _elapsed = Duration.zero;
      _saving = false;
    });

    _showMessage('Sleep tracking cancelled.');
  }

  // =========================================================
  // HELPERS
  // =========================================================

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatClockTime(DateTime? value) {
    if (value == null) {
      return '--:--';
    }

    final local = value.toLocal();

    final hour = local.hour.toString().padLeft(2, '0');

    final minute = local.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;

    final minutes = duration.inMinutes.remainder(60);

    final seconds = duration.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  // =========================================================
  // UI
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final tracking = _sleepStart != null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: const Text('Sleep Tracking'),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 40),

              // ------------------------------------------
              // Sleep icon
              // ------------------------------------------
              Center(
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.12),
                  ),
                  child: const Icon(
                    Icons.bedtime_outlined,
                    size: 80,
                    color: AppColors.primary,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // ------------------------------------------
              // State
              // ------------------------------------------
              Text(
                tracking ? 'Sleep tracking active' : 'Ready for sleep',
                textAlign: TextAlign.center,
                style: AppTextStyles.heading.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                tracking
                    ? _saving
                          ? 'Sleep session ended. Saving your session...'
                          : 'Your sleep session is currently being tracked.'
                    : 'Start tracking when you are ready to sleep.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color?.withValues(
                    alpha: 0.7,
                  ),
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 35),

              // ------------------------------------------
              // Start time
              // ------------------------------------------
              _InfoCard(
                title: 'Sleep Started',
                value: _formatClockTime(_sleepStart),
                icon: Icons.nightlight_outlined,
              ),

              const SizedBox(height: 16),

              // ------------------------------------------
              // Duration
              // ------------------------------------------
              _InfoCard(
                title: 'Elapsed Time',
                value: tracking ? _formatDuration(_elapsed) : '--:--:--',
                icon: Icons.timer_outlined,
              ),

              // Extra space above action button.
              const SizedBox(height: 40),

              // ------------------------------------------
              // Buttons
              // ------------------------------------------
              if (!tracking)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _startSleep,
                    icon: const Icon(Icons.bedtime_outlined),
                    label: const Text('Start Sleep'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                )
              else ...[
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _endSleep,
                    icon: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wb_sunny_outlined),
                    label: Text(_saving ? 'Saving...' : 'Wake Up / End Sleep'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _saving ? null : _cancelSleep,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Cancel Tracking'),
                  ),
                ),
              ],

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================
// REUSABLE INFO CARD
// =============================================================

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 0.7,
                    ),
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
