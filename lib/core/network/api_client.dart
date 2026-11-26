import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:app/features/auth/data/repositories/auth_service.dart';

/// Base URL backend Express.js
/// - Android emulator: http://10.0.2.2:3001
/// - Web / Desktop (localhost): http://localhost:3001
const _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');
const _apiPort = String.fromEnvironment('API_PORT', defaultValue: '3001');

String get kBaseUrl {
  if (_apiBaseUrlOverride.isNotEmpty) {
    return _apiBaseUrlOverride.replaceFirst(RegExp(r'/+$'), '');
  }

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:$_apiPort/api';
  }
  return 'http://localhost:$_apiPort/api';
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Helper untuk melakukan HTTP request ke backend
class ApiClient {
  static final Map<String, String> _defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> get _headers {
    final headers = Map<String, String>.from(_defaultHeaders);
    final token = AuthService.token;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<Map<String, dynamic>> get(String path) async {
    try {
      final uri = Uri.parse('$kBaseUrl$path');
      final res = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));
      return _handleResponse(res);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Gagal terhubung ke server. Pastikan backend berjalan.',
      );
    }
  }

  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final uri = Uri.parse('$kBaseUrl$path');
    try {
      final res = await http
          .post(uri, headers: _headers, body: jsonEncode(body))
          .timeout(timeout);
      return _handleResponse(res);
    } on ApiException {
      rethrow;
    } on TimeoutException catch (error) {
      debugPrint('POST $uri timed out after ${timeout.inSeconds}s: $error');
      throw ApiException(
        'Waktu tunggu habis saat menghubungi backend. Periksa koneksi lalu coba lagi.',
      );
    } on http.ClientException catch (error) {
      debugPrint('POST $uri failed: $error');
      throw ApiException(
        'Tidak dapat mengakses backend di $uri. Periksa server, alamat API, dan CORS jika menggunakan Flutter Web.',
      );
    } catch (error) {
      debugPrint('POST $uri failed: $error');
      throw ApiException('Gagal memproses respons dari server.');
    }
  }

  static Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final uri = Uri.parse('$kBaseUrl$path');
      final res = await http
          .put(uri, headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 10));
      return _handleResponse(res);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Gagal terhubung ke server. Pastikan backend berjalan.',
      );
    }
  }

  static Future<Map<String, dynamic>> delete(String path) async {
    try {
      final uri = Uri.parse('$kBaseUrl$path');
      final res = await http
          .delete(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));
      return _handleResponse(res);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Gagal terhubung ke server. Pastikan backend berjalan.',
      );
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response res) {
    Map<String, dynamic> data = <String, dynamic>{};
    final rawBody = res.body.trim();
    if (rawBody.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawBody);
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      } catch (_) {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          throw ApiException(
            'Format respons server tidak valid.',
            statusCode: res.statusCode,
          );
        }
      }
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return data;
    }

    final serverMessage = data['message']?.toString().trim();
    throw ApiException(
      (serverMessage != null && serverMessage.isNotEmpty)
          ? serverMessage
          : 'Terjadi kesalahan server (${res.statusCode}).',
      statusCode: res.statusCode,
    );
  }
}
