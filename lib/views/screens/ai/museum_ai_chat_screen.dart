import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:app/models/ai_chat_models.dart';
import 'package:app/viewmodels/ai_chat_viewmodel.dart';
import 'package:app/viewmodels/auth_viewmodel.dart';

typedef AiImagePickerCallback = Future<AiChatImageAttachment?> Function(
  ImageSource source,
);

class _PromptStarter {
  final IconData icon;
  final String title;
  final String subtitle;
  final String prompt;

  const _PromptStarter({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.prompt,
  });
}

class MuseumAiChatScreen extends StatefulWidget {
  final String? initialPrompt;
  final AiImagePickerCallback? imagePickerOverride;
  final AiChatViewModel? viewModel;
  final AuthViewModel? authViewModel;

  const MuseumAiChatScreen({
    super.key,
    this.initialPrompt,
    this.imagePickerOverride,
    this.viewModel,
    this.authViewModel,
  });

  @override
  State<MuseumAiChatScreen> createState() => _MuseumAiChatScreenState();
}

class _MuseumAiChatScreenState extends State<MuseumAiChatScreen> {
  static const Color _bgCream = Color(0xFFF7F3EA);
  static const Color _darkGreen = Color(0xFF3F5243);
  static const Color _goldAccent = Color(0xFFCBB26A);
  static const Color _textDark = Color(0xFF2C322B);
  static const Color _textMuted = Color(0xFF727A71);
  static const Color _borderLight = Color(0xFFE0E3DF);

  static const List<_PromptStarter> _promptStarters = [
    _PromptStarter(
      icon: Icons.train_outlined,
      title: 'Sejarah & makna Gerbong Maut',
      subtitle: 'Tragedi heroik 23 November 1947 Bondowoso–Surabaya',
      prompt: 'Ceritakan sejarah dan makna Gerbong Maut di Museum Brawijaya',
    ),
    _PromptStarter(
      icon: Icons.collections_bookmark_outlined,
      title: 'Koleksi ikonik halaman & ruang museum',
      subtitle: 'Tank Amfibi, Mobil Dinas Letkol, Perahu Segigir & lainnya',
      prompt:
          'Apa saja koleksi ikonik di halaman dan ruang pamer Museum Brawijaya?',
    ),
    _PromptStarter(
      icon: Icons.map_outlined,
      title: 'Rekomendasi rute tur 30 menit vs 1 jam',
      subtitle: 'Panduan jalur kunjungan paling efisien di dalam museum',
      prompt:
          'Berikan rekomendasi rute tur Museum Brawijaya untuk 30 menit vs 1 jam',
    ),
    _PromptStarter(
      icon: Icons.confirmation_number_outlined,
      title: 'Info jam buka, lokasi & cara pesan e-tiket',
      subtitle: 'Harga tiket terbaru, jadwal buka, dan panduan pemesanan',
      prompt:
          'Info jam buka, lokasi, harga tiket, dan cara pesan e-tiket Museum Brawijaya',
    ),
  ];

  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();

  late final AiChatViewModel _viewModel;
  late final bool _ownsViewModel;
  late final AuthViewModel _authViewModel;
  late final bool _ownsAuthViewModel;
  bool _initialPromptHandled = false;

  @override
  void initState() {
    super.initState();
    _ownsViewModel = widget.viewModel == null;
    _viewModel = widget.viewModel ?? AiChatViewModel();
    _ownsAuthViewModel = widget.authViewModel == null;
    _authViewModel = widget.authViewModel ?? AuthViewModel();
    _inputController.addListener(_onInputChanged);
    _initSessions();
  }

  @override
  void dispose() {
    _inputController.removeListener(_onInputChanged);
    _inputController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    if (_ownsViewModel) {
      _viewModel.dispose();
    }
    if (_ownsAuthViewModel) {
      _authViewModel.dispose();
    }
    super.dispose();
  }

  void _onInputChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _initSessions() async {
    await _viewModel.loadSessions();
    if (!mounted) return;

    final initial = widget.initialPrompt?.trim();
    if (initial != null && initial.isNotEmpty && !_initialPromptHandled) {
      _initialPromptHandled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _sendMessage(initial);
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _startNewChat() {
    if (_viewModel.isSending) return;
    _viewModel.startNewChat();
    _inputController.clear();
  }

  void _openSession(AiChatSession session) {
    if (_viewModel.isSending) return;
    _viewModel.openSession(session);
    _scrollToBottom();
  }

  Future<void> _deleteSession(String sessionId) async {
    await _viewModel.deleteSession(sessionId);
  }

  void _showFeedbackSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : _darkGreen,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleAttachTap() async {
    if (_viewModel.isSending || _viewModel.isPickingImage) return;

    // Di Web atau saat pengujian, langsung pilih gambar dari perangkat (1 klik)
    if (kIsWeb || widget.imagePickerOverride != null) {
      await _pickImage(ImageSource.gallery);
      return;
    }

    // Di Mobile, tawarkan Galeri atau Kamera ala Gemini / ChatGPT / Claude
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: _borderLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Text(
                    'Unggah Gambar ke Asisten AI',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _textDark,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    'Kirim foto koleksi, artefak, atau papan informasi museum (JPG, PNG, WEBP maks. 5 MB).',
                    style: TextStyle(fontSize: 11.5, color: _textMuted),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: _darkGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      color: _darkGreen,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Pilih dari Galeri',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: _textDark,
                    ),
                  ),
                  subtitle: const Text(
                    'Unggah foto dari penyimpanan perangkat',
                    style: TextStyle(fontSize: 11.5, color: _textMuted),
                  ),
                  onTap: () => Navigator.pop(sheetCtx, ImageSource.gallery),
                ),
                const SizedBox(height: 4),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: _darkGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: _darkGreen,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Ambil Foto dengan Kamera',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: _textDark,
                    ),
                  ),
                  subtitle: const Text(
                    'Foto langsung koleksi atau artefak museum',
                    style: TextStyle(fontSize: 11.5, color: _textMuted),
                  ),
                  onTap: () => Navigator.pop(sheetCtx, ImageSource.camera),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source != null && mounted) {
      await _pickImage(source);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_viewModel.isPickingImage) return;
    _viewModel.setPickingImage(true);

    try {
      AiChatImageAttachment? attachment;
      if (widget.imagePickerOverride != null) {
        attachment = await widget.imagePickerOverride!(source);
      } else {
        final picked = await _imagePicker.pickImage(
          source: source,
          maxWidth: 1280,
          maxHeight: 1280,
          imageQuality: 85,
        );
        if (picked != null) {
          final bytes = await picked.readAsBytes();
          final fileName =
              picked.name.trim().isNotEmpty ? picked.name.trim() : 'foto.jpg';
          final mimeType =
              AiChatViewModel.inferMimeType(fileName, picked.mimeType) ??
                  'image/jpeg';
          attachment = AiChatImageAttachment(
            bytes: bytes,
            mimeType: mimeType,
            fileName: fileName,
          );
        }
      }

      if (!mounted) return;
      if (attachment == null) {
        _viewModel.setPickingImage(false);
        return;
      }

      if (attachment.bytes.isEmpty) {
        _viewModel.setPickingImage(false);
        _showFeedbackSnack('File gambar kosong.', isError: true);
        return;
      }

      if (attachment.sizeBytes > AiChatViewModel.maxImageBytes) {
        _viewModel.setPickingImage(false);
        _showFeedbackSnack(
          'Ukuran gambar maksimal 5 MB. Silakan pilih gambar yang lebih kecil.',
          isError: true,
        );
        return;
      }

      final validatedMime = AiChatViewModel.inferMimeType(
        attachment.fileName,
        attachment.mimeType,
      );
      if (validatedMime == null) {
        _viewModel.setPickingImage(false);
        _showFeedbackSnack(
          'Format gambar harus JPG, PNG, WEBP, atau GIF.',
          isError: true,
        );
        return;
      }

      _viewModel.setPendingImage(
        AiChatImageAttachment(
          bytes: attachment.bytes,
          mimeType: validatedMime,
          fileName: attachment.fileName,
        ),
      );
      _viewModel.setPickingImage(false);
      _inputFocusNode.requestFocus();
    } catch (e) {
      if (!mounted) return;
      _viewModel.setPickingImage(false);
      _showFeedbackSnack(
        'Gagal memilih gambar: ${e.toString().replaceFirst("Exception: ", "")}',
        isError: true,
      );
    }
  }

  Future<void> _sendMessage(
    String rawText, {
    bool isRetry = false,
    AiChatImageAttachment? overrideImage,
  }) async {
    final attachedImage =
        overrideImage ?? (isRetry ? null : _viewModel.pendingImage);
    final rawTrimmed = rawText.trim();
    if ((rawTrimmed.isEmpty && attachedImage == null) || _viewModel.isSending) {
      return;
    }

    _inputController.clear();

    final sendFuture = _viewModel.sendMessage(
      rawPrompt: rawTrimmed,
      imageOverride: overrideImage,
      isRetry: isRetry,
    );
    _scrollToBottom();
    await sendFuture;
    if (!mounted) return;
    _scrollToBottom();
  }

  Future<void> _copyToClipboard(
    String text, {
    String feedback = 'Jawaban disalin ke clipboard',
  }) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(feedback),
        backgroundColor: _darkGreen,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleQuickAction(AiQuickAction action) {
    final targetRoute =
        action.route == '/kuis' || action.route.trim().isEmpty
            ? '/koleksi'
            : action.route;
    context.go(targetRoute);
  }

  void _showImageFullscreen(Uint8List bytes, String? fileName) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(dialogCtx).size.height * 0.78,
                    maxWidth: MediaQuery.of(dialogCtx).size.width * 0.92,
                  ),
                  child: Image.memory(bytes, fit: BoxFit.contain),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(dialogCtx),
                  ),
                ),
              ),
              if (fileName != null && fileName.isNotEmpty)
                Positioned(
                  left: 12,
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _formatSessionTime(DateTime dt) {
    final now = DateTime.now();
    final sameDay =
        now.year == dt.year && now.month == dt.month && now.day == dt.day;
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    if (sameDay) return 'Hari ini, $hh:$mm';
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
    return '${dt.day} ${months[dt.month - 1]} • $hh:$mm';
  }

  Future<void> _showHistorySheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return ListenableBuilder(
          listenable: _viewModel,
          builder: (ctx, _) {
            final savedSessions = _viewModel.savedSessions;
            final activeSession = _viewModel.activeSession;
            final maxHeight = MediaQuery.of(ctx).size.height * 0.78;
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
                          const Icon(
                            Icons.history_rounded,
                            color: _darkGreen,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Riwayat Obrolan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _textDark,
                                fontFamily: 'Lato',
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.pop(sheetCtx);
                              _startNewChat();
                            },
                            icon: const Icon(
                              Icons.add,
                              size: 16,
                              color: _darkGreen,
                            ),
                            label: const Text(
                              'Baru',
                              style: TextStyle(
                                color: _darkGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (savedSessions.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: _bgCream,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _borderLight),
                          ),
                          child: const Column(
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 38,
                                color: _textMuted,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Belum Ada Riwayat Obrolan',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _textDark,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Mulai percakapan dengan Pemandu Virtual Museum Brawijaya dan sesi Anda akan tersimpan otomatis di sini.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _textMuted,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Flexible(
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: savedSessions.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, index) {
                              final item = savedSessions[index];
                              final isActive = item.id == activeSession.id;
                              final validCount =
                                  item.messages.where((m) => !m.isError).length;

                              return Material(
                                color: isActive
                                    ? _darkGreen.withValues(alpha: 0.08)
                                    : const Color(0xFFFAFAF8),
                                borderRadius: BorderRadius.circular(14),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.pop(sheetCtx);
                                    _openSession(item);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isActive
                                            ? _darkGreen
                                            : _borderLight,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: isActive
                                                ? _darkGreen
                                                : _darkGreen.withValues(
                                                    alpha: 0.1,
                                                  ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.auto_awesome,
                                            size: 16,
                                            color: isActive
                                                ? _goldAccent
                                                : _darkGreen,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: _textDark,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '$validCount pesan • ${_formatSessionTime(item.updatedAt)}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: _textMuted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: 'Hapus riwayat',
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            size: 19,
                                            color: _textMuted,
                                          ),
                                          onPressed: () async {
                                            await _deleteSession(item.id);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_viewModel, _authViewModel]),
      builder: (context, _) {
        final user = _authViewModel.currentUser;
        final firstName = (user?.nama.trim().isNotEmpty == true)
            ? user!.nama.trim().split(' ').first
            : 'Pengunjung';
        final savedSessions = _viewModel.savedSessions;
        final activeSession = _viewModel.activeSession;
        final isSending = _viewModel.isSending;

        return Scaffold(
          backgroundColor: _bgCream,
          appBar: AppBar(
            backgroundColor: _darkGreen,
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  context.go('/');
                }
              },
            ),
            titleSpacing: 0,
            title: const Row(
              children: [
                Icon(Icons.auto_awesome, color: _goldAccent, size: 19),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Asisten AI Brawijaya',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Lato',
                        ),
                      ),
                      Text(
                        'Pemandu Virtual Resmi Museum',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10.5,
                          fontFamily: 'Lato',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Riwayat Obrolan',
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.history_rounded, color: Colors.white),
                    if (savedSessions.isNotEmpty)
                      Positioned(
                        right: -3,
                        top: -3,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: _goldAccent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${savedSessions.length}',
                            style: const TextStyle(
                              color: _textDark,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: _showHistorySheet,
              ),
              IconButton(
                tooltip: 'Percakapan Baru',
                icon: const Icon(
                  Icons.add_comment_outlined,
                  color: Colors.white,
                ),
                onPressed: _startNewChat,
              ),
            ],
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  children: [
                    Expanded(
                      child: activeSession.messages.isEmpty && !isSending
                          ? _buildWelcomeView(firstName)
                          : _buildMessagesList(),
                    ),
                    _buildComposerBar(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeView(String firstName) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero Emblem & Greeting
          Center(
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [_darkGreen, Color(0xFF5D7660)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: _goldAccent, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: _darkGreen.withValues(alpha: 0.2),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: _goldAccent,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Halo, $firstName!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _darkGreen,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Saya Pemandu Virtual Resmi Museum Brawijaya Malang.\nTanyakan kisah koleksi, rute tur, info tiket, atau unggah foto artefak lewat tombol +.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: _textMuted,
              height: 1.45,
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'PERTANYAAN POPULER',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.9,
              color: _darkGreen,
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 10),

          // Prompt Starter Cards
          for (final starter in _promptStarters) ...[
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _sendMessage(starter.prompt),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: _borderLight),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: _darkGreen.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(starter.icon, color: _darkGreen, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              starter.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _textDark,
                                fontFamily: 'Lato',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              starter.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: _textMuted,
                                fontFamily: 'Lato',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.north_east_rounded,
                        size: 16,
                        color: _goldAccent,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 9),
          ],
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    final messages = _viewModel.activeSession.messages;
    final isSending = _viewModel.isSending;
    final totalCount = messages.length + (isSending ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      itemCount: totalCount,
      itemBuilder: (context, index) {
        if (isSending && index == messages.length) {
          return const _TypingIndicatorBubble();
        }
        final message = messages[index];
        final isLastMessage = index == messages.length - 1 && !isSending;

        if (message.isUser) {
          return _buildUserBubble(message);
        }
        if (message.isError) {
          return _buildErrorBubble(message);
        }
        return _buildAssistantBubble(message, showFollowUps: isLastMessage);
      },
    );
  }

  Widget _buildUserBubble(AiChatMessage message) {
    final imgBytes = message.imageBytes;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14, left: 42),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: _darkGreen,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(5),
            ),
            boxShadow: [
              BoxShadow(
                color: _darkGreen.withValues(alpha: 0.14),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (imgBytes != null) ...[
                GestureDetector(
                  onTap: () => _showImageFullscreen(imgBytes, message.imageName),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 220,
                        maxHeight: 170,
                      ),
                      child: Image.memory(
                        imgBytes,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          padding: const EdgeInsets.all(12),
                          color: Colors.white12,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ] else if (message.imageName != null &&
                  message.imageName!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.image_outlined,
                        size: 14,
                        color: _goldAccent,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          message.imageName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                message.content,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  height: 1.45,
                  fontFamily: 'Lato',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBubble(AiChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, right: 20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFDECEA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  color: Colors.red.shade700,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Kendala Koneksi Asisten AI',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              message.content,
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade900,
                height: 1.4,
              ),
            ),
            if (message.retryPrompt != null &&
                message.retryPrompt!.isNotEmpty) ...[
              const SizedBox(height: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _darkGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  minimumSize: const Size(0, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _viewModel.isSending
                    ? null
                    : () => _sendMessage(
                          message.retryPrompt!,
                          isRetry: true,
                          overrideImage: message.retryImage,
                        ),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text(
                  'Coba Lagi',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAssistantBubble(
    AiChatMessage message, {
    required bool showFollowUps,
  }) {
    final badgeLabel = message.mode == 'gemini' ? 'Gemini AI' : 'Pemandu Cerdas';
    final visibleQuickActions =
        message.quickActions.where((a) => a.route != '/kuis').toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16, right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(5),
              ),
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
                // Header AI badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: _darkGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: _goldAccent,
                        size: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Pemandu Brawijaya',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _darkGreen,
                          fontFamily: 'Lato',
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _bgCream,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _borderLight),
                      ),
                      child: Text(
                        badgeLabel,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: _textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Rich Markdown Body
                MarkdownBody(
                  data: message.content,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(
                      fontSize: 13,
                      color: _textDark,
                      height: 1.5,
                      fontFamily: 'Lato',
                    ),
                    strong: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _darkGreen,
                    ),
                    em: const TextStyle(
                      fontStyle: FontStyle.italic,
                      color: _textMuted,
                    ),
                    h1: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _darkGreen,
                      fontFamily: 'PlayfairDisplay',
                    ),
                    h2: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _darkGreen,
                      fontFamily: 'PlayfairDisplay',
                    ),
                    h3: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _darkGreen,
                      fontFamily: 'PlayfairDisplay',
                    ),
                    listBullet: const TextStyle(
                      fontSize: 13,
                      color: _darkGreen,
                      fontWeight: FontWeight.bold,
                    ),
                    listIndent: 18,
                    blockSpacing: 8,
                    blockquoteDecoration: BoxDecoration(
                      color: _bgCream,
                      borderRadius: BorderRadius.circular(8),
                      border: const Border(
                        left: BorderSide(color: _goldAccent, width: 3),
                      ),
                    ),
                    blockquotePadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                ),

                // Tombol Aksi Pintar Aplikasi (Koleksi, Pesan Tiket, Tentang)
                if (visibleQuickActions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final action in visibleQuickActions)
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _darkGreen,
                            backgroundColor: _bgCream,
                            side: const BorderSide(color: _goldAccent),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 7,
                            ),
                            minimumSize: const Size(0, 34),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => _handleQuickAction(action),
                          icon: Icon(_iconForQuickAction(action.type), size: 15),
                          label: Text(
                            action.label,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],

                // Footer Copy & Share buttons
                const SizedBox(height: 10),
                const Divider(height: 1, color: _borderLight),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: _textMuted,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: const Size(0, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _copyToClipboard(message.content),
                      icon: const Icon(Icons.copy_rounded, size: 14),
                      label: const Text(
                        'Salin',
                        style: TextStyle(fontSize: 11.5),
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: _textMuted,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: const Size(0, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _copyToClipboard(
                        'Info Museum Brawijaya Malang (Asisten AI):\n\n${message.content}',
                        feedback: 'Teks siap bagikan telah disalin ke clipboard',
                      ),
                      icon: const Icon(Icons.share_outlined, size: 14),
                      label: const Text(
                        'Bagikan',
                        style: TextStyle(fontSize: 11.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Saran Tanya Lanjutan (Follow-up Suggestions)
          if (showFollowUps && message.followUpSuggestions.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 6),
              child: Text(
                'Tanya lanjutan:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _textMuted,
                ),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final suggestion in message.followUpSuggestions)
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _sendMessage(suggestion),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _darkGreen.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.subdirectory_arrow_right_rounded,
                              size: 14,
                              color: _darkGreen,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                suggestion,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: _darkGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  IconData _iconForQuickAction(String type) {
    switch (type) {
      case 'tiket':
        return Icons.confirmation_number_outlined;
      case 'tentang':
        return Icons.location_on_outlined;
      case 'koleksi':
      default:
        return Icons.collections_bookmark_outlined;
    }
  }

  Widget _buildPendingImagePreview() {
    final pending = _viewModel.pendingImage;
    if (pending == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _bgCream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _goldAccent.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(
              pending.bytes,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 52,
                height: 52,
                color: _borderLight,
                child: const Icon(Icons.image_outlined, color: _textMuted),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  pending.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${pending.formattedSize} • Siap dianalisis Asisten AI',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: _textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Hapus gambar',
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(6),
            onPressed: _viewModel.isSending ? null : _viewModel.clearPendingImage,
            icon: const Icon(
              Icons.close_rounded,
              size: 18,
              color: _textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposerBar() {
    final isSending = _viewModel.isSending;
    final isPickingImage = _viewModel.isPickingImage;
    final pendingImage = _viewModel.pendingImage;
    final canSend = !isSending &&
        (_inputController.text.trim().isNotEmpty || pendingImage != null);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: _borderLight)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPendingImagePreview(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Tombol + untuk Unggah Gambar (ala Gemini / ChatGPT / Claude)
              Tooltip(
                message: 'Unggah gambar',
                child: Material(
                  color: pendingImage != null
                      ? _darkGreen.withValues(alpha: 0.12)
                      : _bgCream,
                  shape: CircleBorder(
                    side: BorderSide(
                      color: pendingImage != null ? _darkGreen : _borderLight,
                    ),
                  ),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: (isSending || isPickingImage)
                        ? null
                        : _handleAttachTap,
                    child: SizedBox(
                      width: 42,
                      height: 42,
                      child: isPickingImage
                          ? const Padding(
                              padding: EdgeInsets.all(11),
                              child: CircularProgressIndicator(
                                color: _darkGreen,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.add_rounded,
                              color: _darkGreen,
                              size: 22,
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _inputController,
                  focusNode: _inputFocusNode,
                  enabled: !isSending,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (value) {
                    if (canSend) {
                      _sendMessage(value);
                    }
                  },
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: _textDark,
                    fontFamily: 'Lato',
                  ),
                  decoration: InputDecoration(
                    hintText: pendingImage != null
                        ? 'Tanyakan sesuatu tentang gambar ini...'
                        : 'Tanya koleksi, sejarah, rute, atau kirim foto...',
                    hintStyle: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF98A097),
                    ),
                    filled: true,
                    fillColor: _bgCream,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 11,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: _borderLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: _borderLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(
                        color: _darkGreen,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: canSend
                    ? _darkGreen
                    : _darkGreen.withValues(alpha: 0.45),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: canSend
                      ? () => _sendMessage(_inputController.text)
                      : null,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: isSending
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TypingIndicatorBubble extends StatefulWidget {
  const _TypingIndicatorBubble();

  @override
  State<_TypingIndicatorBubble> createState() => _TypingIndicatorBubbleState();
}

class _TypingIndicatorBubbleState extends State<_TypingIndicatorBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, right: 32),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(5),
          ),
          border: Border.all(color: const Color(0xFFE0E3DF)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: Color(0xFF3F5243),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Color(0xFFCBB26A),
                size: 12,
              ),
            ),
            const SizedBox(width: 10),
            AnimatedBuilder(
              animation: _controller,
              builder: (_, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final phase = (_controller.value - (i * 0.2)) % 1.0;
                    final opacity = 0.25 +
                        (0.75 *
                            (1.0 - (phase - 0.5).abs() * 2).clamp(0.0, 1.0));
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3F5243)
                            .withValues(alpha: opacity),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                );
              },
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                'Pemandu sedang menyiapkan jawaban...',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, color: Color(0xFF727A71)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
