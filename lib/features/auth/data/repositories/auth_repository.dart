import 'dart:typed_data';

import 'package:app/features/auth/data/repositories/auth_service.dart';

/// Kontrak repository untuk autentikasi, Google OAuth, profil, dan sesi pengguna.
abstract interface class AuthRepository {
  UserModel? get currentUser;
  bool get isLoggedIn;

  Future<void> init();
  Future<String?> preloadGoogleSignInConfig({bool forceRefresh = false});
  Future<String?> getRememberedEmail();
  Future<void> saveRememberMe({required String email, required bool remember});
  Future<void> saveLastTab(int index);
  String? validatePassword(String password);
  Future<UserModel> login({required String email, required String password});
  Future<UserModel> register({
    required String nama,
    required String email,
    required String password,
  });
  Future<UserModel> loginWithGoogle();
  Future<Map<String, dynamic>> forgotPassword({required String email});
  Future<void> resetPassword({
    String token = '',
    String? otp,
    required String newPassword,
    String? email,
  });
  Future<UserModel> updateProfile({
    int? userId,
    String? nama,
    String? email,
    String? currentPassword,
    String? newPassword,
    String? avatarUrl,
    bool clearAvatar = false,
  });
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    String? confirmPassword,
  });
  Future<UserModel> uploadAvatar({
    required Uint8List imageBytes,
    required String filename,
    required String mimeType,
  });
  Future<UserModel> removeAvatar();
  Future<UserModel?> fetchMe();
  Future<void> logout();
}

/// Implementasi default [AuthRepository] berbasis [AuthService].
class DefaultAuthRepository implements AuthRepository {
  const DefaultAuthRepository();

  @override
  UserModel? get currentUser => AuthService.currentUser;

  @override
  bool get isLoggedIn => AuthService.isLoggedIn;

  @override
  Future<void> init() => AuthService.init();

  @override
  Future<String?> preloadGoogleSignInConfig({bool forceRefresh = false}) =>
      AuthService.preloadGoogleSignInConfig(forceRefresh: forceRefresh);

  @override
  Future<String?> getRememberedEmail() => AuthService.getRememberedEmail();

  @override
  Future<void> saveRememberMe({
    required String email,
    required bool remember,
  }) =>
      AuthService.saveRememberMe(email: email, remember: remember);

  @override
  Future<void> saveLastTab(int index) => AuthService.saveLastTab(index);

  @override
  String? validatePassword(String password) =>
      AuthService.validatePassword(password);

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) =>
      AuthService.login(email: email, password: password);

  @override
  Future<UserModel> register({
    required String nama,
    required String email,
    required String password,
  }) =>
      AuthService.register(nama: nama, email: email, password: password);

  @override
  Future<UserModel> loginWithGoogle() => AuthService.loginWithGoogle();

  @override
  Future<Map<String, dynamic>> forgotPassword({required String email}) =>
      AuthService.forgotPassword(email: email);

  @override
  Future<void> resetPassword({
    String token = '',
    String? otp,
    required String newPassword,
    String? email,
  }) =>
      AuthService.resetPassword(
        token: token,
        otp: otp,
        newPassword: newPassword,
        email: email,
      );

  @override
  Future<UserModel> updateProfile({
    int? userId,
    String? nama,
    String? email,
    String? currentPassword,
    String? newPassword,
    String? avatarUrl,
    bool clearAvatar = false,
  }) =>
      AuthService.updateProfile(
        userId: userId,
        nama: nama,
        email: email,
        currentPassword: currentPassword,
        newPassword: newPassword,
        avatarUrl: avatarUrl,
        clearAvatar: clearAvatar,
      );

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    String? confirmPassword,
  }) =>
      AuthService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

  @override
  Future<UserModel> uploadAvatar({
    required Uint8List imageBytes,
    required String filename,
    required String mimeType,
  }) =>
      AuthService.uploadAvatar(
        imageBytes: imageBytes,
        filename: filename,
        mimeType: mimeType,
      );

  @override
  Future<UserModel> removeAvatar() => AuthService.removeAvatar();

  @override
  Future<UserModel?> fetchMe() => AuthService.fetchMe();

  @override
  Future<void> logout() => AuthService.logout();
}
