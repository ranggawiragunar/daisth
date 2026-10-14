import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../../core/design_system/components/daisth_surface.dart';
import '../../../../core/design_system/tokens/daisth_spacing.dart';
import '../../../../core/time/domain/models/calendar_day.dart';
import '../../../../core/localization/daisth_localizations.dart';
import '../../domain/models/daily_reflection.dart';
import '../../domain/models/reflection_rhythm.dart';
import '../../domain/repositories/reflection_repository.dart';

class ReflectionTodayCard extends StatefulWidget {
  const ReflectionTodayCard({
    required this.repository,
    required this.onOpen,
    super.key,
  });

  final ReflectionRepository repository;
  final VoidCallback onOpen;

  @override
  State<ReflectionTodayCard> createState() => _ReflectionTodayCardState();
}

class _ReflectionTodayCardState extends State<ReflectionTodayCard> {
  DailyReflection? _reflection;
  bool _loading = true;
  StreamSubscription<ReflectionChange>? _subscription;

  CalendarDay get _today => CalendarDay.fromDateTime(DateTime.now());

  @override
  void initState() {
    super.initState();
    _subscription = widget.repository.changes.listen((change) {
      if (change.day == _today) unawaited(_load());
    });
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final reflection = await widget.repository.getReflection(_today);
      if (!mounted) return;
      setState(() {
        _reflection = reflection;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: DaisthLocalizations.text(
        context,
        id: 'Refleksi Hari Ini. Buka refleksi harian.',
        en: 'Today’s reflection. Open daily reflection.',
      ),
      child: InkWell(
        onTap: widget.onOpen,
        borderRadius: BorderRadius.circular(20),
        child: DaisthSurface(
          style: DaisthSurfaceStyle.softPrimary,
          child: Row(
            children: [
              Icon(
                PhosphorIconsRegular.notepad,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: DaisthSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DaisthLocalizations.text(
                        context,
                        id: 'Refleksi Hari Ini',
                        en: 'Today’s Reflection',
                      ),
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: DaisthSpacing.xxs),
                    Text(
                      _loading
                          ? DaisthLocalizations.text(
                              context,
                              id: 'Memuat refleksi hari ini.',
                              en: 'Loading today’s reflection.',
                            )
                          : _reflection == null
                          ? DaisthLocalizations.text(
                              context,
                              id: 'Luangkan sebentar untuk melihat kembali ritmemu hari ini.',
                              en: 'Take a moment to reflect on how today felt.',
                            )
                          : '${_reflectionLabel(context, _reflection!.rhythm)} · ${DaisthLocalizations.text(context, id: 'Tersimpan', en: 'Saved')}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                PhosphorIconsRegular.caretRight,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _reflectionLabel(BuildContext context, ReflectionRhythm rhythm) =>
    switch (rhythm) {
      ReflectionRhythm.steady => DaisthLocalizations.text(
        context,
        id: 'Terasa mengalir',
        en: 'Felt steady',
      ),
      ReflectionRhythm.mixed => DaisthLocalizations.text(
        context,
        id: 'Naik turun',
        en: 'Up and down',
      ),
      ReflectionRhythm.heavy => DaisthLocalizations.text(
        context,
        id: 'Terasa berat',
        en: 'Felt heavy',
      ),
    };
