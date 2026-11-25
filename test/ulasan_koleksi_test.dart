import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/data/services/koleksi_service.dart';
import 'package:app/data/services/ulasan_service.dart';
import 'package:app/views/screens/koleksi/detail_generic_koleksi_screen.dart';
import 'package:app/views/screens/koleksi/koleksi_screen.dart';
import 'package:app/views/screens/tentang/tentang_screen.dart';

void main() {
  group('Model JSON parsing (null-safe)', () {
    test('KoleksiItem.fromJson handles string id and nullable fields safely', () {
      final item = KoleksiItem.fromJson({
        'id': '42',
        'kode': null,
        'nama': 'Senjata Katana Jepang',
        'sub_deskripsi': null,
        'deskripsi_lengkap': '   ',
        'kategori': null,
        'tahun': 1942,
        'lokasi': null,
        'status': null,
        'image_url': '  ',
      });

      expect(item.id, 42);
      expect(item.nama, 'Senjata Katana Jepang');
      expect(item.kategori, 'Umum');
      expect(item.tahun, '1942');
      expect(item.status, 'DIPAMERKAN');
      expect(item.deskripsiLengkap, isNull);
      expect(item.imageUrl, isNull);
    });

    test('UlasanItem.fromJson clamps rating and computes avatar initial safely', () {
      final item = UlasanItem.fromJson({
        'id': '7',
        'nama': 'setiawan aji',
        'avatar_initial': '',
        'rating': '5',
        'comment': 'sangat bagus',
        'created_at': '2026-11-22T00:38:00.000Z',
      });

      expect(item.id, 7);
      expect(item.nama, 'setiawan aji');
      expect(item.avatarInitial, 'S');
      expect(item.rating, 5);
      expect(item.comment, 'sangat bagus');
    });
  });

  group('KoleksiScreen', () {
    testWidgets(
      'renders fallback collection without unmodifiable-list crash across viewports',
      (tester) async {
        final viewports = <Size>[
          const Size(320, 640),
          const Size(390, 844),
          const Size(1280, 800),
        ];

        for (final size in viewports) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            MaterialApp(
              home: KoleksiScreen(
                koleksiLoader: () async => throw Exception('offline'),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Benda-Benda Bersejarah'), findsOneWidget);
          expect(find.text('Gerbong Maut'), findsOneWidget);
          expect(find.text('Semua'), findsOneWidget);
          expect(find.text('Kendaraan'), findsOneWidget);
          expect(find.text('Senjata'), findsOneWidget);
          expect(find.text('Dokumen'), findsNothing);
          expect(find.text('Pakaian'), findsNothing);
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'handles multiple backend items with empty images without duplicate ValueKey error and opens generic detail safely',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final items = [
          KoleksiItem(
            id: 101,
            kode: '#INV-MB-101',
            nama: 'Artefak Khusus Satu',
            subDeskripsi: 'Peninggalan 1945',
            deskripsiLengkap: 'Deskripsi lengkap artefak khusus pertama.',
            kategori: 'Senjata',
            tahun: '1945',
            lokasi:
                'Ruang Koleksi Senjata / Ruang Pameran Dalam Gedung Utama Lantai 1',
            status: 'DIPAMERKAN',
            imageUrl: null,
          ),
          KoleksiItem(
            id: 102,
            kode: '#INV-MB-102',
            nama: 'Artefak Khusus Dua',
            subDeskripsi: 'Peninggalan 1948',
            deskripsiLengkap: 'Deskripsi lengkap artefak khusus kedua.',
            kategori: 'Kendaraan',
            tahun: '1948',
            lokasi: 'Ruang Pameran Sejarah Lantai 2',
            status: 'DIPAMERKAN',
            imageUrl: null,
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: KoleksiScreen(
              koleksiLoader: () async => items,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Artefak Khusus Satu'), findsOneWidget);
        expect(find.text('Artefak Khusus Dua'), findsOneWidget);
        expect(find.text('Dokumen'), findsNothing);
        expect(find.text('Pakaian'), findsNothing);
        expect(tester.takeException(), isNull);

        // Filter kategori Kendaraan
        final kendaraanChip = find.text('Kendaraan');
        await tester.ensureVisible(kendaraanChip);
        await tester.tap(kendaraanChip);
        await tester.pumpAndSettle();
        expect(find.text('Artefak Khusus Dua'), findsOneWidget);
        expect(find.text('Artefak Khusus Satu'), findsNothing);

        // Kembali ke Semua lalu buka detail generic dengan lokasi panjang
        final semuaChip = find.text('Semua');
        await tester.ensureVisible(semuaChip);
        await tester.tap(semuaChip);
        await tester.pumpAndSettle();

        final detailButtons = find.text('Lihat Detail');
        expect(detailButtons, findsNWidgets(2));
        await tester.ensureVisible(detailButtons.last);
        await tester.tap(detailButtons.last);
        await tester.pumpAndSettle();

        expect(find.byType(DetailGenericKoleksiScreen), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Kembali ke Koleksi'));
        await tester.pumpAndSettle();
        expect(find.byType(KoleksiScreen), findsOneWidget);
      },
    );
  });

  group('TentangScreen Ulasan', () {
    testWidgets(
      'validates and submits review cleanly and displays it in list',
      (tester) async {
        tester.view.physicalSize = const Size(390, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final storedReviews = <UlasanItem>[
          UlasanItem(
            id: 2,
            nama: 'Pandu setiawan',
            avatarInitial: 'P',
            avatarColor: '#3F5243',
            category: 'Kunjungan Umum',
            rating: 5,
            comment: 'Sangat bagus dan bagi saya banyak belajar sejarah.',
            reply: '',
            replyDate: '',
            createdAt: '2026-11-11T15:08:50.000Z',
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: TentangScreen(
              reviewsLoader: () async => (
                items: List<UlasanItem>.from(storedReviews),
                stats: UlasanStats(
                  averageRating: storedReviews.fold<int>(
                        0,
                        (sum, r) => sum + r.rating,
                      ) /
                      storedReviews.length,
                  total: storedReviews.length,
                ),
              ),
              reviewSubmitter: ({
                required String nama,
                required int rating,
                required String comment,
                String category = 'Kunjungan Umum',
              }) async {
                final created = UlasanItem(
                  id: 3,
                  nama: nama,
                  avatarInitial: nama[0].toUpperCase(),
                  avatarColor: '#3F5243',
                  category: category,
                  rating: rating,
                  comment: comment,
                  reply: '',
                  replyDate: '',
                  createdAt: '2026-11-22T00:50:00.000Z',
                );
                storedReviews.insert(0, created);
                return created;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Pastikan ulasan dari backend muncul
        final writeReviewBtn = find.text('Tulis Ulasan');
        await tester.scrollUntilVisible(
          writeReviewBtn,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Pandu setiawan'), findsOneWidget);
        expect(find.text('1 ulasan'), findsOneWidget);

        // Buka form ulasan
        await tester.tap(writeReviewBtn);
        await tester.pumpAndSettle();

        // Pilih bintang 5
        final star5 = find.byKey(const ValueKey('rating-star-5'));
        await tester.ensureVisible(star5);
        await tester.tap(star5);
        await tester.pumpAndSettle();

        // Isi nama dan ulasan
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), 'setiawan aji');
        await tester.enterText(fields.at(1), 'sangat bagus');

        final submitBtn = find.text('Kirim Ulasan');
        await tester.ensureVisible(submitBtn);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();

        expect(find.text('Ulasan berhasil dikirim dan tersimpan!'), findsOneWidget);
        expect(find.text('setiawan aji'), findsOneWidget);
        expect(find.text('sangat bagus'), findsOneWidget);
        expect(find.text('2 ulasan'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
