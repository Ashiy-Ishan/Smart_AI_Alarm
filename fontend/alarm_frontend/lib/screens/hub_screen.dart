import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:alarm_frontend/utils/app_text_styles.dart';
import 'package:alarm_frontend/components/hub_env_card.dart';
import 'package:alarm_frontend/components/hub_motion_row.dart';
import 'package:alarm_frontend/components/hub_device_control_card.dart';
import 'package:alarm_frontend/components/hub_status_card.dart';
import 'package:alarm_frontend/screens/motion_log_screen.dart';
import 'package:alarm_frontend/screens/hub_setup/bluetooth_scan_screen.dart';

class HubScreen extends StatefulWidget {
  const HubScreen({super.key});

  @override
  State<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<HubScreen> with AutomaticKeepAliveClientMixin {
  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;
  String? _macAddress;
  String? _hiddenUid;
  bool _isInitialized = false;
  Timer? _resetTimer;
  int _countdown = 15;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _findUserDevice();
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  String _getHiddenUid(String email) {
    String prefix = email.split('@').first.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
    String hash = email.hashCode.abs().toString();
    String suffix = hash.length > 4 ? hash.substring(hash.length - 4) : hash.padLeft(4, '0');
    return "user_${prefix}_$suffix";
  }

  Future<void> _findUserDevice() async {
    try {
      final email = FirebaseAuth.instance.currentUser?.email ?? "";
      if (email.isEmpty) {
        if (mounted) setState(() => _isInitialized = true);
        return;
      }
      _hiddenUid = _getHiddenUid(email);
      final snapshot = await _rtdb.ref().child('Users').child(_hiddenUid!).child('Devices').get();
      if (snapshot.exists && mounted) {
        final devices = snapshot.value as Map<dynamic, dynamic>;
        if (devices.isNotEmpty) {
          _macAddress = devices.keys.first.toString();
        }
      }
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      if (mounted) setState(() => _isInitialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16, 
                  right: 16, 
                  top: MediaQuery.of(context).padding.top + 16,
                  bottom: MediaQuery.of(context).padding.bottom + 100,
                ),
                child: _macAddress == null ? _buildNoDeviceUI() : _buildLiveDashboardContent(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoDeviceUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.bluetooth_disabled, size: 80, color: AppColors.textSecondary),
        const SizedBox(height: 24),
        const Text(
          "No Hub Connected",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          "Link your Bedside Hub to see live\nenvironment and activity stats.",
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 32),
        TextButton(
          onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const BluetoothScanScreen()));
            _findUserDevice();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text(
              "Setup Bedside Hub",
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLiveDashboardContent() {
    return StreamBuilder(
      stream: _rtdb.ref().child('Users').child(_hiddenUid!).child('Devices').child(_macAddress!).onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Sync Error", style: TextStyle(color: Colors.red)));
        final data = snapshot.data?.snapshot.value as Map<dynamic, dynamic>? ?? {};

        final double temp = (data['Temperature'] ?? 0.0).toDouble();
        final double humidity = (data['Humidity'] ?? 0.0).toDouble();
        final String lightStatus = data['LightStatus'] ?? 'UNKNOWN';
        final bool relayEnabled = data['RelayEnabled'] ?? false;
        final bool motion = (data['MotionDetected'] ?? 0) == 1;
        final String userStatus = data['UserStatus'] ?? 'idle';
        final int soundLevel = data['SoundLevel'] ?? 5;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bedside Hub', style: AppTextStyles.heading),
                    const SizedBox(height: 2),
                    Text('MAC: $_macAddress', style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.primary, size: 20),
                  onPressed: _findUserDevice,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Environment', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: HubEnvCard(icon: Icons.thermostat_outlined, value: '${temp.toStringAsFixed(1)}°C', label: 'Temp')),
                const SizedBox(width: 10),
                Expanded(child: HubEnvCard(icon: Icons.water_drop_outlined, value: '${humidity.toStringAsFixed(1)}%', label: 'Humidity')),
                const SizedBox(width: 10),
                Expanded(child: HubEnvCard(icon: Icons.wb_sunny_outlined, value: lightStatus, label: 'Light')),
              ],
            ),
            const SizedBox(height: 20),
            
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MotionLogScreen())),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Live Activity', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                        Text(userStatus.toUpperCase(), style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    HubMotionRow(time: 'Motion Status', event: motion ? 'MOTION DETECTED' : 'Status: Still'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Hardware Configuration', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            
            HubDeviceControlCard(
              icon: Icons.power,
              title: 'Master Relay',
              subtitle: relayEnabled ? 'System Enabled' : 'System Disabled',
              value: relayEnabled ? 1.0 : 0.0,
              onChanged: (v) => _updateDevice('RelayEnabled', v > 0.5),
              trailing: Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: relayEnabled,
                  onChanged: (v) => _updateDevice('RelayEnabled', v),
                  activeTrackColor: AppColors.primary,
                ),
              ),
            ),

            const SizedBox(height: 12),
            HubDeviceControlCard(
              icon: Icons.volume_up_outlined,
              title: 'Hub Volume',
              subtitle: 'Level: $soundLevel',
              value: soundLevel / 10.0,
              onChanged: (v) => _updateDevice('SoundLevel', (v * 10).round()),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showFactoryResetWarning(context),
                icon: const Icon(Icons.settings_backup_restore, color: Colors.orangeAccent, size: 18),
                label: const Text("FACTORY RESET & UNBIND", style: TextStyle(color: Colors.orangeAccent, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.orangeAccent),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _updateDevice(String key, dynamic value) {
    if (_macAddress != null && _hiddenUid != null) {
      _rtdb.ref().child('Users').child(_hiddenUid!).child('Devices').child(_macAddress!).update({key: value});
    }
  }

  void _showFactoryResetWarning(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.card,
            title: const Text("Factory Reset Warning", style: TextStyle(color: Colors.orangeAccent)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "This will wipe all hardware settings and delete your data from the cloud.",
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                Text(
                  "Resetting in: $_countdown seconds",
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _cancelReset();
                  Navigator.pop(ctx);
                },
                child: const Text("CANCEL", style: TextStyle(color: AppColors.primary)),
              ),
            ],
          );
        },
      ),
    );

    _startResetCountdown(context);
  }

  void _startResetCountdown(BuildContext context) {
    _countdown = 15;
    _updateDevice('FactoryReset', true);

    _resetTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        if (mounted) {
          setState(() => _countdown--);
        }
      } else {
        timer.cancel();
        _verifyAndExecuteReset(context);
      }
    });
  }

  void _cancelReset() {
    _resetTimer?.cancel();
    _updateDevice('FactoryReset', false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Reset Canceled")),
      );
    }
  }

  void _verifyAndExecuteReset(BuildContext context) async {
    if (_macAddress == null || _hiddenUid == null) return;

    final snapshot = await _rtdb.ref().child('Users').child(_hiddenUid!).child('Devices').child(_macAddress!).child('FactoryReset').get();
    
    if (snapshot.exists && snapshot.value == true) {
      try {
        await _rtdb.ref().child('Users').child(_hiddenUid!).child('Devices').child(_macAddress!).remove();
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop(); // Close dialog
          setState(() => _macAddress = null);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Device factory reset and unlinked successfully.")),
          );
        }
      } catch (e) {
        print("Reset Error: $e");
      }
    }
  }
}
