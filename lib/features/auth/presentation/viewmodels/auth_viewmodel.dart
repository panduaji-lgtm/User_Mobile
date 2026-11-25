import 'package:flutter/foundation.dart';
import 'package:app/features/auth/data/repositories/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _currentUser;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser ?? AuthService.currentUser;
  bool get isAuthenticated => currentUser != null;

  Future<bool> login(String email, String password, {bool rememberMe = false}) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || password.isEmpty) {
      _errorMessage = 'Harap masukkan email dan kata sandi Anda';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await AuthService.login(email: cleanEmail, password: password);
      await AuthService.saveSession(user, rememberMe: rememberMe);
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String nama,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await AuthService.register(
        nama: nama,
        email: email,
        password: password,
      );
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithGoogle(String email, {bool rememberMe = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await AuthService.loginWithGoogle(email: email);
      await AuthService.saveSession(user, rememberMe: rememberMe);
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await AuthService.logout();
    _currentUser = null;
    notifyListeners();
  }
}

