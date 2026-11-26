import 'package:app/features/tiket/data/repositories/tiket_service.dart';

/// Kontrak repository untuk pemesanan tiket dan pembayaran Midtrans.
abstract interface class TiketRepository {
  Future<List<TiketCategory>> getCategories();

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
    Map<int, int> extraCategories = const {},
  });

  Future<Uri> createPayment(String bookingId);
  Future<PaymentStatusResult> checkPaymentStatus(String bookingId);
  Future<List<TicketBooking>> getMyBookings(String email);
  Future<TicketBooking> getBookingById(String id);
  Future<JamOperasional> getJamOperasional();
  Uri getTicketPdfUri(String bookingId);
  Uri getTicketQrUri(String bookingId);
}

/// Implementasi default [TiketRepository] berbasis [TiketService].
class DefaultTiketRepository implements TiketRepository {
  const DefaultTiketRepository();

  @override
  Future<List<TiketCategory>> getCategories() => TiketService.getCategories();

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
    Map<int, int> extraCategories = const {},
  }) =>
      TiketService.createBooking(
        nama: nama,
        email: email,
        phone: phone,
        dewasa: dewasa,
        pelajar: pelajar,
        wna: wna,
        sesi: sesi,
        visitDate: visitDate,
        paymentMethod: paymentMethod,
        isMancanegara: isMancanegara,
        extraCategories: extraCategories,
      );

  @override
  Future<Uri> createPayment(String bookingId) =>
      TiketService.createPayment(bookingId);

  @override
  Future<PaymentStatusResult> checkPaymentStatus(String bookingId) =>
      TiketService.checkPaymentStatus(bookingId);

  @override
  Future<List<TicketBooking>> getMyBookings(String email) =>
      TiketService.getMyBookings(email);

  @override
  Future<TicketBooking> getBookingById(String id) =>
      TiketService.getBookingById(id);

  @override
  Future<JamOperasional> getJamOperasional() =>
      TiketService.getJamOperasional();

  @override
  Uri getTicketPdfUri(String bookingId) =>
      TiketService.getTicketPdfUri(bookingId);

  @override
  Uri getTicketQrUri(String bookingId) =>
      TiketService.getTicketQrUri(bookingId);
}
