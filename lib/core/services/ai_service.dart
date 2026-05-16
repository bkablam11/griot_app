import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class AIService {
  // API Key depuis .env (sécurisé)
  final String _apiKey = dotenv.env['GEMINI_API_KEY']!;

  Future<Map<String, String>?> enrichirRecit(String resumeUser) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-3.1-flash-lite',
        apiKey: _apiKey,
      );

      final prompt =
          """
      Tu es un Maître Griot, gardien de la mémoire africaine. 
      Je te donne un résumé d'une histoire : "$resumeUser"
      
      Instructions strictes :
      1. Crée un titre majestueux et poétique en Français.
      2. Crée un prompt artistique en ANGLAIS pour générer une image. 
        Le style doit être : "traditional African oil painting, warm lighting, high detail, ethnic art".
      
      Tu dois répondre UNIQUEMENT au format JSON comme ceci :
      {"titre": "le titre", "image_prompt": "the image prompt"}
      """;

      final response = await model.generateContent([Content.text(prompt)]);

      // Nettoyage de la réponse (Gemini met parfois des balises ```json)
      String cleanText = response.text!
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      // Décodage du JSON
      final Map<String, dynamic> data = jsonDecode(cleanText);

      return {
        "titre": data['titre'] ?? "Récit sans titre",
        "prompt": data['image_prompt'] ?? "African landscape painting",
      };
    } catch (e) {
      debugPrint(" Erreur Gemini : $e");
      return null;
    }
  }
}
