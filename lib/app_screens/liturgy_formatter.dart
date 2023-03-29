import 'dart:developer' as dev;
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/widgets/liturgy_tabs_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';


class LiturgyFormatter extends StatefulWidget {
  LiturgyFormatter(this.aelfJson);

  final aelfJson;

  @override
  _LiturgyFormatterState createState() => _LiturgyFormatterState();
}

class _LiturgyFormatterState extends State<LiturgyFormatter> 
  with TickerProviderStateMixin {
  
  Map<String, dynamic> decodedAelfJson;
  var localaelfJson;
  TabController _tabController;
  LoadingState loadingState = LoadingState.Loaded;

  

  List<int> _massPos = [];
  List<String> _tabMenuTitles;
  List<Widget> _tabChildren;
  int _length;

  Map <String, dynamic> loadingLiturgy() {
    return {
      '_tabMenuTitles': ['Chargement'],
      '_tabChildren': [Center(child: CircularProgressIndicator())],
      'tabLength': 1
    };
  }

  Map <String, dynamic> parseLiturgy(var aelfJson) {
    String title, text, subtitle, ref, nb;
    List<String> _newTabTitles = [];
    List<Widget> _newTabChildren = [];
    int _newLength = 0;
    var view = [];

    //setState(() {
    //  loadingState = LoadingState.Loading;
    //});

    if (aelfJson is Map && aelfJson.containsKey("erreur")) {
      print("aelf_json contains key erreur");
        _tabMenuTitles = ["Erreur"];
        _tabChildren = [DisplayContainer("Erreur", "", false, "", "", "", aelfJson["erreur"])];
        _tabController = TabController(vsync: this, length: 1);
      return {
        '_tabMenuTitles': _tabMenuTitles,
        '_tabChildren': _tabChildren,
        'tabLength': 1
      };
    } else if (aelfJson.containsKey("messes")) {
        print("aelf_json has no error");
      // display one tab per reading
      for (int e = 0; e < aelfJson["messes"].length; e++) {
        if (aelfJson["messes"].length > 1) {
          /* display the different masses if there are several
          add one button per mass in a tab
          display this tab before each mass so that we can 
          quickly jump from one mass to another  
          the nested loops are needed */
          List<Widget> list = <Widget>[];
          for (int i = 0; i < aelfJson["messes"].length; i++) {
            list.add(new GestureDetector(
                onTap: () {
                  // move to tab when select mass in liturgy screen context
                  _tabController.animateTo(
                    _newTabTitles.length >= i && i > 0 ? _massPos[i] : 0
                  );                  
                },
                child: Container(
                  margin: EdgeInsets.all(30.0),
                  padding: EdgeInsets.all(10.0),
                  alignment: Alignment.topCenter,
                  width: MediaQuery.of(context).size.width - 40,
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.secondary),
                    color: (i == e ? Theme.of(context).colorScheme.secondary : null),
                  ),
                  child: Text(aelfJson["messes"][i]["nom"],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: (i == e
                              ? Theme.of(context).scaffoldBackgroundColor
                              : Theme.of(context).textTheme.bodyText2.color),
                          fontSize: 20)),
                )));
          }
          // add mass menu
          this._massPos.add(_newTabTitles.length);
          _newTabTitles.add("Messes");
          _newTabChildren.add(SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.only(top: 100),
                  alignment: Alignment.center,
                  child: Column(children: list),
                ),
              ));
        }

        // display each mass elements
        for (int i = 0; i < aelfJson["messes"][e]["lectures"].length; i++) {
          List index = [
            "Première",
            "Deuxième",
            "Troisième",
            "Quatrième",
            "Cinqième",
            "Sixième",
            "Septième",
            "Huitième",
            "Neuvième",
            "Dixième"
          ];

          // foreach types of mass elements -> create new tab menu and add container with elements
          // el = mass element
          Map el = aelfJson["messes"][e]["lectures"][i];
          ref = el.containsKey("ref") ? el["ref"] : "";
          switch (el["type"]) {
            case 'sequence':
              {
                _newTabTitles.add("Séquence");
                _newTabChildren.add(DisplayContainer(
                    "Séquence", "", false, "", "", "", el["contenu"]));
              }
              break;
            case 'entree_messianique':
              {
                _newTabTitles.add("Entrée messianique");
                _newTabChildren.add(DisplayContainer("Entrée messianique",
                    el["intro_lue"], false, "", "", ref, el["contenu"]));
              }
              break;
            case 'psaume':
              {
                _newTabTitles.add("Psaume");
                _newTabChildren.add(DisplayContainer(
                    "Psaume",
                    el["refrain_psalmique"],
                    false,
                    "",
                    "",
                    ref,
                    el["contenu"]));
              }
              break;
            case 'cantique' : 
              {
                _newTabTitles.add("Cantique");
                _newTabChildren.add(DisplayContainer(
                  "Cantique",
                  el["refrain_psalmique"],
                  false,
                  "",
                  "",
                  ref,
                  el["contenu"]));
              }
              break;
            case 'evangile':
              {
                _newTabTitles.add("Évangile");
                _newTabChildren.add(DisplayContainer(
                    el["titre"],
                    el["intro_lue"],
                    false,
                    (el.containsKey("verset_evangile")
                        ? el['verset_evangile']
                        : ""),
                    (el.containsKey("ref_verset") ? el['ref_verset'] : ""),
                    ref,
                    el["contenu"]));
              }
              break;
            default:
              {
                if (el["type"].contains("lecture_")) {
                  nb = el["type"].split('_')[1];
                  title = index.length >= int.parse(nb)
                      ? "${index[int.parse(nb) - 1]} Lecture"
                      : "Lecture $nb";
                  _newTabTitles.add(title);
                  _newTabChildren.add(DisplayContainer(el["titre"],
                      el["intro_lue"], false, "", "", ref, el["contenu"]));
                }
              }
              break;
          }
        }
      }
      _length = _newTabChildren.length; //int
      _tabController = TabController(vsync: this, length: _length);
      _tabMenuTitles = _newTabTitles; // List<Widget>
      _tabChildren = _newTabChildren; // List<Widget>
      return {
        '_tabMenuTitles': _tabMenuTitles,
        '_tabChildren': _tabChildren,
        'tabLength': _length
      };
    } else if (aelfJson.containsKey("informations")) {
      //set lenght
      _newLength = 1;
      
      // generate sentence
      text = "${capitalize(aelfJson["informations"]["jour"])} ${aelfJson["informations"]["fete"]}" +
          (aelfJson["informations"].containsKey("semaine") ? ", ${aelfJson["informations"]["semaine"]}." : ".") +
          (aelfJson["informations"].containsKey("couleur")
              ? " La couleur liturgique est le ${aelfJson["informations"]["couleur"]}."
              : "");
      // display screen
      _newTabTitles.add("Informations");
      _newTabChildren.add(Container(
            padding: EdgeInsets.symmetric(vertical: 100, horizontal: 25),
            child: Consumer<CurrentZoom>(
              builder: (context, currentZoom, child) => Text(text,
                textAlign: TextAlign.center, style: TextStyle(fontSize: 18 * currentZoom.value/100)),
            ),
          ));

        _length = _newLength; //int
        _tabController = TabController(vsync: this, length: _length);
        _tabMenuTitles = _newTabTitles; // List<Widget>
        _tabChildren = _newTabChildren; // List<Widget>
      return {
        '_tabMenuTitles': _tabMenuTitles,
        '_tabChildren': _tabChildren,
        'tabLength': _length
      };
    } else {
      // for each element in others types -> add to new tabs (key -type of element, value - content)
      var office = aelfJson.keys.first;
      aelfJson[office].forEach((k, v) {
        if (v != null) { 
          if (v.length != 0) {
            // get text reference
            ref = "";
            if (v.runtimeType != String && v.runtimeType != int) {
              ref = v.containsKey("reference") ? v["reference"] : "";
            }

            // foreach types of elements -> create new tab menu and add container with elements
            switch (k) {
              case 'introduction':
                {
                  _newTabTitles.add("Introduction");
                  _newTabChildren.add(
                      DisplayContainer("Introduction", "", false, "", "", "", v));
                }
                break;
              case 'psaume_invitatoire':
                {
                  // define subtitle with antienne before and remove html text tags
                  subtitle = aelfJson[office].containsKey("antienne_invitatoire")
                      ? aelfJson[office]["antienne_invitatoire"]
                      : "";
                  // add antienne before subtitle
                  subtitle = addAntienneBefore(subtitle);
                  text = v["texte"] + "<p>Gloire au Père,...</p>";

                  _newTabTitles.add("Antienne invitatoire");
                  _newTabChildren.add(DisplayContainer(
                      "Psaume invitatoire",
                      subtitle,
                      true,
                      "",
                      "",
                      (ref != "" ? "Ps $ref" : ""),
                      text));
                }
                break;
              case 'hymne':
                {
                  _newTabTitles.add("Hymne");
                  _newTabChildren.add(DisplayContainer(
                      "Hymne", v["titre"], false, "", "", "", v["texte"]));
                }
                break;
              case 'cantique_mariale':
                {
                  // define subtitle with antienne before and remove html text tags
                  subtitle = aelfJson[office].containsKey("antienne_magnificat")
                      ? aelfJson[office]["antienne_magnificat"]
                      : "";
                  // add antienne before subtitle
                  subtitle = addAntienneBefore(subtitle);

                  _newTabTitles.add(v["titre"]);
                  _newTabChildren.add(DisplayContainer(
                      v["titre"], subtitle, true, "", "", ref, v["texte"]));
                }
                break;
              case 'pericope':
                {
                  _newTabTitles.add("Parole de Dieu");
                  _newTabChildren.add(DisplayContainer(
                      "Parole de Dieu",
                      "",
                      false,
                      "",
                      "",
                      ref,
                      v["texte"] +
                          '<p class="repons">Répons</p>' +
                          aelfJson[office]["repons"]));
                }
                break;
              case 'lecture':
                {
                  _newTabTitles.add("Lecture");
                  _newTabChildren.add(DisplayContainer(
                      "« " + capitalize(v["titre"]) + " »",
                      "",
                      false,
                      "",
                      "",
                      ref,
                      v["texte"] +
                          '<p class="repons">Répons</p>' +
                          aelfJson[office]["repons_lecture"]));
                }
                break;
              case 'te_deum':
                {
                  _newTabTitles.add(v["titre"]);
                  _newTabChildren.add(DisplayContainer(
                      v["titre"], "", false, "", "", ref, v["texte"]));
                }
                break;
              case 'texte_patristique':
                {
                  _newTabTitles.add("Lecture patristique");
                  _newTabChildren.add(DisplayContainer(
                      "« " + capitalize(aelfJson[office]["titre_patristique"]) + " »",
                      "",
                      false,
                      "",
                      "",
                      ref,
                      v +
                          '<p class="repons">Répons</p>' +
                          aelfJson[office]["repons_patristique"]));
                }
                break;
              case 'intercession':
                {
                  _newTabTitles.add("Intercession");
                  _newTabChildren.add(DisplayContainer(
                      "Intercession", "", false, "", "", ref, v));
                }
                break;
              case 'notre_pere':
                {
                  _newTabTitles.add("Notre Père");
                  _newTabChildren.add(DisplayContainer(
                      "Notre Père",
                      "",
                      false,
                      "",
                      "",
                      "",
                      "Notre Père, qui es aux cieux, <br>que ton nom soit sanctifié,<br>que ton règne vienne,<br>que ta volonté soit faite sur la terre comme au ciel.<br>Donne-nous aujourd’hui notre pain de ce jour.<br>Pardonne-nous nos offenses,<br>comme nous pardonnons aussi à ceux qui nous ont offensés.<br>Et ne nous laisse pas entrer en tentation<br>mais délivre-nous du Mal.<br><br>Amen"));
                }
                break;
              case 'oraison':
                {
                  text = v + "<p class=\"spacer\"><br></p>Que le seigneur nous bénisse, qu'il nous garde de tout mal, et nous conduise à la vie éternelle.<br>Amen.";
                  _newTabTitles.add("Oraison et bénédiction");
                  _newTabChildren.add(DisplayContainer(
                      "Oraison et bénédiction", "", false, "", "", ref, text));
                }
                break;
              case 'hymne_mariale':
                {
                  _newTabTitles.add(v["titre"]);
                  _newTabChildren.add(
                    DisplayContainer(v["titre"], "", false, "", "", "", v["texte"])
                  );
                }
                break;
              case 'erreur':
                {
                  _newTabTitles.add("Erreur");
                  _newTabChildren.add(
                      DisplayContainer("Erreur", "", false, "", "", "", v));
                }
                break;
              default:
                {
                  // display pasumes and cantiques
                  if (k.contains("psaume_") || k.contains("cantique_")) {
                    // get number of the element
                    nb = k.split('_')[1];
                    title = k.contains("psaume_")
                        ? "Psaume " + v["reference"]
                        : v["titre"];
                    subtitle = aelfJson[office].containsKey("antienne_" + nb)
                        ? aelfJson[office]["antienne_" + nb]
                        : "";

                    // add antienne before subtitle
                    subtitle = addAntienneBefore(subtitle);
                    // if no antienne and psaume is splited, get previous antienne
                    RegExp regExp = new RegExp(
                      r"- (I|V)",
                      caseSensitive: false,
                      multiLine: false,
                    );
                    if (subtitle == "" && regExp.hasMatch(title)) {
                      for (int i = int.parse(nb) - 1; i > 0; i--) {
                        // foreach previous antiennes
                        nb = i.toString();
                        if (aelfJson[office].containsKey("antienne_" + nb) &&
                            aelfJson[office]["antienne_" + nb] != "") {
                          subtitle =
                              addAntienneBefore(aelfJson[office]["antienne_" + nb]);
                          break;
                        }
                      }
                    }

                    // parse name of cantique when it is with psaume id and transform his name form
                    if (k.contains("psaume_") &&
                        v["reference"].toLowerCase().contains("cantique")) {
                      List<String> t = ref.split("(");
                      if (t.length > 0) {
                        title = capitalize(t[0]);
                      }
                      // get cantique reference
                      if (t.length > 1) {
                        RegExp exp =
                            new RegExp(r"(\(|\).|\))", caseSensitive: false);
                        ref = t[1].replaceAll(exp, "");
                      }
                    } else if (k.contains("psaume_")) {
                      // add ps before psaume reference
                      ref = ref != "" ? "Ps $ref" : "";
                    }
                    text = v["texte"] + "<p>Gloire au Père,...</p>";

                    _newTabTitles.add(title);
                    _newTabChildren.add(DisplayContainer(
                        title, subtitle, true, "", "", ref, text));
                  }
                }
                break;
            }
          }
        }
      });
        _length = _newTabChildren.length; //int
        _tabController = TabController(vsync: this, length: _newTabChildren.length);
        _tabMenuTitles = _newTabTitles; // List<Widget>
        _tabChildren = _newTabChildren; // List<Widget>
      return {
        '_tabMenuTitles': _tabMenuTitles,
        '_tabChildren': _tabChildren,
        'tabLength': _length
      };
    }
  }

  @override
  initState() {
    //loadingState = LoadingState.Loading;
    
    // init tabs
    _tabController = TabController(
      initialIndex: 0,
      length: 2,
      vsync: this,
    );
    _tabMenuTitles = ['Chargement 1', 'Chargement 2'];
    _tabChildren = [Center(child: Text('1...')),Center(child: Text('2...'))];
    parseLiturgy(widget.aelfJson);
    super.initState();
  }
  
  
  @override
  Widget build(BuildContext context) {
    //_isAelfJsonChanged();
    // FIXME: I am triggered thousand times per second
    dev.log("build LiturgyFormatter");
    switch (loadingState) {
      case LoadingState.Loading:
        return 
        Center(child: CircularProgressIndicator());
      case LoadingState.Loaded:
        return
        Consumer<LiturgyState>(
          builder: (context, liturgyState, child) {
            //parseLiturgy(liturgyState.aelfJson);
            return Scaffold(
            //TODO: when the issue above is fixe, add a GestureDetectore to zoom in and out, same as in book_screen.dart
            body: 
            LiturgyTabsView(tabsMap: parseLiturgy(liturgyState.aelfJson)),
            //Column(
            //  children: [
            //    // Ok now we have date and json that can be provided by a provider ^^
            //    // TODO: go on with region and liturgy type
            //    // TODO: replace all old stuffs
            //    Text(liturgyState.date),
            //    Text(liturgyState.region),
            //    Text(liturgyState.aelfJson.toString().substring(0,70)),
            //    // TODO: reprendre ici : on a créé un widget LiturgyTabsView, lui faire utiliser 
            //    // la liturgy depuis le provider. 
            //    Container(
            //      color: Theme.of(context).primaryColor,
            //      width: MediaQuery.of(context).size.width,
            //      child: Center(
            //        child: TabBar(
            //          indicatorColor: Theme.of(context).tabBarTheme.labelColor,
            //          labelColor: Theme.of(context).tabBarTheme.labelColor,
            //          unselectedLabelColor:
            //            Theme.of(context).tabBarTheme.unselectedLabelColor,
            //          labelPadding: EdgeInsets.symmetric(horizontal: 0),
            //          isScrollable: true,
            //          controller: _tabController,
            //          tabs: <Widget>[
            //            for(String title in _tabMenuTitles) ConstrainedBox(
            //              constraints: BoxConstraints(
            //                minWidth: (MediaQuery.of(context).size.width / 3),
            //              ),
            //              child: Container(
            //                padding: EdgeInsets.symmetric(horizontal: 12),
            //                child: Tab(text: title),
            //              )
            //            )
            //          ]
            //        ),
            //      ),
            //    ),
            //    Expanded(
            //      child: TabBarView(
            //        controller: _tabController,
            //        children: _tabChildren
            //      ),
            //    ),
            //  ],
            //),
          );
          },
        );
        break;
      }
    return 
    Text('Erreur...');
  }
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

enum LoadingState {
  Loading,
  Loaded
}


String capitalize(String s) {
  if (s == null) {
    return "";
  } else
  if (s.length <= 1)  {
    return "";
  } else
  return s[0].toUpperCase() + s.substring(1).toLowerCase();
}

String correctAelfHTML(String content) {
  // transform text elements for better displaying and change their color
  return content
      .replaceAll('V/ <p>', '<p>V/ ')
      .replaceAll('R/ <p>', '<p>R/ ')
      .replaceAll('V/', '<span class="red-text">V/</span>')
      .replaceAll('R/', '<span class="red-text">R/</span>');
}

String removeAllHtmlTags(String htmlText) {
  RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
  return htmlText.replaceAll(exp, '');
}

String addAntienneBefore(String content) {
  if (content != "" && content != null) {
    return '<span class="red-text">Antienne : </span>' +
        removeAllHtmlTags(content);
  }
  return "";
}

// widget to display all element in tab view
class DisplayContainer extends StatelessWidget {
  final String title, subtitle, intro, refIntro, ref, content;
  final bool repeatSubtitle;

  const DisplayContainer(this.title, this.subtitle, this.repeatSubtitle, 
    this.intro, this.refIntro, this.ref, this.content,{Key key}) : super (key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.topLeft,
      child: SingleChildScrollView(
        child: Column(children: <Widget>[
          // title
          GenerateWidgetTitle (title),
          // reference
          GenerateWidgetRef(ref),
          // subtitle
          GenerateWidgetSubtitle(subtitle),
          // intro
          GenerateWidgetContent(intro),
          GenerateWidgetRef(refIntro),
          // content
          GenerateWidgetContent(content),
          // subtitle again for psaumes antiennes
          (repeatSubtitle ? GenerateWidgetSubtitle(subtitle) : Row()),
          // add bottom padding
          Padding(
            padding: EdgeInsets.only(bottom: 150),
          ),
        ]),
      ),
    );
  }
}

class GenerateWidgetTitle extends StatelessWidget {
  final String content;

  const GenerateWidgetTitle(this.content, {Key key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    if (content == "") {
      return Row();
    } else {
      return Consumer<CurrentZoom>(
        builder: (context, currentZoom, child) => Row(children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 25, bottom: 5, left: 5),
              child: Html(
                data: content,
                style: {
                  "html": Style.fromTextStyle(
                    TextStyle(
                    color: Theme.of(context).textTheme.bodyText2.color,
                    fontWeight: FontWeight.w900,
                    fontSize: 20 * currentZoom.value/100),
                  )
                },
        ),
            ),
          ),
          ]),
      );
    }
  }
}

class GenerateWidgetRef extends StatelessWidget {
  final String content;

  GenerateWidgetRef(this.content, {Key key}) : super (key: key);

  @override
  Widget build(BuildContext context) {
    if (content == "") {
      return Padding(
        padding: EdgeInsets.only(bottom: 20),
      );
    } else {
      return Consumer<CurrentZoom>(
        builder: (context, currentZoom, child) => Padding(
          padding: EdgeInsets.only(right: 15, bottom: 20),
          child: Align(
            alignment: Alignment.topRight,
            child: Text((content != "" ? "- $content" : ""),
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 16 * currentZoom.value/100,
                    color: Theme.of(context).textTheme.bodyText2.color)),
          )
        ),
      );
    }
  }
}

class GenerateWidgetSubtitle extends StatelessWidget {
  final String content;

  const GenerateWidgetSubtitle(this.content, {Key key}) : super (key: key);

  @override
  Widget build(BuildContext context) {
    if (content == "") {
      return Row();
    } else { 
        return Consumer<CurrentZoom>(
          builder: (context, currentZoom, child) => Row(children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 5),
                child: Html(
                  data: content,
                  style: {
                    "html": Style.fromTextStyle(
                      TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 17 * currentZoom.value/100,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).textTheme.bodyText2.color),
                    ),
                    ".red-text": Style.fromTextStyle(TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 14 * currentZoom.value/100))
                  },
          ),
              ),
            ),
              ]),
        );
    }
  }
}

class GenerateWidgetContent extends StatelessWidget {
  final String content;

  const GenerateWidgetContent(this.content, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (content == "") {
      return Row();
    } else {
      return Consumer<CurrentZoom>(
        builder: (context, currentZoom, child) => Row(children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10, left: 5),
              child: Html(
                data: correctAelfHTML(content),
                style: {
                  "html": Style.fromTextStyle(TextStyle(color: Theme.of(context).textTheme.bodyText2.color, fontSize: 16 * currentZoom.value/100)),
                  ".verse_number": Style.fromTextStyle(
                    TextStyle(
                      height: 1.2,
                      fontSize: 14 * currentZoom.value/100,
                      color: Theme.of(context).colorScheme.secondary)
                    ),
                  ".repons": Style.fromTextStyle(TextStyle(
                    height: 5, color: Theme.of(context).colorScheme.secondary, fontSize: 14 * currentZoom.value/100
                    )
                  ),
                  ".red-text": Style.fromTextStyle(TextStyle(color: Theme.of(context).colorScheme.secondary)),
                  ".spacer": Style.fromTextStyle(
                    TextStyle(fontSize: 14 * currentZoom.value/100, height: 0.3 * currentZoom.value/100)
                    )
                }
              ),
            ),
          ),
        ]),
      );
    }
  }
}
