import 'package:aelf_flutter/data/changelog_data.dart';
import 'package:aelf_flutter/widgets/changelog_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:aelf_flutter/widgets/custom_expansion_tile.dart' as custom;

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
      backgroundColor: Theme.of(context).textTheme.titleLarge!.color,
      content: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Container(
              width: double.infinity,
              //constraints: BoxConstraints.expand(),
              padding: EdgeInsets.only(top: 15),
              child: Card(
                color: Theme.of(context).textTheme.titleLarge!.color,
                child: ListTile(
                  dense: false,
                  title: Text("""Nouveautés : Corrections""",
                      textAlign: TextAlign.left,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge!.color)),
                  subtitle: Text(
                      "Dans l'office des lecture, ajout du verset manquant après les psaumes.",
                      style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge!.color)),
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
                    ("L'app AELF (version $version) est développée bénévolement par des volontaires. Elle vous permet d'avoir sur votre iPhone la liturgie (messe et offices), et toute la Bible dans la traduction française liturgique. \n \nCette application est libre et open source, le développement principal est terminé, mais nous apportons régulièrement des améliorations et des corrections de bugs si nécessaire. Toute aide, est la bienvenue ! Pour toute question, remarque ou proposition d'aide, voyez cette page : https://gitlab.com/nathanael2/aelf-flutter/-/blob/master/README.md ou écrivez-nous sur nathanael+aelf@hannebert.fr \n \n Voici enfin le lien pour accéder aux futures mises à jour, afin de les tester avant une diffusion générale, nous remercions les testeurs pour leur aide en nous faisant des retours. https://testflight.apple.com/join/EwOULWvi")),
            Card(
              color: Theme.of(context).textTheme.titleLarge!.color,
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: custom.ExpansionTile(
                  headerBackgroundColor:
                      Theme.of(context).textTheme.titleLarge!.color,
                  iconColor: Theme.of(context).textTheme.bodyLarge!.color,
                  title: Text(
                    "Historique des changements",
                    style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge!.color,
                        fontSize: 14),
                  ),
                  backgroundColor:
                      Theme.of(context).textTheme.titleLarge!.color,
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
                    ("\n\nLa traduction liturgique est le fruit du travail de l'AELF, l'Association épiscopale liturgique pour les pays francophones. Visitez ce site pour plus d'informations : https://www.aelf.org/page/les-missions-de-laelf Textes liturgiques, logo et nom reproduits avec l'autorisation de l'AELF. Tous droits réservés. L'AELF n'est pas responsable de cette application.")),
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

Future<void> _launchInBrowser(url) async {
  if (await canLaunchUrl(Uri.parse(url))) {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } else {
    throw 'Could not launch $url';
  }
}
// TODO : add a changelog section - DONE
// TODO : fix dark theme for changelog
