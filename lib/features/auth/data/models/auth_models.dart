/// Entitas akun pengguna dan tipe kredensial Google OAuth.
class UserModel {
  final int id;
  final String nama;
  final String email;
  final String authProvider;
  final String? avatarUrl;
  final String? token;
  final String? role;
  final String? createdAt;

  UserModel({
    required this.id,
    required this.nama,
    required this.email,
    required this.authProvider,
    this.avatarUrl,
    this.token,
    this.role,
    this.createdAt,
  });

  bool get hasAvatar => avatarUrl != null && avatarUrl!.trim().isNotEmpty;

  String get initial {
    final trimmed = nama.trim();
    if (trimmed.isEmpty) return 'U';
    return trimmed[0].toUpperCase();
  }

  static String? _normalizeAvatarUrl(dynamic raw) {
    if (raw is! String) return null;
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  factory UserModel.fromJson(Map<String, dynamic> json, {String? token}) =>
      UserModel(
        id: json['id'] is int
            ? json['id'] as int
            : int.tryParse(json['id'].toString()) ?? 0,
        nama: json['nama'] as String? ??
            json['username'] as String? ??
            'Pengunjung',
        email: json['email'] as String? ?? '',
        authProvider: json['auth_provider'] as String? ??
            json['authProvider'] as String? ??
            'local',
        avatarUrl: _normalizeAvatarUrl(json['avatar_url'] ?? json['avatarUrl']),
        token: token ?? json['token'] as String?,
        role: json['role'] as String? ?? 'USER',
        createdAt:
            json['created_at']?.toString() ?? json['createdAt']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': nama,
        'email': email,
        'auth_provider': authProvider,
        'avatar_url': avatarUrl,
        'token': token,
        'role': role,
        'created_at': createdAt,
      };

  UserModel copyWith({
    int? id,
    String? nama,
    String? email,
    String? authProvider,
    String? avatarUrl,
    bool clearAvatarUrl = false,
    String? token,
    String? role,
    String? createdAt,
  }) =>
      UserModel(
        id: id ?? this.id,
        nama: nama ?? this.nama,
        email: email ?? this.email,
        authProvider: authProvider ?? this.authProvider,
        avatarUrl: clearAvatarUrl ? null : (avatarUrl ?? this.avatarUrl),
        token: token ?? this.token,
        role: role ?? this.role,
        createdAt: createdAt ?? this.createdAt,
      );
}

class GoogleAuthCredential {
  final String? idToken;
  final String? accessToken;
  final String? email;
  final String? displayName;
  final String? photoUrl;

  const GoogleAuthCredential({
    this.idToken,
    this.accessToken,
    this.email,
    this.displayName,
    this.photoUrl,
  });

  bool get hasToken =>
      (idToken != null && idToken!.trim().isNotEmpty) ||
      (accessToken != null && accessToken!.trim().isNotEmpty);
}

class GoogleAuthCancelledException implements Exception {
  final String message;

  const GoogleAuthCancelledException([
    this.message = 'Login dengan Google dibatalkan.',
  ]);

  @override
  String toString() => message;
}

class GoogleAuthConfigException implements Exception {
  final String message;

  const GoogleAuthConfigException(this.message);

  @override
  String toString() => message;
}
