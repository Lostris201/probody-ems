import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BluetoothService {
  static const String LAST_DEVICE_KEY = 'last_connected_device';
  static const String SERVICE_UUID = "FFE0";
  static const String CHARACTERISTIC_UUID = "FFE1";
  
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _txCharacteristic;
  bool _isConnected = false;
  
  // Commands for the HM-10 based EMS device
  static const String CMD_START = "START";
  static const String CMD_STOP = "STOP";
  static const String CMD_PAUSE = "PAUSE";
  static const String CMD_RESUME = "RESUME";
  static const String CMD_CONFIG = "CONFIG";
  static const String CMD_INTENSITY = "INTENSITY";
  
  Stream<List<int>>? _dataStream;
  StreamSubscription<List<int>>? _dataSubscription;
  
  // Get connection status
  bool get isConnected => _isConnected;
  
  // Get connected device
  BluetoothDevice? get connectedDevice => _connectedDevice;
  
  // Connect to a specific device
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      // Disconnect from any existing device
      await disconnect();
      
      // Connect to the new device
      await device.connect(autoConnect: false, timeout: Duration(seconds: 10));
      _connectedDevice = device;
      
      // Discover services
      List<BluetoothService> services = await device.discoverServices();
      
      // Find the EMS service and characteristic
      for (BluetoothService service in services) {
        if (service.uuid.toString().toUpperCase().contains(SERVICE_UUID)) {
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            if (characteristic.uuid.toString().toUpperCase().contains(CHARACTERISTIC_UUID)) {
              _txCharacteristic = characteristic;
              
              // Save the device ID for future connections
              await _saveLastConnectedDevice(device.id.id);
              
              // Setup data stream for receiving data from device
              await _setupDataStream(characteristic);
              
              _isConnected = true;
              return true;
            }
          }
        }
      }
      
      // If we got here, we couldn't find the right service/characteristic
      await device.disconnect();
      _connectedDevice = null;
      return false;
    } catch (e) {
      print('Error connecting to device: $e');
      return false;
    }
  }
  
  // Connect to the last used device
  Future<bool> connectToLastDevice() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? lastDeviceId = prefs.getString(LAST_DEVICE_KEY);
      
      if (lastDeviceId == null) {
        return false;
      }
      
      // Get a list of known devices
      List<BluetoothDevice> devices = await FlutterBluePlus.bondedDevices;
      
      // Find the device with the matching ID
      for (BluetoothDevice device in devices) {
        if (device.id.id == lastDeviceId) {
          return await connectToDevice(device);
        }
      }
      
      return false;
    } catch (e) {
      print('Error connecting to last device: $e');
      return false;
    }
  }
  
  // Disconnect from the current device
  Future<void> disconnect() async {
    try {
      // Cancel data stream subscription
      await _dataSubscription?.cancel();
      _dataSubscription = null;
      
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
      }
    } catch (e) {
      print('Error disconnecting: $e');
    } finally {
      _connectedDevice = null;
      _txCharacteristic = null;
      _isConnected = false;
    }
  }
  
  // Save the last connected device ID
  Future<void> _saveLastConnectedDevice(String deviceId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(LAST_DEVICE_KEY, deviceId);
  }
  
  // Setup the data stream for receiving data from the device
  Future<void> _setupDataStream(BluetoothCharacteristic characteristic) async {
    try {
      // Enable notifications if possible
      if (characteristic.properties.notify) {
        await characteristic.setNotifyValue(true);
        _dataStream = characteristic.value;
        
        // Listen for data from the device
        _dataSubscription = _dataStream?.listen((data) {
          // Handle incoming data
          _processIncomingData(data);
        });
      }
    } catch (e) {
      print('Error setting up data stream: $e');
    }
  }
  
  // Process incoming data from the device
  void _processIncomingData(List<int> data) {
    // Convert the data bytes to a string
    String message = utf8.decode(data);
    
    // Process the message based on its content
    if (message.startsWith("STATUS:")) {
      // Handle status updates
      print('Device status: $message');
    } else if (message.startsWith("ERROR:")) {
      // Handle error messages
      print('Device error: $message');
    } else {
      // Handle other messages
      print('Device message: $message');
    }
  }
  
  // Send raw data to the device
  Future<bool> _sendData(List<int> data) async {
    if (!_isConnected || _txCharacteristic == null) {
      return false;
    }
    
    try {
      await _txCharacteristic!.write(data, withoutResponse: false);
      return true;
    } catch (e) {
      print('Error sending data: $e');
      return false;
    }
  }
  
  // Send a command string to the device
  Future<bool> _sendCommand(String command) async {
    return await _sendData(utf8.encode('$command\r\n'));
  }
  
  // Configure the device with program settings
  Future<bool> sendProgramConfiguration(
    List<String> zones,
    int maxIntensity,
    int frequency,
    int pulseWidth,
  ) async {
    // Format: CONFIG:ZONES=zone1,zone2;FREQ=freq;PW=pw;MAX=max
    String zonesStr = zones.join(',');
    String command = '$CMD_CONFIG:ZONES=$zonesStr;FREQ=$frequency;PW=$pulseWidth;MAX=$maxIntensity';
    return await _sendCommand(command);
  }
  
  // Start the training program
  Future<bool> startTraining() async {
    return await _sendCommand(CMD_START);
  }
  
  // Pause the training program
  Future<bool> pauseTraining() async {
    return await _sendCommand(CMD_PAUSE);
  }
  
  // Resume the paused training program
  Future<bool> resumeTraining() async {
    return await _sendCommand(CMD_RESUME);
  }
  
  // Stop the training program
  Future<bool> stopTraining() async {
    return await _sendCommand(CMD_STOP);
  }
  
  // Update the intensity levels for each zone
  Future<bool> updateIntensities(Map<String, double> zoneIntensities) async {
    // Convert intensity values (0.0 to 1.0) to device values (0 to 100)
    Map<String, int> deviceIntensities = {};
    
    zoneIntensities.forEach((zone, intensity) {
      // Convert to integer percentage (0-100)
      deviceIntensities[zone] = (intensity * 100).round();
    });
    
    // Format: INTENSITY:zone1=level1;zone2=level2;...
    List<String> intensityParts = [];
    deviceIntensities.forEach((zone, level) {
      intensityParts.add('$zone=$level');
    });
    
    String command = '$CMD_INTENSITY:${intensityParts.join(';')}';
    return await _sendCommand(command);
  }
  
  // Send a raw custom command to the device
  Future<bool> sendCustomCommand(String command) async {
    return await _sendCommand(command);
  }
}