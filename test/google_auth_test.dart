import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/data/services/auth_service.dart';
import 'package:app/views/screens/auth/login_screen.dart';
import 'package:app/views/screens/auth/register_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthService.debugGoogleSignInOverride = null;
    await AuthService.logout();
  });

  tearDown(() {
    AuthService.debugGoogleSignInOverride = null;
  });

  test('Google OAuth user session persists in SharedPreferences across F5 reload', () async {
    final googleUser = UserModel(
      id: 42,
      nama: 'Nadia Kusuma',
      email: 'nadia.kusuma@gmail.com',
      authProvider: 'google',
      avatarUrl: 'https://lh3.googleusercontent.com/a/example-photo',
      token: 'real.jwt.token',
      role: 'USER',
    );

    await AuthService.saveSession(googleUser);

    AuthService.currentUser = null;
    AuthService.authNotifier.value = null;

    await AuthService.init();

    expect(AuthService.isLoggedIn, isTrue);
    expect(AuthService.currentUser?.id, 42);
    expect(AuthService.currentUser?.nama, 'Nadia Kusuma');
    expect(AuthService.currentUser?.email, 'nadia.kusuma@gmail.com');
    expect(AuthService.currentUser?.authProvider, 'google');
    expect(
      AuthService.currentUser?.avatarUrl,
      'https://lh3.googleusercontent.com/a/example-photo',
    );
  });

  testWidgets('LoginScreen menangani pembatalan login Google tanpa crash', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    AuthService.debugGoogleSignInOverride = ({String? clientId}) async {
      throw const GoogleAuthCancelledException('Login dengan Google dibatalkan.');
    };

    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.pump();

    expect(find.text('Lanjut dengan Google'), findsOneWidget);

    await tester.ensureVisible(find.text('Lanjut dengan Google'));
    await tester.tap(find.text('Lanjut dengan Google'));
    await tester.pumpAndSettle();

    expect(find.text('Login dengan Google dibatalkan.'), findsOneWidget);
    expect(AuthService.isLoggedIn, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('LoginScreen menampilkan pesan jelas jika Google OAuth belum terkonfigurasi', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    AuthService.debugGoogleSignInOverride = ({String? clientId}) async {
      throw const GoogleAuthConfigException(
        'Login dengan Google belum dikonfigurasi.',
      );
    };

    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.pump();

    await tester.ensureVisible(find.text('Lanjut dengan Google'));
    await tester.tap(find.text('Lanjut dengan Google'));
    await tester.pumpAndSettle();

    expect(find.text('Login dengan Google belum dikonfigurasi.'), findsOneWidget);
    expect(AuthService.isLoggedIn, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('RegisterScreen merender tombol Daftar dengan Google tanpa overflow', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
    await tester.pump();

    expect(find.text('Daftar dengan Google'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
