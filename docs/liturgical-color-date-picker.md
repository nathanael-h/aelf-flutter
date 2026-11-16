# Couleur liturgique dans le calendrier de sélection de jour

## Contexte

Le sélecteur de date de l'app (icône calendrier dans l'AppBar, `aelf_home_page.dart`) ouvre
aujourd'hui un `CalendarDatePicker` natif Flutter (`lib/utils/datepicker.dart:41`), dans une
`AlertDialog` de taille fixe. L'utilisateur voudrait voir, directement sur cette grille, la
couleur liturgique de chaque jour (un repère visuel rapide avant même de naviguer vers un jour).

Problème : `CalendarDatePicker` ne permet aucune personnalisation du rendu de ses cellules (pas
de `dayBuilder`). Impossible d'y ajouter un indicateur par jour sans le remplacer. La donnée
elle-même (`DayContent.liturgicalColor`, package `offline_liturgy`) est en revanche déjà
disponible et déjà affichée ailleurs dans l'app sous forme de petit cercle coloré
(`LiturgicalCalendarView._colorCircle`, `offline_liturgy_calendar_view.dart:505`).

Décision déjà prise avec l'utilisateur : écrire une grille de calendrier maison (pas de
dépendance tierce type `table_calendar`), pour rester cohérent avec le reste de l'app qui ne
dépend d'aucun package calendrier.

## Ce qui existe et sera réutilisé

- **Construction du calendrier pour un mois donné** : `LiturgyState.buildCalendarForYear(int year)`
  (`lib/states/liturgyState.dart:1159`) — construit un `Calendar` autonome (sans toucher
  `offlineCalendar`, donc sans effet de bord sur le reste de l'app), couvrant 2 années
  liturgiques, déjà utilisé exactement dans ce but par `LiturgicalCalendarView`
  (`offline_liturgy_calendar_view.dart:141`). Pas de cache interne à cette méthode — on reproduit
  le même pattern que `LiturgicalCalendarView` : garder un seul `Calendar?` + l'année avec
  laquelle il a été construit dans le `State`, et ne reconstruire que si la date demandée tombe
  hors de la fenêtre déjà chargée (sonde `calendar.getDayContent(date) != null`, même idiome que
  `LiturgyState._ensureCalendar`).
- **Résolution couleur → `Color`, dark-mode-aware** : `AelfLiturgicalColors`
  (`lib/utils/theme_provider.dart:79`, `ThemeExtension`), via
  `AelfLiturgicalColors.of(Theme.of(context)).resolve(colorName)`. C'est la variante qui gère
  déjà clair/sombre (contrairement à `getLiturgicalColor()` et à la fonction privée de
  `offline_liturgy_calendar_view.dart`, qui ne seront pas touchées — pas de consolidation des 3
  fonctions dans cette tâche, risque et portée disproportionnés par rapport au besoin).
- **Style visuel du repère** : repris de `_colorCircle()` (10×10, `BoxShape.circle`, bordure
  `Colors.grey.shade400` 0.5px) — cohérence avec l'indicateur déjà utilisé ailleurs dans l'app.
- **Ordre des jours de la semaine (lundi en premier)** et libellés courts mois/jours : mêmes
  tableaux que `LiturgicalCalendarView._months`/`_weekdays`.
- **Contrat d'intégration** : le nouveau widget garde exactement les mêmes paramètres que
  `CalendarDatePicker` (`initialDate`, `firstDate`, `lastDate`, `onDateChanged`, `key`), pour que
  `datepicker.dart` change le moins possible (juste l'import + le nom du widget à la ligne 41 ;
  tout le reste — `AlertDialog`, `pendingDate`, bouton "Aujourd'hui", bornes 2016–2101 — reste
  identique).

## Nouveau widget

Fichier : `lib/widgets/liturgical_date_picker.dart`, classe `LiturgicalDatePicker`
(StatefulWidget).

- En-tête mois/année avec navigation `chevron_left`/`chevron_right` (style identique aux
  flèches année de `LiturgicalCalendarView`), désactivée aux bornes `firstDate`/`lastDate`.
- Ligne d'en-tête des jours (lun.–dim.).
- Grille 7 colonnes × jusqu'à 6 lignes. Chaque cellule du mois affiche :
  - le numéro du jour ;
  - un cercle plein (couleur `ColorScheme.primary`) si le jour est sélectionné, ou juste un
    anneau fin si c'est aujourd'hui (repris de la sémantique Material actuelle) ;
  - un petit point de couleur liturgique sous le numéro, via `AelfLiturgicalColors`.
  Les cellules hors mois (début/fin de grille) restent vides, non cliquables.
- Chargement asynchrone du `Calendar` du mois affiché (via `buildCalendarForYear`, avec un état
  de chargement bref si reconstruction nécessaire) ; `onDateChanged(date)` appelé au tap sur une
  cellule valide.
- Pas de changement de logique de sélection/validation : c'est `datepicker.dart` qui garde
  `pendingDate`, "Annuler"/"OK", et le raccourci "Aujourd'hui".

Taille : la hauteur fixe de l'`AlertDialog` (`datepicker.dart:38-40`, actuellement 380) sera
portée à ~430px pour laisser la place au point de couleur sans texte serré — ajustable pendant
la vérification visuelle.

## Fichiers modifiés

- Nouveau : `lib/widgets/liturgical_date_picker.dart` (le widget décrit ci-dessus).
- `lib/utils/datepicker.dart` : remplace `CalendarDatePicker` par `LiturgicalDatePicker` (ligne
  41) et ajuste la hauteur du `SizedBox` (ligne 40).

## Vérification

- Test widget `test/widgets/liturgical_date_picker_test.dart`, sur le modèle de
  `test/widgets/detection_dialog_test.dart` (pump avec `MaterialApp` thème clair **et** sombre) :
  - un jour connu (ex. mercredi des Cendres = violet, jour de Pâques = blanc, un jour ordinaire
    = vert) affiche le bon point de couleur ;
  - taper une cellule valide déclenche `onDateChanged` avec la bonne date ;
  - la navigation mois respecte les bornes `firstDate`/`lastDate`.
- Vérification visuelle réelle via le skill `run` : lancer l'app, ouvrir le sélecteur de date,
  confirmer à l'œil les couleurs sur quelques dates connues, en thème clair et sombre.
- `flutter analyze` + `flutter test` sur l'ensemble du projet après implémentation.
