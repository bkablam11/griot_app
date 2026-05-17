# 📋 TODO - GRIOT APP - AUDIT COMPLET

**Audit effectué**: 17 mai 2026  
**Statut Global**: 🔄 60% complet - Phase 1 SÉCURITÉ ✅, Phase 2 EN COURS  
**Auteur**: GitHub Copilot

---

## 🎯 AUDIT DE L'ÉTAT ACTUEL (17/05/2026)

### ✅ CE QUI FONCTIONNE BIEN

#### Architecture & Infrastructure
- ✅ Structure projet impeccable (core/, features/, shared/)
- ✅ Flutter dotenv pour API keys sécurisées
- ✅ Hive initialisé pour offline storage (village_box)
- ✅ Build runner + Hive generator configurés
- ✅ Dépendances bien organisées (firebase, supabase, gemini)

#### Authentification & Sécurité
- ✅ Firebase Auth (mode anonyme par défaut)
- ✅ Google Sign-in avec liaison compte anonyme → Gmail
- ✅ Vérification permissions sur iOS/Android
- ✅ Token gestion automatique
- ✅ Supabase Storage configuré (audios bucket)

#### Services Backend
- ✅ **AuthService** : Connexion anonyme + Google, sign-out
- ✅ **StorageService** : Upload audio (Mobile: fichier, Web: bytes)
- ✅ **AIService** : Enrichissement via Gemini (titre + image prompt)
- ✅ Récupération URL publique Supabase automatique

#### Modèles & Données
- ✅ StoryModel avec Hive (typeId: 0)
- ✅ Champs: id, title, elderName, language, audioUrl, summary, createdAt
- ✅ Conversion Map ↔ Model
- ✅ Firestore collection `stories` bien structurée
- ✅ Sous-collection `votes` pour système de likes quotidiens

#### UI/UX & Navigation
- ✅ **MainScreen** : BottomNavigationBar responsive (affiche/cache RecordPage si collecteur)
- ✅ **HomePage** : Écran d'accueil avec boutons d'action
- ✅ **VillagePage** : GridView magazine (1 col mobile, 3 col desktop)
- ✅ **RecordPage** : Enregistrement + formulaire complet
- ✅ **StoryDetailPage** : Lecteur audio + section votes + commentaires
- ✅ **ActualitePage** : Fil d'actualité avec TOP récit du jour
- ✅ Design cohérent (Cormorant Garamond, palette couleurs marron/beige)

#### Enregistrement & Upload Audio
- ✅ Widget `record` package pour capturing audio
- ✅ Affichage durée en temps réel (mm:ss)
- ✅ Sélection fichier audio existant (file_picker)
- ✅ Upload Supabase avec gestion Web/Mobile
- ✅ Génération nom fichier unique (timestamp)

#### Système de Votes
- ✅ Like par utilisateur + par jour
- ✅ Décompte jusqu'à minuit (hh:mm:ss)
- ✅ Calcul TOP story en temps réel
- ✅ Historique votes dans Firestore subcollection
- ✅ Interface visuelle du compteur

#### Autres
- ✅ Google Fonts (Cormorant Garamond) intégrées
- ✅ Responsive design (mobile/tablet/desktop)
- ✅ Gestion contexte build (mounted checks)
- ✅ Couleur background cohérente (#F5F5F0)

---

### ❌ CE QUI NE FONCTIONNE PAS OU EST INCOMPLET

#### Erreurs Critiques
- ❌ **Modèle Gemini invalide** : `gemini-3.1-flash-lite` n'existe pas
  - **Impact** : Enrichissement IA plantera en production
  - **Fix** : Remplacer par `gemini-1.5-flash` (modèle stable Google)

- ❌ **Test widget générique** : `test/widget_test.dart` teste un "Counter" inexistant
  - **Impact** : `flutter test` échouera
  - **Fix** : Adapter test pour GriotApp réelle

- ❌ **Aucune gestion d'erreurs** : Services manquent try-catch cohérents
  - **Impact** : Crashes utilisateur sans feedback
  - **Fix** : Ajouter snackbars + error logging

#### Fonctionnalités Manquantes - CRITIQUE

1. **Pas d'images dans les histoires**
   - Gemini génère `image_prompt` mais jamais utilisé
   - Pas d'appel Stable Diffusion / Imagen
   - Pas d'affichage image dans UI
   - **Impact** : UX très piètre, histoires sans visuel

2. **Pas de tests unitaires**
   - 0 test pour AIService, AuthService, StorageService
   - Pas de fixtures de données
   - Pas de mocking Firebase
   - **Impact** : Refactoring dangereux, regressions invisibles

3. **Pas de build Android/iOS validé**
   - Configuration Firebase OK mais jamais testé `flutter build apk`
   - Pas de test `flutter build ios` complet
   - Permissions Android/iOS basiques manquent

4. **Linting incomplet**
   - `flutter_lints: ^4.0.0` présent mais pas appliqué correctement
   - Pas de `.dart-define` pour analyse stricte
   - Imports inutilisés possibles

#### Fonctionnalités Manquantes - MVP

| Fonctionnalité | Statut | Complexité | Impact |
|---|---|---|---|
| **Système de Rangs** | ❌ Non commencé | ⭐⭐⭐ | Engagement utilisateur |
| **Waveform Audio** | ❌ Non commencé | ⭐⭐ | UX enregistrement |
| **Recherche & Filtrage** | ❌ Non commencé | ⭐⭐ | Découverte histoires |
| **Pagination Infinite** | ❌ Non commencé | ⭐⭐ | Performance mobile |
| **Système Favoris** | ❌ Non commencé | ⭐⭐ | Rétention utilisateur |
| **Notifications Push** | ❌ Non commencé | ⭐⭐⭐ | Engagement |
| **Deep Linking** | ❌ Non commencé | ⭐⭐ | Partage social |
| **Analytics** | ❌ Non commencé | ⭐ | Metrics d'usage |
| **Compression Audio** | ❌ Non commencé | ⭐⭐ | Optimisation stockage |
| **Cache Offline** | ❌ Non commencé | ⭐⭐ | UX sans connexion |
| **Localisation i18n** | ❌ Non commencé | ⭐⭐⭐ | Accessibilité |

---

## 🔴 CRITIQUE - À FAIRE EN PRIORITÉ (Blockers)

### Tâche 1: Corriger modèle Gemini
- **Priorité**: 🔴 BLOQUANT
- **Problème**: API appelle `gemini-3.1-flash-lite` qui n'existe pas
- **Fix**:
  ```dart
  // lib/core/services/ai_service.dart ligne 10
  // ❌ AVANT:
  model: 'gemini-3.1-flash-lite',
  
  // ✅ APRÈS:
  model: 'gemini-1.5-flash',
  ```
- **Test**: Enregistrer histoire → Enrichissement doit fonctionner sans crash
- **Temps est.**: 2 min

### Tâche 2: Corriger widget_test.dart
- **Priorité**: 🔴 BLOQUANT (flutter test échoue)
- **Problème**: Test "Counter" ne correspond pas à l'app
- **Fix**: Remplacer test entier par:
  ```dart
  void main() {
    testWidgets('GriotApp loads and renders', (WidgetTester tester) async {
      await tester.pumpWidget(const GriotApp());
      
      // L'app doit charger sans crash
      expect(find.byType(GriotApp), findsOneWidget);
      
      // HomePage doit être présent après .env chargé
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(HomePage), findsOneWidget);
    });
  }
  ```
- **Test**: `flutter test` doit passer
- **Temps est.**: 5 min

### Tâche 3: Ajouter gestion d'erreurs globale
- **Priorité**: 🔴 HAUTE (UX)
- **Tâches**:
  1. [ ] Ajouter try-catch dans tous les appels Gemini API
  2. [ ] Ajouter try-catch dans uploads Supabase
  3. [ ] Ajouter try-catch dans lectures Firestore
  4. [ ] Ajouter snackbars d'erreur utilisateur
  5. [ ] Exécuter `flutter analyze` → 0 warnings
- **Fichiers**: Tous les services + pages principales
- **Temps est.**: 1.5h

### Tâche 4: Implémenter images pour les histoires
- **Priorité**: 🔴 HAUTE (UX impact)
- **Statut**: À concevoir
- **Approches**:
  - **Option A** : Utiliser Stable Diffusion API (payant, meilleur qualité)
  - **Option B** : Utiliser ImageFX (gratuit mais limité)
  - **Option C** : Utiliser Placeholder + générer async après
- **À faire**:
  1. [ ] Choisir API image génération
  2. [ ] Ajouter champ `imageUrl` dans StoryModel + Firestore
  3. [ ] Modifier AIService pour appeler image API
  4. [ ] Afficher image dans StoryCard (VillagePage)
  5. [ ] Afficher image en hero animation dans StoryDetailPage
- **Temps est.**: 3-4h
- **Dépendance**: Correction modèle Gemini d'abord

---

## 🟡 HAUTE PRIORITÉ - CETTE SEMAINE

### Tâche 5: Implémenter Système de Rangs
**Concept**: Utilisateur gagne rang selon nombre d'histoires collectées
```
Apprenti (0-2 histoires)
Messager (3-9 histoires)
Gardien (10-49 histoires)
Griot d'Or (50+ histoires)
```

- [ ] Créer `UserStats` model (storiesCount, minutesSaved, rank)
- [ ] Ajouter Firestore subcollection `users/{userId}/stats`
- [ ] Fonction `calculateRank(storyCount) → String`
- [ ] UI: Badge rang dans MainScreen
- [ ] UI: Stats dans profil utilisateur
- [ ] Incrémenter counter après publication story

**Fichiers à créer**:
- `lib/core/models/user_stats.dart` (nouveau)
- `lib/core/services/user_service.dart` (nouveau)

**Complexité**: ⭐⭐⭐ Moyen (2h)
**Temps est.**: 2h

---

### Tâche 6: Ajouter Waveform Audio
**Permet visualisation ondes sonores pendant enregistrement**

- [ ] Ajouter `audio_waveforms: ^1.0.0` à pubspec.yaml
- [ ] Modifier RecordPage
- [ ] Intégrer `AudioWaveforms` widget avec `AudioRecorder`
- [ ] Afficher en temps réel pendant `isRecording`
- [ ] Design: Waveform marron (#8C6239) sur fond beige

**Fichiers à modifier**:
- `pubspec.yaml`
- `lib/features/collection/record_page.dart`

**Complexité**: ⭐⭐ Moyen (2.5h)
**Temps est.**: 2.5h

---

### Tâche 7: Ajouter Recherche & Filtrage
**SearchBar + filtres (langue, collecteur, date)**

- [ ] Ajouter SearchBar dans VillagePage
- [ ] Créer `SearchService` avec Firestore queries
- [ ] Filtres dropdown: Langue (Français, Dioula, Baoulé, ...)
- [ ] Filtres dropdown: Date (Plus récent, Plus ancien)
- [ ] Afficher résultats filtrés en temps réel
- [ ] Afficher badge nombre résultats

**Fichiers à créer**:
- `lib/core/services/search_service.dart` (nouveau)

**Complexité**: ⭐⭐ Moyen (2.5h)
**Temps est.**: 2.5h

---

### Tâche 8: Pagination Infinite Scroll
**Charger stories par lots au lieu de tout charger**

- [ ] Modifier VillagePage pour utiliser pagination
- [ ] Implémenter `ScrollController` + `limit(10)`
- [ ] Chaque scroll détecte fin list → charge 10 de plus
- [ ] Afficher loader spinner pendant chargement
- [ ] Tester sur 100+ stories

**Complexité**: ⭐⭐ Moyen (2h)
**Temps est.**: 2h

---

## 🟠 MOYEN TERME - PROCHAINES 2 SEMAINES

### Tâche 9: Système de Favoris
**Bookmark stories pour relire plus tard**

- [ ] Créer Firestore subcollection `users/{userId}/favorites`
- [ ] Ajouter bouton ❤️ dans StoryCard
- [ ] UI: Afficher coeur rouge si story favorite
- [ ] Créer FavoritesPage dans tabs
- [ ] Syncer avec tous les appareils

**Temps est.**: 2h

---

### Tâche 10: Notifications Firebase
**Notifier collecteur quand histoire est publiée**

- [ ] Ajouter `firebase_messaging: ^14.0.0`
- [ ] Créer `NotificationService`
- [ ] Configurer Android/iOS notifications
- [ ] Envoyer notification après publication story
- [ ] Tester sur devices réels

**Temps est.**: 3h

---

### Tâche 11: Deep Linking & Share
**Permettre partage de liens vers histoires**

- [ ] Implémenter Firebase Dynamic Links
- [ ] Ajouter bouton "Partager" dans StoryDetailPage
- [ ] Générer lien court vers story
- [ ] Tester: Partager → Ouvrir lien → Affiche history

**Temps est.**: 3h

---

### Tâche 12: Compression Audio
**Réduire taille fichiers audio avant upload**

- [ ] Ajouter `flutter_ffmpeg` ou `audio_compress`
- [ ] Compresser avant upload Supabase
- [ ] Réduire taille ~50%
- [ ] Maintenir qualité acceptable
- [ ] Tester bitrate optimale

**Temps est.**: 2h

---

### Tâche 13: Cache Images Offline
**Télécharger images quand connexion, afficher en offline**

- [ ] Ajouter `cached_network_image: ^3.0.0`
- [ ] Remplacer `Image.network` par `CachedNetworkImage` partout
- [ ] Télécharger images au background
- [ ] Afficher cache quand offline

**Temps est.**: 1.5h

---

### Tâche 14: Analytics Firebase
**Tracker événements utilisateur**

- [ ] Ajouter `firebase_analytics: ^10.0.0`
- [ ] Créer `AnalyticsService`
- [ ] Logger events: record_start, record_submit, story_viewed, etc.
- [ ] Vérifier events dans Firebase Console

**Temps est.**: 1h

---

## 🔵 OPTIONNEL - POLISH & FUTUR

### Tâche 15: Localisation i18n
**Support FR, EN + langues locales (Dioula, Baoulé, ...)**

- [ ] Ajouter `flutter_localizations` + `intl: ^0.20.2`
- [ ] Créer `lib/l10n/` avec fichiers `.arb`
- [ ] Traduire UI complète en FR + EN
- [ ] Ajouter sélecteur langue dans settings
- [ ] Supporter à minima: FR, EN, Dioula

**Temps est.**: 5h

---

### Tâche 16: Tests Unitaires
**Ajouter tests pour services critiques**

- [ ] Tester AIService (mock API Gemini)
- [ ] Tester AuthService (mock Firebase)
- [ ] Tester StorageService (mock Supabase)
- [ ] Tester SearchService queries
- [ ] Coverage ≥ 70%

**Temps est.**: 4h

---

### Tâche 17: Rate Limiting & Quotas
**Limiter uploads par utilisateur**

- [ ] Vérifier: Taille max audio 50MB
- [ ] Vérifier: Durée max 2h
- [ ] Vérifier: Quota 10 récits/jour par utilisateur
- [ ] Afficher avertissements à l'utilisateur
- [ ] Refuser si limites atteintes

**Temps est.**: 1h

---

## 📊 RÉSUMÉ PROGRESSION

| Phase | Tâches | Temps Est. | Priorité | Status |
|---|---|---|---|---|
| **Bugfix Critique** | 1-4 | 1.5h | 🔴 AUJOURD'HUI | 🔴 À FAIRE |
| **MVP Stabilisation** | 5-8 | 9h | 🟡 CETTE SEMAINE | 🟡 À FAIRE |
| **Fonctionnalités** | 9-14 | 16h | 🟠 PROCHAINES 2 SEM. | 🟡 À FAIRE |
| **Polish** | 15-17 | 10h | 🔵 OPTIONNEL | 🔵 À FAIRE |
| **TOTAL** | 17 | ~36h | - | 60% complet |

---

## 🚀 CHECKPOINTS CLÉS

- [x] **CHECKPOINT 1** (Phase 1) : Sécurité API ✅ **FAIT 16 MAI**
- [ ] **CHECKPOINT 2** (Phase 2) : Bugfix + Tests OK
- [ ] **CHECKPOINT 3** (Phase 2) : Rangs + Waveform + Recherche
- [ ] **CHECKPOINT 4** (Phase 3) : Favoris + Notifications
- [ ] **CHECKPOINT 5** (Phase 4) : Analytics + i18n optionnels
- [ ] **RELEASE MVP** : Play Store + App Store

---

## 📝 NOTES IMPORTANTES

### Problèmes Identifiés
- **Gemini API** : Modèle invalide → Fix immédiat
- **Test App** : Pas adapté → Fix immédiat
- **Images** : Critère UX manquant → À concevoir
- **Build** : Jamais testé `flutter build apk/ios` complet
- **Linting** : Warnings potentiels ignorés

### Recommandations
1. **Corriger les 2 premiers bugfix immédiatement** (30 min)
2. **Ajouter gestion d'erreurs** (1.5h) pour robustesse
3. **Implémenter images** (3-4h) pour UX
4. **Tester builds** complets avant feature supplémentaires
5. **Ajouter tests unitaires** en parallèle du dev

### Dépendances Entre Tâches
```
Tâche 1 (Fix Gemini) → Tâche 4 (Images)
Tâche 2 (Fix Tests) → Toutes autres (CI/CD)
Tâche 3 (Error Handling) → Toutes autres (Robustesse)
Tâche 5 (Rangs) → Tâche 10 (Notifications peut utiliser rangs)
```

---

**Généré le**: 17 mai 2026  
**Par**: GitHub Copilot - Audit Complet  
**Version**: 2.0 (Audit Détaillé)
