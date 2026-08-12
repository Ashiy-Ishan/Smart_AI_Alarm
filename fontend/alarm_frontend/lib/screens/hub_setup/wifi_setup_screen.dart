import 'package:alarm_frontend/screens/main_screen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:alarm_frontend/components/primary_button.dart';
import 'package:alarm_frontend/services/bluetooth_service.dart' as custom;

class WifiSetupScreen extends StatefulWidget {
  final BluetoothDevice device;
  const WifiSetupScreen({super.key, required this.device});

  @override
  State<WifiSetupScreen> createState() => _WifiSetupScreenState();
}

class _WifiSetupScreenState extends State<WifiSetupScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _ssidController = TextEditingController();
  bool _isLoading = false;
  final NetworkInfo _networkInfo = NetworkInfo();

  @override
  void initState() {
    super.initState();
    _autoDetectWifi();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _ssidController.dispose();
    super.dispose();
  }

  Future<void> _autoDetectWifi() async {
    String? wifiName;
    try {
      wifiName = await _networkInfo.getWifiName();
      if (wifiName != null &&
          wifiName.startsWith('"') &&
          wifiName.endsWith('"')) {
        wifiName = wifiName.substring(1, wifiName.length - 1);
      }
    } catch (error) {
      debugPrint('Unable to detect Wi-Fi name: $error');
    }

    final detectedName = wifiName;
    if (mounted && detectedName != null && detectedName.isNotEmpty) {
      setState(() => _ssidController.text = detectedName);
    }
  }

  String _getHiddenUid(String email) {
    String prefix = email
        .split('@')
        .first
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
        .toLowerCase();
    String hash = email.hashCode.abs().toString();
    String suffix = hash.length > 4
        ? hash.substring(hash.length - 4)
        : hash.padLeft(4, '0');
    return "user_${prefix}_$suffix";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add New Device'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connect to Hub',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),

            const Text(
              "Wi-Fi Name",
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextField(
              controller: _ssidController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'MyHomeNetwork',
                hintStyle: const TextStyle(color: Colors.white24),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.border),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(
                    Icons.refresh,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  onPressed: _autoDetectWifi,
                ),
              ),
            ),

            const SizedBox(height: 32),

            const Text(
              "Password",
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: '********',
                hintStyle: TextStyle(color: Colors.white24),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
            ),

            const Spacer(),

            PrimaryButton(
              text: 'Send to Device',
              isLoading: _isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final String ssid = _ssidController.text.trim();
    final String password = _passwordController.text.trim();

    if (ssid.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in both fields")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final email = FirebaseAuth.instance.currentUser?.email ?? "unknown";
    final hiddenUid = _getHiddenUid(email);

    try {
      final bleService = custom.BluetoothService();
      
      // Fetch the REAL MAC Address from the hub characteristic
      final macAddress = await bleService.getDeviceRealMac() ?? widget.device.remoteId.toString();

      // 1. First write to Firebase to ensure the hub has its path ready
      final rtdb = FirebaseDatabase.instance.ref();
      await rtdb
          .child('Users')
          .child(hiddenUid)
          .child('Devices')
          .child(macAddress)
          .set({
            "AlarmTime": "07:00",
            "AlarmEnabled": true,
            "Humidity": 0.0,
            "LightStatus": "INIT",
            "MotionDetected": 0,
            "RelayStatus": "OFF",
            "Temperature": 0.0,
            "UserStatus": "idle",
            "SoundLevel": 5,
            "SelectedTone": 0,
            "FactoryReset": false,
            "ManualLamp": false,
          });

      // 2. Then send provisioning data to the hub via Bluetooth
      // Note: Hub restarts immediately after this, so we do it last
      await bleService.sendProvisioningData(
        ssid,
        password,
        hiddenUid,
      );

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WiFi Data Sent! Configuring Hub...')),
        );

        // Wait 2 seconds to ensure Hub receives data, then close and navigate
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            // Pop until first (MainScreen)
            Navigator.of(context).popUntil((route) => route.isFirst);

            // Switch to Hub Tab (index 2)
            MainScreen.globalKey.currentState?.changeTab(2);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Setup Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
