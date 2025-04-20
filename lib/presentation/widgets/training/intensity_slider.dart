import 'package:flutter/material.dart';

class IntensitySlider extends StatelessWidget {
  final double value;
  final Function(double) onChanged;
  final int levels;
  
  const IntensitySlider({
    Key? key,
    required this.value,
    required this.onChanged,
    this.levels = 10,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Level: ${(value * levels).round()}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              '${(value * 100).round()}%',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
        SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _getTrackColor(value),
            thumbColor: _getTrackColor(value),
            inactiveTrackColor: Colors.grey[300],
            trackHeight: 8.0,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12.0),
            overlayColor: _getTrackColor(value).withAlpha(60),
            overlayShape: RoundSliderOverlayShape(overlayRadius: 20.0),
          ),
          child: Slider(
            value: value,
            min: 0.0,
            max: 1.0,
            divisions: levels,
            onChanged: onChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Weak',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Strong',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
  
  Color _getTrackColor(double value) {
    // Return different colors based on intensity level
    if (value < 0.3) {
      return Colors.green;
    } else if (value < 0.6) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}