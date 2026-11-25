import 'package:flutter/foundation.dart';

import 'package:app/data/repositories/tiket_repository.dart';
import 'package:app/models/tiket_models.dart';

/// ViewModel untuk alur pemesanan tiket, pembayaran Midtrans, verifikasi status, dan riwayat tiket.
class TiketViewModel extends ChangeNotifier {
  final TiketRepository _repository;

  List<TiketCategory> _categories = const [];
  bool _loadingCategories = false;
  bool _submitting = false;
  bool _openingPayment = false;
  bool _checkingStatus = false;
  bool _downloadingPdf = false;
  TicketBooking? _currentBooking;
  Uri? _paymentUri;
  String? _pdfUrl;
  String? _qrImageUrl;
  String? _statusNote;
  String? _errorMessage;
  bool _disposed = false;

  TiketViewModel({TiketRepository? repository})
      : _repository = repository ?? const DefaultTiketRepository();

  List<TiketCategory> get categories => List.unmodifiable(_categories);
  bool get loadingCategories => _loadingCategories;
  bool get submitting => _submitting;
  bool get openingPayment => _openingPayment;
  bool get checkingStatus => _checkingStatus;
  bool get downloadingPdf => _downloadingPdf;
  TicketBooking? get currentBooking => _currentBooking;
  Uri? get paymentUri => _paymentUri;
  String? get pdfUrl => _pdfUrl;
  String? get qrImageUrl => _qrImageUrl;
  String? get statusNote => _statusNote;
  String? get errorMessage => _errorMessage;

  void _safeNotify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  void setOpeningPayment(bool value) {
    if (_openingPayment == value) return;
    _openingPayment = value;
    _safeNotify();
  }

  void setDownloadingPdf(bool value) {
    if (_downloadingPdf == value) return;
    _downloadingPdf = value;
    _safeNotify();
  }

  Uri getTicketPdfUri(String bookingId) {
    final fromServer = _pdfUrl?.trim() ?? '';
    if (fromServer.isNotEmpty) {
      final parsed = Uri.tryParse(fromServer);
      if (parsed != null && parsed.hasScheme && parsed.host.isNotEmpty) {
        return parsed;
      }
    }
    return _repository.getTicketPdfUri(bookingId);
  }

  Uri getTicketQrUri(String bookingId) {
    final fromServer = _qrImageUrl?.trim() ?? '';
    if (fromServer.isNotEmpty) {
      final parsed = Uri.tryParse(fromServer);
      if (parsed != null && parsed.hasScheme && parsed.host.isNotEmpty) {
        return parsed;
      }
    }
    return _repository.getTicketQrUri(bookingId);
  }

  void selectBooking(TicketBooking booking) {
    _currentBooking = booking;
    _paymentUri = null;
    _pdfUrl = null;
    _qrImageUrl = null;
    _statusNote = null;
    _errorMessage = null;
    _safeNotify();
  }

  Future<List<TiketCategory>> loadCategories({
    Future<List<TiketCategory>> Function()? loaderOverride,
  }) async {
    _loadingCategories = true;
    _errorMessage = null;
    _safeNotify();
    try {
      final fetched = loaderOverride != null
          ? await loaderOverride()
          : await _repository.getCategories();
      _categories = List<TiketCategory>.from(fetched);
      return _categories;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _loadingCategories = false;
      _safeNotify();
    }
  }

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
    Future<TicketBooking> Function({
      required String nama,
      required String email,
      String? phone,
      required int dewasa,
      required int pelajar,
      required int wna,
      required String sesi,
      required String visitDate,
      required String paymentMethod,
      int isMancanegara,
    })? creatorOverride,
  }) async {
    _submitting = true;
    _errorMessage = null;
    _safeNotify();
    try {
      final booking = creatorOverride != null
          ? await creatorOverride(
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
            )
          : await _repository.createBooking(
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
            );
      _currentBooking = booking;
      _paymentUri = null;
      _pdfUrl = null;
      _qrImageUrl = null;
      _statusNote = null;
      return booking;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _submitting = false;
      _safeNotify();
    }
  }

  Future<Uri> createPayment(
    String bookingId, {
    Future<Uri> Function(String bookingId)? creatorOverride,
  }) async {
    final uri = creatorOverride != null
        ? await creatorOverride(bookingId)
        : await _repository.createPayment(bookingId);
    _paymentUri = uri;
    _safeNotify();
    return uri;
  }

  Future<PaymentStatusResult> checkPaymentStatus(
    String bookingId, {
    Future<PaymentStatusResult> Function(String bookingId)? checkerOverride,
  }) async {
    _checkingStatus = true;
    _errorMessage = null;
    _safeNotify();
    try {
      final result = checkerOverride != null
          ? await checkerOverride(bookingId)
          : await _repository.checkPaymentStatus(bookingId);
      if (result.booking != null) {
        _currentBooking = result.booking;
      } else if (_currentBooking != null) {
        _currentBooking =
            _currentBooking!.copyWith(status: result.bookingStatus);
      }
      if (result.pdfUrl != null && result.pdfUrl!.trim().isNotEmpty) {
        _pdfUrl = result.pdfUrl!.trim();
      }
      if (result.qrImageUrl != null && result.qrImageUrl!.trim().isNotEmpty) {
        _qrImageUrl = result.qrImageUrl!.trim();
      }
      _statusNote = result.message;
      return result;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _checkingStatus = false;
      _safeNotify();
    }
  }

  Future<List<TicketBooking>> getMyBookings(
    String email, {
    Future<List<TicketBooking>> Function(String email)? loaderOverride,
  }) =>
      loaderOverride != null
          ? loaderOverride(email)
          : _repository.getMyBookings(email);

  void resetBooking() {
    _currentBooking = null;
    _paymentUri = null;
    _pdfUrl = null;
    _qrImageUrl = null;
    _statusNote = null;
    _errorMessage = null;
    _safeNotify();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
