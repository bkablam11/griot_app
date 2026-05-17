# 🎤 GRIOT APP

**Plateforme collaborative de collecte et partage d'histoires traditionnelles**

Griot App est une application Flutter qui valorise et préserve le patrimoine culturel en permettant la collecte, l'enrichissement et le partage d'histoires orales traditionnelles. L'application combine l'enregistrement audio, l'enrichissement IA et un système communautaire pour créer une bibliothèque vivante d'histoires.

---

## ✨ Fonctionnalités Implémentées

### 🔐 Authentification & Sécurité
- **Connexion anonyme sécurisée** via Firebase Auth
- **Liaison Google Sign-in** : Possibilité de convertir compte anonyme en Gmail
- **Gestion automatique des tokens** et sessions persistantes
- **Stockage sécurisé** : Fichiers audio uploadés sur Supabase Storage (bucket `audios`)
- **Permissions avancées** : Vérification Android/iOS pour microphone et fichiers

### 🎙️ Enregistrement Audio Professionnel
- **Enregistrement audio en temps réel** avec visualisation de la durée (mm:ss)
- **Sélection de fichiers existants** via file picker (import d'enregistrements antérieurs)
- **Upload multiplateforme** : Support Web (bytes) et Mobile (fichier)
- **Nommage automatique** : Fichiers générés avec timestamp unique
- **Gestion d'erreurs robuste** : Feedback utilisateur en cas de problème

### 🤖 Enrichissement IA
- **Génération de titre** : Analyse du contenu audio via Google Generative AI (Gemini)
- **Image prompt généré** : Création automatique de descriptions pour illustrations
- **Intégration transparente** : Enrichissement exécuté après enregistrement
- **Modèle optimisé** : Utilisation de `gemini-3.1-flash-lite` pour performances rapides

### 📚 Modèles de Données
- **StoryModel complet** : `id`, `title`, `elderName`, `language`, `audioUrl`, `summary`, `createdAt`
- **Persistance locale** : Hive (TypeId: 0) pour synchronisation offline
- **Firestore collection** : Stockage en cloud avec structure `stories/{storyId}`
- **Sous-collections votes** : Système de likes persistent et versionnée

### 🗺️ Navigation & UI Responsive
- **MainScreen** : Navigation principale avec BottomNavigationBar contextualisée
- **HomePage** : Écran d'accueil avec boutons d'action principaux
- **VillagePage** : Galerie magazine en GridView (1 colonne mobile, 3 colonnes desktop)
- **RecordPage** : Interface complète d'enregistrement avec formulaire
- **StoryDetailPage** : Lecteur audio intégré + section votes/commentaires
- **ActualitePage** : Fil d'actualité avec mise en avant du TOP récit du jour
- **Design cohérent** : Police Cormorant Garamond, palette couleurs marron/beige (#8C6239, #F5F5F0)

### 👍 Système de Votes Gamifié
- **Like quotidien** : Un utilisateur = un vote par jour par histoire
- **Décompte en temps réel** : Affichage du temps restant jusqu'à minuit (hh:mm:ss)
- **TOP Récit du jour** : Calcul automatique de l'histoire la plus likée
- **Historique persistant** : Votes tracés en Firestore subcollection `votes`
- **Interface visuelle intuitive** : Compteur mis à jour en temps réel

### 🏗️ Architecture & Infrastructure
- **Structure modulaire** : Organisation claire en `core/`, `features/`, `shared/`
- **Flutter dotenv** : Gestion sécurisée des clés API (.env)
- **Build runner + Hive generator** : Génération de code pour modèles typés
- **Multiplateforme** : Support iOS, Android, Web, Windows, macOS, Linux
- **Gestion d'état fluide** : Contexte build et vérifications mounted

### 🔄 Services Backend Intégrés
- **AuthService** : Gestion authentification anonyme + Google
- **StorageService** : Upload/téléchargement Supabase Storage optimisé
- **AIService** : Enrichissement Gemini avec gestion d'erreurs
- **URL publiques automatiques** : Génération URLs Supabase accessibles

---

## 🛠️ Pile Technologique

**Framework** : Flutter 3.8+  
**Backend** : Firebase (Auth, Firestore) + Supabase (Storage)  
**IA** : Google Generative AI (Gemini)  
**Base Données Local** : Hive  
**Audio** : Record package  
**UI** : Material 3, Google Fonts  

**Dépendances principales** :
```yaml
firebase_core: ^3.15.2
cloud_firestore: ^5.6.12
firebase_auth: ^5.7.0
google_sign_in: ^6.3.0
supabase_flutter: ^2.12.4
google_generative_ai: ^0.4.7
record: ^5.2.1
file_picker: ^8.0.0
hive: ^2.2.3
dotenv: ^5.1.0
```

---

## 📋 Prérequis

- **Flutter SDK** : 3.8.1+
- **Dart** : 3.8+
- **Node.js** : 18+ (pour Firebase CLI)
- **Compte Firebase** : Créé et configuré
- **Compte Supabase** : Bucket `audios` initialisé
- **Google Cloud API Key** : Pour Generative AI

---

## 🚀 Installation & Setup

### 1. Cloner le projet
```bash
git clone <repository-url>
cd griot_app
```

### 2. Configurer les variables d'environnement
Créer un fichier `.env` à la racine :
```env
GOOGLE_GENERATIVE_AI_API_KEY=your_gemini_api_key
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

### 3. Installer les dépendances
```bash
flutter clean
flutter pub get
```

### 4. Générer le code (Hive, FirebaseAuth, etc.)
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 5. Lancer l'application
```bash
# Développement
flutter run

# Web
flutter run -d chrome

# Build Web
flutter build web --release --dart-define=FLUTTER_WEB_RENDERER=html --no-tree-shake-icons
```

---

## 🔨 Build & Déploiement

### Build Web (Production)
```bash
flutter clean
flutter pub get
flutter build web --release --dart-define=FLUTTER_WEB_RENDERER=html --no-tree-shake-icons
```

### Déploiement Firebase Hosting
```bash
firebase deploy --only hosting
```

### Build Android
```bash
flutter build apk --release
# ou pour AAB (recommandé Play Store)
flutter build appbundle --release
```

### Build iOS
```bash
flutter build ios --release
```

---

## 📁 Structure du Projet

```
lib/
├── core/
│   ├── app_theme.dart          # Thème couleurs et typographie
│   ├── models/                 # Models (StoryModel, etc.)
│   └── services/               # Services (AuthService, StorageService, AIService)
├── features/
│   ├── collection/             # Feature enregistrement (RecordPage)
│   ├── home/                   # HomePage
│   ├── village/                # VillagePage + StoryDetailPage
│   └── actualite/              # ActualitePage
├── shared/                     # Composants réutilisables
└── main.dart                   # Point d'entrée + GriotApp

android/                        # Configuration Android + google-services.json
ios/                            # Configuration iOS
web/                            # Configuration Web
```

---

## 📝 Commandes Utiles

```bash
# Formater le code
flutter format .

# Analyser le code (linting)
flutter analyze

# Tester
flutter test

# Voir les logs
flutter logs

# Simuler sur appareil/émulateur
flutter run -d <device_id>

# Profiler la performance
flutter run --profile
```

---

## 🐛 Tests

Pour exécuter les tests (widget + unit) :
```bash
flutter test
```

---

## 📱 Compatibilité

- ✅ **iOS** : 11.0+
- ✅ **Android** : API 21+
- ✅ **Web** : Chrome, Firefox, Safari
- ✅ **Windows** : 10+
- ✅ **macOS** : 10.14+
- ✅ **Linux** : Ubuntu 18.04+

---

## 🎯 Roadmap (Fonctionnalités à venir)

- 📊 Système de Rangs (Apprenti → Griot d'Or)
- 🌊 Waveform audio visualisation
- 🔍 Recherche & Filtrage avancés
- ❤️ Système de Favoris
- 🔔 Notifications Push Firebase
- 🌍 Localisation i18n (FR, EN, Dioula, Baoulé)
- 📊 Analytics Firebase
- 🔗 Deep Linking & Partage social
- 📸 Génération d'images AI pour les histoires

---

## 📞 Support & Contribution

Pour toute question ou suggestion, veuillez ouvrir une issue sur le repository.

---

**Version** : 1.0.0  
**Dernière mise à jour** : Mai 2026  
**Statut** : 60% MVP complété - Phase 2 en cours
