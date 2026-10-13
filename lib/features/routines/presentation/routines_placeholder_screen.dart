import 'package:flutter/material.dart';

import '../../../core/design_system/components/daisth_empty_state.dart';

class RoutinesPlaceholderScreen extends StatelessWidget {
  const RoutinesPlaceholderScreen({this.bottomContentPadding = 0, super.key});

  final double bottomContentPadding;

  @override
  Widget build(BuildContext context) => DaisthEmptyState(
    imageAsset: 'assets/empty_states/empty_routines_2048.png',
    bottomContentPadding: bottomContentPadding,
    title: 'Routine-mu akan ada di sini',
    description: 'Kelola rutinitas harianmu dari satu tempat.',
  );
}
