import 'package:flutter/material.dart';

class DetailGenericKoleksiScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final String category;
  final String description;
  final String? tahun;
  final String? lokasi;
  final String? image;
  final VoidCallback onBack;

  const DetailGenericKoleksiScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.description,
    this.tahun,
    this.lokasi,
    this.image,
    required this.onBack,
  });

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
                      Icon(Icons.arrow_back, size: 18, color: textDark),
                      SizedBox(width: 8),
                      Text(
                        'Kembali ke Koleksi',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 3. Card Detail Utama
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge Kategori & Tahun
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: darkGreen.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                category.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: darkGreen,
                                ),
                              ),
                            ),
                            if (tahun != null && tahun!.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: goldAccent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'TAHUN $tahun',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF8A6D1C),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Judul & Subtitle
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        child: Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: textMuted,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Gambar
                      if (image != null && image!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: image!.startsWith('http')
                                ? Image.network(
                                    image!,
                                    width: double.infinity,
                                    height: 220,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _buildPlaceholder(),
                                  )
                                : Image.asset(
                                    image!,
                                    width: double.infinity,
                                    height: 220,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _buildPlaceholder(),
                                  ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: _buildPlaceholder(),
                        ),

                      // Lokasi
                      if (lokasi != null && lokasi!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: darkGreen),
                              const SizedBox(width: 6),
                              Text(
                                'Lokasi: $lokasi',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: darkGreen,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Deskripsi Lengkap
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          description.isNotEmpty ? description : 'Koleksi artefak bersejarah Museum Brawijaya Malang.',
                          style: const TextStyle(
                            fontSize: 13,
                            color: textDark,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFFEAE5DC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(Icons.museum_outlined, size: 48, color: Color(0xFF727A71)),
      ),
    );
  }
}
