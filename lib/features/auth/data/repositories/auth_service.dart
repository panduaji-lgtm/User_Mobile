import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/core/network/api_client.dart';

class UserModel {
  final int id;
  final String nama;
  final String email;
  final String authProvider;
  final String? avatarUrl;

  UserModel({
    required this.id,
    required this.nama,
    required this.email,
    required this.authProvider,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as int,
    nama: json['nama'] as String,
    email: json['email'] as String,
    authProvider: json['auth_provider'] as String? ?? 'local',
    avatarUrl: json['avatar_url'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nama': nama,
    'email': email,
    'auth_provider': authProvider,
    if (avatarUrl != null) 'avatar_url': avatarUrl,
  };
}

class AuthService {
  static const _keyRememberMe = 'auth_remember_me';
  static const _keySavedUser = 'auth_saved_user';

  // Simpan user yang sedang login
  static UserModel? currentUser;

  /// Simpan atau hapus sesi login di penyimpanan lokal
  static Future<void> saveSession(UserModel user, {required bool rememberMe}) async {
    final prefs = await SharedPreferences.getInstance();
    if (rememberMe) {
      await prefs.setBool(_keyRememberMe, true);
      await prefs.setString(_keySavedUser, jsonEncode(user.toJson()));
    } else {
      await prefs.remove(_keyRememberMe);
      await prefs.remove(_keySavedUser);
    }
  }

  /// Pulihkan sesi login jika pengguna sebelumnya memilih "Ingat saya"
  static Future<UserModel?> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remember = prefs.getBool(_keyRememberMe) ?? false;
      if (!remember) return null;

      final rawUser = prefs.getString(_keySavedUser);
      if (rawUser == null || rawUser.isEmpty) return null;

      final decoded = jsonDecode(rawUser) as Map<String, dynamic>;
      final user = UserModel.fromJson(decoded);
      currentUser = user;
      return user;
    } catch (_) {
      return null;
    }
  }

  /// Registrasi akun baru pengguna aplikasi
  static Future<UserModel> register({
    required String nama,
    required String email,
    required String password,
  }) async {
    if (nama.trim().isEmpty) throw ApiException('Nama lengkap wajib diisi');
    if (email.trim().isEmpty) throw ApiException('Alamat email wajib diisi');
    if (password.length < 6)
      throw ApiException('Kata sandi minimal 6 karakter');

    final res = await ApiClient.post('/auth/register', {
      'nama': nama.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
    });

    // Karena backend mengirim langsung data user di dalam 'data',
    // kita parsing langsung tanpa mencari key 'user' lagi.
    final data = res['data'] as Map<String, dynamic>;
    final user = UserModel.fromJson(data);
    currentUser = user;
    return user;
  }

  /// Login pengguna aplikasi dengan email & password
  static Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty) throw ApiException('Alamat email wajib diisi');
    if (password.isEmpty) throw ApiException('Kata sandi wajib diisi');

    final res = await ApiClient.post('/auth/user/login', {
      'email': email.trim().toLowerCase(),
      'password': password,
    });

    // Ubah bagian ini agar langsung membaca dari 'data'
    final data = res['data'] as Map<String, dynamic>;
    final user = UserModel.fromJson(data);
    currentUser = user;
    return user;
  }

  /// Login / Register dengan Akun Google
  static Future<UserModel> loginWithGoogle({
    String? email,
    String? nama,
    String? avatarUrl,
  }) async {
    // Parameter opsional untuk simulasi akun Google
    final targetEmail = email ?? 'pengunjung.google@gmail.com';
    final targetNama = nama ?? 'Pengunjung Google';

    final res = await ApiClient.post('/auth/google', {
      'email': targetEmail.toLowerCase(),
      'nama': targetNama,
      'avatarUrl':
          avatarUrl ??
          'https://api.dicebear.com/7.x/avataaars/svg?seed=$targetEmail',
    });

    final data = res['data'] as Map<String, dynamic>;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    currentUser = user;
    return user;
  }

  /// Minta instruksi reset kata sandi untuk alamat email
  static Future<void> forgotPassword({required String email}) async {
    if (email.trim().isEmpty) throw ApiException('Email wajib diisi');

    await ApiClient.post('/auth/forgot-password', {
      'email': email.trim().toLowerCase(),
    });
  }

  /// Reset Password - gunakan token untuk mereset password
  static Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    if (newPassword.length < 6)
      throw ApiException('Kata sandi minimal 6 karakter');

    await ApiClient.post('/auth/reset-password', {
      'token': token,
      'newPassword': newPassword,
    });
  }

  /// Update Profile
  static Future<UserModel> updateProfile({
    required int userId,
    String? nama,
    String? email,
    String? currentPassword,
    String? newPassword,
  }) async {
    final res = await ApiClient.put('/auth/user/profile', {
      'userId': userId,
      if (nama != null) 'nama': nama,
      if (email != null) 'email': email,
      if (currentPassword != null) 'currentPassword': currentPassword,
      if (newPassword != null) 'newPassword': newPassword,
    });

    final data = res['data'] as Map<String, dynamic>;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    currentUser = user;
    return user;
  }

  /// Logout
  static Future<void> logout() async {
    currentUser = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyRememberMe);
      await prefs.remove(_keySavedUser);
    } catch (_) {}
  }
}
