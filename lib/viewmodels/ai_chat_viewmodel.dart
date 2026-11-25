import 'package:flutter/foundation.dart';

import 'package:app/core/network/api_client.dart';
import 'package:app/data/repositories/ai_chat_repository.dart';
import 'package:app/data/services/ai_chat_service.dart';

/// ViewModel untuk Asisten AI Museum Brawijaya (multi-turn, multimodal upload gambar, riwayat sesi).
class AiChatViewModel extends ChangeNotifier {
  static const int maxImageBytes = AiChatService.maxImageBytes;

  static String? inferMimeType(String? fileName, String? reportedMime) =>
      AiChatService.inferMimeType(fileName, reportedMime);

  final AiChatRepository _repository;

  List<AiChatSession> _savedSessions = [];
  late AiChatSession _activeSession;
  AiChatImageAttachment? _pendingImage;
  bool _isSending = false;
  bool _isPickingImage = false;
  List<String> _suggestions = const [];
  bool _disposed = false;

  AiChatViewModel({AiChatRepository? repository})
      : _repository = repository ?? const DefaultAiChatRepository() {
    _activeSession = _createEmptySession();
  }

  List<AiChatSession> get savedSessions => List.unmodifiable(_savedSessions);
  AiChatSession get activeSession => _activeSession;
  AiChatImageAttachment? get pendingImage => _pendingImage;
  bool get isSending => _isSending;
  bool get isPickingImage => _isPickingImage;
  List<String> get suggestions => List.unmodifiable(_suggestions);
  bool get hasMessages => _activeSession.messages.isNotEmpty;

  void _safeNotify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  AiChatSession _createEmptySession() {
    final now = DateTime.now();
    return AiChatSession(
      id: 'chat_${now.microsecondsSinceEpoch}',
      title: 'Percakapan Baru',
      createdAt: now,
      updatedAt: now,
      messages: const [],
    );
  }

  Future<List<AiChatSession>> loadSessions() async {
    _savedSessions = await _repository.loadSessions();
    _safeNotify();
    return _savedSessions;
  }

  Future<void> loadSuggestions() async {
    try {
      final fetched = await _repository.getSuggestions();
      if (fetched.isNotEmpty) {
        _suggestions = fetched;
        _safeNotify();
      }
    } catch (_) {
      // Tetap gunakan daftar prompt starter bawaan saat backend offline
    }
  }

  void setPickingImage(bool picking) {
    if (_isPickingImage == picking) return;
    _isPickingImage = picking;
    _safeNotify();
  }

  void setPendingImage(AiChatImageAttachment? attachment) {
    _pendingImage = attachment;
    _safeNotify();
  }

  void clearPendingImage() {
    if (_pendingImage == null) return;
    _pendingImage = null;
    _safeNotify();
  }

  void startNewChat() {
    if (_isSending) return;
    _activeSession = _createEmptySession();
    _pendingImage = null;
    _safeNotify();
  }

  void openSession(AiChatSession session) {
    if (_isSending) return;
    _activeSession = session;
    _pendingImage = null;
    _safeNotify();
  }

  Future<void> deleteSession(String sessionId) async {
    _savedSessions = await _repository.deleteSession(sessionId);
    if (_activeSession.id == sessionId) {
      _activeSession = _createEmptySession();
    }
    _safeNotify();
  }

  /// Mengirim pesan teks dan/atau gambar multimodal ke backend POST /api/ai/chat.
  Future<void> sendMessage({
    required String rawPrompt,
    AiChatImageAttachment? imageOverride,
    bool isRetry = false,
  }) async {
    final trimmed = rawPrompt.trim();
    final attachment = imageOverride ?? (isRetry ? null : _pendingImage);
    if ((trimmed.isEmpty && attachment == null) || _isSending) return;

    final effectivePrompt =
        trimmed.isNotEmpty ? trimmed : AiChatService.defaultImagePrompt;
    final now = DateTime.now();

    final baseMessages = List<AiChatMessage>.from(_activeSession.messages);
    if (isRetry && baseMessages.isNotEmpty && baseMessages.last.isError) {
      baseMessages.removeLast();
    }

    final shouldAppendUser = !isRetry ||
        baseMessages.isEmpty ||
        !baseMessages.last.isUser ||
        baseMessages.last.content != effectivePrompt;

    if (shouldAppendUser) {
      baseMessages.add(
        AiChatMessage(
          id: 'u_${now.microsecondsSinceEpoch}',
          role: 'user',
          content: effectivePrompt,
          createdAt: now,
          imageBase64: attachment?.base64Data,
          imageMimeType: attachment?.mimeType,
          imageName: attachment?.fileName,
        ),
      );
    }

    final firstUserPrompt = baseMessages.firstWhere((m) => m.isUser).content;
    final sessionTitle = _activeSession.messages.isEmpty
        ? AiChatService.deriveSessionTitle(
            trimmed.isNotEmpty
                ? firstUserPrompt
                : 'Analisis Foto: ${attachment?.fileName ?? 'Gambar'}',
          )
        : _activeSession.title;

    _activeSession = _activeSession.copyWith(
      title: sessionTitle,
      updatedAt: now,
      messages: baseMessages,
    );
    if (!isRetry) {
      _pendingImage = null;
    }
    _isSending = true;
    _safeNotify();

    try {
      final result = await _repository.sendChat(
        history: baseMessages,
        image: attachment,
      );

      final replyTime = DateTime.now();
      final updatedMessages = [
        ...baseMessages,
        AiChatMessage(
          id: 'a_${replyTime.microsecondsSinceEpoch}',
          role: 'assistant',
          content: result.reply,
          createdAt: replyTime,
          followUpSuggestions: result.followUpSuggestions,
          quickActions: result.quickActions,
          mode: result.mode,
        ),
      ];

      final completedSession = _activeSession.copyWith(
        updatedAt: replyTime,
        messages: updatedMessages,
      );

      final sessions = await _repository.upsertSession(completedSession);
      _activeSession = completedSession;
      _savedSessions = sessions;
    } catch (error) {
      final errorTime = DateTime.now();
      final errorMessage = error is ApiException
          ? error.message
          : 'Gagal terhubung ke Asisten AI. Pastikan koneksi internet & server backend aktif.';

      final errorMessages = [
        ...baseMessages,
        AiChatMessage(
          id: 'e_${errorTime.microsecondsSinceEpoch}',
          role: 'assistant',
          content: errorMessage,
          createdAt: errorTime,
          isError: true,
          retryPrompt: effectivePrompt,
          retryImage: attachment,
        ),
      ];

      _activeSession = _activeSession.copyWith(
        updatedAt: errorTime,
        messages: errorMessages,
      );
    } finally {
      _isSending = false;
      _safeNotify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
