import 'package:flutter/foundation.dart';

import 'package:app/data/repositories/auth_repository.dart';
import 'package:app/data/services/auth_service.dart';

/// ViewModel untuk mengelola state autentikasi, Google OAuth, dan profil pengguna.
class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repository;

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isUploadingAvatar = false;
  String? _errorMessage;
  bool _disposed = false;

  AuthViewModel({AuthRepository? repository})
      : _repository = repository ?? const DefaultAuthRepository() {
    AuthService.authNotifier.addListener(_onAuthChanged);
  }

  UserModel? get currentUser => _repository.currentUser;
  bool get isLoggedIn => _repository.isLoggedIn;
  bool get isLoading => _isLoading;
  bool get isGoogleLoading => _isGoogleLoading;
  bool get isUploadingAvatar => _isUploadingAvatar;
  bool get isBusy => _isLoading || _isGoogleLoading || _isUploadingAvatar;
  String? get errorMessage => _errorMessage;

  void _safeNotify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  void _onAuthChanged() {
    _safeNotify();
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      _safeNotify();
    }
  }

  Future<void> init() => _repository.init();

  Future<String?> preloadGoogleSignInConfig({bool forceRefresh = false}) =>
      _repository.preloadGoogleSignInConfig(forceRefresh: forceRefresh);

  Future<String?> getRememberedEmail() => _repository.getRememberedEmail();

  Future<void> saveRememberMe({
    required String email,
    required bool remember,
  }) =>
      _repository.saveRememberMe(email: email, remember: remember);

  Future<void> saveLastTab(int index) => _repository.saveLastTab(index);

  String? validatePassword(String password) =>
      _repository.validatePassword(password);

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();
    try {
      return await _repository.login(email: email, password: password);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  Future<UserModel> register({
    required String nama,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();
    try {
      return await _repository.register(
        nama: nama,
        email: email,
        password: password,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  Future<UserModel> loginWithGoogle() async {
    _isGoogleLoading = true;
    _errorMessage = null;
    _safeNotify();
    try {
      return await _repository.loginWithGoogle();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isGoogleLoading = false;
      _safeNotify();
    }
  }

  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();
    try {
      return await _repository.forgotPassword(email: email);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  Future<void> resetPassword({
    String token = '',
    String? otp,
    required String newPassword,
    String? email,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();
    try {
      await _repository.resetPassword(
        token: token,
        otp: otp,
        newPassword: newPassword,
        email: email,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  Future<UserModel> updateProfile({
    int? userId,
    String? nama,
    String? email,
    String? currentPassword,
    String? newPassword,
    String? avatarUrl,
    bool clearAvatar = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();
    try {
      return await _repository.updateProfile(
        userId: userId,
        nama: nama,
        email: email,
        currentPassword: currentPassword,
        newPassword: newPassword,
        avatarUrl: avatarUrl,
        clearAvatar: clearAvatar,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    String? confirmPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();
    try {
      await _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  Future<UserModel> uploadAvatar({
    required Uint8List imageBytes,
    required String filename,
    required String mimeType,
  }) async {
    _isUploadingAvatar = true;
    _errorMessage = null;
    _safeNotify();
    try {
      return await _repository.uploadAvatar(
        imageBytes: imageBytes,
        filename: filename,
        mimeType: mimeType,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isUploadingAvatar = false;
      _safeNotify();
    }
  }

  Future<UserModel> removeAvatar() async {
    _isUploadingAvatar = true;
    _errorMessage = null;
    _safeNotify();
    try {
      return await _repository.removeAvatar();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isUploadingAvatar = false;
      _safeNotify();
    }
  }

  Future<UserModel?> fetchMe() => _repository.fetchMe();

  Future<void> logout() => _repository.logout();

  @override
  void dispose() {
    _disposed = true;
    AuthService.authNotifier.removeListener(_onAuthChanged);
    super.dispose();
  }
}
