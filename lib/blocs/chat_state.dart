import 'package:ai_chatbot/repositories/chat_repository.dart';
import 'package:equatable/equatable.dart';

enum ChatStatus { idle, awaitingReply, failure }

class ChatState extends Equatable {
  const ChatState({
    this.messages = const [],
    this.contextDocuments = const [],
    this.draft = '',
    this.status = ChatStatus.idle,
    this.composerResetCount = 0,
    this.documentLoading = false,
  });

  /// Newest first (makes a reversed ListView easy)
  final List<ChatMessage> messages;
  final List<String> contextDocuments;
  final String draft;
  final ChatStatus status;

  /// Bumped after sending so the text field clears itself.
  final int composerResetCount;
  final bool documentLoading;
  

  bool get canSend =>
      draft.trim().isNotEmpty && status != ChatStatus.awaitingReply;

  ChatState copyWith({
    List<ChatMessage>? messages,
    List<String>? contextDocuments,
    String? draft,
    ChatStatus? status,
    int? composerResetCount,
    bool? documentLoading,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      contextDocuments: contextDocuments ?? this.contextDocuments,
      draft: draft ?? this.draft,
      status: status ?? this.status,
      composerResetCount: composerResetCount ?? this.composerResetCount,
      documentLoading: documentLoading ?? this.documentLoading,
    );
  }

  @override
  List<Object> get props => [messages, contextDocuments, draft, status, composerResetCount, documentLoading];
}