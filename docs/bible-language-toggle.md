# Bouton grec/hébreu pour le texte biblique (aelf-flutter)

## Contexte

Les bases `assets/bible_grc.db` (Nouveau Testament seul, pas de Septante) et `assets/bible_heb.db` (Ancien Testament massorétique, sans deutérocanoniques) viennent d'être ajoutées à côté de `assets/bible.db` dans aelf-flutter. Il n'existe aujourd'hui aucun code Dart qui les lise. L'objectif est de permettre de basculer l'affichage biblique français vers le grec ou l'hébreu, avec exactement le même bouton visuel que celui déjà utilisé pour les offices (cantiques/Te Deum), à deux endroits : l'écran de lecture de la Bible, et la "lecture biblique" de l'Office des lectures.

Décisions déjà validées :
- Bouton inline dans l'en-tête (pas un bouton global dans l'AppBar).
- Cycle Français → Grec → Hébreu.
- Les trois écrans partagent le même bouton/mécanisme : écran de lecture de la Bible, "lecture biblique" de l'Office des lectures, et lectures de la messe (1ʳᵉ lecture/épître, psaume responsorial, Évangile — y compris leurs formes brèves, qui passent par les mêmes widgets).
- Aucune des deux langues n'est jamais disponible pour le même livre aujourd'hui (grec = NT only, hébreu = AT only) : le cycle doit sauter silencieusement la langue absente.
- Quand la langue choisie n'a en réalité pas de texte pour le passage précis (chapitre/verset manquant à l'intérieur d'un livre par ailleurs disponible, ex. Psaume 9A/9B inexistant en hébreu), **repli silencieux** vers le français, sans aucun message ni changement visuel du bouton.

Aucune modification du package `offline_liturgy` n'est nécessaire : `bibleText()`, `BibleTextProvider`, `CachedBibleTextProvider`, `BibleVerse`, `parseBibleReference()` sont déjà exportés publiquement (`lib/offline_liturgy.dart` → `export 'tools/bible_text_provider.dart';`).

## 1. État partagé

**Nouveau fichier** `lib/utils/bible_language.dart` :
```dart
enum BibleLanguage { french, greek, hebrew }

extension BibleLanguageCycle on BibleLanguage {
  BibleLanguage get next => BibleLanguage.values[(index + 1) % BibleLanguage.values.length];
}
```

**`lib/utils/settings.dart`** : ajouter `keyBibleTextLanguage`, `getBibleTextLanguage()`/`setBibleTextLanguage()`, sur le modèle exact de `keyOriginalPsalmLanguage`/`getOriginalPsalmLanguage()`/`setOriginalPsalmLanguage()` déjà présents.

**`lib/states/liturgyState.dart`** : ajouter `BibleLanguage bibleTextLanguage = BibleLanguage.french;`, `initBibleTextLanguage()` (sur le modèle de `initCanticleLanguage()`, ligne ~1320) appelé depuis le constructeur, et :
```dart
/// Cycle Français -> Grec -> Hébreu pour [book] (abréviation affichée,
/// ex. 'Mt', 'Gn'), en sautant la langue absente pour ce livre (bible_grc.db
/// est NT seul, bible_heb.db AT seul — jamais les deux). Repli silencieux
/// vers le français si ni l'un ni l'autre n'existe pour ce livre.
Future<void> cycleBibleTextLanguage(String book) async {
  var candidate = bibleTextLanguage;
  for (var i = 0; i < BibleLanguage.values.length; i++) {
    candidate = candidate.next;
    if (candidate == BibleLanguage.french ||
        await BibleDbHelper.instance.hasBook(book, candidate)) {
      break;
    }
  }
  if (candidate == bibleTextLanguage) return;
  bibleTextLanguage = candidate;
  setBibleTextLanguage(candidate.name);
  notifyListeners();
}
```
Ce sondage au niveau du livre est la seule vérification *a priori* ; le manque ponctuel d'un chapitre/verset précis à l'intérieur d'un livre disponible (ex. Psaumes) est géré au moment de l'affichage (section 4), en repli silencieux, pas ici.

## 2. Couche données (aelf-flutter uniquement)

**`lib/utils/bibleDbProvider.dart`** : remplacer le singleton `BibleDbSqfProvider` par 3 instances nommées (`french`/`greek`/`hebrew`, `instance` = `french` conservé pour ne pas casser les appels existants), chacune ouvrant son propre fichier. Grec et hébreu s'ouvrent à la demande (pas au démarrage, pour ne pas copier +17 Mo d'assets à chaque lancement pour une fonctionnalité que l'utilisateur n'utilisera peut-être jamais) — `main.dart` continue d'appeler `BibleDbSqfProvider.instance.ensureDatabase()` (français) sans changement.

**`lib/utils/bibleDbHelper.dart`** :
- `getChapterVerses(book, chapter, {BibleLanguage language = BibleLanguage.french})` : résout la bonne instance via `BibleDbSqfProvider.forLanguage(language)`, et appelle désormais elle-même `ensureDatabase()` avant de lire (pour grec/hébreu, qui ne sont pas pré-ouvertes par `main.dart`).
- `getChapterNumber`/`getBookNameLong`/`searchVerses` **inchangées**, toujours sur la base française (métadonnées de navigation ; la recherche plein-texte FTS5 n'existe que sur `bible.db`).
- Nouvelle méthode `hasBook(String book, BibleLanguage language)`, avec un cache en mémoire des livres distincts par langue (une requête `SELECT DISTINCT book` par langue, au premier besoin) — utilisée par `cycleBibleTextLanguage`.

**`lib/utils/bible_text_provider.dart`** : généraliser `AppBibleTextProvider` en 3 instances sœurs (`french`/`greek`/`hebrew`, chacune `CachedBibleTextProvider`), même requête SQL que l'actuelle, juste sur la base correspondante. `base_office_view_state.dart` continue d'utiliser `AppBibleTextProvider.instance` (français) pour l'hydratation initiale de l'office — inchangé, le grec/hébreu est résolu à la demande à l'affichage (section 4), pas à l'hydratation.

## 3. Bouton réutilisable

**Nouveau fichier** `lib/widgets/offline_liturgy_common_widgets/bible_language_button.dart`, calqué sur `canticle_language_button.dart` :
```dart
class BibleLanguageButton extends StatelessWidget {
  final String book;
  final double zoom;
  const BibleLanguageButton({super.key, required this.book, this.zoom = 100});

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LiturgyState>().bibleTextLanguage;
    return LanguageTogglePill(
      active: language != BibleLanguage.french,
      onTap: () => context.read<LiturgyState>().cycleBibleTextLanguage(book),
      zoom: zoom,
      showHebrew: true,
    );
  }
}
```
Réutilise tel quel `LanguageTogglePill`/`LanguageToggleIcon` (`lib/widgets/offline_liturgy_common_widgets/language_toggle_pill.dart`), le bouton déjà utilisé pour les cantiques/Te Deum — aucune modification de ces fichiers.

**Emplacement 1 — `lib/app_screens/book_screen.dart`** : dans la `Row` d'en-tête de chaque page du `PageView.builder` (vers les lignes 189-233), entre le titre "Chapitre X"/"Psaume X" et le `PopupMenuButton` de choix du chapitre : `BibleLanguageButton(book: widget.bookNameShort!)`.

**Emplacement 2 — `lib/widgets/offline_liturgy_readings_view.dart`** : dans `_BiblicalReadingTabState._buildBiblicalReading` (vers la ligne 588), à côté du `BiblicalReferenceButton` existant (même ligne, alignée à droite) — uniquement quand `reading.ref` est non nul. Les lectures patristiques (`_PatristicReadingTab`, pas de champ `ref`) ne sont pas concernées.

**Emplacement 3 — `lib/widgets/offline_liturgy_mass_view.dart`** : trois widgets y affichent déjà une référence biblique suivie du texte français, selon exactement le même agencement (`LiturgyRow` → `Align(centerRight)` → `BiblicalReferenceButton`, puis le contenu) :
- `_MassScriptureWidget` (1ʳᵉ lecture/épître, ligne ~1198) — référence `reference`/contenu `content`.
- `_MassPsalmContent` (psaume responsorial, ligne ~1283) — référence `psalm.biblicalRef ?? psalm.refAbbr`/contenu `psalm.content`. Le bouton n'apparaît que si la référence commence par un code de livre reconnu par `parseBibleReference` (un `refAbbr` seul, ex. "36, 5", n'en a pas — voir `_formatChorusReference`) ; sinon juste le texte français, comme aujourd'hui.
- `_MassGospelContent` (Évangile, ligne ~1413) — référence `gospel.biblicalRef`/contenu `gospel.content`.
Les formes brèves (`shortReadingRef`/`shortReadingContent`, `shortBiblicalRef`/`shortContent`) sont déjà projetées vers ces mêmes champs avant affichage (voir le commentaire ligne ~165 : "biblicalRef/content" aplatis depuis les champs courts), donc elles héritent du bouton sans code supplémentaire. Hors périmètre, volontairement : les antiphons d'entrée/communion et le refrain du psaume (`AntiphonWidget`/`MassChorusEntry`, formules courtes plutôt que des lectures) et le verset d'acclamation de l'Alléluia — à signaler si tu les veux aussi.

Le livre pour `cycleBibleTextLanguage`/`BibleLanguageButton` s'obtient partout de la même façon : `parseBibleReference(reference).first.book` (déjà exporté par le package), dans un `try/catch` défensif — la référence ne portant pas de code de livre valide (psaume sans `biblicalRef`) désactive simplement le bouton à cet endroit.

## 4. Affichage du texte dans l'autre langue

**Nouveau fichier** `lib/widgets/offline_liturgy_common_widgets/bible_text_language_variant.dart` : équivalent générique (texte brut, pas `Psalm`) de `verseStyleFor`/`textDirectionFor` (`psalm_language_variant.dart`) — même police EzraSIL/Alegreya, même RTL pour l'hébreu.

**`book_screen.dart` → `BibleHtmlViewState`** : au lieu de charger une seule fois dans `initState`, `build()` surveille `context.watch<LiturgyState>().bibleTextLanguage` et relance `loadBible(language)` quand elle change. Si `getChapterVerses(..., language: language)` renvoie une liste vide (chapitre absent dans cette langue, ex. Psaume 9A), retomber silencieusement sur un second appel avec `BibleLanguage.french` pour ce chapitre précis — sans toucher à la préférence globale ni afficher de message, conformément au repli silencieux choisi.

**`lib/widgets/book_screen_build_page.dart`** : `BuildPage`/`BibleVerse`/`BibleVerseText` reçoivent la langue effectivement rendue (après repli éventuel) ; appliquer `bibleVerseStyleFor`/`bibleTextDirectionFor` (police, taille, `Directionality` RTL autour de la `ListView`).

**Trois autres points d'appel (Office des lectures + les 3 widgets de messe) partagent exactement le même besoin** : afficher `content` en français par défaut, et à la demande (toggle ≠ français) remplacer par `bibleText(ref, provider)`, avec mise en cache et repli silencieux sur `content` si indisponible. Pour éviter de dupliquer cette logique 4 fois, un seul petit widget partagé :

**Nouveau fichier `lib/widgets/offline_liturgy_common_widgets/bible_text_variant.dart`** :
```dart
final _bibleTextCache = <String, Future<String?>>{};

/// [reference]+[language] resolved via the package's bibleText(), cached
/// (module-level, survives navigating away and back) and never throwing —
/// bibleText() itself can raise FormatException; only the package's own
/// private _safeBibleText catches it, which this app has no access to.
Future<String?> cachedBibleText(String reference, BibleLanguage language) =>
    _bibleTextCache['$reference#${language.name}'] ??= bibleText(
            reference, AppBibleTextProvider.forLanguage(language))
        .catchError((_) => null);

/// Resolves to the text to actually show for [reference]/[frenchContent]
/// under the shared [LiturgyState.bibleTextLanguage] preference: the French
/// content directly when the preference is French or [reference] is null;
/// otherwise the other language's text, falling back silently to
/// [frenchContent] (no message, no change to the toggle) when unavailable.
/// [builder] renders the resolved (text, language actually shown).
class BibleTextVariant extends StatelessWidget {
  final String? reference;
  final String? frenchContent;
  final Widget Function(BuildContext, String text, BibleLanguage language) builder;

  const BibleTextVariant(
      {super.key, this.reference, this.frenchContent, required this.builder});

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LiturgyState>().bibleTextLanguage;
    if (language == BibleLanguage.french ||
        reference == null ||
        reference!.isEmpty) {
      return frenchContent == null
          ? const SizedBox.shrink()
          : builder(context, frenchContent!, BibleLanguage.french);
    }
    return FutureBuilder<String?>(
      future: cachedBibleText(reference!, language),
      builder: (context, snapshot) {
        final resolved = snapshot.data;
        final text = resolved ?? frenchContent;
        if (text == null) return const SizedBox.shrink();
        return builder(
            context, text, resolved != null ? language : BibleLanguage.french);
      },
    );
  }
}
```

**`offline_liturgy_readings_view.dart` → `_BiblicalReadingTabState._buildBiblicalReading`** : remplacer le bloc `if (reading.content != null) ... YamlTextFromString(reading.content!, ...)` par `BibleTextVariant(reference: reading.ref, frenchContent: reading.content, builder: (context, text, language) => ...)`, le `builder` reproduisant l'actuel `YamlTextFromString(text, textAlign: TextAlign.justify, initialLetter: true)` avec `bibleVerseStyleFor`/`bibleTextDirectionFor(language)` (RTL via `Directionality` si hébreu réellement affiché).

**`offline_liturgy_mass_view.dart` → `_MassScriptureWidget`, `_MassPsalmContent`, `_MassGospelContent`** : même remplacement, chacun avec son alignement existant (`TextAlign.left`, `rightIndentMultiplier: 0.75`, `initialLetter` seulement pour la lecture/l'Évangile).

## 5. Limite connue, assumée sans contournement

Vérifié directement par sondage SQL sur les 3 bases : les numéros de verset ne s'alignent pas toujours entre langues pour un même livre quand les traditions diffèrent (ex. Psaume 51 : le verset "3" français correspond au texte après la suscription, alors que l'hébreu numérote cette suscription elle-même comme versets 1-2 — donc verset "3" ≠ même contenu). Le découpage par étiquette de verset (`_slice` dans le package) ne peut pas détecter une coïncidence de numéro qui désigne un contenu différent. Risque réel mais limité en pratique au chemin de l'Office des lectures *si* une lecture biblique y référençait un psaume — ce qui n'arrive normalement jamais (les psaumes passent par la Psalmodie, un circuit séparé avec ses propres variantes `.hebrew`/`.greek` précalculées). Décision : ne pas tenter de détection (aucune des deux bases ne fournit de table d'alignement des versets) ; limitation documentée en commentaire au point d'appel, pas de garde-fou supplémentaire.

### Fichiers concernés
- `lib/utils/bible_language.dart` (nouveau)
- `lib/utils/settings.dart`
- `lib/states/liturgyState.dart`
- `lib/utils/bibleDbProvider.dart`
- `lib/utils/bibleDbHelper.dart`
- `lib/utils/bible_text_provider.dart`
- `lib/widgets/offline_liturgy_common_widgets/bible_language_button.dart` (nouveau)
- `lib/widgets/offline_liturgy_common_widgets/bible_text_language_variant.dart` (nouveau — police/RTL)
- `lib/widgets/offline_liturgy_common_widgets/bible_text_variant.dart` (nouveau — résolution/cache/repli partagés)
- `lib/app_screens/book_screen.dart`
- `lib/widgets/book_screen_build_page.dart`
- `lib/widgets/offline_liturgy_readings_view.dart`
- `lib/widgets/offline_liturgy_mass_view.dart`

## Vérification

- `flutter analyze` côté aelf-flutter après les modifications.
- Lancer l'app, ouvrir un livre du NT (ex. Matthieu) dans l'écran Bible : le bouton doit cycler Français → Grec → Français (hébreu sauté, absent du NT) ; ouvrir un livre de l'AT (ex. Genèse) : Français → Hébreu → Français (grec sauté).
- Ouvrir les Psaumes dans l'écran Bible, basculer en hébreu sur un chapitre comme 9A/9B : doit retomber silencieusement sur le texte français sans message.
- Dans l'Office des lectures d'un jour dont la première lecture est vétéro/néo-testamentaire, vérifier que le bouton apparaît près de la référence, bascule le texte affiché, et retombe silencieusement sur le français si la référence est introuvable dans l'autre langue.
- Dans la Messe du jour, vérifier le bouton sur la 1ʳᵉ lecture, le psaume responsorial (quand sa référence a un code de livre) et l'Évangile, y compris en forme brève quand elle existe (ex. un dimanche des Rameaux ou de la Passion).
- Vérifier visuellement le rendu RTL/police de l'hébreu (EzraSIL) dans les trois écrans.
