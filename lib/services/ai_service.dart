import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ai_provider.dart';
import '../models/message.dart';

class AIService {
  Future<String> sendMessage(
    AIProviderType providerType,
    String apiKey,
    List<ChatMessage> history,
    String systemPrompt,
  ) async {
    final provider = AIProvider.fromType(providerType);

    switch (providerType) {
      case AIProviderType.gemini:
        return _sendGemini(provider, apiKey, history, systemPrompt);
      case AIProviderType.claude:
        return _sendClaude(provider, apiKey, history, systemPrompt);
      default:
        return _sendOpenAICompat(provider, apiKey, history, systemPrompt);
    }
  }

  Future<String> _sendOpenAICompat(
    AIProvider provider,
    String apiKey,
    List<ChatMessage> history,
    String systemPrompt,
  ) async {
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
      ...history.map((m) => {
            'role': m.isUser ? 'user' : 'assistant',
            'content': m.content,
          }),
    ];

    final response = await http
        .post(
          Uri.parse(provider.baseUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'model': provider.defaultModel,
            'messages': messages,
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      throw Exception(
          'Erreur API ${provider.name} (${response.statusCode}): ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = json['choices'] as List<dynamic>;
    final message = choices.first['message'] as Map<String, dynamic>;
    return message['content'] as String;
  }

  Future<String> _sendClaude(
    AIProvider provider,
    String apiKey,
    List<ChatMessage> history,
    String systemPrompt,
  ) async {
    final messages = history.map((m) => {
          'role': m.isUser ? 'user' : 'assistant',
          'content': m.content,
        }).toList();

    final response = await http
        .post(
          Uri.parse(provider.baseUrl),
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
          },
          body: jsonEncode({
            'model': provider.defaultModel,
            'max_tokens': 4096,
            'system': systemPrompt,
            'messages': messages,
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      throw Exception(
          'Erreur API Claude (${response.statusCode}): ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final content = json['content'] as List<dynamic>;
    final textBlock = content.firstWhere(
      (c) => (c as Map<String, dynamic>)['type'] == 'text',
      orElse: () => {'text': ''},
    ) as Map<String, dynamic>;
    return textBlock['text'] as String;
  }

  Future<String> _sendGemini(
    AIProvider provider,
    String apiKey,
    List<ChatMessage> history,
    String systemPrompt,
  ) async {
    final contents = history.map((m) => {
          'role': m.isUser ? 'user' : 'model',
          'parts': [
            {'text': m.content}
          ],
        }).toList();

    final uri = Uri.parse('${provider.baseUrl}?key=$apiKey');

    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'system_instruction': {
              'parts': [
                {'text': systemPrompt}
              ]
            },
            'contents': contents,
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      throw Exception(
          'Erreur API Gemini (${response.statusCode}): ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = json['candidates'] as List<dynamic>;
    final content = candidates.first['content'] as Map<String, dynamic>;
    final parts = content['parts'] as List<dynamic>;
    return (parts.first as Map<String, dynamic>)['text'] as String;
  }
}
