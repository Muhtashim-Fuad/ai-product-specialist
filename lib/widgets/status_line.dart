import 'package:ai_chatbot/blocs/chat_bloc.dart';
import 'package:ai_chatbot/blocs/chat_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StatusLine extends StatelessWidget {
  const StatusLine({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.select((ChatBloc b) => b.state.status);
    final scheme = Theme.of(context).colorScheme;

    final Widget? content = switch (status) {
      ChatStatus.awaitingReply => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text('AI is typing…',
                style: TextStyle(color: scheme.onSurfaceVariant)),
          ],
        ),
      ChatStatus.failure => Text(
          'Something went wrong. Please try again.',
          style: TextStyle(color: scheme.error),
        ),
      ChatStatus.idle => null,
    };

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      alignment: Alignment.topCenter,
      child: content == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Align(alignment: Alignment.centerLeft, child: content),
            ),
    );
  }
}