import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'daisth_notice.dart';

class DaisthNoticeController {
  OverlayEntry? _entry;
  GlobalKey<_DaisthNoticeLayerState>? _layerKey;
  Timer? _timer;
  int _activeId = 0;

  void show(
    BuildContext context, {
    required DaisthNoticeType type,
    required String title,
    String? message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration = const Duration(seconds: 4),
    bool? showCloseButton,
  }) {
    final anchor = DaisthNoticeAnchor.maybeOf(context);
    final mediaQuery = MediaQuery.of(context);
    final bottomInset =
        anchor?.bottomInset ?? mediaQuery.viewPadding.bottom + 12;
    final overlay = Overlay.of(context, rootOverlay: true);
    final id = ++_activeId;
    _removeImmediately();
    final key = GlobalKey<_DaisthNoticeLayerState>();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _DaisthNoticeLayer(
        key: key,
        type: type,
        title: title,
        message: message,
        actionLabel: actionLabel,
        onAction: onAction,
        showCloseButton:
            showCloseButton ?? (duration == null || onAction != null),
        bottomInset: bottomInset,
        onDismiss: () => _dismiss(id),
        onDismissed: () => _removeIfCurrent(id),
      ),
    );
    _entry = entry;
    _layerKey = key;
    overlay.insert(entry);

    if (type == DaisthNoticeType.success || type == DaisthNoticeType.error) {
      unawaited(HapticFeedback.lightImpact());
    }
    if (duration != null && onAction == null) {
      _timer = Timer(duration, () => _dismiss(id));
    }
  }

  void dismiss() => _dismiss(_activeId);

  void _dismiss(int id) {
    if (id != _activeId || _entry == null) return;
    _timer?.cancel();
    _timer = null;
    final state = _layerKey?.currentState;
    if (state == null) {
      _removeIfCurrent(id);
    } else {
      state.dismiss();
    }
  }

  void _removeIfCurrent(int id) {
    if (id != _activeId) return;
    _timer?.cancel();
    _timer = null;
    _removeImmediately();
  }

  void _removeImmediately() {
    _timer?.cancel();
    _timer = null;
    final entry = _entry;
    _entry = null;
    _layerKey = null;
    if (entry != null) {
      entry.remove();
      entry.dispose();
    }
  }

  void dispose() {
    _activeId++;
    _removeImmediately();
  }
}

class DaisthNoticeScope extends InheritedWidget {
  const DaisthNoticeScope({
    required this.controller,
    required super.child,
    super.key,
  });

  final DaisthNoticeController controller;

  static DaisthNoticeController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<DaisthNoticeScope>();
    assert(scope != null, 'No DaisthNoticeScope found in this context.');
    return scope!.controller;
  }

  @override
  bool updateShouldNotify(DaisthNoticeScope oldWidget) =>
      controller != oldWidget.controller;
}

/// Provides the bottom clearance needed by an app-level floating notice.
///
/// Shells with a floating navigation surface can set a larger inset while
/// standalone pages fall back to the device safe area in [show].
class DaisthNoticeAnchor extends InheritedWidget {
  const DaisthNoticeAnchor({
    required this.bottomInset,
    required super.child,
    super.key,
  });

  final double bottomInset;

  static DaisthNoticeAnchor? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DaisthNoticeAnchor>();

  @override
  bool updateShouldNotify(DaisthNoticeAnchor oldWidget) =>
      bottomInset != oldWidget.bottomInset;
}

class _DaisthNoticeLayer extends StatefulWidget {
  const _DaisthNoticeLayer({
    required this.type,
    required this.title,
    required this.onDismiss,
    required this.onDismissed,
    this.message,
    this.actionLabel,
    this.onAction,
    this.showCloseButton = true,
    required this.bottomInset,
    super.key,
  });

  final DaisthNoticeType type;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool showCloseButton;
  final double bottomInset;
  final VoidCallback onDismiss;
  final VoidCallback onDismissed;

  @override
  State<_DaisthNoticeLayer> createState() => _DaisthNoticeLayerState();
}

class _DaisthNoticeLayerState extends State<_DaisthNoticeLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;
  late final CurvedAnimation _curvedAnimation;
  bool _hasStarted = false;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _curvedAnimation = CurvedAnimation(
      parent: _animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasStarted) return;
    _hasStarted = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _animation.value = 1;
    } else {
      _animation.forward();
    }
  }

  void dismiss() {
    if (_isDismissing) return;
    _isDismissing = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _animation.value = 0;
      widget.onDismissed();
    } else {
      _animation.reverse().whenCompleteOrCancel(widget.onDismissed);
    }
  }

  void _runAction() {
    try {
      widget.onAction?.call();
    } finally {
      widget.onDismiss();
    }
  }

  @override
  void dispose() {
    _curvedAnimation.dispose();
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: math.max(
        widget.bottomInset,
        MediaQuery.viewInsetsOf(context).bottom + 12,
      ),
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: AnimatedBuilder(
              animation: _curvedAnimation,
              child: DaisthNotice(
                type: widget.type,
                title: widget.title,
                message: widget.message,
                actionLabel: widget.actionLabel,
                onAction: widget.actionLabel == null || widget.onAction == null
                    ? null
                    : _runAction,
                onClose: widget.onDismiss,
                showCloseButton: widget.showCloseButton,
              ),
              builder: (context, child) => Opacity(
                opacity: _curvedAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, 10 * (1 - _curvedAnimation.value)),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
