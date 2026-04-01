import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_provider.dart';
import '../services/secure_storage_service.dart';
import '../app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _secureStorage = SecureStorageService();
  final Map<AIProviderType, TextEditingController> _controllers = {};
  final Map<AIProviderType, bool> _obscured = {};
  final Map<AIProviderType, bool> _hasSaved = {};
  AIProviderType _selectedProvider = AIProviderType.openai;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    for (final p in AIProvider.all) {
      _controllers[p.type] = TextEditingController();
      _obscured[p.type] = true;
      _hasSaved[p.type] = false;
    }
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    _selectedProvider = AIProviderType.values.firstWhere(
      (e) => e.name == prefs.getString('selected_provider'),
      orElse: () => AIProviderType.openai,
    );
    for (final p in AIProvider.all) {
      final key = await _secureStorage.getApiKey(p.type);
      if (key != null && key.isNotEmpty) {
        _controllers[p.type]!.text = key;
        _hasSaved[p.type] = true;
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveKey(AIProviderType type) async {
    final value = _controllers[type]!.text.trim();
    if (value.isEmpty) {
      _showSnack('Veuillez entrer une clé API.', isError: true);
      return;
    }
    await _secureStorage.saveApiKey(type, value);
    setState(() => _hasSaved[type] = true);
    _showSnack('Clé API ${AIProvider.fromType(type).name} sauvegardée !');
  }

  Future<void> _deleteKey(AIProviderType type) async {
    await _secureStorage.deleteApiKey(type);
    _controllers[type]!.clear();
    setState(() => _hasSaved[type] = false);
    _showSnack('Clé API ${AIProvider.fromType(type).name} supprimée.', isError: true);
  }

  Future<void> _setSelectedProvider(AIProviderType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_provider', type.name);
    setState(() => _selectedProvider = type);
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: AppColors.surface,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SectionHeader(title: 'Fournisseur IA sélectionné'),
                const SizedBox(height: 8),
                _ProviderSelector(
                  selected: _selectedProvider,
                  onChanged: _setSelectedProvider,
                ),
                const SizedBox(height: 24),
                _SectionHeader(title: 'Clés API'),
                const SizedBox(height: 8),
                ...AIProvider.all.map((provider) => _ProviderApiKeyTile(
                      provider: provider,
                      controller: _controllers[provider.type]!,
                      obscured: _obscured[provider.type]!,
                      hasSaved: _hasSaved[provider.type]!,
                      isSelected: _selectedProvider == provider.type,
                      onToggleObscure: () => setState(
                          () => _obscured[provider.type] =
                              !_obscured[provider.type]!),
                      onSave: () => _saveKey(provider.type),
                      onDelete: () => _deleteKey(provider.type),
                      onSelect: () => _setSelectedProvider(provider.type),
                    )),
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.onSurfaceMuted,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _ProviderSelector extends StatelessWidget {
  final AIProviderType selected;
  final ValueChanged<AIProviderType> onChanged;

  const _ProviderSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AIProvider.all.map((p) {
        final isSelected = p.type == selected;
        return GestureDetector(
          onTap: () => onChanged(p.type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.2)
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : const Color(0xFF2A2A4A),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(p.logoEmoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  p.name,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.onSurface,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.check_circle,
                      color: AppColors.primary, size: 14),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ProviderApiKeyTile extends StatelessWidget {
  final AIProvider provider;
  final TextEditingController controller;
  final bool obscured;
  final bool hasSaved;
  final bool isSelected;
  final VoidCallback onToggleObscure;
  final VoidCallback onSave;
  final VoidCallback onDelete;
  final VoidCallback onSelect;

  const _ProviderApiKeyTile({
    required this.provider,
    required this.controller,
    required this.obscured,
    required this.hasSaved,
    required this.isSelected,
    required this.onToggleObscure,
    required this.onSave,
    required this.onDelete,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.primary : const Color(0xFF2A2A4A),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(provider.logoEmoji,
                  style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Text(
                provider.name,
                style: const TextStyle(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.bolt, color: AppColors.primary, size: 12),
                      SizedBox(width: 4),
                      Text('Actif',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                )
              else if (hasSaved)
                GestureDetector(
                  onTap: onSelect,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2A2A4A)),
                    ),
                    child: const Text('Activer',
                        style: TextStyle(
                            color: AppColors.onSurface, fontSize: 11)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  obscureText: obscured,
                  style: const TextStyle(
                      color: AppColors.onSurface, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: provider.apiKeyLabel,
                    hintText: 'sk-...',
                    suffixIcon: IconButton(
                      onPressed: onToggleObscure,
                      icon: Icon(
                        obscured
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 18,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: onSave,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  minimumSize: const Size(0, 50),
                ),
                child: const Text('Sauver'),
              ),
              if (hasSaved) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  tooltip: 'Supprimer la clé',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
