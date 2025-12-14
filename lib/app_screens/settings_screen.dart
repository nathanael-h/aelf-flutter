import 'package:aelf_flutter/utils/text_management.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsMenu extends StatefulWidget {
  static const routeName = '/settingsScreen';
  @override
  SettingsMenuState createState() => SettingsMenuState();
}

enum _regions {
  france,
  belgique,
  luxembourg,
  suisse,
  canada,
  monaco,
  afrique,
  romain
}

class SettingsMenuState extends State<SettingsMenu> {
  String _region = 'romain';
  void _updateRegion(String newRegion) {
    print("Changing region to $newRegion");
    context.read<LiturgyState>().updateRegion(newRegion);
    setState(() => _region = newRegion);
  }

  @override
  Widget build(BuildContext context) {
    _region = context.watch<LiturgyState>().region;
    return Consumer<CurrentZoom>(
      builder: ((context, currentZoom, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Paramètres'),
          ),
          body: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Container(
                          margin: EdgeInsets.fromLTRB(70, 20, 0, 16),
                          child: Text(
                            'Lectures',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                                fontWeight: FontWeight.w600),
                          )),
                      Container(
                        margin: EdgeInsets.fromLTRB(54, 0, 0, 8),
                        child: RadioGroup(
                          onChanged: (String? value) {
                            _updateRegion(value!);
                          },
                          groupValue: _region,
                          child: ExpansionTile(
                            title: Text('Régions',
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color)),
                            subtitle: Text(
                                capitalizeFirstLowerElse(
                                    context.watch<LiturgyState>().region),
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .textTheme
                                      .headlineLarge
                                      ?.color,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                )),
                            children: [
                              RadioListTile(
                                title: Text('Autre (Calendrier romain)'),
                                value: _regions.romain.name,
                              ),
                              RadioListTile(
                                title: Text(capitalizeFirstLowerElse(
                                    _regions.afrique.name)),
                                value: _regions.afrique.name,
                              ),
                              RadioListTile(
                                title: Text(capitalizeFirstLowerElse(
                                    _regions.belgique.name)),
                                value: _regions.belgique.name,
                              ),
                              RadioListTile(
                                title: Text(capitalizeFirstLowerElse(
                                    _regions.canada.name)),
                                value: _regions.canada.name,
                              ),
                              RadioListTile(
                                title: Text(capitalizeFirstLowerElse(
                                    _regions.france.name)),
                                value: _regions.france.name,
                              ),
                              RadioListTile(
                                title: Text(capitalizeFirstLowerElse(
                                    _regions.luxembourg.name)),
                                value: _regions.luxembourg.name,
                              ),
                              RadioListTile(
                                title: Text(capitalizeFirstLowerElse(
                                    _regions.monaco.name)),
                                value: _regions.monaco.name,
                              ),
                              RadioListTile(
                                title: Text(capitalizeFirstLowerElse(
                                    _regions.suisse.name)),
                                value: _regions.suisse.name,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                          margin: EdgeInsets.fromLTRB(54, 12, 0, 16),
                          child: Divider(
                              height: 1,
                              color: Theme.of(context).dividerColor)),
                      Container(
                          margin: EdgeInsets.fromLTRB(70, 20, 0, 32),
                          child: Text(
                            'Affichage',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                                fontWeight: FontWeight.w600),
                          )),
                      Container(
                          margin: EdgeInsets.fromLTRB(70, 0, 0, 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color,
                                        fontWeight: FontWeight.w400,
                                        fontSize: 16),
                                    text: "Taille du texte"),
                              ),
                              Container(
                                  margin: EdgeInsets.fromLTRB(0, 2, 0, 0)),
                              Text(
                                  "Agrandissement du texte : ${currentZoom.value!.toStringAsFixed(0)}%",
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ))
                            ],
                          )),
                      Container(
                          margin: EdgeInsets.fromLTRB(46, 0, 0, 0),
                          child: Slider(
                            min: 60,
                            max: 300,
                            value: currentZoom.value!,
                            onChanged: (newValue) {
                              currentZoom.updateZoom(newValue);
                            },
                          )),
                      Container(
                          margin: EdgeInsets.fromLTRB(54, 0, 0, 16),
                          child: Divider(
                              height: 1, color: Theme.of(context).dividerColor))
                    ],
                  ),
                ),
              )),
        );
      }),
    );
  }
}
//TODO: When region is slected refresh liturgy if shown, and refresh cache in db.
