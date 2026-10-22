import 'package:ai_chatbot/repositories/chat_repository.dart';

class FakeChatRepository implements ChatRepository {
  @override
  Future<String> getReply(List<ChatMessage> history) async {
    await Future.delayed(const Duration(seconds: 1));
    if (history.last.text.toLowerCase().contains('error')) {
      throw Exception('Fake failure');
    }
    return 'You said: "${history.last.text}"';
  }

  @override
  Future<void> embedContext(List<String> path) async {
    await Future.delayed(const Duration(seconds: 1));
  }
}