import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:app/core/network/api_client.dart';
import 'package:app/features/auth/data/models/auth_models.dart';

@JS('window')
external JSObject get _window;

@JS('document')
external JSObject get _document;

class GoogleAuthClient {
  static const String _gisScriptUrl = 'https://accounts.google.com/gsi/client';
  static Future<void>? _scriptLoadFuture;

  static bool _isPlaceholderClientId(String value) {
    final lower = value.trim().toLowerCase();
    return lower.isEmpty ||
        lower.contains('replace-with') ||
        lower.contains('your_google_client_id') ||
        lower.contains('your-google-client-id') ||
        lower.contains('example.apps.googleusercontent.com');
  }

  /// Membaca meta tag `<meta name="google-signin-client_id" content="...">` di web/index.html.
  static String? readWebMetaClientId() {
    try {
      final meta = _document.callMethod<JSObject?>(
        'querySelector'.toJS,
        'meta[name="google-signin-client_id"]'.toJS,
      );
      if (meta == null) return null;
      final content = meta
          .callMethod<JSString?>('getAttribute'.toJS, 'content'.toJS)
          ?.toDart
          .trim();
      if (content == null || _isPlaceholderClientId(content)) return null;
      return content;
    } catch (_) {
      return null;
    }
  }

  static JSObject? _getOAuth2Client() {
    try {
      final google = _window['google'];
      if (google == null || !google.isA<JSObject>()) return null;
      final accounts = (google as JSObject)['accounts'];
      if (accounts == null || !accounts.isA<JSObject>()) return null;
      final oauth2 = (accounts as JSObject)['oauth2'];
      if (oauth2 == null || !oauth2.isA<JSObject>()) return null;
      return oauth2 as JSObject;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _ensureGisScriptLoaded() {
    if (_getOAuth2Client() != null) {
      return Future<void>.value();
    }
    if (_scriptLoadFuture != null) {
      return _scriptLoadFuture!;
    }

    final completer = Completer<void>();
    _scriptLoadFuture = completer.future;

    void finishIfReady() {
      if (!completer.isCompleted && _getOAuth2Client() != null) {
        completer.complete();
      }
    }

    try {
      final existing = _document.callMethod<JSObject?>(
        'querySelector'.toJS,
        'script[src*="accounts.google.com/gsi/client"]'.toJS,
      );

      if (existing == null) {
        final script =
            _document.callMethod<JSObject>('createElement'.toJS, 'script'.toJS);
        script['src'] = _gisScriptUrl.toJS;
        script['async'] = true.toJS;
        script['defer'] = true.toJS;
        script['onload'] = (() {
          finishIfReady();
        }).toJS;
        script['onerror'] = (() {
          if (!completer.isCompleted) {
            _scriptLoadFuture = null;
            completer.completeError(
              ApiException(
                'Gagal memuat Google Identity Services. Periksa koneksi internet Anda.',
              ),
            );
          }
        }).toJS;

        final head = _document['head'];
        if (head != null && head.isA<JSObject>()) {
          (head as JSObject).callMethod<JSAny?>('appendChild'.toJS, script);
        }
      }

      // Polling ringan selama maks. 8 detik untuk script async yang sudah ada di index.html
      var attempts = 0;
      Timer.periodic(const Duration(milliseconds: 100), (timer) {
        attempts++;
        if (_getOAuth2Client() != null) {
          timer.cancel();
          finishIfReady();
          return;
        }
        if (completer.isCompleted) {
          timer.cancel();
          return;
        }
        if (attempts >= 80) {
          timer.cancel();
          _scriptLoadFuture = null;
          completer.completeError(
            ApiException(
              'Layanan Google Sign-In belum siap dimuat. Pastikan koneksi internet aktif lalu coba lagi.',
            ),
          );
        }
      });
    } catch (e) {
      _scriptLoadFuture = null;
      if (!completer.isCompleted) {
        completer.completeError(
          ApiException('Gagal menyiapkan Google Sign-In di browser: $e'),
        );
      }
    }

    return completer.future;
  }

  /// Menyiapkan Google Identity Services SDK lebih awal agar popup tidak diblokir browser.
  static Future<void> prepare({String? clientId}) async {
    try {
      await _ensureGisScriptLoaded();
    } catch (_) {
      // Abaikan error preload; akan ditangani ulang saat pengguna mengklik tombol Google.
    }
  }

  /// Membuka popup resmi Google OAuth 2.0 (accounts.google.com account chooser & consent Lanjutkan).
  static Future<GoogleAuthCredential> signIn({String? clientId}) async {
    final resolvedClientId = (clientId ?? '').trim().isNotEmpty
        ? clientId!.trim()
        : (readWebMetaClientId() ?? '');

    if (resolvedClientId.isEmpty || _isPlaceholderClientId(resolvedClientId)) {
      throw const GoogleAuthConfigException(
        'Login dengan Google belum dikonfigurasi. Isi GOOGLE_CLIENT_ID di file .env UAS_BACKEND atau meta tag google-signin-client_id di web/index.html.',
      );
    }

    // Jika SDK sudah siap dari preload, jangan await sebelum requestAccessToken agar tetap berada di user-gesture browser!
    var oauth2 = _getOAuth2Client();
    if (oauth2 == null) {
      await _ensureGisScriptLoaded();
      oauth2 = _getOAuth2Client();
    }

    if (oauth2 == null) {
      throw ApiException(
        'Google Identity Services tidak tersedia di browser. Muat ulang halaman lalu coba lagi.',
      );
    }

    final completer = Completer<GoogleAuthCredential>();

    final config = JSObject();
    config['client_id'] = resolvedClientId.toJS;
    config['scope'] = 'openid email profile'.toJS;
    config['prompt'] = 'select_account'.toJS;

    config['callback'] = ((JSAny? rawResponse) {
      if (completer.isCompleted) return;
      if (rawResponse == null || !rawResponse.isA<JSObject>()) {
        completer.completeError(
          ApiException('Respons autentikasi dari Google tidak valid.'),
        );
        return;
      }

      final response = rawResponse as JSObject;
      final errorVal = response['error'];
      if (errorVal != null && errorVal.isA<JSString>()) {
        final errCode = (errorVal as JSString).toDart;
        if (errCode == 'access_denied') {
          completer.completeError(
            const GoogleAuthCancelledException('Akses akun Google dibatalkan.'),
          );
          return;
        }
        final descVal = response['error_description'];
        final desc = (descVal != null && descVal.isA<JSString>())
            ? (descVal as JSString).toDart
            : errCode;
        completer.completeError(
          ApiException('Autentikasi Google gagal: $desc'),
        );
        return;
      }

      final tokenVal = response['access_token'];
      final accessToken = (tokenVal != null && tokenVal.isA<JSString>())
          ? (tokenVal as JSString).toDart.trim()
          : '';
      if (accessToken.isEmpty) {
        completer.completeError(
          ApiException('Token akses Google tidak diterima dari browser.'),
        );
        return;
      }

      completer.complete(GoogleAuthCredential(accessToken: accessToken));
    }).toJS;

    config['error_callback'] = ((JSAny? rawError) {
      if (completer.isCompleted) return;
      String errType = 'unknown';
      if (rawError != null && rawError.isA<JSObject>()) {
        final typeVal = (rawError as JSObject)['type'];
        if (typeVal != null && typeVal.isA<JSString>()) {
          errType = (typeVal as JSString).toDart;
        }
      }

      if (errType == 'popup_closed') {
        completer.completeError(
          const GoogleAuthCancelledException('Login dengan Google dibatalkan.'),
        );
      } else if (errType == 'popup_failed_to_open') {
        completer.completeError(
          ApiException(
            'Popup pemilihan akun Google diblokir oleh browser. Izinkan pop-up untuk situs ini lalu klik tombol sekali lagi.',
          ),
        );
      } else {
        completer.completeError(
          ApiException(
            'Gagal membuka halaman login Google ($errType). Pastikan origin URL aplikasi sudah didaftarkan pada Authorized JavaScript origins di Google Cloud Console.',
          ),
        );
      }
    }).toJS;

    try {
      final tokenClient =
          oauth2.callMethod<JSObject>('initTokenClient'.toJS, config);
      final reqConfig = JSObject();
      reqConfig['prompt'] = 'select_account'.toJS;
      tokenClient.callMethod<JSAny?>('requestAccessToken'.toJS, reqConfig);
    } catch (e) {
      if (!completer.isCompleted) {
        completer.completeError(
          ApiException('Tidak dapat memulai alur Google OAuth: $e'),
        );
      }
    }

    return completer.future.timeout(
      const Duration(minutes: 3),
      onTimeout: () => throw const GoogleAuthCancelledException(
        'Waktu pemilihan akun Google habis. Silakan coba lagi.',
      ),
    );
  }

  static Future<void> signOut() async {
    try {
      final google = _window['google'];
      if (google != null && google.isA<JSObject>()) {
        final accounts = (google as JSObject)['accounts'];
        if (accounts != null && accounts.isA<JSObject>()) {
          final id = (accounts as JSObject)['id'];
          if (id != null && id.isA<JSObject>()) {
            (id as JSObject).callMethod<JSAny?>('disableAutoSelect'.toJS);
          }
        }
      }
    } catch (_) {}
  }
}
