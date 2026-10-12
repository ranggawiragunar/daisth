import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../core/design_system/tokens/istiqam_spacing.dart';
import '../../domain/models/reader_content.dart';
import '../view_models/reader_view_model.dart';
import '../widgets/reader_display_controls.dart';
import '../widgets/reader_text_section.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({
    required this.routineId,
    required this.content,
    super.key,
  });

  final String routineId;
  final ReaderContent content;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late final ReaderViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ReaderViewModel(widget.content)..addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _viewModel
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.routineDetail(widget.routineId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = _viewModel.content;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: _back,
          icon: const Icon(PhosphorIconsRegular.arrowLeft),
        ),
        title: Text('Reader', style: theme.textTheme.titleMedium),
        actions: [
          IconButton(
            tooltip: 'Tampilan bacaan',
            onPressed: () => showReaderDisplayControls(context, _viewModel),
            icon: Text(
              'Aa',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: IstiqamSpacing.xs),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            IstiqamSpacing.xl,
            IstiqamSpacing.lg,
            IstiqamSpacing.xl,
            88,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    content.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: IstiqamSpacing.xs),
                  Text(
                    content.context,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (content.subtitle != null) ...[
                    const SizedBox(height: IstiqamSpacing.xs),
                    Text(
                      content.subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: IstiqamSpacing.massive),
                  for (var index = 0; index < content.sections.length; index++)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: index == content.sections.length - 1
                            ? 0
                            : IstiqamSpacing.section,
                      ),
                      child: ReaderTextSection(
                        section: content.sections[index],
                        textScale: _viewModel.textScale,
                        showTransliteration: _viewModel.transliterationVisible,
                        showTranslation: _viewModel.translationVisible,
                      ),
                    ),
                  const SizedBox(height: IstiqamSpacing.section),
                  Text(
                    content.sourceLabel,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ReaderUnavailableScreen extends StatelessWidget {
  const ReaderUnavailableScreen({required this.routineId, super.key});

  final String routineId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RoutePaths.routineDetail(routineId));
            }
          },
          icon: const Icon(PhosphorIconsRegular.arrowLeft),
        ),
        title: Text('Reader', style: theme.textTheme.titleMedium),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(IstiqamSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  PhosphorIconsRegular.bookOpenText,
                  size: 40,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: IstiqamSpacing.lg),
                Text(
                  'Bacaan tidak tersedia',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: IstiqamSpacing.sm),
                Text(
                  'Bacaan ini belum tersedia untuk routine ini.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
