import 'dart:convert';
import 'package:http/http.dart' as http;

/// Base URL backend Express.js
/// - Android emulator: http://10.0.2.2:3001
/// - Web / Desktop (localhost): http://localhost:3001
const String kBaseUrl = 'http://localhost:3001/api';

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

  static Future<Map<String, dynamic>> get(String path) async {
    try {
      final uri = Uri.parse('$kBaseUrl$path');
      final res = await http.get(uri, headers: _defaultHeaders)
          .timeout(const Duration(seconds: 10));
      return _handleResponse(res);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal terhubung ke server. Pastikan backend berjalan.');
    }
  }

  static Future<Map<String, dynamic>> post(
      String path, Map<String, dynamic> body) async {
    try {
      final uri = Uri.parse('$kBaseUrl$path');
      final res = await http
          .post(uri, headers: _defaultHeaders, body: jsonEncode(body))
          .timeout(const Duration(seconds: 10));
      return _handleResponse(res);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal terhubung ke server. Pastikan backend berjalan.');
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response res) {
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return data;
    }
    throw ApiException(
      data['message'] ?? 'Terjadi kesalahan (${res.statusCode})',
      statusCode: res.statusCode,
    );
  }
}
