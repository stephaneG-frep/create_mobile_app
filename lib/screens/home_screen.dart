import 'package:flutter/material.dart';
import '../models/project.dart';
import '../services/storage_service.dart';
import '../widgets/project_card.dart';
import '../app_theme.dart';
import 'new_project_screen.dart';
import 'project_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storageService = StorageService();
  List<AppProject> _projects = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _loading = true);
    final projects = await _storageService.loadProjects();
    if (mounted) {
      setState(() {
        _projects = projects;
        _loading = false;
      });
    }
  }

  Future<void> _deleteProject(AppProject project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Supprimer le projet ?',
            style: TextStyle(color: AppColors.onSurface)),
        content: Text(
          'Voulez-vous vraiment supprimer "${project.name}" ? Cette action est irréversible.',
          style: const TextStyle(color: AppColors.onSurfaceMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler',
                style: TextStyle(color: AppColors.onSurfaceMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storageService.deleteProject(project.id);
      _loadProjects();
    }
  }

  void _openProject(AppProject project) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProjectScreen(project: project),
      ),
    );
    _loadProjects();
  }

  void _openNewProject() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NewProjectScreen()),
    );
    _loadProjects();
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Row(
          children: [
            Text('🚀', style: TextStyle(fontSize: 22)),
            SizedBox(width: 10),
            Text(
              'Mes Projets',
              style: TextStyle(
                color: AppColors.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_outlined,
                color: AppColors.onSurfaceMuted),
            tooltip: 'Paramètres',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewProject,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nouveau projet',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _projects.isEmpty
              ? _EmptyState(onCreateTap: _openNewProject)
              : RefreshIndicator(
                  onRefresh: _loadProjects,
                  color: AppColors.primary,
                  child: ListView(
                    padding: const EdgeInsets.only(top: 12, bottom: 100),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: Text(
                          '${_projects.length} projet${_projects.length > 1 ? 's' : ''}',
                          style: const TextStyle(
                            color: AppColors.onSurfaceMuted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      ..._projects.map(
                        (p) => ProjectCard(
                          project: p,
                          onTap: () => _openProject(p),
                          onDelete: () => _deleteProject(p),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreateTap;

  const _EmptyState({required this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ).createShader(bounds),
              child: const Text(
                '💡',
                style: TextStyle(fontSize: 72),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Aucun projet pour l\'instant',
              style: TextStyle(
                color: AppColors.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Créez votre premier projet et laissez l\'IA vous aider à développer votre idée d\'application mobile.',
              style: TextStyle(
                color: AppColors.onSurfaceMuted,
                fontSize: 15,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onCreateTap,
              icon: const Text('🚀', style: TextStyle(fontSize: 18)),
              label: const Text(
                'Créer mon premier projet',
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: const [
                _FeaturePill(emoji: '🤖', text: 'OpenAI GPT-4o'),
                _FeaturePill(emoji: '🧠', text: 'Claude'),
                _FeaturePill(emoji: '💎', text: 'Gemini'),
                _FeaturePill(emoji: '⚡', text: 'Grok'),
                _FeaturePill(emoji: '🌊', text: 'Mistral'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final String emoji;
  final String text;

  const _FeaturePill({required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A2A4A)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
                color: AppColors.onSurfaceMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
