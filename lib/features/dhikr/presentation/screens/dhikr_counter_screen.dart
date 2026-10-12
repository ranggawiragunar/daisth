import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../core/design_system/components/istiqam_button.dart';
import '../../../../core/design_system/tokens/istiqam_spacing.dart';
import '../../../reader/presentation/widgets/reader_typography.dart';
import '../../domain/models/dhikr_item.dart';
import '../../domain/models/dhikr_sequence.dart';
import '../view_models/dhikr_counter_view_model.dart';
import '../widgets/dhikr_count_surface.dart';
import '../widgets/dhikr_sequence_progress.dart';

class DhikrCounterScreen extends StatefulWidget {
  const DhikrCounterScreen({
    required this.routineId,
    required this.sequence,
    super.key,
  });

  final String routineId;
  final DhikrSequence sequence;

  @override
  State<DhikrCounterScreen> createState() => _DhikrCounterScreenState();
}

class _DhikrCounterScreenState extends State<DhikrCounterScreen> {
  late final DhikrCounterViewModel _viewModel;
  bool _exitDialogOpen = false;
  bool _allowExit = false;

  @override
  void initState() {
    super.initState();
    _viewModel = DhikrCounterViewModel(widget.sequence)
      ..addListener(_onViewModelChanged);
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _viewModel
      ..removeListener(_onViewModelChanged)
      ..dispose();
    super.dispose();
  }

  void _increment() {
    if (_viewModel.isCompleted) return;
    final previousIndex = _viewModel.currentItemIndex;
    _viewModel.increment();
    if (_viewModel.isCompleted) {
      HapticFeedback.mediumImpact();
    } else if (_viewModel.currentItemIndex != previousIndex) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.selectionClick();
    }
  }

  void _undo() {
    if (!_viewModel.canUndo) return;
    _viewModel.undo();
    HapticFeedback.selectionClick();
  }

  Future<void> _resetSession() async {
    if (!_viewModel.hasProgress) return;
    final reset = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset sesi?'),
        content: const Text('Hitungan sesi ini akan kembali ke awal.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Reset sesi'),
          ),
        ],
      ),
    );
    if (!mounted || reset != true) return;
    _viewModel.reset();
  }

  Future<void> _confirmExit() async {
    if (_exitDialogOpen || !_viewModel.hasProgress || _viewModel.isCompleted) {
      return;
    }
    _exitDialogOpen = true;
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar dari sesi?'),
        content: const Text('Progress dzikir sesi ini belum disimpan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Lanjut Dzikir'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    _exitDialogOpen = false;
    if (!mounted || shouldExit != true) return;
    setState(() => _allowExit = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.canPop()) context.pop(false);
    });
  }

  void _requestBack() {
    if (context.canPop()) {
      context.pop(false);
    } else {
      context.go(RoutePaths.routineDetail(widget.routineId));
    }
  }

  void _finish() => context.pop(true);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = _viewModel.currentItem;
    final completed = _viewModel.isCompleted;
    return PopScope<Object?>(
      canPop: _allowExit || !_viewModel.hasProgress || completed,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Kembali',
            onPressed: _requestBack,
            icon: const Icon(PhosphorIconsRegular.arrowLeft),
          ),
          title: Text('Dzikir', style: theme.textTheme.titleMedium),
          actions: [
            PopupMenuButton<String>(
              tooltip: 'Pilihan sesi',
              onSelected: (value) {
                if (value == 'reset') _resetSession();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'reset', child: Text('Reset sesi')),
              ],
              icon: const Icon(PhosphorIconsRegular.dotsThreeVertical),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              IstiqamSpacing.xl,
              IstiqamSpacing.md,
              IstiqamSpacing.xl,
              IstiqamSpacing.section,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: completed
                    ? _buildCompletedState(context)
                    : _buildActiveState(context, item),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveState(BuildContext context, DhikrItem item) {
    final theme = Theme.of(context);
    final sequence = widget.sequence;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(sequence.title, style: theme.textTheme.titleLarge),
        const SizedBox(height: IstiqamSpacing.xxs),
        Text(
          sequence.context,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: IstiqamSpacing.xxs),
        Text(
          sequence.sourceLabel,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: IstiqamSpacing.xl),
        DhikrSequenceProgress(
          currentItemIndex: _viewModel.currentItemIndex,
          completedItemCount: _viewModel.completedItemCount,
          itemCount: sequence.items.length,
          isCompleted: false,
        ),
        const SizedBox(height: IstiqamSpacing.xxl),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: Column(
            key: ValueKey(item.id),
            children: [
              Text(item.title, style: theme.textTheme.titleMedium),
              const SizedBox(height: IstiqamSpacing.md),
              SelectableText(
                item.arabic,
                key: const ValueKey('dhikr-arabic'),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: ReaderTypography.arabic(
                  context,
                  item.id == 'tahlil-closing' ? 0.8 : 1,
                ),
              ),
              const SizedBox(height: IstiqamSpacing.sm),
              Text(
                item.transliteration,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: IstiqamSpacing.xl),
        DhikrCountSurface(
          item: item,
          count: _viewModel.currentItemCount,
          onTap: _increment,
        ),
        const SizedBox(height: IstiqamSpacing.xs),
        Align(
          alignment: Alignment.center,
          child: TextButton.icon(
            key: const ValueKey('dhikr-undo'),
            onPressed: _viewModel.canUndo ? _undo : null,
            icon: const Icon(PhosphorIconsRegular.arrowCounterClockwise),
            label: const Text('Undo count'),
            style: TextButton.styleFrom(
              minimumSize: const Size(44, 44),
              foregroundColor: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedState(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: IstiqamSpacing.xl),
        Icon(PhosphorIconsRegular.checkCircle, size: 42, color: colors.primary),
        const SizedBox(height: IstiqamSpacing.md),
        Text(
          'Dzikir selesai',
          key: const ValueKey('dhikr-completed-title'),
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: IstiqamSpacing.xs),
        Text(
          '${_viewModel.totalCount} hitungan selesai',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: IstiqamSpacing.xxl),
        DhikrSequenceProgress(
          currentItemIndex: _viewModel.currentItemIndex,
          completedItemCount: _viewModel.completedItemCount,
          itemCount: widget.sequence.items.length,
          isCompleted: true,
        ),
        const SizedBox(height: IstiqamSpacing.xl),
        for (var index = 0; index < widget.sequence.items.length; index++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: IstiqamSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.sequence.items[index].title,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Text(
                  '×${_viewModel.counts[index]}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: IstiqamSpacing.xxl),
        SizedBox(
          width: double.infinity,
          child: IstiqamButton(label: 'Selesai', onPressed: _finish),
        ),
        Align(
          alignment: Alignment.center,
          child: TextButton.icon(
            key: const ValueKey('dhikr-undo'),
            onPressed: _viewModel.canUndo ? _undo : null,
            icon: const Icon(PhosphorIconsRegular.arrowCounterClockwise),
            label: const Text('Undo count'),
            style: TextButton.styleFrom(
              minimumSize: const Size(44, 44),
              foregroundColor: colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class DhikrUnavailableScreen extends StatelessWidget {
  const DhikrUnavailableScreen({required this.routineId, super.key});

  final String routineId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    void goBack() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(RoutePaths.routineDetail(routineId));
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: goBack,
          icon: const Icon(PhosphorIconsRegular.arrowLeft),
        ),
        title: Text('Dzikir', style: theme.textTheme.titleMedium),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(IstiqamSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  PhosphorIconsRegular.handsPraying,
                  size: 40,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: IstiqamSpacing.lg),
                Text(
                  'Dzikir tidak tersedia',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: IstiqamSpacing.lg),
                IstiqamButton(label: 'Kembali', onPressed: goBack),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
