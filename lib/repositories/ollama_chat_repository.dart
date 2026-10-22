import 'dart:convert';
import 'dart:io';
import 'package:ai_chatbot/repositories/chat_repository.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class OllamaChatRepository implements ChatRepository {
  static const String _embedFileName = 'products_vector_ollama.db';
  static const String _baseUrl = 'http://localhost:11434';
  static const String _chatModel = 'mistral-nemo';
  static const String _embedModel = 'all-minilm';

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
    } catch (e) {
      return 'Error: could not reach Ollama: $e';
    }

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/chat'),
            headers: {'Content-Type': 'application/json'},
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
          .timeout(const Duration(minutes: 5));

      if (response.statusCode != 200) {
        return 'Error ${response.statusCode}: ${response.body}';
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final content = data['message']?['content'];
      if (content is! String) {
        return 'Error: unexpected response format: ${response.body}';
      }
      return content.trim();
    } on SocketException {
      return 'Error: cannot connect to Ollama at $_baseUrl. Is it running?';
    }
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
          Uri.parse('$_baseUrl/api/embed'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'model': _embedModel, 'input': texts}),
        )
        .timeout(const Duration(seconds: 150));

    if (res.statusCode != 200) {
      throw Exception('Embedding error ${res.statusCode}: ${res.body}');
    }

    final data = jsonDecode(utf8.decode(res.bodyBytes));
    final embeddings = data['embeddings'] as List;

    return embeddings
        .map((e) => (e as List).map((v) => (v as num).toDouble()).toList())
        .toList();
  }

  Future<File> _dbFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_embedFileName');
  }

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
      stderr.writeln('OllamaChatRepository: could not read saved database: $e');
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