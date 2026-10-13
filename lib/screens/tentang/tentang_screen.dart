import 'package:flutter/material.dart';

class TentangScreen extends StatelessWidget {
  const TentangScreen({super.key});

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

              // 2. Title Section & Badge
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFECE6),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: borderLight),
                      ),
                      child: const Text(
                        'TENTANG KAMI',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: goldAccent,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tentang Museum Brawijaya',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Card Sejarah Berdirinya
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderLight),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        child: Image.asset(
                          'assets/images/museum_brawijaya.jpg',
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          alignment: const Alignment(0, -0.2),
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 180,
                              color: Colors.grey.shade300,
                              child: const Icon(
                                Icons.museum,
                                size: 50,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sejarah Berdirinya',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Dibangun atas prakarsa Brigjen TNI (Purn.) Soerachman, Pangdam VIII Brawijaya (1959–1962). Pembangunan dimulai tahun 1967 dan secara resmi diresmikan pada 4 Mei 1968 oleh Kolonel Dr. Soewondo.\n\nMuseum ini didirikan dengan tujuan luhur mengenang dan mewariskan semangat perjuangan Tentara Keamanan Rakyat (TKR) bersama seluruh rakyat pejuang Jawa Timur dalam mempertahankan kemerdekaan Republik Indonesia.',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: textMuted,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 4. Card Perjalanan Museum (Timeline)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderLight),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Perjalanan Museum',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTimelineItem('1962', 'Gagasan Awal', true),
                          _buildTimelineLine(),
                          _buildTimelineItem(
                            '1967',
                            'Pembangunan\nDimulai',
                            true,
                          ),
                          _buildTimelineLine(),
                          _buildTimelineItem('1968', 'Diresmikan', true),
                          _buildTimelineLine(),
                          _buildTimelineItem(
                            'Sekarang',
                            'Terus Benah',
                            false,
                            isLast: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 5. Card Visi
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Visi',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Menjadi pusat edukasi dan rekreasi sejarah perjuangan bangsa yang inspiratif, inklusif, dan relevan bagi generasi muda Jawa Timur dan Indonesia.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: textMuted,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 6. Card Misi
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Misi',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildBulletMission(
                        'Melestarikan dan merawat koleksi benda peninggalan bersejarah.',
                      ),
                      const SizedBox(height: 8),
                      _buildBulletMission(
                        'Mengedukasi generasi muda tentang nilai-nilai patriotisme dan perjuangan \'45.',
                      ),
                      const SizedBox(height: 8),
                      _buildBulletMission(
                        'Meningkatkan aksesibilitas informasi digital dan fasilitas kunjungan.',
                      ),
                      const SizedBox(height: 8),
                      _buildBulletMission(
                        'Menjaga keutuhan narasi sejarah perjuangan kemerdekaan Jawa Timur.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 7. Galeri Museum Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Galeri Museum',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const Text(
                      '6 FOTO PILIHAN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: goldAccent,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Galeri Grid (2 Kolom)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildGalleryCard(
                      'assets/images/collection/menu_gerbong_maut.png',
                      'Gerbong Maut',
                    ),
                    _buildGalleryCard(
                      'assets/images/collection/peta_operasi_militer.png',
                      'Peta Operasi Militer',
                    ),
                    _buildGalleryCard(
                      'assets/images/collection/diorama_pertempuran.png',
                      'Diorama Pertempuran',
                    ),
                    _buildGalleryCard(
                      'assets/images/museum_brawijaya.jpg',
                      'Museum Brawijaya',
                    ),
                    _buildGalleryCard(
                      'assets/images/collection/menu_mobil_dinas_letkol.png',
                      'Mobil Dinas Letkol',
                    ),
                    _buildGalleryCard(
                      'assets/images/collection/menu_perahu_segigir.png',
                      'Perahu Segigir',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
    String year,
    String label,
    bool isActive, {
    bool isLast = false,
  }) {
    const Color goldAccent = Color(0xFFCBB26A);
    const Color textMuted = Color(0xFF727A71);

    return Column(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isLast ? const Color(0xFF2C322B) : goldAccent,
            border: Border.all(color: Colors.white, width: 3),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          year,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C322B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 8.5, color: textMuted, height: 1.2),
        ),
      ],
    );
  }

  Widget _buildTimelineLine() {
    return Expanded(
      child: Container(
        height: 2,
        color: const Color(0xFFE0E3DF),
        margin: const EdgeInsets.only(bottom: 25),
      ),
    );
  }

  Widget _buildBulletMission(String text) {
    const Color textMuted = Color(0xFF727A71);
    const Color goldAccent = Color(0xFFCBB26A);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 5.0),
          child: Icon(Icons.circle, size: 6, color: goldAccent),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 11.5,
              color: textMuted,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGalleryCard(String imagePath, String caption) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            imagePath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey.shade300,
                child: const Icon(
                  Icons.image_not_supported,
                  color: Colors.grey,
                ),
              );
            },
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Text(
                caption,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
