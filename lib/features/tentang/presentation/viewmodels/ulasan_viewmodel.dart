import 'package:flutter/foundation.dart';

import 'package:app/features/tentang/data/repositories/ulasan_repository.dart';
import 'package:app/features/tentang/data/repositories/ulasan_service.dart';

/// ViewModel untuk mengelola daftar ulasan pengunjung, statistik rating, dan pengiriman ulasan.
class UlasanViewModel extends ChangeNotifier {
  static const int minCommentLength = UlasanService.minCommentLength;

  final UlasanRepository _repository;

  List<UlasanItem> _items = const [];
  UlasanStats _stats = UlasanStats(averageRating: 0, total: 0);
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _usingFallback = false;
  String? _errorMessage;
  bool _disposed = false;

  UlasanViewModel({UlasanRepository? repository})
      : _repository = repository ?? const DefaultUlasanRepository();

  List<UlasanItem> get items => List.unmodifiable(_items);
  UlasanStats get stats => _stats;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  bool get usingFallback => _usingFallback;
  String? get errorMessage => _errorMessage;

  void _safeNotify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<({List<UlasanItem> items, UlasanStats stats})> loadReviews({
    bool silent = false,
    Future<({List<UlasanItem> items, UlasanStats stats})> Function()?
        loaderOverride,
  }) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      _safeNotify();
    }
    try {
      final res = loaderOverride != null
          ? await loaderOverride()
          : await _repository.getAll();
      _items = List<UlasanItem>.from(res.items);
      _stats = res.stats;
      _usingFallback = false;
      _errorMessage = null;
      return res;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _usingFallback = true;
      rethrow;
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  Future<UlasanItem> submitReview({
    required String nama,
    required int rating,
    required String comment,
    String category = 'Kunjungan Umum',
    Future<UlasanItem> Function({
      required String nama,
      required int rating,
      required String comment,
      String category,
    })? submitterOverride,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    _safeNotify();
    try {
      final created = submitterOverride != null
          ? await submitterOverride(
              nama: nama,
              rating: rating,
              comment: comment,
              category: category,
            )
          : await _repository.submitReview(
              nama: nama,
              rating: rating,
              comment: comment,
              category: category,
            );
      _items = [created, ..._items];
      _usingFallback = false;
      final total = _items.length;
      final avg = total == 0
          ? 0.0
          : _items.fold<int>(0, (sum, item) => sum + item.rating) / total;
      _stats = UlasanStats(averageRating: avg, total: total);
      return created;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isSubmitting = false;
      _safeNotify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
