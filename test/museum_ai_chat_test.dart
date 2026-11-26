import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/core/network/api_client.dart';
import 'package:app/features/ai_chat/data/repositories/ai_chat_service.dart';
import 'package:app/features/auth/data/repositories/auth_service.dart';
import 'package:app/features/ai_chat/presentation/views/museum_ai_chat_screen.dart';

// 1x1 PNG transparan valid untuk simulasi upload gambar
final Uint8List _samplePngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+ip1sAAAAASUVORK5CYII=',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AiChatService.debugSendChatOverride = null;
    await AuthService.saveSession(
      UserModel(
        id: 11,
        nama: 'Bima Pratama',
        email: 'bima@museum.id',
        authProvider: 'local',
        token: 'jwt_test',
        role: 'USER',
      ),
    );
  });

  tearDown(() {
    AiChatService.debugSendChatOverride = null;
  });

  for (final viewport in const [
    Size(320, 640),
    Size(390, 844),
    Size(1280, 800),
  ]) {
    testWidgets(
      'MuseumAiChatScreen welcome screen, tombol + upload gambar & tanpa banner kuis render tanpa overflow (${viewport.width.toInt()}x${viewport.height.toInt()})',
      (WidgetTester tester) async {
        tester.view.physicalSize = viewport;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(const MaterialApp(home: MuseumAiChatScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Halo, Bima!'), findsOneWidget);
        expect(find.text('Sejarah & makna Gerbong Maut'), findsOneWidget);
        expect(
          find.text('Koleksi ikonik halaman & ruang museum'),
          findsOneWidget,
        );
        expect(
          find.text('Rekomendasi rute tur 30 menit vs 1 jam'),
          findsOneWidget,
        );
        expect(
          find.text('Info jam buka, lokasi & cara pesan e-tiket'),
          findsOneWidget,
        );
        // Pastikan shortcut kuis artefak lama sudah terhapus bersih
        expect(find.textContaining('Kuis Artefak'), findsNothing);
        expect(find.textContaining('kuis interaktif'), findsNothing);
        // Pastikan tombol + upload gambar hadir di sebelah input
        expect(find.byTooltip('Unggah gambar'), findsOneWidget);
        expect(find.byIcon(Icons.add_rounded), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Multi-turn chat, Markdown rendering, Copy, Quick Actions, Follow-up, History & New Chat berfungsi',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(412, 860);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final capturedTurns = <int>[];
      AiChatService.debugSendChatOverride = ({
        required List<Map<String, String>> messages,
        String? visitorName,
        Map<String, dynamic>? image,
      }) async {
        capturedTurns.add(messages.length);
        return AiChatReplyResult(
          reply:
              '### Gerbong Maut (1947)\n- **Peristiwa:** 23 November 1947\n- **Lokasi:** Halaman Tengah Museum Brawijaya',
          mode: 'local_fallback',
          model: 'museum-knowledge-engine',
          followUpSuggestions: const ['Ceritakan lebih detail tentang itu'],
          quickActions: const [
            AiQuickAction(
              type: 'koleksi',
              label: 'Jelajahi Koleksi',
              route: '/koleksi',
            ),
            AiQuickAction(
              type: 'tiket',
              label: 'Pesan E-Tiket',
              route: '/tiket',
            ),
          ],
        );
      };

      await tester.pumpWidget(const MaterialApp(home: MuseumAiChatScreen()));
      await tester.pumpAndSettle();

      // Turn 1: klik Prompt Starter
      await tester.tap(find.text('Sejarah & makna Gerbong Maut'));
      await tester.pumpAndSettle();

      expect(capturedTurns, [1]);
      expect(find.textContaining('Gerbong Maut (1947)'), findsOneWidget);
      expect(find.text('Salin'), findsOneWidget);
      expect(find.text('Bagikan'), findsOneWidget);
      expect(find.text('Jelajahi Koleksi'), findsOneWidget);
      expect(find.text('Pesan E-Tiket'), findsOneWidget);
      expect(find.text('Ceritakan lebih detail tentang itu'), findsOneWidget);

      // Turn 2: klik Follow-up chip -> harus mengirim 3 pesan (user, assistant, user)
      await tester.ensureVisible(
        find.text('Ceritakan lebih detail tentang itu'),
      );
      await tester.tap(find.text('Ceritakan lebih detail tentang itu'));
      await tester.pumpAndSettle();

      expect(capturedTurns, [1, 3]);

      // Pastikan tersimpan ke SharedPreferences
      final saved = await AiChatService.loadSessions();
      expect(saved.length, 1);
      expect(saved.first.messages.length, 4);

      // Klik Percakapan Baru (+) -> kembali ke welcome screen
      await tester.tap(find.byTooltip('Percakapan Baru'));
      await tester.pumpAndSettle();
      expect(find.text('Halo, Bima!'), findsOneWidget);

      // Buka Riwayat Obrolan -> sesi tersimpan tampil dan bisa dibuka kembali
      await tester.tap(find.byTooltip('Riwayat Obrolan'));
      await tester.pumpAndSettle();
      expect(find.text('Riwayat Obrolan'), findsOneWidget);
      expect(find.textContaining('4 pesan'), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Tombol + upload gambar menampilkan preview, bisa dihapus, dan mengirim gambar multimodal ke Asisten AI',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      Map<String, dynamic>? capturedImage;
      String? capturedText;

      AiChatService.debugSendChatOverride = ({
        required List<Map<String, String>> messages,
        String? visitorName,
        Map<String, dynamic>? image,
      }) async {
        capturedImage = image;
        capturedText = messages.last['content'];
        return const AiChatReplyResult(
          reply:
              '### Analisis Gambar Koleksi\nFoto yang Anda unggah menampilkan **Gerbong Maut (GR 10152)** di Museum Brawijaya Malang.',
          mode: 'gemini',
          model: 'gemini-3.5-flash-lite',
          followUpSuggestions: ['Ceritakan kronologi peristiwa 1947'],
          quickActions: [
            AiQuickAction(
              type: 'koleksi',
              label: 'Jelajahi Koleksi',
              route: '/koleksi',
            ),
          ],
        );
      };

      await tester.pumpWidget(
        MaterialApp(
          home: MuseumAiChatScreen(
            imagePickerOverride: (_) async => AiChatImageAttachment(
              bytes: _samplePngBytes,
              mimeType: 'image/png',
              fileName: 'gerbong_maut.png',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Klik tombol + -> preview gambar muncul
      await tester.tap(find.byTooltip('Unggah gambar'));
      await tester.pumpAndSettle();

      expect(find.text('gerbong_maut.png'), findsOneWidget);
      expect(find.byTooltip('Hapus gambar'), findsOneWidget);

      // Uji hapus gambar lalu lampirkan kembali
      await tester.tap(find.byTooltip('Hapus gambar'));
      await tester.pumpAndSettle();
      expect(find.text('gerbong_maut.png'), findsNothing);

      await tester.tap(find.byTooltip('Unggah gambar'));
      await tester.pumpAndSettle();
      expect(find.text('gerbong_maut.png'), findsOneWidget);

      // Ketik pertanyaan lalu kirim
      await tester.enterText(
        find.byType(TextField),
        'Ini koleksi apa di Museum Brawijaya?',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(capturedImage, isNotNull);
      expect(capturedImage!['mimeType'], 'image/png');
      expect(capturedImage!['fileName'], 'gerbong_maut.png');
      expect((capturedImage!['base64'] as String).isNotEmpty, isTrue);
      expect(capturedText, 'Ini koleksi apa di Museum Brawijaya?');

      // Preview sudah dibersihkan setelah kirim, jawaban AI & gambar di bubble tampil
      expect(find.byTooltip('Hapus gambar'), findsNothing);
      expect(find.textContaining('Analisis Gambar Koleksi'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Error handling menampilkan tombol Coba Lagi dan berhasil retry', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    var attempt = 0;
    AiChatService.debugSendChatOverride = ({
      required List<Map<String, String>> messages,
      String? visitorName,
      Map<String, dynamic>? image,
    }) async {
      attempt++;
      if (attempt == 1) {
        throw ApiException('Koneksi ke server terputus.');
      }
      return const AiChatReplyResult(
        reply:
            '**Berhasil tersambung!** Jam buka Museum Brawijaya adalah 08:00 - 15:00 WIB.',
        mode: 'gemini',
        model: 'gemini-3.5-flash-lite',
        followUpSuggestions: [],
        quickActions: [],
      );
    };

    await tester.pumpWidget(const MaterialApp(home: MuseumAiChatScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Info jam buka, lokasi & cara pesan e-tiket'));
    await tester.pumpAndSettle();

    expect(find.text('Koneksi ke server terputus.'), findsOneWidget);
    expect(find.text('Coba Lagi'), findsOneWidget);

    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();

    expect(attempt, 2);
    expect(find.textContaining('08:00 - 15:00 WIB'), findsOneWidget);
    expect(find.text('Gemini AI'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
