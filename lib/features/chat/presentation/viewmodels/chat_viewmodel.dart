import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;

class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class ChatViewModel extends ChangeNotifier {
  final List<ChatMessage> _messages = [
    ChatMessage(
      role: 'assistant',
      content:
          'Halo! Saya Brawijaya Asisten 🏛️. Ada yang bisa saya bantu seputar info kunjungan, harga tiket, sisa kuota, atau koleksi benda bersejarah Museum Brawijaya?',
    ),
  ];
  bool _isLoading = false;
  String? _error;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Otomatis sesuaikan IP: 10.0.2.2 jika Android Emulator, localhost jika Desktop/Web/iOS
  static String get _endpointUrl {
    if (!kIsWeb) {
      try {
        if (Platform.isAndroid) {
          return 'http://10.0.2.2:3001/chat';
        }
      } catch (_) {}
    }
    return 'http://localhost:3001/chat';
  }

  Future<void> send(String userText) async {
    final text = userText.trim();
    if (text.isEmpty || _isLoading) return;

    _messages.add(ChatMessage(role: 'user', content: text));
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Siapkan riwayat (kecuali pesan sapaan awal jika diinginkan, atau kirim semua)
      final historyPayload = _messages
          .where((m) => m.role == 'user' || m.role == 'assistant')
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();

      final response = await http
          .post(
            Uri.parse(_endpointUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'pesan': text,
              'riwayat': historyPayload,
            }),
          )
          .timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final answer = data['jawaban'] ??
            'Maaf, tidak ada respon yang dapat ditampilkan saat ini.';
        _messages.add(ChatMessage(role: 'assistant', content: answer));
      } else {
        _error = 'Server error (${response.statusCode}). Pastikan backend menyala.';
        _messages.add(ChatMessage(
          role: 'assistant',
          content: 'Maaf, terjadi kendala saat menghubungi server (${response.statusCode}). Silakan coba beberapa saat lagi.',
        ));
      }
    } catch (e) {
      _error = e.toString();
      _messages.add(ChatMessage(
        role: 'assistant',
        content:
            'Maaf, tidak dapat terhubung ke server backend chatbot. Pastikan backend di port 3001 sudah berjalan.',
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearChat() {
    _messages.clear();
    _messages.add(ChatMessage(
      role: 'assistant',
      content:
          'Halo! Saya Brawijaya Asisten 🏛️. Ada yang bisa saya bantu seputar info kunjungan, harga tiket, kuota, atau koleksi museum?',
    ));
    _error = null;
    notifyListeners();
  }
}
