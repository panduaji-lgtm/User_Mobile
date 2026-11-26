int _parseInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? fallback;
  return fallback;
}

String _parseString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  return value.toString();
}

/// Model item koleksi museum
class KoleksiItem {
  final int id;
  final String kode;
  final String nama;
  final String subDeskripsi;
  final String? deskripsiLengkap;
  final String kategori;
  final String tahun;
  final String lokasi;
  final String status;
  final String? imageUrl;

  KoleksiItem({
    required this.id,
    required this.kode,
    required this.nama,
    required this.subDeskripsi,
    this.deskripsiLengkap,
    required this.kategori,
    required this.tahun,
    required this.lokasi,
    required this.status,
    this.imageUrl,
  });

  factory KoleksiItem.fromJson(Map<String, dynamic> json) {
    final rawImage = _parseString(json['image_url']).trim();
    final rawDesc = _parseString(json['deskripsi_lengkap']).trim();
    final rawKategori = _parseString(json['kategori']).trim();
    final rawStatus = _parseString(json['status']).trim();

    return KoleksiItem(
      id: _parseInt(json['id']),
      kode: _parseString(json['kode']).trim(),
      nama: _parseString(json['nama'], fallback: 'Koleksi Museum').trim(),
      subDeskripsi: _parseString(json['sub_deskripsi']).trim(),
      deskripsiLengkap: rawDesc.isNotEmpty ? rawDesc : null,
      kategori: rawKategori.isNotEmpty ? rawKategori : 'Umum',
      tahun: _parseString(json['tahun']).trim(),
      lokasi: _parseString(json['lokasi']).trim(),
      status: rawStatus.isNotEmpty ? rawStatus : 'DIPAMERKAN',
      imageUrl: rawImage.isNotEmpty ? rawImage : null,
    );
  }
}
