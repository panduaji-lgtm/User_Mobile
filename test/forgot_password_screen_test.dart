import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:app/views/screens/auth/forgot_password_screen.dart';
import 'package:app/views/screens/auth/login_screen.dart';
import 'package:app/views/screens/auth/reset_password_screen.dart';

void main() {
  testWidgets(
    'login forgot-password link opens the reset instructions screen',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(
            path: '/login',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: '/forgot-password',
            builder: (context, state) => const ForgotPasswordScreen(),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      final forgotPasswordLink = find.text('Lupa kata sandi?');
      await tester.ensureVisible(forgotPasswordLink);
      await tester.tap(forgotPasswordLink);
      await tester.pumpAndSettle();

      expect(find.text('Lupa Kata Sandi?'), findsOneWidget);
      expect(find.text('Alamat Email'), findsOneWidget);
      expect(find.text('Masukkan email Anda'), findsOneWidget);
      expect(find.text('Kirim Link Reset ke Email  →'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final viewport in const [Size(320, 640), Size(390, 844)]) {
    testWidgets(
      'ResetPasswordScreen renders cleanly with token and OTP mode without RenderFlex error (${viewport.width.toInt()}x${viewport.height.toInt()})',
      (tester) async {
        tester.view.physicalSize = viewport;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          const MaterialApp(
            home: ResetPasswordScreen(
              token: 'sample-reset-token',
              email: 'pengunjung@museum.online',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Buat Kata Sandi Baru'), findsOneWidget);
        expect(find.text('Simpan Kata Sandi Baru'), findsOneWidget);
        expect(find.text('Kode OTP Verifikasi (6 Digit)'), findsNothing);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(
          const MaterialApp(
            home: ResetPasswordScreen(
              token: '',
              email: 'pengunjung@museum.online',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Kode OTP Verifikasi (6 Digit)'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
