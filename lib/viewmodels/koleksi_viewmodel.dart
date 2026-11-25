import 'package:flutter/foundation.dart';

import 'package:app/data/repositories/koleksi_repository.dart';
import 'package:app/models/koleksi_model.dart';

/// ViewModel untuk katalog koleksi Museum Brawijaya.
/// Filter kategori dikunci pada: Semua, Kendaraan, dan Senjata.
class KoleksiViewModel extends ChangeNotifier {
  static const List<String> categories = ['Semua', 'Kendaraan', 'Senjata'];

  final KoleksiRepository _repository;

  List<KoleksiItem> _items = const [];
  int _selectedCategoryIndex = 0;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;

  KoleksiViewModel({KoleksiRepository? repository})
      : _repository = repository ?? const DefaultKoleksiRepository();

  List<KoleksiItem> get items => List.unmodifiable(_items);
  int get selectedCategoryIndex => _selectedCategoryIndex;
  String get selectedCategory => categories[_selectedCategoryIndex];
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _safeNotify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  List<KoleksiItem> get filteredItems {
    final query = _searchQuery.trim().toLowerCase();
    final activeCategory = selectedCategory.toLowerCase();
    return _items.where((item) {
      final matchesCategory = activeCategory == 'semua' ||
          item.kategori.toLowerCase() == activeCategory;
      final matchesQuery = query.isEmpty ||
          item.nama.toLowerCase().contains(query) ||
          item.subDeskripsi.toLowerCase().contains(query) ||
          item.kategori.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  void selectCategory(int index) {
    if (index < 0 || index >= categories.length) return;
    if (_selectedCategoryIndex == index) return;
    _selectedCategoryIndex = index;
    _safeNotify();
  }

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    _safeNotify();
  }

  void resetFilters() {
    _searchQuery = '';
    _selectedCategoryIndex = 0;
    _safeNotify();
  }

  Future<List<KoleksiItem>> loadKoleksi({
    Future<List<KoleksiItem>> Function()? loaderOverride,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();

    try {
      final fetched = loaderOverride != null
          ? await loaderOverride()
          : await _repository.getAll();
      _items = List<KoleksiItem>.from(fetched);
      _errorMessage = null;
      return _items;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return _items;
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
