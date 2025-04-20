import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:probody_ems/domain/models/program_model.dart';

/// Widget that displays the human body SVG with highlighted muscle zones
class BodyZoneView extends StatefulWidget {
  final List<String> activeZones;
  final bool isFrontView;
  final Function(String)? onZoneTap;
  final Map<String, double> intensityLevels;

  const BodyZoneView({
    Key? key,
    required this.activeZones,
    required this.isFrontView,
    this.onZoneTap,
    required this.intensityLevels,
  }) : super(key: key);

  @override
  State<BodyZoneView> createState() => _BodyZoneViewState();
}

class _BodyZoneViewState extends State<BodyZoneView> {
  final Map<String, String> _zonePathIds = {
    // Front zones
    'chest_left': 'path_chest_left',
    'chest_right': 'path_chest_right',
    'abs_upper': 'path_abs_upper',
    'abs_lower': 'path_abs_lower',
    'arm_left': 'path_arm_front_left',
    'arm_right': 'path_arm_front_right',
    'leg_left_front': 'path_leg_front_left',
    'leg_right_front': 'path_leg_front_right',
    
    // Back zones
    'back_upper': 'path_back_upper',
    'back_lower': 'path_back_lower',
    'arm_left_back': 'path_arm_back_left',
    'arm_right_back': 'path_arm_back_right',
    'leg_left_back': 'path_leg_back_left',
    'leg_right_back': 'path_leg_back_right',
    'glutes': 'path_glutes',
  };

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth,
          height: constraints.maxWidth * 1.8, // Maintain aspect ratio
          child: Stack(
            children: [
              // Base SVG body image
              SvgPicture.asset(
                widget.isFrontView 
                  ? 'assets/images/body_front.svg'
                  : 'assets/images/body_back.svg',
                width: constraints.maxWidth,
                fit: BoxFit.contain,
              ),
              
              // Overlay for each active zone
              for (final zone in _getVisibleZones())
                _buildZoneOverlay(zone, constraints.maxWidth),
            ],
          ),
        );
      }
    );
  }
  
  List<String> _getVisibleZones() {
    final frontZones = [
      'chest_left', 'chest_right', 'abs_upper', 'abs_lower',
      'arm_left', 'arm_right', 'leg_left_front', 'leg_right_front'
    ];
    
    final backZones = [
      'back_upper', 'back_lower', 'arm_left_back', 'arm_right_back',
      'leg_left_back', 'leg_right_back', 'glutes'
    ];
    
    // Return only zones that should be visible in current view (front/back)
    return widget.activeZones.where((zone) {
      if (widget.isFrontView) {
        return frontZones.contains(zone);
      } else {
        return backZones.contains(zone);
      }
    }).toList();
  }
  
  Widget _buildZoneOverlay(String zone, double containerWidth) {
    // Get the SVG path ID for this zone
    final pathId = _zonePathIds[zone];
    if (pathId == null) return SizedBox.shrink();
    
    // Get intensity level for this zone (0.0 to 1.0)
    final intensity = widget.intensityLevels[zone] ?? 0.0;
    
    // Calculate color based on intensity (green to red gradient)
    // At 0% intensity: mild green
    // At 50% intensity: yellow
    // At 100% intensity: red
    Color zoneColor = _getColorForIntensity(intensity);
    
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => widget.onZoneTap?.call(zone),
        child: SvgPicture.asset(
          widget.isFrontView 
            ? 'assets/images/body_front_zones.svg'
            : 'assets/images/body_back_zones.svg',
          width: containerWidth,
          fit: BoxFit.contain,
          colorFilter: ColorFilter.mode(
            zoneColor.withOpacity(0.7), // Semi-transparent
            BlendMode.srcIn,
          ),
          clipBehavior: Clip.hardEdge,
        ),
      ),
    );
  }
  
  Color _getColorForIntensity(double intensity) {
    // Create a gradient from green to yellow to red
    if (intensity <= 0.5) {
      // Blend from green to yellow
      return Color.lerp(
        Colors.green,
        Colors.yellow,
        intensity * 2, // Scale 0-0.5 to 0-1
      )!;
    } else {
      // Blend from yellow to red
      return Color.lerp(
        Colors.yellow,
        Colors.red,
        (intensity - 0.5) * 2, // Scale 0.5-1 to 0-1
      )!;
    }
  }
  
  String _getZoneLabel(String zoneId) {
    // Convert zone IDs to human-readable labels
    final Map<String, String> zoneLabels = {
      'chest_left': 'Left Chest',
      'chest_right': 'Right Chest',
      'abs_upper': 'Upper Abs',
      'abs_lower': 'Lower Abs',
      'arm_left': 'Left Arm (Front)',
      'arm_right': 'Right Arm (Front)',
      'arm_left_back': 'Left Arm (Back)',
      'arm_right_back': 'Right Arm (Back)',
      'leg_left_front': 'Left Leg (Front)',
      'leg_right_front': 'Right Leg (Front)',
      'leg_left_back': 'Left Leg (Back)',
      'leg_right_back': 'Right Leg (Back)',
      'back_upper': 'Upper Back',
      'back_lower': 'Lower Back',
      'glutes': 'Glutes',
    };
    
    return zoneLabels[zoneId] ?? zoneId;
  }
}