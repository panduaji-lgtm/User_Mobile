import 'package:flutter/foundation.dart';
import 'package:app/features/koleksi/data/repositories/koleksi_service.dart';

class KoleksiViewModel extends ChangeNotifier {
  int _selectedCategoryIndex = 0;
  final List<String> _categories = const ['Semua', 'Senjata', 'Kendaraan'];
  String _searchQuery = '';
  List<Map<String, String>> _dynamicKoleksiItems = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  int get selectedCategoryIndex => _selectedCategoryIndex;
  List<String> get categories => _categories;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final List<Map<String, String>> _fallbackKoleksiItems = const [
    {
      'title': 'Gerbong Maut',
      'subtitle': '1947 - 1948',
      'category': 'Kendaraan',
      'image': 'assets/images/collection/menu_gerbong_maut.png',
      'description':
          'Gerbong kereta api yang menjadi saksi bisu tragedi Peristiwa Gerbong Maut 1947, di mana 46 pejuang kemerdekaan Indonesia tewas dalam kondisi gerbong yang sangat sesak dan panas.',
      'tahun': '1947',
      'lokasi': 'Halaman Depan',
    },
    {
      'title': 'Perahu Segigir',
      'subtitle': 'Perjuangan Laut',
      'category': 'Kendaraan',
      'image': 'assets/images/collection/menu_perahu_segigir.png',
      'description':
          'Perahu tradisional yang digunakan pejuang kemerdekaan untuk operasi militer dan patroli laut.',
      'tahun': '1946',
      'lokasi': 'Area Pameran Luar',
    },
    {
      'title': 'Meriam Si Buang',
      'subtitle': '1945',
      'category': 'Senjata',
      'image': 'assets/images/collection/menu_meriam_si_buang.png',
      'description':
          'Meriam bersejarah hasil rampasan tentara sekutu yang digunakan dalam pertempuran kemerdekaan.',
      'tahun': '1945',
      'lokasi': 'Halaman Depan',
    },
    {
      'title': 'Tank Amfibi',
      'subtitle': '1945',
      'category': 'Kendaraan',
      'image': 'assets/images/collection/menu_tank_amfibi.png',
      'description':
          'Kendaraan lapis baja amfibi yang digunakan dalam operasi militer pertempuran di darat dan air.',
      'tahun': '1945',
      'lokasi': 'Halaman Belakang',
    },
    {
      'title': 'Senapan Laras Panjang',
      'subtitle': '1945 - 1949',
      'category': 'Senjata',
      'image': 'assets/images/collection/menu_senapan_laras_panjang.png',
      'description':
          'Senapan laras panjang yang digunakan oleh prajurit pejuang kemerdekaan Republik Indonesia.',
      'tahun': '1945',
      'lokasi': 'Gedung Utama',
    },
    {
      'title': 'Seragam TNI',
      'subtitle': 'Era Revolusi',
      'category': 'Semua',
      'image': 'assets/images/collection/menu_seragam_tni.png',
      'description':
          'Pakaian dinas resmi dan seragam tempur prajurit TNI pada masa revolusi kemerdekaan fisik.',
      'tahun': '1950',
      'lokasi': 'Gedung Utama (Lantai 2)',
    },
    {
      'title': 'Mobil Dinas Letkol',
      'subtitle': '1947',
      'category': 'Kendaraan',
      'image': 'assets/images/collection/menu_mobil_dinas_letkol.png',
      'description':
          'Kendaraan resmi dinas Letnan Kolonel yang digunakan pada masa perjuangan mempertahankan kemerdekaan.',
      'tahun': '1947',
      'lokasi': 'Gedung Utama (Lantai 1)',
    },
    {
      'title': 'Senjata Penumpasan PRRI',
      'subtitle': 'Operasi Militer',
      'category': 'Senjata',
      'image': 'assets/images/collection/menu_senjata_penumpasan_prri.png',
      'description':
          'Senjata peninggalan operasi militer penumpasan PRRI/Permesta untuk mempertahankan kedaulatan NKRI.',
      'tahun': '1958',
      'lokasi': 'Gedung Utama',
    },
  ];

  // Logic: List yang telah difilter berdasarkan Kategori & Pencarian
  List<Map<String, String>> get filteredItems {
    final activeCollection = _dynamicKoleksiItems.isNotEmpty
        ? _dynamicKoleksiItems
        : _fallbackKoleksiItems;

    String selectedCategory = _categories[_selectedCategoryIndex];
    List<Map<String, String>> list;
    if (selectedCategory == 'Semua') {
      list = activeCollection;
    } else {
      list = activeCollection
          .where((item) => item['category'] == selectedCategory)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((item) {
        final title = (item['title'] ?? '').toLowerCase();
        final sub = (item['subtitle'] ?? '').toLowerCase();
        return title.contains(q) || sub.contains(q);
      }).toList();
    }

    return list;
  }

  // Set kategori yang dipilih
  void setCategory(int index) {
    if (_selectedCategoryIndex != index) {
      _selectedCategoryIndex = index;
      notifyListeners();
    }
  }

  // Set teks pencarian
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Fetch dari API Service
  Future<void> fetchKoleksi() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final backendItems = await KoleksiService.getAll();
      if (backendItems.isNotEmpty) {
        final List<Map<String, String>> mapped = [];
        for (final item in backendItems) {
          String imagePath = item.imageUrl ?? '';
          if (imagePath.isEmpty) {
            final t = item.nama.toLowerCase();
            if (t.contains('gerbong')) {
              imagePath = 'assets/images/collection/menu_gerbong_maut.png';
            } else if (t.contains('perahu')) {
              imagePath = 'assets/images/collection/menu_perahu_segigir.png';
            } else if (t.contains('meriam')) {
              imagePath = 'assets/images/collection/menu_meriam_si_buang.png';
            } else if (t.contains('amfibi')) {
              imagePath = 'assets/images/collection/menu_tank_amfibi.png';
            } else if (t.contains('senapan')) {
              imagePath = 'assets/images/collection/menu_senapan_laras_panjang.png';
            } else if (t.contains('seragam')) {
              imagePath = 'assets/images/collection/menu_seragam_tni.png';
            } else if (t.contains('mobil')) {
              imagePath = 'assets/images/collection/menu_mobil_dinas_letkol.png';
            } else if (t.contains('prri')) {
              imagePath = 'assets/images/collection/menu_senjata_penumpasan_prri.png';
            }
          }

          mapped.add({
            'title': item.nama,
            'subtitle': item.subDeskripsi.isNotEmpty
                ? item.subDeskripsi
                : (item.tahun.isNotEmpty ? item.tahun : 'Koleksi Museum'),
            'category': item.kategori,
            'image': imagePath,
            'description': item.deskripsiLengkap ?? item.subDeskripsi,
            'tahun': item.tahun,
            'lokasi': item.lokasi,
          });
        }
        _dynamicKoleksiItems = mapped;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

