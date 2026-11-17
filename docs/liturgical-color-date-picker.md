# Couleur liturgique dans le calendrier de sélection de jour

## Contexte

Le sélecteur de date de l'app (icône calendrier dans l'AppBar) ouvre une `AlertDialog`
(`DatePickerHelper.selectDate`, `lib/utils/datepicker.dart`) contenant une grille de calendrier.
`CalendarDatePicker`, le widget natif Flutter utilisé à l'origine, ne permet aucune
personnalisation du rendu de ses cellules (pas de `dayBuilder`) : impossible d'y ajouter un
indicateur par jour sans le remplacer. La donnée elle-même (`DayContent.liturgicalColor`, package
`offline_liturgy`) était déjà disponible et déjà affichée ailleurs dans l'app sous forme de petit
cercle coloré (`LiturgicalCalendarView._colorCircle`, `offline_liturgy_calendar_view.dart`).

Décision prise avec l'utilisateur : écrire une grille de calendrier maison (`LiturgicalDatePicker`)
plutôt que d'ajouter une dépendance tierce type `table_calendar`, pour rester cohérent avec le
reste de l'app qui ne dépend d'aucun package calendrier.

## Implémentation

### `LiturgicalDatePicker` (`lib/widgets/liturgical_date_picker.dart`)

`StatefulWidget` qui remplace `CalendarDatePicker` avec le même contrat
(`initialDate`/`firstDate`/`lastDate`/`onDateChanged`/`key`), plus un paramètre supplémentaire
`buildCalendarForYear: Future<Calendar> Function(int year)` — injecté par l'appelant
(`context.read<LiturgyState>().buildCalendarForYear` côté `datepicker.dart`) plutôt que lu via
`Provider` à l'intérieur du widget, pour que `LiturgicalDatePicker` reste testable isolément
(voir `test/widgets/liturgical_date_picker_test.dart`, qui lui passe un calendrier fixe).

- **En-tête mois/année** avec navigation `chevron_left`/`chevron_right`, désactivée aux bornes
  `firstDate`/`lastDate` (`_canGoPrev`/`_canGoNext`).
- **Ligne des jours de la semaine** (lun.–dim.).
- **Grille 7 colonnes**, nombre de lignes calculé selon le nombre de jours du mois affiché.
  Chaque cellule de jour (`dayCell`) affiche :
  - le numéro du jour, dans un cercle plein `colorScheme.primary` si sélectionné, ou cerclé
    d'un anneau fin `colorScheme.primary` si c'est aujourd'hui ;
  - un petit point de 10×10 (bordure `Colors.grey.shade400` 0.5px) coloré via
    `AelfLiturgicalColors.of(theme).resolve(colorName)` quand une couleur liturgique est connue
    pour ce jour, absent sinon.
  Les cellules hors mois (avant le 1er du mois affiché) restent vides, non cliquables ; un jour
  hors de `[firstDate, lastDate]` reste affiché mais n'est pas cliquable (`onTap: null`,
  numéro atténué à 38% d'opacité).
- **Chargement du `Calendar` du mois affiché** : `_ensureCalendar(month)` ne reconstruit que si
  le 15 du mois affiché tombe hors de la fenêtre déjà couverte par le `Calendar` en mémoire
  (`calendar.getDayContent(probe) != null`), même idiome que `LiturgyState._ensureCalendar` et
  `LiturgicalCalendarView`. `_anchorYearFor()` reproduit le calcul d'année liturgique de
  `LiturgicalCalendarView._computeInitialAnchorYear` (fin novembre/décembre appartient à l'année
  liturgique suivante). Un `CircularProgressIndicator` bref remplace la grille pendant une
  reconstruction.
- `onDateChanged(date)` est appelé au tap sur une cellule valide ; la sélection/validation
  (`pendingDate`, boutons "Annuler"/"OK"/"Aujourd'hui") reste entièrement gérée par
  `datepicker.dart`, inchangée.

### Intégration (`lib/utils/datepicker.dart`)

L'`AlertDialog` a une taille fixe `SizedBox(width: 300, height: 430)` (portée de 380 à 430 pour
laisser la place au point de couleur). `LiturgicalDatePicker` y reçoit
`buildCalendarForYear: context.read<LiturgyState>().buildCalendarForYear`
(`LiturgyState.buildCalendarForYear(int year)`, `lib/states/liturgyState.dart`) — construit un
`Calendar` autonome, sans toucher `offlineCalendar` ni créer d'effet de bord sur le reste de
l'app, couvrant 2 années liturgiques.

## Vérification

`test/widgets/liturgical_date_picker_test.dart` pompe le widget avec un `Calendar` fixe
(`_fixtureCalendar`, trois jours de mars 2026 colorés violet/blanc/vert) injecté directement via
`buildCalendarForYear`, sans passer par le vrai calcul du calendrier liturgique :

- le point de couleur affiché correspond à la couleur du jour, en thème clair **et** sombre, et
  est absent pour un jour sans donnée ;
- taper une cellule valide appelle `onDateChanged` avec la bonne date ;
- la navigation mois désactive bien les flèches aux bornes `firstDate`/`lastDate`.

Vérifié aussi visuellement dans l'app (thème clair et sombre, un mois de Carême et une période du
Temps Pascal) via le skill `run`.
