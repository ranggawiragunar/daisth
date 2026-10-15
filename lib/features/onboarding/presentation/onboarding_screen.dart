import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/components/daisth_button.dart';
import '../../../core/design_system/components/daisth_feature_visual.dart';
import '../../../core/design_system/components/daisth_notice.dart';
import '../../../core/design_system/components/daisth_notice_controller.dart';
import '../../../core/design_system/tokens/daisth_spacing.dart';
import '../../../core/localization/daisth_localizations.dart';
import '../../../app/router/route_paths.dart';
import '../../../core/design_system/assets/daisth_assets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    required this.completeOnboarding,
    required this.notices,
    super.key,
  });
  final Future<void> Function() completeOnboarding;
  final DaisthNoticeController notices;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pager = PageController();
  int _page = 0;
  bool _saving = false;

  static const _titles = [
    'Jaga ritme yang penting',
    'Rutinitas yang mengikuti harimu',
    'Catat tanpa menghakimi',
  ];
  static const _descriptions = [
    'Daisth menemani rutinitas harian dengan ruang yang tenang dan sederhana.',
    'Atur rutinitas yang dekat dengan waktu salat, buat kebiasaanmu sendiri, dan pilih pengingat saat kamu siap.',
    'Lihat kembali hari-harimu dan tulis refleksi. Tidak ada skor atau streak. Akun tetap pilihan.',
  ];

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.completeOnboarding();
      if (mounted) context.go(RoutePaths.today);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      widget.notices.show(
        context,
        type: DaisthNoticeType.error,
        title: DaisthLocalizations.text(
          context,
          id: 'Pengaturan belum dapat disimpan.',
          en: 'Settings could not be saved.',
        ),
        message: DaisthLocalizations.text(
          context,
          id: 'Coba lagi untuk melanjutkan.',
          en: 'Try again to continue.',
        ),
      );
    }
  }

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DaisthSpacing.screenHorizontal,
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _saving ? null : _finish,
                      child: Text(
                        DaisthLocalizations.text(
                          context,
                          id: 'Lewati',
                          en: 'Skip',
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pager,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 3,
                      itemBuilder: (context, index) => Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          DaisthFeatureVisual(
                            asset: switch (index) {
                              0 => DaisthAssets.onboardingIntro,
                              1 => DaisthAssets.onboardingRoutine,
                              _ => DaisthAssets.onboardingCalm,
                            },
                            height: index == 0 ? 220 : 176,
                          ),
                          const SizedBox(height: DaisthSpacing.xxxl),
                          Text(
                            DaisthLocalizations.text(
                              context,
                              id: _titles[index],
                              en: const [
                                'Keep a steady rhythm',
                                'Routines that fit your day',
                                'Reflect without judgment',
                              ][index],
                            ),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall,
                          ),
                          const SizedBox(height: DaisthSpacing.md),
                          Text(
                            DaisthLocalizations.text(
                              context,
                              id: _descriptions[index],
                              en: const [
                                'Daisth supports your daily routines with a calm and simple space.',
                                'Set routines around prayer times, create your own habits, and choose reminders when you are ready.',
                                'Look back on your days and write reflections. No scores or streaks. An account is optional.',
                              ][index],
                            ),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: index == _page ? 20 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: index == _page
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: DaisthSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: DaisthButton(
                      label: _page == 2
                          ? DaisthLocalizations.text(
                              context,
                              id: 'Mulai Daisth',
                              en: 'Get started',
                            )
                          : DaisthLocalizations.text(
                              context,
                              id: 'Lanjut',
                              en: 'Continue',
                            ),
                      onPressed: _saving
                          ? null
                          : () {
                              if (_page == 2) {
                                _finish();
                              } else {
                                setState(() => _page++);
                                _pager.animateToPage(
                                  _page,
                                  duration: const Duration(milliseconds: 240),
                                  curve: Curves.easeOut,
                                );
                              }
                            },
                    ),
                  ),
                  const SizedBox(height: DaisthSpacing.xl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
