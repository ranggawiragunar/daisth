import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:daisth/core/design_system/components/daisth_notice_controller.dart';
import 'package:daisth/core/design_system/theme/daisth_theme.dart';
import 'package:daisth/features/auth/domain/models/auth_session.dart';
import 'package:daisth/features/auth/domain/models/auth_user.dart';
import 'package:daisth/features/auth/presentation/auth_screens.dart';
import 'package:daisth/features/auth/presentation/auth_view_model.dart';

import '../support/fake_auth_repository.dart';

Future<void> _withTargetPlatform(
  TargetPlatform platform,
  Future<void> Function() body,
) async {
  debugDefaultTargetPlatformOverride = platform;
  try {
    await body();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

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
          locale: const Locale('id'),
          supportedLocales: const [Locale('id'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: DaisthTheme.light,
          home: AccountScreen(viewModel: viewModel, notices: notices),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Layanan akun belum tersedia saat ini.'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Daisth tetap bisa digunakan dengan data yang tersimpan di perangkat.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('signed-out Account offers optional Google sign-in', (
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
        locale: const Locale('id'),
        supportedLocales: const [Locale('id'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: DaisthTheme.light,
        home: AccountScreen(viewModel: viewModel, notices: notices),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Daisth tetap bisa digunakan tanpa akun.'),
      findsOneWidget,
    );
    expect(find.text('Lanjutkan dengan Google'), findsOneWidget);
    expect(find.text('Email'), findsNothing);
    expect(find.text('Kata sandi'), findsNothing);
  });

  testWidgets('iOS signed-out Account offers Apple and Google optionally', (
    tester,
  ) async {
    await _withTargetPlatform(TargetPlatform.iOS, () async {
      final repository = FakeAuthRepository();
      final viewModel = AuthViewModel(repository);
      final notices = DaisthNoticeController();
      addTearDown(viewModel.dispose);
      addTearDown(repository.dispose);
      addTearDown(notices.dispose);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('id'),
          supportedLocales: const [Locale('id'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: DaisthTheme.light,
          home: AccountScreen(viewModel: viewModel, notices: notices),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Daisth tetap bisa digunakan tanpa akun.'),
        findsOneWidget,
      );
      expect(find.byType(SignInWithAppleButton), findsOneWidget);
      expect(find.text('Sign in with Apple'), findsOneWidget);
      expect(find.text('Lanjutkan dengan Google'), findsOneWidget);

      expect(
        tester
            .widget<SignInWithAppleButton>(find.byType(SignInWithAppleButton))
            .style,
        SignInWithAppleButtonStyle.black,
      );
      await tester.tap(find.byType(SignInWithAppleButton));
      await tester.pumpAndSettle();
      expect(repository.appleSignInRequests, 1);
      expect(find.text('Akun Apple'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });
  });

  testWidgets('Android signed-out Account does not show Apple sign-in', (
    tester,
  ) async {
    await _withTargetPlatform(TargetPlatform.android, () async {
      final repository = FakeAuthRepository();
      final viewModel = AuthViewModel(repository);
      final notices = DaisthNoticeController();
      addTearDown(viewModel.dispose);
      addTearDown(repository.dispose);
      addTearDown(notices.dispose);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('id'),
          supportedLocales: const [Locale('id'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: DaisthTheme.light,
          home: AccountScreen(viewModel: viewModel, notices: notices),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SignInWithAppleButton), findsNothing);
      expect(find.text('Sign in with Apple'), findsNothing);
      expect(find.text('Lanjutkan dengan Google'), findsOneWidget);
    });
  });

  testWidgets(
    'iOS Apple sign-in uses the light logo style in dark appearance',
    (tester) async {
      await _withTargetPlatform(TargetPlatform.iOS, () async {
        final repository = FakeAuthRepository();
        final viewModel = AuthViewModel(repository);
        final notices = DaisthNoticeController();
        addTearDown(viewModel.dispose);
        addTearDown(repository.dispose);
        addTearDown(notices.dispose);

        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('id'),
            supportedLocales: const [Locale('id'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: DaisthTheme.dark,
            home: AccountScreen(viewModel: viewModel, notices: notices),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          tester
              .widget<SignInWithAppleButton>(find.byType(SignInWithAppleButton))
              .style,
          SignInWithAppleButtonStyle.white,
        );
      });
    },
  );

  testWidgets(
    'signed-in Account shows Google profile without verification UX',
    (tester) async {
      final repository = FakeAuthRepository()
        ..session = const AuthSignedIn(
          AuthUser(
            uid: 'test-uid',
            email: 'person@example.com',
            displayName: 'Test User',
          ),
        );
      final viewModel = AuthViewModel(repository);
      final notices = DaisthNoticeController();
      addTearDown(viewModel.dispose);
      addTearDown(repository.dispose);
      addTearDown(notices.dispose);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('id'),
          supportedLocales: const [Locale('id'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: DaisthTheme.light,
          home: AccountScreen(viewModel: viewModel, notices: notices),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('person@example.com'), findsOneWidget);
      expect(find.text('Keluar'), findsOneWidget);
      expect(find.textContaining('verifikasi'), findsNothing);
    },
  );
}
