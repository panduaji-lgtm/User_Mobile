import 'package:app/core/network/api_client.dart';
import 'package:app/features/home/data/models/pengumuman_model.dart';

export 'package:app/features/home/data/models/pengumuman_model.dart';

/// Service untuk data Pusat Informasi (pengumuman & agenda pameran)
class InformasiService {
  /// Ambil pengumuman & agenda berstatus AKTIF dari database
  static Future<List<Pengumuman>> getPengumumanAktif() async {
    final res = await ApiClient.get('/informasi/pengumuman?status=AKTIF');
    final raw = res['data'];
    final list = raw is List<dynamic> ? raw : const <dynamic>[];
    return list
        .whereType<Map<String, dynamic>>()
        .map(Pengumuman.fromJson)
        .where((p) => p.status.toUpperCase() == 'AKTIF')
        .toList();
  }
}

