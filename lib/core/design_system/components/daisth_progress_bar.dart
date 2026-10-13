import 'package:flutter/material.dart';

class DaisthProgressBar extends StatelessWidget {
  const DaisthProgressBar({required this.value, this.height = 4, super.key})
    : assert(value >= 0 && value <= 1);

  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: value,
        minHeight: height,
        backgroundColor: colors.primary.withValues(alpha: 0.12),
        color: colors.primary,
      ),
    );
  }
}
