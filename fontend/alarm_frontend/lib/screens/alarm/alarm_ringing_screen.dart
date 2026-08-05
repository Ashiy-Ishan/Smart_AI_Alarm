import 'package:alarm_frontend/services/notification_service.dart';
import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class AlarmRingingScreen extends StatefulWidget {
  const AlarmRingingScreen({
    super.key,
    required this.macAddress,
    required this.hiddenUid,
  });

  final String macAddress;
  final String hiddenUid;

  @override
  State<AlarmRingingScreen> createState() => _AlarmRingingScreenState();
}

class _AlarmRingingScreenState extends State<AlarmRingingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(String status) async {
    if (_updating) return;
    setState(() => _updating = true);
    try {
      await FirebaseDatabase.instance
          .ref('Users/${widget.hiddenUid}/Devices/${widget.macAddress}/AlarmStatus')
          .set(status);
      await NotificationService().cancelAlarm();
      if (mounted) Navigator.of(context).pop();
    } on FirebaseException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to update alarm: ${error.message ?? error.code}')),
        );
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('ALARM RINGING', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.primary, letterSpacing: 2)),
                  const SizedBox(height: 32),
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) => Transform.scale(
                      scale: 1 + (_pulseController.value * .12),
                      child: child,
                    ),
                    child: const CircleAvatar(
                      radius: 92,
                      backgroundColor: AppColors.card,
                      child: Icon(Icons.alarm_on_rounded, size: 96, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 36),
                  Text('Your alarm is active', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  Text('Device: ${widget.macAddress}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 48),
                  FilledButton.icon(
                    onPressed: _updating ? null : () => _updateStatus('SNOOZED'),
                    icon: const Icon(Icons.snooze_rounded),
                    label: const Text('Snooze'),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _updating ? null : () => _updateStatus('STOPPED'),
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: Text(_updating ? 'Updating...' : 'Stop alarm'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
