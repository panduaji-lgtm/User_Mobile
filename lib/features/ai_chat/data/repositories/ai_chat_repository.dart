import 'package:app/features/ai_chat/data/repositories/ai_chat_service.dart';

/// Kontrak repository untuk Asisten AI Museum Brawijaya (chat multimodal + riwayat sesi).
abstract interface class AiChatRepository {
  Future<List<String>> getSuggestions();
  Future<AiChatReplyResult> sendChat({
    required List<AiChatMessage> history,
    String? visitorName,
    AiChatImageAttachment? image,
  });
  Future<List<AiChatSession>> loadSessions();
  Future<List<AiChatSession>> upsertSession(AiChatSession session);
  Future<List<AiChatSession>> deleteSession(String sessionId);
}

/// Implementasi default [AiChatRepository] berbasis [AiChatService].
class DefaultAiChatRepository implements AiChatRepository {
  const DefaultAiChatRepository();

  @override
  Future<List<String>> getSuggestions() => AiChatService.getSuggestions();

  @override
  Future<AiChatReplyResult> sendChat({
    required List<AiChatMessage> history,
    String? visitorName,
    AiChatImageAttachment? image,
  }) =>
      AiChatService.sendChat(
        history: history,
        visitorName: visitorName,
        image: image,
      );

  @override
  Future<List<AiChatSession>> loadSessions() => AiChatService.loadSessions();

  @override
  Future<List<AiChatSession>> upsertSession(AiChatSession session) =>
      AiChatService.upsertSession(session);

  @override
  Future<List<AiChatSession>> deleteSession(String sessionId) =>
      AiChatService.deleteSession(sessionId);
}
