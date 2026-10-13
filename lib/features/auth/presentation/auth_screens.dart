import 'package:flutter/material.dart';

import '../../../core/design_system/components/daisth_notice.dart';
import '../../../core/design_system/components/daisth_notice_controller.dart';
import '../../../core/design_system/components/daisth_surface.dart';
import '../../../core/design_system/tokens/daisth_spacing.dart';
import '../domain/models/auth_session.dart';
import '../domain/use_cases/delete_account_use_case.dart';
import 'auth_view_model.dart';
import '../../sync/domain/models/sync_entity.dart';
import '../../sync/presentation/sync_view_model.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({
    required this.viewModel,
    this.deleteAccountUseCase,
    this.syncViewModel,
    required this.notices,
    super.key,
  });

  final AuthViewModel viewModel;
  final DeleteAccountUseCase? deleteAccountUseCase;
  final SyncViewModel? syncViewModel;
  final DaisthNoticeController notices;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_changed);
    widget.syncViewModel?.addListener(_changed);
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_changed);
    widget.syncViewModel?.removeListener(_changed);
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

  Future<void> _deleteAccount(AuthSignedIn session) async {
    final useCase = widget.deleteAccountUseCase;
    if (useCase == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus akun Daisth?'),
        content: const Text(
          'Data Daisth yang tersimpan di cloud untuk akun ini akan dihapus permanen. Data yang tersimpan di perangkat ini tetap ada. Anda akan diminta memverifikasi akun Google sebelum penghapusan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus akun'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final outcome = await widget.viewModel.deleteAccount(
      useCase,
      session.user.uid,
    );
    if (!mounted || outcome == DeleteAccountOutcome.cancelled) return;
    _notice(outcome == DeleteAccountOutcome.success);
  }

  Future<void> _activateSync(AuthSignedIn session) async {
    final syncViewModel = widget.syncViewModel;
    if (syncViewModel == null) return;
    final email = session.user.email ?? 'akun Google ini';
    final activate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aktifkan sinkronisasi?'),
        content: Text(
          'Data Daisth di perangkat ini akan ditautkan ke $email dan digabungkan dengan data Daisth yang sudah tersimpan pada akun tersebut. Data lokal tidak akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Aktifkan'),
          ),
        ],
      ),
    );
    if (activate != true || !mounted) return;
    try {
      await syncViewModel.activate(session.user.uid);
      if (mounted) _notice(syncViewModel.status == SyncStatus.synced);
    } catch (_) {
      if (mounted) _notice(false);
    }
  }

  Future<void> _syncNow() async {
    final syncViewModel = widget.syncViewModel;
    if (syncViewModel == null) return;
    await syncViewModel.syncNow();
    if (mounted) _notice(syncViewModel.status == SyncStatus.synced);
  }

  Widget _syncCard(BuildContext context, AuthSignedIn session) {
    final vm = widget.syncViewModel!;
    final state = vm.state;
    final theme = Theme.of(context);
    final linkedUid = state?.linkedUid;
    final mismatch = linkedUid != null && linkedUid != session.user.uid;
    final linked = linkedUid == session.user.uid;
    final busy = vm.status == SyncStatus.syncing;
    String title;
    String body;
    if (mismatch || vm.status == SyncStatus.accountMismatch) {
      title = 'Akun Daisth berbeda';
      body =
          'Data di perangkat ini ditautkan ke akun Daisth lain. Tidak ada data yang dipindahkan ke akun ini. Sinkronisasi dihentikan agar data tidak tercampur. Masuk dengan akun yang sebelumnya ditautkan untuk melanjutkan.';
    } else if (!linked) {
      title = 'Sinkronisasi belum diaktifkan';
      body =
          'Data tetap tersimpan di perangkat. Tautkan ke akun Google untuk menggabungkan data dengan aman.';
    } else {
      title = switch (vm.status) {
        SyncStatus.syncing => 'Menyinkronkan data…',
        SyncStatus.error ||
        SyncStatus.offline ||
        SyncStatus.unavailable => 'Sinkronisasi tertunda',
        _ => 'Sinkronisasi aktif',
      };
      body = state?.lastErrorCode != null
          ? 'Data lokal tetap aman. Periksa koneksi atau coba sinkronkan lagi.'
          : '${state?.pendingCount ?? 0} perubahan menunggu sinkronisasi.';
      if (state?.lastSuccessfulSyncAtUtc case final time?) {
        final localTime = time.toLocal();
        final clock = MaterialLocalizations.of(
          context,
        ).formatTimeOfDay(TimeOfDay.fromDateTime(localTime));
        body +=
            '\nTerakhir disinkronkan ${MaterialLocalizations.of(context).formatMediumDate(localTime)}, $clock.';
      }
    }
    return DaisthSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: DaisthSpacing.sm),
          Text(body, style: theme.textTheme.bodyMedium),
          const SizedBox(height: DaisthSpacing.md),
          if (mismatch || vm.status == SyncStatus.accountMismatch)
            const SizedBox.shrink()
          else if (!linked)
            FilledButton.icon(
              onPressed: busy ? null : () => _activateSync(session),
              icon: const Icon(Icons.cloud_sync_outlined),
              label: const Text('Aktifkan sinkronisasi'),
            )
          else
            OutlinedButton.icon(
              onPressed: busy ? null : _syncNow,
              icon: busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync_rounded),
              label: const Text('Sinkronkan sekarang'),
            ),
        ],
      ),
    );
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            OutlinedButton(
                              onPressed: loading ? null : _signOut,
                              child: const Text('Keluar'),
                            ),
                            const SizedBox(height: DaisthSpacing.sm),
                            if (widget.deleteAccountUseCase != null)
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: theme.colorScheme.error,
                                  side: BorderSide(
                                    color: theme.colorScheme.error.withValues(
                                      alpha: 0.55,
                                    ),
                                  ),
                                ),
                                onPressed: loading
                                    ? null
                                    : () => _deleteAccount(session),
                                icon: loading
                                    ? const SizedBox.square(
                                        dimension: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.delete_outline_rounded),
                                label: const Text('Hapus akun Daisth'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                if (session is AuthSignedIn &&
                    widget.syncViewModel != null) ...[
                  const SizedBox(height: DaisthSpacing.md),
                  _syncCard(context, session),
                ],
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
