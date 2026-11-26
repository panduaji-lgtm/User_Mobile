import 'package:app/core/network/api_client.dart';
import 'package:app/features/tentang/data/models/ulasan_models.dart';

export 'package:app/features/tentang/data/models/ulasan_models.dart';

/// Service untuk ulasan pengunjung
class UlasanService {
  static const int minCommentLength = 5;

  /// Ambil semua ulasan dari backend
  static Future<({List<UlasanItem> items, UlasanStats stats})> getAll({
    int limit = 50,
  }) async {
    final res = await ApiClient.get('/ulasan?limit=$limit');
    final rawList = res['data'];
    final list = rawList is List<dynamic> ? rawList : const <dynamic>[];
    final rawStats = res['stats'];
    final statsJson =
        rawStats is Map<String, dynamic> ? rawStats : const <String, dynamic>{};

    final items = list
        .whereType<Map<String, dynamic>>()
        .map(UlasanItem.fromJson)
        .toList();

    return (
      items: items,
      stats: UlasanStats.fromJson(statsJson),
    );
  }

  /// Kirim ulasan baru dari pengunjung (Flutter app)
  static Future<UlasanItem> submitReview({
    required String nama,
    required int rating,
    required String comment,
    String category = 'Kunjungan Umum',
  }) async {
    final trimmedName = nama.trim();
    final trimmedComment = comment.trim();

    if (trimmedName.isEmpty) {
      throw ApiException('Nama tidak boleh kosong');
    }
    if (rating < 1 || rating > 5) {
      throw ApiException('Rating harus antara 1 dan 5');
    }
    if (trimmedComment.length < minCommentLength) {
      throw ApiException('Komentar minimal $minCommentLength karakter');
    }

    final res = await ApiClient.post('/ulasan', {
      'nama': trimmedName,
      'avatar_initial': trimmedName[0].toUpperCase(),
      'rating': rating,
      'comment': trimmedComment,
      'category': category,
    });
    final data = res['data'];
    if (data is Map<String, dynamic>) {
      return UlasanItem.fromJson(data);
    }
    return UlasanItem(
      id: 0,
      nama: trimmedName,
      avatarInitial: trimmedName[0].toUpperCase(),
      avatarColor: '#3F5243',
      category: category,
      rating: rating,
      comment: trimmedComment,
      reply: '',
      replyDate: '',
      createdAt: DateTime.now().toIso8601String(),
    );
  }
}
