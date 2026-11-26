import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/core/network/api_client.dart';
import 'package:app/features/auth/data/repositories/google_auth_client.dart';
import 'package:app/features/auth/data/models/auth_models.dart';

export 'package:app/features/auth/data/models/auth_models.dart';

class AuthService {
  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'user_data';
  static const String _keyLastTab = 'last_tab_index';
  static const String _keyRememberMe = 'remember_me_flag';
  static const String _keyRememberedEmail = 'remembered_email';

  static const String _googleClientIdEnv =
      String.fromEnvironment('GOOGLE_CLIENT_ID');

  // Simpan user yang sedang login
  static UserModel? currentUser;
  static int lastTab = 0;
  static String? _cachedGoogleClientId;
  static bool _googleConfigFetched = false;

  @visibleForTesting
  static Future<GoogleAuthCredential> Function({String? clientId})?
      debugGoogleSignInOverride;

  /// Mengambil dan menyiapkan konfigurasi Google Client ID lebih awal
  /// (prioritas: --dart-define GOOGLE_CLIENT_ID -> meta tag web/index.html -> GET /api/auth/google/config)
  static Future<String?> preloadGoogleSignInConfig({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _cachedGoogleClientId != null &&
        _cachedGoogleClientId!.isNotEmpty) {
      await GoogleAuthClient.prepare(clientId: _cachedGoogleClientId);
      return _cachedGoogleClientId;
    }

    if (_googleClientIdEnv.trim().isNotEmpty) {
      _cachedGoogleClientId = _googleClientIdEnv.trim();
      _googleConfigFetched = true;
      await GoogleAuthClient.prepare(clientId: _cachedGoogleClientId);
      return _cachedGoogleClientId;
    }

    final metaClientId = GoogleAuthClient.readWebMetaClientId();
    if (metaClientId != null && metaClientId.isNotEmpty) {
      _cachedGoogleClientId = metaClientId;
      _googleConfigFetched = true;
      await GoogleAuthClient.prepare(clientId: _cachedGoogleClientId);
      return _cachedGoogleClientId;
    }

    if (!forceRefresh && _googleConfigFetched) {
      return _cachedGoogleClientId;
    }

    try {
      final res = await ApiClient.get('/auth/google/config');
      final data = res['data'] as Map<String, dynamic>?;
      final serverClientId = (data?['clientId'] as String?)?.trim();
      _googleConfigFetched = true;
      if (serverClientId != null && serverClientId.isNotEmpty) {
        _cachedGoogleClientId = serverClientId;
        await GoogleAuthClient.prepare(clientId: _cachedGoogleClientId);
        return _cachedGoogleClientId;
      }
    } catch (e) {
      debugPrint('Gagal memuat konfigurasi Google OAuth dari backend: $e');
    }

    await GoogleAuthClient.prepare();
    return _cachedGoogleClientId;
  }

  // Notifier untuk reaktivitas auth guard, GoRouter, dan komponen UI Profil/Header
  static final ValueNotifier<UserModel?> authNotifier =
      ValueNotifier<UserModel?>(null);

  static bool get isLoggedIn =>
      currentUser != null &&
      currentUser!.token != null &&
      currentUser!.token!.isNotEmpty;
  static String? get token => currentUser?.token;

  /// Validasi kekuatan kata sandi selaras dengan backend (validatePasswordStrength)
  static String? validatePassword(String password) {
    if (password.isEmpty) return 'Kata sandi wajib diisi';
    if (password.length < 8) return 'Kata sandi minimal 8 karakter';
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Kata sandi harus memiliki minimal 1 huruf besar';
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Kata sandi harus memiliki minimal 1 huruf kecil';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Kata sandi harus memiliki minimal 1 angka';
    }
    return null;
  }

  /// Inisialisasi session dari penyimpanan lokal (SharedPreferences) saat aplikasi dibuka
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      lastTab = prefs.getInt(_keyLastTab) ?? 0;
      final userJsonStr = prefs.getString(_keyUser);
      final savedToken = prefs.getString(_keyToken);

      if (userJsonStr != null && userJsonStr.isNotEmpty) {
        final Map<String, dynamic> userMap =
            jsonDecode(userJsonStr) as Map<String, dynamic>;
        final user = UserModel.fromJson(userMap, token: savedToken);
        currentUser = user;
        authNotifier.value = user;
      } else if (savedToken != null && savedToken.isNotEmpty) {
        final user = UserModel(
          id: 0,
          nama: 'Pengunjung',
          email: '',
          authProvider: 'local',
          token: savedToken,
        );
        currentUser = user;
        authNotifier.value = user;
      }
    } catch (e) {
      debugPrint('Error restoring auth session: $e');
    }
  }

  /// Simpan session pengguna dan token secara persisten di SharedPreferences
  static Future<void> saveSession(UserModel user) async {
    try {
      currentUser = user;
      authNotifier.value = user;
      final prefs = await SharedPreferences.getInstance();
      if (user.token != null && user.token!.isNotEmpty) {
        await prefs.setString(_keyToken, user.token!);
      }
      await prefs.setString(_keyUser, jsonEncode(user.toJson()));
    } catch (e) {
      debugPrint('Error saving auth session: $e');
    }
  }

  /// Simpan tab terakhir yang dikunjungi pengguna
  static Future<void> saveLastTab(int index) async {
    lastTab = index;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyLastTab, index);
    } catch (e) {
      debugPrint('Error saving last tab: $e');
    }
  }

  /// Simpan preferensi Ingat Saya
  static Future<void> saveRememberMe({
    required String email,
    required bool remember,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyRememberMe, remember);
      if (remember) {
        await prefs.setString(_keyRememberedEmail, email);
      } else {
        await prefs.remove(_keyRememberedEmail);
      }
    } catch (e) {
      debugPrint('Error saving remember me: $e');
    }
  }

  /// Ambil email yang tersimpan jika Ingat Saya aktif
  static Future<String?> getRememberedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remember = prefs.getBool(_keyRememberMe) ?? false;
      if (remember) {
        return prefs.getString(_keyRememberedEmail);
      }
    } catch (_) {}
    return null;
  }

  /// Registrasi akun baru pengguna aplikasi ke database MySQL
  static Future<UserModel> register({
    required String nama,
    required String email,
    required String password,
  }) async {
    if (nama.trim().isEmpty) throw ApiException('Nama lengkap wajib diisi');
    if (email.trim().isEmpty) throw ApiException('Alamat email wajib diisi');
    final passError = validatePassword(password);
    if (passError != null) throw ApiException(passError);

    final res = await ApiClient.post('/auth/register', {
      'nama': nama.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
    });

    final data = res['data'] as Map<String, dynamic>;
    String? token = data['token'] as String?;

    // Jika backend belum mengembalikan token saat register, otomatis lakukan login
    if (token == null || token.isEmpty) {
      try {
        final loginRes = await ApiClient.post('/auth/login', {
          'email': email.trim().toLowerCase(),
          'password': password,
        });
        final loginData = loginRes['data'] as Map<String, dynamic>;
        token = loginData['token'] as String?;
      } catch (_) {}
    }

    final user = UserModel.fromJson(data, token: token);
    await saveSession(user);
    return user;
  }

  /// Login pengguna aplikasi dengan email & password
  static Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty) throw ApiException('Alamat email wajib diisi');
    if (password.isEmpty) throw ApiException('Kata sandi wajib diisi');

    Map<String, dynamic> res;
    try {
      res = await ApiClient.post('/auth/login', {
        'email': email.trim().toLowerCase(),
        'password': password,
      });
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        res = await ApiClient.post('/auth/user/login', {
          'email': email.trim().toLowerCase(),
          'password': password,
        });
      } else {
        rethrow;
      }
    }

    final data = res['data'] as Map<String, dynamic>;
    final token = data['token'] as String?;
    final user = UserModel.fromJson(data, token: token);
    await saveSession(user);
    return user;
  }

  /// Login / Register sungguhan dengan Akun Google (OAuth 2.0 Account Chooser -> Verifikasi Backend -> MySQL)
  static Future<UserModel> loginWithGoogle() async {
    String? clientId = _cachedGoogleClientId;

    // Jika belum ada di cache, cek env / meta tag terlebih dahulu secara sinkron (tanpa await agar popup tidak diblokir)
    if (clientId == null || clientId.isEmpty) {
      if (_googleClientIdEnv.trim().isNotEmpty) {
        clientId = _googleClientIdEnv.trim();
        _cachedGoogleClientId = clientId;
      } else {
        final metaId = GoogleAuthClient.readWebMetaClientId();
        if (metaId != null && metaId.isNotEmpty) {
          clientId = metaId;
          _cachedGoogleClientId = clientId;
        }
      }
    }

    // Jika tetap belum tersedia, ambil konfigurasi publik dari backend /api/auth/google/config
    if (clientId == null || clientId.isEmpty) {
      clientId = await preloadGoogleSignInConfig(forceRefresh: true);
    }

    if (kIsWeb &&
        (clientId == null || clientId.isEmpty) &&
        debugGoogleSignInOverride == null) {
      throw const GoogleAuthConfigException(
        'Login dengan Google belum dikonfigurasi. Atur GOOGLE_CLIENT_ID pada file .env UAS_BACKEND lalu restart backend.',
      );
    }

    final signInFn = debugGoogleSignInOverride ?? GoogleAuthClient.signIn;
    final credential = await signInFn(clientId: clientId);

    if (!credential.hasToken) {
      throw ApiException(
        'Token autentikasi Google tidak valid. Silakan coba lagi.',
      );
    }

    final payload = <String, dynamic>{
      if (credential.idToken != null && credential.idToken!.trim().isNotEmpty)
        'idToken': credential.idToken!.trim(),
      if (credential.accessToken != null &&
          credential.accessToken!.trim().isNotEmpty)
        'accessToken': credential.accessToken!.trim(),
    };

    Map<String, dynamic> res;
    try {
      res = await ApiClient.post(
        '/auth/google',
        payload,
        timeout: const Duration(seconds: 15),
      );
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        res = await ApiClient.post(
          '/auth/user/google',
          payload,
          timeout: const Duration(seconds: 15),
        );
      } else {
        rethrow;
      }
    }

    final data = res['data'] as Map<String, dynamic>;
    final userData = data['user'] is Map<String, dynamic>
        ? data['user'] as Map<String, dynamic>
        : data;
    final jwtToken =
        (data['token'] as String?) ?? (userData['token'] as String?);
    if (jwtToken == null || jwtToken.isEmpty) {
      throw ApiException('Token sesi dari server tidak diterima.');
    }

    final user = UserModel.fromJson(userData, token: jwtToken);
    await saveSession(user);
    return user;
  }

  /// Minta instruksi reset kata sandi untuk alamat email
  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    if (email.trim().isEmpty) throw ApiException('Email wajib diisi');

    final res = await ApiClient.post('/auth/forgot-password', {
      'email': email.trim().toLowerCase(),
    });
    return res;
  }

  /// Reset Password - memperbarui password pengguna di database MySQL (via tautan token atau OTP 6 digit)
  static Future<void> resetPassword({
    String token = '',
    String? otp,
    required String newPassword,
    String? email,
  }) async {
    final passError = validatePassword(newPassword);
    if (passError != null) throw ApiException(passError);

    final trimmedToken = token.trim();
    final trimmedOtp = otp?.trim() ?? '';
    final trimmedEmail = email?.trim().toLowerCase() ?? '';

    if (trimmedToken.isEmpty && trimmedOtp.isEmpty) {
      throw ApiException(
        'Kode OTP 6 digit atau tautan verifikasi email wajib disertakan.',
      );
    }

    await ApiClient.post('/auth/reset-password', {
      if (trimmedToken.isNotEmpty) 'token': trimmedToken,
      if (trimmedOtp.isNotEmpty) 'otp': trimmedOtp,
      if (trimmedEmail.isNotEmpty) 'email': trimmedEmail,
      'newPassword': newPassword,
    });
  }

  /// Update Profile pengguna di database MySQL (nama, email, avatarUrl, atau password)
  static Future<UserModel> updateProfile({
    int? userId,
    String? nama,
    String? email,
    String? currentPassword,
    String? newPassword,
    String? avatarUrl,
    bool clearAvatar = false,
  }) async {
    if (!isLoggedIn) {
      throw ApiException('Sesi berakhir. Silakan login kembali.');
    }

    if (newPassword != null && newPassword.isNotEmpty) {
      final passError = validatePassword(newPassword);
      if (passError != null) throw ApiException(passError);
    }

    final payload = <String, dynamic>{
      'userId': ?userId,
      if (nama != null) 'nama': nama.trim(),
      if (email != null) 'email': email.trim().toLowerCase(),
      if (currentPassword != null && currentPassword.isNotEmpty)
        'currentPassword': currentPassword,
      if (newPassword != null && newPassword.isNotEmpty)
        'newPassword': newPassword,
      if (clearAvatar) 'avatarUrl': null else 'avatarUrl': ?avatarUrl,
    };

    Map<String, dynamic> res;
    try {
      res = await ApiClient.put('/auth/profile', payload);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        res = await ApiClient.put('/auth/user/profile', payload);
      } else {
        rethrow;
      }
    }

    final data = res['data'] as Map<String, dynamic>;
    final userData = data['user'] is Map<String, dynamic>
        ? data['user'] as Map<String, dynamic>
        : data;
    final nextToken = (data['token'] as String?) ?? currentUser?.token;
    final user = UserModel.fromJson(userData, token: nextToken);
    await saveSession(user);
    return user;
  }

  /// Ubah Kata Sandi pengguna langsung ke endpoint backend & database MySQL
  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    String? confirmPassword,
  }) async {
    if (!isLoggedIn) {
      throw ApiException('Sesi berakhir. Silakan login kembali.');
    }

    final passError = validatePassword(newPassword);
    if (passError != null) throw ApiException(passError);

    if (confirmPassword != null && newPassword != confirmPassword) {
      throw ApiException('Konfirmasi kata sandi baru tidak cocok');
    }

    final payload = {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
      'confirmPassword': ?confirmPassword,
    };

    try {
      await ApiClient.put('/auth/change-password', payload);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        // Fallback ke endpoint update profile jika server memakai route lama
        await updateProfile(
          userId: currentUser?.id,
          currentPassword: currentPassword,
          newPassword: newPassword,
        );
      } else {
        rethrow;
      }
    }
  }

  /// Upload Foto Profil ke Vercel Blob melalui endpoint API backend (/api/storage/avatar)
  /// Kredensial penyimpanan cloud hanya dikelola di sisi server backend.
  static Future<UserModel> uploadAvatar({
    required Uint8List imageBytes,
    required String filename,
    required String mimeType,
  }) async {
    final activeToken = AuthService.token;
    if (activeToken == null || activeToken.isEmpty) {
      throw ApiException('Anda harus login terlebih dahulu');
    }

    final uri = Uri.parse('$kBaseUrl/storage/avatar');
    http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $activeToken',
              'Content-Type': mimeType,
              'Accept': 'application/json',
            },
            body: imageBytes,
          )
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw ApiException(
        'Waktu unggah habis. Periksa koneksi internet Anda lalu coba lagi.',
      );
    } on http.ClientException {
      throw ApiException(
        'Tidak dapat terhubung ke server backend untuk mengunggah foto.',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>;
      final avatarUrl = data['avatarUrl'] as String?;
      final userData = data['user'] as Map<String, dynamic>?;

      UserModel updated;
      if (userData != null) {
        updated = UserModel.fromJson(userData, token: activeToken);
      } else if (currentUser != null) {
        updated = currentUser!.copyWith(avatarUrl: avatarUrl);
      } else {
        throw ApiException('Gagal memproses data profil');
      }

      await saveSession(updated);
      return updated;
    } else {
      String errorMessage = 'Gagal mengunggah foto profil';
      try {
        final errJson = jsonDecode(response.body) as Map<String, dynamic>;
        if (errJson['message'] is String &&
            (errJson['message'] as String).isNotEmpty) {
          errorMessage = errJson['message'] as String;
        }
      } catch (_) {}
      throw ApiException(errorMessage, statusCode: response.statusCode);
    }
  }

  /// Hapus foto profil pengguna di MySQL & sinkronkan ke SharedPreferences
  static Future<UserModel> removeAvatar() async {
    final activeToken = AuthService.token;
    if (activeToken == null || activeToken.isEmpty) {
      throw ApiException('Anda harus login terlebih dahulu');
    }

    try {
      final res = await ApiClient.delete('/storage/avatar');
      final data = res['data'] as Map<String, dynamic>?;
      final userData = data?['user'] as Map<String, dynamic>?;
      final updated = userData != null
          ? UserModel.fromJson(userData, token: activeToken)
          : currentUser!.copyWith(clearAvatarUrl: true);
      await saveSession(updated);
      return updated;
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        return updateProfile(userId: currentUser?.id, clearAvatar: true);
      }
      rethrow;
    }
  }

  /// Ambil data profil terbaru dari backend & sinkronkan ke SharedPreferences
  static Future<UserModel?> fetchMe() async {
    if (!isLoggedIn) return null;
    try {
      final res = await ApiClient.get('/auth/me');
      final data = res['data'] as Map<String, dynamic>?;
      if (data != null) {
        final updated = UserModel.fromJson(data, token: token);
        await saveSession(updated);
        return updated;
      }
    } catch (_) {}
    return currentUser;
  }

  /// Logout dan bersihkan sesi tersimpan (termasuk sesi Google Sign-In)
  static Future<void> logout() async {
    currentUser = null;
    authNotifier.value = null;
    try {
      await GoogleAuthClient.signOut();
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
      await prefs.remove(_keyUser);
      await prefs.remove(_keyLastTab);
    } catch (e) {
      debugPrint('Error clearing auth session: $e');
    }
  }
}
