import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../theme/istiqam_notice_palette.dart';
import '../theme/istiqam_theme_extension.dart';
import '../tokens/istiqam_radius.dart';
import '../tokens/istiqam_spacing.dart';

enum IstiqamNoticeType { success, info, warning, error, neutral }

class IstiqamNotice extends StatelessWidget {
  const IstiqamNotice({
    required this.type,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.onClose,
    this.showCloseButton = true,
    super.key,
  });

  final IstiqamNoticeType type;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onClose;
  final bool showCloseButton;

  IconData get _icon => switch (type) {
    IstiqamNoticeType.success => PhosphorIconsRegular.checkCircle,
    IstiqamNoticeType.info => PhosphorIconsRegular.info,
    IstiqamNoticeType.warning => PhosphorIconsRegular.warning,
    IstiqamNoticeType.error => PhosphorIconsRegular.xCircle,
    IstiqamNoticeType.neutral => PhosphorIconsRegular.bellSimple,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<IstiqamNoticePalette>()!;
    final colors = theme.colorScheme;
    final (surfaceColor, inkColor) = switch (type) {
      IstiqamNoticeType.success => (palette.successSurface, palette.successInk),
      IstiqamNoticeType.info => (palette.infoSurface, palette.infoInk),
      IstiqamNoticeType.warning => (palette.warningSurface, palette.warningInk),
      IstiqamNoticeType.error => (palette.errorSurface, palette.errorInk),
      IstiqamNoticeType.neutral => (palette.neutralSurface, palette.neutralInk),
    };
    final hasAction = actionLabel != null && onAction != null;
    final accessibleLabel = message == null ? title : '$title. $message';

    return Semantics(
      container: true,
      explicitChildNodes: true,
      liveRegion: true,
      label: accessibleLabel,
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(IstiqamRadius.large),
          border: Border.all(
            color: theme.extension<IstiqamThemeExtension>()!.border.withValues(
              alpha: 0.9,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.24 : 0.085,
              ),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(IstiqamSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: inkColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(IstiqamRadius.medium),
                  ),
                  alignment: Alignment.center,
                  child: Icon(_icon, color: inkColor, size: 21),
                ),
                const SizedBox(width: IstiqamSpacing.md),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.textTheme.titleSmall),
                        if (message != null) ...[
                          const SizedBox(height: IstiqamSpacing.xxs),
                          Text(
                            message!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (showCloseButton)
                  IconButton(
                    tooltip: 'Dismiss notification',
                    onPressed: onClose,
                    constraints: const BoxConstraints.tightFor(
                      width: 44,
                      height: 44,
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.standard,
                    icon: Icon(
                      PhosphorIconsRegular.x,
                      size: 18,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            if (hasAction) ...[
              const SizedBox(height: IstiqamSpacing.xs),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    foregroundColor: inkColor,
                    minimumSize: const Size(44, 44),
                    padding: const EdgeInsets.symmetric(
                      horizontal: IstiqamSpacing.md,
                    ),
                    textStyle: theme.textTheme.labelMedium,
                    tapTargetSize: MaterialTapTargetSize.padded,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(IstiqamRadius.medium),
                    ),
                  ),
                  icon: Icon(PhosphorIconsRegular.arrowRight, size: 16),
                  label: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
