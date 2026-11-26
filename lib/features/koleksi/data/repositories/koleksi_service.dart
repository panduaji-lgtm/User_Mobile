import 'package:app/core/network/api_client.dart';
import 'package:app/features/koleksi/data/models/koleksi_model.dart';

export 'package:app/features/koleksi/data/models/koleksi_model.dart';

/// Service untuk data koleksi museum
class KoleksiService {
  /// Ambil semua koleksi (dengan optional search & kategori filter)
  static Future<List<KoleksiItem>> getAll({
    String? search,
    String? kategori,
    int limit = 50,
  }) async {
    final params = <String>[];
    if (search != null && search.trim().isNotEmpty) {
      params.add('search=${Uri.encodeComponent(search.trim())}');
    }
    if (kategori != null && kategori.trim().isNotEmpty && kategori != 'Semua') {
      params.add('kategori=${Uri.encodeComponent(kategori.trim())}');
    }
    params.add('limit=$limit');
    params.add('status=DIPAMERKAN'); // Tampilkan hanya yang dipamerkan di app pengunjung

    final query = params.isNotEmpty ? '?${params.join('&')}' : '';
    final res = await ApiClient.get('/koleksi$query');
    final rawList = res['data'];
    final list = rawList is List<dynamic> ? rawList : const <dynamic>[];
    return list
        .whereType<Map<String, dynamic>>()
        .map(KoleksiItem.fromJson)
        .toList();
  }

  /// Ambil detail satu koleksi berdasarkan ID
  static Future<KoleksiItem> getById(int id) async {
    final res = await ApiClient.get('/koleksi/$id');
    final data = res['data'];
    if (data is Map<String, dynamic>) {
      return KoleksiItem.fromJson(data);
    }
    throw ApiException('Data koleksi tidak ditemukan');
  }
}
