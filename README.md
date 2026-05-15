# AideChain Mobile — Application Agent Terrain

  > Compagnon mobile de la plateforme [AideChain](lien-vers-repo-web)
  > MIABE Hackathon 2026 · Flutter 3.41 · Dart 3.11

  ## Objectif

  Permettre aux agents terrain des ONG d'enregistrer des bénéficiaires et de distribuer
  des aides **même sans connexion internet**, avec synchronisation automatique dès que le
  réseau est rétabli.

  ## Écrans

  | Écran | Description |
  |-------|-------------|
  | **Login** | Authentification sécurisée · configuration dynamique de l'URL serveur |
  | **Dashboard** | Statut ONG · indicateur hors-ligne · synchronisation manuelle |
  | **Enregistrer bénéficiaire** | Formulaire complet · détection doublon en temps réel (cross-ONG) |
  | **Distribuer une aide** | Recherche bénéficiaire · sélection projet actif · confirmation |

  ## Flux principal

  ```
  Login → Dashboard
             ├── Enregistrer bénéficiaire
             │       └── Doublon détecté → bloqué avant enregistrement
             └── Distribuer une aide
                     ├── En ligne  → POST /api/aides (réponse immédiate)
                     └── Hors-ligne → sauvegarde SQLite → sync auto à reconnexion
  ```

  ## Architecture

  ```
  lib/
  ├── config/
  │   └── api.dart              # URL serveur (configurable, persistée)
  ├── services/
  │   ├── auth_service.dart     # Token · nom agent · nom ONG (SharedPreferences)
  │   ├── api_service.dart      # Client HTTP Dio — login, projets, bénéficiaires, aides
  │   ├── db_service.dart       # SQLite — file d'attente distributions hors-ligne
  │   └── sync_service.dart     # Envoi de la file au serveur + gestion doublons (409)
  └── screens/
      ├── login_screen.dart
      ├── dashboard_screen.dart
      ├── enregistrer_beneficiaire_screen.dart
      └── distribuer_aide_screen.dart
  ```

  ## Mode hors-ligne

  - Détection réseau via `connectivity_plus`
  - Distributions sauvegardées dans SQLite si hors-ligne
  - Synchronisation automatique à la reconnexion
  - Code `409 Conflict` du serveur = doublon déjà distribué → retiré de la file proprement

  ## Stack

  | Élément | Technologie |
  |---------|-------------|
  | Framework | Flutter 3.41.9 · Dart 3.11.5 |
  | HTTP | Dio 5.x |
  | Stockage local | SharedPreferences · SQLite (sqflite) |
  | Réseau | connectivity_plus |
  | Localisation | flutter_localizations · intl (fr_FR) |

  ## Lancement

  ```bash
  flutter pub get
  flutter run          # émulateur ou device USB
  flutter build apk --debug   # APK Android
  ```

  Configurer l'URL serveur depuis l'écran Login → "Configurer l'URL du serveur"
  Exemple : `http://192.168.1.x:8000`

  ## API consommée

  | Méthode | Endpoint | Description |
  |---------|----------|-------------|
  | `POST` | `/api/login` | Authentification agent |
  | `POST` | `/api/logout` | Déconnexion |
  | `GET` | `/api/projets` | Projets actifs de l'ONG |
  | `GET` | `/api/beneficiaires/check` | Vérification doublon |
  | `POST` | `/api/beneficiaires` | Enregistrement bénéficiaire |
  | `POST` | `/api/aides` | Distribution d'aide |

  ---

  Projet réalisé dans le cadre du **MIABE Hackathon 2026** — Édition MBH 2026.
