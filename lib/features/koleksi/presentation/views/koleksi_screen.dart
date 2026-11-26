import 'package:flutter/material.dart';

import 'package:app/features/koleksi/data/models/koleksi_model.dart';
import 'package:app/features/koleksi/presentation/viewmodels/koleksi_viewmodel.dart';
import 'detail_generic_koleksi_screen.dart';
import 'detail_gerbong_maut_screen.dart';
import 'detail_meriam_si_buang_screen.dart';
import 'detail_mobil_dinas_letkol_screen.dart';
import 'detail_perahu_segigir_screen.dart';
import 'detail_senapan_laras_panjang_screen.dart';
import 'detail_senjata_prri_screen.dart';
import 'detail_seragam_tni_screen.dart';
import 'detail_tank_amfibi_screen.dart';

typedef KoleksiLoader = Future<List<KoleksiItem>> Function();

class KoleksiScreen extends StatefulWidget {
  final KoleksiLoader? koleksiLoader;
  final KoleksiViewModel? viewModel;

  const KoleksiScreen({
    super.key,
    this.koleksiLoader,
    this.viewModel,
  });

  @override
  State<KoleksiScreen> createState() => _KoleksiScreenState();
}

class _KoleksiScreenState extends State<KoleksiScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final KoleksiViewModel _viewModel;
  late final bool _ownsViewModel;

  @override
  void initState() {
    super.initState();
    _ownsViewModel = widget.viewModel == null;
    _viewModel = widget.viewModel ?? KoleksiViewModel();
    _fetchKoleksiFromBackend();
  }

  String _resolveLocalAsset(String title, String category) {
    final t = title.toLowerCase();
    if (t.contains('gerbong')) {
      return 'assets/images/collection/menu_gerbong_maut.png';
    }
    if (t.contains('perahu')) {
      return 'assets/images/collection/menu_perahu_segigir.png';
    }
    if (t.contains('meriam')) {
      return 'assets/images/collection/menu_meriam_si_buang.png';
    }
    if (t.contains('amfibi') || t.contains('tank')) {
      return 'assets/images/collection/menu_tank_amfibi.png';
    }
    if (t.contains('senapan')) {
      return 'assets/images/collection/menu_senapan_laras_panjang.png';
    }
    if (t.contains('seragam') || category.toLowerCase() == 'pakaian') {
      return 'assets/images/collection/menu_seragam_tni.png';
    }
    if (t.contains('mobil')) {
      return 'assets/images/collection/menu_mobil_dinas_letkol.png';
    }
    if (t.contains('prri')) {
      return 'assets/images/collection/menu_senjata_penumpasan_prri.png';
    }
    if (t.contains('peta') || category.toLowerCase() == 'dokumen') {
      return 'assets/images/collection/peta_operasi_militer.png';
    }
    if (t.contains('diorama')) {
      return 'assets/images/collection/diorama_pertempuran.png';
    }
    return '';
  }

  List<Map<String, String>> _mapKoleksiItems(List<KoleksiItem> backendItems) {
    final mapped = <Map<String, String>>[];
    for (var i = 0; i < backendItems.length; i++) {
      final item = backendItems[i];
      final fallbackAsset = _resolveLocalAsset(item.nama, item.kategori);
      final rawImage = (item.imageUrl ?? '').trim();
      final imagePath = rawImage.isNotEmpty ? rawImage : fallbackAsset;

      mapped.add({
        'id': item.id > 0 ? 'db-${item.id}' : 'db-idx-$i',
        'kode': item.kode,
        'title': item.nama,
        'subtitle': item.subDeskripsi.isNotEmpty
            ? item.subDeskripsi
            : (item.tahun.isNotEmpty ? item.tahun : 'Koleksi Museum'),
        'category': item.kategori.isNotEmpty ? item.kategori : 'Umum',
        'image': imagePath,
        'fallbackAsset': fallbackAsset,
        'description': (item.deskripsiLengkap ?? '').isNotEmpty
            ? item.deskripsiLengkap!
            : item.subDeskripsi,
        'tahun': item.tahun,
        'lokasi': item.lokasi,
      });
    }
    return mapped;
  }

  Future<void> _fetchKoleksiFromBackend() async {
    await _viewModel.loadKoleksi(loaderOverride: widget.koleksiLoader);
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (_ownsViewModel) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  static const List<Map<String, String>> _fallbackKoleksiItems = [
    {
      'id': 'fallback-gerbong-maut',
      'title': 'Gerbong Maut',
      'subtitle': '1947 - 1948',
      'category': 'Kendaraan',
      'image': 'assets/images/collection/menu_gerbong_maut.png',
      'fallbackAsset': 'assets/images/collection/menu_gerbong_maut.png',
      'description':
          'Gerbong kereta api yang menjadi saksi bisu tragedi Peristiwa Gerbong Maut 1947, di mana 46 pejuang kemerdekaan Indonesia tewas dalam kondisi gerbong yang sangat sesak dan panas.',
      'tahun': '1947',
      'lokasi': 'Halaman Depan',
    },
    {
      'id': 'fallback-meriam-si-buang',
      'title': 'Meriam Si Buang',
      'subtitle': '1945',
      'category': 'Senjata',
      'image': 'assets/images/collection/menu_meriam_si_buang.png',
      'fallbackAsset': 'assets/images/collection/menu_meriam_si_buang.png',
      'description':
          'Meriam bersejarah hasil rampasan tentara sekutu yang digunakan dalam pertempuran kemerdekaan.',
      'tahun': '1945',
      'lokasi': 'Halaman Depan',
    },
    {
      'id': 'fallback-mobil-dinas',
      'title': 'Mobil Dinas Letkol',
      'subtitle': '1947',
      'category': 'Kendaraan',
      'image': 'assets/images/collection/menu_mobil_dinas_letkol.png',
      'fallbackAsset': 'assets/images/collection/menu_mobil_dinas_letkol.png',
      'description':
          'Kendaraan resmi dinas Letnan Kolonel yang digunakan pada masa perjuangan mempertahankan kemerdekaan.',
      'tahun': '1947',
      'lokasi': 'Gedung Utama (Lantai 1)',
    },
    {
      'id': 'fallback-perahu-segigir',
      'title': 'Perahu Segigir',
      'subtitle': 'Perjuangan Laut',
      'category': 'Kendaraan',
      'image': 'assets/images/collection/menu_perahu_segigir.png',
      'fallbackAsset': 'assets/images/collection/menu_perahu_segigir.png',
      'description':
          'Perahu tradisional yang digunakan pejuang kemerdekaan untuk operasi militer dan patroli laut.',
      'tahun': '1946',
      'lokasi': 'Area Pameran Luar',
    },
    {
      'id': 'fallback-senapan-laras',
      'title': 'Senapan Laras Panjang',
      'subtitle': '1945 - 1949',
      'category': 'Senjata',
      'image': 'assets/images/collection/menu_senapan_laras_panjang.png',
      'fallbackAsset': 'assets/images/collection/menu_senapan_laras_panjang.png',
      'description':
          'Senapan laras panjang yang digunakan oleh prajurit pejuang kemerdekaan Republik Indonesia.',
      'tahun': '1945',
      'lokasi': 'Gedung Utama',
    },
    {
      'id': 'fallback-senjata-prri',
      'title': 'Senjata Penumpasan PRRI',
      'subtitle': 'Operasi Militer',
      'category': 'Senjata',
      'image': 'assets/images/collection/menu_senjata_penumpasan_prri.png',
      'fallbackAsset':
          'assets/images/collection/menu_senjata_penumpasan_prri.png',
      'description':
          'Senjata peninggalan operasi militer penumpasan PRRI/Permesta untuk mempertahankan kedaulatan NKRI.',
      'tahun': '1958',
      'lokasi': 'Gedung Utama',
    },
    {
      'id': 'fallback-seragam-tni',
      'title': 'Seragam TNI',
      'subtitle': 'Era Revolusi',
      'category': 'Semua',
      'image': 'assets/images/collection/menu_seragam_tni.png',
      'fallbackAsset': 'assets/images/collection/menu_seragam_tni.png',
      'description':
          'Pakaian dinas resmi dan seragam tempur prajurit TNI pada masa revolusi kemerdekaan fisik.',
      'tahun': '1950',
      'lokasi': 'Gedung Utama (Lantai 2)',
    },
    {
      'id': 'fallback-tank-amfibi',
      'title': 'Tank Amfibi',
      'subtitle': '1945',
      'category': 'Kendaraan',
      'image': 'assets/images/collection/menu_tank_amfibi.png',
      'fallbackAsset': 'assets/images/collection/menu_tank_amfibi.png',
      'description':
          'Kendaraan lapis baja amfibi yang digunakan dalam operasi militer pertempuran di darat dan air.',
      'tahun': '1945',
      'lokasi': 'Halaman Belakang',
    },
  ];

  Widget _buildImageWidget(
    Map<String, String> item, {
    required Color textMuted,
  }) {
    final imagePath = (item['image'] ?? '').trim();
    final fallbackAsset = (item['fallbackAsset'] ?? '').trim();

    Widget buildIconPlaceholder() {
      return const Center(
        child: Icon(
          Icons.museum_outlined,
          color: Color(0xFF727A71),
          size: 32,
        ),
      );
    }

    Widget buildAssetOrPlaceholder(String path) {
      if (path.isEmpty) return buildIconPlaceholder();
      return Image.asset(
        path,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, _, _) => buildIconPlaceholder(),
      );
    }

    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: textMuted.withValues(alpha: 0.6),
              ),
            ),
          );
        },
        errorBuilder: (_, _, _) => buildAssetOrPlaceholder(fallbackAsset),
      );
    }

    return buildAssetOrPlaceholder(
      imagePath.isNotEmpty ? imagePath : fallbackAsset,
    );
  }

  void _openDetailScreen(BuildContext context, Map<String, String> item) {
    void onBack() {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }

    Widget detailScreen = switch (item['title']) {
      'Gerbong Maut' => DetailGerbongMautScreen(onBack: onBack),
      'Perahu Segigir' => DetailPerahuSegigirScreen(onBack: onBack),
      'Meriam Si Buang' => DetailMeriamSiBuangScreen(onBack: onBack),
      'Tank Amfibi' => DetailTankAmfibiScreen(onBack: onBack),
      'Senapan Laras Panjang' => DetailSenapanLarasPanjangScreen(onBack: onBack),
      'Seragam TNI' => DetailSeragamTniScreen(onBack: onBack),
      'Mobil Dinas Letkol' => DetailMobilDinasLetkolScreen(onBack: onBack),
      'Senjata Penumpasan PRRI' => DetailSenjataPrriScreen(onBack: onBack),
      _ => DetailGenericKoleksiScreen(
          title: item['title'] ?? 'Koleksi Museum',
          subtitle: item['subtitle'] ?? '',
          category: item['category'] ?? 'Umum',
          description: item['description'] ?? '',
          tahun: item['tahun'],
          lokasi: item['lokasi'],
          image: item['image'],
          fallbackAsset: item['fallbackAsset'],
          onBack: onBack,
        ),
    };

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => detailScreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color bgCream = Color(0xFFF7F3EA);
    const Color darkGreen = Color(0xFF3F5243);
    const Color goldAccent = Color(0xFFCBB26A);
    const Color cardBg = Colors.white;
    const Color textDark = Color(0xFF2C322B);
    const Color textMuted = Color(0xFF727A71);
    const Color borderLight = Color(0xFFE0E3DF);

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final dynamicItems = _mapKoleksiItems(_viewModel.items);
        final activeCollection = dynamicItems.isNotEmpty
            ? dynamicItems
            : _fallbackKoleksiItems;
        const categories = KoleksiViewModel.categories;
        final safeCategoryIndex = _viewModel.selectedCategoryIndex.clamp(
          0,
          categories.length - 1,
        );
        final selectedCategory = categories[safeCategoryIndex];
        final searchQuery = _viewModel.searchQuery;
        final isLoadingKoleksi = _viewModel.isLoading;
        final loadError = _viewModel.errorMessage;

        // Selalu buat salinan list baru (mutable) sebelum filter & sort
        List<Map<String, String>> filteredItems;
        if (selectedCategory == 'Semua') {
          filteredItems = List<Map<String, String>>.from(activeCollection);
        } else {
          filteredItems = activeCollection
              .where(
                (item) =>
                    (item['category'] ?? '').toLowerCase() ==
                    selectedCategory.toLowerCase(),
              )
              .toList();
        }

        // Filter berdasarkan search query
        if (searchQuery.trim().isNotEmpty) {
          final query = searchQuery.trim().toLowerCase();
          filteredItems = filteredItems
              .where(
                (item) =>
                    (item['title'] ?? '').toLowerCase().contains(query) ||
                    (item['subtitle'] ?? '').toLowerCase().contains(query) ||
                    (item['category'] ?? '').toLowerCase().contains(query) ||
                    (item['lokasi'] ?? '').toLowerCase().contains(query) ||
                    (item['tahun'] ?? '').toLowerCase().contains(query),
              )
              .toList();
        }

        // Urutkan koleksi secara alfabetis (A-Z)
        filteredItems.sort(
          (a, b) => (a['title'] ?? '')
              .toLowerCase()
              .compareTo((b['title'] ?? '').toLowerCase()),
        );

        final titleText = selectedCategory == 'Semua'
            ? 'Benda-Benda Bersejarah'
            : 'Koleksi $selectedCategory Bersejarah';

        final descriptionText = switch (selectedCategory) {
          'Senjata' =>
            'Daftar artefak persenjataan peninggalan masa perjuangan',
          'Kendaraan' =>
            'Daftar kendaraan tempur dan transportasi bersejarah',
          _ => 'Jelajahi berbagai artefak dan benda peninggalan bersejarah',
        };

        final searchHint = selectedCategory == 'Semua'
            ? 'Cari koleksi...'
            : 'Cari ${selectedCategory.toLowerCase()}...';

        return Theme(
          data: Theme.of(context).copyWith(
            textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Lato'),
            primaryTextTheme:
                Theme.of(context).primaryTextTheme.apply(fontFamily: 'Lato'),
          ),
          child: Scaffold(
            backgroundColor: bgCream,
            body: SafeArea(
              child: RefreshIndicator(
                color: darkGreen,
                onRefresh: _fetchKoleksiFromBackend,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Logo
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Color(0xFFE6DDCB)),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: const BoxDecoration(
                                color: darkGreen,
                                shape: BoxShape.circle,
                                border: Border.fromBorderSide(
                                  BorderSide(color: goldAccent, width: 1.5),
                                ),
                              ),
                              child: const Icon(
                                Icons.account_balance,
                                color: goldAccent,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'MUSEUM BRAWIJAYA',
                                style: TextStyle(
                                  fontFamily: 'PlayfairDisplay',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  color: darkGreen,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Muat ulang koleksi',
                              onPressed: isLoadingKoleksi
                                  ? null
                                  : _fetchKoleksiFromBackend,
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(6),
                              icon: Icon(
                                Icons.refresh,
                                size: 18,
                                color: isLoadingKoleksi ? textMuted : darkGreen,
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (isLoadingKoleksi)
                        const LinearProgressIndicator(
                          color: darkGreen,
                          backgroundColor: Color(0xFFE6DDCB),
                          minHeight: 3,
                        ),

                      // Breadcrumb & Dynamic Title Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Text(
                                  'Beranda',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textMuted,
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  size: 18,
                                  color: textMuted,
                                ),
                                const Text(
                                  'Koleksi',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: darkGreen,
                                  ),
                                ),
                                if (selectedCategory != 'Semua') ...[
                                  const Icon(
                                    Icons.chevron_right,
                                    size: 18,
                                    color: textMuted,
                                  ),
                                  Text(
                                    selectedCategory,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: darkGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              titleText,
                              style: const TextStyle(
                                fontFamily: 'PlayfairDisplay',
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: darkGreen,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              descriptionText,
                              style: const TextStyle(
                                fontSize: 14,
                                color: textMuted,
                              ),
                            ),
                            const SizedBox(height: 18),

                            if (loadError != null && dynamicItems.isEmpty)
                              Container(
                                margin: const EdgeInsets.only(bottom: 14),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF8E8),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: goldAccent.withValues(alpha: 0.7),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.cloud_off_outlined,
                                      size: 18,
                                      color: Color(0xFF8A6D1C),
                                    ),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                        'Menampilkan katalog koleksi offline. Ketuk Muat Ulang saat server aktif.',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF6B5314),
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: isLoadingKoleksi
                                          ? null
                                          : _fetchKoleksiFromBackend,
                                      style: TextButton.styleFrom(
                                        foregroundColor: darkGreen,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        minimumSize: const Size(0, 30),
                                      ),
                                      child: const Text(
                                        'Muat Ulang',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Search Bar Dinamis
                            TextField(
                              controller: _searchController,
                              onChanged: _viewModel.setSearchQuery,
                              decoration: InputDecoration(
                                hintText: searchHint,
                                hintStyle: const TextStyle(
                                  color: Color(0xFFA0A7A0),
                                  fontSize: 13,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: textMuted,
                                  size: 20,
                                ),
                                suffixIcon: searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          color: textMuted,
                                          size: 18,
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          _viewModel.setSearchQuery('');
                                        },
                                      )
                                    : null,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                filled: true,
                                fillColor: cardBg,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide:
                                      const BorderSide(color: borderLight),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide:
                                      const BorderSide(color: borderLight),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: darkGreen,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Category Filter Chips (Scrollable agar tidak pernah overflow)
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: List.generate(categories.length,
                                    (index) {
                                  final isSelected =
                                      safeCategoryIndex == index;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: GestureDetector(
                                      onTap: () =>
                                          _viewModel.selectCategory(index),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 7,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              isSelected ? darkGreen : cardBg,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color: isSelected
                                                ? darkGreen
                                                : borderLight,
                                          ),
                                        ),
                                        child: Text(
                                          categories[index],
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected
                                                ? Colors.white
                                                : textDark,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Grid List Koleksi Terfilter
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18.0),
                        child: filteredItems.isEmpty
                            ? Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 48.0),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.search_off,
                                        size: 56,
                                        color:
                                            textMuted.withValues(alpha: 0.5),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Koleksi tidak ditemukan',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        'Coba kata kunci lain atau pilih kategori Semua',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: textMuted,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      GestureDetector(
                                        onTap: () {
                                          _searchController.clear();
                                          _viewModel.resetFilters();
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: darkGreen,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: const Text(
                                            'Tampilkan Semua Koleksi',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : GridView.builder(
                                key: ValueKey(
                                  '$selectedCategory-$searchQuery-${filteredItems.length}',
                                ),
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 300,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  mainAxisExtent: 218,
                                ),
                                itemCount: filteredItems.length,
                                itemBuilder: (context, index) {
                                  final item = filteredItems[index];
                                  return Container(
                                    key: ValueKey(
                                      'koleksi-${item['id'] ?? item['title']}-$index',
                                    ),
                                    decoration: BoxDecoration(
                                      color: cardBg,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFFE6DDCB),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.03,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                            top: Radius.circular(16),
                                          ),
                                          child: Container(
                                            height: 104,
                                            width: double.infinity,
                                            color: bgCream,
                                            child: _buildImageWidget(
                                              item,
                                              textMuted: textMuted,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.all(10),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item['title'] ?? '',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontFamily:
                                                            'PlayfairDisplay',
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: darkGreen,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      item['subtitle'] ?? '',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: textMuted,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                OutlinedButton(
                                                  onPressed: () =>
                                                      _openDetailScreen(
                                                    context,
                                                    item,
                                                  ),
                                                  style:
                                                      OutlinedButton.styleFrom(
                                                    foregroundColor: textDark,
                                                    minimumSize: const Size(
                                                      double.infinity,
                                                      32,
                                                    ),
                                                    tapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                    side: const BorderSide(
                                                      color: Color(0xFFC9D1CB),
                                                      width: 1.5,
                                                    ),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        9,
                                                      ),
                                                    ),
                                                    padding: EdgeInsets.zero,
                                                  ),
                                                  child: const Text(
                                                    'Lihat Detail',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: darkGreen,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
