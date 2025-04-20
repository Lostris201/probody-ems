import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:probody_ems/data/models/program.dart';
import 'package:probody_ems/data/models/device_info.dart';
import 'package:probody_ems/data/repositories/program_repository.dart';
import 'package:probody_ems/data/repositories/device_repository.dart';
import 'package:probody_ems/data/repositories/user_repository.dart';
import 'package:probody_ems/presentation/widgets/common/loading_indicator.dart';
import 'package:probody_ems/services/bluetooth_service.dart';
import 'package:probody_ems/constants/app_constants.dart';
import 'package:probody_ems/constants/localization_constants.dart';

class TrainingScreen extends StatefulWidget {
  final Program program;
  final DeviceInfo? device;

  const TrainingScreen({
    Key? key,
    required this.program,
    this.device,
  }) : super(key: key);

  @override
  _TrainingScreenState createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ProgramRepository _programRepository = ProgramRepository();
  final DeviceRepository _deviceRepository = DeviceRepository();
  final UserRepository _userRepository = UserRepository();
  final BluetoothService _bluetoothService = BluetoothService();
  
  bool _isLoading = true;
  bool _isSessionActive = false;
  bool _isPaused = false;
  bool _isConnected = false;
  int _batteryLevel = 0;
  int _currentIntensity = 0;
  int _maxIntensity = 30;
  String _errorMessage = '';
  Timer? _sessionTimer;
  int _elapsedSeconds = 0;
  int _totalSessionTime = 0;
  List<String> _activeZones = [];
  int _currentPhaseIndex = 0;
  StreamSubscription? _deviceSubscription;
  
  // Body zones that can be active in training
  final Map<String, GlobalKey> _zoneKeys = {};
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initialize();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _sessionTimer?.cancel();
    _deviceSubscription?.cancel();
    _bluetoothService.disconnect();
    super.dispose();
  }
  
  Future<void> _initialize() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Set total session time from program duration
      _totalSessionTime = widget.program.duration * 60; // Convert to seconds
      
      // Connect to device if available
      if (widget.device != null) {
        await _connectToDevice();
      }
      
      // Initialize zone keys for all possible zones
      AppConstants.muscleZones.forEach((zoneId, _) {
        _zoneKeys[zoneId] = GlobalKey();
      });
      
      // Set active zones from the first phase
      if (widget.program.phases.isNotEmpty) {
        _activeZones = widget.program.phases[0].zones;
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error initializing training: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _connectToDevice() async {
    try {
      bool connected = await _bluetoothService.connectToDevice(widget.device!.macAddress);
      
      if (connected) {
        setState(() {
          _isConnected = true;
          _batteryLevel = widget.device!.batteryLevel ?? 0;
        });
        
        // Listen for device data
        _deviceSubscription = _bluetoothService.deviceDataStream.listen((data) {
          if (data.containsKey('batteryLevel')) {
            setState(() {
              _batteryLevel = data['batteryLevel'];
            });
            
            // Update device battery in repository
            _deviceRepository.updateDeviceConnection(
              widget.device!.macAddress,
              DateTime.now(),
              _batteryLevel,
            );
          }
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to connect to device';
          _isConnected = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error: $e';
        _isConnected = false;
      });
    }
  }
  
  void _startSession() async {
    if (!_isConnected && widget.device != null) {
      _showAlert(LocalizationConstants.deviceNotConnected);
      return;
    }
    
    setState(() {
      _isSessionActive = true;
      _isPaused = false;
      _elapsedSeconds = 0;
      _currentPhaseIndex = 0;
      
      // Set active zones from the first phase
      if (widget.program.phases.isNotEmpty) {
        _activeZones = widget.program.phases[0].zones;
      }
    });
    
    // Start the session timer
    _sessionTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
        
        // Check if we need to move to the next phase
        if (_currentPhaseIndex < widget.program.phases.length - 1) {
          int currentPhaseDuration = widget.program.phases[_currentPhaseIndex].duration * 60;
          if (_elapsedSeconds >= currentPhaseDuration) {
            _currentPhaseIndex++;
            _activeZones = widget.program.phases[_currentPhaseIndex].zones;
            
            // Send command to device to change zones
            if (_isConnected) {
              _sendZoneCommand();
            }
          }
        }
        
        // End session if total time reached
        if (_elapsedSeconds >= _totalSessionTime) {
          _endSession();
        }
      });
    });
    
    // Send initial command to device
    if (_isConnected) {
      _sendZoneCommand();
    }
    
    // Save training history
    _saveTrainingHistory();
  }
  
  void _pauseSession() {
    setState(() {
      _isPaused = true;
    });
    
    _sessionTimer?.cancel();
    
    // Send pause command to device
    if (_isConnected) {
      _bluetoothService.sendCommand('PAUSE');
    }
  }
  
  void _resumeSession() {
    setState(() {
      _isPaused = false;
    });
    
    // Resume the timer
    _sessionTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
        
        // Check if we need to move to the next phase
        if (_currentPhaseIndex < widget.program.phases.length - 1) {
          int currentPhaseDuration = widget.program.phases[_currentPhaseIndex].duration * 60;
          if (_elapsedSeconds >= currentPhaseDuration) {
            _currentPhaseIndex++;
            _activeZones = widget.program.phases[_currentPhaseIndex].zones;
            
            // Send command to device to change zones
            if (_isConnected) {
              _sendZoneCommand();
            }
          }
        }
        
        // End session if total time reached
        if (_elapsedSeconds >= _totalSessionTime) {
          _endSession();
        }
      });
    });
    
    // Send resume command to device
    if (_isConnected) {
      _bluetoothService.sendCommand('RESUME');
      _sendZoneCommand();
    }
  }
  
  void _endSession() {
    _sessionTimer?.cancel();
    
    setState(() {
      _isSessionActive = false;
      _isPaused = false;
      _currentIntensity = 0;
    });
    
    // Send stop command to device
    if (_isConnected) {
      _bluetoothService.sendCommand('STOP');
    }
    
    // Show completion dialog
    _showCompletionDialog();
  }
  
  void _sendZoneCommand() {
    if (!_isConnected) return;
    
    // Format: ZONES:<zone1>,<zone2>,...|INTENSITY:<level>
    String command = 'ZONES:${_activeZones.join(',')}|INTENSITY:$_currentIntensity';
    _bluetoothService.sendCommand(command);
  }
  
  Future<void> _saveTrainingHistory() async {
    try {
      final userId = _userRepository.currentUser?.uid;
      if (userId != null) {
        await _programRepository.saveTrainingHistory(
          userId: userId,
          programId: widget.program.id,
          duration: _totalSessionTime ~/ 60, // Convert seconds to minutes
          intensity: _currentIntensity,
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      print('Error saving training history: $e');
    }
  }
  
  void _increaseIntensity() {
    if (_currentIntensity < _maxIntensity) {
      setState(() {
        _currentIntensity++;
      });
      
      if (_isConnected) {
        _sendZoneCommand();
      }
    }
  }
  
  void _decreaseIntensity() {
    if (_currentIntensity > 0) {
      setState(() {
        _currentIntensity--;
      });
      
      if (_isConnected) {
        _sendZoneCommand();
      }
    }
  }
  
  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocalizationConstants.alert),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LocalizationConstants.ok),
          ),
        ],
      ),
    );
  }
  
  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocalizationConstants.trainingComplete),
        content: Text(
          '${LocalizationConstants.youCompletedProgram} ${widget.program.name}!\n'
          '${LocalizationConstants.duration}: ${_formatTime(_elapsedSeconds)}\n'
          '${LocalizationConstants.intensity}: $_currentIntensity/${_maxIntensity}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Return to previous screen
            },
            child: Text(LocalizationConstants.finish),
          ),
        ],
      ),
    );
  }
  
  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.program.name)),
        body: const LoadingIndicator(message: 'Preparing training session...'),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.program.name),
        actions: [
          if (_isConnected)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Row(
                children: [
                  Icon(Icons.bluetooth_connected, color: Colors.green),
                  SizedBox(width: 4),
                  Text('$_batteryLevel%'),
                ],
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: LocalizationConstants.front),
            Tab(text: LocalizationConstants.back),
          ],
        ),
      ),
      body: Column(
        children: [
          // Error message if any
          if (_errorMessage.isNotEmpty)
            Container(
              color: Colors.red.shade100,
              padding: const EdgeInsets.all(8.0),
              width: double.infinity,
              child: Text(
                _errorMessage,
                style: TextStyle(color: Colors.red.shade900),
                textAlign: TextAlign.center,
              ),
            ),
          
          // Training timer and phase info
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${LocalizationConstants.time}: ${_formatTime(_elapsedSeconds)} / ${_formatTime(_totalSessionTime)}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (widget.program.phases.length > 1)
                      Text(
                        '${LocalizationConstants.phase}: ${_currentPhaseIndex + 1}/${widget.program.phases.length}',
                        style: TextStyle(fontSize: 14),
                      ),
                  ],
                ),
                Text(
                  '${LocalizationConstants.intensity}: $_currentIntensity',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          
          // Body visualization with active zones
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Front view
                _buildBodyView('assets/images/body_front.svg', isBack: false),
                
                // Back view
                _buildBodyView('assets/images/body_back.svg', isBack: true),
              ],
            ),
          ),
          
          // Control buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Intensity controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _isSessionActive && !_isPaused ? _decreaseIntensity : null,
                      child: Icon(Icons.remove),
                      style: ElevatedButton.styleFrom(
                        shape: CircleBorder(),
                        padding: EdgeInsets.all(16),
                      ),
                    ),
                    SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isSessionActive && !_isPaused ? _increaseIntensity : null,
                      child: Icon(Icons.add),
                      style: ElevatedButton.styleFrom(
                        shape: CircleBorder(),
                        padding: EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                
                // Session control buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (!_isSessionActive)
                      ElevatedButton.icon(
                        onPressed: _startSession,
                        icon: Icon(Icons.play_arrow),
                        label: Text(LocalizationConstants.start),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      )
                    else if (_isPaused)
                      ElevatedButton.icon(
                        onPressed: _resumeSession,
                        icon: Icon(Icons.play_arrow),
                        label: Text(LocalizationConstants.resume),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: _pauseSession,
                        icon: Icon(Icons.pause),
                        label: Text(LocalizationConstants.pause),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    
                    if (_isSessionActive)
                      ElevatedButton.icon(
                        onPressed: _endSession,
                        icon: Icon(Icons.stop),
                        label: Text(LocalizationConstants.stop),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          backgroundColor: Colors.red,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBodyView(String assetPath, {required bool isBack}) {
    return Stack(
      children: [
        // Body SVG
        Center(
          child: SvgPicture.asset(
            assetPath,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        
        // Highlight active zones
        ..._activeZones.map((zoneId) {
          // Skip zones that don't belong to this view (front/back)
          bool zoneBelongsToView = AppConstants.muscleZones[zoneId]?.contains(isBack ? 'back' : 'front') ?? false;
          if (!zoneBelongsToView) return SizedBox();
          
          // Get zone position and dimensions
          final zoneData = AppConstants.muscleZonePositions[zoneId];
          if (zoneData == null) return SizedBox();
          
          Map<String, double> position = isBack ? zoneData['back'] : zoneData['front'];
          
          return Positioned(
            left: position['left'],
            top: position['top'],
            width: position['width'],
            height: position['height'],
            child: Container(
              key: _zoneKeys[zoneId],
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red, width: 2),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}