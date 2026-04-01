import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/project.dart';
import '../models/ai_provider.dart';
import '../services/storage_service.dart';
import '../app_theme.dart';
import 'chat_screen.dart';

class ProjectScreen extends StatefulWidget {
  final AppProject project;

  const ProjectScreen({super.key, required this.project});

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AppProject _project;
  final _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _tabController = TabController(length: 4, vsync: this);
    _saveProject();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _saveProject() async {
    await _storageService.saveProject(_project);
  }

  void _onProjectUpdated(AppProject updated) {
    setState(() => _project = updated);
    _storageService.saveProject(updated);
  }

  Future<void> _shareProject() async {
    final buffer = StringBuffer();
    buffer.writeln('# ${_project.name}');
    buffer.writeln();
    buffer.writeln('**Description :** ${_project.description}');
    buffer.writeln();

    if (_project.features.isNotEmpty) {
      buffer.writeln('## Features');
      for (int i = 0; i < _project.features.length; i++) {
        buffer.writeln('${i + 1}. ${_project.features[i]}');
      }
      buffer.writeln();
    }

    if (_project.userStories.isNotEmpty) {
      buffer.writeln('## User Stories');
      for (int i = 0; i < _project.userStories.length; i++) {
        buffer.writeln('${i + 1}. ${_project.userStories[i]}');
      }
      buffer.writeln();
    }

    if (_project.roadmap.isNotEmpty) {
      buffer.writeln('## Roadmap');
      for (final phase in ['MVP', 'v1.0', 'v2.0']) {
        final items =
            _project.roadmap.where((r) => r.phase == phase).toList();
        if (items.isNotEmpty) {
          buffer.writeln('### $phase');
          for (final item in items) {
            buffer.writeln('- ${item.title} (P${item.priority})');
          }
        }
      }
    }

    buffer.writeln();
    buffer.writeln(
        'Généré avec Create Mobile App - Propulsé par ${_project.providerUsed != null ? AIProvider.fromType(_project.providerUsed!).name : "IA"}');

    await Share.share(buffer.toString(), subject: _project.name);
  }

  @override
  Widget build(BuildContext context) {
    final providerEmoji = _project.providerUsed != null
        ? AIProvider.fromType(_project.providerUsed!).logoEmoji
        : '🤖';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _project.name,
              style: const TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              children: [
                Text(providerEmoji, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text(
                  _project.providerUsed != null
                      ? AIProvider.fromType(_project.providerUsed!).name
                      : '',
                  style: const TextStyle(
                      color: AppColors.onSurfaceMuted, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _shareProject,
            icon: const Icon(Icons.ios_share_outlined),
            tooltip: 'Exporter',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.chat_bubble_outline, size: 18), text: 'Chat'),
            Tab(icon: Icon(Icons.star_outline, size: 18), text: 'Features'),
            Tab(icon: Icon(Icons.person_outline, size: 18), text: 'Stories'),
            Tab(icon: Icon(Icons.map_outlined, size: 18), text: 'Roadmap'),
          ],
          labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.onSurfaceMuted,
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: _shareProject,
        backgroundColor: AppColors.secondary,
        child: const Icon(Icons.share, color: Colors.black),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ChatTab(
            project: _project,
            onProjectUpdated: _onProjectUpdated,
          ),
          _FeaturesTab(
            project: _project,
            onProjectUpdated: _onProjectUpdated,
          ),
          _UserStoriesTab(
            project: _project,
            onProjectUpdated: _onProjectUpdated,
          ),
          _RoadmapTab(
            project: _project,
            onProjectUpdated: _onProjectUpdated,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Features Tab ────────────────────────────────────

class _FeaturesTab extends StatelessWidget {
  final AppProject project;
  final ValueChanged<AppProject> onProjectUpdated;

  const _FeaturesTab({required this.project, required this.onProjectUpdated});

  @override
  Widget build(BuildContext context) {
    if (project.features.isEmpty) {
      return _EmptyTabState(
        emoji: '⭐',
        title: 'Aucune feature encore',
        subtitle:
            'Allez dans l\'onglet Chat et dites "Génère des features" pour commencer.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: project.features.length,
      itemBuilder: (_, i) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF2A2A4A)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      color: AppColors.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  project.features[i],
                  style: const TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────── User Stories Tab ────────────────────────────────

class _UserStoriesTab extends StatelessWidget {
  final AppProject project;
  final ValueChanged<AppProject> onProjectUpdated;

  const _UserStoriesTab(
      {required this.project, required this.onProjectUpdated});

  @override
  Widget build(BuildContext context) {
    if (project.userStories.isEmpty) {
      return _EmptyTabState(
        emoji: '📋',
        title: 'Aucune user story encore',
        subtitle:
            'Allez dans l\'onglet Chat et dites "Crée les user stories" pour commencer.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: project.userStories.length,
      itemBuilder: (_, i) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF2A2A4A)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      color: AppColors.primaryLight,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  project.userStories[i],
                  style: const TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────── Roadmap Tab ─────────────────────────────────────

class _RoadmapTab extends StatelessWidget {
  final AppProject project;
  final ValueChanged<AppProject> onProjectUpdated;

  const _RoadmapTab({required this.project, required this.onProjectUpdated});

  static const Map<String, Color> _phaseColors = {
    'MVP': Color(0xFF10B981),
    'v1.0': Color(0xFF3B82F6),
    'v2.0': Color(0xFF8B5CF6),
  };

  static const Map<int, String> _priorityLabels = {
    1: 'Critique',
    2: 'Important',
    3: 'Optionnel',
  };

  static const Map<int, Color> _priorityColors = {
    1: AppColors.error,
    2: AppColors.secondary,
    3: AppColors.onSurfaceMuted,
  };

  @override
  Widget build(BuildContext context) {
    if (project.roadmap.isEmpty) {
      return _EmptyTabState(
        emoji: '🗺️',
        title: 'Aucune roadmap encore',
        subtitle:
            'Allez dans l\'onglet Chat et dites "Propose une roadmap" pour commencer.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: ['MVP', 'v1.0', 'v2.0'].map((phase) {
        final items =
            project.roadmap.where((r) => r.phase == phase).toList();
        if (items.isEmpty) return const SizedBox.shrink();

        final phaseColor = _phaseColors[phase] ?? AppColors.primary;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 10, top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: phaseColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: phaseColor.withOpacity(0.4)),
              ),
              child: Text(
                phase,
                style: TextStyle(
                  color: phaseColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            ...items.map((item) {
              final priorityColor =
                  _priorityColors[item.priority] ?? AppColors.onSurfaceMuted;
              final priorityLabel =
                  _priorityLabels[item.priority] ?? 'Normal';

              return Container(
                margin: const EdgeInsets.only(bottom: 8, left: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border(
                    left: BorderSide(color: phaseColor, width: 3),
                    top: const BorderSide(color: Color(0xFF2A2A4A)),
                    right: const BorderSide(color: Color(0xFF2A2A4A)),
                    bottom: const BorderSide(color: Color(0xFF2A2A4A)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          color: AppColors.onSurface,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        priorityLabel,
                        style: TextStyle(
                          color: priorityColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }
}

// ─────────────────────────── Empty State ─────────────────────────────────────

class _EmptyTabState extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;

  const _EmptyTabState({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.onSurfaceMuted,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
