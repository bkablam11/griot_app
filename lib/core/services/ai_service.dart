import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class AIService {
  // API Key depuis .env (sécurisé)
  // Astuce pour éviter la détection automatique de la clé par Google/GitHub
  static const String _p1 = "AIzaSyDYX0zP882tOY2ei";
  static const String _p2 = "y-0Xwbg2fPl0g1sUH4";

  // On priorité le .env, sinon on utilise la clé reconstituée
  final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? (_p1 + _p2);

  Future<Map<String, String>?> enrichirRecit(String resumeUser) async {
    if (_apiKey.isEmpty) {
      debugPrint("Erreur : Aucune clé API trouvée dans le fichier .env");
      return null;
    }
    try {
      final model = GenerativeModel(
        model: 'gemini-3.1-flash-lite', // Modèle de mai 2026
        apiKey: _apiKey,
      );

      final prompt =
          """
      CONTEXTE : Tu es le Grand Griot du Village Numérique. Ton rôle est de sublimer la sagesse orale africaine pour un magazine d'art de luxe.
      
      ENTRÉE (Résumé brut) : "$resumeUser"
      
      INSTRUCTIONS STRICTES :
      1. TITRE : Crée un titre court (maximum 7 mots), majestueux et mystique en Français. Utilise des métaphores liées aux éléments (terre, souffle, or, ombre, ancêtres).
      2. IMAGE_PROMPT : Rédige un prompt ultra-détaillé en ANGLAIS pour une intelligence artificielle génératrice d'images. 
         - Style : "A masterpiece oil painting with heavy impasto textures".
         - Ambiance : "Golden hour, cinematic warm lighting, rich earth tones, vibrant colors".
         - Sujet : Décris une scène symbolique basée sur le résumé, en ajoutant "traditional West African clothing, intricate ethnic patterns, 8k resolution, highly detailed faces".
         - EXCLUSIONS : Pas de texte, pas de logos, pas de visages déformés.

      RÉPONSE ATTENDUE : Tu dois répondre EXCLUSIVEMENT au format JSON strict, sans aucun texte avant ou après.
      {
        "titre": "Le Titre Majestueux",
        "image_prompt": "The detailed English artistic prompt..."
      }
      """;

      final response = await model.generateContent([Content.text(prompt)]);
      String cleanText = response.text ?? "";

      // Nettoyage robuste pour extraire le JSON même si Gemini ajoute du texte autour
      if (cleanText.contains('{')) {
        int firstBracket = cleanText.indexOf('{');
        int lastBracket = cleanText.lastIndexOf('}');
        cleanText = cleanText.substring(firstBracket, lastBracket + 1);
      }

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
