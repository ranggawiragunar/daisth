import 'package:flutter/material.dart';

import '../../../core/design_system/components/daisth_notice.dart';
import '../../../core/design_system/components/daisth_notice_controller.dart';
import '../../../core/design_system/components/daisth_surface.dart';
import '../../../core/design_system/tokens/daisth_spacing.dart';
import '../domain/models/auth_session.dart';
import 'auth_view_model.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({
    required this.viewModel,
    required this.notices,
    super.key,
  });

  final AuthViewModel viewModel;
  final DaisthNoticeController notices;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_changed);
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _signIn() async {
    final success = await widget.viewModel.signInWithGoogle();
    if (!mounted) return;
    if (widget.viewModel.failure != AuthFailure.cancelled) _notice(success);
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text(
          'Data yang tersimpan di perangkat ini tidak akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final success = await widget.viewModel.signOut();
    if (mounted) _notice(success);
  }

  Future<void> _retryAvailability() async {
    final success = await widget.viewModel.retryAvailability();
    if (mounted) _notice(success);
  }

  void _notice(bool success) {
    final vm = widget.viewModel;
    widget.notices.show(
      context,
      type: success ? DaisthNoticeType.success : DaisthNoticeType.error,
      title: vm.message ?? (success ? 'Selesai.' : 'Terjadi kendala.'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    final session = vm.session;
    final loading = vm.operation == AuthOperationState.loading;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Account'), centerTitle: true),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(DaisthSpacing.screenHorizontal),
              children: [
                if (session is AuthUnavailable)
                  DaisthSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Layanan akun belum tersedia saat ini.',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: DaisthSpacing.sm),
                        Text(
                          'Daisth tetap bisa digunakan dengan data yang tersimpan di perangkat.',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: DaisthSpacing.md),
                        TextButton.icon(
                          onPressed: loading ? null : _retryAvailability,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Coba lagi'),
                        ),
                      ],
                    ),
                  )
                else if (session is AuthSignedOut)
                  DaisthSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Daisth tetap bisa digunakan tanpa akun.',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: DaisthSpacing.sm),
                        Text(
                          'Hubungkan akun Google untuk menggunakan fitur berbasis akun saat tersedia.',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: DaisthSpacing.lg),
                        OutlinedButton.icon(
                          onPressed: loading ? null : _signIn,
                          icon: loading
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.account_circle_outlined),
                          label: const Text('Lanjutkan dengan Google'),
                        ),
                      ],
                    ),
                  )
                else if (session is AuthSignedIn)
                  DaisthSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _AccountAvatar(photoUrl: session.user.photoUrl),
                            const SizedBox(width: DaisthSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    session.user.displayName ?? 'Akun Google',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  if (session.user.email case final email?)
                                    Text(
                                      email,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: DaisthSpacing.lg),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: loading ? null : _signOut,
                            child: const Text('Keluar'),
                          ),
                        ),
                      ],
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

class _AccountAvatar extends StatelessWidget {
  const _AccountAvatar({this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final fallback = CircleAvatar(
      child: Icon(
        Icons.person_outline_rounded,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
    if (photoUrl == null || photoUrl!.isEmpty) return fallback;
    return ClipOval(
      child: Image.network(
        photoUrl!,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback,
      ),
    );
  }
}
