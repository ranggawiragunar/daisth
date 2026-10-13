import 'package:flutter/material.dart';

import '../../../core/design_system/components/daisth_empty_state.dart';

class HistoryPlaceholderScreen extends StatelessWidget {
  const HistoryPlaceholderScreen({this.bottomContentPadding = 0, super.key});

  final double bottomContentPadding;

  @override
  Widget build(BuildContext context) => DaisthEmptyState(
    imageAsset: 'assets/empty_states/empty_history_2048.png',
    bottomContentPadding: bottomContentPadding,
    title: 'Belum ada history',
    description:
        'Selesaikan routine untuk mulai melihat perjalanan konsistensimu.',
  );
}
