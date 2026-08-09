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
      
      await ble.FlutterBluePlus.stopScan();
      
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
        elevation: 0,
      ),
      body: Column(
        children: [
          if (_isScanning) const LinearProgressIndicator(color: AppColors.primary, minHeight: 2),
          Expanded(
            child: StreamBuilder<List<ble.ScanResult>>(
              stream: ble.FlutterBluePlus.scanResults,
              initialData: const [],
              builder: (c, snapshot) {
                final alarmDevices = snapshot.data!
                    .where((r) {
                      final name = r.device.platformName.toLowerCase();
                      final localName = r.advertisementData.advName.toLowerCase();
                      return name.contains("alarm") || localName.contains("alarm");
                    })
                    .toList();

                if (alarmDevices.isEmpty && !_isScanning) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.search_off, size: 64, color: AppColors.textSecondary),
                          SizedBox(height: 16),
                          Text(
                            "No Alarm Devices Found",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Ensure your Bedside Hub is powered on and in pairing mode.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (alarmDevices.isEmpty && _isScanning) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 24),
                        Text("Searching for Hub...", style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: alarmDevices
                      .map((r) => Card(
                            color: AppColors.card,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.black26,
                                child: Icon(Icons.alarm, color: AppColors.primary),
                              ),
                              title: Text(
                                r.device.platformName.isNotEmpty ? r.device.platformName : "Smart Alarm Hub",
                                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                r.device.remoteId.toString(),
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                              ),
                              trailing: const Icon(Icons.chevron_right, color: AppColors.primary),
                              onTap: () async {
                                bool connected = await _bleService.connectToDevice(r.device);
                                if (connected && mounted) {
                                  if (context.mounted) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => WifiSetupScreen(device: r.device),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
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
        child: Icon(_isScanning ? Icons.stop : Icons.refresh, color: Colors.black),
      ),
    );
  }
}
