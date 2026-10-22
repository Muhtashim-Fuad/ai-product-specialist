import 'dart:async';
import 'package:ai_chatbot/repositories/chat_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc({required this._repository})
      : super(const ChatState()) {
    on<DraftChanged>(_onDraftChanged);
    on<MessageSent>(_onMessageSent);
    on<MessageCleared>(_onMessageCleared);
    on<DocumentLoaded>(_onDocumentLoaded);
    on<DocumentAdded>(_onDocumentAdded);
    on<DocumentDeleted>(_onDocumentDeleted);
  }

  final ChatRepository _repository;


  void _onMessageCleared(MessageCleared event, Emitter<ChatState> emit) {
    emit(const ChatState(messages: []));
  }

  void _onDraftChanged(DraftChanged event, Emitter<ChatState> emit) {
    emit(state.copyWith(draft: event.text));
  }

  Future<void> _onDocumentLoaded(DocumentLoaded event, Emitter<ChatState> emit) async {
    emit(
      state.copyWith(
        documentLoading: true,
      ),
    );
    await _repository.embedContext(state.contextDocuments);
    
    emit(
      state.copyWith(
        documentLoading: false,
      ),
    );
  }

  Future<void> _onMessageSent(
    MessageSent event,
    Emitter<ChatState> emit,
  ) async {
    if (!state.canSend) return;

    final userMessage = ChatMessage(
      text: state.draft.trim(),
      sender: Sender.user,
    );

    emit(state.copyWith(
      messages: [userMessage, ...state.messages],
      draft: '',
      status: ChatStatus.awaitingReply,
      composerResetCount: state.composerResetCount + 1,
    ));

    try {
      final reply = await _repository.getReply(
        state.messages.reversed.toList(), // oldest → newest for the AI
      );

      // This is to ensure that incase user cleared the messages, the rest does not execute
      // & accidentally returns the assistant's response
      if (state.composerResetCount <= 0) return;

      emit(state.copyWith(
        messages: [ChatMessage(text: reply, sender: Sender.ai), ...state.messages],
        status: ChatStatus.idle,
      ));
    } catch (_) {
      emit(state.copyWith(status: ChatStatus.failure));
    }
  }

  void _onDocumentAdded(DocumentAdded event, Emitter<ChatState> emit) {
    List<String> nonDuplicates = [];
    for (int i=0; i<event.paths.length; i++) {
      String path = event.paths[i];
      if (!state.contextDocuments.contains(path)) nonDuplicates.add(path);
    }

    emit(state.copyWith(
      contextDocuments: [...state.contextDocuments, ...nonDuplicates],
    ));
  }

  void _onDocumentDeleted(DocumentDeleted event, Emitter<ChatState> emit) {
    emit(state.copyWith(
      contextDocuments: state.contextDocuments.where(
        (element) => element != event.path,
      ).toList(),

    ));
  }
}