import '../models/chat_message_model.dart';
import '../models/chat_thread_model.dart';
import 'api_service.dart';

class ChatService {
  ChatService(this._apiService);

  final ApiService _apiService;

  Future<ChatThreadModel> startThread(String specialistUserId) async {
    final response = await _apiService.post(
      '/chats/threads',
      body: {
        'specialist_user_id': specialistUserId,
      },
    );
    if (response is! Map<String, dynamic>) {
      throw const ApiException('Unexpected chat thread response');
    }
    final thread = response['thread'];
    if (thread is! Map<String, dynamic>) {
      throw const ApiException('Chat thread missing');
    }
    return ChatThreadModel.fromJson(thread);
  }

  Future<List<ChatThreadModel>> fetchThreads() async {
    final response = await _apiService.get('/chats/threads');
    if (response is! Map<String, dynamic>) {
      throw const ApiException('Unexpected chat threads response');
    }
    final items = response['items'];
    if (items is! List) {
      return [];
    }
    return items
        .whereType<Map>()
        .map((item) => ChatThreadModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<ChatMessageModel>> fetchMessages(String threadId) async {
    final response = await _apiService.get('/chats/threads/$threadId/messages');
    if (response is! Map<String, dynamic>) {
      throw const ApiException('Unexpected chat messages response');
    }
    final items = response['items'];
    if (items is! List) {
      return [];
    }
    return items
        .whereType<Map>()
        .map((item) => ChatMessageModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<ChatMessageModel> sendMessage({
    required String threadId,
    required String messageText,
    List<Map<String, dynamic>> attachments = const [],
  }) async {
    final response = await _apiService.post(
      '/chats/messages',
      body: {
        'thread_id': threadId,
        'message_text': messageText,
        'attachments': attachments,
      },
    );
    if (response is! Map<String, dynamic>) {
      throw const ApiException('Unexpected send message response');
    }
    final item = response['item'];
    if (item is! Map<String, dynamic>) {
      throw const ApiException('Sent message missing');
    }
    return ChatMessageModel.fromJson(item);
  }
}
