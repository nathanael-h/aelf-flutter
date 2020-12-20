import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html/dom.dart' as dom;


class LiturgyFormatter extends StatefulWidget {
  LiturgyFormatter(this.aelfJson, this._liturgyType);

  final aelfJson;
  final String _liturgyType;
  final String rawJson = '{"name":"Mary","age":30}';

  @override
  _LiturgyFormatterState createState() => _LiturgyFormatterState();
}

class _LiturgyFormatterState extends State<LiturgyFormatter> 
  with TickerProviderStateMixin {
  
  Map<String, dynamic> decodedAelfJson;
  var localaelfJson;
  var parsedAelfJson;
  TabController _tabController;
  LoadingState loadingState = LoadingState.Loading;

  

  List<int> _massPos = [];
  List<String> _tabMenuTitles;
  List<Widget> _tabChildren;
  int _length;

  void parseLiturgy(var aelf_json) {
    String title, text, subtitle, ref, nb;
    List<String> _newTabTitles = [];
    List<Widget> _newTabChildren = [];
    int _newLength = 0;

    setState(() {
      loadingState = LoadingState.Loading;
    });

    if (widget._liturgyType == "messes") {
      for (int e = 0; e < aelf_json.length; e++) {
        if (aelf_json.length > 1) {
          // display the different mass if there are several
          List<Widget> list = new List<Widget>();
          for (int i = 0; i < aelf_json.length; i++) {
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
                    border: Border.all(color: Theme.of(context).accentColor),
                    color: (i == e ? Theme.of(context).accentColor : null),
                  ),
                  child: Text(aelf_json[i]["nom"],
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
        for (int i = 0; i < aelf_json[e]["lectures"].length; i++) {
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
          Map el = aelf_json[e]["lectures"][i];
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
      text = "${capitalize(aelf_json["jour"])} ${aelf_json["fete"]}" +
          (aelf_json.containsKey("semaine") ? ", ${aelf_json["semaine"]}." : ".") +
          (aelf_json.containsKey("couleur")
              ? " La couleur liturgique est le ${aelf_json["couleur"]}."
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
      aelf_json.forEach((k, v) {
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
                subtitle = aelf_json.containsKey("antienne_invitatoire")
                    ? aelf_json["antienne_invitatoire"]
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
                subtitle = aelf_json.containsKey("antienne_magnificat")
                    ? aelf_json["antienne_magnificat"]
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
                        aelf_json["repons"]));
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
                        aelf_json["repons_lecture"]));
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
                    "« " + capitalize(aelf_json["titre_patristique"]) + " »",
                    "",
                    false,
                    "",
                    "",
                    ref,
                    v +
                        '<p class="repons">Répons</p>' +
                        aelf_json["repons_patristique"]));
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
                _newTabTitles.add("Oraison");
                _newTabChildren.add(
                    DisplayContainer("Oraison", "", false, "", "", ref, text));
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
                  subtitle = aelf_json.containsKey("antienne_" + nb)
                      ? aelf_json["antienne_" + nb]
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
                      if (aelf_json.containsKey("antienne_" + nb) &&
                          aelf_json["antienne_" + nb] != "") {
                        subtitle =
                            addAntienneBefore(aelf_json["antienne_" + nb]);
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
      });
      setState(() {
        _length = _newTabChildren.length; //int
        _tabController = TabController(vsync: this, length: _newTabChildren.length);
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
    _tabChildren = [Center(child: Text('1...')),Center(child: Text('2...'))];
    
    super.initState();
  }
  
  
  @override
  Widget build(BuildContext context) {
    _isAelfJsonChanged();
    switch (loadingState) {
      case LoadingState.Loading:
        return 
        Center(child: CircularProgressIndicator());
      case LoadingState.Loaded:
        return
        Scaffold(
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
                      for(String title in _tabMenuTitles) Container(
                          width: MediaQuery.of(context).size.width / 3,
                          child: Tab(text: title),
                        )
                    ]
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: _tabChildren
                ),
              ),
            ],
          ),
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
  if (content != "") {
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
      return Row(children: [
        Html(
          data: content,
          padding: EdgeInsets.only(top: 25, bottom: 5, left: 15, right: 15),
          defaultTextStyle: TextStyle(
              color: Theme.of(context).textTheme.bodyText2.color,
            fontWeight: FontWeight.w900,
            fontSize: 20),
      ),
    ]);
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
      return Padding(
        padding: EdgeInsets.only(right: 15, bottom: 20),
        child: Align(
          alignment: Alignment.topRight,
          child: Text((content != "" ? "- $content" : ""),
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyText2.color)),
        )
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
        return Row(children: [
          Html(
            data: content,
            padding: EdgeInsets.only(top: 0, bottom: 0, left: 15, right: 15),
            defaultTextStyle: TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodyText2.color),
          customTextStyle: (dom.Node node, TextStyle baseStyle) {
            if (node is dom.Element) {
              switch (node.className) {
                case "red-text":
                  return baseStyle
                      .merge(TextStyle(color: Theme.of(context).accentColor));
              }
            }
            return baseStyle;
          },
        ),
      ]);
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
      return Row(children: [
        Html(
          data: correctAelfHTML(content),
          padding: EdgeInsets.symmetric(vertical: 20, horizontal: 15),
          defaultTextStyle:
              TextStyle(color: Theme.of(context).textTheme.bodyText2.color, fontSize: 16),
          customTextStyle: (dom.Node node, TextStyle baseStyle) {
            if (node is dom.Element) {
              switch (node.className) {
                case "verse_number":
                  return baseStyle.merge(TextStyle(
                      height: 1.2,
                      fontSize: 14,
                      color: Theme.of(context).accentColor));
                  break;
                case "repons":
                  return baseStyle.merge(TextStyle(
                      height: 5, color: Theme.of(context).accentColor));
                  break;
                case "red-text":
                  return baseStyle
                      .merge(TextStyle(color: Theme.of(context).accentColor));
                  break;
                case "spacer":
                  return baseStyle.merge(TextStyle(height: 2));
                  break;
              }
            }
            return baseStyle;
          },
        ),
      ]);
    }
  }
}
