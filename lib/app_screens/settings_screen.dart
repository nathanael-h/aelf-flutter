import 'package:aelf_flutter/states/fontSizeState.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences_settings/shared_preferences_settings.dart';
import 'package:aelf_flutter/settings.dart';


class SettingsMenu extends StatefulWidget {
  static const routeName = '/settingsScreen';
  @override
  _SettingsMenuState createState() => _SettingsMenuState();
}

enum Regions { france, belgique, luxembourg, suisse, canada, afrique, autre }

class _SettingsMenuState extends State<SettingsMenu> {
  get _subtitle {
    Settings().getString(keyPrefRegion, 'Choisir une région').then((value) => value);
  }
  @override
  Widget build(BuildContext context) {
    return Consumer<CurrentZoom>(
      builder: ((context, currentZoom, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Paramètres'),
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
                  Container(
                    margin: EdgeInsets.fromLTRB(54, 0, 0, 16),
                    child: RadioPickerSettingsTile(
                        settingKey: keyPrefRegion,
                        title: 'Régions', 
                        subtitle: _subtitle,
                        values: {
                            'afrique': 'Afrique',
                            'belgique': 'Belgique',
                            'canada': 'Canada',
                            'france': 'France',
                            'luxembourg': 'Luxembourg',
                            'suisse' : 'Suisse',
                            'romain' : 'Autre (Calendrier romain)',
                        },
                        defaultKey: 'romain',
                        cancelCaption: 'Annuler',
                    ),
                  ),
                  Container(
                      margin: EdgeInsets.fromLTRB(70, 20, 0, 16),
                      child: Text(
                        'Affichage',
                        style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w600),
                      )),
                  Container(
                    margin: EdgeInsets.fromLTRB(54, 0, 0, 16),
                    child: Column(children: [
                      Text("Agrandissement du texte : " + currentZoom.value.toStringAsFixed(0) + "%"),
                      Slider(
                        min:100,
                        max: 700,
                        value: currentZoom.value,
                        onChanged: (newValue) {
                          currentZoom.updateZoom(newValue);
                        },
                      )
                    ],)
                  ),
                  //Container(
                  //    margin: EdgeInsets.fromLTRB(70, 20, 0, 16),
                  //    child: Text(
                  //      'Affichage',
                  //      style: TextStyle(
                  //          color: Theme.of(context).primaryColor,
                  //          fontWeight: FontWeight.w600),
                  //    )),
                  //Container(
                  //    margin: EdgeInsets.fromLTRB(70, 16, 0, 16),
                  //    child: Text(
                  //      'Taille du texte',
                  //      style: TextStyle(fontWeight: FontWeight.w600),
                  //    )),
                ],
              )),
        );
        
      }),
    );
  }
}
//TODO: When region is slected refresh liturgy if shown, and refresh cache in db.