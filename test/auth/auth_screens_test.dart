import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daisth/core/design_system/components/daisth_notice_controller.dart';
import 'package:daisth/core/design_system/theme/daisth_theme.dart';
import 'package:daisth/features/auth/domain/models/auth_session.dart';
import 'package:daisth/features/auth/presentation/auth_screens.dart';
import 'package:daisth/features/auth/presentation/auth_view_model.dart';

import '../support/fake_auth_repository.dart';

void main() {
  testWidgets(
    'Account explains unavailable service while preserving local use',
    (tester) async {
      final repository = FakeAuthRepository()
        ..session = const AuthUnavailable();
      final viewModel = AuthViewModel(repository);
      final notices = DaisthNoticeController();
      addTearDown(viewModel.dispose);
      addTearDown(repository.dispose);
      addTearDown(notices.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: DaisthTheme.light,
          home: AccountScreen(viewModel: viewModel, notices: notices),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Layanan akun belum tersedia di versi ini.'),
        findsOneWidget,
      );
      expect(
        find.text('Data Daisth di perangkat tetap bisa digunakan.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('signed-out Account offers sign-in and account creation', (
    tester,
  ) async {
    final repository = FakeAuthRepository();
    final viewModel = AuthViewModel(repository);
    final notices = DaisthNoticeController();
    addTearDown(viewModel.dispose);
    addTearDown(repository.dispose);
    addTearDown(notices.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: DaisthTheme.light,
        home: AccountScreen(viewModel: viewModel, notices: notices),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Daisth tetap bisa digunakan tanpa akun.'),
      findsOneWidget,
    );
    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('Buat akun'), findsOneWidget);
  });
}
