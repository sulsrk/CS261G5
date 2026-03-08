import 'package:flutter/material.dart';

/// Slider used to control simulation speed.
class SpeedSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const SpeedSlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final clampedValue = value.clamp(0.5, 3.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Simulation speed',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${clampedValue.toStringAsFixed(1)}x',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
        Slider(
          value: clampedValue,
          min: 0.5,
          max: 3.0,
          divisions: 10,
          label: '${clampedValue.toStringAsFixed(1)}x',
          onChanged: onChanged,
        ),
      ],
    );
  }
}

