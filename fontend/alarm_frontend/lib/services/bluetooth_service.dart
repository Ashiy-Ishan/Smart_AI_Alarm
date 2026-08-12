import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();

  ble.BluetoothDevice? connectedDevice;
  ble.BluetoothCharacteristic? writeCharacteristic;
  ble.BluetoothCharacteristic? readMacCharacteristic;

  final String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  final String CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  final String MAC_READ_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a9";

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      Map<Permission, PermissionStatus> statuses = await [
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

      // Request MTU to ensure provisioning data fits in packets
      if (Platform.isAndroid) {
        try {
          await device.requestMtu(512);
        } catch (e) {
          Logger().w('MTU request failed: $e');
        }
      }

      await Future.delayed(const Duration(milliseconds: 500));
      List<ble.BluetoothService> services = await device.discoverServices();

      for (var service in services) {
        if (service.uuid.toString().toLowerCase() ==
            SERVICE_UUID.toLowerCase()) {
          for (var char in service.characteristics) {
            if (char.uuid.toString().toLowerCase() ==
                CHARACTERISTIC_UUID.toLowerCase()) {
              writeCharacteristic = char;
            }
            if (char.uuid.toString().toLowerCase() ==
                MAC_READ_UUID.toLowerCase()) {
              readMacCharacteristic = char;
            }
          }
        }
      }
      return writeCharacteristic != null;
    } catch (e) {
      return false;
    }
  }

  Future<String?> getDeviceRealMac() async {
    if (readMacCharacteristic != null) {
      try {
        List<int> value = await readMacCharacteristic!.read();
        return utf8.decode(value).trim();
      } catch (e) {
        Logger().e('mac read error: $e');
      }
    }
    return connectedDevice?.remoteId.toString();
  }

  Future<bool> sendProvisioningData(
    String ssid,
    String password,
    String uid,
  ) async {
    if (writeCharacteristic != null) {
      try {
        // Trim credentials before sending
        String s = ssid.trim();
        String p = password.trim();
        String u = uid.trim();
        
        String payload = "$s,$p,$u";
        
        // Reverting to with response for guaranteed delivery
        // The "Setup Failed" message is avoided by the catch block and UI order
        await writeCharacteristic!.write(utf8.encode(payload),
            withoutResponse: false);

        return true;
      } catch (e) {
        Logger().e('Provisioning write error: $e');
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
