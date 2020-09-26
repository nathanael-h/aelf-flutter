import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';

class About {
  String version;
  About(this.version);
  void popUp(BuildContext context) {
    var popUp = AlertDialog(
      title: Align(alignment: Alignment.centerLeft, child: Text("À propos")),
      content: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Linkify(
                textAlign: TextAlign.left,
                onOpen: (link) => _launchInBrowser(link.url),
                text:
                    ("L'application AELF (version $version) est développée bénévolement par quelques volontaires, avec le soutien de l'AELF. Actuellement elle vous permet d'avoir sur votre iPhone la liturgie des heures, les lectures de la messe, et toute la Bible dans la traduction française liturgique. Cette traduction est le fruit du travail de l'AELF, l'Association épiscopale liturgique pour les pays francophones. Voir le site pour plus d'informations : https://www.aelf.org/page/les-missions-de-laelf \n \nCette application est libre et open source,le développement principal est terminé, mais nous apportons régulièrement des améliorations et des corrections de bugs si nécessaire. Toute aide est la bienvenue ! Pour toute question, remarque ou proposition d'aide, voyez cette page : https://gitlab.com/nathanael2/aelf-flutter/-/blob/master/README.md \n \nTextes liturgiques, logo et nom reproduits avec l'aimable autorisation de l'AELF. Tous droits réservés. L'AELF n'est pas responsable de cette application. ")),
            Align(
              alignment: Alignment.centerRight,
              child: FlatButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Valider'),
                textColor: Theme.of(context).primaryColor,
              ),
            )
          ],
        ),
      ),
    );
    showDialog(context: context, builder: (BuildContext contect) => popUp);
  }
}

Future<void> _launchInBrowser(String url) async {
  if (await canLaunch(url)) {
    await launch(
      url,
      forceSafariVC: false,
      forceWebView: false,
    );
  } else {
    throw 'Could not launch $url';
  }
}
// TODO : add a changelog section
