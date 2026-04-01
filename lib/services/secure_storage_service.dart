import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/ai_provider.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  String _keyFor(AIProviderType type) => 'api_key_${type.name}';

  Future<void> saveApiKey(AIProviderType type, String key) async {
    await _storage.write(key: _keyFor(type), value: key);
  }

  Future<String?> getApiKey(AIProviderType type) async {
    return _storage.read(key: _keyFor(type));
  }

  Future<bool> hasApiKey(AIProviderType type) async {
    final key = await getApiKey(type);
    return key != null && key.isNotEmpty;
  }

  Future<void> deleteApiKey(AIProviderType type) async {
    await _storage.delete(key: _keyFor(type));
  }
}
