# Widget Flutter "Messe" dans aelf-flutter (Phase 4)

## Statut : ✅ Implémentée (2026-07-15) — vérification visuelle manuelle recommandée

Tous les changements ci-dessous ont été appliqués :
- `dart format` + `dart analyze` sur tout `lib/` : propre, aucune régression (les 28 alertes existantes sont toutes préexistantes, ailleurs dans le code)
- `flutter run -d macos` : l'app compile et se lance sans crash (process actif, logs normaux). Le socket du Dart VM Service n'a pas pu s'ouvrir dans cet environnement sandboxé (sans rapport avec le code applicatif) et la capture d'écran n'a pas été possible faute d'accès à l'affichage — **la vérification visuelle interactive (naviguer vers "Messe (nouveau)", activer le flag, tester les dates/modes tab-scroll) n'a pas pu être automatisée ici et reste à faire manuellement.**

## Context

Les phases 1-3 (dans `offline-liturgy`, branche `masses`) ont livré un pipeline Mass complet et exporté (`massDetection`, `massExport`, classes `Mass`/`Masses`). Il reste à construire la vue Flutter qui l'exploite, sur le modèle de `morning_view` — dernière étape du plan initial.

`aelf-flutter` suit une architecture à 4 couches déjà bien établie et documentée (`docs/office_display.md`) : `BaseOfficeViewState<W,T>` (chargement, sélection célébration/commun) → `XxxOfficeDisplay` (tabs/scroll) → widgets communs (`ScriptureWidget`, `AntiphonWidget`, `CelebrationChipsSelector`, `buildOrationWidgets`, etc.). Morning/Vespers/Readings suivent tous exactement ce patron ; Mass doit faire pareil.

Deux blocages trouvés en explorant, à lever avant que la vue soit utilisable :
- `pubspec.yaml` épingle `offline_liturgy` sur un commit antérieur à tout le travail Mass (`975d9b3c...`), 10+ commits de retard sur `main`. Le pipeline Mass n'existe que sur la branche `masses` (actuellement `cef6fef8`, poussée sur GitHub).
- Aucune section "Messe offline" n'existe dans la navigation (`app_sections.dart`, `liturgy_screen.dart`, `LiturgyState`) — seule l'ancienne messe basée sur l'API web AELF (`mass_parser.dart`, section `"messes"`) existe.

Décisions validées avec l'utilisateur :
- `pubspec.yaml` épinglé sur le commit actuel de `masses` (`cef6fef82d1464528c4fdd08be948057aa63c0ad`), pas sur le nom de branche.
- La nouvelle vue **coexiste** avec l'ancienne "Messe" (API AELF) — ne la remplace pas. Cohérent avec `AGENTS.md` : *"Do not brake the existing liturgy (compline, mass, vesper, etc.) that uses external API [...] until the offline liturgy feature and branch get stable and merged."*
- Structure de la Liturgie de la Parole : un onglet par lecture (nommé par position), **avec les deux modes tab et scroll** comme les autres offices (pas de mode simplifié).

Particularité de Mass à noter : `massDetection` peut produire **plusieurs entrées pour un même jour** (ex: Rameaux → procession + messe de la Passion ; Pâques → vigile + messe du jour), chacune avec un `massName` distinct mais le même `isCelebrable`. Plutôt que construire un sélecteur dédié, on réutilise `CelebrationChipsSelector` tel quel : il traite naturellement ces variantes comme des "célébrations" alternatives sélectionnables par chips — cela fonctionne mécaniquement sans code neuf, au prix d'un libellé générique ("Choisir la célébration" plutôt que "Choisir la messe"). Précédent : l'ancienne messe (`mass_parser.dart`) résolvait déjà ce même problème via un menu de choix.

## Changements

### 1. `pubspec.yaml`
Changer le `ref:` de la dépendance git `offline_liturgy` de `975d9b3c27a333f97994bf29468b8bbb1d33a9de` à `cef6fef82d1464528c4fdd08be948057aa63c0ad`. Lancer `flutter pub get` ensuite (régénère `pubspec.lock`).

### 2. Nouveau fichier : `lib/widgets/offline_liturgy_mass_view.dart`

Sur le modèle exact de `offline_liturgy_morning_view.dart` :

- **`MassView`** (`StatefulWidget`, params `massList: Map<String, CelebrationContext>`, `date`, `calendar`) → `_MassViewState extends BaseOfficeViewState<MassView, Mass>` avec `celebrationList => widget.massList`, `debugOfficeName => 'Mass'`, `hasInputChanged` (date + massList), `exportOffice: (ctx) => massExport(ctx)`, `buildOfficeDisplay(...) => MassOfficeDisplay(...)`.

- **`MassOfficeDisplay`** — dual mode tab/scroll piloté par `context.watch<LiturgyState>().useScrollMode`, exactement comme `MorningOfficeDisplay`. Contrairement à Morning (qui a un état local pour le choix du psaume d'invitatoire), Mass n'a besoin d'aucun état interne mutable — `StatelessWidget` suffit.

  Sections/onglets, dans l'ordre, chacune conditionnelle si les données sont vides (comme les autres offices) :
  1. **Office** *(si `_hasMultipleCelebrations` ou commun nécessaire)* — `_OfficeTab` : copie quasi verbatim du `_OfficeTab` de `morning_view` (logique 100% générique, déjà dupliquée à l'identique dans Vespers/Readings — même convention, pas de nouvelle abstraction partagée).
  2. **Introduction** — `OfficeHeaderDisplay` (identique aux autres offices) + `AntiphonWidget` sur `entranceAntiphon` (jusqu'à 3 `MassAntiphon.content`) + `buildOrationWidgets(collect)`.
  3. **Une section par `MassReadingPart`** de `readingParts`, labellisée par position (fonction `_readingPartLabel`) :
     - `READING`/`EPISTLE` → `ScriptureWidget` (déjà quasi identique : `title`/`reference: biblicalRef`/`content`) ; options multiples au sein d'une même part (ex: choix Col 3 / 1 Co 5 à Pâques) séparées par "ou" (même idiome que `buildOrationWidgets`).
     - `PSALM`/`CANTICLE` → nouveau petit widget (`_MassPsalmContent`, privé au fichier) : titre (`refAbbr`/`biblicalRef`) + refrain (`chorus: List<MassChorusEntry>`, rendu simple façon antienne) + texte (`YamlTextFromString`, même pipeline de marquage que le reste des contenus Mass).
     - `GOSPEL` → nouveau petit widget (`_MassGospelContent`) : titre/référence + antiennes d'acclamation (`beforeAcclamationAntiphon`/`acclamationAntiphon`/`afterAcclamationAntiphon`) + texte justifié (style `ScriptureWidget`).
     - Labellisation (`_readingPartLabel`) : compte le nombre total de parts de chaque famille (lecture vs psaume) ; 1 seule → "Lecture"/"Psaume" ; 2 → "1ère lecture"/"2ème lecture" ; plus (vigile pascale) → "Lecture 1", "Lecture 2"… Gospel toujours "Évangile" (unique).
  4. **Offrandes** — `buildOrationWidgets(offeringPrayer)` ; `prefaceList` affiché en simple texte de référence s'il est présent (pas de bibliothèque de textes de préfaces existante — hors scope).
  5. **Communion** — `AntiphonWidget` sur `communionAntiphon` + `buildOrationWidgets(prayerAfterCommunion)`.
  6. **Bénédiction** — `buildOrationWidgets(solemnBlessingList)` si présent.

  Les libellés de section spécifiques à la Messe (Lecture, Psaume, Évangile, Offrandes, Communion, Bénédiction…) sont codés en dur en français dans le widget plutôt qu'ajoutés à `liturgyLabels` du package `offline_liturgy` — cohérent avec le précédent déjà présent dans `morning_view` (`Tab(text: 'Benedictus')` en dur), et garde ce changement scopé à `aelf-flutter` uniquement.

### 3. Câblage navigation
- `lib/data/app_sections.dart` : ajouter `AppSectionItem(title: "Messe (nouveau)", name: "offline_mass", ...)`, sur le modèle de `"Laudes (nouveau)"` → `offline_morning`. L'entrée "Messe" existante reste inchangée (coexistence).
- `lib/states/liturgyState.dart` : ajouter `Map<String, CelebrationContext> offlineMass = {}`, une méthode `getOfflineMass(dateTime, region)` (calque de `getOfflineMorning`, utilisant `FlutterDataLoader` + `massDetection`), et un `case 'offline_mass':` dans le switch de `updateLiturgy()`.
- `lib/app_screens/liturgy_screen.dart` : ajouter `case "offline_mass":` retournant `MassView(massList: liturgyState.offlineMass, date: ..., calendar: ...)` avec le même garde "spinner tant que vide" que les autres cas.
- `lib/widgets/left_menu.dart` : **aucun changement** — `offline_mass` est automatiquement filtré par la règle existante (`name.startsWith('offline_') && !offlineEnabled → false`), et `'messes'` n'étant pas ajouté à `_aelfReplacedOffices`, les deux entrées coexistent quand le flag est actif, comme décidé.
- `lib/app_screens/aelf_home_page.dart` : **aucun changement** — le `FIXME` préexistant sur le nombre de pages codé en dur (`List.generate(10, ...)` vs ~19 `appSections`) n'est pas dans le scope de cette phase ; une entrée de plus ne fait qu'accentuer un écart déjà toléré (les sauts de page sont déjà clampés). `_computeCurrentOffice()`/`offlineMap` n'est pas non plus modifié : la détection automatique du dimanche continue de pointer vers la messe historique, cohérent avec la coexistence.

## Vérification
- `flutter pub get` après le bump de `pubspec.yaml`, vérifier que `massDetection`/`massExport`/`Mass` sont bien résolus (`dart analyze` ne doit rapporter aucune erreur d'import).
- `dart format lib` puis `dart analyze` / `flutter analyze` sur tout `lib/` (convention du projet, cf. `AGENTS.md`).
- Lancer l'app (`flutter run`), activer le flag `feature_offline_liturgy` dans les réglages, vérifier que "Messe (nouveau)" apparaît dans le menu à côté de "Messe", et que l'ancienne messe fonctionne toujours à l'identique (non-régression explicitement demandée par `AGENTS.md`).
- Tester la nouvelle vue sur plusieurs jours représentatifs (mêmes dates que la vérification du pipeline en phase 3) : un dimanche ordinaire, un jour de semaine, un dimanche des Rameaux (2 messes sélectionnables), Pâques (vigile + jour) — en mode onglets et en mode scroll (bascule via le réglage global).
- Vérifier l'alignement des colonnes (règle `AGENTS.md` sur `LiturgyRow`/`hideVerseIdPlaceholder`) sur les nouveaux widgets `_MassPsalmContent`/`_MassGospelContent`.

## Suite
Aucune — phase 4 est la dernière étape du plan initial (schéma YAML → classe → pipeline → widget Flutter).
