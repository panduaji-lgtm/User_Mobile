import 'package:flutter/material.dart';

import 'package:app/features/koleksi/presentation/views/detail_gerbong_maut_screen.dart';
import 'package:app/features/koleksi/presentation/views/detail_meriam_si_buang_screen.dart';
import 'package:app/features/koleksi/presentation/views/detail_mobil_dinas_letkol_screen.dart';
import 'package:app/features/koleksi/presentation/views/detail_perahu_segigir_screen.dart';
import 'package:app/features/koleksi/presentation/views/detail_senapan_laras_panjang_screen.dart';
import 'package:app/features/koleksi/presentation/views/detail_senjata_prri_screen.dart';
import 'package:app/features/koleksi/presentation/views/detail_seragam_tni_screen.dart';
import 'package:app/features/koleksi/presentation/views/detail_tank_amfibi_screen.dart';

import 'package:app/features/koleksi/presentation/views/detail_generic_koleksi_screen.dart';
import 'package:app/features/koleksi/presentation/viewmodels/koleksi_viewmodel.dart';

class KoleksiScreen extends StatefulWidget {
  const KoleksiScreen({super.key});

  @override
  State<KoleksiScreen> createState() => _KoleksiScreenState();
}

class _KoleksiScreenState extends State<KoleksiScreen> {
  late final KoleksiViewModel _viewModel;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = KoleksiViewModel();
    _viewModel.fetchKoleksi();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
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
        final categories = _viewModel.categories;
        final selectedCategoryIndex = _viewModel.selectedCategoryIndex;
        final selectedCategory = categories[selectedCategoryIndex];
        final filteredItems = _viewModel.filteredItems;

        String titleText = selectedCategory == 'Semua'
            ? 'Benda-Benda Bersejarah'
            : 'Koleksi $selectedCategory Bersejarah';

        String descriptionText = selectedCategory == 'Senjata'
            ? 'Daftar artefak persenjataan peninggalan masa perjuangan'
            : selectedCategory == 'Kendaraan'
            ? 'Daftar kendaraan tempur dan transportasi bersejarah'
            : 'Jelajahi berbagai artefak dan benda peninggalan bersejarah';

        String searchHint = selectedCategory == 'Semua'
            ? 'Cari koleksi...'
            : 'Cari ${selectedCategory.toLowerCase()}...';

        return Theme(
          data: Theme.of(context).copyWith(
            textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Lato'),
            primaryTextTheme: Theme.of(context).primaryTextTheme.apply(fontFamily: 'Lato'),
          ),
          child: Scaffold(
            backgroundColor: bgCream,
            body: SafeArea(
              child: SingleChildScrollView(
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
                          const Text(
                            'MUSEUM BRAWIJAYA',
                            style: TextStyle(
                              fontFamily: 'PlayfairDisplay',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: darkGreen,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Breadcrumb & Dynamic Title Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              const Text(
                                'Beranda',
                                style: TextStyle(fontSize: 13, color: textMuted),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                size: 18,
                                color: textMuted,
                              ),
                              const Text(
                                'Koleksi',
                                style: TextStyle(fontSize: 13, color: darkGreen),
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
                            style: const TextStyle(fontSize: 14, color: textMuted),
                          ),
                          const SizedBox(height: 24),

                          // Search Bar Dinamis
                          TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              _viewModel.setSearchQuery(value);
                            },
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
                              suffixIcon: _viewModel.searchQuery.isNotEmpty
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
                                vertical: 16,
                              ),
                              filled: true,
                              fillColor: cardBg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: borderLight),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: borderLight),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xFF3F5243),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Category Filter Chips
                          Row(
                            children: List.generate(categories.length, (index) {
                              final isSelected = selectedCategoryIndex == index;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: GestureDetector(
                                  onTap: () {
                                    _viewModel.setCategory(index);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected ? darkGreen : cardBg,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected ? darkGreen : borderLight,
                                      ),
                                    ),
                                    child: Text(
                                      categories[index],
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected ? Colors.white : textDark,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Grid List Koleksi Terfilter
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: filteredItems.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 48.0),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 56,
                                      color: const Color(0xFF727A71).withOpacity(0.5),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Koleksi tidak ditemukan',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2C322B),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Coba kata kunci lain atau hapus pencarian',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF727A71),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    GestureDetector(
                                      onTap: () {
                                        _searchController.clear();
                                        _viewModel.setSearchQuery('');
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF3F5243),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Text(
                                          'Hapus Pencarian',
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
                              key: ValueKey('$selectedCategory-${_viewModel.searchQuery}'),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 300,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: 204,
                        ),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return Container(
                        key: ValueKey(item['image']),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE6DDCB)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                              child: Container(
                                height: 104,
                                width: double.infinity,
                                color: const Color(0xFFF7F3EA),
                                child: (item['image'] != null && item['image']!.startsWith('http'))
                                    ? Image.network(
                                        item['image']!,
                                        fit: BoxFit.contain,
                                        filterQuality: FilterQuality.high,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Center(
                                            child: Icon(
                                              Icons.museum_outlined,
                                              color: textMuted,
                                              size: 32,
                                            ),
                                          );
                                        },
                                      )
                                    : Image.asset(
                                        item['image'] != null && item['image']!.isNotEmpty
                                            ? item['image']!
                                            : 'assets/images/collection/menu_gerbong_maut.png',
                                        fit: BoxFit.contain,
                                        filterQuality: FilterQuality.high,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Center(
                                            child: Icon(
                                              Icons.museum_outlined,
                                              color: textMuted,
                                              size: 32,
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['title'] ?? '',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontFamily: 'PlayfairDisplay',
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: darkGreen,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item['subtitle'] ?? '',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                    OutlinedButton(
                                      onPressed: () {
                                        void onBack() {
                                          Navigator.of(context).pop();
                                        }

                                        Widget? detailScreen =
                                            switch (item['title']) {
                                              'Gerbong Maut' =>
                                                DetailGerbongMautScreen(
                                                  onBack: onBack,
                                                ),
                                              'Perahu Segigir' =>
                                                DetailPerahuSegigirScreen(
                                                  onBack: onBack,
                                                ),
                                              'Meriam Si Buang' =>
                                                DetailMeriamSiBuangScreen(
                                                  onBack: onBack,
                                                ),
                                              'Tank Amfibi' =>
                                                DetailTankAmfibiScreen(
                                                  onBack: onBack,
                                                ),
                                              'Senapan Laras Panjang' =>
                                                DetailSenapanLarasPanjangScreen(
                                                  onBack: onBack,
                                                ),
                                              'Seragam TNI' =>
                                                DetailSeragamTniScreen(
                                                  onBack: onBack,
                                                ),
                                              'Mobil Dinas Letkol' =>
                                                DetailMobilDinasLetkolScreen(
                                                  onBack: onBack,
                                                ),
                                              'Senjata Penumpasan PRRI' =>
                                                DetailSenjataPrriScreen(
                                                  onBack: onBack,
                                                ),
                                              _ => null,
                                            };

                                        // Fallback ke DetailGenericKoleksiScreen untuk koleksi baru yang ditambahkan admin
                                        detailScreen ??= DetailGenericKoleksiScreen(
                                          title: item['title'] ?? 'Koleksi Museum',
                                          subtitle: item['subtitle'] ?? '',
                                          category: item['category'] ?? 'Umum',
                                          description: item['description'] ?? '',
                                          tahun: item['tahun'],
                                          lokasi: item['lokasi'],
                                          image: item['image'],
                                          onBack: onBack,
                                        );

                                        Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) => detailScreen!,
                                          ),
                                        );
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: textDark,
                                        minimumSize: const Size(
                                          double.infinity,
                                          32,
                                        ),
                                        side: const BorderSide(
                                          color: Color(0xFFC9D1CB),
                                          width: 1.5,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            9,
                                          ),
                                        ),
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: const Text(
                                        'Lihat Detail',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
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
    );
      },
    );
  }
}
