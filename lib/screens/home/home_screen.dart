import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onBookTicket,
    required this.onReadHistory,
  });

  final VoidCallback onBookTicket;
  final VoidCallback onReadHistory;

  @override
  Widget build(BuildContext context) {
    const Color bgCream = Color(0xFFF7F3EA);
    const Color darkGreen = Color(0xFF3F5243);
    const Color goldAccent = Color(0xFFCBB26A);
    const Color cardBg = Colors.white;
    const Color textDark = Color(0xFF2C322B);
    const Color textMuted = Color(0xFF727A71);
    const Color borderLight = Color(0xFFE0E3DF);

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Lato'),
        primaryTextTheme: Theme.of(context).primaryTextTheme
            .apply(fontFamily: 'Lato'),
      ),
      child: Scaffold(
        backgroundColor: bgCream,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Logo
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
                          fontFamily: 'PlayfairDisplay',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: textDark,
                        ),
                      ),
                    ],
                  ),
                ),

                // Hero Section
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 12.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'JELAJAHI SEJARAH\nPERJUANGAN BANGSA DI\nMALANG',
                        style: TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          height: 1.25,
                          color: darkGreen,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Mari Mengenal Lebih Dekat Perjuangan Rakyat Malang Melawan Penjajahan',
                        style: TextStyle(
                          fontSize: 12,
                          color: textMuted,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: onBookTicket,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: darkGreen,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              'Pesan Tiket-mu Sekarang!',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 18),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Grid Statistik (Background Hijau Tua)
                Container(
                  color: darkGreen,
                  padding: const EdgeInsets.symmetric(
                    vertical: 24.0,
                    horizontal: 24.0,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatItem(
                              number: '1968',
                              label: 'TAHUN BERDIRI',
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.white24,
                          ),
                          Expanded(
                            child: _buildStatItem(
                              number: '+1.600',
                              label: 'KOLEKSI',
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Divider(color: Colors.white24, height: 1),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatItem(
                              number: '500RB+',
                              label: 'PENGUNJUNG / TAHUN',
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.white24,
                          ),
                          Expanded(
                            child: _buildStatItem(
                              number: 'Rp 10.000',
                              label: 'HARGA TIKET MASUK',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Kenapa Berkunjung
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'KENAPA BERKUNJUNG KE MUSEUM BRAWIJAYA',
                        style: TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: darkGreen,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureCard(
                        icon: Icons.inventory_2_outlined,
                        title: 'KOLEKSI OTENTIK',
                        description: 'Menyimpan peninggalan asli perang kemerdekaan, dari senjata, tank hingga artefak bersejarah.',
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureCard(
                        icon: Icons.location_on_outlined,
                        title: 'LOKASI STRATEGIS',
                        description: 'Terletak di pusat kota Malang di Jalan Ijen, mudah diakses kendaraan umum dan dekat destinasi wisata.',
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureCard(
                        icon: Icons.groups_outlined,
                        title: 'RAMAH KELUARGA & EDUKATIF',
                        description: 'Fasilitas yang merepresentasikan edukasi bagi seluruh kalangan, menambah wawasan kebangsaan.',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Card Sejarah Singkat
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
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
                            height: 300,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 300,
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
                                'TENTANG MUSEUM',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: goldAccent,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'SEJARAH SINGKAT',
                                style: TextStyle(
                                  fontFamily: 'PlayfairDisplay',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: darkGreen,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Museum Brawijaya diprakarsai oleh Brigjen TNI (Purn) Soerachman pada tahun 1962 dan diresmikan pada 4 Mei 1968. Museum ini didirikan sebagai sarana pembinaan mental kejuangan dan pelestarian nilai-nilai 45 bagi generasi penerus bangsa.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textMuted,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton(
                                onPressed: onReadHistory,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: textDark,
                                  side: const BorderSide(color: borderLight),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                ),
                                child: const Text(
                                  'Baca Sejarah Lengkap',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
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
      ),
    );
  }

  Widget _buildStatItem({required String number, required String label}) {
    return Column(
      children: [
        Text(
          number,
          style: const TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFCBB26A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F3EA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF3F5243)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3F5243),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF727A71),
                    height: 1.4,
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
