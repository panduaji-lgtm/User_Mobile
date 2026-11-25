import 'package:app/core/network/api_client.dart';

/// Model kategori tiket dari backend
class TiketCategory {
  final int id;
  final String badge;
  final String badgeBg;
  final String badgeColor;
  final String title;
  final int price;
  final int kuota;
  final String status;

  TiketCategory({
    required this.id,
    required this.badge,
    required this.badgeBg,
    required this.badgeColor,
    required this.title,
    required this.price,
    required this.kuota,
    required this.status,
  });

  factory TiketCategory.fromJson(Map<String, dynamic> json) => TiketCategory(
    id: json['id'] as int,
    badge: json['badge'] as String,
    badgeBg: json['badge_bg'] as String? ?? '#fef3c7',
    badgeColor: json['badge_color'] as String? ?? '#92400e',
    title: json['title'] as String,
    price: json['price'] as int,
    kuota: json['kuota'] as int,
    status: json['status'] as String,
  );
}

/// Model pemesanan tiket
class TicketBooking {
  final String id;
  final String nama;
  final String email;
  final String? phone;
  final int kategoriDewasa;
  final int kategoriPelajar;
  final int kategoriWna;
  final int totalTiket;
  final int totalBiaya;
  final String sesi;
  final String visitDate;
  final String paymentMethod;
  final String status;
  final int checkedIn;
  final int isMancanegara;

  TicketBooking({
    required this.id,
    required this.nama,
    required this.email,
    this.phone,
    required this.kategoriDewasa,
    required this.kategoriPelajar,
    required this.kategoriWna,
    required this.totalTiket,
    required this.totalBiaya,
    required this.sesi,
    required this.visitDate,
    required this.paymentMethod,
    required this.status,
    required this.checkedIn,
    this.isMancanegara = 0,
  });

  factory TicketBooking.fromJson(Map<String, dynamic> json) => TicketBooking(
    id: json['id'] as String,
    nama: json['nama'] as String,
    email: json['email'] as String,
    phone: json['phone'] as String?,
    kategoriDewasa: json['kategori_dewasa'] as int? ?? 0,
    kategoriPelajar: json['kategori_pelajar'] as int? ?? 0,
    kategoriWna: json['kategori_wna'] as int? ?? 0,
    totalTiket: json['total_tiket'] as int,
    totalBiaya: json['total_biaya'] as int,
    sesi: json['sesi'] as String,
    visitDate: json['visit_date'] as String,
    paymentMethod: json['payment_method'] as String? ?? 'QRIS',
    status: json['status'] as String,
    checkedIn: json['checked_in'] as int? ?? 0,
    isMancanegara: json['is_mancanegara'] as int? ?? 0,
  );
}

/// Service untuk semua operasi tiket
class TiketService {
  /// Ambil semua kategori tiket yang aktif dari backend
  static Future<List<TiketCategory>> getCategories() async {
    final res = await ApiClient.get('/tiket/categories');
    final list = res['data'] as List<dynamic>;
    return list
        .map((e) => TiketCategory.fromJson(e as Map<String, dynamic>))
        .where((c) => c.status == 'Aktif')
        .toList();
  }

  /// Buat pemesanan tiket baru
  /// Mengembalikan [TicketBooking] yang baru dibuat
  static Future<TicketBooking> createBooking({
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
  }) async {
    final body = {
      'nama': nama,
      'email': email,
      if (phone != null) 'phone': phone,
      'kategori_dewasa': dewasa,
      'kategori_pelajar': pelajar,
      'kategori_wna': wna,
      'sesi': sesi,
      'visit_date': visitDate,
      'payment_method': paymentMethod,
      'is_mancanegara': isMancanegara,
    };
    final res = await ApiClient.post('/tiket/bookings', body);
    return TicketBooking.fromJson(res['data'] as Map<String, dynamic>);
  }

  /// Buat transaksi Midtrans untuk pemesanan yang sudah tersimpan.
  static Future<Uri> createPayment(String bookingId) async {
    final res = await ApiClient.post('/payments/create-transaction', {
      'bookingId': bookingId,
    });
    final redirectUrl = res['redirect_url'];
    if (redirectUrl is! String || redirectUrl.trim().isEmpty) {
      throw ApiException('URL pembayaran tidak tersedia dari server.');
    }

    final uri = Uri.tryParse(redirectUrl);
    if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http') || uri.host.isEmpty) {
      throw ApiException('URL pembayaran dari server tidak valid.');
    }
    return uri;
  }

  /// Ambil riwayat pemesanan berdasarkan email
  static Future<List<TicketBooking>> getMyBookings(String email) async {
    final res = await ApiClient.get(
      '/tiket/bookings?search=${Uri.encodeComponent(email)}&limit=50',
    );
    final list = res['data'] as List<dynamic>;
    return list
        .map((e) => TicketBooking.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Ambil detail 1 pemesanan berdasarkan ID
  static Future<TicketBooking> getBookingById(String id) async {
    final res = await ApiClient.get(
      '/tiket/bookings/${Uri.encodeComponent(id)}',
    );
    return TicketBooking.fromJson(res['data'] as Map<String, dynamic>);
  }

  /// Ambil jam operasional museum dari backend
  static Future<Map<String, String>> getJamOperasional() async {
    final res = await ApiClient.get('/informasi/jam-operasional');
    final data = res['data'] as Map<String, dynamic>?;
    return {
      'hari': (data?['hari'] as String?) ?? 'Selasa - Minggu (Senin Libur)',
      'jam': (data?['jam'] as String?) ?? '08:00 - 15:00 WIB',
      'telepon': (data?['telepon'] as String?) ?? '(0341) 551502',
    };
  }
}
