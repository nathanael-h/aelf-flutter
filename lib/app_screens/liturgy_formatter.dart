import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html/dom.dart' as dom;

class LiturgyFormatter {
  // make this a singleton class
  LiturgyFormatter();

  // tab content
  List<Widget> tabMenu = [
    Tab(text: ""),
  ];
  List<Widget> tabChild = <Widget>[Center()];
  // allow conserve mass position to move between all mass with controller
  List<int> _massPos = [];

  TabController tabController;

  // tabController init and set to move between tab, mass,...
  void initTabController(dynamic self) {
    tabController = new TabController(vsync: self, length: this.tabMenu.length);
  }

  // change tab when you select mass
  void setTabController(int index) {
    this.tabController.animateTo(
        this.tabMenu.length >= index && index > 0 ? this._massPos[index] : 0);
  }

  void displayProgressIndicator(self, dynamic context, String liturgyType) {
    setTabController(0);
    this.tabMenu = [generateScreenWidthTab(context, liturgyType)];
    this.tabChild = [Center(child: new CircularProgressIndicator())];
    initTabController(self);
  }

  var aelf_json;
  String liturgyType;
  // save aelf json and liturgy type
  void saveData(var aelf_json, String liturgyType){
    this.aelf_json=aelf_json;
    this.liturgyType = liturgyType;
  }

  void parseLiturgy(
      dynamic self, dynamic context, bool tabControllerInit) {
    String title, text, subtitle, ref, nb;
    // place tab to the first position

    // set tab to first position
    if(tabControllerInit){
      setTabController(0);
    }

    // reset tabs
    this.tabMenu = [];
    this.tabChild = [];
    this._massPos = [];


    if (liturgyType == "messes") {
      for (int e = 0; e < aelf_json.length; e++) {
        if (aelf_json.length > 1) {
          // display the different mass if there are several
          List<Widget> list = new List<Widget>();
          for (int i = 0; i < aelf_json.length; i++) {
            list.add(new GestureDetector(
                onTap: () {
                  // move to tab when select mass in liturgy screen context
                  setTabController(i);
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
          this._massPos.add(this.tabMenu.length);
          this.tabMenu.add(Tab(text: "Messes"));
          this.tabChild.add(SingleChildScrollView(
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
                this.tabMenu.add(Tab(text: "Séquence"));
                this.tabChild.add(displayContainer(context, 
                    "Séquence", "", false, "", "", "", el["contenu"]));
              }
              break;
            case 'entree_messianique':
              {
                this.tabMenu.add(Tab(text: "Entrée messianique"));
                this.tabChild.add(displayContainer(context, "Entrée messianique",
                    el["intro_lue"], false, "", "", ref, el["contenu"]));
              }
              break;
            case 'psaume':
              {
                this.tabMenu.add(Tab(text: "Psaume"));
                this.tabChild.add(displayContainer(context, 
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
                this.tabMenu.add(Tab(text: "Cantique"));
                this.tabChild.add(displayContainer(context, 
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
                this.tabMenu.add(Tab(text: "Évangile"));
                this.tabChild.add(displayContainer(context, 
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
                  this.tabMenu.add(Tab(text: title));
                  this.tabChild.add(displayContainer(context, el["titre"],
                      el["intro_lue"], false, "", "", ref, el["contenu"]));
                }
              }
              break;
          }
        }
      }
    } else if (liturgyType == "informations") {
      // generate sentence
      text = "${capitalize(aelf_json["jour"])} ${aelf_json["fete"]}" +
          (aelf_json.containsKey("semaine") ? ", ${aelf_json["semaine"]}." : ".") +
          (aelf_json.containsKey("couleur")
              ? " La couleur liturgique est le ${aelf_json["couleur"]}."
              : "");
      // display screen
      this.tabMenu.add(generateScreenWidthTab(context, "Informations"));
      this.tabChild.add(Container(
            padding: EdgeInsets.symmetric(vertical: 100, horizontal: 25),
            child: Text(text,
                textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
          ));
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
                this.tabMenu.add(Tab(text: "Introduction"));
                this.tabChild.add(
                    displayContainer(context, "Introduction", "", false, "", "", "", v));
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

                this.tabMenu.add(Tab(text: "Antienne invitatoire"));
                this.tabChild.add(displayContainer(context, 
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
                this.tabMenu.add(Tab(text: "Hymne"));
                this.tabChild.add(displayContainer(context, 
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

                this.tabMenu.add(Tab(text: v["titre"]));
                this.tabChild.add(displayContainer(context, 
                    v["titre"], subtitle, true, "", "", ref, v["texte"]));
              }
              break;
            case 'pericope':
              {
                this.tabMenu.add(Tab(text: "Parole de Dieu"));
                this.tabChild.add(displayContainer(context, 
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
                this.tabMenu.add(Tab(text: "Lecture"));
                this.tabChild.add(displayContainer(context, 
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
                this.tabMenu.add(Tab(text: v["titre"]));
                this.tabChild.add(displayContainer(context, 
                    v["titre"], "", false, "", "", ref, v["texte"]));
              }
              break;
            case 'texte_patristique':
              {
                this.tabMenu.add(Tab(text: "Lecture patristique"));
                this.tabChild.add(displayContainer(context, 
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
                this.tabMenu.add(Tab(text: "Intercession"));
                this.tabChild.add(displayContainer(context, 
                    "Intercession", "", false, "", "", ref, v));
              }
              break;
            case 'notre_pere':
              {
                this.tabMenu.add(Tab(text: "Notre Père"));
                this.tabChild.add(displayContainer(context, 
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
                text =
                    "$v <p class=\"spacer\"><br></p>Que le seigneur nous bénisse, qu'il nous garde de tout mal, et nous conduise à la vie éternelle.<br>Amen.";
                this.tabMenu.add(Tab(text: "Oraison"));
                this.tabChild.add(
                    displayContainer(context, "Oraison", "", false, "", "", ref, text));
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
                            this.addAntienneBefore(aelf_json["antienne_" + nb]);
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

                  this.tabMenu.add(Tab(text: title));
                  this.tabChild.add(displayContainer(context, 
                      title, subtitle, true, "", "", ref, text));
                }
              }
              break;
          }
        }
      });
    }
    // reset tab controller and his index
    if(tabControllerInit){
      initTabController(self);
    }
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

  // function to display all element in tab view
  dynamic displayContainer(dynamic context, String title, String subtitle, bool repeatSubtitle,
      String intro, String refIntro, String ref, String content) {
    return Container(
      alignment: Alignment.topLeft,
      child: SingleChildScrollView(
        child: Column(children: <Widget>[
          // title
          _generateWidgetTitle(context, title),
          // reference
          _generateWidgetRef(context, ref),
          // subtitle
          _generateWidgetSubtitle(context, subtitle),
          // intro
          _generateWidgetContent(context, intro),
          _generateWidgetRef(context, refIntro),
          // content
          _generateWidgetContent(context, content),
          // subtitle again for psaumes antiennes
          (repeatSubtitle ? _generateWidgetSubtitle(context, subtitle) : Row()),
          // add bottom padding
          Padding(
            padding: EdgeInsets.only(bottom: 150),
          ),
        ]),
      ),
    );
  }

  Widget generateScreenWidthTab(dynamic context, String title) {
    // get screen width and remove it tab paddings
    double screenWidth = MediaQuery.of(context).size.width;
    screenWidth = screenWidth - screenWidth * 0.2;
    return new Container(
      width: screenWidth,
      child: new Tab(text: title),
    );
  }

  // display this message when aelf return not found status
  void displayMessage(
      dynamic self, dynamic context, String liturgyType, String content) {
    // place tab to the first position
    setTabController(0);
    this.tabMenu = [generateScreenWidthTab(context, liturgyType)];
    this.tabChild = <Widget>[
      Center(
        child: Text(content),
      )
    ];
    // reset tab controller
    initTabController(self);
  }

  // Functions to generate all content widgets

  Widget _generateWidgetTitle(dynamic context, String content) {
    if (content == "") {
      return Row();
    }
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

  Widget _generateWidgetRef(dynamic context, String content) {
    if (content == "") {
      return Padding(
        padding: EdgeInsets.only(bottom: 20),
      );
    }
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
        ));
  }

  Widget _generateWidgetSubtitle(dynamic context, String content) {
    if (content == "") {
      return Row();
    }
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

  Widget _generateWidgetContent(dynamic context, String content) {
    if (content == "") {
      return Row();
    }
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
