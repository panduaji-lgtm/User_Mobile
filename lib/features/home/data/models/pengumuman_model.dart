/// Model pengumuman & agenda pameran yang dikelola admin di Pusat Informasi
class Pengumuman {
  final int id;
  final String title;
  final String description;
  final String category;
  final String date;
  final String status;

  const Pengumuman({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.date,
    required this.status,
  });

  bool get isAgenda => category.toLowerCase().contains('agenda');
  bool get isPemeliharaan => category.toLowerCase().contains('pemeliharaan');

  factory Pengumuman.fromJson(Map<String, dynamic> json) {
    String str(dynamic v, [String fb = '']) =>
        v == null ? fb : v.toString().trim();
    final rawId = json['id'];
    return Pengumuman(
      id: rawId is num ? rawId.toInt() : int.tryParse('$rawId') ?? 0,
      title: str(json['title'], 'Pengumuman'),
      description: str(json['description']),
      category: str(json['category'], 'Informasi Umum'),
      date: str(json['date']),
      status: str(json['status'], 'AKTIF'),
    );
  }
}

