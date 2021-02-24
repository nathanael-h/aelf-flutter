import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class LiturgyFormatter extends StatefulWidget {
  LiturgyFormatter(this.aelfJson, this._liturgyType, this.fontSize);
  double fontSize;

  final aelfJson;
  final String _liturgyType;

  @override
  _LiturgyFormatterState createState() => _LiturgyFormatterState();
}

class _LiturgyFormatterState extends State<LiturgyFormatter>
    with TickerProviderStateMixin {
  Map<String, dynamic> decodedAelfJson;
  var localaelfJson;
  TabController _tabController;
  LoadingState loadingState = LoadingState.Loading;

  List<int> _massPos = [];
  List<String> _tabMenuTitles;
  List<Widget> _tabChildren;
  int _length;

  void parseLiturgy(var aelfJson) {
    String title, text, subtitle, ref, nb;
    List<String> _newTabTitles = [];
    List<Widget> _newTabChildren = [];
    int _newLength = 0;

    setState(() {
      loadingState = LoadingState.Loading;
    });

    if (aelfJson is Map && aelfJson.containsKey("erreur")) {
      print("aelfJson contains key erreur");
      setState(() {
        _tabMenuTitles = ["Erreur"];
        _tabChildren = [
          DisplayContainer("Erreur", "", false, "", "", "", aelfJson["erreur"],
              widget.fontSize)
        ];
        _tabController = TabController(vsync: this, length: 1);
        loadingState = LoadingState.Loaded;
      });
    } else if (widget._liturgyType == "messes") {
      print("aelfJson has no error");
      // display one tab per reading
      for (int e = 0; e < aelfJson.length; e++) {
        if (aelfJson.length > 1) {
          /* display the different masses if there are several
          add one button per mass in a tab
          display this tab before each mass so that we can 
          quickly jump from one mass to another  
          the nested loops are needed */
          List<Widget> list = <Widget>[];
          for (int i = 0; i < aelfJson.length; i++) {
            list.add(new GestureDetector(
                onTap: () {
                  // move to tab when select mass in liturgy screen context
                  _tabController.animateTo(
                      _newTabTitles.length >= i && i > 0 ? _massPos[i] : 0);
                },
                child: Container(
                  margin: EdgeInsets.all(30.0),
                  padding: EdgeInsets.all(10.0),
                  alignment: Alignment.topCenter,
                  width: MediaQuery.of(context).size.width - 40,
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).accentColor),
                    color: (i == e ? Theme.of(context).accentColor : null),
                  ),
                  child: Text(aelfJson[i]["nom"],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: (i == e
                              ? Theme.of(context).scaffoldBackgroundColor
                              : Theme.of(context).textTheme.bodyText2.color),
                          fontSize: widget.fontSize + 6)),
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
        for (int i = 0; i < aelfJson[e]["lectures"].length; i++) {
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
          Map el = aelfJson[e]["lectures"][i];
          ref = el.containsKey("ref") ? el["ref"] : "";
          switch (el["type"]) {
            case 'sequence':
              {
                _newTabTitles.add("Séquence");
                _newTabChildren.add(DisplayContainer("Séquence", "", false, "",
                    "", "", el["contenu"], widget.fontSize));
              }
              break;
            case 'entree_messianique':
              {
                _newTabTitles.add("Entrée messianique");
                _newTabChildren.add(DisplayContainer(
                    "Entrée messianique",
                    el["intro_lue"],
                    false,
                    "",
                    "",
                    ref,
                    el["contenu"],
                    widget.fontSize));
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
                    el["contenu"],
                    widget.fontSize));
              }
              break;
            case 'cantique':
              {
                _newTabTitles.add("Cantique");
                _newTabChildren.add(DisplayContainer(
                    "Cantique",
                    el["refrain_psalmique"],
                    false,
                    "",
                    "",
                    ref,
                    el["contenu"],
                    widget.fontSize));
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
                    el["contenu"],
                    widget.fontSize));
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
                  _newTabChildren.add(DisplayContainer(
                      el["titre"],
                      el["intro_lue"],
                      false,
                      "",
                      "",
                      ref,
                      el["contenu"],
                      widget.fontSize));
                }
              }
              break;
          }
        }
      }
      setState(() {
        _length = _newTabChildren.length; //int
        _tabController = TabController(vsync: this, length: _length);
        _tabMenuTitles = _newTabTitles; // List<Widget>
        _tabChildren = _newTabChildren; // List<Widget>
      });
    } else if (widget._liturgyType == "informations") {
      //set lenght
      _newLength = 1;

      // generate sentence
      text = "${capitalize(aelfJson["jour"])} ${aelfJson["fete"]}" +
          (aelfJson.containsKey("semaine") ? ", ${aelfJson["semaine"]}." : ".") +
          (aelfJson.containsKey("couleur")
              ? " La couleur liturgique est le ${aelfJson["couleur"]}."
              : "");
      // display screen
      _newTabTitles.add("Informations");
      _newTabChildren.add(Container(
        padding: EdgeInsets.symmetric(vertical: 100, horizontal: 25),
        child: Text(text,
            textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
      ));

      setState(() {
        _length = _newLength; //int
        _tabController = TabController(vsync: this, length: _length);
        _tabMenuTitles = _newTabTitles; // List<Widget>
        _tabChildren = _newTabChildren; // List<Widget>
      });
    } else {
      // for each element in others types -> add to new tabs (key -type of element, value - content)
      aelfJson.forEach((k, v) {
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
                _newTabChildren.add(DisplayContainer(
                    "Introduction", "", false, "", "", "", v, widget.fontSize));
              }
              break;
            case 'psaume_invitatoire':
              {
                // define subtitle with antienne before and remove html text tags
                subtitle = aelfJson.containsKey("antienne_invitatoire")
                    ? aelfJson["antienne_invitatoire"]
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
                    text,
                    widget.fontSize));
              }
              break;
            case 'hymne':
              {
                _newTabTitles.add("Hymne");
                _newTabChildren.add(DisplayContainer("Hymne", v["titre"], false,
                    "", "", "", v["texte"], widget.fontSize));
              }
              break;
            case 'cantique_mariale':
              {
                // define subtitle with antienne before and remove html text tags
                subtitle = aelfJson.containsKey("antienne_magnificat")
                    ? aelfJson["antienne_magnificat"]
                    : "";
                // add antienne before subtitle
                subtitle = addAntienneBefore(subtitle);

                _newTabTitles.add(v["titre"]);
                _newTabChildren.add(DisplayContainer(v["titre"], subtitle, true,
                    "", "", ref, v["texte"], widget.fontSize));
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
                        aelfJson["repons"],
                    widget.fontSize));
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
                        aelfJson["repons_lecture"],
                    widget.fontSize));
              }
              break;
            case 'te_deum':
              {
                _newTabTitles.add(v["titre"]);
                _newTabChildren.add(DisplayContainer(v["titre"], "", false, "",
                    "", ref, v["texte"], widget.fontSize));
              }
              break;
            case 'texte_patristique':
              {
                _newTabTitles.add("Lecture patristique");
                _newTabChildren.add(DisplayContainer(
                    "« " + capitalize(aelfJson["titre_patristique"]) + " »",
                    "",
                    false,
                    "",
                    "",
                    ref,
                    v +
                        '<p class="repons">Répons</p>' +
                        aelfJson["repons_patristique"],
                    widget.fontSize));
              }
              break;
            case 'intercession':
              {
                _newTabTitles.add("Intercession");
                _newTabChildren.add(DisplayContainer("Intercession", "", false,
                    "", "", ref, v, widget.fontSize));
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
                    "Notre Père, qui es aux cieux, <br>que ton nom soit sanctifié,<br>que ton règne vienne,<br>que ta volonté soit faite sur la terre comme au ciel.<br>Donne-nous aujourd’hui notre pain de ce jour.<br>Pardonne-nous nos offenses,<br>comme nous pardonnons aussi à ceux qui nous ont offensés.<br>Et ne nous laisse pas entrer en tentation<br>mais délivre-nous du Mal.<br><br>Amen",
                    widget.fontSize));
              }
              break;
            case 'oraison':
              {
                text = v +
                    "<p class=\"spacer\"><br></p>Que le seigneur nous bénisse, qu'il nous garde de tout mal, et nous conduise à la vie éternelle.<br>Amen.";
                _newTabTitles.add("Oraison");
                _newTabChildren.add(DisplayContainer(
                    "Oraison", "", false, "", "", ref, text, widget.fontSize));
              }
              break;
            case 'erreur':
              {
                _newTabTitles.add("Erreur");
                _newTabChildren.add(DisplayContainer(
                    "Erreur", "", false, "", "", "", v, widget.fontSize));
              }
              break;
            
            case 'hymne':
              {
                _newTabTitles.add("Hymne");
                _newTabChildren.add(DisplayContainer(
                    "Hymne", v["titre"], false, "", "", "", v["texte"],widget.fontSize));
              }
              break;
            case 'cantique_mariale':
              {
                // define subtitle with antienne before and remove html text tags
                subtitle = aelfJson.containsKey("antienne_magnificat")
                    ? aelfJson["antienne_magnificat"]
                    : "";
                // add antienne before subtitle
                subtitle = addAntienneBefore(subtitle);

                _newTabTitles.add(v["titre"]);
                _newTabChildren.add(DisplayContainer(
                    v["titre"], subtitle, true, "", "", ref, v["texte"],widget.fontSize));
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
                        aelfJson["repons"],
                        widget.fontSize));
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
                        aelfJson["repons_lecture"],
                        widget.fontSize));
              }
              break;
            case 'te_deum':
              {
                _newTabTitles.add(v["titre"]);
                _newTabChildren.add(DisplayContainer(
                    v["titre"], "", false, "", "", ref, v["texte"],
                    widget.fontSize));
              }
              break;
            case 'texte_patristique':
              {
                _newTabTitles.add("Lecture patristique");
                _newTabChildren.add(DisplayContainer(
                    "« " + capitalize(aelfJson["titre_patristique"]) + " »",
                    "",
                    false,
                    "",
                    "",
                    ref,
                    v +
                        '<p class="repons">Répons</p>' +
                        aelfJson["repons_patristique"],
                        widget.fontSize));
              }
              break;
            case 'intercession':
              {
                _newTabTitles.add("Intercession");
                _newTabChildren.add(DisplayContainer(
                    "Intercession", "", false, "", "", ref, v, widget.fontSize));
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
                    "Notre Père, qui es aux cieux, <br>que ton nom soit sanctifié,<br>que ton règne vienne,<br>que ta volonté soit faite sur la terre comme au ciel.<br>Donne-nous aujourd’hui notre pain de ce jour.<br>Pardonne-nous nos offenses,<br>comme nous pardonnons aussi à ceux qui nous ont offensés.<br>Et ne nous laisse pas entrer en tentation<br>mais délivre-nous du Mal.<br><br>Amen",
                    widget.fontSize));
              }
              break;
            case 'oraison':
              {
                text = v + "<p class=\"spacer\"><br></p>Que le seigneur nous bénisse, qu'il nous garde de tout mal, et nous conduise à la vie éternelle.<br>Amen.";
                _newTabTitles.add("Oraison et bénédiction");
                _newTabChildren.add(DisplayContainer(
                    "Oraison et bénédiction", "", false, "", "", ref, text,widget.fontSize));
              }
              break;
            case 'hymne_mariale':
              {
                _newTabTitles.add(v["titre"]);
                _newTabChildren.add(
                  DisplayContainer(v["titre"], "", false, "", "", "", v["texte"],widget.fontSize)
                );
              }
              break;
            case 'erreur':
              {
                _newTabTitles.add("Erreur");
                _newTabChildren.add(
                    DisplayContainer("Erreur", "", false, "", "", "", v,widget.fontSize));
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
                  subtitle = aelfJson.containsKey("antienne_" + nb)
                      ? aelfJson["antienne_" + nb]
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
                      if (aelfJson.containsKey("antienne_" + nb) &&
                          aelfJson["antienne_" + nb] != "") {
                        subtitle =
                            addAntienneBefore(aelfJson["antienne_" + nb]);
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
                      title, subtitle, true, "", "", ref, text,widget.fontSize));
                }
              }
              break;
            
            }
          }
        }
      });
      setState(() {
        _length = _newTabChildren.length; //int
        _tabController =
            TabController(vsync: this, length: _newTabChildren.length);
        _tabMenuTitles = _newTabTitles; // List<Widget>
        _tabChildren = _newTabChildren; // List<Widget>
      });
    }
    setState(() {
      loadingState = LoadingState.Loaded;
    });
  }

  void _isAelfJsonChanged() {
    if (localaelfJson != widget.aelfJson) {
      setState(() {
        localaelfJson = widget.aelfJson;
        parseLiturgy(localaelfJson);
      });
    }
  }

  @override
  initState() {
    loadingState = LoadingState.Loading;

    // init tabs
    _tabController = TabController(
      initialIndex: 0,
      length: 2,
      vsync: this,
    );
    _tabMenuTitles = ['Chargement 1', 'Chargement 2'];
    _tabChildren = [Center(child: Text('1...')), Center(child: Text('2...'))];

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _isAelfJsonChanged();
    switch (loadingState) {
      case LoadingState.Loading:
        return Center(child: CircularProgressIndicator());
      case LoadingState.Loaded:
        return Scaffold(
          body: Column(
            children: [
              Container(
                color: Theme.of(context).primaryColor,
                width: MediaQuery.of(context).size.width,
                child: Center(
                  child: TabBar(
                      indicatorColor: Theme.of(context).tabBarTheme.labelColor,
                      labelColor: Theme.of(context).tabBarTheme.labelColor,
                      unselectedLabelColor:
                          Theme.of(context).tabBarTheme.unselectedLabelColor,
                      labelPadding: EdgeInsets.symmetric(horizontal: 0),
                      isScrollable: true,
                      controller: _tabController,
                      tabs: <Widget>[
                        for (String title in _tabMenuTitles)
                          ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth:
                                    (MediaQuery.of(context).size.width / 3),
                              ),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Tab(text: title),
                              ))
                      ]),
                ),
              ),
              Expanded(
                child: TabBarView(
                    controller: _tabController, children: _tabChildren),
              ),
            ],
          ),
        );
        break;
    }
    return Text('Erreur...');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

enum LoadingState { Loading, Loaded }

String capitalize(String s) {
  if (s == null) {
    return "";
  } else if (s.length <= 1) {
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
  final double fontSize;

  const DisplayContainer(this.title, this.subtitle, this.repeatSubtitle,
      this.intro, this.refIntro, this.ref, this.content, this.fontSize,
      {Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.topLeft,
      child: SingleChildScrollView(
        child: Column(children: <Widget>[
          // title
          GenerateWidgetTitle(title, fontSize),
          // reference
          GenerateWidgetRef(ref, fontSize),
          // subtitle
          GenerateWidgetSubtitle(subtitle, fontSize),
          // intro
          GenerateWidgetContent(intro, fontSize),
          GenerateWidgetRef(refIntro, fontSize),
          // content
          GenerateWidgetContent(content, fontSize),
          // subtitle again for psaumes antiennes
          (repeatSubtitle ? GenerateWidgetSubtitle(subtitle, fontSize) : Row()),
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
  final double fontSize;

  const GenerateWidgetTitle(this.content, this.fontSize, {Key key})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    if (content == "") {
      return Row();
    } else {
      return Row(children: [
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
                  fontSize: this.fontSize + 6),
                )
              },
      ),
          ),
        ),
    ]);
    }
  }
}

class GenerateWidgetRef extends StatelessWidget {
  final String content;
  final double fontSize;

  GenerateWidgetRef(this.content, this.fontSize, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (content == "") {
      return Padding(
        padding: EdgeInsets.only(bottom: 20),
      );
    } else {
      return Padding(
          padding: EdgeInsets.only(right: 15, bottom: 20),
          child: Align(
            alignment: Alignment.topRight,
            child: Text((content != "" ? "- $content" : ""),
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: this.fontSize + 2,
                    color: Theme.of(context).textTheme.bodyText2.color)),
          ));
    }
  }
}

class GenerateWidgetSubtitle extends StatelessWidget {
  final String content;
  final double fontSize;

  const GenerateWidgetSubtitle(this.content, this.fontSize, {Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (content == "") {
      return Row();
    } else { 
        return Row(children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 5),
              child: Html(
                data: content,
                style: {
                  "html": Style.fromTextStyle(
                    TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: this.fontSize + 3,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodyText2.color),
                  ),
                  ".red-text": Style.fromTextStyle(TextStyle(color: Theme.of(context).accentColor))
                },
        ),
            ),
          ),
      ]);
    }
  }
}

class GenerateWidgetContent extends StatelessWidget {
  final String content;
  final double fontSize;

  const GenerateWidgetContent(this.content, this.fontSize, {Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (content == "") {
      return Row();
    } else {
      return Row(children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10, left: 5),
            child: Html(
              data: correctAelfHTML(content),
              style: {
                "html": Style.fromTextStyle(TextStyle(color: Theme.of(context).textTheme.bodyText2.color, fontSize: this.fontSize + 2)),
                ".verse_number": Style.fromTextStyle(
                  TextStyle(
                    height: 1.2,
                    fontSize: this.fontSize,
                    color: Theme.of(context).accentColor)
                  ),
                ".repons": Style.fromTextStyle(TextStyle(
                  height: 5, color: Theme.of(context).accentColor
                  )
                ),
                ".red-text": Style.fromTextStyle(TextStyle(color: Theme.of(context).accentColor)),
                ".spacer": Style.fromTextStyle(
                  TextStyle(fontSize: Theme.of(context).textTheme.bodyText1.fontSize, height: 0.3)
                  )
              }
            ),
          ),
        ),
      ]);
    }
  }
}
