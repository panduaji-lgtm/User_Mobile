import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:app/core/network/api_client.dart';
import 'package:app/models/ai_chat_models.dart';
import 'package:app/models/auth_models.dart';
import 'package:app/models/koleksi_model.dart';
import 'package:app/models/tiket_models.dart';
import 'package:app/viewmodels/ai_chat_viewmodel.dart';
import 'package:app/viewmodels/auth_viewmodel.dart';
import 'package:app/viewmodels/koleksi_viewmodel.dart';
import 'package:app/viewmodels/tiket_viewmodel.dart';

// ─── TEMA WARNA RESMI MUSEUM BRAWIJAYA ─────────────────────────────────────────
const Color _bgCream = Color(0xFFF7F3EA);
const Color _darkGreen = Color(0xFF3F5243);
const Color _goldAccent = Color(0xFFCBB26A);
const Color _cardBg = Colors.white;
const Color _textDark = Color(0xFF2C322B);
const Color _textMuted = Color(0xFF727A71);
const Color _borderLight = Color(0xFFE0E3DF);

const int _maxAvatarSizeBytes = 5 * 1024 * 1024; // 5 MB

/// Deteksi & validasi format gambar asli (JPG, PNG, WebP) menggunakan magic bytes.
/// Memastikan dukungan penuh pada Flutter Web & Mobile meski ekstensi file tidak tersedia.
String? _detectValidImageMime(Uint8List bytes, {String? fallbackMime, String? fileName}) {
  if (bytes.lengthInBytes < 12) return null;

  // JPEG: FF D8 FF
  if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
    return 'image/jpeg';
  }

  // PNG: 89 50 4E 47 0D 0A 1A 0A
  if (bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47 &&
      bytes[4] == 0x0D &&
      bytes[5] == 0x0A &&
      bytes[6] == 0x1A &&
      bytes[7] == 0x0A) {
    return 'image/png';
  }

  // WebP: RIFF....WEBP
  if (bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return 'image/webp';
  }

  // Fallback jika browser/platform sudah mengonfirmasi MIME yang diizinkan
  final normalizedMime = fallbackMime?.split(';').first.trim().toLowerCase();
  if (normalizedMime == 'image/jpeg' || normalizedMime == 'image/jpg') {
    return 'image/jpeg';
  }
  if (normalizedMime == 'image/png' || normalizedMime == 'image/webp') {
    return normalizedMime;
  }

  final lowerName = fileName?.toLowerCase() ?? '';
  if (lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg')) return 'image/jpeg';
  if (lowerName.endsWith('.png')) return 'image/png';
  if (lowerName.endsWith('.webp')) return 'image/webp';

  return null;
}

String _formatRupiah(int amount) {
  return NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(amount);
}

String _formatShortDate(String? rawIso) {
  if (rawIso == null || rawIso.trim().isEmpty) return '';
  final parsed = DateTime.tryParse(rawIso.trim());
  if (parsed == null) return '';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];
  return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
}

/// Widget avatar bundar dengan dukungan URL Vercel Blob, indikator loading,
/// tombol kamera ganti foto, dan fallback otomatis ke inisial nama.
class _UserAvatarWidget extends StatelessWidget {
  final UserModel? user;
  final double size;
  final bool isUploading;
  final VoidCallback? onChangePhoto;

  const _UserAvatarWidget({
    required this.user,
    this.size = 78,
    this.isUploading = false,
    this.onChangePhoto,
  });

  @override
  Widget build(BuildContext context) {
    final hasAvatar = user?.hasAvatar ?? false;
    final initial = user?.initial ?? 'U';

    Widget fallbackInitial() => Center(
          child: Text(
            initial,
            style: TextStyle(
              fontSize: size * 0.38,
              fontWeight: FontWeight.bold,
              color: _goldAccent,
              fontFamily: 'PlayfairDisplay',
            ),
          ),
        );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: isUploading ? null : onChangePhoto,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: _darkGreen,
              shape: BoxShape.circle,
              border: Border.all(color: _goldAccent, width: 2.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipOval(
              child: hasAvatar
                  ? Image.network(
                      user!.avatarUrl!,
                      key: ValueKey(user!.avatarUrl),
                      width: size,
                      height: size,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => fallbackInitial(),
                      loadingBuilder: (ctx, child, progress) {
                        if (progress == null) return child;
                        return Center(
                          child: SizedBox(
                            width: size * 0.3,
                            height: size * 0.3,
                            child: const CircularProgressIndicator(
                              color: _goldAccent,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      },
                    )
                  : fallbackInitial(),
            ),
          ),
        ),
        if (isUploading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.48),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.2,
                  ),
                ),
              ),
            ),
          ),
        if (onChangePhoto != null)
          Positioned(
            bottom: -2,
            right: -2,
            child: Tooltip(
              message: 'Ganti Foto Profil',
              child: Material(
                color: _goldAccent,
                shape: const CircleBorder(),
                elevation: 2,
                child: InkWell(
                  onTap: isUploading ? null : onChangePhoto,
                  customBorder: const CircleBorder(),
                  child: Container(
                    padding: const EdgeInsets.all(6.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Helper memilih gambar (Web & Mobile), validasi format & ukuran, lalu unggah ke Vercel Blob via AuthViewModel.
Future<void> _showAvatarActionSheet({
  required BuildContext context,
  required AuthViewModel authViewModel,
}) async {
  if (authViewModel.isUploadingAvatar) return;
  final user = authViewModel.currentUser;
  final hasAvatar = user?.hasAvatar ?? false;

  Future<void> pickAndUpload(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();
      if (bytes.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berkas gambar kosong atau gagal dibaca.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (bytes.lengthInBytes > _maxAvatarSizeBytes) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ukuran foto terlalu besar. Maksimal 5 MB.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final detectedMime = _detectValidImageMime(
        bytes,
        fallbackMime: pickedFile.mimeType,
        fileName: pickedFile.name,
      );
      if (detectedMime == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Format gambar tidak didukung. Gunakan JPG, PNG, atau WebP.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await authViewModel.uploadAvatar(
        imageBytes: bytes,
        filename: pickedFile.name.isNotEmpty ? pickedFile.name : 'avatar.jpg',
        mimeType: detectedMime,
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto profil berhasil diperbarui & tersimpan!'),
          backgroundColor: _darkGreen,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      final msg = e is ApiException
          ? e.message
          : e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg.isNotEmpty ? msg : 'Gagal mengunggah foto profil.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> removeAvatar() async {
    try {
      await authViewModel.removeAvatar();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto profil dihapus. Kembali menggunakan inisial nama.'),
          backgroundColor: _darkGreen,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      final msg = e is ApiException
          ? e.message
          : e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
      );
    }
  }

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: _borderLight,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Ubah Foto Profil',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _textDark,
                      fontFamily: 'Lato',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: _textMuted, size: 20),
                  onPressed: () => Navigator.pop(sheetContext),
                ),
              ],
            ),
            const Text(
              'Format yang didukung: JPG, PNG, atau WebP (maksimal 5 MB). Foto tersimpan aman di cloud storage.',
              style: TextStyle(fontSize: 12, color: _textMuted, fontFamily: 'Lato'),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _darkGreen.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library_outlined, color: _darkGreen, size: 22),
              ),
              title: Text(
                kIsWeb ? 'Pilih Foto dari Perangkat' : 'Pilih dari Galeri',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textDark),
              ),
              subtitle: const Text(
                'JPG, PNG, WebP • Maks. 5 MB',
                style: TextStyle(fontSize: 11, color: _textMuted),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: _textMuted),
              onTap: () {
                Navigator.pop(sheetContext);
                pickAndUpload(ImageSource.gallery);
              },
            ),
            if (!kIsWeb)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _darkGreen.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_outlined, color: _darkGreen, size: 22),
                ),
                title: const Text(
                  'Ambil Foto dengan Kamera',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textDark),
                ),
                subtitle: const Text(
                  'Gunakan kamera perangkat Anda',
                  style: TextStyle(fontSize: 11, color: _textMuted),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: _textMuted),
                onTap: () {
                  Navigator.pop(sheetContext);
                  pickAndUpload(ImageSource.camera);
                },
              ),
            if (hasAvatar) ...[
              const Divider(height: 20),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                ),
                title: const Text(
                  'Hapus Foto Profil',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red),
                ),
                subtitle: const Text(
                  'Gunakan kembali avatar inisial nama',
                  style: TextStyle(fontSize: 11, color: _textMuted),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  removeAvatar();
                },
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// HALAMAN UTAMA PROFIL PENGGUNA (Lengkap, Responsif, Vercel Blob Avatar)
// ─────────────────────────────────────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  final bool isRootTab;
  final ValueChanged<int>? onSwitchTab;
  final AuthViewModel? authViewModel;
  final TiketViewModel? tiketViewModel;
  final AiChatViewModel? aiChatViewModel;
  final KoleksiViewModel? koleksiViewModel;

  const ProfileScreen({
    super.key,
    this.isRootTab = false,
    this.onSwitchTab,
    this.authViewModel,
    this.tiketViewModel,
    this.aiChatViewModel,
    this.koleksiViewModel,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final AuthViewModel _authViewModel;
  late final TiketViewModel _tiketViewModel;
  late final AiChatViewModel _aiChatViewModel;
  late final KoleksiViewModel _koleksiViewModel;
  late final bool _ownsAuthViewModel;
  late final bool _ownsTiketViewModel;
  late final bool _ownsAiChatViewModel;
  late final bool _ownsKoleksiViewModel;

  bool _isLoadingActivity = true;
  List<TicketBooking> _myBookings = [];
  int _aiChatSessionCount = 0;
  int _totalKoleksi = 0;

  @override
  void initState() {
    super.initState();
    _ownsAuthViewModel = widget.authViewModel == null;
    _ownsTiketViewModel = widget.tiketViewModel == null;
    _ownsAiChatViewModel = widget.aiChatViewModel == null;
    _ownsKoleksiViewModel = widget.koleksiViewModel == null;
    _authViewModel = widget.authViewModel ?? AuthViewModel();
    _tiketViewModel = widget.tiketViewModel ?? TiketViewModel();
    _aiChatViewModel = widget.aiChatViewModel ?? AiChatViewModel();
    _koleksiViewModel = widget.koleksiViewModel ?? KoleksiViewModel();
    _loadProfileAndActivity();
  }

  @override
  void dispose() {
    if (_ownsAuthViewModel) _authViewModel.dispose();
    if (_ownsTiketViewModel) _tiketViewModel.dispose();
    if (_ownsAiChatViewModel) _aiChatViewModel.dispose();
    if (_ownsKoleksiViewModel) _koleksiViewModel.dispose();
    super.dispose();
  }

  Future<void> _loadProfileAndActivity() async {
    if (mounted) setState(() => _isLoadingActivity = true);

    // Sinkronisasi profil terbaru (termasuk avatarUrl) dari MySQL melalui AuthViewModel
    await _authViewModel.fetchMe();
    final user = _authViewModel.currentUser;

    final results = await Future.wait<dynamic>([
      if (user != null && user.email.trim().isNotEmpty)
        _tiketViewModel
            .getMyBookings(user.email.trim())
            .catchError((_) => <TicketBooking>[])
      else
        Future.value(<TicketBooking>[]),
      _aiChatViewModel
          .loadSessions()
          .catchError((_) => <AiChatSession>[]),
      _koleksiViewModel
          .loadKoleksi()
          .catchError((_) => <KoleksiItem>[]),
    ]);

    if (!mounted) return;
    final bookings = (results[0] as List<TicketBooking>)
        .where((b) =>
            user == null ||
            user.email.trim().isEmpty ||
            b.email.trim().toLowerCase() == user.email.trim().toLowerCase())
        .toList();
    final aiSessions = results[1] as List<AiChatSession>;
    final koleksiList = results[2] as List<KoleksiItem>;

    setState(() {
      _myBookings = bookings;
      _aiChatSessionCount = aiSessions.length;
      _totalKoleksi = koleksiList.length;
      _isLoadingActivity = false;
    });
  }

  void _navigateToTab(int tabIndex, String fallbackRoute) {
    if (widget.onSwitchTab != null) {
      widget.onSwitchTab!(tabIndex);
    } else {
      context.go(fallbackRoute);
    }
  }

  Future<void> _showMyTicketsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        final maxHeight = MediaQuery.of(sheetCtx).size.height * 0.78;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: _borderLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.confirmation_number_outlined, color: _darkGreen, size: 22),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Riwayat & Tiket Saya',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _textDark,
                            fontFamily: 'Lato',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: _textMuted, size: 20),
                        onPressed: () => Navigator.pop(sheetCtx),
                      ),
                    ],
                  ),
                  Text(
                    _myBookings.isEmpty
                        ? 'Belum ada riwayat pemesanan tiket pada email akun Anda.'
                        : 'Menampilkan ${_myBookings.length} riwayat pemesanan tiket Anda.',
                    style: const TextStyle(fontSize: 12, color: _textMuted),
                  ),
                  const SizedBox(height: 14),
                  if (_myBookings.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: _bgCream,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _borderLight),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.confirmation_number_outlined, size: 42, color: _textMuted),
                          SizedBox(height: 10),
                          Text(
                            'Belum Ada Tiket',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _textDark,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Pesan e-tiket kunjungan Museum Brawijaya secara praktis melalui menu Tiket.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: _textMuted),
                          ),
                        ],
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _myBookings.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, index) {
                          final item = _myBookings[index];
                          final statusUpper = item.status.toUpperCase();
                          final Color statusBg;
                          final Color statusFg;
                          if (statusUpper == 'LUNAS' || statusUpper == 'SUCCESS') {
                            statusBg = const Color(0xFFE6F4EA);
                            statusFg = const Color(0xFF1E7E34);
                          } else if (statusUpper == 'BATAL' || statusUpper == 'FAILED') {
                            statusBg = const Color(0xFFFDECEA);
                            statusFg = const Color(0xFFC62828);
                          } else {
                            statusBg = const Color(0xFFFFF8E1);
                            statusFg = const Color(0xFFB26A00);
                          }

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAFAF8),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _borderLight),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.id,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: _darkGreen,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: statusBg,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        statusUpper,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: statusFg,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 4,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.calendar_today, size: 12, color: _textMuted),
                                        const SizedBox(width: 4),
                                        Text(
                                          item.visitDate,
                                          style: const TextStyle(fontSize: 11.5, color: _textDark),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.schedule, size: 12, color: _textMuted),
                                        const SizedBox(width: 4),
                                        Text(
                                          item.sesi,
                                          style: const TextStyle(fontSize: 11.5, color: _textDark),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        '${item.totalTiket} Tiket • ${item.paymentMethod}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 11.5, color: _textMuted),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatRupiah(item.totalBiaya),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: _textDark,
                                      ),
                                    ),
                                  ],
                                ),
                                if (item.checkedIn == 1) ...[
                                  const SizedBox(height: 6),
                                  const Row(
                                    children: [
                                      Icon(Icons.verified_outlined, size: 13, color: _darkGreen),
                                      SizedBox(width: 4),
                                      Text(
                                        'Sudah Check-in di Loket',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: _darkGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _darkGreen,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text(
                      'Pesan Tiket Kunjungan',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.pop(sheetCtx);
                      _navigateToTab(2, '/tiket');
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final user = _authViewModel.currentUser;
    if (user == null) return;

    final updated = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ChangePasswordDialog(
        user: user,
        authViewModel: _authViewModel,
      ),
    );

    if (updated == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kata sandi berhasil diperbarui di database MySQL!'),
          backgroundColor: _darkGreen,
        ),
      );
    }
  }

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red, size: 22),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Konfirmasi Keluar',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun ini?\nAnda perlu login kembali untuk mengakses tiket dan profil Anda.',
          style: TextStyle(fontSize: 13, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: _textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Keluar'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _authViewModel.logout();
      if (mounted) context.go('/login');
    }
  }

  void _showFaqDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: _darkGreen),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Bantuan & FAQ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('• Jam Operasional:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              SizedBox(height: 2),
              Text('Selasa - Minggu: 08.00 - 15.00 WIB (Senin Tutup).\n', style: TextStyle(fontSize: 12, height: 1.4)),
              Text('• Pemesanan E-Tiket:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              SizedBox(height: 2),
              Text('Tiket resmi dapat dipesan melalui menu Tiket dan diverifikasi dengan QR Code di loket.\n', style: TextStyle(fontSize: 12, height: 1.4)),
              Text('• Lokasi Museum:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              SizedBox(height: 2),
              Text('Jl. Ijen No.25A, Gading Kasri, Kec. Klojen, Kota Malang, Jawa Timur 65115.', style: TextStyle(fontSize: 12, height: 1.4)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(color: _darkGreen, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _statusLabel(UserModel? user) {
    final role = (user?.role ?? 'USER').toUpperCase();
    if (role == 'ADMIN' || role == 'SUPERADMIN') return 'Administrator Aktif';
    if (role == 'STAFF') return 'Staf Museum Aktif';
    return 'Aktif • Pengunjung Terdaftar';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _authViewModel,
      builder: (context, _) {
        final user = _authViewModel.currentUser;
        final joinedDate = _formatShortDate(user?.createdAt);

        return Scaffold(
          backgroundColor: _bgCream,
          appBar: AppBar(
            backgroundColor: _darkGreen,
            elevation: 0,
            automaticallyImplyLeading: !widget.isRootTab,
            leading: widget.isRootTab
                ? null
                : IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        context.go('/');
                      }
                    },
                  ),
            title: const Text(
              'Profil Pengguna',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Lato',
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                tooltip: 'Muat ulang profil',
                icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 21),
                onPressed: _loadProfileAndActivity,
              ),
            ],
          ),
          body: SafeArea(
            child: RefreshIndicator(
              color: _darkGreen,
              onRefresh: _loadProfileAndActivity,
              child: LayoutBuilder(
                builder: (context, viewportConstraints) {
                  final horizontalPadding = viewportConstraints.maxWidth < 360 ? 12.0 : 16.0;
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 18),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ─── CARD PROFIL UTAMA & AVATAR ─────────────────────────
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: _cardBg,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _borderLight),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: LayoutBuilder(
                                builder: (ctx, cardConstraints) {
                                  final isVeryCompact = cardConstraints.maxWidth < 290;
                                  final avatarWidget = _UserAvatarWidget(
                                    user: user,
                                    size: isVeryCompact ? 70 : 78,
                                    isUploading: _authViewModel.isUploadingAvatar,
                                    onChangePhoto: () => _showAvatarActionSheet(
                                      context: context,
                                      authViewModel: _authViewModel,
                                    ),
                                  );

                                  final userInfoColumn = Column(
                                    crossAxisAlignment: isVeryCompact
                                        ? CrossAxisAlignment.center
                                        : CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user?.nama ?? 'Pengunjung Museum',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign:
                                            isVeryCompact ? TextAlign.center : TextAlign.start,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: _textDark,
                                          fontFamily: 'Lato',
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        user?.email ?? '—',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign:
                                            isVeryCompact ? TextAlign.center : TextAlign.start,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: _textMuted,
                                          fontFamily: 'Lato',
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        alignment: isVeryCompact
                                            ? WrapAlignment.center
                                            : WrapAlignment.start,
                                        spacing: 6,
                                        runSpacing: 5,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _darkGreen.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.verified,
                                                  size: 11,
                                                  color: _darkGreen,
                                                ),
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    _statusLabel(user),
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: _darkGreen,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              user?.authProvider == 'google'
                                                  ? 'Google Auth'
                                                  : 'Akun Mandiri',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF475569),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (joinedDate.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          'Bergabung sejak $joinedDate',
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            color: _textMuted,
                                          ),
                                        ),
                                      ],
                                    ],
                                  );

                                  if (isVeryCompact) {
                                    return Column(
                                      children: [
                                        avatarWidget,
                                        const SizedBox(height: 12),
                                        userInfoColumn,
                                      ],
                                    );
                                  }

                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      avatarWidget,
                                      const SizedBox(width: 16),
                                      Expanded(child: userInfoColumn),
                                    ],
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),

                            // ─── RINGKASAN AKTIVITAS PENGGUNA (3 KARTU RESPONSIF) ───
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSummaryStatCard(
                                    icon: Icons.confirmation_number_outlined,
                                    value: _isLoadingActivity ? '...' : '${_myBookings.length}',
                                    label: 'Tiket Saya',
                                    onTap: _showMyTicketsSheet,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildSummaryStatCard(
                                    icon: Icons.auto_awesome,
                                    value: _isLoadingActivity ? '...' : '$_aiChatSessionCount',
                                    label: 'Obrolan AI',
                                    onTap: () async {
                                      await context.push('/asisten-ai');
                                      if (mounted) await _loadProfileAndActivity();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildSummaryStatCard(
                                    icon: Icons.collections_bookmark_outlined,
                                    value: _isLoadingActivity ? '...' : '$_totalKoleksi',
                                    label: 'Koleksi',
                                    onTap: () => _navigateToTab(1, '/koleksi'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // ─── AKTIVITAS & AKSES CEPAT ────────────────────────────
                            const Text(
                              'Aktivitas & Akses Cepat',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _darkGreen,
                                fontFamily: 'Lato',
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: _borderLight),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: _cardBg,
                                borderRadius: BorderRadius.circular(15),
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  children: [
                                    _buildTile(
                                      icon: Icons.auto_awesome,
                                      title: 'Asisten AI Museum Brawijaya',
                                      subtitle: 'Tanya pemandu virtual seputar koleksi, rute & e-tiket',
                                      onTap: () async {
                                        await context.push('/asisten-ai');
                                        if (mounted) await _loadProfileAndActivity();
                                      },
                                    ),
                                    const Divider(height: 1, indent: 56, endIndent: 16),
                                    _buildTile(
                                      icon: Icons.confirmation_number_outlined,
                                      title: 'Riwayat & Tiket Saya',
                                      subtitle: _myBookings.isEmpty
                                          ? 'Cek status pemesanan atau pesan e-tiket masuk'
                                          : '${_myBookings.length} pemesanan tercatat • Ketuk untuk detail',
                                      onTap: _showMyTicketsSheet,
                                    ),
                                    const Divider(height: 1, indent: 56, endIndent: 16),
                                    _buildTile(
                                      icon: Icons.collections_bookmark_outlined,
                                      title: 'Jelajahi Koleksi Bersejarah',
                                      subtitle: 'Lihat koleksi kendaraan, senjata, dan arsip perang',
                                      onTap: () => _navigateToTab(1, '/koleksi'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ─── PENGATURAN AKUN & LAYANAN ──────────────────────────
                            const Text(
                              'Pengaturan Akun & Layanan',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _darkGreen,
                                fontFamily: 'Lato',
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: _borderLight),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: _cardBg,
                                borderRadius: BorderRadius.circular(15),
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  children: [
                                    _buildTile(
                                      icon: Icons.person_outline,
                                      title: 'Edit Profil',
                                      subtitle: 'Ubah nama lengkap, email, dan foto profil Anda',
                                      onTap: () async {
                                        final updated = await context.push('/edit-profile');
                                        if (updated == true && mounted) {
                                          await _loadProfileAndActivity();
                                        }
                                      },
                                    ),
                                    const Divider(height: 1, indent: 56, endIndent: 16),
                                    _buildTile(
                                      icon: Icons.lock_outline,
                                      title: 'Ubah Kata Sandi',
                                      subtitle: 'Perbarui kata sandi akun di database MySQL',
                                      onTap: _showChangePasswordDialog,
                                    ),
                                    const Divider(height: 1, indent: 56, endIndent: 16),
                                    _buildTile(
                                      icon: Icons.museum_outlined,
                                      title: 'Tentang Museum Brawijaya',
                                      subtitle: 'Sejarah perjuangan, galeri, peta, dan ulasan',
                                      onTap: () => _navigateToTab(3, '/tentang'),
                                    ),
                                    const Divider(height: 1, indent: 56, endIndent: 16),
                                    _buildTile(
                                      icon: Icons.help_outline,
                                      title: 'Pusat Bantuan & FAQ',
                                      subtitle: 'Jam operasional, panduan tiket, dan lokasi',
                                      onTap: _showFaqDialog,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // ─── TOMBOL LOGOUT ──────────────────────────────────────
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade700,
                                foregroundColor: Colors.white,
                                elevation: 1,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(Icons.logout, size: 18),
                              label: const Text(
                                'Keluar dari Akun',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Lato',
                                ),
                              ),
                              onPressed: _confirmLogout,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Versi Aplikasi 1.0.0 • Museum Brawijaya Malang',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11, color: _textMuted),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryStatCard({
    required IconData icon,
    required String value,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: _cardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _darkGreen.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: _darkGreen),
              ),
              const SizedBox(height: 7),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                  fontFamily: 'Lato',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: _textMuted,
                  fontFamily: 'Lato',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _darkGreen.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: _darkGreen, size: 20),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: _textDark,
          fontFamily: 'Lato',
        ),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11, color: _textMuted, fontFamily: 'Lato'),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 13, color: Color(0xFFA0A7A0)),
      onTap: onTap,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DIALOG UBAH KATA SANDI (Terhubung ke Backend & Database MySQL)
// ─────────────────────────────────────────────────────────────────────────────
class _ChangePasswordDialog extends StatefulWidget {
  final UserModel user;
  final AuthViewModel authViewModel;

  const _ChangePasswordDialog({
    required this.user,
    required this.authViewModel,
  });

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final currentPass = _currentPassController.text;
    final newPass = _newPassController.text;
    final confirmPass = _confirmPassController.text;

    if (widget.user.authProvider != 'google' && currentPass.isEmpty) {
      setState(() => _errorMessage = 'Kata sandi saat ini wajib diisi.');
      return;
    }

    final strengthError = widget.authViewModel.validatePassword(newPass);
    if (strengthError != null) {
      setState(() => _errorMessage = strengthError);
      return;
    }

    if (newPass != confirmPass) {
      setState(() => _errorMessage = 'Konfirmasi kata sandi baru tidak cocok.');
      return;
    }

    if (currentPass.isNotEmpty && currentPass == newPass) {
      setState(
        () => _errorMessage = 'Kata sandi baru harus berbeda dari kata sandi saat ini.',
      );
      return;
    }

    setState(() {
      _errorMessage = null;
      _isSaving = true;
    });

    try {
      await widget.authViewModel.changePassword(
        currentPassword: currentPass,
        newPassword: newPass,
        confirmPassword: confirmPass,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = e is ApiException
            ? e.message
            : e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.lock_reset, color: _darkGreen, size: 22),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Ubah Kata Sandi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDECEA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(fontSize: 12, color: Colors.red.shade800),
                  ),
                ),
              ],
              const Text(
                'Kata Sandi Saat Ini',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textDark),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _currentPassController,
                obscureText: _obscureCurrent,
                enabled: !_isSaving,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: widget.user.authProvider == 'google'
                      ? 'Opsional jika akun Google belum punya sandi'
                      : 'Masukkan kata sandi lama',
                  hintStyle: const TextStyle(fontSize: 12),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrent ? Icons.visibility_off : Icons.visibility,
                      size: 18,
                    ),
                    onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Kata Sandi Baru',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textDark),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _newPassController,
                obscureText: _obscureNew,
                enabled: !_isSaving,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Min. 8 karakter (A-Z, a-z, 0-9)',
                  hintStyle: const TextStyle(fontSize: 12),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNew ? Icons.visibility_off : Icons.visibility,
                      size: 18,
                    ),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Konfirmasi Kata Sandi Baru',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textDark),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _confirmPassController,
                obscureText: _obscureConfirm,
                enabled: !_isSaving,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Ulangi kata sandi baru',
                  hintStyle: const TextStyle(fontSize: 12),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                      size: 18,
                    ),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Gunakan minimal 8 karakter dengan kombinasi huruf besar, huruf kecil, dan angka.',
                style: TextStyle(fontSize: 10.5, color: _textMuted, height: 1.35),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context, false),
          child: const Text('Batal', style: TextStyle(color: _textMuted)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _darkGreen,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HALAMAN FORM EDIT PROFIL (Edit Foto, Nama, Email, & Password Opsional)
// ─────────────────────────────────────────────────────────────────────────────
class EditProfileScreen extends StatefulWidget {
  final AuthViewModel? authViewModel;

  const EditProfileScreen({super.key, this.authViewModel});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final AuthViewModel _authViewModel;
  late final bool _ownsAuthViewModel;
  late final TextEditingController _namaController;
  late final TextEditingController _emailController;
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;

  @override
  void initState() {
    super.initState();
    _ownsAuthViewModel = widget.authViewModel == null;
    _authViewModel = widget.authViewModel ?? AuthViewModel();
    final user = _authViewModel.currentUser;
    _namaController = TextEditingController(text: user?.nama ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    if (_ownsAuthViewModel) _authViewModel.dispose();
    _namaController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final user = _authViewModel.currentUser;
    if (user == null) return;

    final nama = _namaController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final currentPass = _currentPasswordController.text;
    final newPass = _newPasswordController.text;

    if (nama.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama lengkap minimal 2 karakter'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Format alamat email tidak valid'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (newPass.isNotEmpty) {
      if (user.authProvider != 'google' && currentPass.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Masukkan kata sandi saat ini untuk mengubah kata sandi'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final passError = _authViewModel.validatePassword(newPass);
      if (passError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(passError), backgroundColor: Colors.red),
        );
        return;
      }
    }

    try {
      await _authViewModel.updateProfile(
        userId: user.id,
        nama: nama,
        email: email,
        currentPassword: currentPass.isNotEmpty ? currentPass : null,
        newPassword: newPass.isNotEmpty ? newPass : null,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil diperbarui di database'),
          backgroundColor: _darkGreen,
        ),
      );
      if (Navigator.canPop(context)) {
        Navigator.pop(context, true);
      } else {
        context.go('/profil');
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException
          ? e.message
          : e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _authViewModel,
      builder: (context, _) {
        final user = _authViewModel.currentUser;
        final isLoading = _authViewModel.isLoading;
        final isUploadingAvatar = _authViewModel.isUploadingAvatar;
        return Scaffold(
          backgroundColor: _bgCream,
          appBar: AppBar(
            backgroundColor: _darkGreen,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  context.go('/profil');
                }
              },
            ),
            title: const Text(
              'Edit Profil',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 580),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: _UserAvatarWidget(
                          user: user,
                          size: 86,
                          isUploading: isUploadingAvatar,
                          onChangePhoto: () => _showAvatarActionSheet(
                            context: context,
                            authViewModel: _authViewModel,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        user?.nama ?? 'Pengguna',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _textDark,
                        ),
                      ),
                      Text(
                        user?.email ?? '',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: _textMuted),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Ketuk foto atau ikon kamera untuk mengubah foto profil',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: _textMuted),
                      ),
                      const SizedBox(height: 20),

                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _borderLight),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Nama Lengkap',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _textDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _namaController,
                              enabled: !isLoading,
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Masukkan nama lengkap',
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFFAFAFA),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: _borderLight),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            const Text(
                              'Alamat Email',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _textDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _emailController,
                              enabled: !isLoading,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'nama@email.com',
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFFAFAFA),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: _borderLight),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Divider(),
                            const SizedBox(height: 10),

                            const Text(
                              'Ubah Kata Sandi (Opsional)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Kosongkan jika tidak ingin mengubah kata sandi',
                              style: TextStyle(fontSize: 11, color: _textMuted),
                            ),
                            const SizedBox(height: 12),

                            const Text(
                              'Kata Sandi Saat Ini',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _textDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _currentPasswordController,
                              enabled: !isLoading,
                              obscureText: _obscureCurrent,
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Masukkan kata sandi lama',
                                hintStyle: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFA0A7A0),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureCurrent ? Icons.visibility_off : Icons.visibility,
                                    size: 18,
                                    color: _textMuted,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscureCurrent = !_obscureCurrent),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFFAFAFA),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: _borderLight),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            const Text(
                              'Kata Sandi Baru',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _textDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _newPasswordController,
                              enabled: !isLoading,
                              obscureText: _obscureNew,
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Min. 8 karakter (huruf besar, kecil & angka)',
                                hintStyle: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFA0A7A0),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureNew ? Icons.visibility_off : Icons.visibility,
                                    size: 18,
                                    color: _textMuted,
                                  ),
                                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFFAFAFA),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: _borderLight),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            ElevatedButton(
                              onPressed: (isLoading || isUploadingAvatar) ? null : _handleSave,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _darkGreen,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 46),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Simpan Perubahan',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
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
            ),
          ),
        );
      },
    );
  }
}
