# Affichage des offices offline — fonctionnement général

## Vue d'ensemble

L'affichage des offices repose sur une architecture en 4 couches :

1. **Données** : le package `offline_liturgy` résout et exporte le contenu liturgique
2. **État** : `BaseOfficeViewState` gère le cycle de vie (chargement, sélection, erreur)
3. **Affichage principal** : un widget `XxxOfficeDisplay` (stateless) orchestre les sections
4. **Widgets communs** : blocs réutilisables (antienne, psaume, en-tête, texte…)

---

## 1. Cycle de vie et chargement (`BaseOfficeViewState`)

`BaseOfficeViewState<W, T>` est la classe abstraite partagée par Laudes, Vêpres, Office des lectures et Milieu du jour. La Complies possède son propre état simplifié.

### Séquence de chargement

```
initState()
  └─ _loadOffice()
       ├─ Cherche la première célébration "célébrable" dans celebrationList
       ├─ Consulte SelectedCelebrationState pour respecter un choix global préexistant
       │   (uniquement si cette célébration a une priorité ≤ à la première option)
       ├─ Lit les versets imprécatoires (getImprecatoryVerses)
       ├─ Résout le commun par défaut (premier de la liste, ou choix global si cohérent)
       ├─ Appelle exportOffice(CelebrationContext) → Future<T>
       └─ setState() → buildOfficeDisplay(...)
```

### Déclencheurs de rechargement

| Événement | Méthode |
|---|---|
| Changement de date ou de liste | `didUpdateWidget` → `_loadOffice` |
| Changement source SVG ton psalmique | listener sur `LiturgyState` → `_loadOffice` |
| Utilisateur choisit une autre célébration | `_onCelebrationChanged` |
| Utilisateur choisit un autre commun | `_onCommonChanged` |
| Long press → override de précédence | `_onPrecedenceOverridden` → `_onCelebrationChanged` + animation shake |

### Animation shake

Lors d'un override de précédence (forçage en fête ou solennité), une animation `TweenSequence` translate l'affichage horizontalement (±6 px, 500 ms) pour signaler visuellement le changement.

---

## 2. Modes d'affichage : onglets vs scroll

Chaque office peut s'afficher dans deux modes contrôlés par `LiturgyState.useScrollMode` :

### Mode onglets (défaut)
```
DefaultTabController
  ├─ LiturgyTabBar           ← barre d'onglets colorée
  └─ PinchZoomSelectionArea
       └─ TabBarView          ← chaque section dans son propre widget scrollable
```
Chaque onglet contient un `ListView` indépendant. Le contenu n'est pas chargé tant que l'onglet n'est pas visité.

### Mode scroll
```
PinchZoomSelectionArea
  └─ CustomScrollView (ou SingleChildScrollView)
       ├─ SliverToBoxAdapter (section 1)
       ├─ SliverToBoxAdapter (Divider)
       ├─ SliverToBoxAdapter (section 2)
       …
```
Toutes les sections sont instanciées immédiatement avec `shrinkWrap: true` + `NeverScrollableScrollPhysics`. Les psaumes avec SVG utilisent `SliverStickyHeader` pour épingler le ton pendant le défilement.

---

## 3. Structure des offices

### Laudes (`MorningOfficeDisplay`)

| Onglet | Contenu |
|---|---|
| Office *(si nécessaire)* | Sélecteurs célébration + commun |
| Introduction | En-tête + texte d'introduction + invitatoire (psaume sélectionnable) |
| Hymnes | Sélecteur d'hymne |
| Psaume 1…N | Un psaume par onglet |
| Capitule | Lecture brève + répons |
| Benedictus | Cantique évangélique avec antiennes |
| Intercession | Texte + Pater Noster (expandable) |
| Oraison | Oraison(s) + bénédiction |

L'invitatoire possède un sélecteur de psaume par chips (cas multi-psaumes). En mode scroll, il est suivi directement du psaume sélectionné avec éventuel SVG sticky.

### Vêpres (`VespersOfficeDisplay`)

| Onglet | Contenu |
|---|---|
| Office *(si nécessaire)* | Sélecteurs célébration + commun |
| Introduction | En-tête + texte d'introduction |
| Hymnes | Sélecteur d'hymne |
| Psaume 1…N | Un psaume par onglet |
| Lecture | Lecture brève + répons |
| Magnificat | Cantique évangélique avec antiennes |
| Intercession | Texte + Pater Noster (expandable) |
| Oraison | Oraison(s) + bénédiction |

Identique aux Laudes dans sa structure, sans invitatoire.

### Office des lectures (`ReadingsOfficeDisplay`)

| Onglet | Contenu |
|---|---|
| Office *(si nécessaire)* | Sélecteurs célébration + commun |
| Introduction | En-tête + texte d'introduction |
| Lecture biblique | Titre + sous-titre + contenu + répons |
| Lecture patristique | Titre + sous-titre + contenu + répons |
| Te Deum | Texte (conditionnel) |
| Oraison | Oraison(s) |

### Complies (`ComplineOfficeDisplay`)

La Complies n'hérite pas de `BaseOfficeViewState`. Son état propre (`_ComplineViewState`) gère :
- La sélection du type de complies (dimanche, férial…) par chips
- Le chargement via `complineExport()`
- `getImprecatoryVerses()` pour les versets imprécatoires

| Onglet | Contenu |
|---|---|
| Office *(si > 1 type)* | Sélecteur de type de complies |
| Introduction | En-tête + commentaire éventuel + Confiteor (expandable) |
| Hymnes | Sélecteur d'hymne |
| Psaume 1…N | Un psaume par onglet |
| Lecture | Lecture brève + répons |
| Cantique de Siméon | Cantique avec antiennes |
| Oraison | Oraison(s) + conclusion |
| Hymnes mariales | Sélecteur hymne marial |

Pendant le chargement, un `LinearProgressIndicator` de 2 px s'affiche en haut via un `Stack`.

### Milieu du jour — Tierce / Sexte / None (`MiddleOfDayOfficeView`)

Un seul widget générique `MiddleOfDayOfficeView` sert les trois petites heures. Des sélecteurs passés en paramètre (`hymnSelector`, `hourOfficeSelector`, `psalmodySelector`) extraient la partie pertinente du `MiddleOfDay`.

| Onglet | Contenu |
|---|---|
| Office *(si nécessaire)* | Sélecteurs célébration + commun |
| Introduction | En-tête + texte d'introduction |
| Hymne | Sélecteur d'hymne |
| Psaume 1…N | Un psaume par onglet |
| Capitule | Lecture brève + répons + oraison + bénédiction courte |

---

## 4. Onglet "Office" — sélection de la célébration

L'onglet Office n'apparaît que si au moins une des conditions suivantes est vraie :
- Il y a plusieurs célébrations fêtables (`isCelebrable`)
- La fête nécessite un commun ET il y a plusieurs communs disponibles (ou la précédence > 8)

Exceptions : octave de Pâques et de Noël — pas de sélection de commun même s'il existe.

### `CelebrationChipsSelector`

Chaque célébration affichée comme `ChoiceChip` coloré selon la couleur liturgique. Les fêtes (précédence 5–11, sauf la mémoire de la Vierge) supportent le long press :
- Normal → Fête forcée (précédence 8)
- Fête/Mémoire → Solennité forcée (précédence 4)
- Solennité → retour à normal

Un retour haptique différencié (léger/moyen/fort) accompagne chaque niveau.

Les célébrations non fêtables sont affichées en italique dans une section séparée.

### `CommonChipsSelector`

Si un seul commun disponible (sans option "pas de commun"), il est affiché comme texte informatif simple. Sinon, chips de sélection avec option "Pas de commun" si la précédence > 8.

---

## 5. Widgets communs

### `OfficeHeaderDisplay`

Affiché en premier dans chaque onglet Introduction. Contient dans l'ordre :
1. Titre de l'office (`officeDescription`) — `fontSize: 18 * zoom/100`, gras, centré
2. Barre de couleur liturgique — hauteur fixe 6 px, radius 3
3. Informations complémentaires (`additionalInfo` = année liturgique + semaine) — `fontSize: 12 * zoom/100`, italique, aligné à droite ; sinon espace vide
4. Label de rang (`typeLabel`, ex. "Mémoire obligatoire") — `fontSize: 14 * zoom/100`, italique, centré
5. Boîte de description (`celebrationDescription`) — texte dans un conteneur bordé, `fontSize: 14 * zoom/100`

Tous les espacements verticaux sont proportionnels au zoom.

### `AntiphonWidget`

Affiche une à trois antiennes. Chaque antienne est une `Row` :
- Label coloré ("Ant.", "Ant. 1"…) — `fontSize: 13 * zoom/100`, couleur secondaire
- Texte via `YamlTextWidget` — `fontSize: 13 * zoom/100`, `paragraphSpacing: 4 * zoom/100`

Espacement inter-antiennes : `top: 3 * zoom/100` sur les antiennes 2 et 3.
Espacement effectif total entre deux antiennes = **4 + 3 = 7 px** au zoom 100.

### `PsalmDisplayWidget` / `PsalmDisplayHeader` + `PsalmDisplayBody`

Structure d'un psaume :
```
Titre (+ référence biblique en trailing)
Sous-titre (optionnel)
Commentaire (optionnel) + SizedBox(12 * zoom/100)
SizedBox(12 * zoom/100)
Antienne d'ouverture (optionnelle) + SizedBox(12 * zoom/100)
[SVG ton psalmique - si mode non-sticky]
Texte du psaume (PsalmFromMarkdown)
SizedBox(20 * zoom/100)
Antienne de clôture (optionnelle)
SizedBox(12 * zoom/100)
Verset après (optionnel)
```

`PsalmDisplayHeader` + `PsalmDisplayBody` sont les versions splitées pour le mode sticky SVG (sliver), utilisées quand `svgData` est présent en mode onglet ou scroll.

### `CanticleWidget` / `CanticleHeader` + `CanticleBody`

Canticle évangélique (Benedictus, Magnificat, Nunc Dimittis). Même logique de split header/body que les psaumes. Les antiennes sont dans `Map<String, List<String>>` : la clé peut être `'antiphon'` (unique), `'A'`/`'B'`/`'C'` (selon l'année liturgique), ou un index pour plusieurs antiennes.

### `ScriptureWidget`

Affiche une lecture courte : titre + référence + texte justifié. L'espacement entre titre et texte est `spacing ?? 16 * zoom/100`.

### `PsalmTabWidget`

Wrapper en mode onglet pour un psaume. Deux chemins :
- **Sans SVG** : `ListView` avec `PsalmDisplayWidget`
- **Avec SVG** : `CustomScrollView` avec `SliverPersistentHeader` (pinned) contenant `PsalmToneWidget`, encadré par `PsalmDisplayHeader` et `PsalmDisplayBody`

### `HymnsTabWidget` → `HymnSelectorWithTitle`

Si plusieurs hymnes : `DropdownButton` de sélection + titre + auteur + `HymnContentDisplay`. Si une seule : affichage direct. `HymnContentDisplay` utilise `paragraphSpacing: 15 * zoomValue/100`.

---

## 6. Rendu du texte liturgique

### `YamlTextParser`

Parse une chaîne YAML en `List<YamlTextParagraph>`. Un paragraphe = bloc séparé par une ligne vide (`\n\n`). Chaque paragraphe contient des lignes, chaque ligne des segments typés.

Syntaxe supportée :

| Marqueur | Effet |
|---|---|
| `%texte%` | Italique |
| `§R…§E` | Rubrique (texte rouge, taille -3 px, italique) |
| `^mot` | Exposant (décalé -(fontSize × 0.45), taille × 0.65) |
| `>ligne` | Retrait à droite (indent = fontSize × 1.5) |
| `R/`, `V/` | Convertis en ℟ / ℣ (rouge, gras) |
| `+`, `*` | Symboles liturgiques (rouge, gras) |
| `'` | Apostrophe typographique ' |
| ` :` ` ;` ` !` ` ?` | Espace fine insécable avant ponctuation |

### `YamlTextWidget`

Rend une `List<YamlTextParagraph>` comme une `Column`. Chaque paragraphe est enveloppé dans `Padding(bottom: paragraphSpacing)` — **y compris le dernier**, ce qui crée un espace sous le widget.

Paramètres clés :
- `paragraphSpacing` : défaut 12 px (non zoomé dans `YamlTextWidget` lui-même)
- `textStyle` : fourni par l'appelant, typiquement `fontSize: 16 * zoom/100, height: 1.2`
- `textAlign` : gauche ou justifié selon le contexte

### `YamlTextFromString`

Wrapper avec cache de parsing (`didUpdateWidget` re-parse si le contenu change). Scale automatiquement via `Consumer<CurrentZoom>` : `fontSize: 16 * zoom/100` et `paragraphSpacing: widget.paragraphSpacing * zoom/100` (défaut 12 × zoom/100).

---

## 7. SVG ton psalmique

### `PsalmToneWidget`

Affiche une ou plusieurs partitions SVG de ton psalmique.

- Le SVG est prétraité par `preprocessPsalmSvg` : injection de la couleur du texte (selon le thème), de la police (serif ou non), et de la couleur rouge liturgique
- Échelle × 1.2 (`_svgScale`) par rapport à la largeur naturelle du SVG, clampée à `screenWidth - 20`
- **1 SVG** : `SvgPicture.string` aligné à gauche, `Padding(vertical: 12, horizontal: 10)`
- **N SVGs** : `PageView` horizontal hauteur fixe 160 px + `SizedBox(8)` + indicateur dots animés

### Mode sticky (onglet) — `PsalmToneSliverDelegate`

`PsalmToneSliverDelegate` est un `SliverPersistentHeaderDelegate` à hauteur fixe (`minExtent == maxExtent`). La hauteur est calculée par `psalmToneSliverExtent()` à partir des attributs `width`/`height` du SVG :
- 1 SVG : `targetWidth × (naturalHeight / naturalWidth) + 24`
- N SVGs : `202 + 24 = 226 px`

Un `HapticFeedback.lightImpact()` est déclenché quand le sliver passe en mode "pinned" (`overlapsContent` passe à `true`).

### Mode sticky (scroll) — `SliverStickyHeader`

Fourni par le package `flutter_sticky_header`. Le ton est placé dans le `header` (sticky) et le corps du psaume dans le `sliver`. Le prochain psaume pousse le ton hors de l'écran quand il arrive.

---

## 8. Système de zoom

### `CurrentZoom`

`ChangeNotifier` persisté via `SharedPreferences` (clé `keyCurrentZoom`).

- Plage : 60–300 (défaut : 100)
- Chargé au démarrage, clampé immédiatement

### Consommation dans les widgets

```dart
// Pattern watch (rebuild complet)
final zoom = context.watch<CurrentZoom>().value;

// Pattern Consumer (rebuild partiel)
Consumer<CurrentZoom>(
  builder: (context, currentZoom, child) {
    final zoom = currentZoom.value;
    …
  },
)
```

### Convention d'application

- **Tailles de police** : `fontSize: baseSize * zoom / 100`
- **Espacements verticaux** : `SizedBox(height: h * zoom / 100)`, `EdgeInsets.only(top/bottom: v * zoom / 100)`
- **Espacements entre chips** : `spacing: 8 * zoom / 100, runSpacing: 8 * zoom / 100`
- **Paddings du paragraphe** : `paragraphSpacing: baseSpacing * zoom / 100`
- **Paddings horizontaux** : non scalés (marge d'écran fixe, indépendante de la taille de texte)

### Pinch-to-zoom — `PinchZoomSelectionArea`

Wrapper `GestureDetector` qui capte `onScaleStart`/`onScaleUpdate`/`onScaleEnd` et appelle `CurrentZoom.updateZoom(zoomAvantPinch × scale)`. Combine `SelectionArea` pour permettre la sélection de texte.

---

## 9. États globaux pertinents

| Provider | Rôle |
|---|---|
| `CurrentZoom` | Niveau de zoom texte (60–300) |
| `LiturgyState` | Mode scroll/onglets, source SVG ton, versets imprécatoires |
| `SelectedCelebrationState` | Célébration courante, commun courant, overrides de précédence par clé |
| `ThemeNotifier` | Thème sombre/clair, police serif — influence le prétraitement SVG |

`SelectedCelebrationState` est partagé entre les offices d'un même jour : quand l'utilisateur choisit une célébration aux Laudes, la même clé est proposée par défaut aux Vêpres (sous réserve de priorité compatible).
