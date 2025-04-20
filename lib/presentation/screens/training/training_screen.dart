import 'dart:async';

import 'package:flutter/material.dart';
import 'package:probody_ems/constants/localization_constants.dart';
import 'package:probody_ems/domain/models/program_model.dart';
import 'package:probody_ems/presentation/widgets/common/loading_indicator.dart';
import 'package:probody_ems/presentation/widgets/training/body_zone_view.dart';
import 'package:probody_ems/services/bluetooth_service.dart';
import 'package:wakelock/wakelock.dart';

class TrainingScreen extends StatefulWidget {
  final ProgramModel program;
  
  const TrainingScreen({
    Key? key,
    required this.program,
  }) : super(key: key);

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  bool _isFrontView = true;
  bool _isTrainingActive = false;
  int _currentTimeRemaining = 0;
  int _totalSessionTime = 0;
  late Timer _timer;
  Map<String, double> _zoneIntensities = {};
  bool _isPaused = false;
  bool _isConnecting = true;
  String? _errorMessage;
  
  final BluetoothService _bluetoothService = BluetoothService();
  
  @override
  void initState() {
    super.initState();
    // Prevent screen from turning off during training
    Wakelock.enable();
    
    // Initialize zone intensities with 0
    for (var zone in widget.program.targetZones) {
      _zoneIntensities[zone] = 0.0;
    }
    
    // Connect to the device and prepare for training
    _connectToDevice();
    
    // Calculate total session time
    _totalSessionTime = widget.program.duration * 60; // convert to seconds
  }
  
  @override
  void dispose() {
    // Allow screen to turn off when leaving this screen
    Wakelock.disable();
    
    // Cancel the timer if it's active
    if (_isTrainingActive) {
      _timer.cancel();
    }
    
    // Disconnect from the device when leaving
    _stopTraining();
    _bluetoothService.disconnect();
    
    super.dispose();
  }
  
  Future<void> _connectToDevice() async {
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });
    
    try {
      final connected = await _bluetoothService.connectToLastDevice();
      
      if (!connected) {
        setState(() {
          _errorMessage = LocalizationConstants.deviceConnectionFailed;
          _isConnecting = false;
        });
        return;
      }
      
      // Configure the device with program settings
      await _configureDevice();
      
      setState(() {
        _isConnecting = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isConnecting = false;
      });
    }
  }
  
  Future<void> _configureDevice() async {
    try {
      // Send program configuration to the device
      await _bluetoothService.sendProgramConfiguration(
        widget.program.targetZones,
        widget.program.maxIntensity,
        widget.program.frequency,
        widget.program.pulseWidth,
      );
    } catch (e) {
      setState(() {
        _errorMessage = LocalizationConstants.deviceConfigurationFailed;
      });
    }
  }
  
  void _startTraining() {
    if (_errorMessage != null) return;
    
    _bluetoothService.startTraining();
    
    setState(() {
      _isTrainingActive = true;
      _isPaused = false;
      _currentTimeRemaining = _totalSessionTime;
    });
    
    // Start timer to count down the remaining time
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_isPaused) return;
      
      setState(() {
        if (_currentTimeRemaining > 0) {
          _currentTimeRemaining--;
          
          // Gradually increase intensity over time
          if (_currentTimeRemaining % 10 == 0) { // Every 10 seconds
            _updateZoneIntensities();
          }
        } else {
          _stopTraining();
          timer.cancel();
        }
      });
    });
  }
  
  void _pauseTraining() {
    _bluetoothService.pauseTraining();
    
    setState(() {
      _isPaused = true;
    });
  }
  
  void _resumeTraining() {
    _bluetoothService.resumeTraining();
    
    setState(() {
      _isPaused = false;
    });
  }
  
  void _stopTraining() {
    if (!_isTrainingActive) return;
    
    _bluetoothService.stopTraining();
    
    setState(() {
      _isTrainingActive = false;
      _isPaused = false;
      
      // Reset zone intensities
      for (var zone in _zoneIntensities.keys) {
        _zoneIntensities[zone] = 0.0;
      }
    });
    
    if (_timer.isActive) {
      _timer.cancel();
    }
  }
  
  void _updateZoneIntensities() {
    // Calculate progress (0 to 1)
    final progress = 1 - (_currentTimeRemaining / _totalSessionTime);
    
    // Update intensities based on current progress
    for (var zone in widget.program.targetZones) {
      // Maximum intensity is determined by program settings
      final maxZoneIntensity = widget.program.maxIntensity / 100.0;
      
      // Ramp up intensity to max level by 50% of the time, then maintain
      double newIntensity;
      if (progress < 0.2) {
        // Warmup phase (0-20% of session)
        newIntensity = maxZoneIntensity * (progress / 0.2) * 0.7;
      } else if (progress < 0.8) {
        // Main training phase (20-80% of session)
        newIntensity = maxZoneIntensity;
      } else {
        // Cool down phase (80-100% of session)
        newIntensity = maxZoneIntensity * (1 - ((progress - 0.8) / 0.2));
      }
      
      _zoneIntensities[zone] = newIntensity;
    }
    
    // Send updated intensities to the device
    _bluetoothService.updateIntensities(_zoneIntensities);
  }
  
  void _toggleBodyView() {
    setState(() {
      _isFrontView = !_isFrontView;
    });
  }
  
  void _handleZoneTap(String zoneId) {
    if (!_isTrainingActive || _isPaused) return;
    
    // When user taps a zone, reduce its intensity by 20% (with min of 0)
    if (_zoneIntensities.containsKey(zoneId)) {
      setState(() {
        final currentIntensity = _zoneIntensities[zoneId] ?? 0;
        final newIntensity = (currentIntensity - 0.2).clamp(0.0, 1.0);
        _zoneIntensities[zoneId] = newIntensity;
      });
      
      // Send updated intensities to the device
      _bluetoothService.updateIntensities(_zoneIntensities);
    }
  }
  
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isConnecting) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.program.name),
        ),
        body: LoadingIndicator(
          message: LocalizationConstants.connectingToDevice,
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.program.name),
        actions: [
          IconButton(
            icon: Icon(Icons.swap_horiz),
            onPressed: _toggleBodyView,
            tooltip: LocalizationConstants.toggleBodyView,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_errorMessage != null)
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.red.shade100,
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade800),
                    ),
                  ),
                ],
              ),
            ),
          
          // Status bar showing time remaining and progress
          Container(
            padding: EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Time remaining
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocalizationConstants.timeRemaining,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      _formatTime(_currentTimeRemaining),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
                
                // Progress indicator
                if (_isTrainingActive)
                  Container(
                    width: 120,
                    child: LinearProgressIndicator(
                      value: 1 - (_currentTimeRemaining / _totalSessionTime),
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Body visualization
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: BodyZoneView(
                  activeZones: widget.program.targetZones,
                  isFrontView: _isFrontView,
                  onZoneTap: _isTrainingActive ? _handleZoneTap : null,
                  intensityLevels: _zoneIntensities,
                ),
              ),
            ),
          ),
          
          // Control buttons
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (!_isTrainingActive)
                  ElevatedButton.icon(
                    icon: Icon(Icons.play_arrow),
                    label: Text(LocalizationConstants.startTraining),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: _errorMessage == null ? _startTraining : null,
                  )
                else
                  Row(
                    children: [
                      if (_isPaused)
                        ElevatedButton.icon(
                          icon: Icon(Icons.play_arrow),
                          label: Text(LocalizationConstants.resume),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onPressed: _resumeTraining,
                        )
                      else
                        ElevatedButton.icon(
                          icon: Icon(Icons.pause),
                          label: Text(LocalizationConstants.pause),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.secondary,
                            foregroundColor: Theme.of(context).colorScheme.onSecondary,
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onPressed: _pauseTraining,
                        ),
                      SizedBox(width: 16),
                      ElevatedButton.icon(
                        icon: Icon(Icons.stop),
                        label: Text(LocalizationConstants.stop),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onPressed: _stopTraining,
                      ),
                    ],
                  ),
              ],
            ),
          ),
          
          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}