import 'package:flutter/material.dart';

class DetailGenericKoleksiScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final String category;
  final String description;
  final String? tahun;
  final String? lokasi;
  final String? image;
  final String? fallbackAsset;
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
    this.fallbackAsset,
    required this.onBack,
  });

  Widget _buildDetailImage() {
    final trimmedImage = (image ?? '').trim();
    final trimmedFallback = (fallbackAsset ?? '').trim();

    Widget buildAssetOrPlaceholder(String assetPath) {
      if (assetPath.isEmpty) return _buildPlaceholder();
      return Image.asset(
        assetPath,
        width: double.infinity,
        height: 220,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _buildPlaceholder(),
      );
    }

    if (trimmedImage.startsWith('http://') ||
        trimmedImage.startsWith('https://')) {
      return Image.network(
        trimmedImage,
        width: double.infinity,
        height: 220,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => buildAssetOrPlaceholder(trimmedFallback),
      );
    }

    if (trimmedImage.isNotEmpty) {
      return buildAssetOrPlaceholder(trimmedImage);
    }

    return buildAssetOrPlaceholder(trimmedFallback);
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
                  borderRadius: BorderRadius.circular(8),
                  onTap: onBack,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                      // Badge Kategori & Tahun (Wrap agar aman di layar kecil)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
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
                            if (tahun != null && tahun!.trim().isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: goldAccent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'TAHUN ${tahun!.trim()}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF8A6D1C),
                                  ),
                                ),
                              ),
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
                      if (subtitle.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 4,
                          ),
                          child: Text(
                            subtitle.trim(),
                            style: const TextStyle(
                              fontSize: 13,
                              color: textMuted,
                            ),
                          ),
                        ),

                      const SizedBox(height: 12),

                      // Gambar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            color: bgCream,
                            child: _buildDetailImage(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Lokasi
                      if (lokasi != null && lokasi!.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 6,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 1),
                                child: Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: darkGreen,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Lokasi: ${lokasi!.trim()}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: darkGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Deskripsi Lengkap
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          description.trim().isNotEmpty
                              ? description.trim()
                              : 'Koleksi artefak bersejarah Museum Brawijaya Malang.',
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
        child: Icon(
          Icons.museum_outlined,
          size: 48,
          color: Color(0xFF727A71),
        ),
      ),
    );
  }
}
