import 'package:flutter/material.dart';

/// A restrained, non-interactive illustration used to support a feature.
class DaisthFeatureVisual extends StatelessWidget {
  const DaisthFeatureVisual({
    required this.asset,
    required this.height,
    this.width,
    this.alignment = Alignment.center,
    this.fit = BoxFit.contain,
    this.semanticLabel,
    super.key,
  });

  final String asset;
  final double height;
  final double? width;
  final Alignment alignment;
  final BoxFit fit;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Image.asset(
    asset,
    height: height,
    width: width,
    alignment: alignment,
    fit: fit,
    filterQuality: FilterQuality.high,
    isAntiAlias: true,
    semanticLabel: semanticLabel,
    errorBuilder: (_, _, _) => SizedBox(height: height, width: width),
  );
}
