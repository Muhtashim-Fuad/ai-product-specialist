import 'package:equatable/equatable.dart';

enum Sender { user, ai }

class ChatMessage extends Equatable {
  const ChatMessage({required this.text, required this.sender});

  final String text;
  final Sender sender;

  @override
  List<Object> get props => [text, sender];
}

abstract class ChatRepository {
  Future<String> getReply(List<ChatMessage> history);
  Future<void> embedContext(List<String> path);
}
