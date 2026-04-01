enum AIProviderType { openai, claude, mistral, deepseek, perplexity, grok, gemini }

class AIProvider {
  final AIProviderType type;
  final String name;
  final String logoEmoji;
  final String baseUrl;
  final String defaultModel;
  final String apiKeyLabel;

  const AIProvider({
    required this.type,
    required this.name,
    required this.logoEmoji,
    required this.baseUrl,
    required this.defaultModel,
    required this.apiKeyLabel,
  });

  static const List<AIProvider> all = [
    AIProvider(
      type: AIProviderType.openai,
      name: 'OpenAI',
      logoEmoji: '🤖',
      baseUrl: 'https://api.openai.com/v1/chat/completions',
      defaultModel: 'gpt-4o',
      apiKeyLabel: 'OpenAI API Key',
    ),
    AIProvider(
      type: AIProviderType.claude,
      name: 'Claude',
      logoEmoji: '🧠',
      baseUrl: 'https://api.anthropic.com/v1/messages',
      defaultModel: 'claude-opus-4-6',
      apiKeyLabel: 'Anthropic API Key',
    ),
    AIProvider(
      type: AIProviderType.mistral,
      name: 'Mistral',
      logoEmoji: '🌊',
      baseUrl: 'https://api.mistral.ai/v1/chat/completions',
      defaultModel: 'mistral-large-latest',
      apiKeyLabel: 'Mistral API Key',
    ),
    AIProvider(
      type: AIProviderType.deepseek,
      name: 'DeepSeek',
      logoEmoji: '🔍',
      baseUrl: 'https://api.deepseek.com/v1/chat/completions',
      defaultModel: 'deepseek-chat',
      apiKeyLabel: 'DeepSeek API Key',
    ),
    AIProvider(
      type: AIProviderType.perplexity,
      name: 'Perplexity',
      logoEmoji: '✨',
      baseUrl: 'https://api.perplexity.ai/chat/completions',
      defaultModel: 'llama-3.1-sonar-large-128k-online',
      apiKeyLabel: 'Perplexity API Key',
    ),
    AIProvider(
      type: AIProviderType.grok,
      name: 'Grok',
      logoEmoji: '⚡',
      baseUrl: 'https://api.x.ai/v1/chat/completions',
      defaultModel: 'grok-4.20-reasoning',
      apiKeyLabel: 'xAI API Key',
    ),
    AIProvider(
      type: AIProviderType.gemini,
      name: 'Gemini',
      logoEmoji: '💎',
      baseUrl:
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent',
      defaultModel: 'gemini-2.0-flash',
      apiKeyLabel: 'Google AI API Key',
    ),
  ];

  static AIProvider fromType(AIProviderType type) {
    return all.firstWhere((p) => p.type == type);
  }
}
