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
                    margin: EdgeInsets.fromLTRB(70, 20, 0, 32),
                    child: Text(
                      'Affichage',
                      style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600),
                    )
                  ),
                  Container(
                    margin: EdgeInsets.fromLTRB(70, 0, 0, 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w400,
                              fontSize: 16
                            ),
                            text: "Taille du texte"
                            ),
                        ),
                        Container(
                          margin: EdgeInsets.fromLTRB(0, 2, 0, 0)
                        ),
                        Text(
                          "Agrandissement du texte : " + currentZoom.value.toStringAsFixed(0) + "%",
                          style: TextStyle(
                            color: Color(0x8a000000),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          )
                        )
                      ],
                    )
                  ),
                  Container(
                    margin: EdgeInsets.fromLTRB(46, 0, 0, 0),
                    child: Slider(
                      min:100,
                      max: 700,
                      value: currentZoom.value,
                      onChanged: (newValue) {
                        currentZoom.updateZoom(newValue);
                      },
                    )
                  ),
                Container(
                  margin: EdgeInsets.fromLTRB(54, 0, 0, 16),
                  child: Divider(height: 1, color: Color.fromARGB(255, 94, 94, 94))
                )
                ],
              )),
        );
        
      }),
    );
  }
}
//TODO: When region is slected refresh liturgy if shown, and refresh cache in db.