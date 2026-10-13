import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../theme/daisth_notice_palette.dart';
import '../theme/daisth_theme_extension.dart';
import '../tokens/daisth_radius.dart';

enum DaisthNoticeType { success, info, warning, error, neutral }

class DaisthNotice extends StatelessWidget {
  const DaisthNotice({
    required this.type,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.onClose,
    this.showCloseButton = true,
    super.key,
  });

  final DaisthNoticeType type;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onClose;
  final bool showCloseButton;

  IconData get _icon => switch (type) {
    DaisthNoticeType.success => PhosphorIconsRegular.checkCircle,
    DaisthNoticeType.info => PhosphorIconsRegular.info,
    DaisthNoticeType.warning => PhosphorIconsRegular.warning,
    DaisthNoticeType.error => PhosphorIconsRegular.xCircle,
    DaisthNoticeType.neutral => PhosphorIconsRegular.bellSimple,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<DaisthNoticePalette>()!;
    final colors = theme.colorScheme;
    final (surfaceColor, inkColor) = switch (type) {
      DaisthNoticeType.success => (palette.successSurface, palette.successInk),
      DaisthNoticeType.info => (palette.infoSurface, palette.infoInk),
      DaisthNoticeType.warning => (palette.warningSurface, palette.warningInk),
      DaisthNoticeType.error => (palette.errorSurface, palette.errorInk),
      DaisthNoticeType.neutral => (palette.neutralSurface, palette.neutralInk),
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
          borderRadius: BorderRadius.circular(DaisthRadius.large),
          border: Border.all(
            color: theme.extension<DaisthThemeExtension>()!.border.withValues(
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
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(_icon, color: inkColor, size: 19),
            const SizedBox(width: 10),
            Flexible(
              fit: FlexFit.loose,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (message != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      message!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (hasAction) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  foregroundColor: inkColor,
                  minimumSize: const Size(44, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  textStyle: theme.textTheme.labelMedium,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(actionLabel!),
              ),
            ],
            if (showCloseButton) ...[
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Dismiss notification',
                onPressed: onClose,
                constraints: const BoxConstraints.tightFor(
                  width: 36,
                  height: 36,
                ),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  PhosphorIconsRegular.x,
                  size: 17,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
