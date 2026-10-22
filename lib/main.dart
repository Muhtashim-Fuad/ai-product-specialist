import 'package:ai_chatbot/app_theme.dart';
import 'package:ai_chatbot/blocs/chat_bloc.dart';
import 'package:ai_chatbot/chat_page.dart';
import 'package:ai_chatbot/repositories/chat_repository.dart';
import 'package:ai_chatbot/repositories/ollama_chat_repository.dart';
import 'package:ai_chatbot/repositories/openrouter_chat_repository.dart';
import 'package:ai_chatbot/blocs/theme_bloc.dart';
import 'package:ai_chatbot/blocs/theme_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<ChatRepository>(
      create: (_) => OllamaChatRepository(),
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                ChatBloc(repository: context.read<ChatRepository>()),
          ),
          BlocProvider(create: (_) => ThemeBloc()),
        ],
        child: const _AppView(),
      ),
    );
  }
}

class _AppView extends StatelessWidget {
  const _AppView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: state.mode,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          home: const ChatPage(),
        );
      },
    );
  }
}