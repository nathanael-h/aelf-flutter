import 'package:aelf_flutter/data/changelog_data.dart';
import 'package:aelf_flutter/widgets/changelog_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';

const _whatsNewText =
    """Bienvenue dans cette nouvelle version de l'application AELF !

Beaucoup de nouvelles fonctionnalités sont à découvrir, pour vous aider à être au plus proche de ce que propose la richesse de la liturgie de l'Église.

L'appli démarre en mode "Simple", mais vous pouvez la passer dans les paramètres en mode "Avancé" pour accéder aux nouvelles fonctionnalités:

- Intégration de l'office pour la Dédicace de votre église et de l'office des défunts
- Intégration des propres de quelques diocèses, plus sont à venir
- Accès à toute la palette de mémoires obligatoires et facultatives, et choix du commun
- Possibilité de passer une fête en solennité locale, pour la fête patronale de l'église paroissiale ou autre
- Affichage d'un calendrier liturgique
- Les Cantiques Évangélique peuvent être affichés en langues anciennes (latin et grec)
- Les Psaumes et Cantiques peuvent être affichés en hébreu ou grec
- Géolocalisation possible pour avoir les spécificités des diocèses et pays francophones
- Interface retravaillée avec une police avec empattements. Il est possible de repasser à une police plus moderne
- Des partitions de tons de psaumes
- Office des lectures : lectures bibliques sur deux ans
- Un nouvel affichage vertical, en plus de l'affichage horizontal habituel (par onglets)
- La possibilité d'afficher ou de masquer les versets imprécatoires (entre crochets)
- Le bouton « référence biblique », présent dans la liturgie et qui ouvre le même texte dans la Bible, est désormais plus visible et plus joli
- Les informations sont désormais visibles dans le menu latéral gauche
""";

const _creditsText = """

La traduction liturgique est le fruit du travail de l'AELF, l'Association épiscopale liturgique pour les pays francophones. Pour plus d'informations, visitez son site : https://www.aelf.org/page/les-missions-de-laelf
Textes liturgiques, logo et nom reproduits avec l'autorisation de l'AELF. Tous droits réservés. L'AELF n'est pas responsable de cette application.

Le texte grec des cantiques évangéliques (Benedictus, Magnificat, Nunc dimittis) est tiré du Greek New Testament: SBL Edition (SBLGNT), © 2010 Society of Biblical Literature et Logos Bible Software, sous licence Creative Commons BY 4.0 : https://creativecommons.org/licenses/by/4.0/
Modifications apportées au texte publié : suppression des signes d'apparat critique propres à cette édition, et regroupement du verset 46 du Magnificat avec le verset 47, comme pour les versions française et latine.

Ce texte grec est affiché avec la police Alegreya, de Huerta Tipográfica, sous licence SIL Open Font License : http://scripts.sil.org/OFL

Le texte hébreu des psaumes est celui du Codex de Léningrad (domaine public), via l'Open Scriptures Hebrew Bible (OSHB) : https://github.com/openscriptures/morphhb

Ce texte hébreu est affiché avec la police Ezra SIL, de SIL International, sous licence SIL Open Font License : http://scripts.sil.org/OFL

Les symboles Refrain et Verset ainsi que l'illustration de fin d'office viennent de https://gregorio-project.github.io""";

void showAboutPopup(BuildContext context, String? version) {
  final textColor = Theme.of(context).textTheme.bodyLarge!.color;
  final surfaceColor = Theme.of(context).colorScheme.surface;
  final textStyle = TextStyle(color: textColor);

  Widget linkify(String text) => Linkify(
        text: text,
        style: textStyle,
        textAlign: TextAlign.left,
        onOpen: (link) => _launchInBrowser(link.url),
      );

  final popUp = AlertDialog(
    title: Align(
      alignment: Alignment.centerLeft,
      child: Text("À propos", style: textStyle),
    ),
    backgroundColor: surfaceColor,
    content: SingleChildScrollView(
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 15),
            child: SizedBox(
              width: double.infinity,
              child: Card(
                color: surfaceColor,
                child: ListTile(
                  title: Text("Nouvelle version",
                      style: textStyle.copyWith(fontWeight: FontWeight.bold)),
                  subtitle: Text(_whatsNewText, style: textStyle),
                ),
              ),
            ),
          ),
          const Padding(padding: EdgeInsets.only(top: 20)),
          linkify(
              "L'app AELF (version $version) est développée par des bénévoles. Elle vous permet d'avoir sur votre iPhone la liturgie (messe et offices) et toute la Bible dans la traduction liturgique française.\n\nCette application est libre et open source. Son développement principal est terminé, mais nous y apportons régulièrement des améliorations et, si nécessaire, des corrections de bugs. Toute aide est la bienvenue ! Pour toute question, remarque ou proposition d'aide, consultez cette page : https://gitlab.com/nathanael2/aelf-flutter/-/blob/master/README.md ou écrivez-nous à nathanael+aelf@hannebert.fr\n\nEnfin, nous remercions les testeurs pour leurs retours. Voici le lien pour accéder aux futures mises à jour et les tester avant leur diffusion générale : https://testflight.apple.com/join/EwOULWvi"),
          Card(
            color: surfaceColor,
            child: Theme(
              data:
                  Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                collapsedBackgroundColor: surfaceColor,
                backgroundColor: surfaceColor,
                iconColor: textColor,
                collapsedIconColor: textColor,
                title: Text("Historique des changements",
                    style: textStyle.copyWith(fontSize: 14)),
                children: changelogEntries
                    .map((entry) => ChangelogTile(entry: entry))
                    .toList(),
              ),
            ),
          ),
          linkify(_creditsText),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Valider',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary)),
            ),
          ),
        ],
      ),
    ),
  );

  showDialog(
    context: context,
    builder: (context) => Align(
      alignment: Alignment.topCenter,
      child: SizedBox(width: 800, child: popUp),
    ),
  );
}

Future<void> _launchInBrowser(String url) async {
  if (await canLaunchUrl(Uri.parse(url))) {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } else {
    throw 'Could not launch $url';
  }
}
