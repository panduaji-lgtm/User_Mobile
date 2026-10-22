import 'package:flutter/material.dart';

// Model sederhana untuk satu ulasan
class _ReviewData {
  final String name;
  final String date;
  final int rating;
  final String comment;
  final String avatarInitial;
  final Color avatarColor;

  const _ReviewData({
    required this.name,
    required this.date,
    required this.rating,
    required this.comment,
    required this.avatarInitial,
    required this.avatarColor,
  });
}

class TentangScreen extends StatefulWidget {
  const TentangScreen({super.key});

  @override
  State<TentangScreen> createState() => _TentangScreenState();
}

class _TentangScreenState extends State<TentangScreen> {
  static const Color bgCream     = Color(0xFFF7F3EA);
  static const Color darkGreen   = Color(0xFF3F5243);
  static const Color goldAccent  = Color(0xFFCBB26A);
  static const Color cardBg      = Colors.white;
  static const Color textDark    = Color(0xFF2C322B);
  static const Color textMuted   = Color(0xFF727A71);
  static const Color borderLight = Color(0xFFE0E3DF);

  static const List<Color> _avatarColors = [
    Color(0xFF3F5243),
    Color(0xFF6B4C2A),
    Color(0xFF7A5C3C),
    Color(0xFF4A6670),
    Color(0xFF5E4266),
    Color(0xFF436B5A),
  ];

  final List<_ReviewData> _reviews = [
    const _ReviewData(
      name: 'Budi Santoso',
      date: '12 Oktober 2025',
      rating: 5,
      comment: 'Museum yang sangat edukatif! Koleksinya lengkap dan terjaga dengan baik. Sangat direkomendasikan untuk kunjungan keluarga dan pelajar.',
      avatarInitial: 'B',
      avatarColor: Color(0xFF3F5243),
    ),
    const _ReviewData(
      name: 'Siti Rahayu',
      date: '5 September 2025',
      rating: 5,
      comment: 'Tempat bersejarah yang wajib dikunjungi. Gerbong Maut dan Diorama Pertempuran sangat mengesankan. Staf ramah dan informatif.',
      avatarInitial: 'S',
      avatarColor: Color(0xFF6B4C2A),
    ),
    const _ReviewData(
      name: 'Ahmad Fauzi',
      date: '20 Agustus 2025',
      rating: 4,
      comment: 'Koleksinya luar biasa dan penuh nilai sejarah. Suasana museum sangat tenang dan nyaman untuk belajar sejarah perjuangan bangsa.',
      avatarInitial: 'A',
      avatarColor: Color(0xFF7A5C3C),
    ),
  ];

  final _formKey           = GlobalKey<FormState>();
  final _nameController    = TextEditingController();
  final _commentController = TextEditingController();
  int  _selectedRating = 0;
  int  _hoverRating    = 0;
  bool _isSubmitting   = false;
  bool _showForm       = false;

  @override
  void dispose() {
    _nameController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  double get _averageRating {
    if (_reviews.isEmpty) return 0;
    return _reviews.fold(0, (sum, r) => sum + r.rating) / _reviews.length;
  }

  double _ratingFraction(int star) {
    if (_reviews.isEmpty) return 0;
    final count = _reviews.where((r) => r.rating == star).length;
    return count / _reviews.length;
  }

  String _formattedToday() {
    const monthNames = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    final now = DateTime.now();
    return '${now.day} ${monthNames[now.month]} ${now.year}';
  }

  void _submitReview() async {
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
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 600));

    final name    = _nameController.text.trim();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final color   = _avatarColors[_reviews.length % _avatarColors.length];

    setState(() {
      _reviews.insert(
        0,
        _ReviewData(
          name:          name,
          date:          _formattedToday(),
          rating:        _selectedRating,
          comment:       _commentController.text.trim(),
          avatarInitial: initial,
          avatarColor:   color,
        ),
      );
      _nameController.clear();
      _commentController.clear();
      _selectedRating = 0;
      _hoverRating    = 0;
      _isSubmitting   = false;
      _showForm       = false;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Ulasan berhasil dikirim! Terima kasih'),
          ],
        ),
        backgroundColor: darkGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Logo
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: const BoxDecoration(color: darkGreen, shape: BoxShape.circle),
                      child: const Icon(Icons.account_balance, color: goldAccent, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'MUSEUM BRAWIJAYA',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: textDark),
                    ),
                  ],
                ),
              ),

              // 2. Title & Badge
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFECE6),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: borderLight),
                      ),
                      child: const Text(
                        'TENTANG KAMI',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: goldAccent, letterSpacing: 0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tentang Museum Brawijaya',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textDark),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Card Sejarah
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderLight),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        child: Image.asset(
                          'assets/images/museum_brawijaya.jpg',
                          height: 180, width: double.infinity,
                          fit: BoxFit.cover,
                          alignment: const Alignment(0, -0.2),
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 180, color: Colors.grey.shade300,
                            child: const Icon(Icons.museum, size: 50, color: Colors.grey),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Sejarah Berdirinya', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textDark)),
                            SizedBox(height: 8),
                            Text(
                              'Dibangun atas prakarsa Brigjen TNI (Purn.) Soerachman, Pangdam VIII Brawijaya (1959-1962). Pembangunan dimulai tahun 1967 dan secara resmi diresmikan pada 4 Mei 1968 oleh Kolonel Dr. Soewondo.\n\nMuseum ini didirikan dengan tujuan luhur mengenang dan mewariskan semangat perjuangan Tentara Keamanan Rakyat (TKR) bersama seluruh rakyat pejuang Jawa Timur dalam mempertahankan kemerdekaan Republik Indonesia.',
                              style: TextStyle(fontSize: 11.5, color: textMuted, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 4. Timeline
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: borderLight)),
                  child: Column(
                    children: [
                      const Text('Perjalanan Museum', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textDark)),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTimelineItem('1962', 'Gagasan Awal', true),
                          _buildTimelineLine(),
                          _buildTimelineItem('1967', 'Pembangunan\nDimulai', true),
                          _buildTimelineLine(),
                          _buildTimelineItem('1968', 'Diresmikan', true),
                          _buildTimelineLine(),
                          _buildTimelineItem('Sekarang', 'Terus Benah', false, isLast: true),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 5. Visi
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: borderLight)),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Visi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textDark)),
                      SizedBox(height: 8),
                      Text(
                        'Menjadi pusat edukasi dan rekreasi sejarah perjuangan bangsa yang inspiratif, inklusif, dan relevan bagi generasi muda Jawa Timur dan Indonesia.',
                        style: TextStyle(fontSize: 11.5, color: textMuted, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 6. Misi
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: borderLight)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Misi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textDark)),
                      const SizedBox(height: 12),
                      _buildBulletMission('Melestarikan dan merawat koleksi benda peninggalan bersejarah.'),
                      const SizedBox(height: 8),
                      _buildBulletMission("Mengedukasi generasi muda tentang nilai-nilai patriotisme dan perjuangan '45."),
                      const SizedBox(height: 8),
                      _buildBulletMission('Meningkatkan aksesibilitas informasi digital dan fasilitas kunjungan.'),
                      const SizedBox(height: 8),
                      _buildBulletMission('Menjaga keutuhan narasi sejarah perjuangan kemerdekaan Jawa Timur.'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 7. Galeri Museum
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Galeri Museum', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
                    Text('6 FOTO PILIHAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: goldAccent, letterSpacing: 0.8)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: GridView.count(
                  crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
                  childAspectRatio: 1.3, shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildGalleryCard('assets/images/collection/menu_gerbong_maut.png', 'Gerbong Maut'),
                    _buildGalleryCard('assets/images/collection/peta_operasi_militer.png', 'Peta Operasi Militer'),
                    _buildGalleryCard('assets/images/collection/diorama_pertempuran.png', 'Diorama Pertempuran'),
                    _buildGalleryCard('assets/images/museum_brawijaya.jpg', 'Museum Brawijaya'),
                    _buildGalleryCard('assets/images/collection/menu_mobil_dinas_letkol.png', 'Mobil Dinas Letkol'),
                    _buildGalleryCard('assets/images/collection/menu_perahu_segigir.png', 'Perahu Segigir'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 8. Ulasan Pengunjung
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Ulasan Pengunjung', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
                    Text('RATING & KESAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: goldAccent, letterSpacing: 0.8)),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Rating Summary Card (dinamis)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderLight),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: Row(
                    children: [
                      Column(
                        children: [
                          Text(
                            _averageRating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: textDark, height: 1),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: List.generate(5, (i) {
                              final full = i < _averageRating.floor();
                              final half = !full && (i < _averageRating && _averageRating - i >= 0.5);
                              return Icon(
                                full ? Icons.star : (half ? Icons.star_half : Icons.star_border),
                                color: goldAccent, size: 14,
                              );
                            }),
                          ),
                          const SizedBox(height: 4),
                          Text('${_reviews.length} ulasan', style: const TextStyle(fontSize: 10, color: textMuted)),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          children: List.generate(5, (i) {
                            final star = 5 - i;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: _buildRatingBar(star, _ratingFraction(star)),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Tombol Tulis Ulasan
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: GestureDetector(
                  onTap: () => setState(() => _showForm = !_showForm),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _showForm ? const Color(0xFFEFECE6) : darkGreen,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _showForm ? borderLight : darkGreen),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _showForm ? Icons.close : Icons.edit_note_rounded,
                          color: _showForm ? textMuted : Colors.white, size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _showForm ? 'Batalkan' : 'Tulis Ulasan Anda',
                          style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600,
                            color: _showForm ? textMuted : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Form Ulasan (animasi slide)
              AnimatedSize(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                child: _showForm ? _buildReviewForm() : const SizedBox.shrink(),
              ),

              const SizedBox(height: 16),

              // Daftar Ulasan
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: _reviews.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildReviewCard(
                      name: r.name, date: r.date, rating: r.rating,
                      comment: r.comment, avatarInitial: r.avatarInitial, avatarColor: r.avatarColor,
                    ),
                  )).toList(),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ── Form Ulasan ─────────────────────────────
  Widget _buildReviewForm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderLight),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.rate_review_outlined, color: darkGreen, size: 18),
                  SizedBox(width: 8),
                  Text('Bagikan Pengalaman Anda', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textDark)),
                ],
              ),
              const SizedBox(height: 16),

              // Pilih Rating Bintang
              const Text('Rating', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textMuted)),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (i) {
                  final starIndex = i + 1;
                  final filled = starIndex <= (_hoverRating > 0 ? _hoverRating : _selectedRating);
                  return GestureDetector(
                    onTap: () => setState(() => _selectedRating = starIndex),
                    child: MouseRegion(
                      onEnter: (_) => setState(() => _hoverRating = starIndex),
                      onExit:  (_) => setState(() => _hoverRating = 0),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 150),
                        child: Icon(
                          filled ? Icons.star_rounded : Icons.star_border_rounded,
                          key: ValueKey('$starIndex-$filled'),
                          color: filled ? goldAccent : borderLight,
                          size: 36,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              if (_selectedRating > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _ratingLabel(_selectedRating),
                    style: const TextStyle(fontSize: 11, color: goldAccent, fontWeight: FontWeight.w600),
                  ),
                ),
              const SizedBox(height: 16),

              // Input Nama
              const Text('Nama Anda', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textMuted)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                style: const TextStyle(fontSize: 13, color: textDark),
                decoration: _inputDecoration('Masukkan nama Anda', Icons.person_outline),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Nama tidak boleh kosong';
                  if (v.trim().length < 2) return 'Nama minimal 2 karakter';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Input Komentar
              const Text('Ulasan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textMuted)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _commentController,
                maxLines: 4,
                style: const TextStyle(fontSize: 13, color: textDark),
                decoration: _inputDecoration('Ceritakan pengalaman kunjungan Anda...', null),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Ulasan tidak boleh kosong';
                  if (v.trim().length < 10) return 'Ulasan minimal 10 karakter';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Tombol Kirim
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkGreen,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF8A9A8B),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Kirim Ulasan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData? prefixIcon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFA0A7A0)),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: textMuted, size: 18) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: const Color(0xFFF7F5F0),
      border:             OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: borderLight)),
      enabledBorder:      OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: borderLight)),
      focusedBorder:      OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: darkGreen, width: 1.5)),
      errorBorder:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.2)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
    );
  }

  String _ratingLabel(int rating) {
    switch (rating) {
      case 1: return 'Kurang Memuaskan';
      case 2: return 'Cukup';
      case 3: return 'Lumayan';
      case 4: return 'Bagus';
      case 5: return 'Sangat Memuaskan!';
      default: return '';
    }
  }

  Widget _buildRatingBar(int star, double fraction) {
    return Row(
      children: [
        Text('$star', style: const TextStyle(fontSize: 10, color: textMuted)),
        const SizedBox(width: 4),
        const Icon(Icons.star, color: goldAccent, size: 10),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction, minHeight: 6,
              backgroundColor: borderLight,
              valueColor: const AlwaysStoppedAnimation<Color>(goldAccent),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard({
    required String name, required String date, required int rating,
    required String comment, required String avatarInitial, required Color avatarColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderLight),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18, backgroundColor: avatarColor,
                child: Text(avatarInitial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
                    Text(date, style: const TextStyle(fontSize: 10, color: textMuted)),
                  ],
                ),
              ),
              Row(children: List.generate(rating, (_) => const Icon(Icons.star, color: goldAccent, size: 13))),
            ],
          ),
          const SizedBox(height: 10),
          Text(comment, style: const TextStyle(fontSize: 11.5, color: textMuted, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String year, String label, bool isActive, {bool isLast = false}) {
    return Column(
      children: [
        Container(
          width: 22, height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isLast ? textDark : goldAccent,
            border: Border.all(color: Colors.white, width: 3),
          ),
        ),
        const SizedBox(height: 6),
        Text(year, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textDark)),
        const SizedBox(height: 2),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 8.5, color: textMuted, height: 1.2)),
      ],
    );
  }

  Widget _buildTimelineLine() {
    return Expanded(child: Container(height: 2, color: borderLight, margin: const EdgeInsets.only(bottom: 25)));
  }

  Widget _buildBulletMission(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(padding: EdgeInsets.only(top: 5.0), child: Icon(Icons.circle, size: 6, color: goldAccent)),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 11.5, color: textMuted, height: 1.4))),
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
            imagePath, fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey.shade300,
              child: const Icon(Icons.image_not_supported, color: Colors.grey),
            ),
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter, end: Alignment.topCenter,
                  colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
                ),
              ),
              child: Text(caption, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
