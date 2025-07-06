import 'dart:developer';
import 'package:aelf_flutter/app_screens/book_screen.dart';
import 'package:aelf_flutter/parse_chapter.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/theme_provider.dart';
import 'package:aelf_flutter/widgets/bible_verse_id.dart';
import 'package:aelf_flutter/widgets/liturgy_content.dart';
import 'package:aelf_flutter/widgets/liturgy_tabs_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';

class LiturgyFormatter extends StatefulWidget {
  @override
  LiturgyFormatterState createState() => LiturgyFormatterState();
}

class LiturgyFormatterState extends State<LiturgyFormatter>
    with TickerProviderStateMixin {
  TabController? _tabController;
  final List<int> _massPos = [];
  List<String?>? _tabMenuTitles;
  List<Widget>? _tabChildren;
  late int _length;
  int fooBar = 0;

  int getCurrentIndex() {
    if (_tabController != null) {
      return _tabController!.index;
    } else {
      return 0;
    }
  }

  Map<String, dynamic> loadingLiturgy() {
    _tabController =
        TabController(vsync: this, length: 1, initialIndex: getCurrentIndex());
    return {
      '_tabMenuTitles': ['Chargement'],
      '_tabChildren': [Center(child: CircularProgressIndicator())],
      '_tabController': _tabController
    };
  }

  Map<String, dynamic> parseLiturgy(Map? aelfJson) {
    String? title, subtitle, ref, nb;
    String text = "";
    List<String?> _newTabTitles = [];
    List<Widget> _newTabChildren = [];
    int _newLength = 0;

    if (aelfJson is Map && aelfJson.containsKey("erreur")) {
      print("aelf_json contains key erreur");
      _tabMenuTitles = ["Erreur"];
      _tabChildren = [
        DisplayContainer("Erreur", "", false, "", "", "", aelfJson["erreur"])
      ];
      _tabController = TabController(
          vsync: this, length: 1, initialIndex: getCurrentIndex());
      return {
        '_tabMenuTitles': _tabMenuTitles,
        '_tabChildren': _tabChildren,
        '_tabController': _tabController
      };
    } else if (aelfJson!.containsKey("messes")) {
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
            list.add(GestureDetector(
                onTap: () {
                  // move to tab when select mass in liturgy screen context
                  _tabController!.animateTo(
                      (_newTabTitles.length >= i && i > 0) ? _massPos[i] : 0);
                },
                child: Container(
                  margin: EdgeInsets.all(30.0),
                  padding: EdgeInsets.all(10.0),
                  alignment: Alignment.topCenter,
                  width: MediaQuery.of(context).size.width - 40,
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Theme.of(context).colorScheme.secondary),
                    color: (i == e
                        ? Theme.of(context).colorScheme.secondary
                        : null),
                  ),
                  child: Text(aelfJson["messes"][i]["nom"],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: (i == e
                              ? Theme.of(context).scaffoldBackgroundColor
                              : Theme.of(context).textTheme.bodyMedium!.color),
                          fontSize: 20)),
                )));
          }
          // add mass menu
          _massPos.add(_newTabTitles.length);
          _newTabTitles.add("Messes");
          _newTabChildren.add(SingleChildScrollView(
            child: Center(
              child: Container(
                width: 600,
                padding: EdgeInsets.only(top: 100),
                alignment: Alignment.center,
                child: Column(children: list),
              ),
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
                if (!(ref!.contains("Ps"))) {
                  ref = "Ps $ref";
                }
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
            case 'epitre':
              {
                _newTabTitles.add("Épitre");
                _newTabChildren.add(DisplayContainer(el["titre"],
                    el["intro_lue"], false, "", "", ref, el["contenu"]));
              }
              break;
            default:
              {
                if (el["type"].contains("lecture_")) {
                  nb = el["type"].split('_')[1];
                  title = index.length >= int.parse(nb!)
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
      _tabController = TabController(
          vsync: this,
          length: _length,
          initialIndex: getCurrentIndex() > _length ? 0 : getCurrentIndex());
      _tabMenuTitles = _newTabTitles; // List<Widget>
      _tabChildren = _newTabChildren; // List<Widget>
      return {
        '_tabMenuTitles': _tabMenuTitles,
        '_tabChildren': _tabChildren,
        '_tabController': _tabController
      };
    } else if (aelfJson.containsKey("informations")) {
      //set lenght
      _newLength = 1;

      // Parts for new informations panel
      String newInfoTitle =
          capitalizeFirstLowerElse(aelfJson["informations"]["liturgical_day"]);
      RomanizePsalterWeek(int psalterWeek) {
        switch (psalterWeek) {
          case 1:
            {
              return "I";
            }
          case 2:
            {
              return "II";
            }
          case 3:
            {
              return "III";
            }
          case 4:
            {
              return "IV";
            }
          default:
            {
              return "";
            }
        }
      }

      String newInfoSubtitle = aelfJson["informations"]["psalter_week"] == null
          ? ""
          : "Année ${aelfJson["informations"]["liturgical_year"]} - Semaine ${RomanizePsalterWeek(aelfJson["informations"]["psalter_week"])}";
      text += "$newInfoTitle \n$newInfoSubtitle" + "\n --- \n";
      for (int i = 0;
          i < aelfJson["informations"]["liturgy_options"].length;
          i++) {
        // ignore: prefer_interpolation_to_compose_strings
        text += "Couleur liturgique : " +
            aelfJson["informations"]["liturgy_options"][i]["liturgical_color"] +
            "\n";
        text +=
            "${capitalizeFirst(aelfJson["informations"]["liturgy_options"][i]["liturgical_name"])}\n";
        text += aelfJson["informations"]["liturgy_options"][i]
                ["liturgical_degree"] +
            "\n --- \n";
      }
      // display screen
      _newTabTitles.add("Informations");
      _newTabChildren.add(Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: 600,
          padding: EdgeInsets.symmetric(vertical: 100, horizontal: 25),
          child: Consumer<CurrentZoom>(
            builder: (context, currentZoom, child) => Text(text,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18 * currentZoom.value! / 100)),
          ),
        ),
      ));

      _length = _newLength; //int
      _tabController = TabController(
          vsync: this, length: _length, initialIndex: getCurrentIndex());
      _tabMenuTitles = _newTabTitles; // List<Widget>
      _tabChildren = _newTabChildren; // List<Widget>
      return {
        '_tabMenuTitles': _tabMenuTitles,
        '_tabChildren': _tabChildren,
        '_tabController': _tabController
      };
    } else {
      // for each element in others types -> add to new tabs (key -type of element, value - content)
      var office = aelfJson.keys.first;
      print("office type is : ${office.runtimeType}");
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
                  _newTabChildren.add(DisplayContainer(
                      "Introduction", "", false, "", "", "", v));
                }
                break;
              case 'psaume_invitatoire':
                {
                  // define subtitle with antienne before and remove html text tags
                  subtitle =
                      aelfJson[office].containsKey("antienne_invitatoire")
                          ? aelfJson[office]["antienne_invitatoire"]
                          : "";
                  // add antienne before subtitle
                  subtitle = addAntienneBefore(subtitle);
                  text = v["texte"].replaceAll(RegExp(r'</p>$'),
                      '<span class="verse_number"></span><br /><br />Gloire au Père,...');
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
                          // ignore: prefer_interpolation_to_compose_strings
                          '<p class="repons">Répons</p>' +
                          aelfJson[office]["repons"]));
                }
                break;
              case 'lecture':
                {
                  _newTabTitles.add("Lecture");
                  _newTabChildren.add(DisplayContainer(
                      "« ${capitalizeFirstLowerElse(v["titre"])} »",
                      "",
                      false,
                      "",
                      "",
                      ref,
                      v["texte"] +
                          // ignore: prefer_interpolation_to_compose_strings
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
                      "« ${capitalizeFirstLowerElse(aelfJson[office]["titre_patristique"])} »",
                      "",
                      false,
                      "",
                      "",
                      ref,
                      v +
                          // ignore: prefer_interpolation_to_compose_strings
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
                  text = v +
                      "<p class=\"spacer\"><br></p>Que le seigneur nous bénisse, qu'il nous garde de tout mal, et nous conduise à la vie éternelle.<br>Amen.";
                  _newTabTitles.add("Oraison et bénédiction");
                  _newTabChildren.add(DisplayContainer(
                      "Oraison et bénédiction", "", false, "", "", ref, text));
                }
                break;
              case 'hymne_mariale':
                {
                  _newTabTitles.add(v["titre"]);
                  _newTabChildren.add(DisplayContainer(
                      v["titre"], "", false, "", "", "", v["texte"]));
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
                        // ignore: prefer_interpolation_to_compose_strings
                        ? "Psaume " + v["reference"]
                        : v["titre"];
                    subtitle = aelfJson[office].containsKey("antienne_${nb!}")
                        ? aelfJson[office]["antienne_${nb!}"]
                        : "";

                    // add antienne before subtitle
                    subtitle = addAntienneBefore(subtitle);
                    // if no antienne and psaume is splited, get previous antienne
                    RegExp regExp = RegExp(
                      r"- (I|V)",
                      caseSensitive: false,
                      multiLine: false,
                    );
                    if (subtitle == "" && regExp.hasMatch(title!)) {
                      for (int i = int.parse(nb!) - 1; i > 0; i--) {
                        // foreach previous antiennes
                        nb = i.toString();
                        if (aelfJson[office].containsKey("antienne_${nb!}") &&
                            aelfJson[office]["antienne_${nb!}"] != "") {
                          subtitle = addAntienneBefore(
                              aelfJson[office]["antienne_${nb!}"]);
                          break;
                        }
                      }
                    }

                    // parse name of cantique when it is with psaume id and transform his name form
                    if (k.contains("psaume_") &&
                        v["reference"].toLowerCase().contains("cantique")) {
                      List<String> t = ref!.split("(");
                      if (t.isNotEmpty) {
                        title = capitalizeFirstLowerElse(t[0]);
                      }
                      // get cantique reference
                      if (t.length > 1) {
                        RegExp exp =
                            RegExp(r"(\(|\).|\))", caseSensitive: false);
                        ref = t[1].replaceAll(exp, "");
                      }
                    } else if (k.contains("psaume_")) {
                      // add ps before psaume reference
                      ref = ref != "" ? "Ps $ref" : "";
                    }
                    text = v["texte"].replaceAll(RegExp(r'</p>$'),
                        '<span class="verse_number"></span><br /><br />Gloire au Père,...');
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
      _tabController = TabController(
          vsync: this,
          length: _newTabChildren.length,
          initialIndex: getCurrentIndex());
      _tabMenuTitles = _newTabTitles; // List<Widget>
      _tabChildren = _newTabChildren; // List<Widget>
      return {
        '_tabMenuTitles': _tabMenuTitles,
        '_tabChildren': _tabChildren,
        '_tabController': _tabController
      };
    }
  }

  @override
  initState() {
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
    print("build LiturgyFormatter prout");
    print("fooBar = $fooBar");
    fooBar += 1;

    return Consumer<LiturgyState>(
      builder: (context, liturgyState, child) {
        if (liturgyState.aelfJson == null) {
          return Scaffold(
            body: LiturgyTabsView(tabsMap: loadingLiturgy()),
          );
        } else {
          print(
              "showing LiturgyTabsView: ${liturgyState.date} ${liturgyState.liturgyType.toString()} ${liturgyState.region}");
          return Scaffold(
            body: LiturgyTabsView(tabsMap: parseLiturgy(liturgyState.aelfJson)),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _tabController!.dispose();
    log("_tabController disposed");
    super.dispose();
  }
}

String capitalizeFirstLowerElse(String? s) {
  if (s == null) {
    return "";
  } else if (s.isEmpty) {
    return "";
  } else {
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }
}

String capitalizeFirst(String? s) {
  if (s == null) {
    return "";
  } else if (s.isEmpty) {
    return "";
  } else {
    return s[0].toUpperCase() + s.substring(1);
  }
}

String correctAelfHTML(String content) {
  // transform text elements for better displaying and change their color
  return content
      .replaceAll('V/ <p>', '<p>℣ ')
      .replaceAll('R/ <p>', '<p>℟ ')
      .replaceAll('V/', '<span class="red-text">℣</span>')
      .replaceAll('R/', '<span class="red-text">℟</span>')
      .replaceFirst(RegExp('^`?<span|^"?<span'), '<p><span');
}

String removeAllHtmlTags(String htmlText) {
  RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
  return htmlText.replaceAll(exp, '');
}

String addAntienneBefore(String? content) {
  if (content != "" && content != null) {
    return '<span class="red-text">Antienne : </span>${removeAllHtmlTags(content)}';
  }
  return "";
}

// widget to display all element in tab view
class DisplayContainer extends StatelessWidget {
  final String? title, subtitle, intro, refIntro, ref, content;
  final bool repeatSubtitle;

  const DisplayContainer(this.title, this.subtitle, this.repeatSubtitle,
      this.intro, this.refIntro, this.ref, this.content,
      {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: 600,
        alignment: Alignment.topLeft,
        child: SingleChildScrollView(
          child: Column(children: <Widget>[
            // title
            GenerateWidgetTitle(title),
            // intro
            GenerateWidgetIntro(intro),
            GenerateWidgetRefIntro(refIntro),
            // subtitle
            GenerateWidgetSubtitle(subtitle),
            // reference
            GenerateWidgetRef(ref),
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
      ),
    );
  }
}

class GenerateWidgetTitle extends StatelessWidget {
  final String? content;

  const GenerateWidgetTitle(this.content, {Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    if (content == "" || content == null) {
      return Row();
    } else {
      return Consumer<CurrentZoom>(
        builder: (context, currentZoom, child) => Row(children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 25, bottom: 5),
              child: Row(
                children: [
                  verseIdPlaceholder(),
                  Expanded(
                    child: Html(
                      data: content,
                      style: {
                        "html": Style.fromTextStyle(
                          TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyMedium!.color,
                              fontWeight: FontWeight.w900,
                              fontSize: 20 * currentZoom.value! / 100),
                        ),
                        "body": Style(
                            margin: Margins.zero, padding: HtmlPaddings.zero),
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]),
      );
    }
  }
}

class GenerateWidgetRef extends StatelessWidget {
  final String? content;

  GenerateWidgetRef(this.content, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (content == "" || content == null) {
      return Padding(
        padding: EdgeInsets.only(bottom: 20),
      );
    } else {
      return Consumer<CurrentZoom>(
        builder: (context, currentZoom, child) => Padding(
            padding: EdgeInsets.only(right: 15, bottom: 20),
            child: Align(
              alignment: Alignment.topRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: context.read<ThemeNotifier>().darkTheme!
                        ? Color.fromARGB(255, 38, 41, 49)
                        : Color.fromARGB(255, 240, 229, 210)),
                onPressed: () => refButtonPressed(content ?? "", context),
                child: Text((content != "" ? "- $content" : ""),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 16 * currentZoom.value! / 100,
                        color: Theme.of(context).textTheme.bodyMedium!.color)),
              ),
            )),
      );
    }
  }
}

class GenerateWidgetRefIntro extends StatelessWidget {
  final String? content;

  GenerateWidgetRefIntro(this.content, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (content == "" || content == null) {
      return Padding(
        padding: EdgeInsets.only(bottom: 20),
      );
    } else {
      return Consumer<CurrentZoom>(
        builder: (context, currentZoom, child) => Padding(
            padding: EdgeInsets.only(right: 25, bottom: 20),
            child: Align(
              alignment: Alignment.topRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: context.read<ThemeNotifier>().darkTheme!
                        ? Color.fromARGB(255, 38, 41, 49)
                        : Color.fromARGB(255, 240, 229, 210)),
                onPressed: () => refButtonPressed(content ?? "", context),
                child: Text((content != "" ? "- $content" : ""),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 14 * currentZoom.value! / 100,
                        color: Theme.of(context).textTheme.bodyMedium!.color)),
              ),
            )),
      );
    }
  }
}

class GenerateWidgetSubtitle extends StatelessWidget {
  final String? content;

  const GenerateWidgetSubtitle(this.content, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (content == "" || content == null) {
      return Row();
    } else {
      return Consumer<CurrentZoom>(
        builder: (context, currentZoom, child) => Row(children: [
          Expanded(
            child: Row(
              children: [
                verseIdPlaceholder(),
                Expanded(
                  child: Html(
                    data: content,
                    style: {
                      "html": Style.fromTextStyle(
                        TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 16 * currentZoom.value! / 100,
                            fontWeight: FontWeight.w500,
                            color:
                                Theme.of(context).textTheme.bodyMedium!.color),
                      ),
                      ".red-text": Style.fromTextStyle(TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontSize: 14 * currentZoom.value! / 100)),
                      "body": Style(
                          margin: Margins.zero, padding: HtmlPaddings.zero),
                    },
                  ),
                ),
              ],
            ),
          ),
        ]),
      );
    }
  }
}

class GenerateWidgetContent extends StatelessWidget {
  final String? content;
  static const double bottomMarginFactor = 3.0;

  const GenerateWidgetContent(this.content, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (content == "" || content == null) {
      return Row();
    } else {
      return Consumer<CurrentZoom>(
        builder: (context, currentZoom, child) => Row(children: [
          Expanded(
            child: Padding(
                padding: const EdgeInsets.only(bottom: 10, left: 0, right: 15),
                // child: Html(data: correctAelfHTML(content!), style: {
                // child: Row(
                //   children: [
                //     Text(extractVerses(content!).entries.first.key.toString()),
                //     Html(
                //         data: extractVerses(content!).entries.first.value,
                //         style: {
                //           "html": Style.fromTextStyle(TextStyle(
                //               color:
                //                   Theme.of(context).textTheme.bodyMedium!.color,
                //               fontSize: 16 * currentZoom.value! / 100)),
                //           ".verse_number": Style.fromTextStyle(TextStyle(
                //               height: 1.2,
                //               fontSize: 14 * currentZoom.value! / 100,
                //               color: Theme.of(context).colorScheme.secondary)),
                //           ".repons": Style.fromTextStyle(TextStyle(
                //               height: 5,
                //               color: Theme.of(context).colorScheme.secondary,
                //               fontSize: 14 * currentZoom.value! / 100)),
                //           ".red-text": Style.fromTextStyle(TextStyle(
                //               color: Theme.of(context).colorScheme.secondary)),
                //           ".spacer": Style.fromTextStyle(TextStyle(
                //               fontSize: 14 * currentZoom.value! / 100,
                //               height: 0.3 * currentZoom.value! / 100))
                //         }),
                //   ],
                // ),

                // Replace the invalid code with the following:
                // child: Column(
                //   children: extractVerses(correctAelfHTML(content!))
                //       .entries
                //       .map((entry) {
                //     print(" abc $entry");
                //     return Text('Verse ${entry.key}: ${entry.value}');
                //   }).toList(),
                // ),

                child: Column(
                  children: extractVerses(correctAelfHTML(content!))
                      .entries
                      .map((entry) {
                    return Container(
                      child: Row(
                        children: [
                          // Align(
                          //   alignment: Alignment.topLeft,
                          //   child: Text(
                          //     entry.key.toString(),
                          //     style: TextStyle(
                          //         height: 1.2,
                          //         fontSize: 14 * currentZoom.value! / 100,
                          //         color: Theme.of(context)
                          //             .colorScheme
                          //             .secondary),
                          //   ),
                          // ),
                          BibleVerseId(
                              id: entry.key,
                              fontSize:
                                  verseFontSize * currentZoom.value! / 100),
                          // BibleVerseId width is 5 + (16 * currentZoom)
                          Expanded(
                            child: Html(
                              data: entry.value,
                              style: {
                                "html": Style.fromTextStyle(TextStyle(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .color,
                                  fontSize: 16 * currentZoom.value! / 100,
                                )),
                                ".verse_number": Style.fromTextStyle(TextStyle(
                                    height: 1.2,
                                    fontSize: verseFontSize *
                                        verseIdFontSizeFactor *
                                        currentZoom.value! /
                                        100,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary)),
                                ".repons": Style.fromTextStyle(TextStyle(
                                    height: 5,
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                    fontSize: 14 * currentZoom.value! / 100)),
                                ".red-text": Style.fromTextStyle(TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                    fontSize: 14 * currentZoom.value! / 100)),
                                "body": Style(
                                    margin: Margins.zero,
                                    padding: HtmlPaddings.zero),
                              },
                            ),
                          ),
                        ],
                        // Align content (verse id & verse text) to the top
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                      ),
                      // Mark verse delimitation
                      margin: EdgeInsets.only(
                        bottom:
                            16 * currentZoom.value! / 100 / bottomMarginFactor,
                      ),
                    );
                  }).toList(),
                )),
          ),
        ]),
      );
    }
  }
}

class GenerateWidgetIntro extends StatelessWidget {
  final String? content;

  const GenerateWidgetIntro(this.content, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (content == "" || content == null) {
      return Row();
    } else {
      return Consumer<CurrentZoom>(
        builder: (context, currentZoom, child) => Row(children: [
          verseIdPlaceholder(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 45),
              child: Html(data: correctAelfHTML(content!), style: {
                "html": Style.fromTextStyle(TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium!.color,
                    fontSize: 14 * currentZoom.value! / 100)),
                ".verse_number": Style.fromTextStyle(TextStyle(
                    height: 1.2,
                    fontSize: 12 * currentZoom.value! / 100,
                    color: Theme.of(context).colorScheme.secondary)),
                ".repons": Style.fromTextStyle(TextStyle(
                    height: 5,
                    color: Theme.of(context).colorScheme.secondary,
                    fontSize: 12 * currentZoom.value! / 100)),
                ".red-text": Style.fromTextStyle(
                    TextStyle(color: Theme.of(context).colorScheme.secondary)),
                ".spacer": Style.fromTextStyle(TextStyle(
                    fontSize: 12 * currentZoom.value! / 100,
                    height: 0.3 * currentZoom.value! / 100)),
                "body": Style(margin: Margins.zero, padding: HtmlPaddings.zero),
              }),
            ),
          ),
        ]),
      );
    }
  }
}

void refButtonPressed(String references_element, BuildContext context) {
  print("references_element : $references_element");

  // The following part is derived from
  // https://github.com/HackMyChurch/aelf-dailyreadings/blob/5d59e8d7e5a7077b916971615e9c52013ebf8077/app/src/main/assets/js/lecture.js
  // which is available under the MIT licence
  // So we can use it in this AGPL open course project, but not change the licence
  // Thus here begins a MIT code block

  //   ----------------------
  // | Start of the MIT code |
  //   ----------------------

  // Extract reference-ish from a larger string
  // This allows surviving references like "Stabat Mater. Jn 19, 25-27"
  RegExp reference_extractor = RegExp(
      r'^(?<prefix>.*?)(?<reference>(?:[1-3]\s*)?[a-zA-Z]+\w*\s*[0-9]+(?:\s*\([0-9]+\))?(?:,(?:[-\s,.]|(?:[0-9]+[a-z]*))*[a-z0-9]\b)?)(?<suffix>.*?)$');

  // Extract reference
  //var reference_full_string = references_element.textContent.slice(1);
  String reference_full_string = references_element;
  Iterable<RegExpMatch> reference_parts =
      reference_extractor.allMatches(reference_full_string);
  if (reference_parts.isEmpty) {
    print("reference_parts is empty");
    return null;
  }

  // Extract reference components
  // ignore: unused_local_variable
  String reference_prefix = reference_parts.first[1] ?? "";
  String reference_text = reference_parts.first[2] ?? "";
  // ignore: unused_local_variable
  String reference_suffix = reference_parts.first[3] ?? "";

  // Prepare link
  String reference = reference_text;

  // Extract "Cantiques" references
  if (RegExp(r'^CANTIQUE').hasMatch(reference)) {
    reference = reference.split('(')[1].split(')')[0];
  }

  // Clean extracted reference
  reference = reference.toLowerCase();
  // Remove all type of whitespaces
  reference = reference.replaceAll(RegExp(r'\s*'), "");
  // Remove some stuffs around parentethis
  reference = reference.replaceAll(RegExp(r'\([0-9]*[A-Z]?\)'), "");

  // Do we still have something to parse ?
  if (reference == "") {
    return null;
  }

  // Extract the main reference chunks
  var matches = RegExp(r'([0-9]?)([a-z]+)([0-9]*[a-b]*)(,?)(.*?)(?:-[iv]+)*$')
      .allMatches(reference);
  if (matches.isEmpty) {
    return null;
  }

  String book_number = matches.first[1] ?? "";
  String book_name = capitalizeFirstLowerElse(matches.first[2]);
  String chapter = matches.first[3] ?? "";
  String comma = matches.first[4] ?? "";
  String rest = matches.first[5] ?? "";

  // Build the link
  String verses = chapter.toUpperCase() + comma + rest;
  print("verses = $verses");
  String link =
      "https://www.aelf.org/bible/$book_number$book_name/$chapter?reference=$verses";
  print("link = $link");

  //   -- -----------------
  // | End of the MIT code |
  //   -------------------

  Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExtractArgumentsScreen(
            bookNameShort: book_number + book_name,
            bookChToOpen: chapter,
            keywords: [""],
            reference: parse_reference(verses)),
      ));
}

// This widget is used when no verse ID is expected, to shift the following
// widget(s) and to have it aligned with the content of verses.
class verseIdPlaceholder extends StatelessWidget {
  const verseIdPlaceholder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrentZoom>(builder: (context, currentZoom, child) {
      double verseIdPlaceholderWidth =
          5 + 1 + (verseFontSize * currentZoom.value! / 100);

      return Container(width: verseIdPlaceholderWidth);
    });
  }
}

const double verseFontSize = 16;
