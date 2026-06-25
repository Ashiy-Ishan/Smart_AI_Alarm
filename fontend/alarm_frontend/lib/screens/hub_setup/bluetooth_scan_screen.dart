import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;
import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:alarm_frontend/services/bluetooth_service.dart' as custom;
import 'package:alarm_frontend/screens/hub_setup/wifi_setup_screen.dart';

class BluetoothScanScreen extends StatefulWidget {
  const BluetoothScanScreen({super.key});

  @override
  State<BluetoothScanScreen> createState() => _BluetoothScanScreenState();
}

class _BluetoothScanScreenState extends State<BluetoothScanScreen> {
  final custom.BluetoothService _bleService = custom.BluetoothService();
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  void _startScan() async {
    bool hasPermission = await _bleService.requestPermissions();
    if (hasPermission) {
      setState(() => _isScanning = true);
      
      // Stop any existing scan first
      await ble.FlutterBluePlus.stopScan();
      
      // Start scan with aggressive parameters for S21 compatibility
      await ble.FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        androidUsesFineLocation: true,
      );

      ble.FlutterBluePlus.isScanning.listen((scanning) {
        if (mounted) setState(() => _isScanning = scanning);
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bluetooth and Location permissions are required for scanning.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Connect Bedside Hub'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Column(
        children: [
          if (_isScanning) const LinearProgressIndicator(color: AppColors.primary),
          Expanded(
            child: StreamBuilder<List<ble.ScanResult>>(
              stream: ble.FlutterBluePlus.scanResults,
              initialData: const [],
              builder: (c, snapshot) {
                // Combine results from both names for more robust detection
                final alarmDevices = snapshot.data!
                    .where((r) {
                      final name = r.device.platformName.toLowerCase();
                      final localName = r.advertisementData.localName.toLowerCase();
                      return name.contains("alarm") || localName.contains("alarm");
                    })
                    .toList();

                if (alarmDevices.isEmpty && !_isScanning) {
                  return const Center(
                    child: Text(
                      "No Alarm Devices Found.\nEnsure your device is in pairing mode.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }

                return ListView(
                  children: alarmDevices
                      .map((r) => ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: AppColors.card,
                              child: Icon(Icons.alarm, color: AppColors.primary),
                            ),
                            title: Text(
                              r.device.platformName.isNotEmpty ? r.device.platformName : "Smart Alarm Hub",
                              style: const TextStyle(color: AppColors.textPrimary),
                            ),
                            subtitle: Text(
                              r.device.remoteId.toString(),
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                            ),
                            trailing: const Icon(Icons.bluetooth_connected, color: AppColors.primary),
                            onTap: () async {
                              bool connected = await _bleService.connectToDevice(r.device);
                              if (connected && mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => WifiSetupScreen(device: r.device),
                                  ),
                                );
                              }
                            },
                          ))
                      .toList(),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isScanning ? null : _startScan,
        backgroundColor: AppColors.primary,
        child: Icon(_isScanning ? Icons.stop : Icons.search),
      ),
    );
  }
}
