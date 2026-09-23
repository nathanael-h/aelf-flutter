import 'package:aelf_flutter/data/changelog_data.dart';
import 'package:aelf_flutter/widgets/changelog_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';

class About {
  String? version;
  About(this.version);
  void popUp(BuildContext context) {
    var popUp = AlertDialog(
      title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "À propos",
            style:
                TextStyle(color: Theme.of(context).textTheme.bodyLarge!.color),
          )),
      backgroundColor: Theme.of(context).colorScheme.surface,
      content: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Container(
              width: double.infinity,
              //constraints: BoxConstraints.expand(),
              padding: EdgeInsets.only(top: 15),
              child: Card(
                color: Theme.of(context).colorScheme.surface,
                child: ListTile(
                  dense: false,
                  title: Text("""Nouveautés : lecture continue de la Bible""",
                      textAlign: TextAlign.left,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge!.color)),
                  subtitle: Text("""Nouveautés :\n
- Un bouton « Partager » permet d'envoyer à vos proches un lien vers la Parole de Dieu que vous lisez
- La région liturgique par défaut est désormais choisie en fonction de la langue de votre appareil
- Dans les paramètres, vous pouvez choisir une police de caractères plus classique (avec empattements)
- Découvrez et testez la future version de la liturgie des Heures et de la messe, disponible sans connexion Internet
- Dans cette future version, découvrez aussi :
  - Un choix plus large de fêtes, de mémoires, d'hymnes, de calendriers liturgiques, etc.
  - Des partitions de tons de psaumes
  - Un nouvel affichage vertical, en plus de l'affichage horizontal habituel (par onglets)
  - Une vue du calendrier liturgique annuel
  - La possibilité d'afficher ou de masquer les versets imprécatoires (entre crochets)
- Le bouton « référence biblique », présent dans la liturgie et qui ouvre le même texte dans la Bible, est désormais plus visible et plus joli
- Les informations sont désormais visibles dans le menu latéral gauche
- Correction : le menu en haut à droite se fermait trop vite dans certains cas
""", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge!.color)),
                ),
              ),
            ),
            Padding(padding: EdgeInsets.only(top: 20)),
            Linkify(
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge!.color),
                textAlign: TextAlign.left,
                onOpen: (link) => _launchInBrowser(link.url),
                text:
                    ("L'app AELF (version $version) est développée par des bénévoles. Elle vous permet d'avoir sur votre iPhone la liturgie (messe et offices) et toute la Bible dans la traduction liturgique française.\n\nCette application est libre et open source. Son développement principal est terminé, mais nous y apportons régulièrement des améliorations et, si nécessaire, des corrections de bugs. Toute aide est la bienvenue ! Pour toute question, remarque ou proposition d'aide, consultez cette page : https://gitlab.com/nathanael2/aelf-flutter/-/blob/master/README.md ou écrivez-nous à nathanael+aelf@hannebert.fr\n\nEnfin, nous remercions les testeurs pour leurs retours. Voici le lien pour accéder aux futures mises à jour et les tester avant leur diffusion générale : https://testflight.apple.com/join/EwOULWvi")),
            Card(
              color: Theme.of(context).colorScheme.surface,
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  collapsedBackgroundColor:
                      Theme.of(context).colorScheme.surface,
                  iconColor: Theme.of(context).textTheme.bodyLarge!.color,
                  collapsedIconColor:
                      Theme.of(context).textTheme.bodyLarge!.color,
                  title: Text(
                    "Historique des changements",
                    style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge!.color,
                        fontSize: 14),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  children: changelogEntries
                      .map((entry) => ChangelogTile(entry: entry))
                      .toList(),
                ),
              ),
            ),
            Linkify(
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge!.color),
                textAlign: TextAlign.left,
                onOpen: (link) => _launchInBrowser(link.url),
                text:
                    ("\n\nLa traduction liturgique est le fruit du travail de l'AELF, l'Association épiscopale liturgique pour les pays francophones. Pour plus d'informations, visitez son site : https://www.aelf.org/page/les-missions-de-laelf\nTextes liturgiques, logo et nom reproduits avec l'autorisation de l'AELF. Tous droits réservés. L'AELF n'est pas responsable de cette application.")),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Valider',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.secondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    showDialog(
        context: context,
        builder: (BuildContext context) => Align(
            alignment: Alignment.topCenter,
            child: Container(width: 800, child: popUp)));
  }
}

Future<void> _launchInBrowser(String url) async {
  if (await canLaunchUrl(Uri.parse(url))) {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } else {
    throw 'Could not launch $url';
  }
}
// TODO : add a changelog section - DONE
// TODO : fix dark theme for changelog
