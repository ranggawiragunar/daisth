import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../../core/design_system/components/daisth_surface.dart';
import '../../../../core/design_system/tokens/daisth_spacing.dart';
import '../../../../core/time/domain/models/calendar_day.dart';
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
      label: 'Refleksi Hari Ini. Buka refleksi harian.',
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
                      'Refleksi Hari Ini',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: DaisthSpacing.xxs),
                    Text(
                      _loading
                          ? 'Memuat refleksi hari ini.'
                          : _reflection == null
                          ? 'Luangkan sebentar untuk melihat kembali ritmemu hari ini.'
                          : '${_reflectionLabel(_reflection!.rhythm)} · Tersimpan',
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

String _reflectionLabel(ReflectionRhythm rhythm) => switch (rhythm) {
  ReflectionRhythm.steady => 'Terasa mengalir',
  ReflectionRhythm.mixed => 'Naik turun',
  ReflectionRhythm.heavy => 'Terasa berat',
};
