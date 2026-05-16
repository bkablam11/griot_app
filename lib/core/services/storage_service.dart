import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  final _client = Supabase.instance.client;

  /// Cette fonction accepte soit un [path] (Mobile), soit des [bytes] (Web)
  Future<String?> uploadAudio({
    String? localPath,
    Uint8List? fileBytes,
    required String fileName,
  }) async {
    try {
      if (kIsWeb) {
        // --- LOGIQUE WEB ---
        if (fileBytes == null) return null;
        await _client.storage
            .from('audios')
            .uploadBinary(
              fileName,
              fileBytes,
              fileOptions: const FileOptions(
                contentType: 'audio/mpeg',
                upsert: true,
              ),
            );
      } else {
        // --- LOGIQUE MOBILE (Android/iOS) ---
        if (localPath == null) return null;
        final file = File(localPath);
        await _client.storage
            .from('audios')
            .upload(
              fileName,
              file,
              fileOptions: const FileOptions(
                contentType: 'audio/mpeg',
                upsert: true,
              ),
            );
      }

      // Récupération de l'URL publique (Identique pour les deux)
      return _client.storage.from('audios').getPublicUrl(fileName);
    } catch (e) {
      debugPrint("❌ Erreur Storage Universel : $e");
      return null;
    }
  }
}
