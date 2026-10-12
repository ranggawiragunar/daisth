import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../theme/istiqam_notice_palette.dart';
import '../theme/istiqam_theme_extension.dart';
import '../tokens/istiqam_radius.dart';

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
