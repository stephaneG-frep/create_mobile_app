import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/ai_provider.dart';
import '../models/project.dart';
import '../services/secure_storage_service.dart';
import '../widgets/provider_chip.dart';
import '../app_theme.dart';
import 'project_screen.dart';

class NewProjectScreen extends StatefulWidget {
  const NewProjectScreen({super.key});

  @override
  State<NewProjectScreen> createState() => _NewProjectScreenState();
}

class _NewProjectScreenState extends State<NewProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  AIProviderType _selectedProvider = AIProviderType.openai;
  bool _checking = false;
  final _secureStorage = SecureStorageService();

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _checking = true);

    final hasKey = await _secureStorage.hasApiKey(_selectedProvider);
    if (!hasKey) {
      if (mounted) {
        setState(() => _checking = false);
        final providerName =
            AIProvider.fromType(_selectedProvider).name;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Veuillez configurer votre clé API $providerName dans les paramètres.'),
            backgroundColor: AppColors.error,
            action: SnackBarAction(
              label: 'Paramètres',
              textColor: AppColors.secondary,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        );
      }
      return;
    }

    final project = AppProject(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      createdAt: DateTime.now(),
      providerUsed: _selectedProvider,
    );

    if (mounted) {
      setState(() => _checking = false);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ProjectScreen(project: project),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nouveau Projet'),
        backgroundColor: AppColors.surface,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.2),
                    AppColors.secondary.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.3), width: 1),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('💡', style: TextStyle(fontSize: 32)),
                  SizedBox(height: 8),
                  Text(
                    'Décrivez votre idée d\'app',
                    style: TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'L\'IA va générer les features, user stories et roadmap pour vous.',
                    style: TextStyle(
                        color: AppColors.onSurfaceMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Project Name
            const _FieldLabel(text: 'Nom du projet'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: AppColors.onSurface),
              decoration: const InputDecoration(
                hintText: 'Ex: MonApp Fitness, TravelBuddy...',
                prefixIcon: Icon(Icons.apps),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Nom requis' : null,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // Description
            const _FieldLabel(text: 'Description de l\'idée'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descController,
              style: const TextStyle(color: AppColors.onSurface),
              maxLines: 5,
              decoration: const InputDecoration(
                hintText:
                    'Décrivez votre app en détail : cible, problème résolu, fonctionnalités clés...',
                alignLabelWithHint: true,
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Description requise' : null,
            ),
            const SizedBox(height: 24),

            // Provider selection
            const _FieldLabel(text: 'Choisir le fournisseur IA'),
            const SizedBox(height: 12),
            SizedBox(
              height: 130,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: AIProvider.all.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final p = AIProvider.all[i];
                  return SizedBox(
                    width: 90,
                    child: ProviderCard(
                      provider: p,
                      isSelected: _selectedProvider == p.type,
                      onTap: () =>
                          setState(() => _selectedProvider = p.type),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Text(
                      AIProvider.fromType(_selectedProvider).logoEmoji,
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    'Modèle : ${AIProvider.fromType(_selectedProvider).defaultModel}',
                    style: const TextStyle(
                        color: AppColors.onSurfaceMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _checking ? null : _submit,
                icon: _checking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('🚀', style: TextStyle(fontSize: 18)),
                label: Text(
                  _checking ? 'Création...' : 'Créer le projet',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.onSurface,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
