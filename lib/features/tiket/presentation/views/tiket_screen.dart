import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:app/features/tiket/data/repositories/tiket_service.dart';
import 'package:app/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:app/features/tiket/presentation/viewmodels/tiket_viewmodel.dart';

typedef CategoriesLoader = Future<List<TiketCategory>> Function();
typedef BookingCreator = Future<TicketBooking> Function({
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
});
typedef PaymentCreator = Future<Uri> Function(String bookingId);
typedef PaymentStatusChecker = Future<PaymentStatusResult> Function(
  String bookingId,
);
typedef MyBookingsLoader = Future<List<TicketBooking>> Function(String email);

class TiketScreen extends StatefulWidget {
  const TiketScreen({
    super.key,
    required this.onGoHome,
    this.categoriesLoader,
    this.bookingCreator,
    this.paymentCreator,
    this.statusChecker,
    this.myBookingsLoader,
    this.viewModel,
    this.authViewModel,
  });

  final VoidCallback onGoHome;
  final CategoriesLoader? categoriesLoader;
  final BookingCreator? bookingCreator;
  final PaymentCreator? paymentCreator;
  final PaymentStatusChecker? statusChecker;
  final MyBookingsLoader? myBookingsLoader;
  final TiketViewModel? viewModel;
  final AuthViewModel? authViewModel;

  @override
  State<TiketScreen> createState() => _TiketScreenState();
}

class _TiketScreenState extends State<TiketScreen> {
  // 0 = Formulir, 1 = Instruksi Pembayaran Midtrans, 2 = E-Tiket Lunas
  int _currentStep = 0;

  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _selectedCountryCode = '+62';
  String _selectedCountryFlag = '🇮🇩';

  static const List<Map<String, String>> _countryCodes = [
    {'name': 'Indonesia', 'code': '+62', 'flag': '🇮🇩'},
    {'name': 'Malaysia', 'code': '+60', 'flag': '🇲🇾'},
    {'name': 'Singapura', 'code': '+65', 'flag': '🇸🇬'},
    {'name': 'Australia', 'code': '+61', 'flag': '🇦🇺'},
    {'name': 'Jepang', 'code': '+81', 'flag': '🇯🇵'},
    {'name': 'Korea Selatan', 'code': '+82', 'flag': '🇰🇷'},
    {'name': 'Amerika Serikat', 'code': '+1', 'flag': '🇺🇸'},
    {'name': 'Inggris', 'code': '+44', 'flag': '🇬🇧'},
    {'name': 'Jerman', 'code': '+49', 'flag': '🇩🇪'},
    {'name': 'Belanda', 'code': '+31', 'flag': '🇳🇱'},
    {'name': 'Tiongkok', 'code': '+86', 'flag': '🇨🇳'},
    {'name': 'Arab Saudi', 'code': '+966', 'flag': '🇸🇦'},
    {'name': 'Thailand', 'code': '+66', 'flag': '🇹🇭'},
    {'name': 'Filipina', 'code': '+63', 'flag': '🇵🇭'},
    {'name': 'Vietnam', 'code': '+84', 'flag': '🇻🇳'},
    {'name': 'India', 'code': '+91', 'flag': '🇮🇳'},
    {'name': 'Prancis', 'code': '+33', 'flag': '🇫🇷'},
  ];

  DateTime _selectedDate = _defaultVisitDate();
  String _selectedSesi = '08:00 - 10:00';
  int _qtyDewasa = 1;
  int _qtyPelajar = 0;
  int _qtyWna = 0;
  String _paymentMethod = 'QRIS';

  // Harga dari backend (default fallback)
  int _priceDewasa = 10000;
  int _pricePelajar = 5000;
  int _priceWna = 25000;

  // Kategori tambahan yang dibuat admin (selain Dewasa / Pelajar / WNA)
  List<TiketCategory> _extraCategories = const [];
  final Map<int, int> _qtyExtra = {};

  // Jam operasional dari admin (Pusat Informasi)
  JamOperasional _jam = const JamOperasional();
  Timer? _refreshTimer;

  int get _extraTicketCount =>
      _qtyExtra.values.fold(0, (sum, qty) => sum + qty);

  int get _extraTotal => _extraCategories.fold(
        0,
        (sum, cat) => sum + (_qtyExtra[cat.id] ?? 0) * cat.price,
      );

  bool _isClosedDay(DateTime day) => _jam.closedWeekdays.contains(day.weekday);

  DateTime _nextOpenDay(DateTime from) {
    var day = DateTime(from.year, from.month, from.day);
    for (var i = 0; i < 7 && _isClosedDay(day); i++) {
      day = day.add(const Duration(days: 1));
    }
    return day;
  }

  late final TiketViewModel _viewModel;
  late final bool _ownsViewModel;
  late final AuthViewModel _authViewModel;
  late final bool _ownsAuthViewModel;

  static DateTime _defaultVisitDate() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    // Jika besok hari Senin (libur reguler museum), sarankan hari Selasa
    if (tomorrow.weekday == DateTime.monday) {
      return tomorrow.add(const Duration(days: 1));
    }
    return tomorrow;
  }

  static String _formatRupiah(int amount) {
    final formatted = amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return 'Rp $formatted';
  }

  // Deteksi Wisatawan Mancanegara berdasarkan kode negara nomor telepon
  bool get _isMancanegara => _selectedCountryCode != '+62';

  String get _cleanPhoneDigits =>
      _phoneController.text.replaceAll(RegExp(r'[\s\-()]'), '').trim();

  String get _fullPhoneNumber {
    final num = _cleanPhoneDigits;
    if (num.isEmpty) return '';
    if (num.startsWith('+')) return num;
    final cleanNum = num.startsWith('0') ? num.substring(1) : num;
    return '$_selectedCountryCode$cleanNum';
  }

  int get _totalBayar {
    if (_isMancanegara) {
      return _qtyWna * _priceWna;
    }
    return (_qtyDewasa * _priceDewasa) +
        (_qtyPelajar * _pricePelajar) +
        _extraTotal;
  }

  String get _formattedDate {
    final d = _selectedDate;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String get _apiDate {
    final d = _selectedDate;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _ownsViewModel = widget.viewModel == null;
    _viewModel = widget.viewModel ?? TiketViewModel();
    _ownsAuthViewModel = widget.authViewModel == null;
    _authViewModel = widget.authViewModel ?? AuthViewModel();

    final user = _authViewModel.currentUser;
    if (user != null) {
      if (user.nama.trim().isNotEmpty) {
        _namaController.text = user.nama.trim();
      }
      if (user.email.trim().isNotEmpty) {
        _emailController.text = user.email.trim();
      }
    }
    _phoneController.addListener(_onPhoneChanged);
    _loadPrices();
    _loadJamOperasional();
    // Sinkronkan perubahan admin (kategori & jam operasional) secara berkala
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted || _currentStep != 0) return;
      _loadPrices(silent: true);
      _loadJamOperasional();
    });
  }

  void _onPhoneChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadJamOperasional() async {
    try {
      final jam = await _viewModel.loadJamOperasional();
      if (!mounted) return;
      setState(() {
        _jam = jam;
        final sessions = _jam.sessions;
        if (!sessions.contains(_selectedSesi) && sessions.isNotEmpty) {
          _selectedSesi = sessions.first;
        }
        if (_isClosedDay(_selectedDate)) {
          _selectedDate = _nextOpenDay(_selectedDate);
        }
      });
    } catch (_) {
      // Tetap gunakan jam operasional bawaan jika server tidak dapat dihubungi
    }
  }

  Future<void> _loadPrices({bool silent = false}) async {
    try {
      final cats = silent
          ? await (widget.categoriesLoader?.call() ??
              TiketService.getCategories())
          : await _viewModel.loadCategories(
              loaderOverride: widget.categoriesLoader,
            );
      if (!mounted) return;
      setState(() {
        for (final cat in cats) {
          if (cat.isMancanegara) {
            _priceWna = cat.price;
          } else if (cat.isPelajar) {
            _pricePelajar = cat.price;
          } else if (cat.isDewasa) {
            _priceDewasa = cat.price;
          }
        }
        _extraCategories = cats.where((c) => c.isExtra).toList();
        final validIds = _extraCategories.map((c) => c.id).toSet();
        _qtyExtra.removeWhere((id, _) => !validIds.contains(id));
      });
    } catch (_) {
      // Gunakan harga fallback bawaan jika server tidak dapat dihubungi
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.red.shade700 : const Color(0xFF3F5243),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _handleBayar() async {
    final nama = _namaController.text.trim();
    final email = _emailController.text.trim();

    if (nama.isEmpty || email.isEmpty) {
      _showSnack('Nama dan email wajib diisi', isError: true);
      return;
    }

    if (nama.length < 3) {
      _showSnack('Nama lengkap minimal 3 karakter', isError: true);
      return;
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      _showSnack('Format email tidak valid', isError: true);
      return;
    }

    final digits = _cleanPhoneDigits.replaceFirst(RegExp(r'^\+'), '');
    if (digits.isNotEmpty &&
        (digits.length < 8 ||
            digits.length > 15 ||
            !RegExp(r'^[0-9]+$').hasMatch(digits))) {
      _showSnack('Nomor telepon harus berupa 8-15 digit angka', isError: true);
      return;
    }

    final totalTiket = _isMancanegara
        ? _qtyWna
        : (_qtyDewasa + _qtyPelajar + _extraTicketCount);
    if (totalTiket == 0) {
      _showSnack('Pilih minimal 1 tiket', isError: true);
      return;
    }

    if (_isClosedDay(_selectedDate)) {
      _showSnack(
        'Museum tutup pada hari tersebut. Silakan pilih tanggal kunjungan lain.',
        isError: true,
      );
      return;
    }

    try {
      final booking = await _viewModel.createBooking(
        nama: nama,
        email: email,
        phone: _fullPhoneNumber.isNotEmpty ? _fullPhoneNumber : null,
        dewasa: _isMancanegara ? 0 : _qtyDewasa,
        pelajar: _isMancanegara ? 0 : _qtyPelajar,
        wna: _isMancanegara ? _qtyWna : 0,
        sesi: _selectedSesi,
        visitDate: _apiDate,
        paymentMethod: _isMancanegara ? 'CREDIT_CARD' : _paymentMethod,
        isMancanegara: _isMancanegara ? 1 : 0,
        extraCategories:
            _isMancanegara ? const {} : Map<int, int>.from(_qtyExtra),
        creatorOverride: widget.bookingCreator,
      );
      if (!mounted) return;
      setState(() {
        _currentStep = booking.isPaid ? 2 : 1;
      });
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  Future<void> _openPayment() async {
    final booking = _viewModel.currentBooking;
    if (booking == null || _viewModel.openingPayment) return;

    _viewModel.setOpeningPayment(true);
    try {
      var paymentUri = _viewModel.paymentUri;
      if (paymentUri == null) {
        paymentUri = await _viewModel.createPayment(
          booking.id,
          creatorOverride: widget.paymentCreator,
        );
        if (!mounted) return;
      }

      bool launched = false;
      try {
        launched = await launchUrl(
          paymentUri,
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {
        launched = false;
      }

      if (!launched) {
        try {
          launched = await launchUrl(
            paymentUri,
            mode: LaunchMode.platformDefault,
          );
        } catch (_) {
          launched = false;
        }
      }

      if (!launched && mounted) {
        _showSnack(
          'Pop-up diblokir browser. Gunakan tombol "Salin Link Pembayaran" untuk membuka halaman Midtrans.',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
      }
    } finally {
      if (mounted) _viewModel.setOpeningPayment(false);
    }
  }

  Future<void> _checkPaymentStatus() async {
    final booking = _viewModel.currentBooking;
    if (booking == null || _viewModel.checkingStatus) return;

    try {
      final result = await _viewModel.checkPaymentStatus(
        booking.id,
        checkerOverride: widget.statusChecker,
      );
      if (!mounted) return;

      final updatedBooking = _viewModel.currentBooking ?? booking;
      if (result.isPaid || updatedBooking.isPaid) {
        setState(() {
          _currentStep = 2;
        });
      }

      _showSnack(
        result.message,
        isError: result.isCancelled,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack(
        'Gagal mengecek status pembayaran: ${e.toString().replaceFirst("Exception: ", "")}',
        isError: true,
      );
    }
  }

  Future<void> _copyText(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    _showSnack('$label berhasil disalin');
  }

  Future<void> _downloadTicketPdf() async {
    final booking = _viewModel.currentBooking;
    if (booking == null || _viewModel.downloadingPdf) return;

    _viewModel.setDownloadingPdf(true);
    try {
      final pdfUri = _viewModel.getTicketPdfUri(booking.id);
      bool launched = false;
      try {
        launched = await launchUrl(
          pdfUri,
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {
        launched = false;
      }

      if (!launched) {
        try {
          launched = await launchUrl(
            pdfUri,
            mode: LaunchMode.platformDefault,
          );
        } catch (_) {
          launched = false;
        }
      }

      if (!mounted) return;
      if (launched) {
        _showSnack('Mengunduh E-Tiket PDF (${booking.id})...');
      } else {
        _showSnack(
          'Browser memblokir unduhan otomatis. Gunakan kode booking ${booking.id} saat check-in.',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnack(
          'Gagal mengunduh E-Tiket PDF: ${e.toString().replaceFirst("Exception: ", "")}',
          isError: true,
        );
      }
    } finally {
      if (mounted) _viewModel.setDownloadingPdf(false);
    }
  }

  void _resetForNewBooking() {
    _viewModel.resetBooking();
    setState(() {
      _currentStep = 0;
    });
  }

  Future<void> _showMyBookingsSheet() async {
    final lookupEmail = _emailController.text.trim().isNotEmpty
        ? _emailController.text.trim()
        : (_authViewModel.currentUser?.email.trim() ?? '');

    if (lookupEmail.isEmpty) {
      _showSnack(
        'Masukkan email terlebih dahulu atau login untuk melihat riwayat tiket.',
        isError: true,
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.72,
          decoration: const BoxDecoration(
            color: Color(0xFFF7F3EA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.receipt_long_outlined,
                      color: Color(0xFF3F5243),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Riwayat Pemesanan Tiket',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C322B),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Email: $lookupEmail',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF727A71),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: FutureBuilder<List<TicketBooking>>(
                  future: _viewModel.getMyBookings(
                    lookupEmail,
                    loaderOverride: widget.myBookingsLoader,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF3F5243),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Gagal memuat riwayat tiket: ${snapshot.error.toString().replaceFirst("Exception: ", "")}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      );
                    }

                    final bookings = snapshot.data ?? const <TicketBooking>[];
                    if (bookings.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.confirmation_number_outlined,
                                size: 42,
                                color: Color(0xFF727A71),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Belum ada riwayat pemesanan tiket.',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF2C322B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      itemCount: bookings.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, idx) {
                        final item = bookings[idx];
                        final badgeColor = item.isPaid
                            ? const Color(0xFF047857)
                            : item.isCancelled
                                ? Colors.red.shade700
                                : const Color(0xFFB45309);
                        final badgeBg = item.isPaid
                            ? const Color(0xFFECFDF5)
                            : item.isCancelled
                                ? const Color(0xFFFEF2F2)
                                : const Color(0xFFFFFBEB);

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE0E3DF)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.id,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Color(0xFF2C322B),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: badgeBg,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      item.status,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: badgeColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${item.visitDate} • ${item.sesi} • ${item.totalTiket} tiket',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF727A71),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatRupiah(item.totalBiaya),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF3F5243),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(ctx).pop();
                                      _viewModel.selectBooking(item);
                                      setState(() {
                                        _currentStep = item.isPaid ? 2 : 1;
                                      });
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFF3F5243),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                    ),
                                    child: Text(
                                      item.isPaid
                                          ? 'Lihat E-Tiket'
                                          : 'Buka Pembayaran',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickDate() async {
    await _loadJamOperasional();
    if (!mounted) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initial = _isClosedDay(_selectedDate) || _selectedDate.isBefore(today)
        ? _nextOpenDay(today)
        : _selectedDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: today.add(const Duration(days: 90)),
      helpText: 'Pilih Tanggal Kunjungan (Senin Libur)',
      selectableDayPredicate: (day) => !_isClosedDay(day),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF3F5243)),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _phoneController.removeListener(_onPhoneChanged);
    _namaController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    if (_ownsViewModel) {
      _viewModel.dispose();
    }
    if (_ownsAuthViewModel) {
      _authViewModel.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color bgCream = Color(0xFFF7F3EA);
    const Color darkGreen = Color(0xFF3F5243);
    const Color goldAccent = Color(0xFFCBB26A);
    const Color cardBg = Colors.white;
    const Color textDark = Color(0xFF2C322B);
    const Color textMuted = Color(0xFF727A71);
    const Color borderLight = Color(0xFFE0E3DF);

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: bgCream,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 16.0,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: darkGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.account_balance,
                            color: goldAccent,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'MUSEUM BRAWIJAYA',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: textDark,
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _showMyBookingsSheet,
                          icon:
                              const Icon(Icons.receipt_long_outlined, size: 15),
                          label: const Text(
                            'Riwayat',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: darkGreen,
                            side: const BorderSide(color: borderLight),
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_currentStep == 0)
                    _buildFormulirPemesanan(
                      darkGreen,
                      goldAccent,
                      cardBg,
                      textDark,
                      textMuted,
                      borderLight,
                    )
                  else if (_currentStep == 1)
                    _buildInstruksiPembayaran(
                      darkGreen,
                      goldAccent,
                      cardBg,
                      textDark,
                      textMuted,
                      borderLight,
                    )
                  else
                    _buildETicketSuccess(
                      darkGreen,
                      goldAccent,
                      cardBg,
                      textDark,
                      textMuted,
                      borderLight,
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRadioIndicator({
    required bool selected,
    required Color activeColor,
  }) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? activeColor : const Color(0xFF9CA3AF),
          width: 2,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: activeColor,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildFormulirPemesanan(
    Color darkGreen,
    Color goldAccent,
    Color cardBg,
    Color textDark,
    Color textMuted,
    Color borderLight,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              InkWell(
                onTap: widget.onGoHome,
                child: Text(
                  'Beranda',
                  style: TextStyle(fontSize: 11, color: textMuted),
                ),
              ),
              Text(
                '  >  Pemesanan Tiket Online',
                style: TextStyle(fontSize: 11, color: textMuted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Formulir Pemesanan Tiket',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Lengkapi data diri dan pilih jadwal kunjungan Anda',
            style: TextStyle(fontSize: 12, color: textMuted),
          ),
          const SizedBox(height: 20),

          // 1. DATA DIRI PEMESAN
          _buildCardSection(
            cardBg,
            borderLight,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 18,
                    color: Color(0xFFCBB26A),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '1. Data Diri Pemesan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildInputLabelField(
                'Nama Lengkap (Sesuai KTP/Paspor)',
                _namaController,
                hintText: 'Contoh: Budi Santoso',
              ),
              const SizedBox(height: 12),
              _buildInputLabelField(
                'Email (Pengiriman E-Tiket & QR Code)',
                _emailController,
                hintText: 'nama@email.com',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _buildPhoneInputField(),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _isMancanegara
                      ? const Color(0xFFF3E8FF)
                      : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isMancanegara
                        ? const Color(0xFFC084FC)
                        : const Color(0xFF6EE7B7),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isMancanegara ? Icons.public : Icons.flag,
                      size: 16,
                      color: _isMancanegara
                          ? const Color(0xFF7E22CE)
                          : const Color(0xFF047857),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isMancanegara
                            ? 'Terdeteksi: Wisatawan Mancanegara (International Tourist). Harga dan metode pembayaran internasional diterapkan.'
                            : 'Terdeteksi: Wisatawan Dalam Negeri (Domestik). Tiket reguler WNI diterapkan.',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _isMancanegara
                              ? const Color(0xFF7E22CE)
                              : const Color(0xFF047857),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. TANGGAL & WAKTU KUNJUNGAN
          _buildCardSection(
            cardBg,
            borderLight,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: Color(0xFFCBB26A),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '2. Tanggal & Waktu Kunjungan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tanggal Kunjungan',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F5F3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFCBB26A),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _formattedDate,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textDark,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.edit_calendar_outlined,
                                  size: 14,
                                  color: Color(0xFF3F5243),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jam Operasional',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F5F3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _jam.jam,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: textDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: goldAccent.withValues(alpha: 0.7),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 15,
                      color: Color(0xFF8A6D1C),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Hari buka: ${_jam.hari}. Tanggal hari libur (Senin) tidak dapat dipilih.',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF6B5314),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Pilih Sesi Jam Kunjungan',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  const spacing = 8.0;
                  final chipWidth = (constraints.maxWidth - spacing * 2) / 3;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: _jam.sessions
                        .map((s) => _buildSesiChip(s, darkGreen, chipWidth))
                        .toList(),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3. PILIH KATEGORI TIKET (Dinamis WNI / WNA)
          _buildCardSection(
            cardBg,
            borderLight,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.confirmation_number_outlined,
                    size: 18,
                    color: Color(0xFFCBB26A),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '3. Pilih Kategori Tiket',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_viewModel.loadingCategories)
                const Center(
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (_isMancanegara) ...[
                _buildQtyRow(
                  'Tiket Wisatawan Mancanegara (WNA)',
                  '${_formatRupiah(_priceWna)}/person',
                  _qtyWna,
                  (val) => setState(() => _qtyWna = val),
                  darkGreen,
                ),
                const SizedBox(height: 8),
                Text(
                  'Kategori khusus wisatawan dari luar negeri.',
                  style: TextStyle(
                    fontSize: 10,
                    color: textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ] else ...[
                _buildQtyRow(
                  'Tiket Dewasa / Umum (WNI)',
                  '${_formatRupiah(_priceDewasa)}/orang',
                  _qtyDewasa,
                  (val) => setState(() => _qtyDewasa = val),
                  darkGreen,
                ),
                Divider(height: 20, color: borderLight),
                _buildQtyRow(
                  'Tiket Pelajar / Mahasiswa (WNI)',
                  '${_formatRupiah(_pricePelajar)}/orang',
                  _qtyPelajar,
                  (val) => setState(() => _qtyPelajar = val),
                  darkGreen,
                ),
                for (final cat in _extraCategories) ...[
                  Divider(height: 20, color: borderLight),
                  _buildQtyRow(
                    cat.title,
                    '${_formatRupiah(cat.price)}/orang • ${cat.badge}',
                    _qtyExtra[cat.id] ?? 0,
                    (val) => setState(() => _qtyExtra[cat.id] = val),
                    darkGreen,
                  ),
                ],
              ],
            ],
          ),
          const SizedBox(height: 16),

          // 4. METODE PEMBAYARAN
          _buildCardSection(
            cardBg,
            borderLight,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 18,
                    color: Color(0xFFCBB26A),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '4. Metode Pembayaran',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (_isMancanegara)
                GestureDetector(
                  onTap: () => setState(() => _paymentMethod = 'CREDIT_CARD'),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF7E22CE),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildRadioIndicator(
                          selected: true,
                          activeColor: const Color(0xFF7E22CE),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Credit / Debit Card (Visa / Mastercard)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Metode pembayaran resmi untuk wisatawan internasional',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E3A8A),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'VISA',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDC2626),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'MC',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _paymentMethod = 'QRIS'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: _paymentMethod == 'QRIS'
                                ? const Color(0xFFF4F5F3)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _paymentMethod == 'QRIS'
                                  ? darkGreen
                                  : borderLight,
                              width: _paymentMethod == 'QRIS' ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              _buildRadioIndicator(
                                selected: _paymentMethod == 'QRIS',
                                activeColor: darkGreen,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'QRIS (E-Wallet)',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: textDark,
                                      ),
                                    ),
                                    Text(
                                      'Gopay, OVO, Dana',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _paymentMethod = 'BANK'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: _paymentMethod == 'BANK'
                                ? const Color(0xFFF4F5F3)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _paymentMethod == 'BANK'
                                  ? darkGreen
                                  : borderLight,
                              width: _paymentMethod == 'BANK' ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              _buildRadioIndicator(
                                selected: _paymentMethod == 'BANK',
                                activeColor: darkGreen,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Transfer Bank',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: textDark,
                                      ),
                                    ),
                                    Text(
                                      'BCA, Mandiri, BNI',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 20),

          // 5. RINGKASAN PESANAN
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: darkGreen,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '5. Ringkasan Pesanan',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: goldAccent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _isMancanegara
                            ? const Color(0xFF7E22CE)
                            : goldAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _isMancanegara ? 'MANCANEGARA' : 'DOMESTIK',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: _isMancanegara ? Colors.white : textDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSummaryRow('Lokasi:', 'Museum Brawijaya Malang'),
                _buildSummaryRow('Tanggal:', _formattedDate),
                _buildSummaryRow('Sesi Waktu:', _selectedSesi),
                if (_isMancanegara)
                  _buildSummaryRow(
                    'Wisatawan Asing x$_qtyWna',
                    _formatRupiah(_qtyWna * _priceWna),
                  )
                else ...[
                  if (_qtyDewasa > 0)
                    _buildSummaryRow(
                      'WNI - Dewasa x$_qtyDewasa',
                      _formatRupiah(_qtyDewasa * _priceDewasa),
                    ),
                  if (_qtyPelajar > 0)
                    _buildSummaryRow(
                      'WNI - Pelajar x$_qtyPelajar',
                      _formatRupiah(_qtyPelajar * _pricePelajar),
                    ),
                  for (final cat in _extraCategories)
                    if ((_qtyExtra[cat.id] ?? 0) > 0)
                      _buildSummaryRow(
                        '${cat.title} x${_qtyExtra[cat.id]}',
                        _formatRupiah((_qtyExtra[cat.id] ?? 0) * cat.price),
                      ),
                ],
                _buildSummaryRow(
                  'Metode Bayar:',
                  _isMancanegara ? 'CREDIT_CARD' : _paymentMethod,
                ),
                _buildSummaryRow('Biaya Admin:', 'GRATIS', isGold: true),
                const Divider(color: Colors.white24, height: 24),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Total Bayar',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _formatRupiah(_totalBayar),
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: goldAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: _viewModel.submitting ? null : _handleBayar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: goldAccent,
                    foregroundColor: textDark,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _viewModel.submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.black,
                            ),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock, size: 16),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Bayar Tiket Sekarang',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    'E-Tiket Resmi & QR Code instan dikirim via Email setelah lunas',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstruksiPembayaran(
    Color darkGreen,
    Color goldAccent,
    Color cardBg,
    Color textDark,
    Color textMuted,
    Color borderLight,
  ) {
    final booking = _viewModel.currentBooking;
    final statusNote = _viewModel.statusNote;
    final openingPayment = _viewModel.openingPayment;
    final checkingStatus = _viewModel.checkingStatus;
    final paymentUri = _viewModel.paymentUri;
    final isCancelled = booking?.isCancelled ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Text(
                  'Instruksi Pembayaran',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Klik tombol bayar di bawah untuk membuka halaman pembayaran resmi Midtrans sesuai metode yang Anda pilih (${booking?.paymentMethod ?? _paymentMethod}). Setelah menyelesaikan pembayaran, tekan "Cek Status Pembayaran" untuk langsung mengaktifkan E-Tiket (LUNAS).',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Status & Pembayaran Midtrans
          _buildCardSection(
            cardBg,
            borderLight,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 20,
                    color: Color(0xFF3F5243),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pembayaran Aman via Midtrans',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isCancelled
                          ? const Color(0xFFFEF2F2)
                          : const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      booking?.status ?? 'MENUNGGU',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isCancelled
                            ? Colors.red.shade700
                            : const Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Pilih QRIS, GoPay, Virtual Account Bank, atau metode lain yang tersedia di halaman Midtrans Snap.',
                style: TextStyle(fontSize: 11, color: textMuted),
              ),
              const SizedBox(height: 14),
              _buildDetailInfoRow('Kode Pesanan', booking?.id ?? '-'),
              _buildDetailInfoRow('Nama Pemesan', booking?.nama ?? '-'),
              _buildDetailInfoRow(
                'Jadwal Kunjungan',
                '${booking?.visitDate ?? _apiDate} (${booking?.sesi ?? _selectedSesi})',
              ),
              _buildDetailInfoRow(
                'Jumlah Tiket',
                '${booking?.totalTiket ?? 1} pengunjung',
              ),
              const Divider(height: 18),
              _buildDetailInfoRow(
                'Total Tagihan',
                _formatRupiah(booking?.totalBiaya ?? 0),
                isBoldPrice: true,
              ),
              if (statusNote != null && statusNote.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isCancelled
                        ? const Color(0xFFFEF2F2)
                        : const Color(0xFFF4F5F3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isCancelled
                          ? Colors.red.shade200
                          : borderLight,
                    ),
                  ),
                  child: Text(
                    statusNote,
                    style: TextStyle(
                      fontSize: 11,
                      color: isCancelled ? Colors.red.shade700 : textDark,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (!isCancelled) ...[
                ElevatedButton.icon(
                  onPressed: openingPayment ? null : _openPayment,
                  icon: openingPayment
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.open_in_new, size: 16),
                  label: Text(
                    openingPayment
                        ? 'Menghubungkan ke Midtrans...'
                        : 'Lanjutkan Pembayaran (Midtrans)',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkGreen,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: checkingStatus ? null : _checkPaymentStatus,
                  icon: checkingStatus
                      ? const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF3F5243),
                          ),
                        )
                      : const Icon(Icons.verified_outlined, size: 17),
                  label: Text(
                    checkingStatus
                        ? 'Memeriksa Status ke Midtrans...'
                        : 'Cek Status Pembayaran',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: darkGreen,
                    side: BorderSide(color: darkGreen, width: 1.4),
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                if (paymentUri != null) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => _copyText(
                        paymentUri.toString(),
                        'Link pembayaran Midtrans',
                      ),
                      icon: const Icon(Icons.copy, size: 14),
                      label: const Text(
                        'Salin Link Pembayaran Midtrans',
                        style: TextStyle(fontSize: 11),
                      ),
                      style: TextButton.styleFrom(foregroundColor: darkGreen),
                    ),
                  ),
                ],
              ] else
                ElevatedButton.icon(
                  onPressed: _resetForNewBooking,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Buat Pemesanan Baru'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkGreen,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Info notifikasi E-Tiket via Email & WhatsApp
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.mark_email_read_outlined,
                        color: Color(0xFF047857),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pengiriman E-Tiket Resmi',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C322B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Setelah pembayaran terverifikasi LUNAS, E-Tiket beserta QR Code resmi dikirim ke:',
                            style: TextStyle(fontSize: 11, color: textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F5F3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.email,
                            size: 16,
                            color: Color(0xFF3F5243),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Email: ${(booking?.email ?? _emailController.text).isNotEmpty ? (booking?.email ?? _emailController.text) : "Email Anda"}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2C322B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.phone_android,
                            size: 16,
                            color: Color(0xFF047857),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'WhatsApp: ${(booking?.phone ?? _fullPhoneNumber).isNotEmpty ? (booking?.phone ?? _fullPhoneNumber) : "Opsional"}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2C322B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => setState(() => _currentStep = 0),
                  child: Center(
                    child: Text(
                      '← Kembali ke Formulir Pemesanan',
                      style: TextStyle(
                        color: darkGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildETicketSuccess(
    Color darkGreen,
    Color goldAccent,
    Color cardBg,
    Color textDark,
    Color textMuted,
    Color borderLight,
  ) {
    final booking = _viewModel.currentBooking;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF26362A), Color(0xFF3F5243)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: goldAccent.withValues(alpha: 0.7),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Color(0xFF34D399),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PEMBAYARAN BERHASIL',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              color: goldAccent,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'E-Tiket Museum Brawijaya Aktif',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: goldAccent.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'KODE BOOKING',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.white70,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              booking?.id ?? '-',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: goldAccent,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Salin kode booking',
                        onPressed: booking == null
                            ? null
                            : () => _copyText(booking.id, 'Kode booking'),
                        icon: const Icon(
                          Icons.copy,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildETicketRow('Status', 'LUNAS'),
                _buildETicketRow('Nama Pemesan', booking?.nama ?? '-'),
                _buildETicketRow('Email', booking?.email ?? '-'),
                _buildETicketRow(
                  'Tanggal Kunjungan',
                  booking?.visitDate ?? _apiDate,
                ),
                _buildETicketRow('Sesi Waktu', booking?.sesi ?? _selectedSesi),
                _buildETicketRow(
                  'Jumlah Tiket',
                  '${booking?.totalTiket ?? 1} Pengunjung',
                ),
                const Divider(color: Colors.white24, height: 22),
                _buildETicketRow(
                  'Total Dibayar',
                  _formatRupiah(booking?.totalBiaya ?? 0),
                ),
                if (booking != null) ...[
                  const SizedBox(height: 18),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 150,
                            height: 150,
                            child: Image.network(
                              _viewModel.getTicketQrUri(booking.id).toString(),
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.qr_code_2_rounded,
                                    size: 84,
                                    color: darkGreen,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    booking.id,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: darkGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'QR Code Check-In E-Tiket',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed:
                        _viewModel.downloadingPdf ? null : _downloadTicketPdf,
                    icon: _viewModel.downloadingPdf
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF2C322B),
                            ),
                          )
                        : const Icon(Icons.download_rounded, size: 18),
                    label: Text(
                      _viewModel.downloadingPdf
                          ? 'Menyiapkan E-Tiket PDF...'
                          : 'Download E-Tiket (PDF)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: goldAccent,
                      foregroundColor: textDark,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildCardSection(
            cardBg,
            borderLight,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Color(0xFF3F5243),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Petunjuk Check-In',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C322B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Tunjukkan kode booking di atas atau QR Code E-Tiket yang dikirim ke email Anda kepada petugas loket masuk Museum Brawijaya (Jl. Ijen No.25A, Kota Malang).',
                style: TextStyle(fontSize: 11.5, color: textMuted, height: 1.5),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _resetForNewBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkGreen,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Pesan Tiket Lagi',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: widget.onGoHome,
                style: OutlinedButton.styleFrom(
                  foregroundColor: darkGreen,
                  side: BorderSide(color: borderLight),
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Kembali ke Beranda',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardSection(
    Color cardBg,
    Color borderLight, {
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildSesiChip(String label, Color darkGreen, double width) {
    final isSelected = _selectedSesi == label;
    return SizedBox(
      width: width,
      child: GestureDetector(
        onTap: () => setState(() => _selectedSesi = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? darkGreen : const Color(0xFFF4F5F3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Tersedia',
                style: TextStyle(
                  fontSize: 8,
                  color: isSelected ? Colors.white70 : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQtyRow(
    String title,
    String subtitle,
    int qty,
    ValueChanged<int> onChanged,
    Color darkGreen,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C322B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 10, color: Color(0xFF727A71)),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: qty > 0 ? () => onChanged(qty - 1) : null,
              icon: const Icon(Icons.remove_circle_outline, size: 20),
              color: darkGreen,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(6),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '$qty',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: () => onChanged(qty + 1),
              icon: const Icon(Icons.add_circle, size: 20),
              color: darkGreen,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(6),
            ),
          ],
        ),
      ],
    );
  }

  void _showCountryPicker() {
    final searchCtrl = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        List<Map<String, String>> filtered = List.from(_countryCodes);
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Pilih Kode Negara',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: TextField(
                      controller: searchCtrl,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search, size: 20),
                        hintText: 'Cari negara atau kode...',
                        hintStyle: const TextStyle(fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF4F5F3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) {
                        setModalState(() {
                          final q = val.toLowerCase().trim();
                          filtered = _countryCodes.where((c) {
                            return c['name']!.toLowerCase().contains(q) ||
                                c['code']!.toLowerCase().contains(q);
                          }).toList();
                        });
                      },
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, idx) {
                        final item = filtered[idx];
                        final isSelected = item['code'] == _selectedCountryCode;
                        return ListTile(
                          leading: Text(
                            item['flag'] ?? '',
                            style: const TextStyle(fontSize: 22),
                          ),
                          title: Text(
                            item['name'] ?? '',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: Text(
                            item['code'] ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? const Color(0xFF3F5243)
                                  : Colors.grey.shade600,
                            ),
                          ),
                          onTap: () {
                            final nextCode = item['code']!;
                            setState(() {
                              _selectedCountryCode = nextCode;
                              _selectedCountryFlag = item['flag']!;
                              if (nextCode != '+62') {
                                if (_qtyWna == 0) _qtyWna = 1;
                                _paymentMethod = 'CREDIT_CARD';
                              } else {
                                if (_qtyDewasa == 0 &&
                                    _qtyPelajar == 0 &&
                                    _extraTicketCount == 0) {
                                  _qtyDewasa = 1;
                                }
                                if (_paymentMethod == 'CREDIT_CARD') {
                                  _paymentMethod = 'QRIS';
                                }
                              }
                            });
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(searchCtrl.dispose);
  }

  Widget _buildPhoneInputField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'No. WhatsApp / Telepon',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C322B),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF4F5F3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              InkWell(
                onTap: _showCountryPicker,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedCountryFlag,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _selectedCountryCode,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.arrow_drop_down,
                        size: 18,
                        color: Color(0xFF727A71),
                      ),
                    ],
                  ),
                ),
              ),
              Container(width: 1, height: 26, color: Colors.grey.shade300),
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 12),
                  decoration: const InputDecoration(
                    hintText: '81234567890',
                    hintStyle: TextStyle(
                      color: Color(0xFFA0A7A0),
                      fontSize: 12,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputLabelField(
    String label,
    TextEditingController controller, {
    String? hintText,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C322B),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Color(0xFFA0A7A0),
              fontSize: 12,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            filled: true,
            fillColor: const Color(0xFFF4F5F3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isGold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isGold ? const Color(0xFFCBB26A) : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailInfoRow(
    String label,
    String value, {
    bool isBoldPrice = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF727A71)),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: isBoldPrice ? 14 : 11,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2C322B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildETicketRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
