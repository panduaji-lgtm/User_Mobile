import 'package:flutter/foundation.dart';
import 'package:app/features/tiket/data/repositories/tiket_service.dart';

class TiketViewModel extends ChangeNotifier {
  int _currentStep = 0;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedSesi = '08:00 - 10:00';
  
  int _qtyDewasa = 1;
  int _qtyPelajar = 0;
  int _qtyWna = 0;
  String _paymentMethod = 'QRIS';

  List<TiketCategory> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  int get currentStep => _currentStep;
  DateTime get selectedDate => _selectedDate;
  String get selectedSesi => _selectedSesi;
  int get qtyDewasa => _qtyDewasa;
  int get qtyPelajar => _qtyPelajar;
  int get qtyWna => _qtyWna;
  String get paymentMethod => _paymentMethod;
  List<TiketCategory> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalTiket => _qtyDewasa + _qtyPelajar + _qtyWna;

  int get priceDewasa => _getPriceByCategory('UMUM / DEWASA', 10000);
  int get pricePelajar => _getPriceByCategory('PELAJAR / MAHASISWA', 5000);
  int get priceWna => _getPriceByCategory('MANCANEGARA', 25000);

  int get totalBiaya =>
      (_qtyDewasa * priceDewasa) +
      (_qtyPelajar * pricePelajar) +
      (_qtyWna * priceWna);

  int _getPriceByCategory(String title, int fallbackPrice) {
    if (_categories.isEmpty) return fallbackPrice;
    final found = _categories.firstWhere(
      (c) => c.title.toUpperCase().contains(title.toUpperCase()),
      orElse: () => TiketCategory(
        id: 0,
        badge: '',
        badgeBg: '',
        badgeColor: '',
        title: title,
        price: fallbackPrice,
        kuota: 100,
        status: 'Aktif',
      ),
    );
    return found.price;
  }

  void setStep(int step) {
    _currentStep = step;
    notifyListeners();
  }

  void setDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setSesi(String sesi) {
    _selectedSesi = sesi;
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  void updateQtyDewasa(int delta) {
    final next = _qtyDewasa + delta;
    if (next >= 0 && (next + _qtyPelajar + _qtyWna) <= 50) {
      _qtyDewasa = next;
      notifyListeners();
    }
  }

  void updateQtyPelajar(int delta) {
    final next = _qtyPelajar + delta;
    if (next >= 0 && (_qtyDewasa + next + _qtyWna) <= 50) {
      _qtyPelajar = next;
      notifyListeners();
    }
  }

  void updateQtyWna(int delta) {
    final next = _qtyWna + delta;
    if (next >= 0 && (_qtyDewasa + _qtyPelajar + next) <= 50) {
      _qtyWna = next;
      notifyListeners();
    }
  }

  Future<void> fetchCategories() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await TiketService.getCategories();
      _categories = res;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
