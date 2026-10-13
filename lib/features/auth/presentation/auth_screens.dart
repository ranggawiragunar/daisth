import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/components/daisth_button.dart';
import '../../../core/design_system/components/daisth_notice.dart';
import '../../../core/design_system/components/daisth_notice_controller.dart';
import '../../../core/design_system/components/daisth_surface.dart';
import '../../../core/design_system/tokens/daisth_spacing.dart';
import '../../../app/router/route_paths.dart';
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
    final ok = await widget.viewModel.signOut();
    if (mounted) _notice(ok);
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
                if (session is AuthUnavailable) ...[
                  DaisthSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Layanan akun belum tersedia di versi ini.',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: DaisthSpacing.sm),
                        Text(
                          'Data Daisth di perangkat tetap bisa digunakan.',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: DaisthSpacing.md),
                        TextButton.icon(
                          onPressed: vm.operation == AuthOperationState.loading
                              ? null
                              : () async {
                                  final ok = await vm.retryAvailability();
                                  if (mounted) _notice(ok);
                                },
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Coba lagi'),
                        ),
                      ],
                    ),
                  ),
                ] else if (session is AuthSignedOut) ...[
                  DaisthSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daisth tetap bisa digunakan tanpa akun.',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: DaisthSpacing.sm),
                        Text(
                          'Hubungkan akun jika kamu ingin menggunakan fitur berbasis akun saat tersedia.',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: DaisthSpacing.lg),
                        SizedBox(
                          width: double.infinity,
                          child: DaisthButton(
                            label: 'Masuk',
                            onPressed: () => context.push(RoutePaths.signIn),
                          ),
                        ),
                        const SizedBox(height: DaisthSpacing.sm),
                        SizedBox(
                          width: double.infinity,
                          child: DaisthButton(
                            label: 'Buat akun',
                            style: DaisthButtonStyle.outline,
                            onPressed: () =>
                                context.push(RoutePaths.createAccount),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (session is AuthSignedIn) ...[
                  DaisthSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Email', style: theme.textTheme.labelMedium),
                        const SizedBox(height: DaisthSpacing.xs),
                        Text(
                          session.user.email,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: DaisthSpacing.md),
                        Row(
                          children: [
                            Icon(
                              session.user.emailVerified
                                  ? Icons.verified_rounded
                                  : Icons.info_outline_rounded,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: DaisthSpacing.sm),
                            Text(
                              session.user.emailVerified
                                  ? 'Email terverifikasi'
                                  : 'Email belum diverifikasi',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        if (!session.user.emailVerified) ...[
                          const SizedBox(height: DaisthSpacing.md),
                          Wrap(
                            spacing: DaisthSpacing.sm,
                            children: [
                              TextButton(
                                onPressed:
                                    vm.operation == AuthOperationState.loading
                                    ? null
                                    : () async {
                                        final ok = await vm
                                            .resendVerification();
                                        if (mounted) _notice(ok);
                                      },
                                child: const Text('Kirim ulang'),
                              ),
                              TextButton(
                                onPressed:
                                    vm.operation == AuthOperationState.loading
                                    ? null
                                    : () async {
                                        final ok = await vm
                                            .refreshVerification();
                                        if (mounted) _notice(ok);
                                      },
                                child: const Text('Periksa lagi'),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: DaisthSpacing.lg),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed:
                                vm.operation == AuthOperationState.loading
                                ? null
                                : _signOut,
                            child: const Text('Keluar'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum AuthFormKind { signIn, createAccount, forgotPassword }

class AuthFormScreen extends StatefulWidget {
  const AuthFormScreen({
    required this.kind,
    required this.viewModel,
    required this.notices,
    super.key,
  });
  final AuthFormKind kind;
  final AuthViewModel viewModel;
  final DaisthNoticeController notices;

  @override
  State<AuthFormScreen> createState() => _AuthFormScreenState();
}

class _AuthFormScreenState extends State<AuthFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_changed);
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String get _title => switch (widget.kind) {
    AuthFormKind.signIn => 'Masuk',
    AuthFormKind.createAccount => 'Buat akun',
    AuthFormKind.forgotPassword => 'Lupa kata sandi',
  };

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final vm = widget.viewModel;
    final bool success = switch (widget.kind) {
      AuthFormKind.signIn => await vm.signIn(_email.text, _password.text),
      AuthFormKind.createAccount => await vm.createAccount(
        _email.text,
        _password.text,
      ),
      AuthFormKind.forgotPassword => await vm.resetPassword(_email.text),
    };
    if (!mounted) return;
    widget.notices.show(
      context,
      type: success ? DaisthNoticeType.success : DaisthNoticeType.error,
      title: vm.message ?? 'Terjadi kendala.',
    );
    if (success) {
      if (widget.kind == AuthFormKind.forgotPassword) {
        context.pop();
      } else {
        context.go(RoutePaths.account);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    final busy = vm.operation == AuthOperationState.loading;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_title), centerTitle: true),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(DaisthSpacing.screenHorizontal),
                children: [
                  DaisthSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.kind == AuthFormKind.createAccount) ...[
                          Text(
                            'Daisth tetap tersedia tanpa akun.',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: DaisthSpacing.lg),
                        ],
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction:
                              widget.kind == AuthFormKind.forgotPassword
                              ? TextInputAction.done
                              : TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) => isValidAuthEmail(value ?? '')
                              ? null
                              : 'Masukkan alamat email yang valid.',
                        ),
                        if (widget.kind != AuthFormKind.forgotPassword) ...[
                          const SizedBox(height: DaisthSpacing.md),
                          TextFormField(
                            controller: _password,
                            obscureText: _obscure,
                            textInputAction:
                                widget.kind == AuthFormKind.createAccount
                                ? TextInputAction.next
                                : TextInputAction.done,
                            autofillHints: [
                              widget.kind == AuthFormKind.signIn
                                  ? AutofillHints.password
                                  : AutofillHints.newPassword,
                            ],
                            decoration: InputDecoration(
                              labelText: 'Kata sandi',
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                              ),
                              suffixIcon: IconButton(
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if ((value ?? '').isEmpty) {
                                return 'Kata sandi wajib diisi.';
                              }
                              if (widget.kind == AuthFormKind.createAccount &&
                                  value!.length < 8) {
                                return 'Gunakan minimal 8 karakter.';
                              }
                              return null;
                            },
                          ),
                        ],
                        if (widget.kind == AuthFormKind.createAccount) ...[
                          const SizedBox(height: DaisthSpacing.md),
                          TextFormField(
                            controller: _confirm,
                            obscureText: _obscure,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              labelText: 'Konfirmasi kata sandi',
                              prefixIcon: Icon(Icons.lock_outline_rounded),
                            ),
                            validator: (value) => value == _password.text
                                ? null
                                : 'Konfirmasi kata sandi belum sama.',
                          ),
                        ],
                        const SizedBox(height: DaisthSpacing.xl),
                        DaisthButton(
                          label: switch (widget.kind) {
                            AuthFormKind.signIn => 'Masuk',
                            AuthFormKind.createAccount => 'Buat akun',
                            AuthFormKind.forgotPassword =>
                              'Kirim instruksi reset',
                          },
                          onPressed: busy ? null : _submit,
                        ),
                        if (busy) ...[
                          const SizedBox(height: DaisthSpacing.md),
                          const Center(child: CircularProgressIndicator()),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: DaisthSpacing.md),
                  if (widget.kind == AuthFormKind.signIn) ...[
                    TextButton(
                      onPressed: () => context.push(RoutePaths.forgotPassword),
                      child: const Text('Lupa kata sandi?'),
                    ),
                    TextButton(
                      onPressed: () => context.push(RoutePaths.createAccount),
                      child: const Text('Belum punya akun? Buat akun'),
                    ),
                  ] else if (widget.kind == AuthFormKind.createAccount)
                    TextButton(
                      onPressed: () => context.push(RoutePaths.signIn),
                      child: const Text('Sudah punya akun? Masuk'),
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
