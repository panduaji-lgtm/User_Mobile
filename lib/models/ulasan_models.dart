int _parseInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? fallback;
  return fallback;
}

double _parseDouble(dynamic value, {double fallback = 0}) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim()) ?? fallback;
  return fallback;
}

String _parseString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  return value.toString();
}

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

  bool get hasReply => reply.trim().isNotEmpty;

  factory UlasanItem.fromJson(Map<String, dynamic> json) {
    final nama = _parseString(json['nama'], fallback: 'Pengunjung').trim();
    final rawInitial = _parseString(json['avatar_initial']).trim();
    final initial = rawInitial.isNotEmpty
        ? rawInitial[0].toUpperCase()
        : (nama.isNotEmpty ? nama[0].toUpperCase() : '?');
    final parsedRating = _parseInt(json['rating'], fallback: 5).clamp(1, 5);

    return UlasanItem(
      id: _parseInt(json['id']),
      nama: nama.isNotEmpty ? nama : 'Pengunjung',
      avatarInitial: initial,
      avatarColor: _parseString(json['avatar_color'], fallback: '#3F5243'),
      category: _parseString(json['category'], fallback: 'Kunjungan Umum'),
      rating: parsedRating,
      comment: _parseString(json['comment']).trim(),
      reply: _parseString(json['reply']).trim(),
      replyDate: _parseString(json['reply_date']).trim(),
      createdAt: _parseString(json['created_at']).trim(),
    );
  }
}

/// Statistik ulasan dari backend
class UlasanStats {
  final double averageRating;
  final int total;

  UlasanStats({required this.averageRating, required this.total});

  factory UlasanStats.fromJson(Map<String, dynamic> json) => UlasanStats(
        averageRating: _parseDouble(json['averageRating']),
        total: _parseInt(json['total']),
      );
}
