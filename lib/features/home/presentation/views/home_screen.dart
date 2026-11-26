import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:app/features/home/presentation/widgets/pengumuman_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onBookTicket,
    required this.onReadHistory,
    this.authViewModel,
  });

  final VoidCallback onBookTicket;
  final VoidCallback onReadHistory;
  final AuthViewModel? authViewModel;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final AuthViewModel _authViewModel;
  late final bool _ownsAuthViewModel;

  @override
  void initState() {
    super.initState();
    _ownsAuthViewModel = widget.authViewModel == null;
    _authViewModel = widget.authViewModel ?? AuthViewModel();
  }

  @override
  void dispose() {
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
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
                      // Logo Profil di Kanan Atas dengan Menu Popup (Reaktif via AuthViewModel)
                      ListenableBuilder(
                        listenable: _authViewModel,
                        builder: (context, _) {
                          final user = _authViewModel.currentUser;
                          final hasAvatar = user?.hasAvatar ?? false;
                          final initial = user?.initial ?? 'U';

                          return PopupMenuButton<String>(
                            tooltip: 'Menu Profil',
                            icon: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: hasAvatar ? darkGreen : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: hasAvatar ? goldAccent : borderLight,
                                  width: hasAvatar ? 1.5 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: hasAvatar
                                    ? Image.network(
                                        user!.avatarUrl!,
                                        width: 38,
                                        height: 38,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => Container(
                                          color: darkGreen,
                                          alignment: Alignment.center,
                                          child: Text(
                                            initial,
                                            style: const TextStyle(
                                              color: goldAccent,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Container(
                                        color: darkGreen,
                                        alignment: Alignment.center,
                                        child: Text(
                                          initial,
                                          style: const TextStyle(
                                            color: goldAccent,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            offset: const Offset(0, 45),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onSelected: (value) {
                              if (value == 'view_profile') {
                                context.go('/profil');
                              } else if (value == 'edit_profile') {
                                context.push('/edit-profile');
                              } else if (value == 'logout') {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    title: const Text(
                                      'Konfirmasi Logout',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    content: const Text(
                                      'Apakah Anda yakin ingin keluar dari akun?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text(
                                          'Batal',
                                          style: TextStyle(color: textMuted),
                                        ),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red.shade700,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        onPressed: () async {
                                          Navigator.pop(ctx);
                                          await _authViewModel.logout();
                                          if (context.mounted) {
                                            context.go('/login');
                                          }
                                        },
                                        child: const Text('Keluar'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                            itemBuilder: (context) {
                              return [
                                PopupMenuItem(
                                  enabled: false,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user?.nama ?? 'Pengunjung',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: textDark,
                                        ),
                                      ),
                                      Text(
                                        user?.email ?? 'Akun Pengguna',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: textMuted,
                                        ),
                                      ),
                                      const Divider(),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'view_profile',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.person_outline,
                                        size: 18,
                                        color: textDark,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'Profil Saya',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: textDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'edit_profile',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.edit_outlined,
                                        size: 18,
                                        color: textDark,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'Edit Profil',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: textDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'logout',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.logout,
                                        size: 18,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'Log Out',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ];
                            },
                          );
                        },
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
                        onPressed: widget.onBookTicket,
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

                // Kartu Utama Asisten AI Museum Brawijaya
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        context.push('/asisten-ai');
                      },
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF28372B), darkGreen, Color(0xFF566E59)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: goldAccent.withValues(alpha: 0.65),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: darkGreen.withValues(alpha: 0.2),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.auto_awesome, color: goldAccent, size: 30),
                            SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Asisten AI Museum Brawijaya',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'Tanya pemandu virtual cerdas seputar koleksi, sejarah Gerbong Maut, rute tur, dan e-tiket.',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: goldAccent,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
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
                          color: Colors.black.withValues(alpha: 0.03),
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
                                onPressed: widget.onReadHistory,
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

                const SizedBox(height: 28),

                // Pengumuman & Agenda Pameran (dikelola admin, dari database)
                const PengumumanSection(),

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
            color: Colors.black.withValues(alpha: 0.02),
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
