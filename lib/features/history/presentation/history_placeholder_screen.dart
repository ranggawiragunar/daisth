import 'package:flutter/material.dart';

import '../../../core/design_system/components/istiqam_empty_state.dart';

class HistoryPlaceholderScreen extends StatelessWidget {
  const HistoryPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) => const IstiqamEmptyState(
    imageAsset: 'assets/illustrations/empty_history.png',
    title: 'Belum ada history',
    description:
        'Selesaikan routine untuk mulai melihat perjalanan konsistensimu.',
  );
}
