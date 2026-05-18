# 📜 CAHIER DES CHARGES : APPLICATION "GRIOT" (V2.0)

## 1. VISION ET OBJECTIFS
**Griot** est une plateforme universelle (Web & Mobile) dédiée à la préservation du patrimoine oral africain.
- **Mission** : Capturer la sagesse des anciens (contes, proverbes, généalogies) via l'audio.
- **Innovation** : Utiliser l'IA pour transformer un enregistrement brut en une œuvre d'art numérique (titre poétique + illustration artistique).
- **Philosophie** : Un design "Magazine de Luxe" qui traite la tradition avec le plus haut niveau d'élégance moderne.

---

## 2. PARCOURS UTILISATEURS (UX)
L'application distingue deux types d'accès :

### A. Le Visiteur (Anonyme)
- Accède instantanément au "Village" sans inscription.
- Peut lire les récits, écouter les audios et laisser des commentaires.
- Peut voter pour ses récits préférés (limité à 1 vote par jour par récit).
- Doit se connecter pour devenir "Collecteur".

### B. Le Collecteur (Authentifié via Google)
- Possède toutes les options du visiteur.
- Accède au module de **Collecte** (Enregistrement/Importation).
- Possède un **Tableau de Bord** ("Héritage") affichant son grade et ses statistiques.
- Gagne des points et monte en grade selon son activité.

---

## 3. IDENTITÉ VISUELLE (Design System)
L'esthétique est de type **"Brutalisme Élégant / Magazine Contemporain"**.

- **Palette de Couleurs** :
    - `Griot-Bg` (#F5F5F0) : Papier crème (fond principal).
    - `Griot-Ink` (#141414) : Noir profond (titres et boutons).
    - `Griot-Earth` (#8C6239) : Terre cuite (accents et progression).
    - `Griot-Olive` (#5A5A40) : Vert organique (icônes et secondaire).
- **Typographie** :
    - Titres : *Cormorant Garamond* (Serif, Italique, Majestueux).
    - Corps : *Inter* (Sans-serif, lisible, moderne).
- **Layout** : Responsive (1 colonne sur mobile, 3 colonnes en mode grille sur Web).

---

## 4. SPÉCIFICATIONS FONCTIONNELLES

### A. Module de Collecte ("L'Oracle")
1. **Saisie** : Nom de l'ancien, titre provisoire, langue, résumé manuel.
2. **Capture Audio** : 
    - Enregistrement direct avec retour visuel (pulsation/timer).
    - Importation de fichiers audio depuis le stockage local.
3. **Traitement Universel** : Gestion hybride des fichiers (Chemin physique sur Mobile, Flux binaire/Bytes sur Web).

### B. Le Laboratoire IA (Enrichissement)
1. **Gemini Engine** : Utilisation du prompt "Grand Griot" pour transformer le résumé en JSON contenant :
    - Un titre majestueux (7 mots max).
    - Un prompt artistique détaillé en anglais.
2. **Imagerie** : Génération d'image via URL dynamique (Pollinations.ai) avec système de `seed` aléatoire pour éviter les blocages.

### C. Le Village (Bibliothèque)
1. **Grille Magazine** : Affichage des cartes avec images IA, titres et compteurs de likes.
2. **Recherche & Filtres** : Recherche textuelle et filtrage par "Chips" de langues.
3. **Détail du Récit** : Lecteur audio, texte complet, likes et commentaires en temps réel.

### D. Système de Reconnaissance (Gamification)
1. **Logique des Rangs** :
    - *Apprenti* (0 récit)
    - *Messager* (3 récits)
    - *Gardien* (10 récits)
    - *Griot d'Or* (50 récits)
2. **Honneurs** : Cumul total des likes reçus.
3. **Fil d'Activité** : Journal public annonçant les nouveaux récits et les montées en grade.

---

## 5. ARCHITECTURE TECHNIQUE (STACK 100% GRATUITE)

| Composant | Solution retenue | Pourquoi ? |
| :--- | :--- | :--- |
| **Frontend** | Flutter | Multiplateforme (Web/Android/iOS) avec un seul code. |
| **Authentification** | Firebase Auth | Gestion facile de Google Sign-in et de l'anonymat. |
| **Base de Données** | Cloud Firestore | NoSQL temps réel (Streams) pour les likes/commentaires. |
| **Stockage Audio** | **Supabase Storage** | 1 Go gratuit sans carte bancaire requise. |
| **Stockage Local** | Hive | Mode offline-first pour la collecte sur le terrain. |
| **Moteur IA** | Gemini 1.5 Flash | Rapide, puissant et gratuit (Google AI Studio). |
| **Hébergement Web** | Firebase Hosting | Gratuit, rapide et gère le HTTPS nativement. |

---

## 6. MODÈLE DE DONNÉES (SCHEMA FIRESTORE)

### Collection `stories`
- `id` (String)
- `title` (String)
- `elderName` (String)
- `summary` (String)
- `audioUrl` (String)
- `imageUrl` (String)
- `language` (String)
- `likesCount` (Number)
- `collectorId` (String)
- `createdAt` (ISO8601 String)
- **Sub-collection** `comments` : `{text, userName, createdAt}`
- **Sub-collection** `votes` : `{userId, lastVotedDate, isCertified}`

### Collection `users`
- `uid` (String)
- `name` (String)
- `storiesCount` (Number)
- `rank` (Enum)
- `lastActive` (String)

### Collection `activities`
- `type` (Enum: new_story / rank_up)
- `userName` (String)
- `title/newRank` (String)
- `createdAt` (String)

---

## 7. RÈGLES MÉTIER ET SÉCURITÉ
1. **Anti-Triche** : Un seul vote par utilisateur par récit par cycle de 24h (réinitialisation à minuit).
2. **Certification** : Les votes des comptes Gmail sont flaggés `isCertified` pour les récompenses réelles.
3. **Secret d'API** : Les clés API doivent être obscurcies (coupées en deux dans le code) pour éviter la suppression automatique par les robots de sécurité.
4. **CORS Web** : Les domaines de production doivent être autorisés dans Google Cloud Console pour l'OAuth.

---

## 8. GUIDE D'INSTALLATION (POUR UN AUTRE LANGAGE)
1. Configurer un projet **Firebase** (Auth/Firestore).
2. Configurer un projet **Supabase** (Storage avec RLS Policy `true` pour `anon`).
3. Obtenir une clé **Google AI Studio** (Gemini).
4. Développer le module de capture audio (gestion spécifique des Blobs sur Web).
5. Créer la logique de transaction pour les montées en grade.
6. Déployer sur un serveur HTTPS (obligatoire pour le micro).

---
*Ce document sert de référence absolue pour le développement de la plateforme GRIOT. Il garantit la cohérence du projet quel que soit l'outil de développement utilisé.*