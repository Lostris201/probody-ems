import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:probody_ems/data/models/program.dart';
import 'package:probody_ems/data/repositories/program_repository.dart';
import 'package:probody_ems/data/repositories/user_repository.dart';
import 'package:probody_ems/presentation/widgets/common/loading_indicator.dart';
import 'package:probody_ems/presentation/widgets/training/body_model_widget.dart';
import 'package:probody_ems/presentation/widgets/training/intensity_slider.dart';
import 'package:probody_ems/services/bluetooth_service.dart';

class TrainingScreen extends StatefulWidget {
  final Program program;
  
  const TrainingScreen({
    Key? key,
    required this.program,
  }) : super(key: key);

  @override
  _TrainingScreenState createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  // Training state
  bool _isTrainingActive = false;
  int _currentPhaseIndex = 0;
  Duration _remainingTime = Duration.zero;
  Timer? _timer;
  
  // Settings
  bool _showFrontView = true;
  Map<String, double> _intensityLevels = {};
  double _masterIntensity = 0.5;  // 0.0 to 1.0
  
  // Services
  late BluetoothService _bluetoothService;
  late UserRepository _userRepository;
  late ProgramRepository _programRepository;
  
  @override
  void initState() {
    super.initState();
    
    _bluetoothService = context.read<BluetoothService>();
    _userRepository = context.read<UserRepository>();
    _programRepository = context.read<ProgramRepository>();
    
    // Initialize intensity levels for all zones in the program
    _resetIntensityLevels();
    
    // Set initial phase and timing
    _preparePhase(0);
  }
  
  @override
  void dispose() {
    _stopTraining();
    _timer?.cancel();
    super.dispose();
  }
  
  void _resetIntensityLevels() {
    // Reset all intensity levels to 0
    setState(() {
      _intensityLevels = {};
      for (final phase in widget.program.phases) {
        for (final zone in phase.targetZones) {
          _intensityLevels[zone.zoneId] = 0.0;
        }
      }
    });
  }
  
  void _preparePhase(int phaseIndex) {
    if (phaseIndex >= widget.program.phases.length) {
      // Training completed
      _stopTraining();
      _showTrainingCompletedDialog();
      return;
    }
    
    final phase = widget.program.phases[phaseIndex];
    
    // Set remaining time to phase duration
    setState(() {
      _currentPhaseIndex = phaseIndex;
      _remainingTime = Duration(seconds: phase.durationSeconds);
    });
  }
  
  void _startTraining() {
    setState(() {
      _isTrainingActive = true;
    });
    
    // Start timer
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds <= 0) {
        // Move to next phase
        _preparePhase(_currentPhaseIndex + 1);
        if (!_isTrainingActive) {
          timer.cancel();
        }
      } else {
        setState(() {
          _remainingTime = _remainingTime - Duration(seconds: 1);
        });
        
        // Update muscle intensities
        _updateMuscleIntensities();
      }
    });
    
    // Apply initial muscle intensities
    _updateMuscleIntensities();
    
    // Send start command to device
    _sendCommandToDevice("START");
  }
  
  void _pauseTraining() {
    setState(() {
      _isTrainingActive = false;
    });
    
    _timer?.cancel();
    
    // Send pause command to device
    _sendCommandToDevice("PAUSE");
  }
  
  void _stopTraining() {
    setState(() {
      _isTrainingActive = false;
    });
    
    _timer?.cancel();
    _resetIntensityLevels();
    
    // Send stop command to device
    _sendCommandToDevice("STOP");
  }
  
  void _updateMuscleIntensities() {
    final currentPhase = widget.program.phases[_currentPhaseIndex];
    
    // Calculate new intensity values based on the current phase settings and master intensity
    Map<String, double> newIntensities = Map.from(_intensityLevels);
    
    for (final zone in currentPhase.targetZones) {
      // Apply the master intensity multiplier to the zone's base intensity
      final adjustedIntensity = zone.intensity * _masterIntensity;
      newIntensities[zone.zoneId] = adjustedIntensity;
    }
    
    // Update state and send commands to device
    setState(() {
      _intensityLevels = newIntensities;
    });
    
    // Send intensity commands to the device
    _sendIntensityToDevice();
  }
  
  void _sendIntensityToDevice() {
    // Format: INTENSITY:[ZONE_ID]:[LEVEL]
    _intensityLevels.forEach((zoneId, level) {
      // Convert 0-1 scale to device scale (0-10)
      final deviceLevel = (level * 10).round();
      if (deviceLevel > 0) {
        _sendCommandToDevice("INTENSITY:$zoneId:$deviceLevel");
      }
    });
  }
  
  void _sendCommandToDevice(String command) {
    try {
      _bluetoothService.sendData(command);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Device communication error: $e'))
      );
    }
  }
  
  void _updateMasterIntensity(double newIntensity) {
    setState(() {
      _masterIntensity = newIntensity;
    });
    
    // Recalculate all zone intensities
    _updateMuscleIntensities();
  }
  
  Future<void> _showTrainingCompletedDialog() async {
    // Save training history
    try {
      final user = await _userRepository.getCurrentUser();
      if (user != null) {
        await _programRepository.saveTrainingHistory(
          userId: user.id,
          programId: widget.program.id,
          completedAt: DateTime.now(),
        );
      }
    } catch (e) {
      print('Error saving training history: $e');
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Training Completed'),
        content: Text(
          'Congratulations! You've completed "${widget.program.name}" training program.'
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Return to previous screen
            },
            child: Text('Done'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final currentPhase = widget.program.phases[_currentPhaseIndex];
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.program.name),
        actions: [
          IconButton(
            icon: Icon(Icons.favorite),
            onPressed: () async {
              try {
                await _programRepository.toggleFavorite(
                  programId: widget.program.id,
                );
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      widget.program.isFavorite
                          ? 'Removed from favorites'
                          : 'Added to favorites'
                    ),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating favorites'))
                );
              }
            },
            color: widget.program.isFavorite ? Colors.red : null,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Program info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Phase: ${currentPhase.name}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: 8),
                      Text(currentPhase.description),
                      SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: _currentPhaseIndex / widget.program.phases.length,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Phase ${_currentPhaseIndex + 1} of ${widget.program.phases.length}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 24),
              
              // Timer display
              Center(
                child: Column(
                  children: [
                    Text(
                      '${_remainingTime.inMinutes.toString().padLeft(2, '0')}:${(_remainingTime.inSeconds % 60).toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!_isTrainingActive)
                          ElevatedButton.icon(
                            icon: Icon(Icons.play_arrow),
                            label: Text(_timer == null ? 'Start' : 'Resume'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            onPressed: _startTraining,
                          )
                        else
                          ElevatedButton.icon(
                            icon: Icon(Icons.pause),
                            label: Text('Pause'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                            onPressed: _pauseTraining,
                          ),
                        SizedBox(width: 16),
                        ElevatedButton.icon(
                          icon: Icon(Icons.stop),
                          label: Text('Stop'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () {
                            _stopTraining();
                            // Ask for confirmation before leaving
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('End Training?'),
                                content: Text(
                                  'Are you sure you want to end this training session? Your progress will not be saved.'
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context); // Close dialog
                                      Navigator.pop(context); // Return to previous screen
                                    },
                                    child: Text('End Training'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 24),
              
              // Body model toggle
              BodyModelToggle(
                showFront: _showFrontView,
                onToggle: (showFront) {
                  setState(() {
                    _showFrontView = showFront;
                  });
                },
              ),
              
              SizedBox(height: 16),
              
              // Body visualization
              Center(
                child: Container(
                  height: 400,
                  child: BodyModelWidget(
                    activeZones: _intensityLevels,
                    showFront: _showFrontView,
                  ),
                ),
              ),
              
              SizedBox(height: 24),
              
              // Master intensity control
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Master Intensity',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: 8),
                      IntensitySlider(
                        value: _masterIntensity,
                        onChanged: _updateMasterIntensity,
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 24),
              
              // Active muscle zones
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active Muscle Zones',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: 16),
                      if (currentPhase.targetZones.isEmpty)
                        Text('No active zones in this phase.')
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: currentPhase.targetZones.length,
                          itemBuilder: (context, index) {
                            final zone = currentPhase.targetZones[index];
                            return ListTile(
                              title: Text(_getZoneName(zone.zoneId)),
                              subtitle: LinearProgressIndicator(
                                value: _intensityLevels[zone.zoneId] ?? 0,
                              ),
                              trailing: Text(
                                '${((_intensityLevels[zone.zoneId] ?? 0) * 100).round()}%',
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
  
  String _getZoneName(String zoneId) {
    // Convert zone IDs to human-readable names
    Map<String, String> zoneNames = {
      'ab_upper': 'Upper Abs',
      'ab_lower': 'Lower Abs',
      'chest_left': 'Left Chest',
      'chest_right': 'Right Chest',
      'shoulder_left': 'Left Shoulder',
      'shoulder_right': 'Right Shoulder',
      'bicep_left': 'Left Bicep',
      'bicep_right': 'Right Bicep',
      'quad_left': 'Left Quad',
      'quad_right': 'Right Quad',
      'upper_back_left': 'Left Upper Back',
      'upper_back_right': 'Right Upper Back',
      'lower_back_left': 'Left Lower Back',
      'lower_back_right': 'Right Lower Back',
      'tricep_left': 'Left Tricep',
      'tricep_right': 'Right Tricep',
      'glute_left': 'Left Glute',
      'glute_right': 'Right Glute',
      'hamstring_left': 'Left Hamstring',
      'hamstring_right': 'Right Hamstring',
      'calf_left': 'Left Calf',
      'calf_right': 'Right Calf',
    };
    
    return zoneNames[zoneId] ?? zoneId;
  }
}