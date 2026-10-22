import 'package:ai_chatbot/blocs/chat_bloc.dart';
import 'package:ai_chatbot/blocs/chat_event.dart';
import 'package:ai_chatbot/blocs/chat_state.dart';
import 'package:ai_chatbot/widgets/chat_bubble.dart';
import 'package:ai_chatbot/widgets/composer.dart';
import 'package:ai_chatbot/widgets/empty_state.dart';
import 'package:ai_chatbot/widgets/status_line.dart';
import 'package:ai_chatbot/widgets/theme_toggle.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Icon(Icons.message, size: 32, color: scheme.primary),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI Assistant',
              style: TextStyle(fontSize: 20),
            ),
            Text(
              'Your Favourite Chatbot',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.secondary.withAlpha(135),
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          context.watch<ChatBloc>().state.documentLoading ? 
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: SizedBox(
                width: 18,
                height: 18,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.0,
                ),
              ),
            ) :
            IconButton(
              icon: Icon(Icons.sync),
              onPressed: context.watch<ChatBloc>().state.contextDocuments.isEmpty ?
              null : 
              () => context.read<ChatBloc>().add(DocumentLoaded()), 
            ),
          IconButton(
            icon: Icon(Icons.article),
            onPressed: (){
              showModalBottomSheet(
                context: context,
                constraints: BoxConstraints(
                  maxWidth: double.infinity, // Or a specific value like 800
                  minWidth: double.infinity,
                ),
                builder:(context) {
                  return DocumentModal();
                },
              );
            }
          ),
          ThemeToggle(),
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: context.watch<ChatBloc>().state.messages.isEmpty ?
              null :
              () => context.read<ChatBloc>().add(MessageCleared()), 
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const new({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        MessageList(),
        StatusLine(),
        Composer(),
      ],
    );
  }
}

class DocumentModal extends StatelessWidget {
  const new({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Choose Document(s) to Upload',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12.0),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              separatorBuilder:(context, index) => SizedBox(height: 0), 
              itemBuilder:(context, index) => Row(
                children: [
                  Flexible(
                    child: TextField(
                      style: TextStyle(
                        fontSize: 14.0,
                      ),
                      controller: TextEditingController(text: context.watch<ChatBloc>().state.contextDocuments[index]),
                      readOnly: true,
                      decoration: const InputDecoration(
                        isDense: true,
                        visualDensity: VisualDensity.compact,
                        border: UnderlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.0),
                  IconButton(
                    onPressed: (){
                      String path = context.read<ChatBloc>().state.contextDocuments[index];
                      context.read<ChatBloc>().add(DocumentDeleted(path));
                    }, 
                    icon: Icon(Icons.delete),
                  ),
                ],
              ), 
              itemCount: context.watch<ChatBloc>().state.contextDocuments.length),
          ),
          SizedBox(height: 8.0),
          InkWell(
            onTap: () async {
              List<PlatformFile> result = await FilePicker.pickFiles();
              List<String> paths = [];
              if (context.mounted)
              {
                for (int i=0; i<result.length; i++) {
                  if (result[i].path != null) paths.add(result[i].path!);
                }
                context.read<ChatBloc>().add(DocumentAdded(paths));
              }
            },
            borderRadius: BorderRadius.circular(8.0),
            child: DottedBorder(
              options: RoundedRectDottedBorderOptions(
                color: Theme.of(context).colorScheme.secondary.withAlpha(124),
                radius: Radius.circular(8.0),
                padding: EdgeInsets.all(8.0),
                dashPattern: [8, 3],
                strokeWidth: 1.4,
              ),
              child: Center(
                child: Icon(
                  Icons.add,
                  color: Theme.of(context).colorScheme.secondary.withAlpha(124),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MessageList extends StatelessWidget {
  const MessageList({super.key});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: BlocBuilder<ChatBloc, ChatState>(
        buildWhen: (prev, curr) => prev.messages != curr.messages,
        builder: (context, state) {
          if (state.messages.isEmpty) return const EmptyState();
          return ListView.builder(
            reverse: true,
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
            itemCount: state.messages.length,
            itemBuilder: (_, i) => ChatBubble(message: state.messages[i]),
          );
        },
      ),
    );
  }
}

