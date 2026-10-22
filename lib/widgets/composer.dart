import 'package:ai_chatbot/blocs/chat_bloc.dart';
import 'package:ai_chatbot/blocs/chat_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Composer extends StatelessWidget {
  const Composer({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ChatBloc>();
    final scheme = Theme.of(context).colorScheme;
    final resetCount =
        context.select((ChatBloc b) => b.state.composerResetCount);
    final canSend = context.select((ChatBloc b) => b.state.canSend) && context.select((ChatBloc b) => b.state.contextDocuments.isNotEmpty);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  style: TextStyle(
                    fontSize: 14,
                  ),
                  key: ValueKey(resetCount),
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.send,
                  onChanged: (text) => bloc.add(DraftChanged(text)),
                  onSubmitted: (_) => bloc.add(const MessageSent()),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Type a message',
                    filled: true,
                    fillColor: scheme.surfaceContainerHighest,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide(color: scheme.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6.0),
              Transform.scale(
                scale: 0.9,
                child: IconButton.filled(
                  iconSize: 22,
                  onPressed:
                      canSend ? () => bloc.add(const MessageSent()) : null,
                  icon: Transform.translate(
                      offset: Offset(2.0, 0),
                      child: const Icon(Icons.send_rounded),
                    ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}