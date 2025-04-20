import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Service for managing Bluetooth Low Energy communication with EMS devices
class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  
  // Singleton pattern
  factory BluetoothService() {
    return _instance;
  }
  
  BluetoothService._internal();
  
  // BLE related fields
  FlutterBluePlus get flutterBlue => FlutterBluePlus.instance;
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _notifyCharacteristic;
  
  // EMS device service and characteristic UUIDs
  final String _serviceUuid = "0000FFE0-0000-1000-8000-00805F9B34FB"; // HM-10 service UUID
  final String _writeCharUuid = "0000FFE1-0000-1000-8000-00805F9B34FB"; // HM-10 characteristic UUID
  final String _notifyCharUuid = "0000FFE1-0000-1000-8000-00805F9B34FB"; // Same for HM-10
  
  // Stream controller for device data
  final _deviceDataController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get deviceDataStream => _deviceDataController.stream;
  
  // Check if Bluetooth is available and enabled
  Future<bool> isBluetoothAvailable() async {
    try {
      BluetoothAdapterState state = await flutterBlue.adapterState.first;
      return state == BluetoothAdapterState.on;
    } catch (e) {
      print("Error checking Bluetooth availability: $e");
      return false;
    }
  }
  
  // Start scanning for devices
  Future<void> startScan() async {
    if (!(await isBluetoothAvailable())) {
      throw Exception("Bluetooth is not available");
    }
    
    // Stop any ongoing scan
    await stopScan();
    
    // Start scanning
    await flutterBlue.startScan(
      timeout: Duration(seconds: 10),
      withServices: [Guid(_serviceUuid)],
    );
  }
  
  // Stop scanning for devices
  Future<void> stopScan() async {
    if (flutterBlue.isScanningNow) {
      await flutterBlue.stopScan();
    }
  }
  
  // Get scan results stream
  Stream<List<ScanResult>> get scanResults => flutterBlue.scanResults;
  
  // Connect to a device by MAC address
  Future<bool> connectToDevice(String macAddress) async {
    try {
      // Stop any ongoing scan
      await stopScan();
      
      // Find device in scan results
      List<ScanResult> results = await flutterBlue.scanResults.first;
      ScanResult? targetResult;
      
      for (ScanResult result in results) {
        if (result.device.id.id == macAddress) {
          targetResult = result;
          break;
        }
      }
      
      if (targetResult == null) {
        // Try to scan specifically for this device
        await startScan();
        await Future.delayed(Duration(seconds: 5));
        
        results = await flutterBlue.scanResults.first;
        for (ScanResult result in results) {
          if (result.device.id.id == macAddress) {
            targetResult = result;
            break;
          }
        }
        
        if (targetResult == null) {
          throw Exception("Device not found");
        }
      }
      
      // Connect to the device
      await targetResult.device.connect(
        autoConnect: false,
        timeout: Duration(seconds: 15),
      );
      
      _connectedDevice = targetResult.device;
      
      // Discover services
      List<BluetoothService> services = await _connectedDevice!.discoverServices();
      
      // Find the target service and characteristics
      for (BluetoothService service in services) {
        if (service.uuid.toString() == _serviceUuid) {
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            if (characteristic.uuid.toString() == _writeCharUuid) {
              _writeCharacteristic = characteristic;
            }
            
            if (characteristic.uuid.toString() == _notifyCharUuid) {
              _notifyCharacteristic = characteristic;
              
              // Set up notification
              await _notifyCharacteristic!.setNotifyValue(true);
              _notifyCharacteristic!.value.listen(_onDataReceived);
            }
          }
        }
      }
      
      // Check if we found the required characteristics
      if (_writeCharacteristic == null || _notifyCharacteristic == null) {
        throw Exception("Required characteristics not found on device");
      }
      
      // Request battery level
      await sendCommand("GET_BATTERY");
      
      return true;
    } catch (e) {
      print("Error connecting to device: $e");
      return false;
    }
  }
  
  // Disconnect from current device
  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.disconnect();
        _connectedDevice = null;
        _writeCharacteristic = null;
        _notifyCharacteristic = null;
      } catch (e) {
        print("Error disconnecting: $e");
      }
    }
  }
  
  // Check if connected to a device
  bool get isConnected => _connectedDevice != null;
  
  // Get the connected device
  BluetoothDevice? get connectedDevice => _connectedDevice;
  
  // Send command to device
  Future<void> sendCommand(String command) async {
    if (_connectedDevice == null || _writeCharacteristic == null) {
      throw Exception("Not connected to a device");
    }
    
    try {
      List<int> bytes = utf8.encode(command);
      await _writeCharacteristic!.write(bytes);
    } catch (e) {
      print("Error sending command: $e");
      throw Exception("Failed to send command: $e");
    }
  }
  
  // Handle received data from device
  void _onDataReceived(List<int> data) {
    try {
      String receivedData = utf8.decode(data);
      print("Received from device: $receivedData");
      
      // Parse the received data
      if (receivedData.startsWith("BATTERY:")) {
        int batteryLevel = int.parse(receivedData.substring(8));
        _deviceDataController.add({"batteryLevel": batteryLevel});
      } else if (receivedData.startsWith("ERROR:")) {
        String error = receivedData.substring(6);
        _deviceDataController.add({"error": error});
      } else if (receivedData.startsWith("STATUS:")) {
        String status = receivedData.substring(7);
        _deviceDataController.add({"status": status});
      }
    } catch (e) {
      print("Error parsing device data: $e");
    }
  }
  
  // Dispose resources
  void dispose() {
    disconnect();
    _deviceDataController.close();
  }
}