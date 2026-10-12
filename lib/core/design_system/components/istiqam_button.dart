import 'package:flutter/material.dart';

import '../tokens/istiqam_radius.dart';
import '../tokens/istiqam_spacing.dart';

enum IstiqamButtonStyle { primary, secondary, outline, text }

class IstiqamButton extends StatelessWidget {
  const IstiqamButton({
    required this.label,
    required this.onPressed,
    this.style = IstiqamButtonStyle.primary,
    this.compact = false,
    this.icon,
    this.labelFontSize,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IstiqamButtonStyle style;
  final bool compact;
  final IconData? icon;
  final double? labelFontSize;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final height = compact ? 44.0 : 52.0;
    final child = icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: IstiqamSpacing.sm),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(IstiqamRadius.large),
    );
    final textStyle = Theme.of(
      context,
    ).textTheme.labelLarge?.copyWith(fontSize: labelFontSize);

    return switch (style) {
      IstiqamButtonStyle.primary => SizedBox(
        height: height,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
            textStyle: textStyle,
            shape: shape,
            padding: const EdgeInsets.symmetric(horizontal: IstiqamSpacing.xl),
            minimumSize: Size(44, height),
          ),
          child: child,
        ),
      ),
      IstiqamButtonStyle.secondary => SizedBox(
        height: height,
        child: FilledButton.tonal(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            foregroundColor: colors.primary,
            textStyle: textStyle,
            shape: shape,
            padding: const EdgeInsets.symmetric(horizontal: IstiqamSpacing.xl),
            minimumSize: Size(44, height),
          ),
          child: child,
        ),
      ),
      IstiqamButtonStyle.outline => SizedBox(
        height: height,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.primary,
            textStyle: textStyle,
            shape: shape,
            side: BorderSide(color: colors.outline),
            padding: const EdgeInsets.symmetric(horizontal: IstiqamSpacing.xl),
            minimumSize: Size(44, height),
          ),
          child: child,
        ),
      ),
      IstiqamButtonStyle.text => SizedBox(
        height: height,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: colors.primary,
            textStyle: textStyle,
            shape: shape,
            padding: const EdgeInsets.symmetric(horizontal: IstiqamSpacing.lg),
            minimumSize: Size(44, height),
          ),
          child: child,
        ),
      ),
    };
  }
}
