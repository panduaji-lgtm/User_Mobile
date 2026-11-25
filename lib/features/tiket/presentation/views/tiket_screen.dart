import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:app/features/tiket/data/repositories/tiket_service.dart';

class TiketScreen extends StatefulWidget {
  const TiketScreen({super.key, required this.onGoHome});

  final VoidCallback onGoHome;

  @override
  State<TiketScreen> createState() => _TiketScreenState();
}

class _TiketScreenState extends State<TiketScreen> {
  int _currentStep = 0;

  final TextEditingController _namaController = TextEditingController(text: '');
  final TextEditingController _emailController = TextEditingController(
    text: '',
  );
  final TextEditingController _phoneController = TextEditingController(
    text: '',
  );
  String _selectedCountryCode = '+62';
  String _selectedCountryFlag = '🇮🇩';

  final List<Map<String, String>> _countryCodes = [
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

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _jamOperasional = '08:00 - 15:00 WIB';
  List<String> _sesiList = ['08:00 - 10:00', '10:00 - 12:00', '13:00 - 15:00'];
  String _selectedSesi = '08:00 - 10:00';
  int _qtyDewasa = 1;
  int _qtyPelajar = 0;
  int _qtyWna = 0;
  String _paymentMethod = 'QRIS';

  // Harga dari backend (default fallback)
  int _priceDewasa = 10000;
  int _pricePelajar = 5000;
  int _priceWna = 25000;

  // State backend
  bool _loadingCategories = true;
  bool _submitting = false;
  bool _openingPayment = false;
  TicketBooking? _booking;
  Uri? _paymentUri;

  // Deteksi Wisatawan Mancanegara berdasarkan kode negara nomor telepon
  bool get _isMancanegara {
    if (_selectedCountryCode != '+62') return true;
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return false;
    if (phone.startsWith('+62') ||
        phone.startsWith('08') ||
        phone.startsWith('62')) {
      return false;
    }
    return false;
  }

  String get _fullPhoneNumber {
    final num = _phoneController.text.trim();
    if (num.isEmpty) return '';
    if (num.startsWith('+')) return num;
    final cleanNum = num.startsWith('0') ? num.substring(1) : num;
    return '$_selectedCountryCode$cleanNum';
  }

  int get _totalBayar {
    if (_isMancanegara) {
      return _qtyWna * _priceWna;
    } else {
      return (_qtyDewasa * _priceDewasa) + (_qtyPelajar * _pricePelajar);
    }
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
    _phoneController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadPrices();
  }

  List<String> _generateSessionsFromJam(String jam) {
    final match = RegExp(r'(\d{1,2}):\d{2}\s*-\s*(\d{1,2}):\d{2}').firstMatch(jam);
    if (match == null) {
      return ['08:00 - 10:00', '10:00 - 12:00', '13:00 - 15:00'];
    }
    final openHour = int.tryParse(match.group(1)!) ?? 8;
    final closeHour = int.tryParse(match.group(2)!) ?? 15;
    if (closeHour <= openHour) {
      return ['08:00 - 10:00', '10:00 - 12:00', '13:00 - 15:00'];
    }

    final List<String> slots = [];
    int cursor = openHour;
    while (cursor < closeHour) {
      if (cursor == 12 && closeHour >= 14) {
        cursor = 13;
        continue;
      }
      final next = (cursor + 2 <= closeHour) ? cursor + 2 : closeHour;
      if (next > cursor) {
        final startStr = '${cursor.toString().padLeft(2, '0')}:00';
        final endStr = '${next.toString().padLeft(2, '0')}:00';
        slots.add('$startStr - $endStr');
      }
      cursor = next;
    }
    return slots.isNotEmpty ? slots : ['08:00 - 10:00', '10:00 - 12:00', '13:00 - 15:00'];
  }

  Future<void> _loadPrices() async {
    try {
      final results = await Future.wait([
        TiketService.getCategories(),
        TiketService.getJamOperasional().catchError((_) => <String, String>{}),
      ]);
      if (!mounted) return;
      final cats = results[0] as List<TiketCategory>;
      final jamInfo = results[1] as Map<String, String>;

      setState(() {
        for (final cat in cats) {
          if (cat.badge.contains('UMUM') || cat.badge.contains('DEWASA')) {
            _priceDewasa = cat.price;
          } else if (cat.badge.contains('PELAJAR')) {
            _pricePelajar = cat.price;
          } else if (cat.badge.contains('MANCANEGARA')) {
            _priceWna = cat.price;
          }
        }
        final jamStr = jamInfo['jam'];
        if (jamStr != null && jamStr.trim().isNotEmpty) {
          _jamOperasional = jamStr.trim();
          _sesiList = _generateSessionsFromJam(_jamOperasional);
          if (!_sesiList.contains(_selectedSesi) && _sesiList.isNotEmpty) {
            _selectedSesi = _sesiList.first;
          }
        }
        _loadingCategories = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _handleBayar() async {
    if (_namaController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama dan email wajib diisi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final totalTiket = _isMancanegara ? _qtyWna : (_qtyDewasa + _qtyPelajar);
    if (totalTiket == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal 1 tiket'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final booking = await TiketService.createBooking(
        nama: _namaController.text.trim(),
        email: _emailController.text.trim(),
        phone: _fullPhoneNumber.isNotEmpty ? _fullPhoneNumber : null,
        dewasa: _isMancanegara ? 0 : _qtyDewasa,
        pelajar: _isMancanegara ? 0 : _qtyPelajar,
        wna: _isMancanegara ? _qtyWna : 0,
        sesi: _selectedSesi,
        visitDate: _apiDate,
        paymentMethod: _paymentMethod,
        isMancanegara: _isMancanegara ? 1 : 0,
      );
      if (!mounted) return;
      setState(() {
        _booking = booking;
        _paymentUri = null;
        _currentStep = 1;
        _submitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _openPayment() async {
    final booking = _booking;
    if (booking == null || _openingPayment) return;

    setState(() => _openingPayment = true);
    try {
      var paymentUri = _paymentUri;
      if (paymentUri == null) {
        paymentUri = await TiketService.createPayment(booking.id);
        if (!mounted) return;
        setState(() => _paymentUri = paymentUri);
      }

      final launched = await launchUrl(
        paymentUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Halaman pembayaran tidak dapat dibuka. Silakan coba lagi.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _openingPayment = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      helpText: 'Pilih Tanggal Kunjungan',
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
    _namaController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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
                    const Text(
                      'MUSEUM BRAWIJAYA',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: textDark,
                      ),
                    ),
                  ],
                ),
              ),
              _currentStep == 0
                  ? _buildFormulirPemesanan(
                      darkGreen,
                      goldAccent,
                      cardBg,
                      textDark,
                      textMuted,
                      borderLight,
                    )
                  : _buildInstruksiPembayaran(
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
          Row(
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
                  Text(
                    '1. Data Diri Pemesan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildInputLabelField(
                'Nama Lengkap (Sesuai KTP/Paspor)',
                _namaController,
              ),
              const SizedBox(height: 12),
              _buildInputLabelField(
                'Email (Pengiriman E-Tiket & QR Code)',
                _emailController,
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
                  Text(
                    '2. Tanggal & Waktu Kunjungan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textDark,
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
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
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formattedDate,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textDark,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 6),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F5F3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _jamOperasional,
                            style: TextStyle(fontSize: 12, color: textDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _sesiList
                    .map((sesi) => _buildSesiChip(sesi, darkGreen))
                    .toList(),
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
                  Text(
                    '3. Pilih Kategori Tiket',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_loadingCategories)
                const Center(
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (_isMancanegara) ...[
                // Khusus Wisatawan Mancanegara
                _buildQtyRow(
                  'Wisatawan Asing (International Tourist)',
                  'Rp ${_priceWna.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}/person',
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
                // Khusus Wisatawan Dalam Negeri (Domestik)
                _buildQtyRow(
                  'WNI - Dewasa / Umum',
                  'Rp ${_priceDewasa.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}/orang',
                  _qtyDewasa,
                  (val) => setState(() => _qtyDewasa = val),
                  darkGreen,
                ),
                Divider(height: 20, color: borderLight),
                _buildQtyRow(
                  'WNI - Pelajar / Anak',
                  'Rp ${_pricePelajar.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}/orang',
                  _qtyPelajar,
                  (val) => setState(() => _qtyPelajar = val),
                  darkGreen,
                ),
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
                  Text(
                    '4. Metode Pembayaran',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (_isMancanegara) ...[
                // Pilihan untuk Wisatawan Mancanegara (Kartu Kredit / Visa / Mastercard)
                GestureDetector(
                  onTap: () => setState(() => _paymentMethod = 'CREDIT_CARD'),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _paymentMethod == 'CREDIT_CARD'
                          ? const Color(0xFFF3E8FF)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _paymentMethod == 'CREDIT_CARD'
                            ? const Color(0xFF7E22CE)
                            : borderLight,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Radio<String>(
                          value: 'CREDIT_CARD',
                          groupValue: _paymentMethod,
                          activeColor: const Color(0xFF7E22CE),
                          onChanged: (val) {
                            if (val != null)
                              setState(() => _paymentMethod = val);
                          },
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
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
                        Row(
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
                ),
              ] else ...[
                // Pilihan untuk Wisatawan Domestik (QRIS & Bank Transfer)
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _paymentMethod = 'QRIS'),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _paymentMethod == 'QRIS'
                                ? const Color(0xFFF4F5F3)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _paymentMethod == 'QRIS'
                                  ? darkGreen
                                  : borderLight,
                            ),
                          ),
                          child: Row(
                            children: [
                              Radio<String>(
                                value: 'QRIS',
                                groupValue: _paymentMethod,
                                activeColor: darkGreen,
                                onChanged: (val) {
                                  if (val != null)
                                    setState(() => _paymentMethod = val);
                                },
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'QRIS (E-Wallet)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: textDark,
                                    ),
                                  ),
                                  Text(
                                    'Gopay, OVO, Dana',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: textMuted,
                                    ),
                                  ),
                                ],
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
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _paymentMethod == 'BANK'
                                ? const Color(0xFFF4F5F3)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _paymentMethod == 'BANK'
                                  ? darkGreen
                                  : borderLight,
                            ),
                          ),
                          child: Row(
                            children: [
                              Radio<String>(
                                value: 'BANK',
                                groupValue: _paymentMethod,
                                activeColor: darkGreen,
                                onChanged: (val) {
                                  if (val != null)
                                    setState(() => _paymentMethod = val);
                                },
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Transfer Bank',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: textDark,
                                    ),
                                  ),
                                  Text(
                                    'BCA, Mandiri, BNI',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '5. Ringkasan Pesanan',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: goldAccent,
                      ),
                    ),
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
                if (_isMancanegara) ...[
                  _buildSummaryRow(
                    'Wisatawan Asing x$_qtyWna',
                    'Rp ${(_qtyWna * _priceWna).toString()}',
                  ),
                ] else ...[
                  _buildSummaryRow(
                    'WNI - Dewasa x$_qtyDewasa',
                    'Rp ${(_qtyDewasa * _priceDewasa).toString()}',
                  ),
                  if (_qtyPelajar > 0)
                    _buildSummaryRow(
                      'WNI - Pelajar x$_qtyPelajar',
                      'Rp ${(_qtyPelajar * _pricePelajar).toString()}',
                    ),
                ],
                _buildSummaryRow('Metode Bayar:', _paymentMethod),
                _buildSummaryRow('Biaya Admin:', 'GRATIS', isGold: true),
                const Divider(color: Colors.white24, height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Bayar',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Rp ${_totalBayar.toString()}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: goldAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: _submitting ? null : _handleBayar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: goldAccent,
                    foregroundColor: textDark,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _submitting
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
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.lock, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Bayar Tiket Sekarang',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    '🔒 E-Tiket Resmi & QR Code instan dikirim via Email',
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
                SizedBox(height: 4),
                Text(
                  'Lanjutkan pembayaran melalui halaman Midtrans. E-tiket resmi akan dikirim melalui Email / WhatsApp setelah pembayaran diverifikasi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildCardSection(
            cardBg,
            borderLight,
            children: [
              const Icon(
                Icons.info_outline,
                size: 20,
                color: Color(0xFF3F5243),
              ),
              const SizedBox(height: 8),
              Text(
                'Selesaikan pembayaran pada halaman Midtrans. Status pembayaran akan diperbarui setelah notifikasi diterima backend.',
                style: TextStyle(fontSize: 11, color: textMuted),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                  Text(
                    'Pembayaran aman melalui Midtrans',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Pilih QRIS, transfer bank, atau metode lain yang tersedia di halaman pembayaran Midtrans.',
                style: TextStyle(fontSize: 11, color: textMuted),
              ),
              const SizedBox(height: 16),
              _buildDetailInfoRow('Kode Pesanan', _booking?.id ?? '-'),
              _buildDetailInfoRow(
                'Total Tagihan',
                'Rp ${_booking?.totalBiaya ?? 0}',
                isBoldPrice: true,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _openingPayment ? null : _openPayment,
                icon: _openingPayment
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
                  _openingPayment
                      ? 'Menghubungkan ke Midtrans...'
                      : 'Lanjutkan Pembayaran',
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
            ],
          ),
          const SizedBox(height: 20),
          // Info notifikasi E-Tiket via Email & WhatsApp
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
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
                            'Setelah pembayaran selesai dan diverifikasi, E-Tiket beserta barcode/QR code resmi hanya dapat diakses melalui:',
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
                              'Email: ${_emailController.text.isNotEmpty ? _emailController.text : "Email Anda"}',
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
                              'WhatsApp: ${_fullPhoneNumber.isNotEmpty ? _fullPhoneNumber : "Nomor WhatsApp Anda"}',
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

  Widget _buildSesiChip(String label, Color darkGreen) {
    bool isSelected = _selectedSesi == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedSesi = label),
      child: Container(
        width: 98,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? darkGreen : const Color(0xFFF4F5F3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              label,
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
    );
  }

  Widget _buildQtyRow(
    String title,
    String subtitle,
    int qty,
    Function(int) onChanged,
    Color darkGreen,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
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
        Row(
          children: [
            IconButton(
              onPressed: qty > 0 ? () => onChanged(qty - 1) : null,
              icon: const Icon(Icons.remove_circle_outline, size: 20),
              color: darkGreen,
            ),
            Text(
              '$qty',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: () => onChanged(qty + 1),
              icon: const Icon(Icons.add_circle, size: 20),
              color: darkGreen,
            ),
          ],
        ),
      ],
    );
  }

  void _showCountryPicker() {
    final searchCtrl = TextEditingController();
    showModalBottomSheet(
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
                            setState(() {
                              _selectedCountryCode = item['code']!;
                              _selectedCountryFlag = item['flag']!;
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
    );
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
              // Dropdown negara dengan bendera dan tanda kebawah
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
              // Input field nomor telepon
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

  Widget _buildInputLabelField(String label, TextEditingController controller) {
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
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isGold ? const Color(0xFFCBB26A) : Colors.white,
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF727A71)),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBoldPrice ? 14 : 11,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2C322B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildETicketRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
