import 'package:flutter/material.dart';

class ToDo {
  String feature;

  ToDo(this.feature);

  void popUp(BuildContext context) {
    print("Cette fonctionnalité (\"$feature\") n'est pas encore développée. \nCette application est libre et open source, si vous souhaitez nous aider à contribuer c'est possible sur :\ngitlab.com/nathanael2/aelf-flutter ");
    var popUp = AlertDialog(
      title: Center(child: Text("🚧 App en chantier 🛠")),
      content: Text("Cette fonctionnalité (\"$feature\") n'est pas encore développée. Cette application est libre🆓 et open source🔓, et le développement 👨‍💻 est encore en cours🚧. Toute aide est la bienvenue ! 🙂 🎉 💪 Voyez cette page :\n👉🏼gitlab.com/nathanael2/aelf-flutter "),
    );
    showDialog(context: context, builder: (BuildContext contect) => popUp);
  }
}

