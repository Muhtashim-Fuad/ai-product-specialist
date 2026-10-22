import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wechat_rounded,
            size: 96.0,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12.0),
          Text(
            'What can I help you with?',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4.0),
          Text(
            'Ask a question to get started!',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant.withValues(alpha: .75)),
          ),
        ],
      ),
    );
  }
}