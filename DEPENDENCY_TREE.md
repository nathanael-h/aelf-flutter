# Arbre des dépendances - aelf-flutter

**Date d'analyse** : 2026-01-01
**Point d'entrée** : main.dart

## Vue d'ensemble

- **Total de fichiers internes** : 47 fichiers
- **Dépendances externes** : 17 packages
- **Architecture** : Application Flutter avec state management Provider
- **Pattern** : Séparation claire des responsabilités (states, screens, utils, widgets, parsers)

---

## Arbre complet des dépendances

```
main.dart
│
├── STATES MANAGEMENT (Provider Pattern)
│   │
│   ├── states/currentZoomState.dart
│   │   └── shared_preferences (externe)
│   │
│   ├── states/liturgyState.dart
│   │   ├── utils/flutter_data_loader.dart
│   │   ├── utils/liturgyDbHelper.dart
│   │   │   ├── sqflite (externe)
│   │   │   └── path (externe)
│   │   ├── utils/settings.dart
│   │   │   ├── shared_preferences (externe)
│   │   │   └── package_info_plus (externe)
│   │   ├── connectivity_plus (externe)
│   │   ├── offline_liturgy (package externe personnalisé)
│   │   │   ├── classes/calendar_class.dart
│   │   │   ├── classes/compline_class.dart
│   │   │   ├── classes/morning_class.dart
│   │   │   └── offices/compline/compline.dart
│   │   ├── logger (externe)
│   │   ├── device_info_plus (externe)
│   │   └── package_info_plus (externe)
│   │
│   ├── states/pageState.dart
│   │   └── (aucune dépendance interne)
│   │
│   └── states/featureFlagsState.dart
│       └── utils/settings.dart [PARTAGÉ]
│
├── THEME & UI
│   └── utils/theme_provider.dart
│       ├── flutter/cupertino.dart (externe)
│       ├── flutter/material.dart (externe)
│       └── shared_preferences (externe)
│
├── UTILS (Utilitaires)
│   ├── utils/bibleDbProvider.dart
│   │   ├── sqflite (externe)
│   │   ├── path (externe)
│   │   └── path_provider (externe)
│   │
│   ├── utils/datepicker.dart
│   │   ├── intl (externe)
│   │   └── flutter/material.dart (externe)
│   │
│   ├── utils/text_management.dart
│   │   └── (fonctions pures, aucune dépendance)
│   │
│   ├── utils/location_service.dart
│   │   ├── flutter/services.dart (externe)
│   │   ├── shared_preferences (externe)
│   │   └── dart:convert
│   │
│   └── utils/settings.dart [PARTAGÉ - utilisé par plusieurs modules]
│
├── ÉCRANS PRINCIPAUX
│   │
│   ├── app_screens/aelf_home_page.dart (Page d'accueil principale)
│   │   │
│   │   ├── ÉCRAN: À Propos
│   │   │   ├── app_screens/about_screen.dart
│   │   │   │   ├── data/changelog_data.dart
│   │   │   │   │   └── models/changelog_entry.dart
│   │   │   │   ├── widgets/changelog_tile.dart
│   │   │   │   ├── widgets/custom_expansion_tile.dart
│   │   │   │   ├── flutter_linkify (externe)
│   │   │   │   └── url_launcher (externe)
│   │   │
│   │   ├── ÉCRAN: Bible
│   │   │   ├── app_screens/bible_lists_screen.dart
│   │   │   │   ├── app_screens/book_screen.dart
│   │   │   │   │   ├── states/currentZoomState.dart [PARTAGÉ]
│   │   │   │   │   ├── widgets/book_screen_build_page.dart
│   │   │   │   │   ├── widgets/fr-fr_aelf.json.dart
│   │   │   │   │   ├── utils/bibleDbHelper.dart
│   │   │   │   │   │   ├── utils/bibleDbProvider.dart [PARTAGÉ]
│   │   │   │   │   │   ├── sqflite (externe)
│   │   │   │   │   │   ├── unorm_dart (externe)
│   │   │   │   │   │   └── diacritic (externe)
│   │   │   │   │   └── provider (externe)
│   │   │   │   └── widgets/fr-fr_aelf.json.dart [PARTAGÉ]
│   │   │   │
│   │   │   └── app_screens/bible_search_screen.dart
│   │   │       ├── app_screens/book_screen.dart [PARTAGÉ]
│   │   │       ├── widgets/fr-fr_aelf.json.dart [PARTAGÉ]
│   │   │       ├── utils/bibleDbHelper.dart [PARTAGÉ]
│   │   │       └── flutter_html (externe)
│   │   │
│   │   ├── ÉCRAN: Liturgie
│   │   │   └── app_screens/liturgy_screen.dart
│   │   │       │
│   │   │       ├── app_screens/liturgy_formatter.dart
│   │   │       │   ├── provider (externe)
│   │   │       │   ├── states/liturgyState.dart [PARTAGÉ]
│   │   │       │   ├── widgets/liturgy_tabs_view.dart
│   │   │       │   ├── parsers/liturgy_parser_service.dart
│   │   │       │   └── app_screens/liturgy_widget_builder.dart
│   │   │       │
│   │   │       ├── LITURGIE HORS LIGNE: Complies
│   │   │       │   └── widgets/offline_liturgy_compline_view.dart
│   │   │       │       ├── offline_liturgy (package externe) [PARTAGÉ]
│   │   │       │       ├── widgets/liturgy_part_rubric.dart
│   │   │       │       ├── widgets/liturgy_part_info_widget.dart
│   │   │       │       ├── app_screens/layout_config.dart
│   │   │       │       ├── widgets/liturgy_part_title.dart
│   │   │       │       ├── widgets/liturgy_part_formatted_text.dart
│   │   │       │       └── widgets/offline_liturgy_common_widgets/
│   │   │       │           ├── evangelic_canticle_display.dart
│   │   │       │           │   ├── widgets/liturgy_part_content_title.dart
│   │   │       │           │   ├── parsers/formatted_text_parser.dart
│   │   │       │           │   ├── offline_liturgy/assets/libraries/canticles_library.dart
│   │   │       │           │   └── app_screens/layout_config.dart
│   │   │       │           ├── scripture_display.dart
│   │   │       │           │   ├── widgets/liturgy_part_content_title.dart
│   │   │       │           │   ├── parsers/formatted_text_parser.dart
│   │   │       │           │   └── app_screens/layout_config.dart
│   │   │       │           ├── office_common_widgets.dart
│   │   │       │           │   ├── offline_liturgy/assets/libraries/hymns_library.dart
│   │   │       │           │   ├── offline_liturgy/assets/libraries/psalms_library.dart
│   │   │       │           │   ├── widgets/liturgy_part_content_title.dart
│   │   │       │           │   ├── widgets/liturgy_part_subtitle.dart
│   │   │       │           │   ├── parsers/formatted_text_parser.dart
│   │   │       │           │   ├── app_screens/layout_config.dart
│   │   │       │           │   └── widgets/offline_liturgy_common_widgets/psalms_display.dart
│   │   │       │           ├── antiphon_display.dart
│   │   │       │           │   ├── widgets/liturgy_part_content_title.dart
│   │   │       │           │   ├── parsers/formatted_text_parser.dart
│   │   │       │           │   └── app_screens/layout_config.dart
│   │   │       │           └── psalms_display.dart
│   │   │       │               ├── widgets/liturgy_part_commentary.dart
│   │   │       │               ├── widgets/liturgy_part_subtitle.dart
│   │   │       │               ├── widgets/liturgy_part_content_title.dart
│   │   │       │               ├── parsers/psalm_parser.dart ⭐
│   │   │       │               ├── parsers/hebrew_greek_yaml_parser.dart ⭐
│   │   │       │               ├── app_screens/layout_config.dart
│   │   │       │               ├── offline_liturgy/assets/libraries/psalms_library.dart
│   │   │       │               └── widgets/offline_liturgy_common_widgets/antiphon_display.dart
│   │   │       │
│   │   │       ├── LITURGIE HORS LIGNE: Laudes (Office du Matin)
│   │   │       │   └── widgets/offline_liturgy_morning_view.dart
│   │   │       │       ├── offline_liturgy (package externe) [PARTAGÉ]
│   │   │       │       ├── utils/liturgical_colors.dart
│   │   │       │       ├── services/morning_office_service.dart
│   │   │       │       ├── widgets/offline_liturgy_common_widgets/ [PARTAGÉ]
│   │   │       │       ├── widgets/liturgy_part_title.dart [PARTAGÉ]
│   │   │       │       ├── widgets/liturgy_part_formatted_text.dart [PARTAGÉ]
│   │   │       │       ├── parsers/psalm_parser.dart ⭐
│   │   │       │       ├── app_screens/layout_config.dart [PARTAGÉ]
│   │   │       │       └── yaml (externe)
│   │   │       │
│   │   │       ├── utils/flutter_data_loader.dart [PARTAGÉ]
│   │   │       ├── provider (externe)
│   │   │       └── offline_liturgy/tools/data_loader.dart
│   │   │
│   │   ├── ÉCRAN: Paramètres
│   │   │   └── app_screens/settings_screen.dart
│   │   │       ├── utils/text_management.dart
│   │   │       ├── states/currentZoomState.dart [PARTAGÉ]
│   │   │       ├── states/liturgyState.dart [PARTAGÉ]
│   │   │       ├── states/featureFlagsState.dart [PARTAGÉ]
│   │   │       ├── widgets/location_selector_widget.dart
│   │   │       ├── utils/location_service.dart
│   │   │       └── provider (externe)
│   │   │
│   │   ├── DONNÉES & CONFIGURATION
│   │   │   ├── data/app_sections.dart
│   │   │   │   └── models/app_section_item.dart
│   │   │   └── data/popup_menu_choices.dart
│   │   │       ├── models/popup_menu_choice.dart
│   │   │       ├── utils/theme_provider.dart [PARTAGÉ]
│   │   │       └── provider (externe)
│   │   │
│   │   ├── NAVIGATION
│   │   │   └── widgets/left_menu.dart
│   │   │       ├── data/app_sections.dart [PARTAGÉ]
│   │   │       ├── states/liturgyState.dart [PARTAGÉ]
│   │   │       ├── states/pageState.dart [PARTAGÉ]
│   │   │       ├── states/featureFlagsState.dart [PARTAGÉ]
│   │   │       ├── widgets/material_drawer_item.dart
│   │   │       └── provider (externe)
│   │   │
│   │   └── AUTRES DÉPENDANCES
│   │       ├── utils/datepicker.dart
│   │       ├── models/popup_menu_choice.dart [PARTAGÉ]
│   │       ├── utils/settings.dart [PARTAGÉ]
│   │       ├── states/liturgyState.dart [PARTAGÉ]
│   │       ├── states/pageState.dart [PARTAGÉ]
│   │       ├── utils/theme_provider.dart [PARTAGÉ]
│   │       ├── connectivity_plus (externe)
│   │       ├── package_info_plus (externe)
│   │       ├── shared_preferences (externe)
│   │       └── provider (externe)
│   │
│   └── app_screens/bible_lists_screen.dart [PARTAGÉ - référencé depuis PassArgumentsScreen]
│
├── DATABASE & STORAGE (Couche de persistance)
│   ├── utils/bibleDbProvider.dart [PARTAGÉ]
│   └── utils/liturgyDbHelper.dart [PARTAGÉ]
│
└── DÉPENDANCES EXTERNES (Packages Flutter)
    ├── flutter/material.dart
    ├── flutter/cupertino.dart
    ├── flutter/foundation.dart
    ├── flutter_localizations
    ├── provider (gestion d'état)
    ├── sqflite (base de données SQLite)
    ├── wakelock_plus (contrôle de l'écran)
    ├── connectivity_plus (vérification réseau)
    ├── shared_preferences (stockage local)
    ├── package_info_plus (infos application)
    ├── device_info_plus (infos appareil)
    ├── path_provider (chemins système)
    ├── intl (internationalisation)
    ├── offline_liturgy (package personnalisé)
    ├── logger (journalisation)
    ├── flutter_html (rendu HTML)
    ├── flutter_linkify (liens cliquables)
    ├── url_launcher (ouverture URLs)
    ├── diacritic (normalisation texte)
    ├── unorm_dart (normalisation Unicode)
    ├── yaml (parsing YAML) ⭐
    └── path (manipulation chemins)
```

---

## Légende

- `[PARTAGÉ]` : Module utilisé par plusieurs autres modules
- `⭐` : Parsers YAML (migration récente depuis HTML)
- `(externe)` : Package externe au projet

---

## Architecture en couches

### 1. Couche Présentation (UI)
- **Écrans** : 5 écrans principaux (home, bible, liturgy, settings, about)
- **Widgets** : Widgets réutilisables organisés par fonctionnalité
- **Layout** : Configuration centralisée dans `layout_config.dart`

### 2. Couche État (State Management)
- **Pattern** : Provider pour la gestion d'état réactive
- **States** :
  - `CurrentZoom` : Gestion du zoom (pinch-to-zoom)
  - `LiturgyState` : État central de la liturgie
  - `PageState` : Navigation entre pages
  - `FeatureFlagsState` : Activation de fonctionnalités

### 3. Couche Métier (Business Logic)
- **Services** : `morning_office_service.dart`
- **Parsers** :
  - `liturgy_parser_service.dart` (liturgie en ligne)
  - `psalm_parser.dart` (psaumes français YAML)
  - `hebrew_greek_yaml_parser.dart` (psaumes anciens YAML) ⭐
  - `formatted_text_parser.dart` (formatage texte liturgique)

### 4. Couche Données (Data Layer)
- **Base de données** :
  - `bibleDbProvider.dart` + `bibleDbHelper.dart` (Bible)
  - `liturgyDbHelper.dart` (Liturgie en ligne)
- **Chargement** :
  - `flutter_data_loader.dart` (assets Flutter)
  - Package `offline_liturgy` (données liturgiques hors ligne)

### 5. Couche Utilitaires
- **Settings** : Gestion des préférences utilisateur
- **Theme** : Thème clair/sombre
- **Location** : Service de géolocalisation
- **Text** : Manipulation de texte

---

## Points d'intégration clés

### 🔄 LiturgyState (Hub central)
Gère l'état de toute la liturgie de l'application :
- Chargement des données liturgiques (en ligne/hors ligne)
- Gestion du calendrier liturgique
- Intégration avec le package `offline_liturgy`
- Connexion réseau et synchronisation

### 📖 Système Bible (Autonome)
Système indépendant avec sa propre base de données :
- Recherche plein texte avec normalisation Unicode
- Navigation par livres/chapitres/versets
- Support du zoom
- Base SQLite locale

### 🕊️ Liturgie Hors Ligne (Feature Flag)
Système modulaire activable via `FeatureFlagsState` :
- **Complies** : Office du soir
- **Laudes** : Office du matin
- **Widgets partagés** : Psaumes, cantiques, antiennes, lectures
- **Format** : YAML uniquement (migration HTML → YAML complétée) ⭐

### 🎨 Parsers YAML (Migration récente)
Nouveaux parsers pour le format YAML :
- **Psaumes français** : `psalm_parser.dart`
  - Numéros de versets `{n}`
  - Markdown : `*italique*`, `_souligné_`
  - Caractères spéciaux : `R/`, `V/`, `*`, `+`
- **Psaumes hébreux/grecs** : `hebrew_greek_yaml_parser.dart`
  - Lettres hébraïques pour numéros (א, ב, ג...)
  - Numéros grecs `{n}`
  - Petusha (פ) en rouge
  - Direction texte auto (RTL/LTR)

---

## Modules partagés (utilisés plusieurs fois)

### États
- `states/currentZoomState.dart` (3+ références)
- `states/liturgyState.dart` (10+ références)
- `states/pageState.dart` (4+ références)
- `states/featureFlagsState.dart` (4+ références)

### Utilitaires
- `utils/settings.dart` (5+ références)
- `utils/theme_provider.dart` (3+ références)
- `utils/bibleDbProvider.dart` (2+ références)
- `utils/bibleDbHelper.dart` (2+ références)

### Widgets
- `widgets/fr-fr_aelf.json.dart` (Bible - 3+ références)
- `widgets/offline_liturgy_common_widgets/*` (Liturgie - 10+ références)
- `widgets/liturgy_part_title.dart` (5+ références)
- `widgets/liturgy_part_formatted_text.dart` (5+ références)

### Parsers
- `parsers/formatted_text_parser.dart` (5+ références)
- `parsers/psalm_parser.dart` (2+ références)

---

## Packages externes critiques

### État et UI
- **provider** : Gestion d'état réactive
- **flutter_localizations** : Localisation française

### Base de données
- **sqflite** : Base de données SQLite
- **shared_preferences** : Préférences utilisateur

### Réseau
- **connectivity_plus** : Détection connexion internet
- **url_launcher** : Ouverture URLs externes

### Texte et données
- **yaml** : Parsing des fichiers YAML liturgiques ⭐
- **intl** : Internationalisation et dates
- **diacritic** : Normalisation caractères accentués
- **unorm_dart** : Normalisation Unicode

### Package personnalisé
- **offline_liturgy** : Package Dart personnalisé contenant :
  - Classes de données (Calendar, Compline, Morning)
  - Bibliothèques (Psalms, Hymns, Canticles)
  - Logique métier des offices

---

## Évolution récente (2026-01-01)

### ✅ Migration HTML → YAML complétée
- Suppression de `hebrew_psalm_parser.dart` (HTML)
- Utilisation exclusive de `hebrew_greek_yaml_parser.dart`
- Tous les psaumes (français, hébreux, grecs) en format YAML
- Plus aucune dépendance HTML dans `psalms_display.dart`

### 🎯 Architecture actuelle
- **Format unique** : YAML pour toutes les données liturgiques
- **Parsers optimisés** : Parsers dédiés par type de contenu
- **Performance** : Lazy loading + mise en cache
- **Maintenabilité** : Code simplifié sans détection de format

---

## Notes de développement

1. **Imports relatifs** : Tous les imports utilisent le style `package:aelf_flutter/...`
2. **Séparation claire** : Logique métier séparée de l'UI
3. **Modularité** : Widgets et parsers réutilisables
4. **Feature Flags** : Activation progressive des fonctionnalités
5. **Offline-first** : Support hors ligne via package `offline_liturgy`
