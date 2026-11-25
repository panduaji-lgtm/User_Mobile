import 'package:flutter/material.dart';

class DetailSenjataPrriScreen extends StatelessWidget {
  final VoidCallback onBack;

  const DetailSenjataPrriScreen({super.key, required this.onBack});

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
              // 1. Header Logo
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

              // 2. Tombol Kembali
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: InkWell(
                  onTap: onBack,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.arrow_back, size: 16, color: textDark),
                      SizedBox(width: 6),
                      Text(
                        'Kembali',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 3. Card Utama Detail Koleksi
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Gambar dengan Overlay Badge
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            Image.asset(
                              'assets/images/collection/menu_senjata_penumpasan_prri.png',
                              height: 190,
                              width: double.infinity,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 190,
                                  color: Colors.grey.shade300,
                                  child: const Icon(
                                    Icons.security,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                            Positioned(
                              bottom: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: darkGreen.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'SENJATA PENUMPASAN PRRI',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Judul & Subjudul
                      const Text(
                        'Senjata Penumpasan PRRI',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'OPERASI MILITER',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: textMuted,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Grid Spesifikasi (Kategori, Operasi Militer, Pelaksanaan)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F7F3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderLight),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Expanded(
                              child: _SpecItem(
                                label: 'KATEGORI',
                                value: 'Senjata Api Lapangan',
                              ),
                            ),
                            Container(width: 1, height: 30, color: borderLight),
                            Expanded(
                              child: _SpecItem(
                                label: 'OPERASI MILITER',
                                value: 'Operasi 17 Agustus',
                              ),
                            ),
                            Container(width: 1, height: 30, color: borderLight),
                            Expanded(
                              child: _SpecItem(
                                label: 'PELAKSANAAN',
                                value: 'Batalyon Kodam V/Brawijaya',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Subjudul Sejarah & Latar Belakang
                      Row(
                        children: const [
                          Padding(
                            padding: EdgeInsets.only(right: 8.0),
                            child: Icon(
                              Icons.circle,
                              size: 8,
                              color: goldAccent,
                            ),
                          ),
                          Text(
                            'Sejarah & Latar Belakang',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Paragraf Deskripsi Sejarah
                      const Text(
                        'Koleksi senjata persenjataan ini merupakan peralatan tempur dan senjata rampasan yang digunakan oleh pasukan jajaran Kodam V/Brawijaya saat dikirim dalam operasi penumpasan pemberontakan PRRI (Pemerintah Revolusioner Republik Indonesia) di Sumatera dan Permesta di Sulawesi pada kurun waktu 1958 hingga 1961.\n\nKeterlibatan prajurit Brawijaya dalam operasi gabungan penumpasan ini menjadi bukti peran aktif pasukan Jawa Timur dalam menjaga keutuhan Negara Kesatuan Republik Indonesia (NKRI) dari ancaman disintegrasi dan gerakan separatisme daerah.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: textMuted,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper Widget untuk Spesifikasi
class _SpecItem extends StatelessWidget {
  final String label;
  final String value;

  const _SpecItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF727A71),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C322B),
            height: 1.2,
          ),
        ),
      ],
    );
  }
}
