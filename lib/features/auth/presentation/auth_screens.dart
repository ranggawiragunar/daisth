import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/design_system/components/daisth_notice.dart';
import '../../../core/design_system/components/daisth_notice_controller.dart';
import '../../../core/design_system/components/daisth_surface.dart';
import '../../../core/design_system/tokens/daisth_spacing.dart';
import '../../../core/localization/daisth_localizations.dart';
import '../domain/models/auth_session.dart';
import '../domain/models/auth_user.dart';
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

  Future<void> _signInWithApple() async {
    final success = await widget.viewModel.signInWithApple();
    if (!mounted) return;
    if (widget.viewModel.failure != AuthFailure.cancelled) _notice(success);
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          DaisthLocalizations.text(
            context,
            id: 'Keluar dari akun?',
            en: 'Sign out?',
          ),
        ),
        content: Text(
          DaisthLocalizations.text(
            context,
            id: 'Data yang tersimpan di perangkat ini tidak akan dihapus.',
            en: 'Data stored on this device will not be deleted.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              DaisthLocalizations.text(context, id: 'Batal', en: 'Cancel'),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              DaisthLocalizations.text(context, id: 'Keluar', en: 'Sign out'),
            ),
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
    final providerName = switch (session.user.provider) {
      AuthProviderKind.google => 'Google',
      AuthProviderKind.apple => 'Apple',
    };
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          DaisthLocalizations.text(
            context,
            id: 'Hapus akun Daisth?',
            en: 'Delete Daisth account?',
          ),
        ),
        content: Text(
          DaisthLocalizations.text(
            context,
            id: 'Data Daisth di cloud untuk akun ini akan dihapus permanen. Data di perangkat tetap ada. Anda akan diminta memverifikasi akun $providerName sebelum penghapusan.',
            en: 'Daisth cloud data for this account will be permanently deleted. Device data will remain. You will be asked to verify your $providerName account before deletion.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              DaisthLocalizations.text(context, id: 'Batal', en: 'Cancel'),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              DaisthLocalizations.text(
                context,
                id: 'Hapus akun',
                en: 'Delete account',
              ),
            ),
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
    final providerName = switch (session.user.provider) {
      AuthProviderKind.google => 'Google',
      AuthProviderKind.apple => 'Apple',
    };
    final email = session.user.email ?? 'akun $providerName ini';
    final activate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          DaisthLocalizations.text(
            context,
            id: 'Aktifkan sinkronisasi?',
            en: 'Turn on sync?',
          ),
        ),
        content: Text(
          DaisthLocalizations.text(
            context,
            id: 'Data Daisth di perangkat ini akan ditautkan ke $email dan digabungkan dengan data Daisth yang sudah tersimpan pada akun tersebut. Data lokal tidak akan dihapus.',
            en: 'Daisth data on this device will be linked to $email and combined with Daisth data already stored in that account. Local data will not be deleted.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              DaisthLocalizations.text(context, id: 'Batal', en: 'Cancel'),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              DaisthLocalizations.text(context, id: 'Aktifkan', en: 'Turn on'),
            ),
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
      title = DaisthLocalizations.text(
        context,
        id: 'Akun Daisth berbeda',
        en: 'Different Daisth account',
      );
      body = DaisthLocalizations.text(
        context,
        id: 'Data di perangkat ini ditautkan ke akun Daisth lain. Tidak ada data yang dipindahkan ke akun ini. Sinkronisasi dihentikan agar data tidak tercampur. Masuk dengan akun yang sebelumnya ditautkan untuk melanjutkan.',
        en: 'Data on this device is linked to another Daisth account. No data was moved to this account. Sync is paused to keep data separate. Sign in with the previously linked account to continue.',
      );
    } else if (!linked) {
      title = DaisthLocalizations.text(
        context,
        id: 'Sinkronisasi belum diaktifkan',
        en: 'Sync is not enabled',
      );
      body = DaisthLocalizations.text(
        context,
        id: 'Data tetap tersimpan di perangkat. Tautkan ke akun Google untuk menggabungkan data dengan aman.',
        en: 'Your data remains on this device. Link a Google account to safely combine your data.',
      );
    } else {
      title = switch (vm.status) {
        SyncStatus.syncing => DaisthLocalizations.text(
          context,
          id: 'Menyinkronkan data…',
          en: 'Syncing data…',
        ),
        SyncStatus.error ||
        SyncStatus.offline ||
        SyncStatus.unavailable => 'Sinkronisasi tertunda',
        _ => DaisthLocalizations.text(
          context,
          id: 'Sinkronisasi aktif',
          en: 'Sync is active',
        ),
      };
      body = state?.lastErrorCode != null
          ? DaisthLocalizations.text(
              context,
              id: 'Data lokal tetap aman. Periksa koneksi atau coba sinkronkan lagi.',
              en: 'Your local data is safe. Check your connection or try syncing again.',
            )
          : DaisthLocalizations.text(
              context,
              id: '${state?.pendingCount ?? 0} perubahan menunggu sinkronisasi.',
              en: '${state?.pendingCount ?? 0} changes are waiting to sync.',
            );
      if (state?.lastSuccessfulSyncAtUtc case final time?) {
        final localTime = time.toLocal();
        final clock = MaterialLocalizations.of(
          context,
        ).formatTimeOfDay(TimeOfDay.fromDateTime(localTime));
        body +=
            '\n${DaisthLocalizations.text(context, id: 'Terakhir disinkronkan', en: 'Last synced')} ${MaterialLocalizations.of(context).formatMediumDate(localTime)}, $clock.';
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
              label: Text(
                DaisthLocalizations.text(
                  context,
                  id: 'Aktifkan sinkronisasi',
                  en: 'Turn on sync',
                ),
              ),
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
              label: Text(
                DaisthLocalizations.text(
                  context,
                  id: 'Sinkronkan sekarang',
                  en: 'Sync now',
                ),
              ),
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
      title: _authMessage(context, vm.message, success),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    final session = vm.session;
    final loading = vm.operation == AuthOperationState.loading;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          DaisthLocalizations.text(context, id: 'Akun', en: 'Account'),
        ),
        centerTitle: true,
      ),
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
                          DaisthLocalizations.text(
                            context,
                            id: 'Layanan akun belum tersedia saat ini.',
                            en: 'Account services are currently unavailable.',
                          ),
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: DaisthSpacing.sm),
                        Text(
                          DaisthLocalizations.text(
                            context,
                            id: 'Daisth tetap bisa digunakan dengan data yang tersimpan di perangkat.',
                            en: 'You can keep using Daisth with data stored on this device.',
                          ),
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: DaisthSpacing.md),
                        TextButton.icon(
                          onPressed: loading ? null : _retryAvailability,
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(
                            DaisthLocalizations.text(
                              context,
                              id: 'Coba lagi',
                              en: 'Try again',
                            ),
                          ),
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
                          DaisthLocalizations.text(
                            context,
                            id: 'Daisth tetap bisa digunakan tanpa akun.',
                            en: 'You can use Daisth without an account.',
                          ),
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: DaisthSpacing.sm),
                        Text(
                          DaisthLocalizations.text(
                            context,
                            id: 'Hubungkan akun untuk menggunakan fitur berbasis akun saat tersedia.',
                            en: 'Connect an account to use account features when available.',
                          ),
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: DaisthSpacing.lg),
                        if (!kIsWeb &&
                            defaultTargetPlatform == TargetPlatform.iOS) ...[
                          SignInWithAppleButton(
                            height: 48,
                            style: theme.brightness == Brightness.dark
                                ? SignInWithAppleButtonStyle.white
                                : SignInWithAppleButtonStyle.black,
                            onPressed: loading ? null : _signInWithApple,
                          ),
                          const SizedBox(height: DaisthSpacing.sm),
                        ],
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
                          label: Text(
                            DaisthLocalizations.text(
                              context,
                              id: 'Lanjutkan dengan Google',
                              en: 'Continue with Google',
                            ),
                          ),
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
                                    session.user.displayName ??
                                        switch (session.user.provider) {
                                          AuthProviderKind.google =>
                                            'Akun Google',
                                          AuthProviderKind.apple =>
                                            'Akun Apple',
                                        },
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
                              child: Text(
                                DaisthLocalizations.text(
                                  context,
                                  id: 'Keluar',
                                  en: 'Sign out',
                                ),
                              ),
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
                                label: Text(
                                  DaisthLocalizations.text(
                                    context,
                                    id: 'Hapus akun Daisth',
                                    en: 'Delete Daisth account',
                                  ),
                                ),
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

String _authMessage(BuildContext context, String? message, bool success) {
  if (message == null) {
    return DaisthLocalizations.text(
      context,
      id: success ? 'Selesai.' : 'Terjadi kendala.',
      en: success ? 'Done.' : 'Something went wrong.',
    );
  }
  if (!DaisthLocalizations.isEnglish(context)) return message;
  return switch (message) {
    'Akun Google berhasil dihubungkan.' => 'Google account connected.',
    'Akun Apple berhasil dihubungkan.' => 'Apple account connected.',
    'Berhasil keluar.' => 'Signed out.',
    'Layanan akun siap.' => 'Account services are ready.',
    'Akun Daisth telah dihapus. Data di perangkat tetap ada.' =>
      'Daisth account deleted. Device data remains.',
    'Koneksi tidak tersedia. Coba lagi saat terhubung ke internet.' =>
      'No connection. Try again when you are online.',
    'Pilihan akun belum dapat digunakan. Coba lagi nanti.' =>
      'This sign-in option is unavailable. Try again later.',
    'Akun ini tidak dapat digunakan. Coba pilih akun lain.' =>
      'This account cannot be used. Try another account.',
    'Akun ini tidak dapat digunakan.' => 'This account cannot be used.',
    'Terlalu banyak percobaan. Coba lagi nanti.' =>
      'Too many attempts. Try again later.',
    'Verifikasi ulang akun untuk melanjutkan.' =>
      'Re-authenticate your account to continue.',
    'Layanan akun belum tersedia. Daisth tetap bisa digunakan.' =>
      'Account services are unavailable. You can keep using Daisth.',
    'Terjadi kendala. Coba lagi.' => 'Something went wrong. Try again.',
    'Gunakan akun yang saat ini terhubung ke Daisth.' =>
      'Use the account currently connected to Daisth.',
    'Verifikasi ulang akun Daisth, lalu coba lagi.' =>
      'Re-authenticate your Daisth account and try again.',
    'Akun belum dapat dihapus. Data di perangkat tetap aman. Coba lagi saat koneksi tersedia.' =>
      'The account could not be deleted. Device data is safe. Try again when you are online.',
    'Akun belum dapat dihapus. Data di perangkat tetap aman. Coba lagi.' =>
      'The account could not be deleted. Device data is safe. Try again.',
    'Penghapusan belum selesai. Data cloud mungkin sudah terhapus, tetapi akun masih aktif karena akses Apple belum dapat dicabut. Coba lagi.' =>
      'Deletion is incomplete. Cloud data may be deleted, but the account remains active because Apple access could not be revoked. Try again.',
    'Layanan akun belum tersedia. Data di perangkat tetap aman.' =>
      'Account services are unavailable. Device data is safe.',
    _ => message,
  };
}
