import 'dart:convert';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();

  ble.BluetoothDevice? connectedDevice;
  ble.BluetoothCharacteristic? writeCharacteristic;
  ble.BluetoothCharacteristic? readMacCharacteristic; // New: for reading real MAC

  // UUIDs - These should match your ESP32 firmware
  static const _serviceUuid = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
  static const _characteristicUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';
  static const _macReadUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26a9';

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final statuses = await <Permission>[
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();
      return statuses[Permission.bluetoothScan]!.isGranted && 
             statuses[Permission.bluetoothConnect]!.isGranted;
    }
    return true;
  }

  Future<bool> connectToDevice(ble.BluetoothDevice device) async {
    try {
      await device.connect(autoConnect: false, license: ble.License.nonprofit);
      connectedDevice = device;
      
      await Future.delayed(const Duration(milliseconds: 500));
      List<ble.BluetoothService> services = await device.discoverServices();
      
      for (var service in services) {
        if (service.uuid.toString().toLowerCase() == _serviceUuid) {
          for (var char in service.characteristics) {
            if (char.uuid.toString().toLowerCase() == _characteristicUuid) {
              writeCharacteristic = char;
            }
            if (char.uuid.toString().toLowerCase() == _macReadUuid) {
              readMacCharacteristic = char;
            }
          }
        }
      }
      return writeCharacteristic != null;
    } catch (e) {
      debugPrint('Bluetooth connection error: $e');
      return false;
    }
  }

  /// Attempts to read the "Real WiFi MAC" from the device if it provides it
  Future<String?> getDeviceRealMac() async {
    if (readMacCharacteristic != null) {
      try {
        List<int> value = await readMacCharacteristic!.read();
        return utf8.decode(value).trim();
      } catch (e) {
        debugPrint('Error reading device MAC: $e');
      }
    }
    // Fallback to Bluetooth MAC if hardware doesn't provide WiFi MAC
    return connectedDevice?.remoteId.toString();
  }

  Future<bool> sendProvisioningData(String ssid, String password, String uid) async {
    if (writeCharacteristic != null) {
      try {
        String payload = "$ssid,$password,$uid";
        await writeCharacteristic!.write(utf8.encode(payload));
        return true;
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  Future<void> disconnect() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
      connectedDevice = null;
      writeCharacteristic = null;
      readMacCharacteristic = null;
    }
  }
}
