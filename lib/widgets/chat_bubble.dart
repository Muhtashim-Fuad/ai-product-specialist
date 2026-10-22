import 'package:ai_chatbot/repositories/chat_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});
  final ChatMessage message;

  static const double _avatarRadius = 16;
  static const double _avatarGap = 8;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isUser = message.sender == Sender.user;

    const big = Radius.circular(20);
    const small = Radius.circular(4);

    final avatar = CircleAvatar(
      radius: _avatarRadius,
      backgroundColor:
          isUser ? scheme.primaryContainer : scheme.tertiaryContainer,
      child: Icon(
        isUser ? Icons.person : Icons.auto_awesome,
        size: 18,
        color: isUser ? scheme.onPrimaryContainer : scheme.onTertiaryContainer,
      ),
    );

    final bubble = Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: big,
            topRight: big,
            bottomLeft: isUser ? big : small,
            bottomRight: isUser ? small : big,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: MarkdownBody(
          data: message.text,
          selectable: true,
          styleSheet: MarkdownStyleSheet(
            p: TextStyle(
            color: isUser ? scheme.onPrimary : scheme.onSurface,
            height: 1.35,
          ),
          ),
        ),
      ),
    );

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.85,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: isUser
              ? [bubble, const SizedBox(width: _avatarGap), avatar]
              : [avatar, const SizedBox(width: _avatarGap), bubble],
        ),
      ),
    );
  }
}