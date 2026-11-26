import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/tiket/data/repositories/tiket_service.dart';
import 'package:app/features/tiket/presentation/views/tiket_screen.dart';

void main() {
  group('TiketService JSON parsing (null-safe)', () {
    test('TiketCategory & TicketBooking handle numeric strings & null safely',
        () {
      final cat = TiketCategory.fromJson({
        'id': '1',
        'badge': 'UMUM / DEWASA',
        'title': 'Tiket Reguler',
        'price': '10000',
        'kuota': '500',
        'status': 'Aktif',
      });
      expect(cat.id, 1);
      expect(cat.price, 10000);

      final booking = TicketBooking.fromJson({
        'id': '#MB-20261122-01',
        'nama': 'Setiawan Aji',
        'email': 'setiawan@museum.online',
        'phone': null,
        'kategori_dewasa': '2',
        'total_tiket': '2',
        'total_biaya': '20000',
        'sesi': '08:00 - 10:00',
        'visit_date': '2026-11-25',
        'status': 'MENUNGGU',
      });
      expect(booking.id, '#MB-20261122-01');
      expect(booking.totalBiaya, 20000);
      expect(booking.isPaid, isFalse);
    });
  });

  group('TiketScreen & Alur Pembayaran Midtrans', () {
    testWidgets(
      'renders cleanly across narrow, mobile, and desktop viewports with zero overflow',
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
              home: TiketScreen(
                onGoHome: () {},
                categoriesLoader: () async => [
                  TiketCategory(
                    id: 1,
                    badge: 'UMUM / DEWASA',
                    badgeBg: '#fef3c7',
                    badgeColor: '#92400e',
                    title: 'Dewasa',
                    price: 10000,
                    kuota: 500,
                    status: 'Aktif',
                  ),
                ],
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Formulir Pemesanan Tiket'), findsOneWidget);
          expect(find.text('Bayar Tiket Sekarang'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'completes full booking -> Midtrans instruction -> check status LUNAS -> E-Ticket flow',
      (tester) async {
        tester.view.physicalSize = const Size(390, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final createdBooking = TicketBooking(
          id: '#MB-20261122-01',
          nama: 'Setiawan Aji',
          email: 'setiawan@museum.online',
          phone: '+6281234567890',
          kategoriDewasa: 1,
          kategoriPelajar: 0,
          kategoriWna: 0,
          totalTiket: 1,
          totalBiaya: 10000,
          sesi: '08:00 - 10:00',
          visitDate: '2026-11-25',
          paymentMethod: 'QRIS',
          status: 'MENUNGGU',
          checkedIn: 0,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: TiketScreen(
              onGoHome: () {},
              categoriesLoader: () async => [
                TiketCategory(
                  id: 1,
                  badge: 'UMUM / DEWASA',
                  badgeBg: '#fef3c7',
                  badgeColor: '#92400e',
                  title: 'Dewasa',
                  price: 10000,
                  kuota: 500,
                  status: 'Aktif',
                ),
              ],
              bookingCreator: ({
                required String nama,
                required String email,
                String? phone,
                required int dewasa,
                required int pelajar,
                required int wna,
                required String sesi,
                required String visitDate,
                required String paymentMethod,
                int isMancanegara = 0,
              }) async =>
                  createdBooking,
              paymentCreator: (id) async => Uri.parse(
                'https://app.sandbox.midtrans.com/snap/v4/redirection/test-token',
              ),
              statusChecker: (id) async => PaymentStatusResult(
                bookingStatus: 'LUNAS',
                transactionStatus: 'settlement',
                message: 'Pembayaran berhasil diverifikasi!',
                booking: createdBooking.copyWith(status: 'LUNAS'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Isi nama, email (domain >4 huruf valid), telepon
        final fields = find.byType(TextField);
        await tester.enterText(fields.at(0), 'Setiawan Aji');
        await tester.enterText(fields.at(1), 'setiawan@museum.online');
        await tester.enterText(fields.at(2), '081234567890');

        // Klik Bayar Tiket Sekarang -> Step 1 Instruksi Pembayaran
        final payBtn = find.text('Bayar Tiket Sekarang');
        await tester.scrollUntilVisible(
          payBtn,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(payBtn);
        await tester.pumpAndSettle();

        expect(find.text('Instruksi Pembayaran'), findsOneWidget);
        expect(find.text('#MB-20261122-01'), findsOneWidget);
        expect(find.text('Cek Status Pembayaran'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Klik Cek Status Pembayaran -> langsung jadi Step 2 E-Tiket LUNAS
        final checkBtn = find.text('Cek Status Pembayaran');
        await tester.ensureVisible(checkBtn);
        await tester.tap(checkBtn);
        await tester.pumpAndSettle();

        expect(find.text('PEMBAYARAN BERHASIL'), findsOneWidget);
        expect(find.text('E-Tiket Museum Brawijaya Aktif'), findsOneWidget);
        expect(find.text('LUNAS'), findsOneWidget);
        expect(find.text('Download E-Tiket (PDF)'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
