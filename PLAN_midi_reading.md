# Lecture MIDI des tons de psaumes

## Statut : ✅ Implémenté (2026-11-06), sauf F6 — écoute et essai sur appareil à faire

> **Depuis le 2026-11-07** : l'application n'utilise plus qu'un seul jeu de tons, `assets/svg/psalm-tones/`
> du package, produit par `build.py` à partir de `psaume_neutre` (copie d'Emmanuel dont les cantiques
> des vêpres NT_4, 5, 6, 9, 10 et 11 ne gardent que leur psalmodie). Les dossiers `seminaire-emmanuel/` et
> `seminaire-paris/` du package et le choix du répertoire dans les paramètres ont disparu ;
> `CelebrationContext.svgSource` est remplacé par `psalmTones`. Ce qui suit décrit le travail initial,
> sur les partitions d'Emmanuel.

| Étape | Commits |
|---|---|
| P1 ménage | `Psaumes` 0afbba3, f9495ba, 16895a2 |
| P2 `\exportOK` manquants | `Psaumes` 8cab2d3 (OT_41, NT_5, PSALM_140 : **choix musicaux à relire**) |
| P3 `build.py` + tests | `Psaumes` 3c1df2c, c189b22, c5292e1 (README) |
| P4 vérification | 136 partitions, toutes avec MIDI ; SVG sans métadonnées identiques à l'ancien `build_svg.py` |
| O1 assets | `offline-liturgy` 409e5c08 (132 partitions avec MIDI, dessin inchangé) |
| O2 test | `offline-liturgy` 7d484a63 |
| F1 banque | `aelf-flutter` 705e994 (9,2 Mo → 0,9 Mo) |
| F2 dépendances | `aelf-flutter` dbb875f (copie locale de `flutter_pcm_sound` avec Swift Package), 2cc315c |
| F3 lecture du MIDI | `aelf-flutter` 73e77d0 |
| F4 `TonePlayer` | `aelf-flutter` 2ed12ca |
| F5 bouton | `aelf-flutter` 7f719f8 |
| F6 épinglage | **reporté** : la branche `midi_reading` d'offline-liturgy n'est pas poussée ; `dependency_overrides` reste actif en local |

Vérifié : `python3 -m unittest discover tests` (Psaumes, 15 tests) ; `dart analyze` et
`test/score_midi_test.dart` (offline-liturgy) ; `flutter analyze` et `flutter test` (aelf-flutter, 480
tests) ; `flutter build macos`, `ios --simulator` et `apk` en debug. Reste à faire à la main : écouter le
résultat et essayer le bouton sur appareil (iOS en mode silencieux, Android, macOS).

Écarts avec le plan :
- `PSALM_118`, `PSALM_71-I` et `PSALM_71-II` n'ont plus de source : leurs SVG restent sans MIDI (pas de
  bouton). Le package ramène `PSALM_118_14` et `PSALM_118_19` à `PSALM_118.svg`, alors que les sources
  distinguent `PSALM_118-14` et `PSALM_118-19` : à traiter à part.
- `flutter_pcm_sound` 3.3.3 (dernière version) n'a pas de Swift Package : Flutter aurait basculé toute l'app sur
  CocoaPods. Le plugin (domaine public) est copié dans `packages/flutter_pcm_sound/` avec un
  `Package.swift` (sources iOS/macOS partagées dans `darwin/`, Dart et Android inchangés) : l'app ne
  dépend que de SPM, projets ios/macos inchangés, pas de `Podfile`. À abandonner quand
  le package publié aura son Swift Package.
- Échec préexistant, sans lien (identique sur `main`) : `office_content_coverage_test.dart`, 6 anomalies
  de textes pour Lyon 2026 (13 mai et 24 décembre).

| Dépôt | Branche | Rôle |
|---|---|---|
| `Psaumes` (sources LilyPond) | `unification` | produire chaque partition SVG **avec le MIDI de sa psalmodie intégré** |
| `offline-liturgy` | `midi_reading` | recevoir les SVG régénérés (aucun changement de code) |
| `aelf-flutter` | `midi_reading` | jouer ce MIDI depuis un petit bouton lecture / stop |

## Objectif

Un petit bouton discret à côté de chaque partition lance la lecture de la psalmodie au piano ; pendant
la lecture il devient un bouton stop. Toucher la partition elle-même ne fait rien, pour ne pas lancer la
lecture par erreur. Uniquement sur Android, iOS et macOS (`dart_melty_soundfont` + `flutter_pcm_sound`,
comme `emmasongs_client`) ; ailleurs, la partition s'affiche comme aujourd'hui, sans bouton.

## Décisions

| Sujet | Décision |
|---|---|
| Plateformes | Android, iOS, macOS (méthode A) |
| Contenu joué | **la psalmodie seule** : les lignes marquées `\exportOK`. Ni refrain, ni flexe, ni accords |
| Marqueur | `\exportOK` est conservé dans les sources |
| Durées | `\breve` jouée comme une noire, les autres durées telles qu'écrites, une noire de silence entre deux lignes |
| Tempo | 90 à la noire partout |
| Transport du MIDI | embarqué dans le SVG : `<metadata id="midi">` en base64 |
| Notation des sources | néerlandaise — ✅ fait (`Psaumes@bad7c56`, rendu SVG vérifié identique sur les 288 partitions) |
| Audio iOS | catégorie `playback` (joue même en mode silencieux) |
| Commande | petit bouton discret ▶ ; pendant la lecture il devient ■ |
| Banque de sons | piano unique, **réduit au maximum** (étape F1) |
| Périmètre | **séminaire de l'Emmanuel seulement** pour l'instant. `psaumes_paris/` et les assets `seminaire-paris/` ne sont pas touchés : les partitions Paris s'affichent sans bouton |

## Mécanisme MIDI retenu (testé)

L'option LilyPond `-dinclude-settings=FICHIER` charge un fichier de réglages avant chaque source. Ce
fichier, `include/psalmody_midi.ily`, redéfinit `toplevel-score-handler` : chaque partition est rendue
normalement (SVG) et, à côté, LilyPond construit lui-même la psalmodie :
- il repère les lignes du source qui portent un `\exportOK` (le marqueur garde la ligne où il est écrit,
  même dans un ton inclus) ;
- il reprend les notes et silences écrits sur ces lignes, dans l'ordre, avec leur **hauteur absolue**
  (le `\relative` est déjà résolu) ;
- il crée de **nouvelles** notes, `\breve` → noire (modifier les notes existantes ne marche pas : LilyPond a
  déjà mis leur durée en cache), une noire de silence à chaque changement de ligne ;
- il ajoute une partition MIDI (`\tempo 4 = 90`) qui ne contient que ces notes : pas d'accords par
  construction.

Essai sur toutes les sources : SVG **identiques octet pour octet** au build actuel, aucune erreur ;
octaves justes (NT_10 en fa#4, au lieu d'une octave trop bas avec l'ancien script) ; NT_1 et NT_2, que
l'ancienne chaîne ne savait pas produire, ont leur MIDI. Emmanuel : 138 MIDI pour 141 partitions.

Partitions Emmanuel encore sans MIDI, faute de ligne `\exportOK` : `OT_41`, `NT_5`, `PSALM_140`
(ton `2b.ily`).

## Partie 1 — `Psaumes` (branche `unification`)

**P1. Ménage de l'ancien matériel** (un commit par lot) :
- racine : `Makefile`, `build_midi.sh`, `build_midi_new.sh`, `build_svg.sh`, `lilypond2midi.py`,
  `lilypond2text.py`, `lilypond2text sauv.py`, `partie1.ly`, `partie2.ly`, `lilytemp.ly`, `_psalmodie.svg`,
  `remove_svg_groups.py`, `build/` ;
- `psaume_Emmanuel/` : les mêmes copies, plus `build_svg.py` (remplacé par P3), `svgo.config.js`
  (remonté à la racine) et `build/` (régénérable) ;
- `.DS_Store` retiré du suivi (déjà dans `.gitignore`) ; `psaumes_Lyon/` vide supprimé ;
- `psaumes_paris/` laissé tel quel (ses scripts compris), à reprendre plus tard.

**P2. Sources** : ajouter les `\exportOK` manquants dans `OT_41`, `NT_5` et `PSALM_140`. Je propose les
lignes, tu valides la musique ; rendu SVG vérifié identique avant et après.

**P3. Un seul script `build.py` à la racine** (bibliothèque standard Python + `lilypond` + `svgo`) :
- `python3 build.py` (tout Emmanuel), `python3 build.py chemin/fichier.ly`. La source est un paramètre
  (dossier des `.ly` → dossier de sortie), pour ajouter Paris plus tard sans réécrire le script ;
- **aucun `.ly` réécrit** : LilyPond lit les sources telles quelles, le réglage MIDI est injecté par
  `-dinclude-settings` ;
- **un seul lancement de LilyPond par office** (pas un par fichier), qui se répartit lui-même sur les
  cœurs : `lilypond -djob-count=N -dinclude-settings=include/psalmody_midi.ily -dcrop -dno-print-pages
  -dbackend=svg -dno-point-and-click -o TMP/office office/*.ly`. `-dno-print-pages` supprime le SVG pleine
  page inutile : il ne reste que `.cropped.svg` + `.midi`. Un dossier par office, car un même nom peut
  exister dans deux offices ;
- **un seul lancement de svgo** sur chaque dossier (`svgo -f`), au lieu d'un par fichier ;
- tous les intermédiaires dans un dossier temporaire (`tempfile.TemporaryDirectory`), effacé à la fin :
  rien n'est laissé dans le dépôt ;
- SVG : attributs sur la racine, comme `build_svg.py` aujourd'hui ; fichier final écrit **seulement si son
  contenu change** (pas de faux changements pour git) ;
- mesuré sur les 141 sources Emmanuel : ~4 s pour LilyPond et < 1 s pour svgo, contre ~45 s en lançant
  les deux outils fichier par fichier ; sorties identiques ;
- MIDI : contrôle **monophonique** (erreur sinon), encodage base64, puis insertion de
  `<metadata id="midi">…</metadata>` juste avant `</svg>`, **après** svgo (son réglage standard supprime
  les `<metadata>`). Sans `\exportOK`, le SVG est produit sans MIDI et le script le signale ;
- sortie à plat `build/seminaire-emmanuel/NOM.svg`, comme les assets. Un même nom produit par deux
  offices doit donner le même SVG, sinon erreur ;
- option `--install CHEMIN` : copie dans `offline-liturgy/assets/svg/` ;
- `build/` n'est plus versionné dans `Psaumes` (ajouté au `.gitignore`) : la copie de référence est celle
  des assets d'offline-liturgy, on n'en garde pas une seconde ;
- `README.md` réécrit : prérequis, usage, rôle de `\exportOK`.

**P4. Vérification** : partitions sans leur `<metadata>` identiques à celles de l'ancien `build_svg.py` ; un
MIDI par partition marquée ; écoute d'un échantillon (psaume, cantique AT, cantique NT, invitatoire).

## Partie 2 — `offline-liturgy` (branche `midi_reading`)

**O1. Assets** : supprimer les 130 `.midi` ajoutés à côté des SVG (jamais commités), régénérer
`assets/svg/seminaire-emmanuel/` avec `build.py --install`. `seminaire-paris/` n'est pas touché. Aucun
changement dans `lib/`.

**O2. Test** `test/score_midi_test.dart` : pour chaque SVG qui contient `<metadata id="midi">` : base64
valide, en-tête MIDI valide, **monophonique**. Mention du format dans `CLAUDE.md`.

## Partie 3 — `aelf-flutter` (branche `midi_reading`)

**F1. Banque de sons réduite** — script `tool/shrink_soundfont.py` (bibliothèque standard), appliqué au
`piano.sf2` d'emmasongs (FreePats « Upright piano KW » : 26 échantillons mono, 44,1 kHz, ~4 s en moyenne,
9,2 Mo) :
1. ne garder que les 10 échantillons qui couvrent la tessiture des tons (si2–ré5 mesuré, marge la2–mi5),
   en élargissant les zones extrêmes pour qu'aucune note ne tombe hors banque → 4,0 Mo ;
2. couper chaque échantillon à ~1,5 s avec un fondu de sortie (une noire à 90 dure 0,67 s, plus la
   résonance) ;
3. rééchantillonner à 22 050 Hz (filtre passe-bas puis une valeur sur deux). Le synthétiseur gère une
   fréquence par échantillon (`Oscillator` : rapport fréquence échantillon / fréquence de sortie).

Estimation : **~0,65 Mo** (÷ 14). Si l'écoute le permet, garder un échantillon sur deux (chacun couvrirait
une dizaine de demi-tons) descendrait vers ~0,35 Mo, au prix d'un timbre moins homogène. Le `.sf2` réduit
va dans `assets/sounds/piano.sf2`, le script et la provenance (crédit FreePats, licence à vérifier) dans
`tool/` et le README.

**F2. Dépendances** (`pubspec.yaml`) : `dart_melty_soundfont: 2.0.0`, `flutter_pcm_sound: 3.3.3` ; dossier
`assets/sounds/` déclaré. Point de vigilance : aelf-flutter n'utilise que Swift Package Manager et
`flutter_pcm_sound` 3.3.3 seulement CocoaPods. Résolu par une copie locale du plugin avec un
`Package.swift` (`packages/flutter_pcm_sound/`) : pas de `Podfile`, pas de CocoaPods.

**F3. `lib/utils/score_midi.dart`** :
- `Uint8List? scoreMidi(String svg)` : décode le contenu de `<metadata id="midi">`, `null` si absent ;
- `String stripScoreMetadata(String svg)` : retire le bloc. Appelé **en premier** dans
  `preprocessPsalmSvg`, pour que flutter_svg ne voie jamais `<metadata>` (il afficherait « unhandled
  element ») et que les remplacements de couleur ne touchent jamais le base64.

**F4. Service `TonePlayer`** — `lib/utils/tone_player.dart`, `ChangeNotifier` enregistré dans le
`MultiProvider` de `main.dart` :
- `static bool get isSupported` : `!kIsWeb && (Android || iOS || macOS)` ;
- initialisation au premier appui : `piano.sf2` → `Synthesizer` + `MidiFileSequencer`,
  `FlutterPcmSound.setup(sampleRate: 44100, channelCount: 1, iosAudioCategory: IosAudioCategory.playback)`,
  seuil et callback d'alimentation ;
- `toggle(Uint8List midi)` : même MIDI en cours → `stop()` ; sinon arrêt de la lecture en cours,
  `MidiFile.fromByteData`, `sequencer.play(loop: false)`, `FlutterPcmSound.start()`. La lecture en cours
  est identifiée par une empreinte des octets ;
- `isPlaying(midi)` pour l'état du bouton ;
- alimentation : blocs de ~2048 échantillons mono (`renderMono`), conversion Int16 **bornée** (`clamp`,
  contrairement à emmasongs), ~1 s de résonance après `endOfSequence`, puis fin et `notifyListeners()` ;
- `stop()` : plus d'alimentation (le plugin n'a pas de `stop` : le tampon restant, ~0,1 s, s'écoule),
  `sequencer.stop()`, `notifyListeners()` ; arrêt aussi quand l'app passe en arrière-plan
  (`WidgetsBindingObserver`).

**F5. `PsalmToneWidget`** — **aucun nouveau paramètre** : chaque élément de `svgData` fournit son MIDI
(pages du `PageView` comprises).
- Si la plateforme est gérée et que le MIDI existe : un **petit bouton discret** à droite de la partition,
  dans la marge de `LiturgyRow` (icône ▶ `play_arrow`, petite taille, couleur secondaire atténuée,
  zone de toucher de taille standard). Pendant la lecture de cette partition il devient ■ (`stop`) ;
- la partition elle-même ne réagit pas au toucher ;
- infobulle et `Semantics` : « Écouter le ton » / « Arrêter » ; état lu via `context.watch<TonePlayer>()` ;
- `dispose()` arrête la lecture si c'est cette partition qui joue ;
- la largeur prise par le bouton est retirée de `maxWidth`, pour que la partition ne déborde pas.

Aucun changement aux appels de `PsalmToneWidget` (psalmodie, Benedictus/Magnificat, invitatoire, modes
défilement et onglets).

**F6. Finalisation** : épingler le `ref:` git d'`offline_liturgy` sur le commit des nouveaux assets,
recommenter `dependency_overrides`.

## Ordre et vérification

P1 → P2 → P3 → P4 → O1 → O2 → F1 → F6. Un commit par étape, `dart format` uniquement sur les fichiers
modifiés.
- `offline-liturgy` : `dart analyze`, `dart test test/score_midi_test.dart`.
- `aelf-flutter` : `flutter analyze` ; essais sur simulateur iOS, Android et macOS :
  - ▶ → lecture et le bouton devient ■ ; ■ → arrêt et retour à ▶ ; fin naturelle → retour à ▶ ;
  - ▶ sur une autre partition → bascule (l'ancienne repasse à ▶) ;
  - toucher la partition → rien ; partition sans MIDI → pas de bouton ;
  - iPhone en mode silencieux → le son joue (`playback`) ; passage en arrière-plan → arrêt ;
  - modes défilement et onglets, écoute de la banque réduite sur toute la tessiture ;
  - source `seminaire-paris` sélectionnée → partitions affichées comme aujourd'hui, sans bouton.
- Compilation Linux inchangée (CI) : le plugin n'y est pas enregistré, `isSupported` masque le bouton.
