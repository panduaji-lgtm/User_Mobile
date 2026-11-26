import 'package:flutter/material.dart';

import 'package:app/features/home/data/repositories/informasi_service.dart';

/// Seksi "Pengumuman & Agenda Pameran" di halaman Beranda.
/// Data diambil langsung dari database melalui backend (dikelola admin).
class PengumumanSection extends StatefulWidget {
  const PengumumanSection({super.key, this.loader});

  /// Loader opsional (untuk pengujian)
  final Future<List<Pengumuman>> Function()? loader;

  @override
  State<PengumumanSection> createState() => _PengumumanSectionState();
}

class _PengumumanSectionState extends State<PengumumanSection> {
  static const Color _darkGreen = Color(0xFF3F5243);
  static const Color _gold = Color(0xFFCBB26A);
  static const Color _textMuted = Color(0xFF727A71);

  late Future<List<Pengumuman>> _future;
  int _tab = 0; // 0 = Semua, 1 = Agenda, 2 = Pengumuman

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Pengumuman>> _load() =>
      (widget.loader ?? InformasiService.getPengumumanAktif)();

  ({Color bg, Color fg, IconData icon}) _style(Pengumuman p) {
    if (p.isAgenda) {
      return (
        bg: const Color(0xFFEDE7F6),
        fg: const Color(0xFF5E35B1),
        icon: Icons.event_available_rounded,
      );
    }
    if (p.isPemeliharaan) {
      return (
        bg: const Color(0xFFFFF3E0),
        fg: const Color(0xFFE65100),
        icon: Icons.construction_rounded,
      );
    }
    return (
      bg: const Color(0xFFE8F5E9),
      fg: const Color(0xFF2E7D32),
      icon: Icons.campaign_rounded,
    );
  }

  void _showDetail(Pengumuman p) {
    final s = _style(p);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.75,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: s.bg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(s.icon, color: s.fg),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.category.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: s.fg,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          p.date,
                          style: const TextStyle(
                            fontSize: 11,
                            color: _textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                p.title,
                style: const TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _darkGreen,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                p.description.isNotEmpty
                    ? p.description
                    : 'Tidak ada keterangan tambahan.',
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.6,
                  color: Color(0xFF4A4F49),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 36,
                decoration: BoxDecoration(
                  color: _gold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KABAR MUSEUM',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _gold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      'Pengumuman & Agenda Pameran',
                      style: TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _darkGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildTab('Semua', 0),
              const SizedBox(width: 8),
              _buildTab('Agenda', 1),
              const SizedBox(width: 8),
              _buildTab('Pengumuman', 2),
            ],
          ),
          const SizedBox(height: 14),
          FutureBuilder<List<Pengumuman>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(color: _darkGreen),
                  ),
                );
              }
              if (snapshot.hasError) {
                return _buildEmpty(
                  Icons.cloud_off_rounded,
                  'Gagal memuat pengumuman. Silakan coba lagi nanti.',
                );
              }
              final all = snapshot.data ?? const <Pengumuman>[];
              final items = all.where((p) {
                if (_tab == 1) return p.isAgenda;
                if (_tab == 2) return !p.isAgenda;
                return true;
              }).toList();
              if (items.isEmpty) {
                return _buildEmpty(
                  Icons.event_note_rounded,
                  'Belum ada pengumuman atau agenda pameran saat ini.',
                );
              }
              return Column(
                children: [
                  for (final p in items) ...[
                    _buildCard(p),
                    const SizedBox(height: 12),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final selected = _tab == index;
    return GestureDetector(
      onTap: () => setState(() => _tab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? _darkGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _darkGreen : const Color(0xFFE0E3DF),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : _darkGreen,
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(IconData icon, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: _textMuted),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: _textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Pengumuman p) {
    final s = _style(p);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showDetail(p),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: s.fg,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(18),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: s.bg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(s.icon, color: s.fg, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: s.bg,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        p.category,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: s.fg,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.calendar_today_rounded,
                                    size: 11,
                                    color: _textMuted,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    p.date,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: _textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                p.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C322B),
                                ),
                              ),
                              if (p.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  p.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    height: 1.4,
                                    color: _textMuted,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 6),
                              const Text(
                                'Baca selengkapnya →',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: _darkGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

