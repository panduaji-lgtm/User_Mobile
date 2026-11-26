import 'dart:convert';
import 'dart:typed_data';

class AiChatImageAttachment {
  final Uint8List bytes;
  final String mimeType;
  final String fileName;

  const AiChatImageAttachment({
    required this.bytes,
    required this.mimeType,
    required this.fileName,
  });

  int get sizeBytes => bytes.length;

  String get base64Data => base64Encode(bytes);

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toApiJson() => {
        'base64': base64Data,
        'mimeType': mimeType,
        'fileName': fileName,
      };
}

class AiQuickAction {
  final String type;
  final String label;
  final String route;

  const AiQuickAction({
    required this.type,
    required this.label,
    required this.route,
  });

  factory AiQuickAction.fromJson(Map<String, dynamic> json) => AiQuickAction(
        type: json['type'] as String? ?? 'koleksi',
        label: json['label'] as String? ?? 'Jelajahi',
        route: json['route'] as String? ?? '/koleksi',
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'label': label,
        'route': route,
      };
}

class AiChatMessage {
  // Batasi ukuran base64 yang disimpan di SharedPreferences agar localStorage Web tidak penuh
  static const int _maxPersistedBase64Length = 180000;

  final String id;
  final String role; // 'user' | 'assistant'
  final String content;
  final DateTime createdAt;
  final List<String> followUpSuggestions;
  final List<AiQuickAction> quickActions;
  final String? mode;
  final bool isError;
  final String? retryPrompt;
  final String? imageBase64;
  final String? imageMimeType;
  final String? imageName;
  final AiChatImageAttachment? retryImage;

  const AiChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.followUpSuggestions = const [],
    this.quickActions = const [],
    this.mode,
    this.isError = false,
    this.retryPrompt,
    this.imageBase64,
    this.imageMimeType,
    this.imageName,
    this.retryImage,
  });

  bool get isUser => role == 'user';

  bool get hasImage =>
      (imageBase64 != null && imageBase64!.isNotEmpty) ||
      (imageName != null && imageName!.isNotEmpty);

  Uint8List? get imageBytes {
    if (imageBase64 == null || imageBase64!.isEmpty) return null;
    try {
      return base64Decode(imageBase64!);
    } catch (_) {
      return null;
    }
  }

  factory AiChatMessage.fromJson(Map<String, dynamic> json) => AiChatMessage(
        id: json['id'] as String? ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        role: json['role'] as String? ?? 'assistant',
        content: json['content'] as String? ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
        followUpSuggestions: (json['followUpSuggestions'] as List<dynamic>?)
                ?.whereType<String>()
                .toList() ??
            const [],
        quickActions: (json['quickActions'] as List<dynamic>?)
                ?.whereType<Map<String, dynamic>>()
                .map(AiQuickAction.fromJson)
                .toList() ??
            const [],
        mode: json['mode'] as String?,
        isError: json['isError'] as bool? ?? false,
        retryPrompt: json['retryPrompt'] as String?,
        imageBase64: json['imageBase64'] as String?,
        imageMimeType: json['imageMimeType'] as String?,
        imageName: json['imageName'] as String?,
      );

  Map<String, dynamic> toJson() {
    final persistableImage =
        imageBase64 != null && imageBase64!.length <= _maxPersistedBase64Length
            ? imageBase64
            : null;
    return {
      'id': id,
      'role': role,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'followUpSuggestions': followUpSuggestions,
      'quickActions': quickActions.map((a) => a.toJson()).toList(),
      'mode': mode,
      'isError': isError,
      'retryPrompt': retryPrompt,
      'imageBase64': ?persistableImage,
      'imageMimeType': ?imageMimeType,
      'imageName': ?imageName,
    };
  }
}

class AiChatSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<AiChatMessage> messages;

  const AiChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
  });

  factory AiChatSession.fromJson(Map<String, dynamic> json) => AiChatSession(
        id: json['id'] as String? ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        title: json['title'] as String? ?? 'Percakapan Baru',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
        messages: (json['messages'] as List<dynamic>?)
                ?.whereType<Map<String, dynamic>>()
                .map(AiChatMessage.fromJson)
                .toList() ??
            const [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'messages': messages.map((m) => m.toJson()).toList(),
      };

  AiChatSession copyWith({
    String? title,
    DateTime? updatedAt,
    List<AiChatMessage>? messages,
  }) =>
      AiChatSession(
        id: id,
        title: title ?? this.title,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        messages: messages ?? this.messages,
      );
}

class AiChatReplyResult {
  final String reply;
  final String mode;
  final String model;
  final List<String> followUpSuggestions;
  final List<AiQuickAction> quickActions;

  const AiChatReplyResult({
    required this.reply,
    required this.mode,
    required this.model,
    required this.followUpSuggestions,
    required this.quickActions,
  });

  factory AiChatReplyResult.fromJson(Map<String, dynamic> json) =>
      AiChatReplyResult(
        reply: json['reply'] as String? ??
            'Maaf, belum ada balasan dari asisten.',
        mode: json['mode'] as String? ?? 'local_fallback',
        model: json['model'] as String? ?? 'museum-knowledge-engine',
        followUpSuggestions: (json['followUpSuggestions'] as List<dynamic>?)
                ?.whereType<String>()
                .toList() ??
            const [],
        quickActions: (json['quickActions'] as List<dynamic>?)
                ?.whereType<Map<String, dynamic>>()
                .map(AiQuickAction.fromJson)
                .toList() ??
            const [],
      );
}
