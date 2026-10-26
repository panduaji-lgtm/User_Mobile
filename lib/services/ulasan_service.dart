import 'api_client.dart';

/// Model ulasan pengunjung
class UlasanItem {
  final int id;
  final String nama;
  final String avatarInitial;
  final String avatarColor;
  final String category;
  final int rating;
  final String comment;
  final String reply;
  final String replyDate;
  final String createdAt;

  UlasanItem({
    required this.id,
    required this.nama,
    required this.avatarInitial,
    required this.avatarColor,
    required this.category,
    required this.rating,
    required this.comment,
    required this.reply,
    required this.replyDate,
    required this.createdAt,
  });

  bool get hasReply => reply.isNotEmpty;

  factory UlasanItem.fromJson(Map<String, dynamic> json) => UlasanItem(
        id: json['id'] as int,
        nama: json['nama'] as String,
        avatarInitial: json['avatar_initial'] as String? ?? '?',
        avatarColor: json['avatar_color'] as String? ?? '#3F5243',
        category: json['category'] as String? ?? 'Kunjungan Umum',
        rating: json['rating'] as int,
        comment: json['comment'] as String,
        reply: json['reply'] as String? ?? '',
        replyDate: json['reply_date'] as String? ?? '',
        createdAt: json['created_at'] as String? ?? '',
      );
}

/// Statistik ulasan dari backend
class UlasanStats {
  final double averageRating;
  final int total;

  UlasanStats({required this.averageRating, required this.total});

  factory UlasanStats.fromJson(Map<String, dynamic> json) => UlasanStats(
        averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
        total: json['total'] as int? ?? 0,
      );
}

/// Service untuk ulasan pengunjung
class UlasanService {
  /// Ambil semua ulasan dari backend
  static Future<({List<UlasanItem> items, UlasanStats stats})> getAll({
    int limit = 50,
  }) async {
    final res = await ApiClient.get('/ulasan?limit=$limit');
    final list = res['data'] as List<dynamic>;
    final statsJson = res['stats'] as Map<String, dynamic>? ?? {};

    return (
      items: list
          .map((e) => UlasanItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      stats: UlasanStats.fromJson(statsJson),
    );
  }

  /// Kirim ulasan baru dari pengunjung (Flutter app)
  ///
  /// [nama] - Nama pengunjung
  /// [rating] - Rating 1-5
  /// [comment] - Isi ulasan (minimal 10 karakter)
  /// [category] - Kategori kunjungan (opsional)
  static Future<UlasanItem> submitReview({
    required String nama,
    required int rating,
    required String comment,
    String category = 'Kunjungan Umum',
  }) async {
    if (nama.trim().isEmpty) throw ApiException('Nama tidak boleh kosong');
    if (rating < 1 || rating > 5) throw ApiException('Rating harus antara 1 dan 5');
    if (comment.trim().length < 10) throw ApiException('Komentar minimal 10 karakter');

    final res = await ApiClient.post('/ulasan', {
      'nama': nama.trim(),
      'rating': rating,
      'comment': comment.trim(),
      'category': category,
    });
    return UlasanItem.fromJson(res['data'] as Map<String, dynamic>);
  }
}
