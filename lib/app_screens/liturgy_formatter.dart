import 'dart:developer';
import 'package:aelf_flutter/app_screens/book_screen.dart';
import 'package:aelf_flutter/utils/parse_chapter.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/widgets/liturgy_part_column.dart';
import 'package:aelf_flutter/widgets/liturgy_tabs_view.dart';
import 'package:flutter/material.dart';
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
        LiturgyPartColumn(
          title: "Erreur",
          subtitle: "",
          repeatSubtitle: false,
          intro: "",
          introRef: "",
          ref: "",
          content: aelfJson["erreur"],
        )
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
                _newTabChildren.add(LiturgyPartColumn(
                  title: "Séquence",
                  subtitle: "",
                  repeatSubtitle: false,
                  intro: "",
                  introRef: "",
                  ref: "",
                  content: el["contenu"],
                ));
              }
              break;
            case 'entree_messianique':
              {
                _newTabTitles.add("Entrée messianique");
                _newTabChildren.add(LiturgyPartColumn(
                  title: "Entrée messianique",
                  subtitle: el["intro_lue"],
                  repeatSubtitle: false,
                  intro: "",
                  introRef: "",
                  ref: ref,
                  content: el["contenu"],
                ));
              }
              break;
            case 'psaume':
              {
                if (!(ref!.contains("Ps"))) {
                  ref = "Ps $ref";
                }
                _newTabTitles.add("Psaume");
                _newTabChildren.add(LiturgyPartColumn(
                  title: "Psaume",
                  subtitle: el["refrain_psalmique"],
                  repeatSubtitle: false,
                  intro: "",
                  introRef: "",
                  ref: ref,
                  content: el["contenu"],
                ));
              }
              break;
            case 'cantique':
              {
                _newTabTitles.add("Cantique");
                _newTabChildren.add(LiturgyPartColumn(
                  title: "Cantique",
                  subtitle: el["refrain_psalmique"],
                  repeatSubtitle: false,
                  intro: "",
                  introRef: "",
                  ref: ref,
                  content: el["contenu"],
                ));
              }
              break;
            case 'evangile':
              {
                _newTabTitles.add("Évangile");
                _newTabChildren.add(LiturgyPartColumn(
                  title: el["titre"],
                  subtitle: el["intro_lue"],
                  repeatSubtitle: false,
                  intro: (el.containsKey("verset_evangile")
                      ? el['verset_evangile']
                      : ""),
                  introRef:
                      (el.containsKey("ref_verset") ? el['ref_verset'] : ""),
                  ref: ref,
                  content: el["contenu"],
                ));
              }
              break;
            case 'epitre':
              {
                _newTabTitles.add("Épitre");
                _newTabChildren.add(LiturgyPartColumn(
                  title: el["titre"],
                  subtitle: el["intro_lue"],
                  repeatSubtitle: false,
                  intro: "",
                  introRef: "",
                  ref: ref,
                  content: el["contenu"],
                ));
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
                  _newTabChildren.add(LiturgyPartColumn(
                    title: el["titre"],
                    subtitle: el["intro_lue"],
                    repeatSubtitle: false,
                    intro: "",
                    introRef: "",
                    ref: ref,
                    content: el["contenu"],
                  ));
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
      // for each part of the office (hymn, psalm, gospel, etc.), -> add a new tab
      // key: officePart (hymn, pslam, gospel etc.)
      // value: officePartElements, can be the text, or a map, examples:
      //   - directly the text: <p>V/ Dieu, viens à mon aide, <br />R/ Seigneur, à notre secours.</p>
      //   - a map: `{auteur: A. Rivière, editeur: CNPL, titre: Voici le temps, Esprit très saint, texte: Voici le temps, Esprit très saint, <br> ...}`

      var office = aelfJson.keys.first;
      print("office type is : ${office.runtimeType}");
      aelfJson[office].forEach((officePart, officePartElements) {
        if (officePartElements != null) {
          if (officePartElements.length != 0) {
            // get text reference
            ref = "";
            if (officePartElements.runtimeType != String &&
                officePartElements.runtimeType != int) {
              ref = officePartElements.containsKey("reference")
                  ? officePartElements["reference"]
                  : "";
            }

            // foreach types of elements -> create new tab menu and add container with elements
            switch (officePart) {
              case 'introduction':
                {
                  _newTabTitles.add("Introduction");
                  _newTabChildren.add(LiturgyPartColumn(
                    title: "Introduction",
                    subtitle: "",
                    repeatSubtitle: false,
                    intro: "",
                    introRef: "",
                    ref: "",
                    content: officePartElements,
                  ));
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
                  text = officePartElements["texte"].replaceAll(
                      RegExp(r'</p>$'), '<br /><br />Gloire au Père, ...</p>');
                  _newTabTitles.add("Antienne invitatoire");
                  _newTabChildren.add(LiturgyPartColumn(
                    title: "Psaume invitatoire",
                    subtitle: subtitle,
                    repeatSubtitle: true,
                    intro: "",
                    introRef: "",
                    ref: (ref != "" ? "Ps $ref" : ""),
                    content: text,
                  ));
                }
                break;
              case 'hymne':
                {
                  _newTabTitles.add("Hymne");
                  _newTabChildren.add(LiturgyPartColumn(
                    title: "Hymne",
                    subtitle: officePartElements["titre"],
                    repeatSubtitle: false,
                    intro: "",
                    introRef: "",
                    ref: "",
                    content: officePartElements["texte"],
                  ));
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

                  _newTabTitles.add(officePartElements["titre"]);
                  _newTabChildren.add(LiturgyPartColumn(
                    title: officePartElements["titre"],
                    subtitle: subtitle,
                    repeatSubtitle: true,
                    intro: "",
                    introRef: "",
                    ref: ref,
                    content: officePartElements["texte"],
                  ));
                }
                break;
              case 'pericope':
                {
                  _newTabTitles.add("Parole de Dieu");
                  _newTabChildren.add(LiturgyPartColumn(
                    title: "Parole de Dieu",
                    subtitle: "",
                    repeatSubtitle: false,
                    intro: "",
                    introRef: "",
                    ref: ref,
                    // ignore: prefer_interpolation_to_compose_strings
                    content: officePartElements["texte"] +
                        '<p class="repons">Répons</p>' +
                        aelfJson[office]["repons"],
                  ));
                }
                break;
              case 'lecture':
                {
                  _newTabTitles.add("Lecture");
                  _newTabChildren.add(LiturgyPartColumn(
                    title:
                        "« ${capitalizeFirstLowerElse(officePartElements["titre"])} »",
                    subtitle: "",
                    repeatSubtitle: false,
                    intro: "",
                    introRef: "",
                    ref: ref,
                    // ignore: prefer_interpolation_to_compose_strings
                    content: officePartElements["texte"] +
                        '<p class="repons">Répons</p>' +
                        aelfJson[office]["repons_lecture"],
                  ));
                }
                break;
              case 'te_deum':
                {
                  _newTabTitles.add(officePartElements["titre"]);
                  _newTabChildren.add(LiturgyPartColumn(
                    title: officePartElements["titre"],
                    subtitle: "",
                    repeatSubtitle: false,
                    intro: "",
                    introRef: "",
                    ref: ref,
                    content: officePartElements["texte"],
                  ));
                }
                break;
              case 'texte_patristique':
                {
                  _newTabTitles.add("Lecture patristique");
                  _newTabChildren.add(LiturgyPartColumn(
                    title: "Lecture patristique",
                    subtitle: "",
                    repeatSubtitle: false,
                    intro: "",
                    introRef: "",
                    ref: ref,
                    // ignore: prefer_interpolation_to_compose_strings
                    content: officePartElements +
                        '<p class="repons">Répons</p>' +
                        aelfJson[office]["repons_patristique"],
                  ));
                }
                break;
              case 'intercession':
                {
                  _newTabTitles.add("Intercession");
                  _newTabChildren.add(LiturgyPartColumn(
                    title: "Intercession",
                    subtitle: "",
                    repeatSubtitle: false,
                    intro: "",
                    introRef: "",
                    ref: ref,
                    content: officePartElements,
                  ));
                }
                break;
              case 'notre_pere':
                {
                  _newTabTitles.add("Notre Père");
                  _newTabChildren.add(LiturgyPartColumn(
                    title: "Notre Père",
                    subtitle: "",
                    repeatSubtitle: false,
                    intro: "",
                    introRef: "",
                    ref: "",
                    content:
                        "Notre Père, qui es aux cieux, <br>que ton nom soit sanctifié,<br>que ton règne vienne,<br>que ta volonté soit faite sur la terre comme au ciel.<br>Donne-nous aujourd’hui notre pain de ce jour.<br>Pardonne-nous nos offenses,<br>comme nous pardonnons aussi à ceux qui nous ont offensés.<br>Et ne nous laisse pas entrer en tentation<br>mais délivre-nous du Mal.<br><br>Amen",
                  ));
                }
                break;
              case 'oraison':
                {
                  text = officePartElements +
                      "<p class=\"spacer\"><br></p>Que le seigneur nous bénisse, qu'il nous garde de tout mal, et nous conduise à la vie éternelle.<br>Amen.";
                  _newTabTitles.add("Oraison et bénédiction");
                  _newTabChildren.add(LiturgyPartColumn(
                    title: "Oraison et bénédiction",
                    subtitle: "",
                    repeatSubtitle: false,
                    intro: "",
                    introRef: "",
                    ref: ref,
                    content: text,
                  ));
                }
                break;
              case 'hymne_mariale':
                {
                  _newTabTitles.add(officePartElements["titre"]);
                  _newTabChildren.add(LiturgyPartColumn(
                    title: officePartElements["titre"],
                    subtitle: "",
                    repeatSubtitle: false,
                    intro: "",
                    introRef: "",
                    ref: "",
                    content: officePartElements["texte"],
                  ));
                }
                break;
              case 'verset_psaume':
                {
                  _newTabTitles.add("Verset");
                  _newTabChildren.add(LiturgyPartColumn(
                    title: "Verset",
                    subtitle: "",
                    repeatSubtitle: false,
                    intro: "",
                    introRef: "",
                    content: officePartElements,
                  ));
                }
                break;
              case 'erreur':
                {
                  _newTabTitles.add("Erreur");
                  _newTabChildren.add(LiturgyPartColumn(
                    title: "Erreur",
                    subtitle: "",
                    repeatSubtitle: false,
                    intro: "",
                    introRef: "",
                    ref: "",
                    content: officePartElements,
                  ));
                }
                break;
              default:
                {
                  // display pasumes and cantiques
                  if (officePart.contains("psaume_") ||
                      officePart.contains("cantique_")) {
                    // get number of the element
                    nb = officePart.split('_')[1];
                    title = officePart.contains("psaume_")
                        // ignore: prefer_interpolation_to_compose_strings
                        ? "Psaume " + officePartElements["reference"]
                        : officePartElements["titre"];
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
                    if (officePart.contains("psaume_") &&
                        officePartElements["reference"]
                            .toLowerCase()
                            .contains("cantique")) {
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
                    } else if (officePart.contains("psaume_")) {
                      // add ps before psaume reference
                      ref = ref != "" ? "Ps $ref" : "";
                    }
                    text = officePartElements["texte"].replaceAll(
                        RegExp(r'</p>$'),
                        '<br /><br />Gloire au Père, ...</p>');
                    _newTabTitles.add(title);
                    _newTabChildren.add(LiturgyPartColumn(
                      title: title,
                      subtitle: subtitle,
                      repeatSubtitle: true,
                      intro: "",
                      introRef: "",
                      ref: ref,
                      content: text,
                    ));
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
          Map<String, dynamic> tabsMap = parseLiturgy(liturgyState.aelfJson);
          return Scaffold(
            body: LiturgyTabsView(tabsMap: tabsMap),
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
      // Move verse and repons characters in the paragraph
      .replaceAll('V/ <p>', '<p>V/ ')
      .replaceAll('R/ <p>', '<p>R/ ')
      // Verse in red, and special character
      .replaceAll('V/', '<span class="red-text">℣</span>')
      // Remove bold for R/
      .replaceAll(
          RegExp(
              r'<strong><span class="verse_number">\W?R/</span>\W?</strong>|<span class="verse_number">R/</span>'),
          '<span class="red-text"> ℟</span>')

      // For repons, replace the class verse_number  OR 'R/' by red-text
      // and use the special character
      .replaceAll(RegExp('<span class="verse_number">R/</span>|R/'),
          '<span class="red-text">℟</span>')
      // Sometimes, the API misses the first <p>
      .replaceFirst(RegExp('^`?<span|^"?<span'), '<p><span')
      // * and + in red
      .replaceAll('*', '<span class="red-text">*</span>')
      .replaceAll('+', '<span class="red-text">+</span>')
      // Replace verse number in the form 'chapter_number.verse_number' by
      // 'chapter_number, <new line> verse_number'
      .replaceAllMapped(RegExp(r'(\d{1,3})(\.)(\d{1,3})'), (Match m) {
    return "${m[1]},<br> ${m[3]}";
  });
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

const double verseFontSize = 16;
