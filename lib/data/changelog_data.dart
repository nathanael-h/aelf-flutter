import 'package:aelf_flutter/models/changelog_entry.dart';

final List<ChangelogEntry> changelogEntries = [
  ChangelogEntry(
      version: "1.11.0",
      date: "27/10/2025",
      description:
          """Bible: mise à jour des textes, cela apporte les corrections dispnibles sur aelf.org/bible.
Lectures : l'auteur des lectures patristiques est de nouveau indiqué.
Date : correction de la date affichée dans deux cas: 
- si l'application reste ouverte après minuit, ce sera bien affiché "Hier" ; 
- le 8ème jour précédent ou suivant était présenté comme le "dernier" ou "prochain" par erreur."""),
  ChangelogEntry(
      version: "1.10.0",
      date: "08/10/2025",
      description:
          """Dans l'office des lecture, ajout du verset manquant après les psaumes.
Dans le menu de gauche, correction de la couleur active en mode nuit.
Correction d'un bug empêchant le téléchargement des messes en avance : désormais les lectures de la messe sont aussi disponibles sans accès à internet.
Maintenance générale."""),
  ChangelogEntry(
      version: "1.9.0",
      date: "15/08/2025",
      description:
          "Alignement des numéros de verset et subtiles améliorations de l'interface."),
  ChangelogEntry(
    version: "1.8.0",
    date: "06/07/2025",
    description: "Correction des titres de la Bible.",
  ),
  ChangelogEntry(
    version: "1.7.0",
    date: "14/03/2025",
    description:
        "Ajout du calendrier liturgique de Monaco. Pour le sélectionner, il faut ouvrir les paramètres de l'application.",
  ),
  ChangelogEntry(
    version: "1.6.0",
    date: "05/01/2025",
    description:
        "L'onglet informations a été retravaillé pour afficher plusieurs fêtes lorsque cela est nécessaire.",
  ),
  ChangelogEntry(
    version: "1.5.0",
    date: "11/07/2024",
    description:
        "L'affichage est plus agréable sur les grands écrans et tablettes.\nDans la liturgie, certaines références bibliques n'étaient pas reconnues, le titre ne correspondait pas à l'office affiché. Ces bugs sont corrigés.",
  ),
  ChangelogEntry(
    version: "1.4.0",
    date: "26/03/2024",
    description:
        "Dans la messe et les offices, la plupart des références sont clicables et ouvriront la lecture dans la Bible.\nL'application s'ouvrira sur le bon office selon le jour et l'heure.\nCorrection d'un oubli, les épitres sont désormais affichées.",
  ),
  ChangelogEntry(
    version: "1.3.0",
    date: "31/10/2023",
    description:
        "Dans la Bible, les versets sont alignés, ce qui rend la présentation plus élégante et la lecture plus agréable.",
  ),
  ChangelogEntry(
    version: "1.2.0",
    date: "23/10/2023",
    description:
        "Dans la Bible, si vous effectuez une recherche, lorsque vous toucherez un des versets trouvés, les versets figurant dans les résultats seront mis en valeur dans le chapitre. Correction d'un bug d'affichage sur les appareils ayant une encoche, en mode paysage. Correction de l'affichage des résultats de la recherche avec le mode nuit.",
  ),
  ChangelogEntry(
    version: "1.1.0",
    date: "28/09/2023",
    description:
        "Dans la Bible, correction d'un bug : seul le 1er psaume s'ouvrait, dans la recherche on tombait uniquement sur le 1er chapitre. Dans la messe, les références du texte sont mieux présentées, ce qui facilite la compréhension.",
  ),
  ChangelogEntry(
    version: "1.0.0",
    date: "23/072023",
    description:
        "Nouveautés : On peut copier le texte de la Bible et de la liturgie pour le partager ailleurs. J'ai aussi fait une grosse maintenant générale sur le code et des corrections de bugs : poignées de sélection de la même couleur que le fond si le thème sombre est activé, la région n'était pas sauvegardée après un redémarrage de l'application, le zoom appliqué depuis les réglages du téléphone ne vient plus en doublon du zoom défini dans l'application, la liturgie ne devrait plus revenir sur la première page aléatoirement. Je cherche plus de personnes pour tester les mises à jour avant une diffusion générale, veuillez cliquer sur le lien indiqué plus haut.",
  ),
  ChangelogEntry(
    version: "0.0.10",
    date: "22/05/2023",
    description:
        "Nouveautés : Zoom à 2 doigts (partout), corrections de bugs (lectures brèves, et autres).",
  ),
  ChangelogEntry(
    version: "0.0.9",
    date: "12/11/2022",
    description:
        "La taille du texte est réglable dans les paramètres. Désormais, quand l'app est ouverte, la mise en veille de l'écran est désactivée. Les titres de livre s'affichent sur deux lignes dans les résulats de la recherche si nécessaire. Maintenance générale de l'application.",
  ),
  ChangelogEntry(
    version: "0.0.8",
    date: "14/04/2022",
    description:
        "Ajout d'une fonctionnalité majeur : la recherche dans le texte intégral de la Bible.",
  ),
  ChangelogEntry(
    version: "0.0.7",
    date: "14/12/2021",
    description:
        "Correction : ajout de l'hymne mariale après la bénédiction pour les complies, résolution d'un bug empêchant l'accès hors ligne à la liturgie, et d'un autre bloquant le chargement de certaines offices.",
  ),
  ChangelogEntry(
    version: "0.0.6",
    date: "24/02/2021",
    description:
        "Vous pouvez basculer entre les thèmes clair et sombre depuis le bouton situé dans le coin supérieur droit.",
  ),
  ChangelogEntry(
    version: "0.0.5",
    date: "30/01/2021",
    description:
        "Adaptez la liturgie au calendrier liturgique de votre ! Le choix est accessible dans le nouveau menu paramètres.",
  ),
  ChangelogEntry(
    version: "0.0.4",
    date: "22/09/2020",
    description:
        "Dans la Bible, il est désormais possible de sélectionner et copier le texte pour le partager, ou le garder dans ses notes.",
  ),
  ChangelogEntry(
    version: "0.0.3",
    date: "26/06/2020",
    description:
        "Correction d'une erreur : si le psaume de la messe est un cantique il n'était pas affiché dans les versions précédentes.",
  ),
  ChangelogEntry(
    version: "0.0.2",
    date: "01/06/2020",
    description:
        "Correction d'un bug où le sélecteur de date ne s'affichait pas.",
  ),
  ChangelogEntry(
    version: "0.0.1",
    date: "18/05/2020",
    description: "Première version publiée",
  ),
];
