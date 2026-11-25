import 'package:app/data/services/koleksi_service.dart';

/// Kontrak repository untuk katalog koleksi Museum Brawijaya.
abstract interface class KoleksiRepository {
  Future<List<KoleksiItem>> getAll({
    String? search,
    String? kategori,
    int limit = 50,
  });

  Future<KoleksiItem> getById(int id);
}

/// Implementasi default [KoleksiRepository] berbasis [KoleksiService].
class DefaultKoleksiRepository implements KoleksiRepository {
  const DefaultKoleksiRepository();

  @override
  Future<List<KoleksiItem>> getAll({
    String? search,
    String? kategori,
    int limit = 50,
  }) =>
      KoleksiService.getAll(search: search, kategori: kategori, limit: limit);

  @override
  Future<KoleksiItem> getById(int id) => KoleksiService.getById(id);
}
