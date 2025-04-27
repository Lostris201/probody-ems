import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BLEService {
  static final BLEService _instance = BLEService._internal();
  factory BLEService() => _instance;
  BLEService._internal();

  final FlutterBluePlus _flutterBlue = FlutterBluePlus.instance;
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _notifyCharacteristic;
  
  final _deviceStateController = StreamController<BluetoothDeviceState>.broadcast();
  Stream<BluetoothDeviceState> get deviceState => _deviceStateController.stream;

  // HM-10 BLE Service and Characteristic UUIDs
  static const String serviceUUID = "FFE0";
  static const String characteristicUUID = "FFE1";

  bool get isConnected => _connectedDevice != null;

  Future<bool> initialize() async {
    try {
      // Check if Bluetooth is available and turned on
      if (await _flutterBlue.isAvailable == false) {
        throw Exception("Bluetooth is not available on this device");
      }

      final state = await _flutterBlue.state.first;
      if (state != BluetoothState.on) {
        await _flutterBlue.turnOn();
      }

      return true;
    } catch (e) {
      print("BLE initialization error: $e");
      return false;
    }
  }

  Future<List<ScanResult>> scanForDevices({Duration timeout = const Duration(seconds: 4)}) async {
    if (!await initialize()) {
      throw Exception("Failed to initialize Bluetooth");
    }

    final completer = Completer<List<ScanResult>>();
    final devices = <ScanResult>[];

    _flutterBlue.scanResults.listen((results) {
      devices.clear();
      for (ScanResult result in results) {
        if (result.device.name.isNotEmpty && 
            result.device.name.toLowerCase().contains('hm-10')) {
          devices.add(result);
        }
      }
    });

    await _flutterBlue.startScan(timeout: timeout);
    await _flutterBlue.stopScan();

    return devices;
  }

  Future<bool> connect(BluetoothDevice device) async {
    try {
      await device.connect(autoConnect: false, timeout: const Duration(seconds: 10));
      _connectedDevice = device;

      device.state.listen((state) {
        _deviceStateController.add(state);
        if (state == BluetoothDeviceState.disconnected) {
          _connectedDevice = null;
          _writeCharacteristic = null;
          _notifyCharacteristic = null;
        }
      });

      // Discover services
      final services = await device.discoverServices();
      final service = services.firstWhere(
        (s) => s.uuid.toString().toUpperCase().contains(serviceUUID),
      );

      // Get characteristics
      _writeCharacteristic = service.characteristics.firstWhere(
        (c) => c.uuid.toString().toUpperCase().contains(characteristicUUID),
      );

      _notifyCharacteristic = _writeCharacteristic;
      await _notifyCharacteristic?.setNotifyValue(true);

      // Listen for notifications
      _notifyCharacteristic?.onValueChanged.listen((value) {
        _handleNotification(value);
      });

      return true;
    } catch (e) {
      print("Connection error: $e");
      return false;
    }
  }

  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.disconnect();
      } catch (e) {
        print("Disconnection error: $e");
      }
    }
  }

  // Command implementations based on the documentation
  Future<bool> setMasterCurrent(int percentage) async {
    if (percentage < 0 || percentage > 100) {
      throw ArgumentError("Percentage must be between 0 and 100");
    }
    return _sendCommand("<P$percentage>");
  }

  Future<bool> setZoneCurrent(int zoneId, int percentage) async {
    if (zoneId < 1 || zoneId > 8) {
      throw ArgumentError("Zone ID must be between 1 and 8");
    }
    if (percentage < 0 || percentage > 100) {
      throw ArgumentError("Percentage must be between 0 and 100");
    }
    return _sendCommand("<Z$zoneId,$percentage>");
  }

  Future<bool> resetAllValues() async {
    return _sendCommand("<Y>");
  }

  Future<bool> pause() async {
    return _sendCommand("<G0>");
  }

  Future<bool> stop() async {
    return _sendCommand("<G0>");
  }

  Future<bool> setLED(bool on) async {
    return _sendCommand(on ? "<C1>" : "<C0>");
  }

  Future<bool> setBuzzer(bool on) async {
    return _sendCommand(on ? "<B1>" : "<B0>");
  }

  Future<bool> startProgram({
    required int frequency,
    required int waveWidth,
    required int breakDuration,
    required int totalDuration,
    required int mode,
  }) async {
    return _sendCommand(
      "<N$frequency,$waveWidth,$breakDuration,$totalDuration,$mode>"
    );
  }

  Future<bool> queryDeviceStatus() async {
    return _sendCommand("<!u0>");
  }

  Future<bool> _sendCommand(String command) async {
    if (_writeCharacteristic == null) {
      throw Exception("Device not connected or characteristic not found");
    }

    try {
      final data = utf8.encode(command);
      await _writeCharacteristic!.write(data, withoutResponse: false);
      return true;
    } catch (e) {
      print("Command error: $e");
      return false;
    }
  }

  void _handleNotification(List<int> value) {
    final response = utf8.decode(value);
    // TODO: Implement response handling based on the device's protocol
    print("Received from device: $response");
  }

  void dispose() {
    _deviceStateController.close();
  }

  // DEBUG: BLE bağlantı ve komut test fonksiyonu
  Future<void> debugTestBLE(BluetoothDevice device) async {
    print('BLE debug test başlıyor...');
    final connected = await connect(device);
    print('Bağlantı: $connected');
    if (!connected) return;
    print('Master akım ayarı: ' + (await setMasterCurrent(10)).toString());
    print('Bölge 1 akım ayarı: ' + (await setZoneCurrent(1, 20)).toString());
    print('LED aç: ' + (await setLED(true)).toString());
    print('Buzzer aç: ' + (await setBuzzer(true)).toString());
    print('Başlat komutu: ' + (await startProgram(frequency: 175, waveWidth: 85, breakDuration: 0, totalDuration: 10000, mode: 1)).toString());
    print('Durum sorgu: ' + (await queryDeviceStatus()).toString());
    await disconnect();
    print('BLE debug test bitti.');
  }
} 
