import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Widget that displays a front and back body model with active muscle zones
/// highlighted based on the current program and intensity levels
class BodyModelWidget extends StatefulWidget {
  final Map<String, double> activeZones;
  final bool showFront;
  
  const BodyModelWidget({
    Key? key,
    required this.activeZones,
    this.showFront = true,
  }) : super(key: key);

  @override
  _BodyModelWidgetState createState() => _BodyModelWidgetState();
}

class _BodyModelWidgetState extends State<BodyModelWidget> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Set up pulse animation for active zones
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)
    );
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return AspectRatio(
          aspectRatio: 0.5, // Body model aspect ratio
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Base body outline
              SvgPicture.asset(
                widget.showFront
                    ? 'assets/images/body_front_outline.svg'
                    : 'assets/images/body_back_outline.svg',
                fit: BoxFit.contain,
              ),
              
              // Active muscle zones - layer by layer according to intensity
              ...widget.activeZones.entries.map((entry) {
                return _buildMuscleZone(entry.key, entry.value);
              }).toList(),
            ],
          ),
        );
      }
    );
  }
  
  Widget _buildMuscleZone(String zoneId, double intensity) {
    // Skip if intensity is 0
    if (intensity <= 0) return SizedBox.shrink();
    
    // Determine which SVG to use based on current view and zone ID
    String assetPath = '';
    
    if (widget.showFront) {
      switch (zoneId) {
        case 'ab_upper':
          assetPath = 'assets/images/zones/front/ab_upper.svg';
          break;
        case 'ab_lower':
          assetPath = 'assets/images/zones/front/ab_lower.svg';
          break;
        case 'chest_left':
          assetPath = 'assets/images/zones/front/chest_left.svg';
          break;
        case 'chest_right':
          assetPath = 'assets/images/zones/front/chest_right.svg';
          break;
        case 'shoulder_left':
          assetPath = 'assets/images/zones/front/shoulder_left.svg';
          break;
        case 'shoulder_right':
          assetPath = 'assets/images/zones/front/shoulder_right.svg';
          break;
        case 'bicep_left':
          assetPath = 'assets/images/zones/front/bicep_left.svg';
          break;
        case 'bicep_right':
          assetPath = 'assets/images/zones/front/bicep_right.svg';
          break;
        case 'quad_left':
          assetPath = 'assets/images/zones/front/quad_left.svg';
          break;
        case 'quad_right':
          assetPath = 'assets/images/zones/front/quad_right.svg';
          break;
      }
    } else {
      switch (zoneId) {
        case 'upper_back_left':
          assetPath = 'assets/images/zones/back/upper_back_left.svg';
          break;
        case 'upper_back_right':
          assetPath = 'assets/images/zones/back/upper_back_right.svg';
          break;
        case 'lower_back_left':
          assetPath = 'assets/images/zones/back/lower_back_left.svg';
          break;
        case 'lower_back_right':
          assetPath = 'assets/images/zones/back/lower_back_right.svg';
          break;
        case 'tricep_left':
          assetPath = 'assets/images/zones/back/tricep_left.svg';
          break;
        case 'tricep_right':
          assetPath = 'assets/images/zones/back/tricep_right.svg';
          break;
        case 'glute_left':
          assetPath = 'assets/images/zones/back/glute_left.svg';
          break;
        case 'glute_right':
          assetPath = 'assets/images/zones/back/glute_right.svg';
          break;
        case 'hamstring_left':
          assetPath = 'assets/images/zones/back/hamstring_left.svg';
          break;
        case 'hamstring_right':
          assetPath = 'assets/images/zones/back/hamstring_right.svg';
          break;
        case 'calf_left':
          assetPath = 'assets/images/zones/back/calf_left.svg';
          break;
        case 'calf_right':
          assetPath = 'assets/images/zones/back/calf_right.svg';
          break;
      }
    }
    
    // If no matching SVG, return empty widget
    if (assetPath.isEmpty) {
      return SizedBox.shrink();
    }
    
    // Calculate color intensity based on intensity value and pulse animation
    double colorIntensity = intensity * _pulseAnimation.value;
    
    // Clamp to valid range
    colorIntensity = colorIntensity.clamp(0.0, 1.0);
    
    // Convert intensity to color (red intensity)
    Color zoneColor = Color.lerp(
      Colors.transparent, 
      Colors.red.withOpacity(0.9),
      colorIntensity,
    )!;
    
    return Positioned.fill(
      child: SvgPicture.asset(
        assetPath,
        fit: BoxFit.contain,
        colorFilter: ColorFilter.mode(
          zoneColor,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}

/// Widget for toggling between front and back view of the body model
class BodyModelToggle extends StatelessWidget {
  final bool showFront;
  final Function(bool) onToggle;
  
  const BodyModelToggle({
    Key? key,
    required this.showFront,
    required this.onToggle,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ToggleButtons(
          isSelected: [showFront, !showFront],
          onPressed: (index) {
            onToggle(index == 0);
          },
          borderRadius: BorderRadius.circular(8),
          selectedColor: Theme.of(context).colorScheme.primary,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text('Front'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text('Back'),
            ),
          ],
        ),
      ],
    );
  }
}