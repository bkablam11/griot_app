import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  final _client = Supabase.instance.client;

  Future<String?> uploadAudio(String localPath, String fileName) async {
    try {
      final file = File(localPath);

      // Envoi du fichier vers Supabase
      await _client.storage
          .from('audios')
          .upload(
            fileName,
            file,
            fileOptions: const FileOptions(
              contentType: 'audio/mpeg', // Format pour .m4a/.mp3
              upsert: true,
            ),
          );

      // Récupération du lien public
      final String publicUrl = _client.storage
          .from('audios')
          .getPublicUrl(fileName);

      debugPrint(" Upload réussi : $publicUrl");
      return publicUrl;
    } catch (e) {
      debugPrint(" Erreur Upload Supabase : $e");
      return null;
    }
  }
}
