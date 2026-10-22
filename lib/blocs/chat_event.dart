import 'package:equatable/equatable.dart';

sealed class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

final class DraftChanged extends ChatEvent {
  const DraftChanged(this.text);
  final String text;
  @override
  List<Object?> get props => [text];
}

final class MessageSent extends ChatEvent {
  const MessageSent();
}

final class MessageCleared extends ChatEvent {
  const MessageCleared();
}

final class DocumentLoaded extends ChatEvent {
  const DocumentLoaded();
}

final class DocumentAdded extends ChatEvent {
  const DocumentAdded(this.paths);
  final List<String> paths;
  @override
  List<Object?> get props => [paths];
}

final class DocumentDeleted extends ChatEvent {
  const DocumentDeleted(this.path);
  final String path;
  @override
  List<Object?> get props => [path];
}