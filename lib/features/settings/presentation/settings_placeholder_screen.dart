import 'package:flutter/material.dart';

import '../../../core/design_system/components/istiqam_empty_state.dart';

class SettingsPlaceholderScreen extends StatelessWidget {
  const SettingsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) => const IstiqamEmptyState(
    imageAsset: 'assets/empty_states/empty_settings_2048.png',
    title: 'Pengaturan segera hadir',
    description:
        'Lokasi, reminder, tampilan, dan preferensi lainnya akan tersedia di sini.',
  );
}
