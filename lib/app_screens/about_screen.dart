import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:aelf_flutter/widgets/custom_expansion_tile.dart' as custom;

class About {
  String version;
  About(this.version);
  void popUp(BuildContext context) {
    var popUp = AlertDialog(
      title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "À propos",
            style:
                TextStyle(color: Theme.of(context).textTheme.bodyText1.color),
          )),
      backgroundColor: Theme.of(context).textTheme.headline6.color,
      content: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Linkify(
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyText1.color),
                textAlign: TextAlign.left,
                onOpen: (link) => _launchInBrowser(link.url),
                text:
                    ("L'app AELF (version $version) est développée bénévolement par des volontaires. Actuellement elle vous permet d'avoir sur votre iPhone la liturgie des heures, les lectures de la messe, et toute la Bible dans la traduction française liturgique. \n \nCette application est libre et open source, le développement principal est terminé, mais nous apportons régulièrement des améliorations et des corrections de bugs si nécessaire. Toute aide, est la bienvenue ! Pour toute question, remarque ou proposition d'aide, voyez cette page : https://gitlab.com/nathanael2/aelf-flutter/-/blob/master/README.md ou écrivez-nous sur nathanael+aelf@hannebert.fr \n \n")),
            Container(
              width: double.infinity,
              //constraints: BoxConstraints.expand(),
              padding: EdgeInsets.only(top: 15),
              child: Card(
                color: Theme.of(context).textTheme.headline6.color,
                child: ListTile(
                  dense: false,
                  title: Text("""Nouveautés : Zoom, veille désactivée, corrections.""",
                      textAlign: TextAlign.left,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyText1.color)),
                  subtitle: Text(
                      "La taille du texte est réglable dans les paramètres. Désormais, quand l'app est ouverte, la mise en veille de l'écran est désactivée. Les titres de livre s'affichent sur deux lignes dans les résulats de la recherche si nécessaire. Maintenance générale de l'application.",
                      style: TextStyle(
                          color: Theme.of(context).textTheme.bodyText1.color)),
                ),
              ),
            ),
            Card(
              color: Theme.of(context).textTheme.headline6.color,
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: custom.ExpansionTile(
                  headerBackgroundColor:
                      Theme.of(context).textTheme.headline6.color,
                  iconColor: Theme.of(context).textTheme.bodyText1.color,
                  title: Text(
                    "Historique des changements",
                    style: TextStyle(
                        color: Theme.of(context).textTheme.bodyText1.color,
                        fontSize: 14),
                  ),
                  backgroundColor: Theme.of(context).textTheme.headline6.color,
                  children: [
                    ListTile(
                      dense: true,
                      title: Text("Version 0.0.8 - 14/04/2022",
                          style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyText1.color)),
                      subtitle: Text(
                          "Ajout d'une fonctionnalité majeur : la recherche dans le texte intégral de la Bible.",
                          style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyText1.color)),
                    ),
                    ListTile(
                      dense: true,
                      title: Text("Version 0.0.7 - 14/12/2021",
                          style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyText1.color)),
                      subtitle: Text(
                          "Correction : ajout de l'hymne mariale après la bénédiction pour les complies, résolution d'un bug empêchant l'accès hors ligne à la liturgie, et d'un autre bloquant le chargement de certaines offices.",
                          style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyText1.color)),
                    ),                    ListTile(
                      dense: true,
                      title: Text("Version 0.0.6 - 24/02/2021",
                          style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyText1.color)),
                      subtitle: Text(
                          "Vous pouvez basculer entre les thèmes clair et sombre depuis le bouton situé dans le coin supérieur droit.",
                          style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyText1.color)),
                    ),
                    ListTile(
                      dense: true,
                      title: Text("Version 0.0.5 - 30/01/2021",
                          style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyText1.color)),
                      subtitle: Text(
                          "Adaptez la liturgie au calendrier liturgique de votre ! Le choix est accessible dans le nouveau menu paramètres.",
                          style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyText1.color)),
                    ),
                    ListTile(
                      dense: true,
                      title: Text("Version 0.0.4 - 22/09/2020",
                          style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyText1.color)),
                      subtitle: Text(
                          "Dans la Bible, il est désormais possible de sélectionner et copier le texte pour le partager, ou le garder dans ses notes.",
                          style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyText1.color)),
                    ),
                    ListTile(
                      dense: true,
                      title: Text("Version 0.0.3 - 26/06/2020",
                          style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyText1.color)),
                      subtitle: Text(
                          "Correction d'une erreur : si le psaume de la messe est un cantique il n'était pas affiché dans les versions précédentes.",
                          style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyText1.color)),
                    ),
                    ListTile(
                      dense: true,
                      title: Text("Version 0.0.2 - 01/06/2020",
                          style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyText1.color)),
                      subtitle: Text(
                          "Correction d'un bug où le sélecteur de date ne s'affichait pas.",
                          style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyText1.color)),
                    ),
                    ListTile(
                      dense: true,
                      title: Text("Version 0.0.1 - 18/05/2020",
                          style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyText1.color)),
                      subtitle: Text("Première version publiée",
                          style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyText1.color)),
                    ),
                  ],
                ),
              ),
            ),
            Linkify(
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyText1.color),
                textAlign: TextAlign.left,
                onOpen: (link) => _launchInBrowser(link.url),
                text:
                    ("\n\nLa traduction liturgique est le fruit du travail de l'AELF, l'Association épiscopale liturgique pour les pays francophones. Visitez ce site pour plus d'informations : https://www.aelf.org/page/les-missions-de-laelf Textes liturgiques, logo et nom reproduits avec l'autorisation de l'AELF. Tous droits réservés. L'AELF n'est pas responsable de cette application.")),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Valider',
                  style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    showDialog(context: context, builder: (BuildContext context) => popUp);
  }
}

Future<void> _launchInBrowser(url) async {
  if (await canLaunchUrl(Uri.parse(url))) {
    await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication 
    );
  } else {
    throw 'Could not launch $url';
  }
}
// TODO : add a changelog section - DONE
// TODO : fix dark theme for changelog
