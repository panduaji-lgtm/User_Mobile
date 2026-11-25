import 'package:flutter/material.dart';

class DetailMeriamSiBuangScreen extends StatelessWidget {
  final VoidCallback onBack;

  const DetailMeriamSiBuangScreen({super.key, required this.onBack});

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
                              'assets/images/collection/menu_meriam_si_buang.png',
                              height: 190,
                              width: double.infinity,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 190,
                                  color: Colors.grey.shade300,
                                  child: const Icon(
                                    Icons.shield,
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
                                  'MERIAM SI BUANG',
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
                        'Meriam Si Buang',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        '1945',
                        style: TextStyle(fontSize: 11, color: textMuted),
                      ),
                      const SizedBox(height: 16),

                      // Grid Spesifikasi (Kategori, Kaliber, Lokasi Awal)
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
                                value: 'Senjata Berat',
                              ),
                            ),
                            Container(width: 1, height: 30, color: borderLight),
                            Expanded(
                              child: _SpecItem(
                                label: 'KALIBER',
                                value: '75 mm',
                              ),
                            ),
                            Container(width: 1, height: 30, color: borderLight),
                            Expanded(
                              child: _SpecItem(
                                label: 'LOKASI AWAL',
                                value: 'Bangil, Pasuruan',
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
                        'Meriam Si Buang merupakan meriam hasil rampasan dari pasukan Angkatan Laut Kerajaan Belanda (KM) yang berhasil direbut oleh pasukan pejuang BKR/TKR Indonesia dalam pertempuran sengit di wilayah Bangil, Kabupaten Pasuruan pada tahun 1945.\n\nSatu hal yang unik dan bersejarah dari meriam ini adalah gugurnya prajurit pejuang bernama Kopral Buang saat mempertahankan pertahanan dan mengoperasikan meriam ini dalam membendung gempuran pasukan Belanda. Sebagai bentuk penghormatan dan mengenang jasa pengorbanan Kopral Buang, meriam ini diabadikan dan diberi nama "Si Buang".',
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
          ),
        ),
      ],
    );
  }
}
