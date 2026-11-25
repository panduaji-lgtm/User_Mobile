import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/data/repositories/ai_chat_repository.dart';
import 'package:app/data/repositories/koleksi_repository.dart';
import 'package:app/data/repositories/tiket_repository.dart';
import 'package:app/data/repositories/ulasan_repository.dart';
import 'package:app/data/services/auth_service.dart';
import 'package:app/models/models.dart';
import 'package:app/viewmodels/ai_chat_viewmodel.dart';
import 'package:app/viewmodels/auth_viewmodel.dart';
import 'package:app/viewmodels/koleksi_viewmodel.dart';
import 'package:app/viewmodels/tiket_viewmodel.dart';
import 'package:app/viewmodels/ulasan_viewmodel.dart';
import 'package:app/views/screens/ai/museum_ai_chat_screen.dart';
import 'package:app/views/screens/koleksi/koleksi_screen.dart';
import 'package:app/views/screens/tiket/tiket_screen.dart';

class _FakeKoleksiRepository implements KoleksiRepository {
  @override
  Future<List<KoleksiItem>> getAll({
    String? search,
    String? kategori,
    int limit = 50,
  }) async =>
      [
        KoleksiItem(
          id: 1,
          kode: 'MB-01',
          nama: 'Gerbong Maut',
          subDeskripsi: 'Kereta bersejarah 1947',
          kategori: 'Kendaraan',
          tahun: '1947',
          lokasi: 'Halaman Tengah',
          status: 'DIPAMERKAN',
        ),
        KoleksiItem(
          id: 2,
          kode: 'MB-02',
          nama: 'Meriam Si Buang',
          subDeskripsi: 'Artileri perjuangan',
          kategori: 'Senjata',
          tahun: '1945',
          lokasi: 'Halaman Depan',
          status: 'DIPAMERKAN',
        ),
      ];

  @override
  Future<KoleksiItem> getById(int id) async => (await getAll()).first;
}

class _FakeAiChatRepository implements AiChatRepository {
  final List<AiChatSession> _sessions = [];

  @override
  Future<List<String>> getSuggestions() async =>
      const ['Sejarah Gerbong Maut', 'Jam buka Museum Brawijaya'];

  @override
  Future<AiChatReplyResult> sendChat({
    required List<AiChatMessage> history,
    String? visitorName,
    AiChatImageAttachment? image,
  }) async =>
      const AiChatReplyResult(
        reply: 'Gerbong Maut merupakan monumen heroik 23 November 1947.',
        mode: 'gemini',
        model: 'gemini-3.5-flash-lite',
        followUpSuggestions: ['Apa koleksi ikonik lainnya?'],
        quickActions: [
          AiQuickAction(
            type: 'koleksi',
            label: 'Jelajahi Koleksi',
            route: '/koleksi',
          ),
        ],
      );

  @override
  Future<List<AiChatSession>> loadSessions() async =>
      List<AiChatSession>.from(_sessions);

  @override
  Future<List<AiChatSession>> upsertSession(AiChatSession session) async {
    _sessions.removeWhere((s) => s.id == session.id);
    _sessions.insert(0, session);
    return List<AiChatSession>.from(_sessions);
  }

  @override
  Future<List<AiChatSession>> deleteSession(String sessionId) async {
    _sessions.removeWhere((s) => s.id == sessionId);
    return List<AiChatSession>.from(_sessions);
  }
}

class _FakeTiketRepository implements TiketRepository {
  final TicketBooking _booking = TicketBooking(
    id: '#MB-20261123-01',
    nama: 'Setiawan Aji',
    email: 'aji@museum.id',
    kategoriDewasa: 1,
    kategoriPelajar: 0,
    kategoriWna: 0,
    totalTiket: 1,
    totalBiaya: 10000,
    sesi: '08:00 - 10:00',
    visitDate: '2026-11-24',
    paymentMethod: 'QRIS',
    status: 'MENUNGGU',
    checkedIn: 0,
  );

  @override
  Future<List<TiketCategory>> getCategories() async => [
        TiketCategory(
          id: 1,
          badge: 'DEWASA',
          badgeBg: '#fef3c7',
          badgeColor: '#92400e',
          title: 'Tiket Reguler',
          price: 10000,
          kuota: 500,
          status: 'Aktif',
        ),
      ];

  @override
  Future<TicketBooking> createBooking({
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
      _booking;

  @override
  Future<Uri> createPayment(String bookingId) async =>
      Uri.parse('https://app.sandbox.midtrans.com/snap/v4/redirection/demo');

  @override
  Future<PaymentStatusResult> checkPaymentStatus(String bookingId) async =>
      PaymentStatusResult(
        bookingStatus: 'LUNAS',
        transactionStatus: 'settlement',
        message: 'Pembayaran lunas',
        booking: _booking.copyWith(status: 'LUNAS'),
      );

  @override
  Future<List<TicketBooking>> getMyBookings(String email) async => [_booking];

  @override
  Future<TicketBooking> getBookingById(String id) async => _booking;

  @override
  Uri getTicketPdfUri(String bookingId) => Uri.parse(
        'http://localhost:3001/api/payment/ticket-pdf/${Uri.encodeComponent(bookingId)}',
      );

  @override
  Uri getTicketQrUri(String bookingId) => Uri.parse(
        'http://localhost:3001/api/payment/ticket-qr/${Uri.encodeComponent(bookingId)}',
      );
}

class _FakeUlasanRepository implements UlasanRepository {
  @override
  Future<({List<UlasanItem> items, UlasanStats stats})> getAll({
    int limit = 50,
  }) async =>
      (
        items: [
          UlasanItem(
            id: 1,
            nama: 'Budi',
            avatarInitial: 'B',
            avatarColor: '#3F5243',
            category: 'Kunjungan Umum',
            rating: 5,
            comment: 'Koleksi sangat terawat',
            reply: '',
            replyDate: '',
            createdAt: '2026-11-22T08:00:00Z',
          ),
        ],
        stats: UlasanStats(averageRating: 5.0, total: 1),
      );

  @override
  Future<UlasanItem> submitReview({
    required String nama,
    required int rating,
    required String comment,
    String category = 'Kunjungan Umum',
  }) async =>
      UlasanItem(
        id: 2,
        nama: nama,
        avatarInitial: nama[0].toUpperCase(),
        avatarColor: '#3F5243',
        category: category,
        rating: rating,
        comment: comment,
        reply: '',
        replyDate: '',
        createdAt: '2026-11-23T08:00:00Z',
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthService.logout();
  });

  test('KoleksiViewModel hanya menyediakan kategori Semua, Kendaraan, Senjata dan memfilter dengan benar', () async {
    final vm = KoleksiViewModel(repository: _FakeKoleksiRepository());
    expect(KoleksiViewModel.categories, ['Semua', 'Kendaraan', 'Senjata']);

    await vm.loadKoleksi();
    expect(vm.filteredItems.length, 2);

    vm.selectCategory(1); // Kendaraan
    expect(vm.filteredItems.length, 1);
    expect(vm.filteredItems.first.nama, 'Gerbong Maut');

    vm.selectCategory(2); // Senjata
    expect(vm.filteredItems.length, 1);
    expect(vm.filteredItems.first.nama, 'Meriam Si Buang');

    vm.selectCategory(0);
    vm.setSearchQuery('gerbong');
    expect(vm.filteredItems.length, 1);
    vm.dispose();
  });

  test('AiChatViewModel mendukung pesan multimodal gambar, saran, dan riwayat sesi', () async {
    final vm = AiChatViewModel(repository: _FakeAiChatRepository());
    await vm.loadSuggestions();
    expect(vm.suggestions, contains('Sejarah Gerbong Maut'));

    vm.setPendingImage(
      AiChatImageAttachment(
        bytes: Uint8List.fromList([1, 2, 3]),
        mimeType: 'image/png',
        fileName: 'foto.png',
      ),
    );
    expect(vm.pendingImage, isNotNull);

    await vm.sendMessage(rawPrompt: 'Ini artefak apa?');
    expect(vm.pendingImage, isNull);
    expect(vm.activeSession.messages.length, 2);
    expect(vm.savedSessions.length, 1);
    expect(vm.activeSession.messages.first.imageName, 'foto.png');

    final sessionId = vm.activeSession.id;
    await vm.deleteSession(sessionId);
    expect(vm.savedSessions, isEmpty);
    vm.dispose();
  });

  test('TiketViewModel mengelola pemesanan, Midtrans URL, dan verifikasi LUNAS', () async {
    final vm = TiketViewModel(repository: _FakeTiketRepository());
    await vm.loadCategories();
    expect(vm.categories.length, 1);

    final booking = await vm.createBooking(
      nama: 'Setiawan Aji',
      email: 'aji@museum.id',
      dewasa: 1,
      pelajar: 0,
      wna: 0,
      sesi: '08:00 - 10:00',
      visitDate: '2026-11-24',
      paymentMethod: 'QRIS',
    );
    expect(booking.id, '#MB-20261123-01');

    final uri = await vm.createPayment(booking.id);
    expect(uri.host, contains('midtrans.com'));

    final status = await vm.checkPaymentStatus(booking.id);
    expect(status.isPaid, isTrue);
    expect(vm.currentBooking?.isPaid, isTrue);
    vm.dispose();
  });

  test('UlasanViewModel memuat statistik dan memperbarui daftar saat submit ulasan', () async {
    final vm = UlasanViewModel(repository: _FakeUlasanRepository());
    await vm.loadReviews();
    expect(vm.items.length, 1);
    expect(vm.stats.total, 1);

    await vm.submitReview(nama: 'Siti', rating: 4, comment: 'Sangat edukatif');
    expect(vm.items.length, 2);
    expect(vm.stats.total, 2);
    expect(vm.stats.averageRating, 4.5);
    vm.dispose();
  });

  test('AuthViewModel bereaksi terhadap sesi pengguna secara reaktif', () async {
    final vm = AuthViewModel();
    var notified = 0;
    vm.addListener(() => notified++);

    expect(vm.isLoggedIn, isFalse);
    await AuthService.saveSession(
      UserModel(
        id: 1,
        nama: 'Pengunjung',
        email: 'user@museum.id',
        authProvider: 'google',
        token: 'jwt_token',
      ),
    );
    expect(vm.isLoggedIn, isTrue);
    expect(notified, greaterThan(0));
    vm.dispose();
  });

  testWidgets(
    'KoleksiScreen, MuseumAiChatScreen, dan TiketScreen terhubung langsung ke ViewModel (end-to-end MVVM)',
    (WidgetTester tester) async {
      // 1. KoleksiScreen membaca data & filter dari KoleksiViewModel
      final koleksiVm = KoleksiViewModel(repository: _FakeKoleksiRepository());
      await tester.pumpWidget(
        MaterialApp(home: KoleksiScreen(viewModel: koleksiVm)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gerbong Maut'), findsOneWidget);
      expect(find.text('Meriam Si Buang'), findsOneWidget);

      await tester.tap(find.text('Senjata'));
      await tester.pumpAndSettle();
      expect(koleksiVm.selectedCategory, 'Senjata');
      expect(find.text('Meriam Si Buang'), findsOneWidget);
      expect(find.text('Gerbong Maut'), findsNothing);
      koleksiVm.dispose();

      // 2. MuseumAiChatScreen mengirim prompt & merender balasan dari AiChatViewModel
      final aiVm = AiChatViewModel(repository: _FakeAiChatRepository());
      final authVm = AuthViewModel();
      await tester.pumpWidget(
        MaterialApp(
          home: MuseumAiChatScreen(viewModel: aiVm, authViewModel: authVm),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Ceritakan Gerbong Maut');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(aiVm.activeSession.messages.length, 2);
      expect(
        find.textContaining('Gerbong Maut merupakan monumen heroik'),
        findsOneWidget,
      );
      aiVm.dispose();
      authVm.dispose();

      // 3. TiketScreen memuat kategori & membuat booking lewat TiketViewModel
      final tiketVm = TiketViewModel(repository: _FakeTiketRepository());
      final tiketAuthVm = AuthViewModel();
      await tester.pumpWidget(
        MaterialApp(
          home: TiketScreen(
            onGoHome: () {},
            viewModel: tiketVm,
            authViewModel: tiketAuthVm,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tiketVm.categories.length, 1);
      expect(find.text('Formulir Pemesanan Tiket'), findsOneWidget);
      tiketVm.dispose();
      tiketAuthVm.dispose();
    },
  );
}
