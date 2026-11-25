import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/core/network/api_client.dart';
import 'package:app/data/services/auth_service.dart';
import 'package:app/models/ai_chat_models.dart';

export 'package:app/models/ai_chat_models.dart';

class AiChatService {
  static const int _maxStoredSessions = 20;
  static const int maxImageBytes = 5 * 1024 * 1024; // 5 MB
  static const String defaultImagePrompt =
      'Tolong identifikasi dan jelaskan gambar ini dalam konteks Museum Brawijaya Malang.';

  static const Set<String> allowedImageMimeTypes = {
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/gif',
  };

  @visibleForTesting
  static Future<AiChatReplyResult> Function({
    required List<Map<String, String>> messages,
    String? visitorName,
    Map<String, dynamic>? image,
  })? debugSendChatOverride;

  static String? inferMimeType(String? fileName, String? reportedMime) {
    final normalizedMime = (reportedMime ?? '').trim().toLowerCase();
    if (normalizedMime == 'image/jpg') return 'image/jpeg';
    if (allowedImageMimeTypes.contains(normalizedMime)) {
      return normalizedMime;
    }

    final lowerName = (fileName ?? '').trim().toLowerCase();
    if (lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lowerName.endsWith('.png')) return 'image/png';
    if (lowerName.endsWith('.webp')) return 'image/webp';
    if (lowerName.endsWith('.gif')) return 'image/gif';
    return null;
  }

  static String _storageKey() {
    final user = AuthService.currentUser;
    final scope = (user?.email.trim().isNotEmpty == true)
        ? user!.email.trim().toLowerCase()
        : (user != null && user.id > 0 ? 'user_${user.id}' : 'guest');
    return 'ai_chat_sessions_$scope';
  }

  /// Mengambil daftar saran pertanyaan populer dari GET /api/ai/chat/suggestions.
  static Future<List<String>> getSuggestions() async {
    final response = await ApiClient.get('/ai/chat/suggestions');
    final data = response['data'];
    if (data is List<dynamic>) {
      return data.whereType<String>().toList();
    }
    if (data is Map<String, dynamic>) {
      final list = data['suggestions'];
      if (list is List<dynamic>) {
        return list.whereType<String>().toList();
      }
    }
    return const [];
  }

  /// Mengirim riwayat percakapan multi-turn (+ opsional gambar multimodal) ke POST /api/ai/chat.
  static Future<AiChatReplyResult> sendChat({
    required List<AiChatMessage> history,
    String? visitorName,
    AiChatImageAttachment? image,
  }) async {
    final apiMessages = history
        .where((m) => !m.isError && m.content.trim().isNotEmpty)
        .map((m) => {'role': m.role, 'content': m.content.trim()})
        .toList();

    if (apiMessages.isEmpty && image != null) {
      apiMessages.add({'role': 'user', 'content': defaultImagePrompt});
    }

    if (apiMessages.isEmpty) {
      throw ApiException('Pesan atau gambar tidak boleh kosong.');
    }

    final resolvedVisitorName =
        (visitorName ?? AuthService.currentUser?.nama)?.trim();
    final imagePayload = image?.toApiJson();

    if (debugSendChatOverride != null) {
      return debugSendChatOverride!(
        messages: apiMessages,
        visitorName: resolvedVisitorName,
        image: imagePayload,
      );
    }

    final response = await ApiClient.post(
      '/ai/chat',
      {
        'messages': apiMessages,
        if (resolvedVisitorName != null && resolvedVisitorName.isNotEmpty)
          'visitorName': resolvedVisitorName,
        'image': ?imagePayload,
      },
      timeout: const Duration(seconds: 50),
    );

    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return AiChatReplyResult.fromJson(data);
    }
    throw ApiException('Format respons Asisten AI tidak valid.');
  }

  /// Memuat seluruh riwayat sesi obrolan milik pengguna saat ini dari SharedPreferences.
  static Future<List<AiChatSession>> loadSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey());
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw) as List<dynamic>;
      final sessions = decoded
          .whereType<Map<String, dynamic>>()
          .map(AiChatSession.fromJson)
          .toList();
      sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return sessions;
    } catch (e) {
      debugPrint('Gagal memuat riwayat chat AI: $e');
      return [];
    }
  }

  static Future<void> _writeSessions(List<AiChatSession> sessions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trimmed = sessions.take(_maxStoredSessions).toList();
      await prefs.setString(
        _storageKey(),
        jsonEncode(trimmed.map((s) => s.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('Gagal menyimpan riwayat chat AI: $e');
    }
  }

  /// Menyimpan atau memperbarui satu sesi percakapan ke SharedPreferences.
  static Future<List<AiChatSession>> upsertSession(
    AiChatSession session,
  ) async {
    final sessions = await loadSessions();
    final filtered = sessions.where((s) => s.id != session.id).toList();
    final updated = [session, ...filtered];
    updated.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    await _writeSessions(updated);
    return updated.take(_maxStoredSessions).toList();
  }

  /// Menghapus satu sesi percakapan dari SharedPreferences.
  static Future<List<AiChatSession>> deleteSession(String sessionId) async {
    final sessions = await loadSessions();
    final updated = sessions.where((s) => s.id != sessionId).toList();
    await _writeSessions(updated);
    return updated;
  }

  static String deriveSessionTitle(String firstUserPrompt) {
    final cleaned = firstUserPrompt.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.isEmpty) return 'Percakapan Baru';
    if (cleaned.length <= 44) return cleaned;
    return '${cleaned.substring(0, 41)}...';
  }
}
