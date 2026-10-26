import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/tiket_service.dart';

class TiketScreen extends StatefulWidget {
  const TiketScreen({super.key, required this.onGoHome});

  final VoidCallback onGoHome;

  @override
  State<TiketScreen> createState() => _TiketScreenState();
}

class _TiketScreenState extends State<TiketScreen> {
  int _currentStep = 0;

  final TextEditingController _namaController = TextEditingController(text: '');
  final TextEditingController _emailController = TextEditingController(text: '');
  final TextEditingController _phoneController = TextEditingController(text: '');

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
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
  TicketBooking? _booking;

  // Countdown timer (15 menit)
  Timer? _countdownTimer;
  int _secondsLeft = 15 * 60;

  int get _totalBayar =>
      (_qtyDewasa * _priceDewasa) +
      (_qtyPelajar * _pricePelajar) +
      (_qtyWna * _priceWna);

  String get _formattedDate {
    final d = _selectedDate;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String get _apiDate {
    final d = _selectedDate;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String get _countdownFormatted {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')} : ${s.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _loadPrices();
  }

  Future<void> _loadPrices() async {
    try {
      final cats = await TiketService.getCategories();
      if (!mounted) return;
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
        _loadingCategories = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _secondsLeft = 15 * 60;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 0) {
        t.cancel();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Waktu pembayaran habis. Silakan pesan ulang.'), backgroundColor: Colors.red),
          );
          setState(() => _currentStep = 0);
        }
      } else {
        if (mounted) setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _handleBayar() async {
    if (_namaController.text.trim().isEmpty || _emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan email wajib diisi'), backgroundColor: Colors.red),
      );
      return;
    }
    final totalTiket = _qtyDewasa + _qtyPelajar + _qtyWna;
    if (totalTiket == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal 1 tiket'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final booking = await TiketService.createBooking(
        nama: _namaController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        dewasa: _qtyDewasa,
        pelajar: _qtyPelajar,
        wna: _qtyWna,
        sesi: _selectedSesi,
        visitDate: _apiDate,
        paymentMethod: _paymentMethod,
      );
      if (!mounted) return;
      setState(() {
        _booking = booking;
        _currentStep = 1;
        _submitting = false;
      });
      _startCountdown();
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Disalin: $text'),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF3F5243),
        ),
      );
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
    _countdownTimer?.cancel();
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
          _buildCardSection(
            cardBg,
            borderLight,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: Color(0xFFCBB26A),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '1. Tanggal & Waktu Kunjungan',
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
                              border: Border.all(color: const Color(0xFFCBB26A)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formattedDate,
                                  style: TextStyle(fontSize: 12, color: textDark, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.edit_calendar_outlined, size: 14, color: Color(0xFF3F5243)),
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
                            '08:00 - 15:00 WIB',
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
              Row(
                children: [
                  _buildSesiChip('08:00 - 10:00', darkGreen),
                  const SizedBox(width: 8),
                  _buildSesiChip('10:00 - 12:00', darkGreen),
                  const SizedBox(width: 8),
                  _buildSesiChip('13:00 - 15:00', darkGreen),
                ],
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
                  Icon(
                    Icons.confirmation_number_outlined,
                    size: 18,
                    color: Color(0xFFCBB26A),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '2. Pilih Kategori Tiket',
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
                const Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)))
              else ...[
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
                Divider(height: 20, color: borderLight),
                _buildQtyRow(
                  'WNA - Wisatawan Asing',
                  'Rp ${_priceWna.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}/person',
                  _qtyWna,
                  (val) => setState(() => _qtyWna = val),
                  darkGreen,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          _buildCardSection(
            cardBg,
            borderLight,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 18,
                    color: Color(0xFFCBB26A),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '3. Data Diri Pemesan',
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
                'Nama Lengkap (Sesuai KTP/Identitas)',
                _namaController,
              ),
              const SizedBox(height: 12),
              _buildInputLabelField(
                'Email (Pengiriman E-Tiket)',
                _emailController,
              ),
              const SizedBox(height: 12),
              _buildInputLabelField('No. WhatsApp / Telepon', _phoneController),
            ],
          ),
          const SizedBox(height: 16),
          _buildCardSection(
            cardBg,
            borderLight,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 18,
                    color: Color(0xFFCBB26A),
                  ),
                  SizedBox(width: 8),
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
              RadioGroup<String>(
                groupValue: _paymentMethod,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _paymentMethod = value);
                  }
                },
                child: Row(
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
                                activeColor: darkGreen,
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
                                activeColor: darkGreen,
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
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: darkGreen,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ringkasan Pesanan',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: goldAccent,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSummaryRow('Lokasi:', 'Museum Brawijaya'),
                _buildSummaryRow('Tanggal:', _formattedDate),
                _buildSummaryRow('Sesi Waktu:', _selectedSesi),
                _buildSummaryRow(
                  'WNI - Dewasa x$_qtyDewasa',
                  'Rp ${(_qtyDewasa * _priceDewasa).toString()}',
                ),
                if (_qtyPelajar > 0)
                  _buildSummaryRow(
                    'WNI - Pelajar x$_qtyPelajar',
                    'Rp ${(_qtyPelajar * _pricePelajar).toString()}',
                  ),
                if (_qtyWna > 0)
                  _buildSummaryRow(
                    'WNA x$_qtyWna',
                    'Rp ${(_qtyWna * _priceWna).toString()}',
                  ),
                _buildSummaryRow('Biaya Admin', 'GRATIS', isGold: true),
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
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
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
                    '🔒 E-Tiket Instant dikirim via WhatsApp & Email',
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
                  'Instruksi Pembayaran & E-Tiket',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Selesaikan pembayaran sebelum batas waktu berakhir untuk mengaktifkan E-Tiket Anda.',
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SISA WAKTU PEMBAYARAN',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: textMuted,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _countdownFormatted,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _secondsLeft < 60 ? Colors.red.shade800 : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Batas Waktu',
                        style: TextStyle(fontSize: 10, color: textMuted),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '20 Sep 2026, 08:15 WIB',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCardSection(
            cardBg,
            borderLight,
            children: _paymentMethod == 'QRIS'
                ? [
                    // ── HEADER QRIS ──────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.qr_code_2, size: 20, color: textDark),
                            SizedBox(width: 8),
                            Text(
                              'Pembayaran via QRIS',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Otomatis',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Scan menggunakan GoPay, OVO, ShopeePay, DANA, atau M-Banking',
                      style: TextStyle(fontSize: 10, color: textMuted),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Container(
                        width: 220,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderLight),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5E7EB),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.qr_code, size: 60, color: textMuted),
                                  SizedBox(height: 8),
                                  Text(
                                    'QR CODE QRIS',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'NMID: ID10202688910',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                            Text(
                              'Museum Brawijaya Official',
                              style: TextStyle(fontSize: 9, color: textMuted),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailInfoRow('Kode Pesanan', _booking?.id ?? '#MBW-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}'),
                    _buildDetailInfoRow(
                      'Total Tagihan',
                      'Rp ${_booking != null ? _booking!.totalBiaya.toString() : _totalBayar.toString()}',
                      isBoldPrice: true,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Status: Menunggu Pembayaran. Harap selesaikan pembayaran.'),
                            backgroundColor: Colors.teal,
                          ),
                        );
                      },
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Cek Status Pembayaran'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkGreen,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ]
                : [
                    // ── HEADER TRANSFER BANK ─────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.account_balance, size: 20, color: textDark),
                            SizedBox(width: 8),
                            Text(
                              'Transfer Bank',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Manual',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pilih salah satu bank dan transfer sesuai nominal tagihan',
                      style: TextStyle(fontSize: 10, color: textMuted),
                    ),
                    const SizedBox(height: 16),

                    // ── KARTU BCA ────────────────────────────────────────
                    _buildBankCard(
                      bankName: 'BCA',
                      accountNumber: '1234 5678 9012',
                      accountName: 'Museum Brawijaya',
                      bankColor: const Color(0xFF005BAC),
                      logoIcon: Icons.account_balance,
                      cardBg: cardBg,
                      borderLight: borderLight,
                      textDark: textDark,
                      textMuted: textMuted,
                    ),
                    const SizedBox(height: 10),

                    // ── KARTU MANDIRI ────────────────────────────────────
                    _buildBankCard(
                      bankName: 'Mandiri',
                      accountNumber: '1400 0012 3456 789',
                      accountName: 'Museum Brawijaya',
                      bankColor: const Color(0xFF003087),
                      logoIcon: Icons.account_balance,
                      cardBg: cardBg,
                      borderLight: borderLight,
                      textDark: textDark,
                      textMuted: textMuted,
                    ),
                    const SizedBox(height: 10),

                    // ── KARTU BNI ─────────────────────────────────────────
                    _buildBankCard(
                      bankName: 'BNI',
                      accountNumber: '0123 4567 89',
                      accountName: 'Museum Brawijaya',
                      bankColor: const Color(0xFFFF6200),
                      logoIcon: Icons.account_balance,
                      cardBg: cardBg,
                      borderLight: borderLight,
                      textDark: textDark,
                      textMuted: textMuted,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailInfoRow('Kode Pesanan', _booking?.id ?? '#MBW-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}'),
                    _buildDetailInfoRow(
                      'Total Tagihan',
                      'Rp ${_booking != null ? _booking!.totalBiaya.toString() : _totalBayar.toString()}',
                      isBoldPrice: true,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Konfirmasi diterima! E-Tiket Anda sedang diverifikasi.'),
                            backgroundColor: Colors.teal,
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text('Konfirmasi Transfer'),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PREVIEW E-TIKET',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: goldAccent,
                          ),
                        ),
                        Text(
                          'Museum Brawijaya',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Lunas',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(color: Colors.white24, height: 24),
                _buildETicketRow('Nama Pemesan:', _namaController.text.isNotEmpty ? _namaController.text : 'Pengunjung'),
                _buildETicketRow('Tanggal Kunjungan:', _formattedDate),
                _buildETicketRow('Sesi Jam:', _selectedSesi),
                _buildETicketRow(
                  'Kategori Tiket:',
                  'Dewasa ($_qtyDewasa)${_qtyPelajar > 0 ? ', Pelajar ($_qtyPelajar)' : ''}${_qtyWna > 0 ? ', WNA ($_qtyWna)' : ''}',
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.barcode_reader, size: 40, color: goldAccent),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () {
                          final code = _booking?.id ?? 'MBW-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                          _copyToClipboard(code);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _booking?.id ?? 'MBW-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                              style: TextStyle(
                                fontSize: 13,
                                letterSpacing: 2,
                                color: goldAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.copy, size: 14, color: goldAccent),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '*E-Tiket & QR Code Masuk akan aktif otomatis setelah pembayaran berhasil diproses.',
                  style: TextStyle(fontSize: 9, color: Colors.white70),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('E-Tiket sedang diunduh (format PDF)...'),
                        backgroundColor: Colors.teal,
                      ),
                    );
                  },
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Unduh E-Tiket (PDF)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    'Salinan e-tiket juga dikirim ke email ${_emailController.text}',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Colors.white70,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => setState(() => _currentStep = 0),
                  child: Center(
                    child: Text(
                      '← Kembali ke Formulir',
                      style: TextStyle(color: goldAccent, fontSize: 11),
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
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedSesi = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
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

  Widget _buildBankCard({
    required String bankName,
    required String accountNumber,
    required String accountName,
    required Color bankColor,
    required IconData logoIcon,
    required Color cardBg,
    required Color borderLight,
    required Color textDark,
    required Color textMuted,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header warna bank ──────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bankColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(logoIcon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Bank $bankName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // ── Isi: nomor rekening & nama ─────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nomor Rekening',
                      style: TextStyle(fontSize: 9, color: textMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      accountNumber,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'a.n. $accountName',
                      style: TextStyle(fontSize: 10, color: textMuted),
                    ),
                  ],
                ),
                // ── Tombol salin ───────────────────────────────────
                GestureDetector(
                  onTap: () => _copyToClipboard(accountNumber.replaceAll(' ', '')),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: bankColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: bankColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.copy, size: 12, color: bankColor),
                        const SizedBox(width: 4),
                        Text(
                          'Salin',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: bankColor,
                          ),
                        ),
                      ],
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
}
