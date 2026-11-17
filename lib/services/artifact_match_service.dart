import 'package:flutter/foundation.dart';

import 'api_client.dart';

class ArtifactMatchResult {
  final String matchedArtifact;
  final String aiExplanation;
  final DateTime createdAt;

  const ArtifactMatchResult({
    required this.matchedArtifact,
    required this.aiExplanation,
    required this.createdAt,
  });

  factory ArtifactMatchResult.fromJson(Map<String, dynamic> json) {
    return ArtifactMatchResult(
      matchedArtifact:
          json['matched_artifact'] as String? ?? 'Artefak Bersejarah',
      aiExplanation:
          json['ai_explanation'] as String? ?? 'Penjelasan tidak tersedia.',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}

class ArtifactMatchService {
  static Future<ArtifactMatchResult> createMatch({
    required List<String> answers,
  }) async {
    try {
      final response = await ApiClient.post('/ai/artifact-match', {
        'answers': answers,
      }, timeout: const Duration(seconds: 90));

      // Pastikan response berupa Map sebelum diparsing
      if (response is Map<String, dynamic>) {
        return ArtifactMatchResult.fromJson(response);
      } else {
        throw ApiException('Format respons dari server tidak valid.');
      }
    } on ApiException catch (error) {
      debugPrint(
        'POST /ai/artifact-match failed with ApiException: ${error.message}',
      );
      throw ApiException(
        error.message.isNotEmpty
            ? error.message
            : 'Analisis kecocokan artefak gagal. Silakan coba lagi.',
        statusCode: error.statusCode,
      );
    } catch (error) {
      debugPrint('POST /ai/artifact-match unexpected error: $error');
      throw ApiException(
        'Terjadi kesalahan koneksi atau server tidak merespons.',
      );
    }
  }
}
