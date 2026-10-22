import 'package:ai_chatbot/blocs/theme_bloc.dart';
import 'package:ai_chatbot/blocs/theme_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeBloc b) => b.state.isDark);
    return IconButton(
      tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
      onPressed: () => context.read<ThemeBloc>().add(const ThemeToggled()),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) => RotationTransition(
          turns: animation,
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: Icon(
          isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          key: ValueKey(isDark),
        ),
      ),
    );
  }
}