import 'package:app/core/network/api_client.dart';
import 'package:app/models/tiket_models.dart';

export 'package:app/models/tiket_models.dart';

String _parseString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  return value.toString();
}

/// Service untuk semua operasi tiket dan pembayaran Midtrans
class TiketService {
  /// Ambil semua kategori tiket yang aktif dari backend
  static Future<List<TiketCategory>> getCategories() async {
    final res = await ApiClient.get('/tiket/categories');
    final rawList = res['data'];
    final list = rawList is List<dynamic> ? rawList : const <dynamic>[];
    return list
        .whereType<Map<String, dynamic>>()
        .map(TiketCategory.fromJson)
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
    final trimmedPhone = phone?.trim();
    final body = <String, dynamic>{
      'nama': nama.trim(),
      'email': email.trim(),
      if (trimmedPhone != null && trimmedPhone.isNotEmpty)
        'phone': trimmedPhone,
      'kategori_dewasa': dewasa,
      'kategori_pelajar': pelajar,
      'kategori_wna': wna,
      'sesi': sesi,
      'visit_date': visitDate,
      'payment_method': paymentMethod,
      'is_mancanegara': isMancanegara,
    };
    final res = await ApiClient.post('/tiket/bookings', body);
    final data = res['data'];
    if (data is Map<String, dynamic>) {
      return TicketBooking.fromJson(data);
    }
    throw ApiException('Data pemesanan tidak valid dari server.');
  }

  /// Buat transaksi Midtrans untuk pemesanan yang sudah tersimpan.
  static Future<Uri> createPayment(String bookingId) async {
    Map<String, dynamic> res;
    try {
      // Endpoint utama backend adalah /payment/create-transaction
      res = await ApiClient.post(
        '/payment/create-transaction',
        {'bookingId': bookingId},
        timeout: const Duration(seconds: 15),
      );
    } on ApiException catch (e) {
      // Fallback jika backend mengarahkan ke /payments/create-transaction
      if (e.statusCode == 404) {
        res = await ApiClient.post(
          '/payments/create-transaction',
          {'bookingId': bookingId},
          timeout: const Duration(seconds: 15),
        );
      } else {
        rethrow;
      }
    }

    final redirectUrl = res['redirect_url'] ??
        res['redirectUrl'] ??
        (res['data'] is Map
            ? (res['data']['redirect_url'] ?? res['data']['redirectUrl'])
            : null);

    if (redirectUrl is! String || redirectUrl.trim().isEmpty) {
      throw ApiException('URL pembayaran tidak tersedia dari server.');
    }

    final uri = Uri.tryParse(redirectUrl.trim());
    if (uri == null || (!uri.scheme.startsWith('http')) || uri.host.isEmpty) {
      throw ApiException('URL pembayaran dari server tidak valid.');
    }
    return uri;
  }

  /// Verifikasi status pembayaran langsung ke backend + Midtrans
  static Future<PaymentStatusResult> checkPaymentStatus(String bookingId) async {
    Map<String, dynamic> res;
    try {
      res = await ApiClient.post(
        '/payment/status',
        {'bookingId': bookingId},
        timeout: const Duration(seconds: 15),
      );
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        res = await ApiClient.post(
          '/payments/status',
          {'bookingId': bookingId},
          timeout: const Duration(seconds: 15),
        );
      } else {
        rethrow;
      }
    }

    final rawBooking = res['data'];
    final booking = rawBooking is Map<String, dynamic>
        ? TicketBooking.fromJson(rawBooking)
        : null;
    final bookingStatus = _parseString(
      res['bookingStatus'] ?? booking?.status,
      fallback: 'MENUNGGU',
    ).trim();
    final transactionStatus = _parseString(
      res['transactionStatus'],
      fallback: 'pending',
    ).trim();
    final message = _parseString(
      res['message'],
      fallback: 'Status pembayaran berhasil diperiksa.',
    ).trim();
    final pdfUrl = _parseString(res['pdfUrl'] ?? res['pdf_url']).trim();
    final qrImageUrl =
        _parseString(res['qrImageUrl'] ?? res['qr_image_url']).trim();

    return PaymentStatusResult(
      bookingStatus: bookingStatus,
      transactionStatus: transactionStatus,
      message: message,
      booking: booking,
      pdfUrl: pdfUrl.isNotEmpty ? pdfUrl : null,
      qrImageUrl: qrImageUrl.isNotEmpty ? qrImageUrl : null,
    );
  }

  /// URL unduh E-Tiket PDF untuk pemesanan berstatus LUNAS
  static Uri getTicketPdfUri(String bookingId) => Uri.parse(
        '$kBaseUrl/payment/ticket-pdf/${Uri.encodeComponent(bookingId.trim())}',
      );

  /// URL gambar QR Code check-in E-Tiket
  static Uri getTicketQrUri(String bookingId) => Uri.parse(
        '$kBaseUrl/payment/ticket-qr/${Uri.encodeComponent(bookingId.trim())}',
      );

  /// Ambil riwayat pemesanan berdasarkan email
  static Future<List<TicketBooking>> getMyBookings(String email) async {
    final res = await ApiClient.get(
      '/tiket/bookings?search=${Uri.encodeComponent(email.trim())}&limit=50',
    );
    final rawList = res['data'];
    final list = rawList is List<dynamic> ? rawList : const <dynamic>[];
    return list
        .whereType<Map<String, dynamic>>()
        .map(TicketBooking.fromJson)
        .toList();
  }

  /// Ambil detail 1 pemesanan berdasarkan ID
  static Future<TicketBooking> getBookingById(String id) async {
    final res = await ApiClient.get(
      '/tiket/bookings/${Uri.encodeComponent(id)}',
    );
    final data = res['data'];
    if (data is Map<String, dynamic>) {
      return TicketBooking.fromJson(data);
    }
    throw ApiException('Data pemesanan tidak ditemukan.');
  }
}
