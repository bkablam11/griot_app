C'est une excellente approche. Avant de poser la première brique de code, il faut que le plan d'architecte soit impeccable. Voici le **Cahier des Charges complet et structuré** pour l'application **GRIOT**, optimisé pour Flutter et des solutions gratuites.

---

# CAHIER DES CHARGES : APPLICATION "GRIOT"

## 1. VISION & OBJECTIFS
**Griot** est une archive numérique de la sagesse africaine. 
- **Mission** : Capturer les récits oraux (contes, généalogies, conseils) avant qu'ils ne disparaissent.
- **Cible** : Les jeunes (Collecteurs) et les anciens (Griots).
- **Valeur Ajoutée** : Transformer un simple audio en une "pièce de collection numérique" grâce à l'IA (texte et image).

---

## 2. IDENTITÉ VISUELLE (Design System)
L'esthétique doit évoquer un **magazine d'art contemporain mélangé à des textures organiques**.

*   **Palette de Couleurs** :
    *   `Griot-Bg` (#F5F5F0) : Fond papier crème, reposant pour la lecture.
    *   `Griot-Ink` (#141414) : Texte noir profond, élégant.
    *   `Griot-Olive` (#5A5A40) : Pour les boutons secondaires et icônes liées à la nature.
    *   `Griot-Earth` (#8C6239) : Pour les accents importants (bouton d'enregistrement).
*   **Typographie** :
    *   Titres : *Cormorant Garamond* (Serif), gras et italique pour le luxe.
    *   Corps : *Inter* ou *Public Sans* (Sans-serif), pour une lisibilité parfaite.
*   **Style UI** : 
    *   Utilisation généreuse de l'espace vide (White space).
    *   Bordures fines, pas d'ombres portées lourdes (style "Flat Brutalism").

---

## 3. FONCTIONNALITÉS PRINCIPALES (MVP)

### A. Module de Collecte (Cœur du projet)
1.  **Formulaire de Contexte** : Saisie du titre, nom de l'ancien, lieu, et langue (ex: Baoulé, Dioula).
2.  **Enregistreur Offline-First** : 
    *   Enregistrement haute qualité (`.m4a`).
    *   Visualiseur d'ondes sonores (feedback visuel).
    *   Stockage local immédiat (pour éviter les pertes en cas de coupure réseau).
3.  **Résumé Manuel** : Le collecteur écrit 3-4 lignes en français résumant l'histoire (sert de base à l'IA).

### B. Le Laboratoire IA (Traitement Gratuit)
1.  **Enrichissement par Gemini 1.5 Flash** (Plan gratuit) :
    *   Analyse du résumé pour créer un titre accrocheur.
    *   Génération d'un "Prompt" artistique pour illustrer l'histoire.
2.  **Illustration (Image Generation)** : 
    *   Utilisation de l'API de **Pollinations.ai** ou **Hugging Face** (Gratuit) pour générer une image basée sur le récit.

### C. La "Grande Bibliothèque" (Le Village)
1.  **Flux Magazine** : Liste des histoires présentées sous forme de cartes élégantes (style Pinterest/Magazine).
2.  **Lecteur Immersif** : 
    *   Affichage de l'image générée en plein écran.
    *   Lecture de l'audio original.
    *   Affichage du texte enrichi.

### D. Profil & Héritage
1.  **Système de Rangs** : Apprenti -> Messager -> Gardien -> Griot d'Or (basé sur le nombre de collectes).
2.  **Statistiques** : Nombre de minutes de sagesse sauvegardées.

---

## 4. ARCHITECTURE TECHNIQUE

### Stack Logicielle (100% Gratuite)
*   **Framework** : Flutter (Multi-plateforme iOS/Android).
*   **Base de données Cloud** : Firebase Firestore (Tier gratuit).
*   **Stockage Fichiers** : Firebase Storage (pour les audios et images).
*   **Base de données Locale** : Isar ou Hive (pour le mode offline).
*   **Moteur IA** : Google Gemini API (Model: `gemini-1.5-flash`).
*   **Génération d'Image** : API Pollinations.ai (ou intégration Hugging Face).

### Flux de Données (Synchronisation)
1.  L'utilisateur enregistre -> Sauvegarde locale (`Isar` + Fichier `.m4a`).
2.  L'application détecte une connexion internet.
3.  Upload de l'audio vers `Firebase Storage`.
4.  Envoi du résumé à `Gemini`.
5.  Gemini renvoie le texte propre et le prompt d'image.
6.  Génération de l'image et sauvegarde finale dans `Firestore`.

---

## 5. MODÈLE DE DONNÉES (SCHEMA)

### Objet : `Story`
```dart
{
  "id": String,
  "title": String,
  "elder_name": String,
  "language": String,
  "summary_raw": String,      // Le résumé du jeune
  "content_ai": String,       // Le texte retravaillé par Gemini
  "audio_url": String,        // Lien Firebase Storage
  "image_url": String,        // Lien image générée
  "collector_id": String,     // ID de l'utilisateur
  "created_at": Timestamp,
  "is_published": Boolean     // Status de synchronisation
}
```

---

## 6. CONTRAINTES & RÈGLES MÉTIER
1.  **Respect de l'Ancien** : Toujours demander le nom de la source.
2.  **Qualité Audio** : L'application doit bloquer l'enregistrement si le micro n'est pas accessible.
3.  **Mode Hors-Ligne** : L'utilisateur doit pouvoir enregistrer 10 histoires sans jamais ouvrir internet.

---

## 7. PROCHAINES ÉTAPES (ROADMAP)
1.  **Phase 1** : Setup Flutter & Firebase + UI de base (Thème Magazine).
2.  **Phase 2** : Module d'enregistrement audio & stockage local.
3.  **Phase 3** : Intégration de l'IA (Gemini) pour le traitement des textes.
4.  **Phase 4** : Module de génération d'image et Mur communautaire.

---

**Es-tu d'accord avec ce cahier des charges ?** 
Si oui, nous pouvons passer à la **Phase 1** : La configuration de la structure du projet Flutter et la création du thème visuel (Couleurs et Polices).