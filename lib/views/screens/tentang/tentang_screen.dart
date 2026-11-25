import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:app/models/ulasan_models.dart';
import 'package:app/viewmodels/auth_viewmodel.dart';
import 'package:app/viewmodels/ulasan_viewmodel.dart';

typedef UlasanLoader = Future<({List<UlasanItem> items, UlasanStats stats})> Function();
typedef UlasanSubmitter = Future<UlasanItem> Function({
  required String nama,
  required int rating,
  required String comment,
  String category,
});

class _ReviewData {
  final int id;
  final String name;
  final String date;
  final int rating;
  final String comment;
  final String reply;
  final String replyDate;
  final String avatarInitial;
  final Color avatarColor;

  const _ReviewData({
    required this.id,
    required this.name,
    required this.date,
    required this.rating,
    required this.comment,
    this.reply = '',
    this.replyDate = '',
    required this.avatarInitial,
    required this.avatarColor,
  });
}

class TentangScreen extends StatefulWidget {
  final UlasanLoader? reviewsLoader;
  final UlasanSubmitter? reviewSubmitter;
  final UlasanViewModel? viewModel;
  final AuthViewModel? authViewModel;

  const TentangScreen({
    super.key,
    this.reviewsLoader,
    this.reviewSubmitter,
    this.viewModel,
    this.authViewModel,
  });

  @override
  State<TentangScreen> createState() => _TentangScreenState();
}

class _TentangScreenState extends State<TentangScreen> {
  static const Color bgCream = Color(0xFFF7F3EA);
  static const Color darkGreen = Color(0xFF3F5243);
  static const Color goldAccent = Color(0xFFCBB26A);
  static const Color cardBg = Colors.white;
  static const Color textDark = Color(0xFF2C322B);
  static const Color textMuted = Color(0xFF727A71);
  static const Color borderLight = Color(0xFFE0E3DF);

  static const List<Color> _avatarColors = [
    Color(0xFF3F5243),
    Color(0xFF6B4C2A),
    Color(0xFF7A5C3C),
    Color(0xFF4A6670),
    Color(0xFF5E4266),
    Color(0xFF436B5A),
  ];

  static const List<_ReviewData> _fallbackReviews = [
    _ReviewData(
      id: -1,
      name: 'Budi Santoso',
      date: '12 Okt 2025',
      rating: 5,
      comment:
          'Museum yang sangat edukatif! Koleksinya lengkap dan terjaga dengan baik. Sangat direkomendasikan untuk kunjungan keluarga dan pelajar.',
      avatarInitial: 'B',
      avatarColor: Color(0xFF3F5243),
    ),
    _ReviewData(
      id: -2,
      name: 'Siti Rahayu',
      date: '5 Sep 2025',
      rating: 5,
      comment:
          'Tempat bersejarah yang wajib dikunjungi. Gerbong Maut dan Diorama Pertempuran sangat mengesankan. Staf ramah dan informatif.',
      avatarInitial: 'S',
      avatarColor: Color(0xFF6B4C2A),
    ),
  ];

  late final UlasanViewModel _viewModel;
  late final bool _ownsViewModel;
  late final AuthViewModel _authViewModel;
  late final bool _ownsAuthViewModel;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _commentController = TextEditingController();
  int _selectedRating = 0;
  bool _showForm = false;

  @override
  void initState() {
    super.initState();
    _ownsViewModel = widget.viewModel == null;
    _viewModel = widget.viewModel ?? UlasanViewModel();
    _ownsAuthViewModel = widget.authViewModel == null;
    _authViewModel = widget.authViewModel ?? AuthViewModel();

    final currentUserName = _authViewModel.currentUser?.nama.trim() ?? '';
    if (currentUserName.isNotEmpty) {
      _nameController.text = currentUserName;
    }
    _fetchReviewsFromBackend();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _commentController.dispose();
    if (_ownsViewModel) {
      _viewModel.dispose();
    }
    if (_ownsAuthViewModel) {
      _authViewModel.dispose();
    }
    super.dispose();
  }

  String _formatDate(String rawDate) {
    final trimmed = rawDate.trim();
    if (trimmed.isEmpty) return 'Baru saja';
    final parsed = DateTime.tryParse(trimmed);
    if (parsed == null) {
      return trimmed.length >= 10 ? trimmed.substring(0, 10) : trimmed;
    }
    final local = parsed.toLocal();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${local.day} ${months[local.month - 1]} ${local.year}';
  }

  Color _parseColor(String hex, int fallbackIndex) {
    final cleaned = hex.trim().replaceFirst('#', '');
    if (cleaned.length == 6) {
      final value = int.tryParse('FF$cleaned', radix: 16);
      if (value != null) return Color(value);
    }
    return _avatarColors[fallbackIndex % _avatarColors.length];
  }

  _ReviewData _mapItem(UlasanItem item, int index) {
    final initial = item.avatarInitial.isNotEmpty
        ? item.avatarInitial
        : (item.nama.isNotEmpty ? item.nama[0].toUpperCase() : '?');
    return _ReviewData(
      id: item.id,
      name: item.nama,
      date: _formatDate(item.createdAt),
      rating: item.rating,
      comment: item.comment,
      reply: item.reply,
      replyDate: item.replyDate,
      avatarInitial: initial,
      avatarColor: _parseColor(item.avatarColor, index),
    );
  }

  List<_ReviewData> get _displayReviews {
    if (_viewModel.items.isNotEmpty) {
      return [
        for (var i = 0; i < _viewModel.items.length; i++)
          _mapItem(_viewModel.items[i], i),
      ];
    }
    if (_viewModel.usingFallback || _viewModel.isLoading) {
      return _fallbackReviews;
    }
    return const [];
  }

  Future<void> _fetchReviewsFromBackend({bool silent = false}) async {
    try {
      await _viewModel.loadReviews(
        silent: silent,
        loaderOverride: widget.reviewsLoader,
      );
    } catch (_) {
      // Status fallback dan pesan error sudah ditangani di UlasanViewModel
    }
  }

  double get _averageRating {
    final usingServerStats = !_viewModel.usingFallback &&
        !(_viewModel.items.isEmpty && _viewModel.isLoading);
    if (usingServerStats) {
      return _viewModel.stats.total > 0 ? _viewModel.stats.averageRating : 0;
    }
    final list = _displayReviews;
    if (list.isEmpty) return 0;
    return list.fold<int>(0, (sum, r) => sum + r.rating) / list.length;
  }

  int get _totalReviewCount {
    final usingServerStats = !_viewModel.usingFallback &&
        !(_viewModel.items.isEmpty && _viewModel.isLoading);
    if (usingServerStats) {
      return _viewModel.stats.total;
    }
    return _displayReviews.length;
  }

  String get _ratingCaption {
    return switch (_selectedRating) {
      1 => '1 / 5 - Perlu Perbaikan',
      2 => '2 / 5 - Cukup',
      3 => '3 / 5 - Baik',
      4 => '4 / 5 - Sangat Baik',
      5 => '5 / 5 - Luar Biasa',
      _ => 'Ketuk bintang untuk memilih rating',
    };
  }

  Future<void> _submitReview() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pilih bintang rating terlebih dahulu'),
          backgroundColor: darkGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    try {
      await _viewModel.submitReview(
        nama: _nameController.text.trim(),
        rating: _selectedRating,
        comment: _commentController.text.trim(),
        submitterOverride: widget.reviewSubmitter,
      );
      if (!mounted) return;

      setState(() {
        _commentController.clear();
        _selectedRating = 0;
        _showForm = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(child: Text('Ulasan berhasil dikirim dan tersimpan!')),
            ],
          ),
          backgroundColor: darkGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      // Sinkronkan ulang dengan daftar & statistik terbaru dari backend
      await _fetchReviewsFromBackend(silent: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal mengirim ulasan: ${e.toString().replaceFirst("Exception: ", "")}',
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Widget _buildGalleryCard(String assetPath, String title) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              assetPath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFFEFECE6),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_outlined, size: 32, color: textMuted),
                    SizedBox(height: 4),
                    Text(
                      'Foto Pilihan',
                      style: TextStyle(fontSize: 9, color: textMuted),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.75),
                    ],
                  ),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletMission(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '• ',
          style: TextStyle(
            color: goldAccent,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 11.5, color: textMuted, height: 1.4),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final reviews = _displayReviews;
        final isLoadingReviews = _viewModel.isLoading;
        final usingFallbackReviews = _viewModel.usingFallback;
        final reviewsError = _viewModel.errorMessage;
        final isSubmitting = _viewModel.isSubmitting;

        return Scaffold(
          backgroundColor: bgCream,
          body: SafeArea(
            child: RefreshIndicator(
              color: darkGreen,
              onRefresh: () => _fetchReviewsFromBackend(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                      const Expanded(
                        child: Text(
                          'MUSEUM BRAWIJAYA',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Title & Badge
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

                // Card Sejarah (Dengan Gambar Asli Museum)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderLight),
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
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              height: 180,
                              width: double.infinity,
                              color: darkGreen,
                              child: const Center(
                                child: Icon(
                                  Icons.museum,
                                  size: 60,
                                  color: goldAccent,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sejarah Berdirinya',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Dibangun atas prakarsa Brigjen TNI (Purn.) Soerachman, Pangdam VIII Brawijaya (1959-1962). Pembangunan dimulai tahun 1967 dan secara resmi diresmikan pada 4 Mei 1968 oleh Kolonel Dr. Soewondo.\n\nMuseum ini didirikan dengan tujuan luhur mengenang dan mewariskan semangat perjuangan Tentara Keamanan Rakyat (TKR) bersama seluruh rakyat pejuang Jawa Timur dalam mempertahankan kemerdekaan Republik Indonesia.',
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

                // Visi
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
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Visi',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
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

                // Misi
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
                          "Mengedukasi generasi muda tentang nilai-nilai patriotisme dan perjuangan '45.",
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
                const SizedBox(height: 16),

                // Lokasi & Peta
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
                        const Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 20,
                              color: darkGreen,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Lokasi & Rute Museum',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Jl. Ijen No.25A, Gading Kasri, Kec. Klojen, Kota Malang, Jawa Timur 65115',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: textMuted,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: SizedBox(
                            width: double.infinity,
                            height: 180,
                            child: FlutterMap(
                              options: const MapOptions(
                                initialCenter: LatLng(-7.9719938, 112.6209786),
                                initialZoom: 16,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName:
                                      'com.example.museum_brawijaya',
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: const LatLng(
                                        -7.9719938,
                                        112.6209786,
                                      ),
                                      width: 44,
                                      height: 44,
                                      alignment: Alignment.bottomCenter,
                                      child: const Icon(
                                        Icons.location_pin,
                                        size: 44,
                                        color: Color(0xFFB63D32),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final uri = Uri.https(
                              'www.google.com',
                              '/maps/search/',
                              {'api': '1', 'query': 'Museum Brawijaya Malang'},
                            );
                            bool launched = false;
                            try {
                              launched = await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            } catch (_) {
                              launched = false;
                            }
                            if (!launched) {
                              try {
                                launched = await launchUrl(
                                  uri,
                                  mode: LaunchMode.platformDefault,
                                );
                              } catch (_) {
                                launched = false;
                              }
                            }
                            if (!launched && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Tidak dapat membuka Google Maps di perangkat ini.',
                                  ),
                                  backgroundColor: Colors.red.shade700,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.directions, size: 18),
                          label: const Text(
                            'Buka Lokasi di Google Maps',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: darkGreen,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 42),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Galeri Museum
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Galeri Museum',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
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
                const SizedBox(height: 24),

                // Header Ulasan Pengunjung
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Ulasan Pengunjung',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'RATING & KESAN',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: goldAccent,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            tooltip: 'Muat ulang ulasan',
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(4),
                            onPressed: isLoadingReviews
                                ? null
                                : () => _fetchReviewsFromBackend(),
                            icon: Icon(
                              Icons.refresh,
                              size: 16,
                              color: isLoadingReviews ? textMuted : darkGreen,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                if (usingFallbackReviews && reviewsError != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: goldAccent.withValues(alpha: 0.7),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.cloud_off_outlined,
                            size: 18,
                            color: Color(0xFF8A6D1C),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Belum terhubung ke server ulasan. Menampilkan ulasan contoh.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6B5314),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: isLoadingReviews
                                ? null
                                : () => _fetchReviewsFromBackend(),
                            style: TextButton.styleFrom(
                              foregroundColor: darkGreen,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: const Size(0, 30),
                            ),
                            child: const Text(
                              'Muat Ulang',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Rating Summary & Form Tulis Ulasan
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _averageRating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: textDark,
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: List.generate(5, (i) {
                                      return Icon(
                                        i < _averageRating.round()
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: goldAccent,
                                        size: 14,
                                      );
                                    }),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$_totalReviewCount ulasan',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _showForm = !_showForm;
                                  if (_showForm &&
                                      _nameController.text.trim().isEmpty) {
                                    final userName =
                                        _authViewModel.currentUser?.nama
                                                .trim() ??
                                            '';
                                    if (userName.isNotEmpty) {
                                      _nameController.text = userName;
                                    }
                                  }
                                });
                              },
                              icon: Icon(
                                _showForm ? Icons.close : Icons.rate_review,
                                size: 16,
                              ),
                              label: Text(
                                _showForm ? 'Tutup' : 'Tulis Ulasan',
                                style: const TextStyle(fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: darkGreen,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_showForm) ...[
                          const Divider(height: 24),
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Bintang Rating:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: textMuted,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: List.generate(5, (index) {
                                    final starVal = index + 1;
                                    return IconButton(
                                      key: ValueKey('rating-star-$starVal'),
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      onPressed: () => setState(
                                        () => _selectedRating = starVal,
                                      ),
                                      icon: Icon(
                                        starVal <= _selectedRating
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: goldAccent,
                                        size: 28,
                                      ),
                                    );
                                  }),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _ratingCaption,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _selectedRating > 0
                                        ? darkGreen
                                        : textMuted,
                                    fontWeight: _selectedRating > 0
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: 'Nama Lengkap',
                                    hintText: 'Masukkan nama Anda',
                                    labelStyle: const TextStyle(fontSize: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ),
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                          ? 'Nama wajib diisi'
                                          : null,
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _commentController,
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    labelText: 'Kesan dan Pesan / Ulasan',
                                    hintText:
                                        'Ceritakan pengalaman kunjungan Anda...',
                                    helperText:
                                        'Minimal ${UlasanViewModel.minCommentLength} karakter',
                                    helperStyle: const TextStyle(
                                      fontSize: 10,
                                      color: textMuted,
                                    ),
                                    labelStyle: const TextStyle(fontSize: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    contentPadding: const EdgeInsets.all(12),
                                  ),
                                  validator: (v) {
                                    final text = v?.trim() ?? '';
                                    if (text.isEmpty) {
                                      return 'Ulasan wajib diisi';
                                    }
                                    if (text.length <
                                        UlasanViewModel.minCommentLength) {
                                      return 'Ulasan minimal ${UlasanViewModel.minCommentLength} karakter';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed:
                                        isSubmitting ? null : _submitReview,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: darkGreen,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    child: isSubmitting
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text(
                                            'Kirim Ulasan',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                if (isLoadingReviews)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
                    child: LinearProgressIndicator(
                      color: darkGreen,
                      backgroundColor: Color(0xFFE6DDCB),
                      minHeight: 3,
                    ),
                  ),

                // Daftar List Ulasan dari Database MySQL
                if (reviews.isEmpty && !isLoadingReviews)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderLight),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.rate_review_outlined,
                            size: 32,
                            color: textMuted,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Belum ada ulasan pengunjung',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: textDark,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Jadilah yang pertama membagikan pengalaman berkunjung ke Museum Brawijaya.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, color: textMuted),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: reviews.length,
                    itemBuilder: (context, index) {
                      final review = reviews[index];
                      return Padding(
                        key: ValueKey('review-${review.id}-$index'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 6.0,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: borderLight),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: review.avatarColor,
                                    child: Text(
                                      review.avatarInitial,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          review.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: textDark,
                                          ),
                                        ),
                                        Text(
                                          review.date,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: List.generate(5, (i) {
                                      return Icon(
                                        i < review.rating
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: goldAccent,
                                        size: 12,
                                      );
                                    }),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                review.comment,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: textDark,
                                  height: 1.4,
                                ),
                              ),
                              if (review.reply.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF7F3EA),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        review.replyDate.isNotEmpty
                                            ? 'Admin Museum Brawijaya • ${review.replyDate}'
                                            : 'Admin Museum Brawijaya:',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: darkGreen,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        review.reply,
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          color: textDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
      },
    );
  }
}
