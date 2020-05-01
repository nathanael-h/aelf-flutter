import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';

class About {
  void popUp(BuildContext context) {
    var popUp = AlertDialog(
      title: Center(child: Text("À propos")),
      content: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Linkify(
                textAlign: TextAlign.justify,
                onOpen: (link) => _launchInBrowser(link.url),
                text:
                    ("L'application AELF est développée bénévolement par quelques volontaires. Actuellement elle vous permet d'avoir sur votre iPhone toute la Bible dans la traduction française liturgique. Cette traduction est le fruit du travail de l'AELF, l'Association épisccopale liturgique pour les pays francophones. Voir le site pour plus d'informations : https://www.aelf.org/page/les-missions-de-laelf \n \n Cette application est libre🆓 et open source🔓, et le développement 👨‍💻 est encore en cours🚧. Toute aide est la bienvenue ! 🙂 🎉 💪 Pour toute question, remarque ou proposition d'aide, voyez cette page :\n👉🏼 https://gitlab.com/nathanael2/aelf-flutter ")),
            Align(
              alignment: Alignment.centerRight,
              child: FlatButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Valider'),
                textColor: Colors.black,
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
// TODO : add a "Valider" button
// TODO : add a changelog section
