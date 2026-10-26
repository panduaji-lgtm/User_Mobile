import 'api_client.dart';

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

  factory KoleksiItem.fromJson(Map<String, dynamic> json) => KoleksiItem(
        id: json['id'] as int,
        kode: json['kode'] as String,
        nama: json['nama'] as String,
        subDeskripsi: json['sub_deskripsi'] as String? ?? '',
        deskripsiLengkap: json['deskripsi_lengkap'] as String?,
        kategori: json['kategori'] as String,
        tahun: json['tahun'] as String? ?? '',
        lokasi: json['lokasi'] as String? ?? '',
        status: json['status'] as String,
        imageUrl: json['image_url'] as String?,
      );
}

/// Service untuk data koleksi museum
class KoleksiService {
  /// Ambil semua koleksi (dengan optional search & kategori filter)
  static Future<List<KoleksiItem>> getAll({
    String? search,
    String? kategori,
    int limit = 50,
  }) async {
    final params = <String>[];
    if (search != null && search.isNotEmpty) params.add('search=${Uri.encodeComponent(search)}');
    if (kategori != null && kategori != 'Semua') params.add('kategori=${Uri.encodeComponent(kategori)}');
    params.add('limit=$limit');
    params.add('status=DIPAMERKAN'); // Tampilkan hanya yang dipamerkan di app pengunjung

    final query = params.isNotEmpty ? '?${params.join('&')}' : '';
    final res = await ApiClient.get('/koleksi$query');
    final list = res['data'] as List<dynamic>;
    return list.map((e) => KoleksiItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Ambil detail satu koleksi berdasarkan ID
  static Future<KoleksiItem> getById(int id) async {
    final res = await ApiClient.get('/koleksi/$id');
    return KoleksiItem.fromJson(res['data'] as Map<String, dynamic>);
  }
}
