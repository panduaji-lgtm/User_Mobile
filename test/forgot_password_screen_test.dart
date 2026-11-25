import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/auth/presentation/views/login_screen.dart';

void main() {
  testWidgets(
    'login forgot-password link opens the reset instructions screen',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      final forgotPasswordLink = find.text('Lupa kata sandi?');
      await tester.ensureVisible(forgotPasswordLink);
      await tester.tap(forgotPasswordLink);
      await tester.pumpAndSettle();

      expect(find.text('Lupa Kata Sandi?'), findsOneWidget);
      expect(find.text('Alamat Email'), findsOneWidget);
      expect(find.text('Masukkan email Anda'), findsOneWidget);
      expect(find.text('Kirim Instruksi Reset  →'), findsOneWidget);
      expect(
        find.text(
          'Masukkan email akun Anda. Kami akan mengirimkan petunjuk untuk mengatur ulang kata sandi Anda.',
        ),
        findsOneWidget,
      );
    },
  );
}
