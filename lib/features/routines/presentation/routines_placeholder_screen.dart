import 'package:flutter/material.dart';

import '../../../core/design_system/components/istiqam_empty_state.dart';

class RoutinesPlaceholderScreen extends StatelessWidget {
  const RoutinesPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) => const IstiqamEmptyState(
    imageAsset: 'assets/illustrations/empty_routines.png',
    title: 'Routine-mu akan ada di sini',
    description: 'Kelola rutinitas harianmu dari satu tempat.',
  );
}
