import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:alarm_frontend/utils/app_text_styles.dart';
import 'package:alarm_frontend/components/hub_env_card.dart';
import 'package:alarm_frontend/components/hub_motion_row.dart';
import 'package:alarm_frontend/components/hub_device_control_card.dart';
import 'package:alarm_frontend/components/hub_status_card.dart';
import 'package:alarm_frontend/screens/motion_log_screen.dart';

class HubScreen extends StatefulWidget {
  const HubScreen({super.key});

  @override
  State<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<HubScreen> {
  bool _smartLight = true;
  double _lightDim = 0.6;
  double _soundLevel = 0.4;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const SizedBox(height: 16),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Bedside Hub', style: AppTextStyles.heading),
                    SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          'Connected: ',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'WiFi',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Icon(Icons.wifi, color: AppColors.primary, size: 26),
              ],
            ),

            const SizedBox(height: 24),

            // Environment section
            const Text(
              'Environment',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: const [
                HubEnvCard(
                  icon: Icons.thermostat_outlined,
                  value: '68°C',
                  label: 'Temp',
                ),
                SizedBox(width: 10),
                HubEnvCard(
                  icon: Icons.water_drop_outlined,
                  value: '48%',
                  label: 'Humidity',
                ),
                SizedBox(width: 10),
                HubEnvCard(
                  icon: Icons.wb_sunny_outlined,
                  value: '12Lux',
                  label: 'Light',
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Motion Log — tappable, navigates to MotionLogScreen
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MotionLogScreen(),
                ),
              ),
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
                      children: const [
                        Text(
                          'Motion Log',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const HubMotionRow(time: '07:04 PM', event: 'Move'),
                    const SizedBox(height: 8),
                    const HubMotionRow(time: '10:44 PM', event: 'Wake'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Hardware Controls
            const Text(
              'Hardware Controls',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),

            // Smart Light card
            HubDeviceControlCard(
              icon: Icons.lightbulb_outline,
              title: 'Smart Light',
              subtitle: 'Dim',
              value: _lightDim,
              onChanged: (v) => setState(() => _lightDim = v),
              trailing: Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: _smartLight,
                  onChanged: (v) => setState(() => _smartLight = v),
                  activeThumbColor: Colors.black,
                  activeTrackColor: AppColors.primary,
                  inactiveThumbColor: AppColors.textSecondary,
                  inactiveTrackColor: AppColors.border,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Sound Level card
            HubDeviceControlCard(
              icon: Icons.volume_up_outlined,
              title: 'Sound Level',
              subtitle: 'Vol ${(RealVolumePercent(_soundLevel))}%',
              value: _soundLevel,
              onChanged: (v) => setState(() => _soundLevel = v),
            ),

            const SizedBox(height: 16),

            // Hub Online Status
            const HubStatusCard(
              isOnline: true,
              statusText: 'Hub online Status',
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Helper method to display human-readable volume percentage
  static int RealVolumePercent(double value) {
    return (value * 100).round();
  }
}
