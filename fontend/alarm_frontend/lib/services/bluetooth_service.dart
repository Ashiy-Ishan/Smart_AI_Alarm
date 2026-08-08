import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;
import 'package:permission_handler/permission_handler.dart';

class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();

  ble.BluetoothDevice? connectedDevice;
  ble.BluetoothCharacteristic? writeCharacteristic;
  ble.BluetoothCharacteristic? readMacCharacteristic;

  // these must match the esp32 code
  final String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  final String CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  final String MAC_READ_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a9";

  // ask user for bluetooth and location
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
      
      await Future.delayed(const Duration(milliseconds: 500));
      List<ble.BluetoothService> services = await device.discoverServices();
      
      for (var service in services) {
        if (service.uuid.toString().toLowerCase() == SERVICE_UUID.toLowerCase()) {
          for (var char in service.characteristics) {
            if (char.uuid.toString().toLowerCase() == CHARACTERISTIC_UUID.toLowerCase()) {
              writeCharacteristic = char;
            }
            if (char.uuid.toString().toLowerCase() == MAC_READ_UUID.toLowerCase()) {
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

  // get the real wifi mac from hardware
  Future<String?> getDeviceRealMac() async {
    if (readMacCharacteristic != null) {
      try {
        List<int> value = await readMacCharacteristic!.read();
        return utf8.decode(value).trim();
      } catch (e) {
        print('mac read error: $e');
      }
    }
    return connectedDevice?.remoteId.toString();
  }

  // send wifi details and user id to device
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
