import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:app/core/network/api_client.dart';
import 'package:app/models/auth_models.dart';

class GoogleAuthClient {
  static GoogleSignIn? _lastInstance;

  static String? readWebMetaClientId() => null;

  static Future<void> prepare({String? clientId}) async {
    // Pada Android/iOS, instance GoogleSignIn disiapkan saat sign-in.
  }

  static GoogleSignIn _createClient({String? clientId}) {
    final trimmed = clientId?.trim();
    return GoogleSignIn(
      scopes: const ['email', 'profile'],
      serverClientId: (trimmed != null && trimmed.isNotEmpty) ? trimmed : null,
    );
  }

  /// Membuka pemilih akun Google native (Android / iOS) dan mengembalikan token untuk diverifikasi backend.
  static Future<GoogleAuthCredential> signIn({String? clientId}) async {
    final googleSignIn = _createClient(clientId: clientId);
    _lastInstance = googleSignIn;

    try {
      // Sign out sesi Google lokal sebelumnya agar layar pemilihan akun (account chooser) selalu muncul
      try {
        await googleSignIn.signOut();
      } catch (_) {}

      final account = await googleSignIn.signIn();
      if (account == null) {
        throw const GoogleAuthCancelledException(
          'Login dengan Google dibatalkan.',
        );
      }

      final auth = await account.authentication;
      final credential = GoogleAuthCredential(
        idToken: auth.idToken,
        accessToken: auth.accessToken,
        email: account.email,
        displayName: account.displayName,
        photoUrl: account.photoUrl,
      );

      if (!credential.hasToken) {
        throw ApiException(
          'Token Google tidak diterima dari perangkat. Pastikan OAuth Client ID & SHA-1 Android/iOS sudah dikonfigurasi di Google Cloud Console.',
        );
      }

      return credential;
    } on GoogleAuthCancelledException {
      rethrow;
    } on ApiException {
      rethrow;
    } on PlatformException catch (e) {
      final code = e.code.toLowerCase();
      final msg = (e.message ?? '').toLowerCase();
      if (code.contains('cancel') ||
          msg.contains('canceled') ||
          msg.contains('cancelled')) {
        throw const GoogleAuthCancelledException(
          'Login dengan Google dibatalkan.',
        );
      }
      if (code.contains('network') || msg.contains('network')) {
        throw ApiException(
          'Gagal menghubungi Google. Periksa koneksi internet Anda.',
        );
      }
      if (msg.contains('apiexception: 10') || code.contains('sign_in_failed')) {
        throw ApiException(
          'Konfigurasi Google Sign-In mobile belum lengkap (Developer Error / SHA-1 atau Client ID belum terdaftar di Google Cloud Console).',
        );
      }
      throw ApiException(
        e.message?.isNotEmpty == true
            ? 'Gagal masuk dengan Google: ${e.message}'
            : 'Gagal masuk dengan Google (${e.code}).',
      );
    } catch (e) {
      throw ApiException('Gagal masuk dengan Google: $e');
    }
  }

  static Future<void> signOut() async {
    try {
      await (_lastInstance ?? GoogleSignIn()).signOut();
    } catch (_) {}
  }
}
