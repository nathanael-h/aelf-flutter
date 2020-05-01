import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';

class About {
  void popUp(BuildContext context) {
    var popUp = AlertDialog(
      title: Center(child: Text("À propos")),
      content: SingleChildScrollView(
        child: Linkify(
            onOpen: (link) => print("Clicked ${link.url}"),
            text:
                ("L'application AELF est développée bénévolement par quelques volontaires. Actuellement elle vous permet d'avoir sur votre iPhone toute la Bible dans la traduction française liturgique. Cette traduction est le fruit du travail de l'AELF, l'Association épisccopale liturgique pour les pays francophones. \n \n Cette application est libre🆓 et open source🔓, et le développement 👨‍💻 est encore en cours🚧. Toute aide est la bienvenue ! 🙂 🎉 💪 Pour toute question, remarque ou proposition d'aide, voyez cette page :\n👉🏼 https://gitlab.com/nathanael2/aelf-flutter ")),
      ),
    );
    showDialog(context: context, builder: (BuildContext contect) => popUp);
  }
}
// TODO : make link clickable
// TODO : add a "Valider" button
// TODO : add a changelog section
// TODO : jusitfy text
