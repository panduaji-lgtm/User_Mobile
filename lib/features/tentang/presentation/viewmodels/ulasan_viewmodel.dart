import 'package:flutter/foundation.dart';
import 'package:app/features/tentang/data/repositories/ulasan_service.dart';

class UlasanViewModel extends ChangeNotifier {
  List<UlasanItem> _ulasanList = [];
  UlasanStats? _stats;
  bool _isLoading = false;
  String? _errorMessage;

  List<UlasanItem> get ulasanList => _ulasanList;
  UlasanStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchUlasan() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await UlasanService.getAll();
      _ulasanList = res.items;
      _stats = res.stats;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> kirimUlasan({
    required String nama,
    required String comment,
    required int rating,
    String category = 'Kunjungan Umum',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await UlasanService.submitReview(
        nama: nama,
        comment: comment,
        rating: rating,
        category: category,
      );
      await fetchUlasan();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
