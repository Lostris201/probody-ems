import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Service that manages Bluetooth connections and communication with EMS devices
class BluetoothService extends ChangeNotifier {
  // Bluetooth state
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  BluetoothConnectionState _connectionState = BluetoothConnectionState.disconnected;
  
  // Connected device properties
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _notifyCharacteristic;
  StreamSubscription? _stateSubscription;
  StreamSubscription? _characteristicSubscription;
  
  // HM-10 service and characteristic UUIDs
  final String _serviceUuid = "0000ffe0-0000-1000-8000-00805f9b34fb";
  final String _characteristicUuid = "0000ffe1-0000-1000-8000-00805f9b34fb";
  
  // Device information
  int _batteryLevel = 0;
  DateTime? _lastConnectionTime;
  
  // Stream controller for received data
  final _dataStreamController = StreamController<String>.broadcast();
  
  // Getters
  BluetoothAdapterState get adapterState => _adapterState;
  BluetoothConnectionState get connectionState => _connectionState;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  int get batteryLevel => _batteryLevel;
  DateTime? get lastConnectionTime => _lastConnectionTime;
  Stream<String> get dataStream => _dataStreamController.stream;
  bool get isConnected => _connectionState == BluetoothConnectionState.connected;
  
  BluetoothService() {
    // Initialize and subscribe to Bluetooth state changes
    _init();
  }
  
  void _init() async {
    // Subscribe to adapter state changes
    FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;
      notifyListeners();
    });
    
    // Get initial adapter state
    try {
      _adapterState = await FlutterBluePlus.adapterState.first;
      notifyListeners();
    } catch (e) {
      print('Error getting adapter state: $e');
    }
  }
  
  /// Connect to a device by its id (MAC address)
  Future<bool> connectToDevice(BluetoothDevice device) async {
    // If already connected to a device, disconnect first
    if (_connectedDevice != null) {
      await disconnect();
    }
    
    try {
      // Connect to the device
      await device.connect();
      _connectedDevice = device;
      _connectionState = BluetoothConnectionState.connected;
      _lastConnectionTime = DateTime.now();
      notifyListeners();
      
      // Set up state change listener
      _stateSubscription = device.connectionState.listen((state) {
        _connectionState = state;
        notifyListeners();
        
        // If disconnected unexpectedly, clean up
        if (state == BluetoothConnectionState.disconnected) {
          _cleanupConnection();
        }
      });
      
      // Discover services
      await _discoverServicesAndCharacteristics();
      
      // Request battery level
      _requestBatteryLevel();
      
      return true;
    } catch (e) {
      print('Error connecting to device: $e');
      await device.disconnect();
      _cleanupConnection();
      return false;
    }
  }
  
  /// Disconnect from the current device
  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.disconnect();
      } catch (e) {
        print('Error disconnecting: $e');
      }
      _cleanupConnection();
    }
  }
  
  /// Clean up connection resources
  void _cleanupConnection() {
    _stateSubscription?.cancel();
    _stateSubscription = null;
    
    _characteristicSubscription?.cancel();
    _characteristicSubscription = null;
    
    _writeCharacteristic = null;
    _notifyCharacteristic = null;
    _connectionState = BluetoothConnectionState.disconnected;
    _connectedDevice = null;
    
    notifyListeners();
  }
  
  /// Discover services and set up characteristics
  Future<void> _discoverServicesAndCharacteristics() async {
    if (_connectedDevice == null) return;
    
    try {
      // Discover services
      List<BluetoothService> services = await _connectedDevice!.discoverServices();
      
      // Find the HM-10 service
      BluetoothService? targetService;
      for (var service in services) {
        if (service.uuid.toString().toLowerCase() == _serviceUuid) {
          targetService = service;
          break;
        }
      }
      
      if (targetService == null) {
        print('HM-10 service not found');
        return;
      }
      
      // Find the characteristic for reading/writing
      for (var characteristic in targetService.characteristics) {
        if (characteristic.uuid.toString().toLowerCase() == _characteristicUuid) {
          // Set the characteristics for writing and notifications
          _writeCharacteristic = characteristic;
          _notifyCharacteristic = characteristic;
          
          // Subscribe to notifications if supported
          if (characteristic.properties.notify) {
            await characteristic.setNotifyValue(true);
            _characteristicSubscription = characteristic.lastValueStream.listen((value) {
              _handleIncomingData(value);
            });
          }
          
          break;
        }
      }
    } catch (e) {
      print('Error discovering services: $e');
    }
  }
  
  /// Send data to the connected device
  Future<bool> sendData(String data) async {
    if (_writeCharacteristic == null || !isConnected) {
      return false;
    }
    
    try {
      // Convert string to bytes
      List<int> bytes = utf8.encode(data + '\n'); // Add newline for HM-10
      
      // Write to the characteristic
      await _writeCharacteristic!.write(bytes);
      return true;
    } catch (e) {
      print('Error sending data: $e');
      return false;
    }
  }
  
  /// Handle incoming data from the device
  void _handleIncomingData(List<int> data) {
    if (data.isEmpty) return;
    
    // Convert bytes to string
    String message = utf8.decode(data);
    
    // Parse battery level if it's a battery response
    if (message.startsWith('BATTERY:')) {
      _parseBatteryLevel(message);
    }
    
    // Broadcast the message to listeners
    _dataStreamController.add(message);
  }
  
  /// Parse battery level from a message
  void _parseBatteryLevel(String message) {
    try {
      // Format: BATTERY:XX where XX is the percentage
      String levelStr = message.split(':')[1].trim();
      _batteryLevel = int.parse(levelStr);
      notifyListeners();
    } catch (e) {
      print('Error parsing battery level: $e');
    }
  }
  
  /// Request battery level from the device
  Future<void> _requestBatteryLevel() async {
    await sendData('GET_BATTERY');
  }
  
  /// Starts scanning for devices
  Stream<List<ScanResult>> startScan({
    Duration timeout = const Duration(seconds: 10),
  }) {
    FlutterBluePlus.startScan(
      timeout: timeout,
      androidScanMode: AndroidScanMode.lowLatency,
    );
    
    return FlutterBluePlus.scanResults;
  }
  
  /// Stops scanning for devices
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }
  
  @override
  void dispose() {
    _stateSubscription?.cancel();
    _characteristicSubscription?.cancel();
    _dataStreamController.close();
    disconnect();
    super.dispose();
  }
}