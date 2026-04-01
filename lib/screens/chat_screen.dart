import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';
import '../models/project.dart';
import '../models/ai_provider.dart';
import '../services/ai_service.dart';
import '../services/secure_storage_service.dart';
import '../services/storage_service.dart';
import '../widgets/message_bubble.dart';
import '../app_theme.dart';

class ChatTab extends StatefulWidget {
  final AppProject project;
  final ValueChanged<AppProject> onProjectUpdated;

  const ChatTab({
    super.key,
    required this.project,
    required this.onProjectUpdated,
  });

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _aiService = AIService();
  final _secureStorage = SecureStorageService();
  final _storageService = StorageService();
  bool _loading = false;
  late AppProject _project;

  static const List<Map<String, String>> _promptChips = [
    {
      'label': 'Génère des features',
      'prompt':
          'Génère une liste de 10 features principales pour mon application. Présente-les sous forme de liste numérotée avec une description courte pour chaque feature.'
    },
    {
      'label': 'Crée les user stories',
      'prompt':
          'Crée 8 user stories détaillées pour mon application en suivant le format : "En tant que [utilisateur], je veux [action] afin de [bénéfice]". Numérote-les.'
    },
    {
      'label': 'Propose une roadmap',
      'prompt':
          'Propose une roadmap de développement avec 3 phases : MVP, v1.0 et v2.0. Pour chaque phase, liste les fonctionnalités à développer avec un niveau de priorité (1=critique, 2=important, 3=optionnel).'
    },
    {
      'label': 'Analyse la concurrence',
      'prompt':
          'Analyse les 3 principaux concurrents potentiels de mon application. Pour chacun, décris leurs points forts, leurs points faibles et comment mon app peut se différencier.'
    },
  ];

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    // Initial AI greeting
    _messages.add(ChatMessage(
      id: const Uuid().v4(),
      content:
          'Bonjour ! Je suis votre assistant IA pour le projet **${_project.name}**. '
          'Je suis prêt à vous aider à développer votre idée d\'application.\n\n'
          'Utilisez les boutons rapides ci-dessous ou posez-moi vos questions !',
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _buildSystemPrompt() {
    return '''Tu es un expert en développement d'applications mobiles et en product management.
Tu aides l'utilisateur à développer son idée d'application mobile.

Projet : ${_project.name}
Description : ${_project.description}

Réponds toujours en français. Sois précis, structuré et actionnable.
Quand tu génères des features, user stories ou une roadmap, utilise des listes numérotées claires.''';
  }

  Future<void> _sendMessage(String content) async {
    if (content.trim().isEmpty || _loading) return;

    final userMsg = ChatMessage(
      id: const Uuid().v4(),
      content: content.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _loading = true;
    });

    _inputController.clear();
    _scrollToBottom();

    try {
      final providerType =
          _project.providerUsed ?? AIProviderType.openai;
      final apiKey = await _secureStorage.getApiKey(providerType);

      if (apiKey == null || apiKey.isEmpty) {
        throw Exception(
            'Clé API manquante pour ${AIProvider.fromType(providerType).name}. Veuillez la configurer dans les paramètres.');
      }

      final response = await _aiService.sendMessage(
        providerType,
        apiKey,
        _messages.where((m) => m.id != userMsg.id).toList() + [userMsg],
        _buildSystemPrompt(),
      );

      final aiMsg = ChatMessage(
        id: const Uuid().v4(),
        content: response,
        isUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(aiMsg);
        _loading = false;
      });

      _scrollToBottom();

      // Detect and offer to save content
      _detectAndOfferSave(content, response);
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        final errorMsg = _parseError(e.toString());
        setState(() {
          _messages.add(ChatMessage(
            id: const Uuid().v4(),
            content: '⚠️ $errorMsg',
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();
      }
    }
  }

  void _detectAndOfferSave(String prompt, String response) {
    final lowerPrompt = prompt.toLowerCase();
    final lowerResponse = response.toLowerCase();

    if (lowerPrompt.contains('feature') ||
        lowerResponse.contains('feature') ||
        lowerPrompt.contains('fonctionnalit')) {
      _offerToSave('features', response);
    } else if (lowerPrompt.contains('user stor') ||
        lowerPrompt.contains('user stories') ||
        lowerResponse.contains('en tant que')) {
      _offerToSave('userStories', response);
    } else if (lowerPrompt.contains('roadmap') ||
        lowerResponse.contains('mvp') ||
        lowerResponse.contains('v1.0')) {
      _offerToSave('roadmap', response);
    }
  }

  void _offerToSave(String type, String response) {
    if (!mounted) return;

    final labels = {
      'features': 'features',
      'userStories': 'user stories',
      'roadmap': 'roadmap',
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Voulez-vous sauvegarder ces ${labels[type]} dans le projet ?'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Sauvegarder',
          textColor: AppColors.secondary,
          onPressed: () => _saveToProject(type, response),
        ),
      ),
    );
  }

  Future<void> _saveToProject(String type, String response) async {
    final updatedProject = AppProject(
      id: _project.id,
      name: _project.name,
      description: _project.description,
      features: _project.features,
      userStories: _project.userStories,
      roadmap: _project.roadmap,
      createdAt: _project.createdAt,
      providerUsed: _project.providerUsed,
    );

    switch (type) {
      case 'features':
        final parsed = _parseList(response);
        updatedProject.features = parsed;
        break;
      case 'userStories':
        final parsed = _parseList(response);
        updatedProject.userStories = parsed;
        break;
      case 'roadmap':
        final items = _parseRoadmap(response);
        updatedProject.roadmap = items;
        break;
    }

    await _storageService.saveProject(updatedProject);
    setState(() => _project = updatedProject);
    widget.onProjectUpdated(updatedProject);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sauvegardé avec succès !'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  List<String> _parseList(String text) {
    final lines = text.split('\n');
    final List<String> items = [];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Match numbered lists: 1. or 1) or • or - or *
      final match = RegExp(r'^[\d]+[.)]\s+(.+)$').firstMatch(trimmed) ??
          RegExp(r'^[-•*]\s+(.+)$').firstMatch(trimmed);

      if (match != null) {
        items.add(match.group(1)!.trim());
      } else if (trimmed.length > 20 && !trimmed.startsWith('#')) {
        // Include longer lines that look like content
        items.add(trimmed);
      }
    }

    return items.take(20).toList();
  }

  List<RoadmapItem> _parseRoadmap(String text) {
    final items = <RoadmapItem>[];
    final lines = text.split('\n');
    String currentPhase = 'MVP';

    for (final line in lines) {
      final trimmed = line.trim().toLowerCase();
      if (trimmed.contains('mvp')) {
        currentPhase = 'MVP';
      } else if (trimmed.contains('v1') || trimmed.contains('v1.0')) {
        currentPhase = 'v1.0';
      } else if (trimmed.contains('v2') || trimmed.contains('v2.0')) {
        currentPhase = 'v2.0';
      }

      final match =
          RegExp(r'^[\d]+[.)]\s+(.+)$').firstMatch(line.trim()) ??
              RegExp(r'^[-•*]\s+(.+)$').firstMatch(line.trim());

      if (match != null) {
        final title = match.group(1)!.trim();
        int priority = 1;
        if (title.toLowerCase().contains('optionnel') ||
            title.contains('3)') ||
            title.contains('priorité 3')) {
          priority = 3;
        } else if (title.toLowerCase().contains('important') ||
            title.contains('priorité 2')) {
          priority = 2;
        }

        items.add(RoadmapItem(
          title: title,
          phase: currentPhase,
          priority: priority,
        ));
      }
    }

    return items.take(30).toList();
  }

  String _parseError(String raw) {
    if (raw.contains('RESOURCE_EXHAUSTED') || raw.contains('quota')) {
      return 'Quota API dépassé. Vérifiez votre plan de facturation ou attendez le reset quotidien.';
    }
    if (raw.contains('INVALID_ARGUMENT') || raw.contains('invalid_api_key') || raw.contains('401')) {
      return 'Clé API invalide. Vérifiez votre clé dans les paramètres.';
    }
    if (raw.contains('403')) {
      return 'Accès refusé. Vérifiez les permissions de votre clé API.';
    }
    if (raw.contains('429')) {
      return 'Trop de requêtes. Attendez quelques secondes avant de réessayer.';
    }
    if (raw.contains('TimeoutException') || raw.contains('timeout')) {
      return 'Délai dépassé. Vérifiez votre connexion et réessayez.';
    }
    if (raw.contains('SocketException') || raw.contains('network')) {
      return 'Erreur réseau. Vérifiez votre connexion internet.';
    }
    // Fallback: extract message before first JSON brace
    final idx = raw.indexOf('{');
    if (idx > 0) return raw.substring(0, idx).trim();
    return raw.length > 200 ? '${raw.substring(0, 200)}…' : raw;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Messages list
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: _messages.length + (_loading ? 1 : 0),
            itemBuilder: (_, index) {
              if (index == _messages.length && _loading) {
                return _TypingIndicator();
              }
              return MessageBubble(message: _messages[index]);
            },
          ),
        ),

        // Prompt chips
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _promptChips.map((chip) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(
                      chip['label']!,
                      style: const TextStyle(
                          color: AppColors.primaryLight, fontSize: 12),
                    ),
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    side: BorderSide(
                        color: AppColors.primary.withOpacity(0.3)),
                    onPressed: _loading
                        ? null
                        : () => _sendMessage(chip['prompt']!),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Input area
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
                top: BorderSide(color: Color(0xFF2A2A4A), width: 1)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  style: const TextStyle(color: AppColors.onSurface),
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _sendMessage,
                  decoration: InputDecoration(
                    hintText: 'Posez une question sur votre projet...',
                    hintStyle: const TextStyle(
                        color: AppColors.onSurfaceMuted, fontSize: 14),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide:
                          const BorderSide(color: Color(0xFF2A2A4A)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide:
                          const BorderSide(color: Color(0xFF2A2A4A)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _loading
                      ? AppColors.onSurfaceMuted
                      : AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _loading
                      ? null
                      : () => _sendMessage(_inputController.text),
                  icon: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🤖', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.aiBubble,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: const Color(0xFF2A2A4A)),
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, __) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final offset = (i / 3);
                    final value =
                        (_controller.value - offset).clamp(0.0, 1.0);
                    final opacity = (value < 0.5
                            ? value * 2
                            : (1 - value) * 2)
                        .clamp(0.3, 1.0);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryLight,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
