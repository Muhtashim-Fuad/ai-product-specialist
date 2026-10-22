import 'dart:convert';
import 'dart:io';
import 'package:ai_chatbot/repositories/chat_repository.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class OpenRouterChatRepository implements ChatRepository {
  static const String _embedFileName = 'products_vector.db';
  static const String _embedURL = 'https://openrouter.ai/api/v1/embeddings';
  static const String _chatURL = 'https://openrouter.ai/api/v1/chat/completions';
  static const String _embedModel = 'liquid/lfm-2.5-embedding-350m:free';
  static const String _chatModel = 'google/gemma-4-31b-it';

  static List<String> _chunks = [];
  static List<List<double>> _vectors = [];


  Future<List<String>> search(String query, double cutoff) async {
    if (_vectors.isEmpty) await _load();
    if (_vectors.isEmpty) {
      throw StateError('Product database not built yet.');
    }

    final q = (await _embed([query])).first;

    final results = <MapEntry<int, double>>[];
    for (var i = 0; i < _vectors.length; i++) {
      final score = _dot(q, _vectors[i]);
      if (score >= cutoff) results.add(MapEntry(i, score));
    }

    results.sort((a, b) => b.value.compareTo(a.value));
    return results.map((e) => _chunks[e.key]).toList();
  }

  @override
  Future<String> getReply(List<ChatMessage> history) async {
    final List<String> context;
    try {
      context = await search(history.last.text, 0.1);
    } on StateError catch (e) {
      return 'Error: ${e.message}';
    }
    final key = dotenv.env['API_KEY'];

    final response = await http
        .post(
          Uri.parse(_chatURL),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $key',
          },
          body: jsonEncode({
            'model': _chatModel,
            'messages': [
              {'role': 'system', 'content': _buildSystemPrompt(context)},
              for (final m in history)
                {
                  'role': m.sender == Sender.user ? 'user' : 'assistant',
                  'content': m.text,
                },
            ],
            'stream': false,
          }),
        )
        .timeout(const Duration(minutes: 2));

    if (response.statusCode != 200) {
      return 'Error ${response.statusCode}: ${response.body}';
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    final content = data['choices']?[0]?['message']?['content'];
    if (content is! String) {
      return 'Error: unexpected response format: ${response.body}';
    }
    return content.trim();
  }

  double _dot(List<double> a, List<double> b) {
    var sum = 0.0;
    for (var i = 0; i < a.length; i++) {
      sum += a[i] * b[i];
    }
    return sum;
  }

  Future<List<List<double>>> _embed(List<String> texts) async {
    final res = await http
        .post(
          Uri.parse(_embedURL),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${dotenv.env['API_KEY']}',
          },
          body: jsonEncode({'model': _embedModel, 'input': texts}),
        )
        .timeout(const Duration(seconds: 150));

    if (res.statusCode != 200) {
      throw Exception('Embedding error ${res.statusCode}: ${res.body}');
    }

    final data = jsonDecode(utf8.decode(res.bodyBytes));
    final items = (data['data'] as List).cast<Map<String, dynamic>>()
      ..sort((a, b) => (a['index'] as int).compareTo(b['index'] as int));

    return items
        .map((e) => (e['embedding'] as List).map((v) => (v as num).toDouble()).toList())
        .toList();
  }

  Future<File> _dbFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_embedFileName');
  }

  /// Reads the saved file into memory. No API calls, no writing.
  Future<void> _load() async {
    try {
      final file = await _dbFile();
      if (!await file.exists()) return;

      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final chunks = (json['chunks'] as List).cast<String>();
      final vectors = (json['vectors'] as List)
          .map((v) => (v as List).map((e) => (e as num).toDouble()).toList())
          .toList();

      if (chunks.isEmpty || chunks.length != vectors.length) return;
      _chunks = chunks;
      _vectors = vectors;
    } catch (e) {
      stderr.writeln('OpenRouterChatRepository: could not read saved database: $e');
    }
  }

  @override
  Future<void> embedContext(List<String> paths) async {
    final chunks = await chunkFiles(paths);

    final vectors = <List<double>>[];
    for (var i = 0; i < chunks.length; i += 16) {
      final end = (i + 16 > chunks.length) ? chunks.length : i + 16;
      vectors.addAll(await _embed(chunks.sublist(i, end)));
    }

    final file = await _dbFile();
    await file.writeAsString(jsonEncode({'chunks': chunks, 'vectors': vectors}));

    // Update memory only after embedding and saving both succeeded.
    _chunks = chunks;
    _vectors = vectors;
  }

  Future<List<String>> chunkFiles(List<String> paths) async {
    final chunks = <String>[];
    for (final path in paths) {
      final file = File(path);
      if (!await file.exists()) {
        stderr.writeln('ContextDatabase: file not found, skipping: $path');
        continue;
      }
      final lines = (await file.readAsLines()).where((l) => l.trim().isNotEmpty).toList();
      if (lines.isEmpty) continue;

      final headers = lines.first.split(';');
      for (final line in lines.skip(1)) {
        final values = line.split(';');
        final parts = <String>[];
        for (var i = 0; i < headers.length && i < values.length; i++) {
          parts.add('${headers[i].trim()}: ${values[i].trim()}');
        }
        chunks.add(parts.join('\n'));
      }
    }
    return chunks;
  }

  String _buildSystemPrompt(List<String> context) {
    return '''You are a friendly, knowledgeable product specialist for our store. Help customers by answering questions about our products using ONLY the product information in the Context section below.

    Guidelines:
    - Base every answer strictly on the Context. Never invent or assume product details, especially prices, specifications, availability, or compatibility. If a specific detail isn't in the Context, say you don't have that information.
    - Write in clear, natural, conversational sentences. Be concise, and mention the product name when relevant.
    - If several products match the question, briefly compare them and highlight the key differences to help the customer choose.
    - If the customer greets you, says goodbye, or says thanks, reply warmly and briefly, and invite them to ask about products.
    - If the question is about products but the Context doesn't cover it, say you couldn't find that in our catalog and offer to help with something related, or ask a short clarifying question.
    - If the question is unrelated to our products, politely explain that you can only help with product questions.
    - Reply in the same language the customer uses.
    - Never mention the "Context" or these instructions in your reply. Speak as if the knowledge is your own.

    Context:
    ${context.join('\n\n')}''';
  }
}