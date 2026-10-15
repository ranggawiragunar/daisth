import 'package:flutter/material.dart';

import '../../../core/design_system/components/daisth_empty_state.dart';
import '../../../core/design_system/assets/daisth_assets.dart';
import '../../../core/localization/daisth_localizations.dart';

class RoutinesPlaceholderScreen extends StatelessWidget {
  const RoutinesPlaceholderScreen({this.bottomContentPadding = 0, super.key});

  final double bottomContentPadding;

  @override
  Widget build(BuildContext context) => DaisthEmptyState(
    imageAsset: DaisthAssets.emptyRoutines,
    bottomContentPadding: bottomContentPadding,
    title: DaisthLocalizations.text(
      context,
      id: 'Rutinitasmu akan ada di sini',
      en: 'Your routines will appear here',
    ),
    description: DaisthLocalizations.text(
      context,
      id: 'Kelola rutinitas harianmu dari satu tempat.',
      en: 'Manage your daily routines in one place.',
    ),
  );
}
