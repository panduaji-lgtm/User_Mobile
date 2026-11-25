import 'package:app/data/services/ulasan_service.dart';

/// Kontrak repository untuk ulasan & statistik rating pengunjung.
abstract interface class UlasanRepository {
  Future<({List<UlasanItem> items, UlasanStats stats})> getAll({
    int limit = 50,
  });

  Future<UlasanItem> submitReview({
    required String nama,
    required int rating,
    required String comment,
    String category = 'Kunjungan Umum',
  });
}

/// Implementasi default [UlasanRepository] berbasis [UlasanService].
class DefaultUlasanRepository implements UlasanRepository {
  const DefaultUlasanRepository();

  @override
  Future<({List<UlasanItem> items, UlasanStats stats})> getAll({
    int limit = 50,
  }) =>
      UlasanService.getAll(limit: limit);

  @override
  Future<UlasanItem> submitReview({
    required String nama,
    required int rating,
    required String comment,
    String category = 'Kunjungan Umum',
  }) =>
      UlasanService.submitReview(
        nama: nama,
        rating: rating,
        comment: comment,
        category: category,
      );
}
