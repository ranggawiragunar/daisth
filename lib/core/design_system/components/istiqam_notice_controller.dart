import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/istiqam_spacing.dart';
import 'istiqam_notice.dart';

class IstiqamNoticeController {
  OverlayEntry? _entry;
  GlobalKey<_IstiqamNoticeLayerState>? _layerKey;
  Timer? _timer;
  int _activeId = 0;

  void show(
    BuildContext context, {
    required IstiqamNoticeType type,
    required String title,
    String? message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration = const Duration(seconds: 4),
    bool showCloseButton = true,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    final id = ++_activeId;
    _removeImmediately();
    final key = GlobalKey<_IstiqamNoticeLayerState>();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _IstiqamNoticeLayer(
        key: key,
        type: type,
        title: title,
        message: message,
        actionLabel: actionLabel,
        onAction: onAction,
        showCloseButton: showCloseButton,
        onDismiss: () => _dismiss(id),
        onDismissed: () => _removeIfCurrent(id),
      ),
    );
    _entry = entry;
    _layerKey = key;
    overlay.insert(entry);

    if (type == IstiqamNoticeType.success || type == IstiqamNoticeType.error) {
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

class IstiqamNoticeScope extends InheritedWidget {
  const IstiqamNoticeScope({
    required this.controller,
    required super.child,
    super.key,
  });

  final IstiqamNoticeController controller;

  static IstiqamNoticeController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<IstiqamNoticeScope>();
    assert(scope != null, 'No IstiqamNoticeScope found in this context.');
    return scope!.controller;
  }

  @override
  bool updateShouldNotify(IstiqamNoticeScope oldWidget) =>
      controller != oldWidget.controller;
}

class _IstiqamNoticeLayer extends StatefulWidget {
  const _IstiqamNoticeLayer({
    required this.type,
    required this.title,
    required this.onDismiss,
    required this.onDismissed,
    this.message,
    this.actionLabel,
    this.onAction,
    this.showCloseButton = true,
    super.key,
  });

  final IstiqamNoticeType type;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool showCloseButton;
  final VoidCallback onDismiss;
  final VoidCallback onDismissed;

  @override
  State<_IstiqamNoticeLayer> createState() => _IstiqamNoticeLayerState();
}

class _IstiqamNoticeLayerState extends State<_IstiqamNoticeLayer>
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
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            IstiqamSpacing.xl,
            IstiqamSpacing.md,
            IstiqamSpacing.xl,
            0,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: AnimatedBuilder(
                animation: _curvedAnimation,
                child: IstiqamNotice(
                  type: widget.type,
                  title: widget.title,
                  message: widget.message,
                  actionLabel: widget.actionLabel,
                  onAction:
                      widget.actionLabel == null || widget.onAction == null
                      ? null
                      : _runAction,
                  onClose: widget.onDismiss,
                  showCloseButton: widget.showCloseButton,
                ),
                builder: (context, child) => Opacity(
                  opacity: _curvedAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, -10 * (1 - _curvedAnimation.value)),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
