import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/features/auth/data/repositories/auth_service.dart';
import 'package:app/features/profile/presentation/views/edit_profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthService.logout();
  });

  test('AuthService persists avatarUrl across SharedPreferences reload (F5)', () async {
    const blobUrl =
        'https://demo-store.public.blob.vercel-storage.com/avatars/user-1-123456.jpg';
    final user = UserModel(
      id: 1,
      nama: 'Budi Santoso',
      email: 'budi@example.com',
      authProvider: 'local',
      avatarUrl: blobUrl,
      token: 'jwt_test_token',
      role: 'USER',
    );

    await AuthService.saveSession(user);

    // Simulasi reload halaman browser (F5): reset memori lalu pulihkan dari SharedPreferences
    AuthService.currentUser = null;
    AuthService.authNotifier.value = null;

    await AuthService.init();

    expect(AuthService.isLoggedIn, isTrue);
    expect(AuthService.currentUser?.nama, 'Budi Santoso');
    expect(AuthService.currentUser?.email, 'budi@example.com');
    expect(AuthService.currentUser?.avatarUrl, blobUrl);
    expect(AuthService.currentUser?.hasAvatar, isTrue);
  });

  for (final viewport in const [
    Size(320, 640), // Layar mobile kecil
    Size(390, 844), // Layar mobile standar
    Size(1280, 800), // Layar web / desktop
  ]) {
    testWidgets(
      'ProfileScreen renders lengkap tanpa overflow pada ukuran ${viewport.width.toInt()}x${viewport.height.toInt()}',
      (WidgetTester tester) async {
        tester.view.physicalSize = viewport;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await AuthService.saveSession(
          UserModel(
            id: 7,
            nama: 'Raka Pratama Wijaya',
            email: 'raka.pratama@museum.id',
            authProvider: 'local',
            avatarUrl: null,
            token: 'jwt_test_token',
            role: 'USER',
            createdAt: '2026-10-15T08:00:00.000Z',
          ),
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: ProfileScreen(isRootTab: true),
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));

        // Pastikan info akun & fallback inisial tampil
        expect(find.text('Raka Pratama Wijaya'), findsOneWidget);
        expect(find.text('raka.pratama@museum.id'), findsOneWidget);
        expect(find.text('R'), findsOneWidget);
        expect(find.text('Aktif • Pengunjung Terdaftar'), findsOneWidget);

        // Pastikan tombol ganti foto ada pada avatar
        expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);

        // Pastikan ringkasan & navigasi aktivitas tampil
        expect(find.text('Tiket Saya'), findsOneWidget);
        expect(find.text('Obrolan AI'), findsOneWidget);
        expect(find.text('Koleksi'), findsOneWidget);
        expect(find.text('Asisten AI Museum Brawijaya'), findsOneWidget);
        expect(find.text('Riwayat & Tiket Saya'), findsOneWidget);
        expect(find.text('Jelajahi Koleksi Bersejarah'), findsOneWidget);

        // Pastikan menu pengaturan & tombol logout tampil
        expect(find.text('Edit Profil'), findsOneWidget);
        expect(find.text('Ubah Kata Sandi'), findsOneWidget);
        expect(find.text('Tentang Museum Brawijaya'), findsOneWidget);
        expect(find.text('Keluar dari Akun'), findsOneWidget);

        // Tidak ada error overflow / exception selama render
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Dialog Ubah Kata Sandi & Konfirmasi Logout berjalan tanpa overflow', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await AuthService.saveSession(
      UserModel(
        id: 8,
        nama: 'Siti Rahayu',
        email: 'siti@museum.id',
        authProvider: 'local',
        token: 'jwt_test_token',
        role: 'USER',
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: ProfileScreen(isRootTab: true),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    // Buka dialog Ubah Kata Sandi
    await tester.scrollUntilVisible(find.text('Ubah Kata Sandi'), 200);
    await tester.tap(find.text('Ubah Kata Sandi'));
    await tester.pumpAndSettle();

    expect(find.text('Kata Sandi Saat Ini'), findsOneWidget);
    expect(find.text('Kata Sandi Baru'), findsOneWidget);
    expect(find.text('Konfirmasi Kata Sandi Baru'), findsOneWidget);

    // Validasi client-side saat form kosong
    await tester.tap(find.text('Simpan'));
    await tester.pump();
    expect(find.text('Kata Sandi Saat Ini'), findsOneWidget);
    expect(find.text('Kata sandi saat ini wajib diisi.'), findsOneWidget);

    // Tutup dialog Ubah Kata Sandi
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    // Buka dialog Konfirmasi Logout
    await tester.scrollUntilVisible(find.text('Keluar dari Akun'), 200);
    await tester.tap(find.text('Keluar dari Akun'));
    await tester.pumpAndSettle();

    expect(find.text('Konfirmasi Keluar'), findsOneWidget);
    expect(find.text('Ya, Keluar'), findsOneWidget);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
