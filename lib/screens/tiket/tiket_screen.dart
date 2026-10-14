import 'package:flutter/material.dart';

class TiketScreen extends StatefulWidget {
  const TiketScreen({super.key, required this.onGoHome});

  final VoidCallback onGoHome;

  @override
  State<TiketScreen> createState() => _TiketScreenState();
}

class _TiketScreenState extends State<TiketScreen> {
  int _currentStep = 0;

  final TextEditingController _namaController = TextEditingController(
    text: 'Budi Santoso',
  );
  final TextEditingController _emailController = TextEditingController(
    text: 'budi@example.com',
  );
  final TextEditingController _phoneController = TextEditingController(
    text: '081234567890',
  );

  final String _selectedDate = '09/20/2026';
  String _selectedSesi = '08:00 - 10:00';
  int _qtyDewasa = 1;
  int _qtyPelajar = 0;
  int _qtyWna = 0;
  String _paymentMethod = 'QRIS';

  final int _priceDewasa = 10000;
  final int _pricePelajar = 5000;
  final int _priceWna = 20000;

  int get _totalBayar =>
      (_qtyDewasa * _priceDewasa) +
      (_qtyPelajar * _pricePelajar) +
      (_qtyWna * _priceWna);

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
                            _selectedDate,
                            style: TextStyle(fontSize: 12, color: textDark),
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
              _buildQtyRow(
                'WNI - Dewasa / Umum',
                'Rp 10.000 /orang',
                _qtyDewasa,
                (val) => setState(() => _qtyDewasa = val),
                darkGreen,
              ),
              Divider(height: 20, color: borderLight),
              _buildQtyRow(
                'WNI - Pelajar / Anak',
                'Rp 5.000 /orang',
                _qtyPelajar,
                (val) => setState(() => _qtyPelajar = val),
                darkGreen,
              ),
              Divider(height: 20, color: borderLight),
              _buildQtyRow(
                'WNA - Wisatawan Asing',
                'Rp 20.000 /person',
                _qtyWna,
                (val) => setState(() => _qtyWna = val),
                darkGreen,
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
                _buildSummaryRow('Tanggal:', '20 Sep 2026'),
                _buildSummaryRow('Sesi Waktu:', _selectedSesi),
                _buildSummaryRow(
                  'WNI - Dewasa x$_qtyDewasa',
                  'Rp ${(_qtyDewasa * _priceDewasa).toString()}',
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
                  onPressed: () {
                    setState(() {
                      _currentStep = 1;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: goldAccent,
                    foregroundColor: textDark,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
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
                        '14 : 59 : 30',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
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
            children: [
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
              _buildDetailInfoRow('Kode Pesanan', '#MBW-2026-9941'),
              _buildDetailInfoRow(
                'Total Tagihan',
                'Rp 10.000',
                isBoldPrice: true,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {},
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
                _buildETicketRow('Nama Pemesan:', _namaController.text),
                _buildETicketRow('Tanggal Kunjungan:', '20 Sep 2026'),
                _buildETicketRow('Sesi Jam:', _selectedSesi),
                _buildETicketRow('Kategori Tiket:', 'WNI - Dewasa (x1)'),
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
                      SizedBox(height: 4),
                      Text(
                        'MBW-2026-9941',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 2,
                          color: goldAccent,
                          fontWeight: FontWeight.bold,
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
                  onPressed: () {},
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
}
