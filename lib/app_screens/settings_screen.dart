import 'package:flutter/material.dart';
import 'package:aelf_flutter/settings.dart';

class SettingsScreen extends StatefulWidget {
  static const routeName = '/settingsScreen';
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

enum Regions { france, belgique, luxembourg, suisse, canada, afrique, autre }

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(30, 32, 36, 1),
        title: Text('Réglages'),
      ),
      body: Container(
          color: Theme.of(context).bottomAppBarColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Container(
                  margin: EdgeInsets.fromLTRB(70, 20, 0, 16),
                  child: Text(
                    'Lectures',
                    style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600),
                  )),
              RawMaterialButton(
                child: Container(
                  margin: EdgeInsets.fromLTRB(70, 20, 0, 16),
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Région',
                        style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      Text(
                        'Choisir une région',
                        style: TextStyle(fontWeight: FontWeight.normal),
                      ),
                    ],
                  ),
                ),
                onPressed: _askForRegion,
              ),
              Divider(),
              Container(
                  margin: EdgeInsets.fromLTRB(70, 20, 0, 16),
                  child: Text(
                    'Affichage',
                    style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600),
                  )),
              Container(
                  margin: EdgeInsets.fromLTRB(70, 16, 0, 16),
                  child: Text(
                    'Taille du texte',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  )),
            ],
          )),
    );
  }

  Future _askForRegion() async {
    await showDialog(
        context: context,
        child: SimpleDialog(
          title: Text('Choisissez une région'),
          children: <Widget>[
            SimpleDialogOption(
              child: Text('France'),
              onPressed: () {
                Navigator.pop(context);
                setPrefRegion('france');
              },
            ),
            SimpleDialogOption(
              child: Text('Belgique'),
              onPressed: () {
                Navigator.pop(context);
                setPrefRegion('belgique');
              },
            ),
            SimpleDialogOption(
              child: Text('Luxembourg'),
              onPressed: () {
                Navigator.pop(context);
                setPrefRegion('luxembourg');
              },
            ),
            SimpleDialogOption(
              child: Text('Suisse'),
              onPressed: () {
                Navigator.pop(context);
                setPrefRegion('suisse');
              },
            ),
            SimpleDialogOption(
              child: Text('Canada'),
              onPressed: () {
                Navigator.pop(context);
                setPrefRegion('canada');
              },
            ),
            SimpleDialogOption(
              child: Text('Afrique'),
              onPressed: () {
                Navigator.pop(context);
                setPrefRegion('afrique');
              },
            ),
            SimpleDialogOption(
              child: Text('Autre (Calendrier Romain)'),
              onPressed: () {
                Navigator.pop(context);
                setPrefRegion('autre');
              },
            ),
          ],
        ));
  }
}
//TODO: When region is slected refresh liturgy if shown, and refresh cache in db.